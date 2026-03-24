/// ============================================================================
/// DayFlow - 新闻摘要领域模型
/// ============================================================================
///
/// 该文件定义了新闻功能的核心领域模型，包括：
/// - [NewsCategory] 枚举：新闻分类
/// - [NewsSummary] 类：表示一条 AI 生成的新闻摘要
///
/// 新闻摘要由后端 AI 服务自动生成，用户可以浏览每日新闻要点，
/// 并将感兴趣的新闻加入书签收藏。
/// ============================================================================

/// 新闻分类枚举
///
/// 定义了 DayFlow 支持的新闻分类类型。
/// 每个分类都有对应的 [label]（UI 显示文本）和 [value]（数据库存储值）。
///
/// 分类列表可根据需要扩展，新增分类时只需在此枚举中添加即可。
enum NewsCategory {
  /// 科技 - 科技行业动态、产品发布、技术趋势
  technology('科技', 'technology'),

  /// 财经 - 金融市场、经济政策、企业财报
  finance('财经', 'finance'),

  /// 体育 - 赛事结果、运动员动态
  sports('体育', 'sports'),

  /// 娱乐 - 影视、音乐、明星动态
  entertainment('娱乐', 'entertainment'),

  /// 健康 - 医疗健康、养生保健
  health('健康', 'health'),

  /// 国际 - 国际新闻、全球事件
  world('国际', 'world'),

  /// 其他 - 未归类的新闻
  other('其他', 'other');

  /// 构造函数
  const NewsCategory(this.label, this.value);

  /// UI 显示标签（中文名称）
  final String label;

  /// 数据库 / JSON 存储值（英文标识符）
  final String value;

  /// 从字符串值解析为 [NewsCategory] 枚举
  ///
  /// 如果传入的值无法匹配任何已知分类，默认返回 [NewsCategory.other]。
  static NewsCategory fromValue(String value) {
    return NewsCategory.values.firstWhere(
      (c) => c.value == value,
      orElse: () => NewsCategory.other,
    );
  }
}

/// 新闻摘要领域模型
///
/// 表示一条由 AI 生成的每日新闻摘要，包含标题、正文摘要、分类和来源链接。
/// 新闻摘要通过后端定时任务生成，同步到本地数据库后在客户端展示。
///
/// 该类是不可变的（immutable），通过 [copyWith] 创建修改后的副本。
///
/// 示例：
/// ```dart
/// final news = NewsSummary(
///   date: DateTime.now(),
///   category: NewsCategory.technology,
///   headline: 'Flutter 4.0 正式发布',
///   summary: 'Google 发布了 Flutter 4.0，带来了重大性能改进...',
///   sourceUrl: 'https://flutter.dev/blog/flutter-4',
///   createdAt: DateTime.now(),
/// );
/// ```
class NewsSummary {
  /// 新闻摘要的唯一标识符（数据库自增主键）
  ///
  /// 新建时为 null，保存到数据库后由数据库自动分配。
  final int? id;

  /// 新闻所属日期
  ///
  /// 表示这条新闻是哪一天的摘要。
  /// 用于按日期分组显示新闻列表。
  final DateTime date;

  /// 新闻分类
  ///
  /// 决定新闻在 UI 中显示的标签颜色和分组位置。
  final NewsCategory category;

  /// 新闻标题
  ///
  /// 简洁概括新闻核心内容的一句话标题。
  final String headline;

  /// 新闻摘要正文
  ///
  /// AI 生成的新闻内容摘要，通常为 2-3 段文字，
  /// 概括原文的关键信息和要点。
  final String summary;

  /// 新闻来源 URL（可选）
  ///
  /// 原始新闻文章的链接地址。
  /// 用户可以点击链接查看完整的原文。
  /// 允许为 null，表示没有对应的来源链接。
  final String? sourceUrl;

  /// 记录创建时间
  ///
  /// 表示该摘要在系统中生成的时间。
  final DateTime createdAt;

  /// 构造函数
  const NewsSummary({
    this.id,
    required this.date,
    required this.category,
    required this.headline,
    required this.summary,
    this.sourceUrl,
    required this.createdAt,
  });

  /// 从数据库行数据创建 [NewsSummary]
  ///
  /// 将数据库查询结果（Map 格式）转换为领域模型对象。
  ///
  /// [map] 数据库查询返回的键值对
  factory NewsSummary.fromMap(Map<String, dynamic> map) {
    return NewsSummary(
      id: map['id'] as int?,
      date: DateTime.parse(map['date'] as String),
      category: NewsCategory.fromValue(map['category'] as String? ?? 'other'),
      headline: map['headline'] as String,
      summary: map['summary'] as String,
      sourceUrl: map['source_url'] as String?,
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }

  /// 从 JSON 数据创建 [NewsSummary]
  ///
  /// 用于从 Supabase 远程 API 响应中解析新闻数据。
  factory NewsSummary.fromJson(Map<String, dynamic> json) {
    return NewsSummary(
      id: json['id'] as int?,
      date: DateTime.parse(json['date'] as String),
      category: NewsCategory.fromValue(json['category'] as String? ?? 'other'),
      headline: json['headline'] as String,
      summary: json['summary'] as String,
      sourceUrl: json['source_url'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  /// 将新闻摘要转换为 JSON 格式
  ///
  /// 用于向 Supabase 远程 API 发送数据。
  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'date': date.toIso8601String(),
      'category': category.value,
      'headline': headline,
      'summary': summary,
      'source_url': sourceUrl,
      'created_at': createdAt.toIso8601String(),
    };
  }

  /// 创建当前对象的副本，并允许修改部分字段
  NewsSummary copyWith({
    int? id,
    DateTime? date,
    NewsCategory? category,
    String? headline,
    String? summary,
    String? sourceUrl,
    DateTime? createdAt,
  }) {
    return NewsSummary(
      id: id ?? this.id,
      date: date ?? this.date,
      category: category ?? this.category,
      headline: headline ?? this.headline,
      summary: summary ?? this.summary,
      sourceUrl: sourceUrl ?? this.sourceUrl,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  String toString() {
    return 'NewsSummary(id: $id, date: $date, category: ${category.value}, '
        'headline: $headline)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is NewsSummary &&
        other.id == id &&
        other.headline == headline &&
        other.category == category &&
        other.date == date;
  }

  @override
  int get hashCode {
    return Object.hash(id, headline, category, date);
  }
}
