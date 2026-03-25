/// DayFlow 全局 Provider 桶文件（Barrel File）
///
/// 此文件集中导出应用中所有的 Riverpod Provider，
/// 方便其他模块统一导入使用。
///
/// 使用方式：
/// ```dart
/// import 'package:dayflow/core/providers/providers.dart';
/// ```
///
/// 同时定义了一些共享的工具类 Provider，
/// 例如网络连接状态等全局通用的状态管理。
library;

// ============================================================
// 导出所有 Provider 模块
// ============================================================

/// Supabase 相关 Provider（客户端、认证、认证状态流）
export 'package:dayflow/core/supabase/supabase_client.dart';

/// 主题相关 Provider（主题模式状态管理）
export 'package:dayflow/core/theme/theme_provider.dart';

/// 路由 Provider（GoRouter 实例）
export 'package:dayflow/core/router/app_router.dart';
