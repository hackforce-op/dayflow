/// DayFlow 认证模块 - 登录页面
///
/// 此文件实现了应用的登录页面 [LoginPage]，包括：
/// - 邮箱和密码输入框（带表单验证）
/// - "登录" 主按钮
/// - "使用 Google 登录" 社交登录按钮
/// - 跳转到注册页面的链接
/// - 加载状态和错误提示处理
///
/// 使用 [ConsumerStatefulWidget] 集成 Riverpod 状态管理，
/// 监听 [authProvider] 的状态变化来驱动 UI 更新。
///
/// 路由路径：/login（在 app_router.dart 中配置）
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:dayflow/core/constants/app_constants.dart';
import 'package:dayflow/core/router/app_router.dart';
import 'package:dayflow/features/auth/providers/auth_provider.dart';
import 'package:dayflow/features/auth/providers/remembered_accounts_provider.dart';
import 'package:dayflow/features/auth/presentation/widgets/auth_text_field.dart';
import 'package:dayflow/features/auth/presentation/widgets/social_login_button.dart';

/// 登录页面
///
/// 提供邮箱密码登录和 Google 第三方登录两种方式。
/// 使用 [ConsumerStatefulWidget] 以便：
/// 1. 管理表单控制器的生命周期（StatefulWidget）
/// 2. 访问 Riverpod Provider（ConsumerWidget）
class LoginPage extends ConsumerStatefulWidget {
  /// 创建登录页面
  const LoginPage({
    super.key,
    this.prefilledEmail,
  });

  final String? prefilledEmail;

  @override
  ConsumerState<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends ConsumerState<LoginPage> {
  // ============================================================
  // 表单相关状态
  // ============================================================

  /// 表单全局 Key，用于触发和管理表单验证
  final _formKey = GlobalKey<FormState>();

  /// 邮箱输入框控制器
  final _emailController = TextEditingController();

  /// 密码输入框控制器
  final _passwordController = TextEditingController();

  @override
  void initState() {
    super.initState();
    if (widget.prefilledEmail != null && widget.prefilledEmail!.isNotEmpty) {
      _emailController.text = widget.prefilledEmail!;
    }
  }

  @override
  void dispose() {
    // 释放控制器资源，防止内存泄漏
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  // ============================================================
  // 事件处理方法
  // ============================================================

  /// 处理登录按钮点击
  ///
  /// 执行流程：
  /// 1. 验证表单输入（邮箱格式、密码非空）
  /// 2. 调用 [AuthNotifier.signIn] 执行登录
  /// 3. 状态变化会自动触发 UI 更新（通过 ref.listen）
  void _handleSignIn() {
    // 验证表单，如果有字段不合法则直接返回
    if (!_formKey.currentState!.validate()) return;

    // 触发登录操作
    ref.read(authProvider.notifier).signIn(
          email: _emailController.text.trim(),
          password: _passwordController.text,
        );
  }

  /// 处理 Google 登录按钮点击
  void _handleGoogleSignIn() {
    ref.read(authProvider.notifier).signInWithGoogle();
  }

  /// 导航到注册页面
  void _navigateToRegister() {
    context.go(RoutePaths.register);
  }

  // ============================================================
  // UI 构建
  // ============================================================

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final rememberedAccounts = ref.watch(rememberedAccountsProvider);

    // 监听认证状态，处理错误提示和导航
    ref.listen<AuthState>(authProvider, (previous, next) {
      // 登录失败时显示错误 SnackBar
      if (next is AuthStateError) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(next.message),
            backgroundColor: theme.colorScheme.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      } else if (next is AuthStateAuthenticated) {
        ref
            .read(rememberedAccountsProvider.notifier)
            .remember(next.userProfile);
        context.go(RoutePaths.diary);
      }
    });

    // 读取当前认证状态，判断是否处于加载中
    final authState = ref.watch(authProvider);
    final isLoading = authState is AuthStateLoading;

    return Scaffold(
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
                  // 应用标题区域
                  // ------------------------------------------------
                  Icon(
                    Icons.wb_sunny_outlined,
                    size: 64,
                    color: theme.colorScheme.primary,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    AppConstants.appName,
                    textAlign: TextAlign.center,
                    style: theme.textTheme.headlineLarge,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '欢迎回来，请登录你的账号',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 40),

                  if (rememberedAccounts.isNotEmpty) ...[
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        '已记住账号',
                        style: theme.textTheme.labelLarge,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: rememberedAccounts
                          .map(
                            (account) => ActionChip(
                              label: Text(account.displayName ?? account.email),
                              avatar:
                                  const Icon(Icons.person_outline, size: 18),
                              onPressed: () {
                                _emailController.text = account.email;
                              },
                            ),
                          )
                          .toList(),
                    ),
                    const SizedBox(height: 16),
                  ],

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
                      // 基本的邮箱格式验证
                      if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$')
                          .hasMatch(value.trim())) {
                        return '请输入有效的邮箱地址';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  // ------------------------------------------------
                  // 密码输入框
                  // ------------------------------------------------
                  AuthTextField(
                    controller: _passwordController,
                    label: '密码',
                    hint: '请输入密码',
                    prefixIcon: Icons.lock_outlined,
                    obscureText: true,
                    textInputAction: TextInputAction.done,
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
                  const SizedBox(height: 24),

                  // ------------------------------------------------
                  // 登录按钮
                  // ------------------------------------------------
                  SizedBox(
                    height: 48,
                    child: FilledButton(
                      // 加载中时禁用按钮
                      onPressed: isLoading ? null : _handleSignIn,
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
                              '登录',
                              style: TextStyle(fontSize: 16),
                            ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // ------------------------------------------------
                  // 分割线
                  // ------------------------------------------------
                  Row(
                    children: [
                      Expanded(
                          child: Divider(color: theme.colorScheme.outline)),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Text(
                          '或',
                          style: theme.textTheme.bodySmall,
                        ),
                      ),
                      Expanded(
                          child: Divider(color: theme.colorScheme.outline)),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // ------------------------------------------------
                  // Google 登录按钮
                  // ------------------------------------------------
                  SocialLoginButton(
                    provider: SocialProvider.google,
                    onPressed: _handleGoogleSignIn,
                    isLoading: isLoading,
                  ),
                  const SizedBox(height: 32),

                  // ------------------------------------------------
                  // 注册链接
                  // ------------------------------------------------
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        '还没有账号？',
                        style: theme.textTheme.bodyMedium,
                      ),
                      TextButton(
                        onPressed: _navigateToRegister,
                        child: const Text('注册'),
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
