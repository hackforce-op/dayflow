/// DayFlow 应用主题配置（全面升级版）
///
/// 设计理念：现代感、层次感、品质感
/// - 四套色系均采用更饱满的种子颜色，视觉辨识度更高
/// - 深色模式下使用更亮的主色，确保暗背景可读性
/// - 卡片 / 按钮 / 输入框全部使用 16px 大圆角
/// - 新增 NavigationBar、FilledButton、Chip、Divider、ListTile 主题
library;

import 'package:flutter/material.dart';

// ============================================================
// 主题预设枚举
// ============================================================

/// 主题风格预设
///
/// 每套色系都有专属中文名称，颜色更饱满有个性。
enum ThemePreset {
  /// 星空蓝 — 深邃专业的深蓝色调
  seaBreeze,

  /// 晨曦橙 — 活力温暖的橙红色调
  sunrise,

  /// 翡翠绿 — 清新自然的祖母绿色调
  forest,

  /// 幻紫 — 时尚现代的紫罗兰色调
  graphite,
}

extension ThemePresetLabel on ThemePreset {
  String get label {
    return switch (this) {
      ThemePreset.seaBreeze => '星空蓝',
      ThemePreset.sunrise => '晨曦橙',
      ThemePreset.forest => '翡翠绿',
      ThemePreset.graphite => '幻紫',
    };
  }
}

// ============================================================
// 内部色盘结构
// ============================================================

class _ThemePalette {
  final Color lightSeed;
  final Color darkSeed;
  final Color secondary;
  final Color tertiary;

  const _ThemePalette({
    required this.lightSeed,
    required this.darkSeed,
    required this.secondary,
    required this.tertiary,
  });
}

// ============================================================
// 应用主题类
// ============================================================

/// 应用主题配置类
///
/// 提供浅色/深色两套主题，基于 Material 3 设计规范。
abstract class AppTheme {
  static const String _fontFamily = 'NotoSansCJKsc';
  static const List<String> _fontFamilyFallback = <String>[
    'Noto Sans CJK SC',
    'Noto Sans SC',
    'Source Han Sans SC',
    'Microsoft YaHei',
    'PingFang SC',
    'Heiti SC',
    'WenQuanYi Micro Hei',
    'Noto Color Emoji',
    'Segoe UI Emoji',
    'Apple Color Emoji',
    'sans-serif',
  ];

  static _ThemePalette _paletteForPreset(ThemePreset preset) {
    return switch (preset) {
      // 星空蓝：深邃蓝色主调，青绿辅助，珊瑚点缀
      ThemePreset.seaBreeze => const _ThemePalette(
          lightSeed: Color(0xFF1864AB),
          darkSeed: Color(0xFF74C0FC),
          secondary: Color(0xFF0CA678),
          tertiary: Color(0xFFFF6B6B),
        ),
      // 晨曦橙：暖红主调，琥珀辅助，玫红点缀
      ThemePreset.sunrise => const _ThemePalette(
          lightSeed: Color(0xFFC92A2A),
          darkSeed: Color(0xFFFF8787),
          secondary: Color(0xFFE67700),
          tertiary: Color(0xFFCC5DE8),
        ),
      // 翡翠绿：祖母绿主调，深绿辅助，蓝色点缀
      ThemePreset.forest => const _ThemePalette(
          lightSeed: Color(0xFF087F5B),
          darkSeed: Color(0xFF63E6BE),
          secondary: Color(0xFF2B8A3E),
          tertiary: Color(0xFF1971C2),
        ),
      // 幻紫：紫罗兰主调，靛蓝辅助，青绿点缀
      ThemePreset.graphite => const _ThemePalette(
          lightSeed: Color(0xFF6741D9),
          darkSeed: Color(0xFFB197FC),
          secondary: Color(0xFF3B5BDB),
          tertiary: Color(0xFF0CA678),
        ),
    };
  }

  // ============================================================
  // 浅色主题
  // ============================================================

  static ThemeData lightTheme({ThemePreset preset = ThemePreset.seaBreeze}) {
    final palette = _paletteForPreset(preset);
    final colorScheme = ColorScheme.fromSeed(
      seedColor: palette.lightSeed,
      brightness: Brightness.light,
      secondary: palette.secondary,
      tertiary: palette.tertiary,
    );
    return _buildTheme(colorScheme, Brightness.light);
  }

  // ============================================================
  // 深色主题
  // ============================================================

