/// DayFlow 主题状态管理
///
/// 此文件使用 Riverpod 的 [StateNotifier] 管理应用的主题模式，包括：
/// - 三种主题模式：跟随系统、浅色模式、深色模式
/// - 使用 [SharedPreferences] 持久化用户的主题偏好
/// - 应用启动时自动恢复上次的主题设置
///
/// 架构说明：
/// - [ThemeModeNotifier] 继承 [StateNotifier<ThemeMode>]，管理主题状态
/// - [themeModeProvider] 是全局的 StateNotifierProvider
/// - 主题切换会自动保存到本地存储
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:dayflow/core/constants/app_constants.dart';

// ============================================================
// 主题模式状态管理器
// ============================================================

/// 主题模式状态管理器
///
/// 使用 [StateNotifier] 管理 [ThemeMode] 状态，
/// 并通过 [SharedPreferences] 实现主题偏好的持久化存储。
///
/// 支持三种模式：
/// - [ThemeMode.system]：跟随系统设置
/// - [ThemeMode.light]：始终使用浅色主题
/// - [ThemeMode.dark]：始终使用深色主题
class ThemeModeNotifier extends StateNotifier<ThemeMode> {
  /// 创建主题模式管理器
  ///
  /// 初始默认为跟随系统设置，然后异步加载用户保存的偏好。
  ThemeModeNotifier() : super(ThemeMode.system) {
    _loadThemeMode();
  }

  /// 从 SharedPreferences 加载已保存的主题模式
  ///
  /// 读取存储的主题模式字符串，转换为对应的 [ThemeMode] 枚举值。
  /// 如果没有保存的偏好或读取失败，保持默认的 system 模式。
  Future<void> _loadThemeMode() async {
    final prefs = await SharedPreferences.getInstance();
    final themeModeString = prefs.getString(AppConstants.themePrefsKey);

    if (themeModeString != null) {
      state = _themeModeFromString(themeModeString);
    }
  }

  /// 设置新的主题模式
  ///
  /// 更新内存中的状态，并异步保存到 SharedPreferences。
  /// [mode] 要设置的新主题模式
  Future<void> setThemeMode(ThemeMode mode) async {
    state = mode;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      AppConstants.themePrefsKey,
      _themeModeToString(mode),
    );
  }

  /// 在系统/浅色/深色三种模式之间循环切换
  ///
  /// 切换顺序：system → light → dark → system
  /// 适合用在设置页面的快捷切换按钮。
  Future<void> toggleThemeMode() async {
    final nextMode = switch (state) {
      ThemeMode.system => ThemeMode.light,
      ThemeMode.light => ThemeMode.dark,
      ThemeMode.dark => ThemeMode.system,
    };
    await setThemeMode(nextMode);
  }

  /// 将 [ThemeMode] 枚举转换为字符串，用于持久化存储
  String _themeModeToString(ThemeMode mode) {
    return switch (mode) {
      ThemeMode.system => 'system',
      ThemeMode.light => 'light',
      ThemeMode.dark => 'dark',
    };
  }

  /// 将字符串转换为 [ThemeMode] 枚举，用于从存储中恢复
  ThemeMode _themeModeFromString(String value) {
    return switch (value) {
      'light' => ThemeMode.light,
      'dark' => ThemeMode.dark,
      _ => ThemeMode.system,
    };
  }
}

// ============================================================
// Riverpod Provider（手动定义，非代码生成）
// ============================================================

/// 主题模式 Provider
///
/// 全局状态管理器，管理应用的 [ThemeMode]。
/// 在 [MaterialApp] 中使用 `ref.watch(themeModeProvider)` 获取当前主题模式。
///
/// 使用方式：
/// ```dart
/// // 读取当前主题
/// final themeMode = ref.watch(themeModeProvider);
///
/// // 切换主题
/// ref.read(themeModeProvider.notifier).toggleThemeMode();
///
/// // 设置指定主题
/// ref.read(themeModeProvider.notifier).setThemeMode(ThemeMode.dark);
/// ```
final themeModeProvider =
    StateNotifierProvider<ThemeModeNotifier, ThemeMode>((ref) {
  return ThemeModeNotifier();
});
