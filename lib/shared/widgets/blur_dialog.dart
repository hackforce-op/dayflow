library;

import 'dart:ui';

import 'package:flutter/material.dart';

/// 显示带背景模糊效果的对话框
///
/// 性能优化策略：
/// - 动画进行时跳过 BackdropFilter（GPU 每帧模糊代价极高）
/// - 动画结束后（animation.value >= 0.95）再启用模糊，用户无感知
/// - RepaintBoundary 将模糊层限制在独立图层，杜绝重绘污染
/// - sigma 设为 4，兼顾视觉效果与渲染成本
Future<T?> showBlurDialog<T>({
  required BuildContext context,
  required WidgetBuilder builder,
  bool barrierDismissible = true,
  String? barrierLabel,
  Color barrierColor = const Color(0x73000000),
}) {
  final effectiveBarrierLabel = barrierLabel ??
      MaterialLocalizations.of(context).modalBarrierDismissLabel;

  return showGeneralDialog<T>(
    context: context,
    barrierDismissible: barrierDismissible,
    barrierLabel: effectiveBarrierLabel,
    barrierColor: barrierColor,
    transitionDuration: const Duration(milliseconds: 200),
    pageBuilder: (dialogContext, animation, __) {
      // 构建内容子树（不随动画重建）
      final content = SafeArea(
        child: Center(
          child: Builder(builder: (ctx) => builder(ctx)),
        ),
      );

      // 模糊度随动画渐进增加，避免突然出现导致的视觉闪烁
      return RepaintBoundary(
        child: AnimatedBuilder(
          animation: animation,
          builder: (_, child) {
            final sigma = 4.0 * animation.value;
            if (sigma < 0.5) return child!;
            return BackdropFilter(
              filter: ImageFilter.blur(sigmaX: sigma, sigmaY: sigma),
              child: child,
            );
          },
          child: content,
        ),
      );
    },
    transitionBuilder: (context, animation, _, child) {
      final curved = CurvedAnimation(
        parent: animation,
        curve: Curves.easeOutCubic,
        reverseCurve: Curves.easeInCubic,
      );

      return FadeTransition(
        opacity: curved,
        child: ScaleTransition(
          scale: Tween<double>(begin: 0.94, end: 1).animate(curved),
          child: child,
        ),
      );
    },
  );
}

/// 用于 showDateRangePicker 等系统弹窗的模糊背景构建器
Widget blurPopupBuilder(BuildContext context, Widget? child) {
  if (child == null) {
    return const SizedBox.shrink();
  }

  // sigma 从 8 降至 4，与 showBlurDialog 保持一致
  return RepaintBoundary(
    child: BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 4, sigmaY: 4),
      child: child,
    ),
  );
}

