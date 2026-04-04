/// DayFlow - 日记本领域模型
///
/// 表示一个日记本（日记分组容器），包含名称、封面等元信息。
library;

/// 日记本领域模型
///
/// 不可变对象，通过 [copyWith] 创建修改后的副本。
class Notebook {
  /// 本地数据库自增主键
  final int? id;

  /// 云端主键 ID（Supabase UUID）
  final String? cloudId;

  /// 日记本名称
  final String name;

  /// 封面图片 URL（可选）
  final String? coverUrl;

  /// 排序序号（数值越小越靠前）
  final int sortOrder;

  /// 创建时间
  final DateTime createdAt;

  /// 最后更新时间
  final DateTime updatedAt;

  /// 所属用户 ID
  final String userId;

  const Notebook({
    this.id,
    this.cloudId,
    required this.name,
    this.coverUrl,
    this.sortOrder = 0,
    required this.createdAt,
    required this.updatedAt,
    required this.userId,
  });

  Notebook copyWith({
    int? id,
    String? cloudId,
    String? name,
    String? coverUrl,
    int? sortOrder,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? userId,
  }) {
    return Notebook(
      id: id ?? this.id,
      cloudId: cloudId ?? this.cloudId,
      name: name ?? this.name,
      coverUrl: coverUrl ?? this.coverUrl,
      sortOrder: sortOrder ?? this.sortOrder,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      userId: userId ?? this.userId,
    );
  }
}
