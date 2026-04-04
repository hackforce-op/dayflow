/// DayFlow 应用全局常量定义
///
/// 此文件包含应用程序中使用的所有常量值，包括：
/// - Supabase 后端配置（URL 和匿名密钥）
/// - 应用基本信息（名称、版本）
/// - 默认心情选项列表
///
/// 注意：Supabase 的 URL 和 anonKey 是占位符，
/// 部署前必须替换为真实的项目凭证。
library;

/// 应用全局常量类
///
/// 使用抽象类 + 静态常量的方式，防止被实例化，
/// 所有常量通过 [AppConstants.xxx] 的方式访问。
abstract class AppConstants {
  // ============================================================
  // Supabase 后端配置
  // ============================================================

  static const String _supabaseUrlEnvKey = 'SUPABASE_URL';
  static const String _supabaseAnonKeyEnvKey = 'SUPABASE_ANON_KEY';

  /// Supabase 项目 URL
  ///
  /// 通过 `--dart-define-from-file=env.json` 注入，
  /// 格式：https://<project-ref>.supabase.co
  static const String supabaseUrl = String.fromEnvironment(_supabaseUrlEnvKey);

  /// Supabase 匿名密钥（anon key）
  ///
  /// 通过 `--dart-define-from-file=env.json` 注入。
  /// 此密钥可安全暴露在客户端，需配合 Row Level Security 使用。
  static const String supabaseAnonKey =
      String.fromEnvironment(_supabaseAnonKeyEnvKey);

  /// 当前项目是否已经完成 Supabase 基础配置
  static bool get isSupabaseConfigured {
    return supabaseUrl.isNotEmpty && supabaseAnonKey.isNotEmpty;
  }

  /// 首次启动 DayFlow 所需的最小 Supabase 配置说明
  static String get supabaseSetupInstructions {
    return '请先在项目根目录创建 env.json，填入 SUPABASE_URL 和 '
        'SUPABASE_ANON_KEY，然后使用 '
        'flutter run -d chrome --web-port=3000 '
        '--dart-define-from-file=env.json '
        '启动项目。';
  }

  /// 在应用启动前校验 Supabase 配置。
  static void validateSupabaseConfiguration() {
    final missingKeys = <String>[
      if (supabaseUrl.isEmpty) _supabaseUrlEnvKey,
      if (supabaseAnonKey.isEmpty) _supabaseAnonKeyEnvKey,
    ];

    if (missingKeys.isEmpty) {
      return;
    }

    throw StateError(
      'Supabase 云项目还未配置完成，缺少：${missingKeys.join(', ')}。\n'
      '$supabaseSetupInstructions',
    );
  }

  // ============================================================
  // 应用基本信息
  // ============================================================

  /// 应用名称
  static const String appName = 'DayFlow';

  /// 应用版本号
  static const String appVersion = '1.0.0';

  /// 应用构建号
  static const int appBuildNumber = 1;

  // ============================================================
  // 默认心情选项
  // ============================================================

  /// 默认心情选项列表
  ///
  /// 每个心情由 emoji 图标和中文标签组成，
  /// 用户在记录日记时可以从中选择当前的心情状态。
  /// 列表按照从积极到消极的顺序排列。
  static const List<Map<String, String>> defaultMoodOptions = [
    {'emoji': '😊', 'label': '开心'},
    {'emoji': '😌', 'label': '平静'},
    {'emoji': '🥰', 'label': '感恩'},
    {'emoji': '😤', 'label': '愤怒'},
    {'emoji': '😢', 'label': '难过'},
    {'emoji': '😰', 'label': '焦虑'},
    {'emoji': '😴', 'label': '疲惫'},
    {'emoji': '🤔', 'label': '思考'},
    {'emoji': '😎', 'label': '自信'},
    {'emoji': '🤩', 'label': '兴奋'},
  ];

  // ============================================================
  // SharedPreferences 存储键
  // ============================================================

  /// 主题模式存储键，用于持久化用户的主题偏好设置
  static const String themePrefsKey = 'theme_mode';

  /// 主题风格预设存储键
  static const String themePresetPrefsKey = 'theme_preset';

  /// 已登录账号列表存储键
  static const String rememberedAccountsPrefsKey = 'remembered_accounts';

  /// 侧边栏宽度存储键
  static const String sidebarWidthPrefsKey = 'sidebar_width';

  /// 侧边栏收起状态存储键
  static const String sidebarCollapsedPrefsKey = 'sidebar_collapsed';

  /// 农历显示开关存储键
  static const String lunarCalendarPrefsKey = 'lunar_calendar_enabled';

  /// 日记位置记录偏好存储键
  ///
  /// 值为 'true' 表示用户同意自动记录位置，'false' 表示拒绝，
  /// 不存在时表示尚未询问。
  static const String locationPermPrefsKey = 'diary_location_enabled';

  /// 「点击即可编辑」开关存储键
  ///
  /// 开启后，在日记详情页点击内容区域即直接跳转编辑页面。
  static const String tapToEditPrefsKey = 'tap_to_edit_enabled';
}
