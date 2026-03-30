/// DayFlow 认证模块 - 注册页面
///
/// 此文件实现了应用的用户注册页面 [RegisterPage]，包括：
/// - 邮箱、显示名称、密码、确认密码四个输入字段
/// - 密码强度指示器（弱 / 中 / 强）
/// - "注册" 主按钮
/// - 跳转到登录页面的链接
/// - 加载状态和错误提示处理
///
/// 注册成功后的行为取决于 Supabase 项目配置：
/// - 如果开启了邮箱验证：提示用户查收验证邮件
/// - 如果未开启邮箱验证：自动登录并跳转到首页
///
/// 路由路径：/register（在 app_router.dart 中配置）
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:dayflow/core/constants/app_constants.dart';
import 'package:dayflow/core/router/app_router.dart';
import 'package:dayflow/features/auth/providers/auth_provider.dart';
import 'package:dayflow/features/auth/presentation/widgets/auth_text_field.dart';

/// 注册页面
///
/// 提供完整的用户注册表单，包含输入验证和密码强度提示。
/// 使用 [ConsumerStatefulWidget] 管理表单状态和访问 Riverpod Provider。
class RegisterPage extends ConsumerStatefulWidget {
  /// 创建注册页面
  const RegisterPage({super.key});

  @override
  ConsumerState<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends ConsumerState<RegisterPage> {
  // ============================================================
  // 表单相关状态
  // ============================================================

  /// 表单全局 Key
  final _formKey = GlobalKey<FormState>();

  /// 邮箱输入框控制器
  final _emailController = TextEditingController();

  /// 显示名称输入框控制器
  final _displayNameController = TextEditingController();

  /// 密码输入框控制器
  final _passwordController = TextEditingController();

  /// 确认密码输入框控制器
  final _confirmPasswordController = TextEditingController();

  /// 密码强度等级（0~3）
  ///
  /// - 0：无输入
  /// - 1：弱（长度 < 8 或仅包含一种字符类型）
  /// - 2：中（长度 ≥ 8，包含两种字符类型）
  /// - 3：强（长度 ≥ 8，包含三种及以上字符类型）
  int _passwordStrength = 0;

  @override
  void initState() {
    super.initState();
    // 监听密码输入变化，实时更新密码强度指示器
    _passwordController.addListener(_updatePasswordStrength);
  }

  @override
  void dispose() {
    // 释放所有控制器资源
    _emailController.dispose();
    _displayNameController.dispose();
    _passwordController.removeListener(_updatePasswordStrength);
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  // ============================================================
  // 密码强度计算
  // ============================================================

  /// 更新密码强度指示器
  ///
  /// 根据密码的长度和字符多样性计算强度等级：
  /// - 包含小写字母 +1
  /// - 包含大写字母 +1
  /// - 包含数字 +1
  /// - 包含特殊字符 +1
  ///
  /// 最终强度 = min(字符类型数量, 3)
  void _updatePasswordStrength() {
    final password = _passwordController.text;

    if (password.isEmpty) {
      setState(() => _passwordStrength = 0);
      return;
    }

    int strength = 0;

    // 检查密码长度是否达到基本要求
    if (password.length >= 6) strength++;

    // 检查是否包含大小写字母
    if (password.contains(RegExp(r'[a-z]')) &&
        password.contains(RegExp(r'[A-Z]'))) {
      strength++;
    }

    // 检查是否包含数字
    if (password.contains(RegExp(r'[0-9]'))) strength++;

    // 检查是否包含特殊字符
    if (password.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]'))) {
      strength++;
    }

    // 强度范围限制为 0~3
    setState(() => _passwordStrength = strength.clamp(0, 3));
  }

  /// 获取密码强度的描述文字
  String _getStrengthLabel() {
    return switch (_passwordStrength) {
      0 => '',
      1 => '弱',
      2 => '中',
      3 => '强',
      _ => '',
    };
  }

  /// 获取密码强度对应的颜色
  Color _getStrengthColor() {
    return switch (_passwordStrength) {
      1 => Colors.red,
      2 => Colors.orange,
      3 => Colors.green,
      _ => Colors.grey,
    };
  }

  // ============================================================
  // 事件处理方法
  // ============================================================

  /// 处理注册按钮点击
  ///
  /// 执行流程：
  /// 1. 验证表单输入
  /// 2. 调用 [AuthNotifier.signUp] 执行注册
  /// 3. 注册结果通过 ref.listen 处理
  void _handleSignUp() {
    if (!_formKey.currentState!.validate()) return;

    ref.read(authProvider.notifier).signUp(
          email: _emailController.text.trim(),
          password: _passwordController.text,
          displayName: _displayNameController.text.trim().isNotEmpty
              ? _displayNameController.text.trim()
              : null,
        );
  }

  /// 导航到登录页面
  void _navigateToLogin() {
    context.go(RoutePaths.login);
  }

  // ============================================================
  // UI 构建
  // ============================================================

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // 监听认证状态变化
    ref.listen<AuthState>(authProvider, (previous, next) {
      if (next is AuthStateError) {
        // 注册失败，显示错误提示
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(next.message),
            backgroundColor: theme.colorScheme.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      } else if (next is AuthStateAuthenticated) {
        context.go(RoutePaths.diary);
      } else if (next is AuthStateUnauthenticated &&
          previous is AuthStateLoading) {
        // 注册成功但需要邮箱验证
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('注册成功！请查收验证邮件后登录'),
            backgroundColor: theme.colorScheme.primary,
            behavior: SnackBarBehavior.floating,
          ),
        );
        // 跳转到登录页面
        context.go(RoutePaths.login);
      }
    });

    final authState = ref.watch(authProvider);
    final isLoading = authState is AuthStateLoading;

    return Scaffold(
      // 顶部返回导航栏
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: _navigateToLogin,
        ),
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // ------------------------------------------------
                  // 页面标题区域
                  // ------------------------------------------------
                  Text(
                    '创建账号',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.headlineLarge,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '加入 ${AppConstants.appName}，开始你的日常管理',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 32),

                  // ------------------------------------------------
                  // 邮箱输入框
                  // ------------------------------------------------
                  AuthTextField(
                    controller: _emailController,
                    label: '邮箱',
                    hint: '请输入邮箱地址',
                    prefixIcon: Icons.email_outlined,
                    keyboardType: TextInputType.emailAddress,
                    textInputAction: TextInputAction.next,
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return '请输入邮箱地址';
                      }
                      if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$')
                          .hasMatch(value.trim())) {
                        return '请输入有效的邮箱地址';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  // ------------------------------------------------
                  // 显示名称输入框
                  // ------------------------------------------------
                  AuthTextField(
                    controller: _displayNameController,
                    label: '昵称',
                    hint: '请输入你的昵称（可选）',
                    prefixIcon: Icons.person_outlined,
                    textInputAction: TextInputAction.next,
                  ),
                  const SizedBox(height: 16),

                  // ------------------------------------------------
                  // 密码输入框
                  // ------------------------------------------------
                  AuthTextField(
                    controller: _passwordController,
                    label: '密码',
                    hint: '请设置密码（至少 6 位）',
                    prefixIcon: Icons.lock_outlined,
                    obscureText: true,
                    textInputAction: TextInputAction.next,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return '请输入密码';
                      }
                      if (value.length < 6) {
                        return '密码至少 6 位字符';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 8),

                  // ------------------------------------------------
                  // 密码强度指示器
                  // ------------------------------------------------
                  if (_passwordController.text.isNotEmpty)
                    _PasswordStrengthIndicator(
                      strength: _passwordStrength,
                      label: _getStrengthLabel(),
                      color: _getStrengthColor(),
                    ),
                  const SizedBox(height: 8),

                  // ------------------------------------------------
                  // 确认密码输入框
                  // ------------------------------------------------
                  AuthTextField(
                    controller: _confirmPasswordController,
                    label: '确认密码',
                    hint: '请再次输入密码',
                    prefixIcon: Icons.lock_outlined,
                    obscureText: true,
                    textInputAction: TextInputAction.done,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return '请确认密码';
                      }
                      if (value != _passwordController.text) {
                        return '两次输入的密码不一致';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 24),

                  // ------------------------------------------------
                  // 注册按钮
                  // ------------------------------------------------
                  SizedBox(
                    height: 48,
                    child: FilledButton(
                      onPressed: isLoading ? null : _handleSignUp,
                      child: isLoading
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Text(
                              '注册',
                              style: TextStyle(fontSize: 16),
                            ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // ------------------------------------------------
                  // 登录链接
                  // ------------------------------------------------
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        '已有账号？',
                        style: theme.textTheme.bodyMedium,
                      ),
                      TextButton(
                        onPressed: _navigateToLogin,
                        child: const Text('登录'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ============================================================
// 密码强度指示器（私有组件）
// ============================================================

/// 密码强度指示器
///
/// 通过三段彩色进度条和文字标签直观展示密码的安全强度。
/// 强度等级：弱（红色）、中（橙色）、强（绿色）。
class _PasswordStrengthIndicator extends StatelessWidget {
  /// 密码强度等级（0~3）
  final int strength;

  /// 强度描述文字
  final String label;

  /// 强度对应颜色
  final Color color;

  const _PasswordStrengthIndicator({
    required this.strength,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 三段式进度条
        Row(
          children: List.generate(3, (index) {
            return Expanded(
              child: Container(
                height: 4,
                margin: EdgeInsets.only(right: index < 2 ? 4 : 0),
                decoration: BoxDecoration(
                  // 当前段的强度 <= strength 时显示颜色，否则显示灰色
                  color: index < strength ? color : Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            );
          }),
        ),
        const SizedBox(height: 4),

        // 强度描述文字
        if (label.isNotEmpty)
          Text(
            '密码强度：$label',
            style: TextStyle(
              fontSize: 12,
              color: color,
              fontWeight: FontWeight.w500,
            ),
          ),
      ],
    );
  }
}