  static ThemeData darkTheme({ThemePreset preset = ThemePreset.seaBreeze}) {
    final palette = _paletteForPreset(preset);
    final colorScheme = ColorScheme.fromSeed(
      seedColor: palette.darkSeed,
      brightness: Brightness.dark,
      secondary: palette.secondary,
      tertiary: palette.tertiary,
    );
    return _buildTheme(colorScheme, Brightness.dark);
  }

  // ============================================================
  // 公共主题构建
  // ============================================================

  /// 根据色系和亮度构建统一的 ThemeData
  static ThemeData _buildTheme(ColorScheme colorScheme, Brightness brightness) {
    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      fontFamily: _fontFamily,
      brightness: brightness,

      // ── AppBar ────────────────────────────────────────────
      appBarTheme: AppBarTheme(
        centerTitle: false,
        elevation: 0,
        scrolledUnderElevation: 1,
        backgroundColor: colorScheme.surface,
        surfaceTintColor: colorScheme.surfaceTint,
        foregroundColor: colorScheme.onSurface,
        titleTextStyle: _textStyle(
          color: colorScheme.onSurface,
          fontSize: 20,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.3,
        ),
        iconTheme: IconThemeData(color: colorScheme.onSurfaceVariant),
        actionsIconTheme: IconThemeData(color: colorScheme.onSurfaceVariant),
      ),

      // ── 卡片：更大圆角 + 明显阴影 ─────────────────────────
      cardTheme: CardThemeData(
        elevation: 2,
        shadowColor: colorScheme.shadow.withAlpha(60),
        surfaceTintColor: colorScheme.surfaceTint,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        clipBehavior: Clip.antiAlias,
      ),

      // ── NavigationBar（移动端底部导航） ────────────────────
      navigationBarTheme: NavigationBarThemeData(
        elevation: 4,
        height: 72,
        backgroundColor: colorScheme.surface,
        surfaceTintColor: colorScheme.surfaceTint,
        shadowColor: colorScheme.shadow.withAlpha(40),
        indicatorColor: colorScheme.primaryContainer,
        indicatorShape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          final isSelected = states.contains(WidgetState.selected);
          return _textStyle(
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
            color: isSelected
                ? colorScheme.primary
                : colorScheme.onSurfaceVariant,
          );
        }),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          final isSelected = states.contains(WidgetState.selected);
          return IconThemeData(
            color: isSelected
                ? colorScheme.onPrimaryContainer
                : colorScheme.onSurfaceVariant,
            size: 24,
          );
        }),
      ),

      // ── FilledButton ─────────────────────────────────────
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: _textStyle(fontSize: 14, fontWeight: FontWeight.w600),
        ),
      ),

      // ── ElevatedButton ────────────────────────────────────
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          elevation: 2,
          shadowColor: colorScheme.shadow.withAlpha(80),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: _textStyle(fontSize: 14, fontWeight: FontWeight.w600),
        ),
      ),

      // ── OutlinedButton ────────────────────────────────────
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          side: BorderSide(color: colorScheme.outline),
          textStyle: _textStyle(fontSize: 14, fontWeight: FontWeight.w500),
        ),
      ),

      // ── TextButton ────────────────────────────────────────
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      ),

      // ── 输入框 ────────────────────────────────────────────
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: brightness == Brightness.light
            ? colorScheme.surfaceContainerHighest.withAlpha(120)
            : colorScheme.surfaceContainer,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: colorScheme.primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: colorScheme.error, width: 1.5),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: colorScheme.error, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
        floatingLabelStyle: TextStyle(
          color: colorScheme.primary,
          fontWeight: FontWeight.w500,
        ),
      ),

      // ── Chip / ChoiceChip ─────────────────────────────────
      chipTheme: ChipThemeData(
        backgroundColor: colorScheme.surfaceContainerHighest,
        selectedColor: colorScheme.primaryContainer,
        disabledColor: colorScheme.surfaceContainerLowest,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        labelPadding: const EdgeInsets.symmetric(horizontal: 4),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        side: BorderSide.none,
        labelStyle: _textStyle(
          fontSize: 13,
          fontWeight: FontWeight.w500,
          color: colorScheme.onSurface,
        ),
        checkmarkColor: colorScheme.onPrimaryContainer,
      ),

      // ── FloatingActionButton ─────────────────────────────
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: colorScheme.primary,
        foregroundColor: colorScheme.onPrimary,
        elevation: 4,
        focusElevation: 6,
        hoverElevation: 6,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
        ),
      ),

      // ── Divider ───────────────────────────────────────────
      dividerTheme: DividerThemeData(
        color: colorScheme.outlineVariant,
        thickness: 1,
        space: 1,
      ),

      // ── ListTile ──────────────────────────────────────────
      listTileTheme: ListTileThemeData(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        tileColor: Colors.transparent,
        selectedTileColor: colorScheme.primaryContainer.withAlpha(80),
        selectedColor: colorScheme.primary,
        iconColor: colorScheme.onSurfaceVariant,
      ),

      // ── SnackBar ──────────────────────────────────────────
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        backgroundColor: colorScheme.inverseSurface,
        contentTextStyle: _textStyle(
          fontSize: 14,
          color: colorScheme.onInverseSurface,
        ),
        elevation: 6,
      ),

      // ── Dialog ────────────────────────────────────────────
      dialogTheme: DialogThemeData(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        elevation: 8,
        shadowColor: colorScheme.shadow.withAlpha(100),
        backgroundColor: colorScheme.surface,
        surfaceTintColor: colorScheme.surfaceTint,
        titleTextStyle: _textStyle(
          fontSize: 18,
          fontWeight: FontWeight.w700,
          color: colorScheme.onSurface,
        ),
        contentTextStyle: _textStyle(
          fontSize: 14,
          color: colorScheme.onSurfaceVariant,
          height: 1.6,
        ),
      ),

      // ── Switch ────────────────────────────────────────────
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return colorScheme.primary;
          }
          return colorScheme.outline;
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return colorScheme.primaryContainer;
          }
          return colorScheme.surfaceContainerHighest;
        }),
      ),

      // ── 文字排版 ──────────────────────────────────────────
      textTheme: _buildTextTheme(colorScheme),
    );
  }

  // ============================================================
  // 文字排版
  // ============================================================

  static TextStyle _textStyle({
    double? fontSize,
    FontWeight? fontWeight,
    Color? color,
    double? letterSpacing,
    double? height,
  }) {
    return TextStyle(
      fontFamily: _fontFamily,
      fontFamilyFallback: _fontFamilyFallback,
      fontSize: fontSize,
      fontWeight: fontWeight,
      color: color,
      letterSpacing: letterSpacing,
      height: height,
    );
  }

  static TextTheme _buildTextTheme(ColorScheme colorScheme) {
    return TextTheme(
      headlineLarge: _textStyle(
        fontSize: 30,
        fontWeight: FontWeight.bold,
        color: colorScheme.onSurface,
        letterSpacing: -0.5,
      ),
      headlineMedium: _textStyle(
        fontSize: 24,
        fontWeight: FontWeight.w700,
        color: colorScheme.onSurface,
        letterSpacing: -0.3,
      ),
      headlineSmall: _textStyle(
        fontSize: 20,
        fontWeight: FontWeight.w700,
        color: colorScheme.onSurface,
      ),
      titleLarge: _textStyle(
        fontSize: 18,
        fontWeight: FontWeight.w600,
        color: colorScheme.onSurface,
      ),
      titleMedium: _textStyle(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: colorScheme.onSurface,
      ),
      titleSmall: _textStyle(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: colorScheme.onSurfaceVariant,
        letterSpacing: 0.3,
      ),
      bodyLarge: _textStyle(
        fontSize: 16,
        fontWeight: FontWeight.normal,
        color: colorScheme.onSurface,
        height: 1.6,
      ),
      bodyMedium: _textStyle(
        fontSize: 14,
        fontWeight: FontWeight.normal,
        color: colorScheme.onSurface,
        height: 1.6,
      ),
      bodySmall: _textStyle(
        fontSize: 12,
        fontWeight: FontWeight.normal,
        color: colorScheme.onSurfaceVariant,
        height: 1.5,
      ),
      labelLarge: _textStyle(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: colorScheme.onSurface,
      ),
      labelMedium: _textStyle(
        fontSize: 12,
        fontWeight: FontWeight.w500,
        color: colorScheme.onSurfaceVariant,
      ),
      labelSmall: _textStyle(
        fontSize: 11,
        fontWeight: FontWeight.w500,
        color: colorScheme.onSurfaceVariant,
        letterSpacing: 0.5,
      ),
    );
  }
}
