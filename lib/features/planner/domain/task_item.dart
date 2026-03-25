/// ============================================================================
/// DayFlow - 任务项领域模型
/// ============================================================================
///
/// 该文件定义了计划/待办功能的核心领域模型，包括：
/// - [TaskStatus] 枚举：任务的完成状态
/// - [TaskPriority] 枚举：任务的优先级
/// - [TaskItem] 类：表示一个完整的任务/待办事项
///
/// 任务管理是 DayFlow 的核心功能之一，用户可以创建、编辑、排序和跟踪
/// 每日待办事项的完成情况。
/// ============================================================================

/// 任务状态枚举
///
/// 表示任务在生命周期中的当前状态。
/// 任务的典型流转路径：todo → inProgress → done
///
/// 每个状态都有对应的 [label]（UI 显示文本）和 [value]（数据库存储值）。
enum TaskStatus {
  /// 待办 - 任务已创建但尚未开始
  todo('待办', 'todo'),

  /// 进行中 - 任务正在执行
  inProgress('进行中', 'in_progress'),

  /// 已完成 - 任务已完成
  done('已完成', 'done');

  /// 构造函数
  const TaskStatus(this.label, this.value);

  /// UI 显示标签
  final String label;

  /// 数据库存储值
  final String value;

  /// 从字符串值解析为 [TaskStatus] 枚举
  ///
  /// 如果传入的值无法匹配，默认返回 [TaskStatus.todo]。
  /// 这确保了即使数据库中存储了意外值，应用也不会崩溃。
  static TaskStatus fromValue(String value) {
    return TaskStatus.values.firstWhere(
      (s) => s.value == value,
      orElse: () => TaskStatus.todo,
    );
  }
}

/// 任务优先级枚举
///
/// 使用数字值表示优先级，数字越小优先级越高：
/// - high = 1（最高优先级）
/// - medium = 2（默认优先级）
/// - low = 3（最低优先级）
///
/// 这种设计使得按优先级排序时可以直接使用数字升序排列。
enum TaskPriority {
  /// 高优先级（紧急/重要任务）
  high('高', 1),

  /// 中优先级（一般任务，默认值）
  medium('中', 2),

  /// 低优先级（不紧急的任务）
  low('低', 3);

  /// 构造函数
  const TaskPriority(this.label, this.value);

  /// UI 显示标签
  final String label;

  /// 数据库存储值（整数）
  final int value;

  /// 从整数值解析为 [TaskPriority] 枚举
  ///
  /// 如果传入的值无法匹配，默认返回 [TaskPriority.medium]。
  static TaskPriority fromValue(int value) {
    return TaskPriority.values.firstWhere(
      (p) => p.value == value,
      orElse: () => TaskPriority.medium,
    );
  }
}

/// 任务项领域模型
///
/// 表示用户创建的一个待办任务，包含标题、描述、优先级、状态等完整信息。
/// 该类是不可变的（immutable），通过 [copyWith] 创建修改后的副本。
///
/// 创建新任务示例：
/// ```dart
/// final task = TaskItem(
///   title: '完成项目报告',
///   description: '整理本周的工作成果并生成报告',
///   priority: TaskPriority.high,
///   status: TaskStatus.todo,
///   dueDate: DateTime(2024, 12, 31),
///   createdAt: DateTime.now(),
///   userId: 'user-123',
/// );
/// ```
class TaskItem {
  /// 任务的唯一标识符（数据库自增主键）
  ///
  /// 新建任务时为 null，保存到数据库后由数据库自动分配。
  final int? id;

  /// 任务标题
  ///
  /// 简洁描述任务内容的一句话，在任务列表中显示。
  final String title;

  /// 任务详细描述（可选）
  ///
  /// 对任务的详细说明、备注或步骤。
  /// 允许为 null，表示用户未填写详细描述。
  final String? description;

  /// 任务优先级
  ///
  /// 决定任务在列表中的视觉样式和默认排序。
  /// 默认为 [TaskPriority.medium]。
  final TaskPriority priority;

  /// 任务当前状态
  ///
  /// 表示任务在生命周期中的位置。
  /// 默认为 [TaskStatus.todo]。
  final TaskStatus status;

