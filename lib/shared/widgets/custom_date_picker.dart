/// DayFlow - 自定义日期选择器（内置农历开关）
///
/// 替代系统 showDatePicker，在弹窗内部提供：
/// - 月/年导航（◀ 年月 ▶）
/// - 日历网格（显示公历日期，农历开启时同时显示农历日期）
/// - 底部"农历"开关（切换后实时更新日历显示）
/// - 农历偏好自动用 SharedPreferences 持久化
///
/// 用法：
/// ```dart
/// final picked = await showCustomDatePicker(
///   context: context,
///   initialDate: DateTime.now(),
///   firstDate: DateTime(2000),
///   lastDate: DateTime(2100),
/// );
/// ```
library;

import 'package:flutter/material.dart';
import 'package:lunar/lunar.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:dayflow/core/constants/app_constants.dart';
import 'package:dayflow/shared/widgets/blur_dialog.dart';

// ============================================================
// 公开入口函数
// ============================================================

/// 显示自带农历开关的日期选择弹窗
///
/// 参数与 Flutter 内置 [showDatePicker] 保持一致。
/// 返回用户选择的 [DateTime]，取消则返回 null。
Future<DateTime?> showCustomDatePicker({
  required BuildContext context,
  required DateTime initialDate,
  required DateTime firstDate,
  required DateTime lastDate,
}) {
  return showBlurDialog<DateTime>(
    context: context,
    builder: (ctx) => _CustomDatePickerContent(
      initialDate: initialDate,
      firstDate: firstDate,
      lastDate: lastDate,
    ),
  );
}

// ============================================================
// 内部日历弹窗内容
// ============================================================

/// 日历弹窗主体
///
/// 是一个 StatefulWidget，独立管理：
/// - 当前显示的年/月
/// - 已选中的日期
/// - 农历显示开关
class _CustomDatePickerContent extends StatefulWidget {
  final DateTime initialDate;
  final DateTime firstDate;
  final DateTime lastDate;

  const _CustomDatePickerContent({
    required this.initialDate,
    required this.firstDate,
    required this.lastDate,
  });

  @override
  State<_CustomDatePickerContent> createState() =>
      _CustomDatePickerContentState();
}

class _CustomDatePickerContentState extends State<_CustomDatePickerContent> {
  /// 当前显示的年份
  late int _displayYear;

  /// 当前显示的月份（1-12）
  late int _displayMonth;

  /// 当前选中的日期
  late DateTime _selectedDate;

  /// 是否开启农历显示
  bool _showLunar = false;

  @override
  void initState() {
    super.initState();
    _selectedDate = widget.initialDate;
    _displayYear = widget.initialDate.year;
    _displayMonth = widget.initialDate.month;
    _loadLunarPreference();
  }

  /// 从 SharedPreferences 加载农历偏好
  Future<void> _loadLunarPreference() async {
    final prefs = await SharedPreferences.getInstance();
    final enabled =
        prefs.getBool(AppConstants.lunarCalendarPrefsKey) ?? false;
    if (mounted) setState(() => _showLunar = enabled);
  }

  /// 保存农历偏好到 SharedPreferences
  Future<void> _saveLunarPreference(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(AppConstants.lunarCalendarPrefsKey, value);
  }

  /// 上一月
  void _prevMonth() {
    setState(() {
      if (_displayMonth == 1) {
        _displayMonth = 12;
        _displayYear--;
      } else {
        _displayMonth--;
      }
    });
  }

