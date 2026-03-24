/// DayFlow 日期格式化工具类
///
/// 此文件提供常用的日期格式化方法，包括：
/// - 标准日期格式化（年-月-日、月-日等）
/// - 相对时间显示（刚刚、几分钟前、几小时前等）
/// - 友好的中文日期描述（今天、昨天、前天等）
/// - 日记和规划模块专用的格式化方法
///
/// 使用 [intl] 包进行国际化日期格式化。
library;

import 'package:intl/intl.dart';

/// 日期格式化工具类
///
/// 所有方法均为静态方法，无需实例化即可使用。
/// 示例：
/// ```dart
/// final formatted = AppDateUtils.formatDate(DateTime.now());
/// final relative = AppDateUtils.relativeTime(someDateTime);
/// ```
abstract class AppDateUtils {
  // ============================================================
  // 预定义的日期格式化器
  // ============================================================

  /// 完整日期格式：2024-01-15
  static final DateFormat _fullDateFormat = DateFormat('yyyy-MM-dd');

  /// 中文日期格式：2024年1月15日
  static final DateFormat _chineseDateFormat = DateFormat('yyyy年M月d日');

  /// 月日格式：1月15日
  static final DateFormat _monthDayFormat = DateFormat('M月d日');

  /// 时间格式：14:30
  static final DateFormat _timeFormat = DateFormat('HH:mm');

  /// 完整日期时间格式：2024-01-15 14:30
  static final DateFormat _dateTimeFormat = DateFormat('yyyy-MM-dd HH:mm');

  /// 中文星期名称映射
  static const List<String> _weekdayNames = [
    '星期一',
    '星期二',
    '星期三',
    '星期四',
    '星期五',
    '星期六',
    '星期日',
  ];

  // ============================================================
  // 基础格式化方法
  // ============================================================

  /// 格式化为完整日期字符串
  ///
  /// 输出格式：2024-01-15
  /// [date] 要格式化的日期
  static String formatDate(DateTime date) {
    return _fullDateFormat.format(date);
  }

  /// 格式化为中文日期字符串
  ///
  /// 输出格式：2024年1月15日
  /// [date] 要格式化的日期
  static String formatChineseDate(DateTime date) {
    return _chineseDateFormat.format(date);
  }

  /// 格式化为月日字符串
  ///
  /// 输出格式：1月15日
  /// [date] 要格式化的日期
  static String formatMonthDay(DateTime date) {
    return _monthDayFormat.format(date);
  }

  /// 格式化为时间字符串
  ///
  /// 输出格式：14:30
  /// [date] 要格式化的日期时间
  static String formatTime(DateTime date) {
    return _timeFormat.format(date);
  }

  /// 格式化为完整日期时间字符串
  ///
  /// 输出格式：2024-01-15 14:30
  /// [date] 要格式化的日期时间
  static String formatDateTime(DateTime date) {
    return _dateTimeFormat.format(date);
  }

  // ============================================================
  // 中文星期相关
  // ============================================================

  /// 获取中文星期名称
  ///
  /// 返回：星期一 到 星期日
  /// [date] 要获取星期的日期
  static String getWeekday(DateTime date) {
    // DateTime.weekday 返回 1（周一）到 7（周日），防御性边界检查
    final index = date.weekday - 1;
    if (index < 0 || index >= _weekdayNames.length) return '未知';
    return _weekdayNames[index];
  }

  /// 格式化为带星期的中文日期
  ///
  /// 输出格式：2024年1月15日 星期一
  /// [date] 要格式化的日期
  static String formatChineseDateWithWeekday(DateTime date) {
    return '${formatChineseDate(date)} ${getWeekday(date)}';
  }

  // ============================================================
  // 相对时间
  // ============================================================

  /// 将日期转换为相对时间描述
  ///
  /// 根据与当前时间的差距，返回友好的中文描述：
  /// - 1 分钟内：刚刚
  /// - 1 小时内：x 分钟前
  /// - 24 小时内：x 小时前
  /// - 2 天内：昨天 HH:mm
  /// - 当年内：M月d日
  /// - 更早：yyyy-MM-dd
  ///
  /// [date] 要转换的日期时间
  static String relativeTime(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    // 1 分钟以内 → 刚刚
    if (difference.inMinutes < 1) {
      return '刚刚';
    }

    // 1 小时以内 → x 分钟前
    if (difference.inHours < 1) {
      return '${difference.inMinutes}分钟前';
    }

    // 24 小时以内 → x 小时前
    if (difference.inHours < 24) {
      return '${difference.inHours}小时前';
    }

    // 判断是否是昨天
    final yesterday = DateTime(now.year, now.month, now.day - 1);
    if (date.year == yesterday.year &&
        date.month == yesterday.month &&
        date.day == yesterday.day) {
      return '昨天 ${formatTime(date)}';
    }

    // 判断是否是前天
    final dayBeforeYesterday = DateTime(now.year, now.month, now.day - 2);
    if (date.year == dayBeforeYesterday.year &&
        date.month == dayBeforeYesterday.month &&
        date.day == dayBeforeYesterday.day) {
      return '前天 ${formatTime(date)}';
    }

    // 同一年内 → M月d日
    if (date.year == now.year) {
      return formatMonthDay(date);
    }

    // 更早的日期 → 完整日期
    return formatDate(date);
  }

  // ============================================================
  // 日记模块专用
  // ============================================================

  /// 格式化日记标题日期
  ///
  /// 根据日期与今天的关系返回友好描述：
  /// - 今天：今天（M月d日 星期x）
  /// - 昨天：昨天（M月d日 星期x）
  /// - 其他：M月d日 星期x
  ///
  /// [date] 日记的日期
  static String formatDiaryDate(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final targetDate = DateTime(date.year, date.month, date.day);
    final difference = today.difference(targetDate).inDays;

    final weekday = getWeekday(date);
    final monthDay = formatMonthDay(date);

    if (difference == 0) {
      return '今天（$monthDay $weekday）';
    } else if (difference == 1) {
      return '昨天（$monthDay $weekday）';
    } else if (difference == 2) {
      return '前天（$monthDay $weekday）';
    } else {
      return '$monthDay $weekday';
    }
  }

  // ============================================================
  // 辅助方法
  // ============================================================

  /// 判断两个日期是否是同一天
  ///
  /// 仅比较年、月、日，忽略时间部分。
  /// [a] 第一个日期
  /// [b] 第二个日期
  static bool isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  /// 判断给定日期是否是今天
  ///
  /// [date] 要判断的日期
  static bool isToday(DateTime date) {
    return isSameDay(date, DateTime.now());
  }

  /// 获取某个月的天数
  ///
  /// 正确处理闰年的二月。
  /// [year] 年份
  /// [month] 月份（1-12）
  static int daysInMonth(int year, int month) {
    // 通过构造下个月的第 0 天来获取当月最后一天
    return DateTime(year, month + 1, 0).day;
  }
}
