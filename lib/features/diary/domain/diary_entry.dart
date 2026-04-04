/// ============================================================================
/// DayFlow - 日记条目领域模型
/// ============================================================================
///
/// 该文件定义了日记功能的核心领域模型，包括：
/// - [Mood] 枚举：表示用户的心情状态
/// - [DiaryEntry] 类：表示一条完整的日记记录
///
/// 领域模型是业务逻辑的核心，不依赖任何外部框架（如数据库、网络等）。
/// 它在 UI 层和数据层之间充当桥梁，确保数据的一致性和类型安全。
/// ============================================================================
library;

/// 心情枚举
///
/// 用于记录用户写日记时的心情状态。
/// 每种心情都有对应的标签（label）用于 UI 显示，以及值（value）用于数据库存储。
///
/// 使用示例：
/// ```dart
/// final mood = Mood.happy;
/// print(mood.emoji);  // 输出: 😊
/// print(mood.label);  // 输出: 开心
/// print(mood.value);  // 输出: happy
/// ```
enum Mood {
  /// 开心 - 表示积极、愉悦的心情
  happy('😊', '开心', 'happy'),

  /// 平静 - 表示平和、安宁的心情
  calm('😌', '平静', 'calm'),

  /// 悲伤 - 表示低落、难过的心情
  sad('😢', '悲伤', 'sad'),

  /// 愤怒 - 表示生气、不满的心情
  angry('😠', '愤怒', 'angry'),

  /// 焦虑 - 表示紧张、担忧的心情
  anxious('😰', '焦虑', 'anxious'),

  /// 兴奋 - 表示激动、期待的心情
  excited('🤩', '兴奋', 'excited'),

  /// 疲惫 - 表示困倦、精力不足的心情
  tired('😴', '疲惫', 'tired'),

  /// 感恩 - 表示感激、珍惜的心情
  grateful('🙏', '感恩', 'grateful');

  /// 构造函数
  ///
  /// [emoji] 用于在 UI 中显示的表情符号
  /// [label] 用于在 UI 中显示的中文名称
  /// [value] 用于在数据库和 JSON 中存储的字符串标识符
  const Mood(this.emoji, this.label, this.value);

  /// UI 显示用 emoji
  final String emoji;

  /// UI 显示标签（中文名称）
  final String label;

  /// 数据库 / JSON 存储值
  final String value;

  /// 从字符串值解析为 [Mood] 枚举
  ///
  /// 如果传入的值不匹配任何枚举项，返回 null。
  /// 这在从数据库读取数据时非常有用，因为数据库中可能存储了无效值。
  ///
  /// 示例：
  /// ```dart
  /// final mood = Mood.fromValue('happy'); // 返回 Mood.happy
  /// final unknown = Mood.fromValue('xyz'); // 返回 null
  /// ```
  static Mood? fromValue(String? value) {
    if (value == null) return null;
    return Mood.values.where((m) => m.value == value).firstOrNull;
  }
}

/// 日记条目领域模型
///
/// 表示一条完整的日记记录，包含内容、心情、日期等信息。
/// 该类是不可变的（immutable），通过 [copyWith] 方法创建修改后的副本。
///
/// 创建新日记：
/// ```dart
/// final entry = DiaryEntry(
///   content: '今天天气真好！',
///   mood: Mood.happy,
///   date: DateTime.now(),
///   createdAt: DateTime.now(),
///   updatedAt: DateTime.now(),
///   userId: 'user-123',
/// );
/// ```
class DiaryEntry {
  static const Object _unset = Object();

  /// 日记条目的唯一标识符（数据库自增主键）
  ///
  /// 新建日记时为 null，保存到数据库后由数据库自动分配。
  final int? id;

  /// Supabase 云端主键（UUID）
  ///
  /// 该字段用于多设备同步，与本地 SQLite 的自增主键解耦。
  final String? cloudId;

  /// 日记正文内容
  ///
  /// 支持富文本格式（通过 Flutter Quill 编辑器输入）。
  /// 存储为纯文本或 JSON 格式的 Delta 数据。
  final String content;

  /// 用户的心情状态（可选）
  ///
  /// 允许为 null，表示用户未选择心情。
  final Mood? mood;

  /// 日记所属日期
  ///
  /// 注意：这是日记"所属"的日期，不一定是创建日期。
  /// 例如用户可以补写前一天的日记。
  final DateTime date;

  /// 记录创建时间
  final DateTime createdAt;

  /// 记录最后更新时间
  final DateTime updatedAt;

  /// 所属用户的唯一标识符
  ///
  /// 对应 Supabase Auth 中的用户 ID，用于数据隔离和同步。
  final String userId;

  /// 地理位置坐标（可选），格式："纬度,经度"
  ///
  /// 记录写日记时的当前地理位置，在列表页展示于每条记录底部。
  final String? location;

  /// 位置地名（可选），geocoding 解析后的可读地址
  ///
  /// 例如："酸奶紫米露(西华记忆店)西华..."
  final String? locationName;

  /// 图片 URL 列表（可选），以英文逗号分隔存储
  ///
  /// 日记中插入的图片地址集合，列表页取第一张作为封面缩略图显示。
  final String? imageUrls;

