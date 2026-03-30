/// DayFlow Supabase 客户端初始化与访问
///
/// 此文件负责管理 Supabase 后端服务的初始化和访问，包括：
/// - Supabase 客户端的初始化（在应用启动时调用）
/// - 通过 Riverpod Provider 全局暴露 Supabase 客户端实例
/// - 便捷的辅助方法，快速访问认证、数据库、存储等子服务
///
/// Supabase 提供了以下后端能力：
/// - 用户认证（邮箱/密码、OAuth）
/// - PostgreSQL 数据库（通过 REST API 访问）
/// - 实时数据订阅（Realtime）
/// - 文件存储（Storage）
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:dayflow/core/constants/app_constants.dart';

// ============================================================
// Supabase 初始化
// ============================================================

/// 初始化 Supabase 客户端
///
/// 必须在 [main] 函数中、[runApp] 之前调用此方法。
/// 使用 [AppConstants] 中配置的 URL 和匿名密钥进行初始化。
///
/// 示例：
/// ```dart
/// void main() async {
///   WidgetsFlutterBinding.ensureInitialized();
///   await initializeSupabase();
///   runApp(const ProviderScope(child: DayFlowApp()));
/// }
/// ```
Future<void> initializeSupabase() async {
  AppConstants.validateSupabaseConfiguration();

  await Supabase.initialize(
    url: AppConstants.supabaseUrl,
    anonKey: AppConstants.supabaseAnonKey,
  );
}

// ============================================================
// Riverpod Providers（手动定义，非代码生成）
// ============================================================

/// Supabase 客户端 Provider
///
/// 提供全局单例的 [SupabaseClient] 实例。
/// 通过 [Supabase.instance.client] 获取已初始化的客户端。
///
/// 使用方式：
/// ```dart
/// final client = ref.watch(supabaseClientProvider);
/// final data = await client.from('table').select();
/// ```
final supabaseClientProvider = Provider<SupabaseClient>((ref) {
  return Supabase.instance.client;
});

/// Supabase 认证服务 Provider
///
/// 提供 [GoTrueClient] 实例，用于用户认证相关操作：
/// - 登录 / 注册 / 登出
/// - 获取当前用户信息
/// - 监听认证状态变化
///
/// 使用方式：
/// ```dart
/// final auth = ref.watch(supabaseAuthProvider);
/// final user = auth.currentUser;
/// ```
final supabaseAuthProvider = Provider<GoTrueClient>((ref) {
  return ref.watch(supabaseClientProvider).auth;
});

/// 当前认证状态 Provider（流式）
///
/// 监听 Supabase 的认证状态变化事件流，
/// 当用户登录、登出或 token 刷新时自动通知。
///
/// 使用方式：
/// ```dart
/// final authState = ref.watch(authStateChangesProvider);
/// authState.when(
///   data: (state) => ...,
///   loading: () => ...,
///   error: (e, s) => ...,
/// );
/// ```
final authStateChangesProvider = StreamProvider<AuthState>((ref) {
  return ref.watch(supabaseClientProvider).auth.onAuthStateChange;
});
