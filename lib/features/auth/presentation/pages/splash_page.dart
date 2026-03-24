/// DayFlow 认证模块 - 闪屏页面
///
/// 此文件实现了应用的启动闪屏页面 [SplashPage]，包括：
/// - 应用 Logo 和名称的居中展示
/// - 加载进度指示器
/// - 自动检查认证状态并导航到相应页面
///
/// 闪屏页的生命周期：
/// 1. 应用启动时显示此页面
/// 2. 检查 Supabase 本地认证会话
/// 3. 已登录 → 跳转到首页（/diary）
/// 4. 未登录 → 跳转到登录页（/login）
///
/// 注意：实际的导航跳转由 [GoRouter] 的路由守卫处理，
/// 此页面主要负责视觉展示和触发状态检查。
///
/// 路由路径：/splash（在 app_router.dart 中配置）
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:dayflow/core/constants/app_constants.dart';
import 'package:dayflow/core/router/app_router.dart';
import 'package:dayflow/features/auth/providers/auth_provider.dart';

/// 闪屏页面
///
/// 应用启动时的首屏，展示品牌信息并在后台检查认证状态。
/// 使用 [ConsumerWidget] 监听 [authProvider] 的状态变化，
/// 根据认证结果自动导航到登录页或首页。
class SplashPage extends ConsumerWidget {
  /// 创建闪屏页面
  const SplashPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);

    // 监听认证状态变化，根据结果进行导航
    ref.listen<AuthState>(authProvider, (previous, next) {
      // 等待初始化完成后再导航
      switch (next) {
        case AuthStateAuthenticated():
          // 已登录 → 跳转到首页
          context.go(RoutePaths.diary);
        case AuthStateUnauthenticated():
          // 未登录 → 跳转到登录页
          context.go(RoutePaths.login);
        case AuthStateError():
          // 认证检查出错 → 跳转到登录页
          context.go(RoutePaths.login);
        default:
          // 初始化中或加载中，继续显示闪屏
          break;
      }
    });

    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // ------------------------------------------------
            // 应用 Logo
            // ------------------------------------------------
            // 使用太阳图标作为应用标识，传达"日常"的概念
            Icon(
              Icons.wb_sunny_outlined,
              size: 80,
              color: theme.colorScheme.primary,
            ),
            const SizedBox(height: 24),

            // ------------------------------------------------
            // 应用名称
            // ------------------------------------------------
            Text(
              AppConstants.appName,
              style: theme.textTheme.headlineLarge?.copyWith(
                color: theme.colorScheme.primary,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),

            // ------------------------------------------------
            // 应用副标题
            // ------------------------------------------------
            Text(
              '你的日常管理助手',
              style: theme.textTheme.bodyLarge?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 48),

            // ------------------------------------------------
            // 加载指示器
            // ------------------------------------------------
            SizedBox(
              width: 32,
              height: 32,
              child: CircularProgressIndicator(
                strokeWidth: 3,
                color: theme.colorScheme.primary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
