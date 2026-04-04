/// DayFlow 路由配置
///
/// 此文件使用 go_router 定义应用的完整路由结构，包括：
/// - 闪屏页（splash）→ 应用启动时显示
/// - 认证页面（login / register）→ 未登录时跳转
/// - 主页面（ShellRoute + 底部导航栏）→ 日记、规划、新闻三个标签页
/// - 日记编辑页（diary/edit）→ 新建或编辑日记条目
///
/// 路由守卫逻辑：
/// - 检查 Supabase 认证状态
/// - 未登录用户自动重定向到登录页
/// - 已登录用户访问登录/注册页时重定向到首页
///
/// 使用手动 Riverpod Provider（非代码生成）。
library;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:dayflow/features/auth/presentation/pages/account_select_page.dart';
import 'package:dayflow/features/diary/presentation/pages/diary_detail_page.dart';
import 'package:dayflow/features/diary/presentation/pages/diary_edit_page.dart';
import 'package:dayflow/features/diary/presentation/pages/diary_list_page.dart';
import 'package:dayflow/features/diary/presentation/pages/notebook_list_page.dart';
import 'package:dayflow/features/auth/presentation/pages/login_page.dart';
import 'package:dayflow/features/auth/presentation/pages/register_page.dart';
import 'package:dayflow/features/auth/presentation/pages/splash_page.dart';
import 'package:dayflow/features/news/presentation/pages/news_page.dart';
import 'package:dayflow/features/planner/presentation/pages/planner_page.dart';
import 'package:dayflow/features/profile/presentation/pages/profile_page.dart';
import 'package:dayflow/features/settings/presentation/pages/settings_page.dart';
import 'package:dayflow/shared/widgets/app_bottom_nav.dart';
import 'package:dayflow/shared/widgets/app_shell_scaffold.dart';

// ============================================================
// 路由路径常量
// ============================================================

/// 路由路径常量
///
/// 集中管理所有路由路径字符串，避免硬编码和拼写错误。
abstract class RoutePaths {
  /// 闪屏页
  static const String splash = '/splash';

  /// 登录页
  static const String login = '/login';

  /// 注册页
  static const String register = '/register';

  /// 启动账号选择页
  static const String accountSelect = '/account-select';

  /// 日记列表页（主页默认标签）
  static const String diary = '/diary';

  /// 日记编辑页，[id] 为可选参数：
  /// - 不传 id：新建日记
  /// - 传入 id：编辑已有日记
  static const String diaryEdit = '/diary/edit';

  /// 日记详情页
  static const String diaryView = '/diary/view';

  /// 规划页
  static const String planner = '/planner';

  /// 新闻页
  static const String news = '/news';

  /// 个人资料页
  static const String profile = '/profile';

  /// 设置页
  static const String settings = '/settings';
}

// ============================================================
// GoRouter 配置
// ============================================================

