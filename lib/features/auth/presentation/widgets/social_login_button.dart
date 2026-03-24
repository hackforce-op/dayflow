/// DayFlow 认证模块 - 第三方社交登录按钮组件
///
/// 此文件提供第三方登录按钮 [SocialLoginButton]，
/// 支持 Google、Apple、GitHub 等 OAuth 提供商。
///
/// 特性：
/// - 图标 + 文字的标准布局
/// - 支持多种登录提供商（通过 [SocialProvider] 枚举配置）
/// - 加载状态指示（按钮内显示进度条）
/// - 自动适配应用主题
///
/// 使用方式：
/// ```dart
/// SocialLoginButton(
///   provider: SocialProvider.google,
///   onPressed: () => ref.read(authProvider.notifier).signInWithGoogle(),
/// )
/// ```
library;

import 'package:flutter/material.dart';

// ============================================================
// 社交登录提供商枚举
// ============================================================

/// 支持的第三方登录提供商
///
/// 每个提供商定义了在按钮中显示的：
/// - [label]：按钮文字（中文）
/// - [icon]：按钮左侧图标
/// - [backgroundColor]：按钮背景色（品牌色）
/// - [foregroundColor]：按钮文字和图标颜色
enum SocialProvider {
  /// Google 登录
  ///
  /// 使用 Google 品牌白色按钮 + 彩色 G 图标的经典样式。
  google(
    label: '使用 Google 登录',
    icon: Icons.g_mobiledata,
    backgroundColor: Colors.white,
    foregroundColor: Color(0xFF757575),
  ),

  /// Apple 登录
  ///
  /// 使用 Apple 品牌黑色按钮 + 白色苹果图标的样式。
  apple(
    label: '使用 Apple 登录',
    icon: Icons.apple,
    backgroundColor: Colors.black,
    foregroundColor: Colors.white,
  ),

  /// GitHub 登录
  ///
  /// 使用 GitHub 品牌深灰色按钮的样式。
  github(
    label: '使用 GitHub 登录',
    icon: Icons.code,
    backgroundColor: Color(0xFF24292E),
    foregroundColor: Colors.white,
  );

  /// 按钮显示文字
  final String label;

  /// 按钮左侧图标
  final IconData icon;

  /// 按钮背景颜色（提供商品牌色）
  final Color backgroundColor;

  /// 按钮前景颜色（文字和图标颜色）
  final Color foregroundColor;

  const SocialProvider({
    required this.label,
    required this.icon,
    required this.backgroundColor,
    required this.foregroundColor,
  });
}

// ============================================================
// 社交登录按钮组件
// ============================================================

/// 第三方社交登录按钮
///
/// 统一的社交登录按钮组件，根据指定的 [provider] 自动配置
/// 按钮的图标、文字和颜色样式。
///
/// 支持加载状态 [isLoading]：
/// - 为 true 时：显示进度指示器，按钮不可点击
/// - 为 false 时：显示正常的图标 + 文字
class SocialLoginButton extends StatelessWidget {
  /// 登录提供商
  ///
  /// 决定按钮的视觉样式（图标、文字、颜色）。
  final SocialProvider provider;

  /// 按钮点击回调
  ///
  /// 触发对应的第三方登录流程。
  /// 在加载状态下回调不会被执行。
  final VoidCallback? onPressed;

  /// 是否处于加载状态
  ///
  /// 为 true 时按钮显示圆形进度指示器，且不可点击。
  final bool isLoading;

  /// 创建社交登录按钮
  ///
  /// [provider] 必填，登录提供商
  /// [onPressed] 可选，按钮点击回调
  /// [isLoading] 可选，默认为 false
  const SocialLoginButton({
    super.key,
    required this.provider,
    this.onPressed,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // 深色模式下，白色背景的按钮需要特殊处理
    final isDark = theme.brightness == Brightness.dark;
    final bgColor = isDark && provider == SocialProvider.google
        ? theme.colorScheme.surfaceContainerHighest
        : provider.backgroundColor;
    final fgColor = isDark && provider == SocialProvider.google
        ? theme.colorScheme.onSurface
        : provider.foregroundColor;

    return SizedBox(
      width: double.infinity,
      height: 48,
      child: OutlinedButton(
        // 加载中时禁用按钮
        onPressed: isLoading ? null : onPressed,
        style: OutlinedButton.styleFrom(
          backgroundColor: bgColor,
          foregroundColor: fgColor,
          side: BorderSide(
            color: isDark
                ? theme.colorScheme.outline
                : Colors.grey.shade300,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16),
        ),
        child: isLoading
            // 加载状态：显示小型进度指示器
            ? SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: fgColor,
                ),
              )
            // 正常状态：图标 + 文字
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // 提供商图标
                  Icon(provider.icon, size: 24),
                  const SizedBox(width: 12),
                  // 按钮文字
                  Text(
                    provider.label,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}