  /// 截止日期（可选）
  ///
  /// 任务需要完成的期限。允许为 null，表示没有截止日期。
  /// 超过截止日期的未完成任务会在 UI 中高亮提示。
  final DateTime? dueDate;

  /// 排序序号
  ///
  /// 用于用户自定义排序（拖拽排序）。
  /// 数值越小越靠前，默认为 0。
  final int sortOrder;

  /// 记录创建时间
  final DateTime createdAt;

  /// 所属用户的唯一标识符
  ///
  /// 对应 Supabase Auth 中的用户 ID。
  final String userId;

  /// 构造函数
  const TaskItem({
    this.id,
    required this.title,
    this.description,
    this.priority = TaskPriority.medium,
    this.status = TaskStatus.todo,
    this.dueDate,
    this.sortOrder = 0,
    required this.createdAt,
    required this.userId,
  });

  /// 从数据库行数据创建 [TaskItem]
  ///
  /// 将数据库查询结果（Map 格式）转换为领域模型对象。
  ///
  /// [map] 数据库查询返回的键值对
  factory TaskItem.fromMap(Map<String, dynamic> map) {
    return TaskItem(
      id: map['id'] as int?,
      title: map['title'] as String,
      description: map['description'] as String?,
      priority: TaskPriority.fromValue(map['priority'] as int? ?? 2),
      status: TaskStatus.fromValue(map['status'] as String? ?? 'todo'),
      dueDate: map['due_date'] != null
          ? DateTime.parse(map['due_date'] as String)
          : null,
      sortOrder: map['sort_order'] as int? ?? 0,
      createdAt: DateTime.parse(map['created_at'] as String),
      userId: map['user_id'] as String,
    );
  }

  /// 从 JSON 数据创建 [TaskItem]
  ///
  /// 用于从 Supabase 远程 API 响应中解析任务数据。
  factory TaskItem.fromJson(Map<String, dynamic> json) {
    return TaskItem(
      id: json['id'] as int?,
      title: json['title'] as String,
      description: json['description'] as String?,
      priority: TaskPriority.fromValue(json['priority'] as int? ?? 2),
      status: TaskStatus.fromValue(json['status'] as String? ?? 'todo'),
      dueDate: json['due_date'] != null
          ? DateTime.parse(json['due_date'] as String)
          : null,
      sortOrder: json['sort_order'] as int? ?? 0,
      createdAt: DateTime.parse(json['created_at'] as String),
      userId: json['user_id'] as String,
    );
  }

  /// 将任务转换为 JSON 格式
  ///
  /// 用于向 Supabase 远程 API 发送数据。
  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'title': title,
      'description': description,
      'priority': priority.value,
      'status': status.value,
      'due_date': dueDate?.toIso8601String(),
      'sort_order': sortOrder,
      'created_at': createdAt.toIso8601String(),
      'user_id': userId,
    };
  }

  /// 创建当前对象的副本，并允许修改部分字段
  TaskItem copyWith({
    int? id,
    String? title,
    String? description,
    TaskPriority? priority,
    TaskStatus? status,
    DateTime? dueDate,
    int? sortOrder,
    DateTime? createdAt,
    String? userId,
  }) {
    return TaskItem(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      priority: priority ?? this.priority,
      status: status ?? this.status,
      dueDate: dueDate ?? this.dueDate,
      sortOrder: sortOrder ?? this.sortOrder,
      createdAt: createdAt ?? this.createdAt,
      userId: userId ?? this.userId,
    );
  }

  /// 判断任务是否已过期（超过截止日期且未完成）
  bool get isOverdue {
    if (dueDate == null || status == TaskStatus.done) return false;
    return DateTime.now().isAfter(dueDate!);
  }

  /// 判断任务是否已完成
  bool get isDone => status == TaskStatus.done;

  @override
  String toString() {
    return 'TaskItem(id: $id, title: $title, status: ${status.value}, '
        'priority: ${priority.value})';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is TaskItem &&
        other.id == id &&
        other.title == title &&
        other.status == status &&
        other.priority == priority &&
        other.userId == userId;
  }

  @override
  int get hashCode {
    return Object.hash(id, title, status, priority, userId);
  }
}
