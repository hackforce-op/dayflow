/// DayFlow 通用加载指示器组件
///
/// 此文件提供可复用的加载状态 Widget，包括：
/// - 全屏居中加载动画（带可选文字提示）
/// - 适用于页面加载、数据请求等场景
///
/// 使用方式：
/// ```dart
/// // 默认加载指示器
/// AppLoadingWidget()
///
/// // 带文字提示的加载指示器
/// AppLoadingWidget(message: '正在加载数据...')
/// ```
library;

import 'package:flutter/material.dart';

/// 通用加载指示器 Widget
///
/// 在页面中心显示一个 [CircularProgressIndicator]，
/// 可选择性地在下方显示提示文字。
class AppLoadingWidget extends StatelessWidget {
  /// 创建加载指示器
  ///
  /// [message] 可选的加载提示文字，显示在进度指示器下方。
  /// [key] Widget 的 key。
  const AppLoadingWidget({super.key, this.message});

  /// 加载提示文字
  ///
  /// 如果为 null，则只显示进度指示器，不显示文字。
  final String? message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        // 垂直居中排列
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          // 圆形进度指示器，使用主题主色调
          const CircularProgressIndicator(),

          // 如果有提示文字，则在下方显示
          if (message != null) ...[
            const SizedBox(height: 16),
            Text(
              message!,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ],
      ),
    );
  }
}