/// 创建应用路由器
///
/// 接收 [Ref] 参数以访问 Riverpod 的依赖注入系统，
/// 主要用于在路由守卫中检查认证状态。
///
/// 路由结构：
/// ```
/// /splash          → 闪屏页（占位）
/// /login           → 登录页（占位）
/// /register        → 注册页（占位）
/// /diary           → 日记列表（ShellRoute 内，带底部导航）
/// /diary/view/:id  → 日记详情页
/// /diary/edit      → 日记编辑页
/// /diary/edit/:id  → 编辑已有日记
/// /planner         → 规划页（ShellRoute 内，带底部导航）
/// /news            → 新闻页（ShellRoute 内，带底部导航）
/// ```
GoRouter createRouter(Ref ref) {
  return GoRouter(
    // 应用启动时的初始路由
    initialLocation: RoutePaths.accountSelect,

    // 路由调试日志（仅在 debug 模式下输出路由变化）
    debugLogDiagnostics: kDebugMode,

    // ----------------------------------------------------------
    // 全局路由守卫（重定向逻辑）
    // ----------------------------------------------------------
    redirect: (BuildContext context, GoRouterState state) {
      // 获取当前 Supabase 认证会话
      final session = Supabase.instance.client.auth.currentSession;
      final isLoggedIn = session != null;

      // 当前正在访问的路径
      final currentPath = state.matchedLocation;

      // 认证相关页面的路径集合
      final isAuthRoute =
          currentPath == RoutePaths.login || currentPath == RoutePaths.register;

      final isAccountSelectRoute = currentPath == RoutePaths.accountSelect;

      // 是否在闪屏页
      final isSplashRoute = currentPath == RoutePaths.splash;

      final isPublicRoute =
          isAuthRoute || isSplashRoute || isAccountSelectRoute;

      // 规则 1：闪屏页 → 根据登录状态跳转
      if (isSplashRoute) {
        return RoutePaths.accountSelect;
      }

      // 规则 2：未登录 + 非认证页面 → 跳转到登录页
      if (!isLoggedIn && !isPublicRoute) {
        return RoutePaths.login;
      }

      // 规则 3：已登录 + 认证页面 → 跳转到首页
      if (isLoggedIn && isAuthRoute) {
        return RoutePaths.diary;
      }

      // 其他情况不重定向，正常导航
      return null;
    },

    // ----------------------------------------------------------
    // 路由定义
    // ----------------------------------------------------------
    routes: [
      // 闪屏页路由 - 应用启动时显示，自动检查认证状态
      GoRoute(
        path: RoutePaths.splash,
        name: 'splash',
        builder: (context, state) => const SplashPage(),
      ),

      // 登录页路由 - 邮箱密码登录 + Google 第三方登录
      GoRoute(
        path: RoutePaths.login,
        name: 'login',
        builder: (context, state) {
          final prefilledEmail = state.uri.queryParameters['email'];
          return LoginPage(prefilledEmail: prefilledEmail);
        },
      ),

      GoRoute(
        path: RoutePaths.accountSelect,
        name: 'account-select',
        builder: (context, state) => const AccountSelectPage(),
      ),

      // 注册页路由 - 新用户注册（含密码强度提示）
      GoRoute(
        path: RoutePaths.register,
        name: 'register',
        builder: (context, state) => const RegisterPage(),
      ),

      // --------------------------------------------------------
      // 主页面 ShellRoute（带底部导航栏）
      // --------------------------------------------------------
      // ShellRoute 将底部导航栏包裹在子路由外层，
      // 切换标签时只替换内部内容，导航栏保持不变。
      ShellRoute(
        builder: (context, state, child) {
          // 根据当前路径计算选中的标签索引
          final currentIndex = calculateSelectedIndex(state.matchedLocation);

          return AppShellScaffold(
            child: child,
            currentIndex: currentIndex,
          );
        },
        routes: [
          // 日记本列表页（首页默认入口）
          GoRoute(
            path: RoutePaths.diary,
            name: 'diary',
            builder: (context, state) => const NotebookListPage(),
            routes: [
              // 日记本内的日记列表
              GoRoute(
                path: 'notebook/:notebookId',
                name: 'diary-notebook',
                builder: (context, state) {
                  final notebookId =
                      int.tryParse(state.pathParameters['notebookId'] ?? '');
                  return DiaryListPage(notebookId: notebookId);
                },
              ),
              // 日记详情
              GoRoute(
                path: 'view/:id',
                name: 'diary-view',
                builder: (context, state) {
                  final id = int.tryParse(state.pathParameters['id'] ?? '');
                  return DiaryDetailPage(diaryId: id ?? -1);
                },
              ),
              // 新建日记
              GoRoute(
                path: 'edit',
                name: 'diary-new',
                builder: (context, state) {
                  final notebookId = int.tryParse(
                      state.uri.queryParameters['notebookId'] ?? '');
                  return DiaryEditPage(notebookId: notebookId);
                },
              ),
              // 编辑已有日记（通过路径参数传递日记 ID）
              GoRoute(
                path: 'edit/:id',
                name: 'diary-edit',
                builder: (context, state) {
                  final id = int.tryParse(state.pathParameters['id'] ?? '');
                  return DiaryEditPage(diaryId: id);
                },
              ),
            ],
          ),

          // 规划页
          GoRoute(
            path: RoutePaths.planner,
            name: 'planner',
            builder: (context, state) => const PlannerPage(),
          ),

          // 新闻页
          GoRoute(
            path: RoutePaths.news,
            name: 'news',
            builder: (context, state) => const NewsPage(),
          ),
        ],
      ),

      GoRoute(
        path: RoutePaths.profile,
        name: 'profile',
        builder: (context, state) => const ProfilePage(),
      ),

      GoRoute(
        path: RoutePaths.settings,
        name: 'settings',
        builder: (context, state) => const SettingsPage(),
      ),
    ],
  );
}

// ============================================================
// Riverpod Provider（手动定义，非代码生成）
// ============================================================

/// GoRouter 实例 Provider
///
/// 在应用中通过此 Provider 获取路由器实例。
/// 在 [MaterialApp.router] 中使用：
/// ```dart
/// final router = ref.watch(routerProvider);
/// MaterialApp.router(routerConfig: router);
/// ```
final routerProvider = Provider<GoRouter>((ref) {
  return createRouter(ref);
});
