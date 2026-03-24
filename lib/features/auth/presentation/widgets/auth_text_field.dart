/// DayFlow 认证模块 - 可复用文本输入框组件
///
/// 此文件提供认证页面专用的文本输入框 [AuthTextField]，
/// 统一登录和注册页面中所有输入框的视觉样式和交互行为。
///
/// 特性：
/// - 支持自定义标签、提示文字、前缀图标
/// - 支持密码输入模式（文本遮盖 + 显示/隐藏切换按钮）
/// - 内置表单验证支持（通过 [validator] 回调）
/// - 自动适配应用主题（浅色/深色模式）
///
/// 使用方式：
/// ```dart
/// AuthTextField(
///   controller: _emailController,
///   label: '邮箱',
///   hint: '请输入邮箱地址',
///   prefixIcon: Icons.email_outlined,
///   keyboardType: TextInputType.emailAddress,
///   validator: (value) => value?.isEmpty == true ? '请输入邮箱' : null,
/// )
/// ```
library;

import 'package:flutter/material.dart';

/// 认证文本输入框组件
///
/// 为认证页面（登录、注册）提供统一样式的文本输入框。
/// 继承 [StatefulWidget] 以支持密码显示/隐藏的内部状态管理。
///
/// 设计说明：
/// - 使用应用主题中定义的 [InputDecorationTheme] 作为基础样式
/// - 在此基础上添加认证场景特有的装饰（标签、图标等）
/// - 密码模式下自动添加"显示/隐藏"按钮
class AuthTextField extends StatefulWidget {
  /// 文本编辑控制器
  ///
  /// 用于读取和设置输入框的文本内容。
  /// 由调用方创建和管理生命周期。
  final TextEditingController controller;

  /// 输入框标签文本
  ///
  /// 显示在输入框上方或悬浮于输入框上，标识该字段的用途。
  /// 例如："邮箱"、"密码"、"确认密码"。
  final String label;

  /// 占位提示文本
  ///
  /// 在输入框为空时显示的灰色提示文字。
  /// 例如："请输入邮箱地址"。
  final String? hint;

  /// 前缀图标
  ///
  /// 显示在输入框左侧的图标，提供视觉提示。
  /// 例如：Icons.email_outlined（邮箱）、Icons.lock_outlined（密码）。
  final IconData? prefixIcon;

  /// 是否为密码输入框
  ///
  /// 设置为 true 时：
  /// - 文本默认以圆点遮盖（obscureText = true）
  /// - 在输入框右侧显示"显示/隐藏"切换按钮
  final bool obscureText;

  /// 键盘类型
  ///
  /// 控制弹出的虚拟键盘布局：
  /// - [TextInputType.emailAddress]：邮箱键盘（带 @ 符号）
  /// - [TextInputType.visiblePassword]：密码键盘
  /// - [TextInputType.text]：默认文本键盘
  final TextInputType? keyboardType;

  /// 输入验证函数
  ///
  /// 在表单提交时调用，返回 null 表示验证通过，
  /// 返回非 null 字符串表示验证失败（字符串为错误提示信息）。
  ///
  /// 示例：
  /// ```dart
  /// validator: (value) {
  ///   if (value == null || value.isEmpty) return '此字段不能为空';
  ///   return null;
  /// }
  /// ```
  final String? Function(String?)? validator;

  /// 输入框的键盘操作按钮类型
  ///
  /// 控制键盘右下角按钮的显示：
  /// - [TextInputAction.next]：下一步（跳转到下一个输入框）
  /// - [TextInputAction.done]：完成
  final TextInputAction? textInputAction;

  /// 创建认证文本输入框
  const AuthTextField({
    super.key,
    required this.controller,
    required this.label,
    this.hint,
    this.prefixIcon,
    this.obscureText = false,
    this.keyboardType,
    this.validator,
    this.textInputAction,
  });

  @override
  State<AuthTextField> createState() => _AuthTextFieldState();
}

class _AuthTextFieldState extends State<AuthTextField> {
  /// 密码是否处于遮盖（不可见）状态
  ///
  /// 仅在 [widget.obscureText] 为 true 时使用。
  /// 初始值与 [widget.obscureText] 相同（即默认遮盖密码）。
  late bool _isObscured;

  @override
  void initState() {
    super.initState();
    // 初始化密码遮盖状态为组件配置的值
    _isObscured = widget.obscureText;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return TextFormField(
      controller: widget.controller,

      // 密码遮盖：如果是密码字段，使用内部状态控制；否则不遮盖
      obscureText: _isObscured,

      // 键盘类型
      keyboardType: widget.keyboardType,

      // 验证函数
      validator: widget.validator,

      // 键盘操作按钮
      textInputAction: widget.textInputAction,

      // 输入框装饰
      decoration: InputDecoration(
        // 标签文本
        labelText: widget.label,

        // 占位提示
        hintText: widget.hint,

        // 前缀图标
        prefixIcon: widget.prefixIcon != null
            ? Icon(widget.prefixIcon, color: theme.colorScheme.onSurfaceVariant)
            : null,

        // 后缀图标：密码字段显示可见性切换按钮
        suffixIcon: widget.obscureText
            ? IconButton(
                icon: Icon(
                  _isObscured
                      ? Icons.visibility_outlined
                      : Icons.visibility_off_outlined,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                // 切换密码的可见性
                onPressed: () {
                  setState(() {
                    _isObscured = !_isObscured;
                  });
                },
              )
            : null,
      ),
    );
  }
}
