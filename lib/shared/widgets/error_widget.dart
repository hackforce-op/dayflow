/// DayFlow 通用错误显示组件
///
/// 此文件提供可复用的错误状态 Widget，包括：
/// - 错误图标 + 错误消息文字
/// - 可选的重试按钮（带回调函数）
/// - 适用于网络错误、数据加载失败等场景
///
/// 使用方式：
/// ```dart
/// // 基础错误显示
/// AppErrorWidget(message: '加载失败')
///
/// // 带重试按钮的错误显示
/// AppErrorWidget(
///   message: '网络连接失败',
///   onRetry: () => ref.refresh(someProvider),
/// )
/// ```
library;

import 'package:flutter/material.dart';

/// 通用错误显示 Widget
///
/// 在页面中心显示错误图标、错误消息，
/// 以及可选的重试按钮，方便用户重新加载数据。
class AppErrorWidget extends StatelessWidget {
  /// 创建错误显示组件
  ///
  /// [message] 错误提示消息，必填。
  /// [onRetry] 重试按钮的回调函数，为 null 时不显示重试按钮。
  /// [icon] 自定义错误图标，默认为 [Icons.error_outline]。
  /// [key] Widget 的 key。
  const AppErrorWidget({
    required this.message,
    super.key,
    this.onRetry,
    this.icon,
  });

  /// 错误提示消息文字
  final String message;

  /// 重试按钮的回调函数
  ///
  /// 如果为 null，则不显示重试按钮。
  /// 通常传入刷新数据的方法，例如 `ref.refresh(provider)`。
  final VoidCallback? onRetry;

  /// 自定义错误图标
  ///
  /// 如果为 null，则使用默认的 [Icons.error_outline] 图标。
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          // 垂直居中排列
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            // 错误图标，使用错误色调
            Icon(
              icon ?? Icons.error_outline,
              size: 64,
              color: theme.colorScheme.error,
            ),

            const SizedBox(height: 16),

            // 错误消息文字，居中显示，最多 3 行
            Text(
              message,
              style: theme.textTheme.bodyLarge?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),

            // 如果提供了重试回调，显示重试按钮
            if (onRetry != null) ...[
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh),
                label: const Text('重试'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
