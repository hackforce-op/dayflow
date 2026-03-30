/// DayFlow 应用入口文件
///
/// 此文件是整个 DayFlow 应用的启动入口，负责：
/// 1. 初始化 Flutter 引擎绑定（WidgetsFlutterBinding）
/// 2. 初始化 Supabase 后端服务连接
/// 3. 使用 Riverpod 的 [ProviderScope] 包裹整个应用
/// 4. 创建并配置 [MaterialApp.router]，集成 go_router 路由
/// 5. 支持浅色/深色主题切换
///
/// 启动流程：
/// ```
/// main() → ensureInitialized → initSupabase → runApp
///   → ProviderScope → DayFlowApp → MaterialApp.router
/// ```
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:dayflow/core/constants/app_constants.dart';
import 'package:dayflow/core/supabase/supabase_client.dart';
import 'package:dayflow/core/theme/app_theme.dart';
import 'package:dayflow/core/theme/theme_provider.dart';
import 'package:dayflow/core/router/app_router.dart';

// ============================================================
// 应用启动入口
// ============================================================

/// 应用程序的主入口函数
///
/// 执行以下初始化步骤：
/// 1. 确保 Flutter 引擎绑定已初始化（异步操作前必须调用）
/// 2. 初始化 Supabase 客户端（连接后端服务）
/// 3. 启动应用，使用 [ProviderScope] 作为根节点以启用 Riverpod 状态管理
void main() async {
  // 步骤 1：确保 Flutter 引擎绑定已初始化
  // 在调用任何异步方法（如 Supabase 初始化）之前必须调用此方法
  WidgetsFlutterBinding.ensureInitialized();

  try {
    // 步骤 2：初始化 Supabase 后端连接
    // 使用 AppConstants 中配置的 URL 和匿名密钥
    await initializeSupabase();

    // 步骤 3：启动应用
    // ProviderScope 是 Riverpod 的根组件，存储所有 Provider 的状态
    runApp(
      const ProviderScope(
        child: DayFlowApp(),
      ),
    );
  } catch (error, stackTrace) {
    FlutterError.reportError(
      FlutterErrorDetails(
        exception: error,
        stack: stackTrace,
        library: 'dayflow',
      ),
    );

    runApp(
      StartupErrorApp(
        message: _formatStartupError(error),
      ),
    );
  }
}

String _formatStartupError(Object error) {
  if (error is StateError) {
    return error.message;
  }

  return '应用启动失败，请检查 Supabase 配置和网络连接。\n$error';
}

class StartupErrorApp extends StatelessWidget {
  const StartupErrorApp({
    super.key,
    required this.message,
  });

  final String message;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: AppConstants.appName,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      home: Scaffold(
        body: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 560),
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'DayFlow 启动失败',
                          style: Theme.of(context).textTheme.headlineSmall,
                        ),
                        const SizedBox(height: 12),
                        SelectableText(message),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ============================================================
// 应用根组件
// ============================================================

/// DayFlow 应用根组件
///
/// 使用 [ConsumerWidget] 替代 [StatelessWidget]，
/// 以便通过 [WidgetRef] 访问 Riverpod 的 Provider。
///
/// 主要职责：
/// - 配置 [MaterialApp.router] 作为应用的顶层 Widget
/// - 集成 go_router 提供声明式路由
/// - 根据用户偏好应用浅色或深色主题
/// - 设置应用标题和全局主题
class DayFlowApp extends ConsumerWidget {
  /// 创建 DayFlow 应用根组件
  const DayFlowApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // 监听路由器实例（当路由配置变化时自动重建）
    final router = ref.watch(routerProvider);

    // 监听当前主题模式（system / light / dark）
    final themeMode = ref.watch(themeModeProvider);

    return MaterialApp.router(
      // 应用标题（显示在任务管理器等系统界面中）
      title: AppConstants.appName,

      // 去掉右上角的 DEBUG 标签
      debugShowCheckedModeBanner: false,

      // ----------------------------------------------------------
      // 主题配置
      // ----------------------------------------------------------

      /// 浅色主题（Material 3 设计）
      theme: AppTheme.lightTheme,

      /// 深色主题（Material 3 设计）
      darkTheme: AppTheme.darkTheme,

      /// 当前主题模式：根据用户偏好切换
      /// - ThemeMode.system：跟随系统设置
      /// - ThemeMode.light：强制浅色
      /// - ThemeMode.dark：强制深色
      themeMode: themeMode,

      // ----------------------------------------------------------
      // 路由配置（go_router）
      // ----------------------------------------------------------

      /// 使用 go_router 的路由配置
      routerConfig: router,
    );
  }
}
