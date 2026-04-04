library;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:dayflow/core/constants/app_constants.dart';
import 'package:dayflow/core/theme/app_theme.dart';

class ThemePresetNotifier extends StateNotifier<ThemePreset> {
  ThemePresetNotifier() : super(ThemePreset.seaBreeze) {
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final value = prefs.getString(AppConstants.themePresetPrefsKey);
    if (value == null) {
      return;
    }

    state = ThemePreset.values.firstWhere(
      (item) => item.name == value,
      orElse: () => ThemePreset.seaBreeze,
    );
  }

  Future<void> setPreset(ThemePreset preset) async {
    state = preset;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(AppConstants.themePresetPrefsKey, preset.name);
  }
}

final themePresetProvider =
    StateNotifierProvider<ThemePresetNotifier, ThemePreset>((ref) {
  return ThemePresetNotifier();
});