  /// 所属日记本 ID（可选）
  ///
  /// 为 null 表示未分类日记。
  final int? notebookId;

  /// 构造函数
  const DiaryEntry({
    this.id,
    this.cloudId,
    required this.content,
    this.mood,
    required this.date,
    required this.createdAt,
    required this.updatedAt,
    required this.userId,
    this.location,
    this.locationName,
    this.imageUrls,
    this.notebookId,
  });

  /// 从数据库行数据创建 [DiaryEntry]
  ///
  /// 将数据库查询结果（Map 格式）转换为领域模型对象。
  /// 日期字段从 ISO 8601 字符串或毫秒时间戳解析。
  ///
  /// [map] 数据库查询返回的键值对
  factory DiaryEntry.fromMap(Map<String, dynamic> map) {
    final rawNotebookId = map['notebook_id'];

    return DiaryEntry(
      id: map['id'] as int?,
      cloudId: map['cloud_id'] as String?,
      content: map['content'] as String,
      mood: Mood.fromValue(map['mood'] as String?),
      date: DateTime.parse(map['date'] as String),
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: DateTime.parse(map['updated_at'] as String),
      userId: map['user_id'] as String,
      location: map['location'] as String?,
      locationName: map['location_name'] as String?,
      imageUrls: map['image_urls'] as String?,
      notebookId: rawNotebookId is int
          ? rawNotebookId
          : int.tryParse(rawNotebookId?.toString() ?? ''),
    );
  }

  /// 从 JSON 数据创建 [DiaryEntry]
  ///
  /// 用于从 Supabase 远程 API 响应中解析日记数据。
  /// JSON 键名采用 snake_case 格式（与 Supabase 列名一致）。
  ///
  /// [json] API 返回的 JSON 对象
  factory DiaryEntry.fromJson(Map<String, dynamic> json) {
    final rawId = json['id'];
    final rawNotebookId = json['notebook_id'];

    return DiaryEntry(
      id: rawId is int ? rawId : null,
      cloudId: rawId is String ? rawId : json['cloud_id'] as String?,
      content: json['content'] as String,
      mood: Mood.fromValue(json['mood'] as String?),
      date: DateTime.parse(json['date'] as String).toLocal(),
      createdAt: DateTime.parse(json['created_at'] as String).toLocal(),
      updatedAt: DateTime.parse(json['updated_at'] as String).toLocal(),
      userId: json['user_id'] as String,
      location: json['location'] as String?,
      locationName: json['location_name'] as String?,
      imageUrls: json['image_urls'] as String?,
      notebookId: rawNotebookId is int
          ? rawNotebookId
          : int.tryParse(rawNotebookId?.toString() ?? ''),
    );
  }

  /// 将日记条目转换为 JSON 格式
  ///
  /// 用于向 Supabase 远程 API 发送数据。
  /// 输出的键名采用 snake_case 格式。
  /// 注意：[id] 字段不包含在输出中，因为它由服务端自动生成。
  /// location / location_name / image_urls 始终包含（即使为 null），
  /// 确保云端同步时不会因字段缺失而丢失已有数据。
  Map<String, dynamic> toJson() {
    return {
      if (cloudId != null) 'id': cloudId,
      'content': content,
      'mood': mood?.value,
      'date': date.toUtc().toIso8601String(),
      'created_at': createdAt.toUtc().toIso8601String(),
      'updated_at': updatedAt.toUtc().toIso8601String(),
      'user_id': userId,
      'location': location,
      'location_name': locationName,
      'image_urls': imageUrls,
    };
  }

  /// 创建当前对象的副本，并允许修改部分字段
  ///
  /// 由于 [DiaryEntry] 是不可变的，修改时需要创建新实例。
  /// 未指定的字段将保留原始值。
  DiaryEntry copyWith({
    int? id,
    Object? cloudId = _unset,
    String? content,
    Object? mood = _unset,
    DateTime? date,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? userId,
    Object? location = _unset,
    Object? locationName = _unset,
    Object? imageUrls = _unset,
    Object? notebookId = _unset,
  }) {
    return DiaryEntry(
      id: id ?? this.id,
      cloudId: identical(cloudId, _unset) ? this.cloudId : cloudId as String?,
      content: content ?? this.content,
      mood: identical(mood, _unset) ? this.mood : mood as Mood?,
      date: date ?? this.date,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      userId: userId ?? this.userId,
      location:
          identical(location, _unset) ? this.location : location as String?,
      locationName: identical(locationName, _unset)
          ? this.locationName
          : locationName as String?,
      imageUrls:
          identical(imageUrls, _unset) ? this.imageUrls : imageUrls as String?,
      notebookId: identical(notebookId, _unset)
          ? this.notebookId
          : notebookId as int?,
    );
  }

  @override
  String toString() {
    return 'DiaryEntry(id: $id, cloudId: $cloudId, date: $date, '
        'mood: ${mood?.value}, '
        'contentLength: ${content.length})';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is DiaryEntry &&
        other.id == id &&
        other.cloudId == cloudId &&
        other.content == content &&
        other.mood == mood &&
        other.date == date &&
        other.userId == userId &&
        other.notebookId == notebookId;
  }

  @override
  int get hashCode {
    return Object.hash(id, cloudId, content, mood, date, userId, notebookId);
  }
}