  /// 下一月
  void _nextMonth() {
    setState(() {
      if (_displayMonth == 12) {
        _displayMonth = 1;
        _displayYear++;
      } else {
        _displayMonth++;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Material(
      borderRadius: BorderRadius.circular(16),
      clipBehavior: Clip.antiAlias,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 340),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // ─── 顶部：年月导航 ───
              _buildMonthNavigator(theme),
              const SizedBox(height: 8),
              // ─── 星期标题行 ───
              _buildWeekdayHeader(theme),
              const SizedBox(height: 4),
              // ─── 日期网格 ───
              _buildDayGrid(theme),
              const Divider(height: 16),
              // ─── 底部：农历开关 + 取消/确认 ───
              _buildFooter(theme),
            ],
          ),
        ),
      ),
    );
  }

  /// 年月导航行（◀ 2025年6月 ▶）
  Widget _buildMonthNavigator(ThemeData theme) {
    // 判断是否可以继续翻页
    final canGoBack = DateTime(_displayYear, _displayMonth)
        .isAfter(DateTime(widget.firstDate.year, widget.firstDate.month));
    final canGoForward = DateTime(_displayYear, _displayMonth)
        .isBefore(DateTime(widget.lastDate.year, widget.lastDate.month));

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        // 上一月按钮
        IconButton(
          onPressed: canGoBack ? _prevMonth : null,
          icon: const Icon(Icons.chevron_left),
          splashRadius: 20,
        ),
        // 年月标题（点击可快速跳转功能预留位）
        Text(
          '$_displayYear年$_displayMonth月',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        // 下一月按钮
        IconButton(
          onPressed: canGoForward ? _nextMonth : null,
          icon: const Icon(Icons.chevron_right),
          splashRadius: 20,
        ),
      ],
    );
  }

  /// 星期标题行（日 一 二 三 四 五 六）
  Widget _buildWeekdayHeader(ThemeData theme) {
    const weekdayLabels = ['日', '一', '二', '三', '四', '五', '六'];
    return Row(
      children: weekdayLabels.map((label) {
        return Expanded(
          child: Center(
            child: Text(
              label,
              style: theme.textTheme.labelSmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  /// 日历网格（含农历文字）
  Widget _buildDayGrid(ThemeData theme) {
    // 当月第一天是星期几（0=周日，1=周一 ... 6=周六）
    final firstDayOfMonth = DateTime(_displayYear, _displayMonth, 1);
    final firstWeekday = firstDayOfMonth.weekday % 7; // 转换为从周日开始

    // 当月总天数
    final daysInMonth = DateTime(_displayYear, _displayMonth + 1, 0).day;

    // 网格总格数（前置空格 + 当月天数），凑整为 7 的倍数
    final totalCells =
        (firstWeekday + daysInMonth + 6) ~/ 7 * 7;

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 7,
        mainAxisExtent: 48, // 每格高度固定
      ),
      itemCount: totalCells,
      itemBuilder: (context, index) {
        final dayNumber = index - firstWeekday + 1;

        // 空白格
        if (dayNumber < 1 || dayNumber > daysInMonth) {
          return const SizedBox.shrink();
        }

        final cellDate = DateTime(_displayYear, _displayMonth, dayNumber);

        // 是否超出允许范围
        final isEnabled = !cellDate.isBefore(
                DateTime(widget.firstDate.year, widget.firstDate.month,
                    widget.firstDate.day)) &&
            !cellDate.isAfter(DateTime(widget.lastDate.year,
                widget.lastDate.month, widget.lastDate.day));

        // 是否为选中日
        final isSelected = cellDate.year == _selectedDate.year &&
            cellDate.month == _selectedDate.month &&
            cellDate.day == _selectedDate.day;

        // 是否为今天
        final today = DateTime.now();
        final isToday = cellDate.year == today.year &&
            cellDate.month == today.month &&
            cellDate.day == today.day;

        // 获取农历日期标签（仅在开启农历时计算）
        final lunarLabel = _showLunar ? _getLunarDayLabel(cellDate) : null;

        return _DayCell(
          day: dayNumber,
          lunarLabel: lunarLabel,
          isSelected: isSelected,
          isToday: isToday,
          isEnabled: isEnabled,
          onTap: isEnabled
              ? () => setState(() => _selectedDate = cellDate)
              : null,
        );
      },
    );
  }

  /// 底部操作栏：农历开关 + 取消/确认按钮
  Widget _buildFooter(ThemeData theme) {
    return Row(
      children: [
        // 农历开关
        const Text('农历'),
        const SizedBox(width: 4),
        Switch(
          value: _showLunar,
          onChanged: (value) {
            setState(() => _showLunar = value);
            _saveLunarPreference(value);
          },
        ),
        const Spacer(),
        // 取消按钮
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('取消'),
        ),
        // 确认按钮
        FilledButton(
          onPressed: () => Navigator.of(context).pop(_selectedDate),
          child: const Text('确认'),
        ),
      ],
    );
  }

  /// 获取农历日期标签：初一显示月份，其余显示日
  ///
  /// 若是节气或节日则优先显示节气/节日名称（最多 2 字）。
  String _getLunarDayLabel(DateTime date) {
    try {
      final lunar = Lunar.fromDate(date);
      final day = lunar.getDay();

      // 初一：显示农历月份
      if (day == 1) {
        return lunar.getMonthInChinese();
      }

      // 节日：优先展示（最多取第一个，截取前 2 字）
      final festivals = lunar.getFestivals();
      if (festivals.isNotEmpty) {
        final f = festivals[0];
        return f.length > 2 ? f.substring(0, 2) : f;
      }

      // 节气：优先展示
      final jieQi = lunar.getJieQi();
      if (jieQi.isNotEmpty) {
        return jieQi.length > 2 ? jieQi.substring(0, 2) : jieQi;
      }

      // 普通日期
      return lunar.getDayInChinese();
    } catch (_) {
      // lunar 包偶发异常时降级处理
      return '';
    }
  }
}

// ============================================================
// 单日格子组件
// ============================================================

/// 日历中的单日格子
class _DayCell extends StatelessWidget {
  final int day;
  final String? lunarLabel;
  final bool isSelected;
  final bool isToday;
  final bool isEnabled;
  final VoidCallback? onTap;

  const _DayCell({
    required this.day,
    this.lunarLabel,
    required this.isSelected,
    required this.isToday,
    required this.isEnabled,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    Color? bgColor;
    Color textColor = isEnabled
        ? theme.colorScheme.onSurface
        : theme.colorScheme.onSurface.withAlpha(80);

    if (isSelected) {
      bgColor = theme.colorScheme.primary;
      textColor = theme.colorScheme.onPrimary;
    } else if (isToday) {
      bgColor = theme.colorScheme.primaryContainer;
      textColor = theme.colorScheme.onPrimaryContainer;
    }

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.all(2),
        decoration: BoxDecoration(
          color: bgColor,
          shape: BoxShape.circle,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // 公历日期
            Text(
              '$day',
              style: theme.textTheme.bodySmall?.copyWith(
                color: textColor,
                fontWeight:
                    isSelected || isToday ? FontWeight.bold : FontWeight.normal,
                height: 1.1,
              ),
            ),
            // 农历标签（可选）
            if (lunarLabel != null)
              Text(
                lunarLabel!,
                style: TextStyle(
                  fontSize: 8,
                  color: isSelected
                      ? theme.colorScheme.onPrimary.withAlpha(200)
                      : theme.colorScheme.tertiary,
                  height: 1.1,
                ),
                overflow: TextOverflow.visible,
              ),
          ],
        ),
      ),
    );
  }
}
