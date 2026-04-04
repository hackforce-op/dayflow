/// ============================================================================
/// DayFlow - 任务数据访问对象 (DAO)
/// ============================================================================
///
/// 该文件封装了所有任务（待办事项）相关的数据库操作。
///
/// ## 核心功能
///
/// - CRUD 操作：创建、读取、更新、删除任务
/// - 状态筛选：按 todo / in_progress / done 筛选任务
/// - 日期查询：查询指定日期的任务列表
/// - 排序管理：支持拖拽排序（更新 sortOrder 字段）
/// - 响应式查询：提供 Stream 接口实现 UI 自动更新
///
/// ## 使用方式
///
/// ```dart
/// final db = ref.read(appDatabaseProvider);
/// final taskDao = TaskDao(db);
///
/// // 监听待办任务列表
/// final stream = taskDao.watchTasksByStatus('user-123', 'todo');
///
/// // 创建新任务
/// await taskDao.insertTask(TasksCompanion.insert(...));
/// ```
/// ============================================================================
import 'package:drift/drift.dart';

import '../database.dart';

/// 任务数据访问对象
///
/// 封装了 [Tasks] 表的所有数据库操作。
/// 手动编写查询逻辑，不依赖 Drift 的 @DriftAccessor 代码生成。
class TaskDao {
  /// 数据库实例引用
  final AppDatabase _db;

  /// 构造函数
  ///
  /// [db] 应用数据库实例
  TaskDao(this._db);

  // ==========================================================================
  // 查询操作 (Read)
  // ==========================================================================

  /// 获取指定用户的所有任务
  ///
  /// 返回按优先级升序（高优先级在前）、排序序号升序排列的任务列表。
  ///
  /// [userId] 用户唯一标识符
  Future<List<Task>> getAllTasks(String userId) {
    return (_db.select(_db.tasks)
          ..where((t) => t.userId.equals(userId))
          ..orderBy([
            /// 先按优先级排序（数字小 = 优先级高）
            (t) => OrderingTerm(
                  expression: t.priority,
                  mode: OrderingMode.asc,
                ),

            /// 再按自定义排序序号
            (t) => OrderingTerm(
                  expression: t.sortOrder,
                  mode: OrderingMode.asc,
                ),
          ]))
        .get();
  }

  /// 监听指定用户的所有任务（响应式）
  ///
  /// 返回 Stream，任务数据变化时自动发出新列表。
  /// 排序规则：优先级升序 → 排序序号升序。
  ///
  /// [userId] 用户唯一标识符
  Stream<List<Task>> watchAllTasks(String userId) {
    return (_db.select(_db.tasks)
          ..where((t) => t.userId.equals(userId))
          ..orderBy([
            (t) => OrderingTerm(
                  expression: t.priority,
                  mode: OrderingMode.asc,
                ),
            (t) => OrderingTerm(
                  expression: t.sortOrder,
                  mode: OrderingMode.asc,
                ),
          ]))
        .watch();
  }

  /// 根据 ID 获取单个任务
  ///
  /// [id] 任务的数据库 ID
  ///
  /// 返回 [Future<Task?>]，如果不存在则返回 null。
  Future<Task?> getTaskById(int id) {
    return (_db.select(_db.tasks)..where((t) => t.id.equals(id)))
        .getSingleOrNull();
  }

  /// 按状态筛选任务
  ///
  /// 获取指定状态的任务列表。常见用法：
  /// - 获取所有待办任务：`getTasksByStatus(userId, 'todo')`
  /// - 获取进行中任务：`getTasksByStatus(userId, 'in_progress')`
  /// - 获取已完成任务：`getTasksByStatus(userId, 'done')`
  ///
  /// [userId] 用户唯一标识符
  /// [status] 任务状态字符串
  ///
  /// 返回按优先级和排序序号排列的任务列表。
  Future<List<Task>> getTasksByStatus(String userId, String status) {
    return (_db.select(_db.tasks)
          ..where((t) => t.userId.equals(userId) & t.status.equals(status))
          ..orderBy([
            (t) => OrderingTerm(
                  expression: t.priority,
                  mode: OrderingMode.asc,
                ),
            (t) => OrderingTerm(
                  expression: t.sortOrder,
                  mode: OrderingMode.asc,
                ),
          ]))
        .get();
  }

  /// 监听指定状态的任务（响应式）
  ///
  /// 返回 Stream，指定状态的任务发生变化时自动更新。
  /// 适合与 Riverpod 的 StreamProvider 配合使用。
  ///
  /// [userId] 用户唯一标识符
  /// [status] 任务状态字符串（'todo' / 'in_progress' / 'done'）
  Stream<List<Task>> watchTasksByStatus(String userId, String status) {
    return (_db.select(_db.tasks)
          ..where((t) => t.userId.equals(userId) & t.status.equals(status))
          ..orderBy([
            (t) => OrderingTerm(
                  expression: t.priority,
                  mode: OrderingMode.asc,
                ),
            (t) => OrderingTerm(
                  expression: t.sortOrder,
                  mode: OrderingMode.asc,
                ),
          ]))
        .watch();
  }

  /// 查询指定日期的任务
  ///
  /// 获取截止日期在指定日期当天的所有任务。
  /// 日期比较只比较年月日，忽略时分秒。
  ///
  /// [userId] 用户唯一标识符
  /// [date] 目标日期
  Future<List<Task>> getTasksByDate(String userId, DateTime date) {
    /// 计算当天的起止时间
    final dayStart = DateTime(date.year, date.month, date.day);
    final dayEnd = DateTime(date.year, date.month, date.day, 23, 59, 59);

    return (_db.select(_db.tasks)
          ..where((t) =>
              t.userId.equals(userId) &
              (t.dueDate.isNull() |
                  (t.dueDate.isBiggerOrEqualValue(dayStart) &
                      t.dueDate.isSmallerOrEqualValue(dayEnd))))
          ..orderBy([
            (t) => OrderingTerm(
                  expression: t.priority,
                  mode: OrderingMode.asc,
                ),
            (t) => OrderingTerm(
                  expression: t.sortOrder,
                  mode: OrderingMode.asc,
                ),
          ]))
        .get();
  }

  /// 监听指定日期的任务（响应式）
  ///
  /// [userId] 用户唯一标识符
  /// [date] 目标日期
  Stream<List<Task>> watchTasksByDate(String userId, DateTime date) {
    final dayStart = DateTime(date.year, date.month, date.day);
    final dayEnd = DateTime(date.year, date.month, date.day, 23, 59, 59);

    return (_db.select(_db.tasks)
          ..where((t) =>
              t.userId.equals(userId) &
              (t.dueDate.isNull() |
                  (t.dueDate.isBiggerOrEqualValue(dayStart) &
                      t.dueDate.isSmallerOrEqualValue(dayEnd))))
          ..orderBy([
            (t) => OrderingTerm(
                  expression: t.priority,
                  mode: OrderingMode.asc,
                ),
            (t) => OrderingTerm(
                  expression: t.sortOrder,
                  mode: OrderingMode.asc,
                ),
          ]))
        .watch();
  }

  // ==========================================================================
  // 创建操作 (Create)
  // ==========================================================================

  /// 插入一条新任务
  ///
  /// [task] 要插入的任务数据（使用 Drift 的 Companion 对象）
  ///
  /// 返回新记录的数据库自增 ID。
  ///
  /// 示例：
  /// ```dart
  /// final id = await taskDao.insertTask(
  ///   TasksCompanion.insert(
  ///     title: '完成项目报告',
  ///     description: Value('整理本周工作成果'),
  ///     priority: Value(1),
  ///     createdAt: DateTime.now(),
  ///     userId: 'user-123',
  ///   ),
  /// );
  /// ```
  Future<int> insertTask(TasksCompanion task) {
    return _db.into(_db.tasks).insert(task);
  }

  // ==========================================================================
  // 更新操作 (Update)
  // ==========================================================================

  /// 更新一条任务记录
  ///
  /// 根据主键 (id) 更新对应的任务记录。
  ///
  /// [task] 要更新的任务数据（必须包含有效的 id）
  ///
  /// 返回 true 表示更新成功，false 表示未找到记录。
  Future<bool> updateTask(TasksCompanion task) {
    return (_db.update(_db.tasks)..where((t) => t.id.equals(task.id.value)))
        .write(task)
        .then((rows) => rows > 0);
  }

  /// 更新任务状态
  ///
  /// 快捷方法，仅更新任务的状态字段。
  /// 常用于任务完成操作（一键标记为 done）。
  ///
  /// [id] 任务 ID
  /// [status] 新的状态值（'todo' / 'in_progress' / 'done'）
  Future<bool> updateTaskStatus(int id, String status) {
    return (_db.update(_db.tasks)..where((t) => t.id.equals(id)))
        .write(TasksCompanion(status: Value(status)))
        .then((rows) => rows > 0);
  }

  /// 批量更新任务排序序号
  ///
  /// 用于拖拽排序场景：用户通过拖拽重新排列任务后，
  /// 调用此方法批量更新所有受影响任务的排序序号。
  ///
  /// [updates] 任务 ID 到新排序序号的映射
  ///   - key: 任务 ID
  ///   - value: 新的排序序号（sortOrder）
  ///
  /// 使用数据库事务确保原子性：要么全部更新成功，要么全部回滚。
  ///
  /// 示例：
  /// ```dart
  /// // 将 3 个任务重新排序
  /// await taskDao.updateSortOrders({
  ///   1: 0,  // 任务 1 排在第一位
  ///   3: 1,  // 任务 3 排在第二位
  ///   2: 2,  // 任务 2 排在第三位
  /// });
  /// ```
  Future<void> updateSortOrders(Map<int, int> updates) {
    return _db.transaction(() async {
      for (final entry in updates.entries) {
        await (_db.update(_db.tasks)..where((t) => t.id.equals(entry.key)))
            .write(TasksCompanion(sortOrder: Value(entry.value)));
      }
    });
  }

  // ==========================================================================
  // 删除操作 (Delete)
  // ==========================================================================

  /// 删除指定 ID 的任务
  ///
  /// [id] 要删除的任务 ID
  ///
  /// 返回被删除的行数（0 或 1）。
  Future<int> deleteTask(int id) {
    return (_db.delete(_db.tasks)..where((t) => t.id.equals(id))).go();
  }

  /// 删除指定用户的所有任务
  ///
  /// ⚠️ 危险操作！将删除该用户的全部任务数据。
  ///
  /// [userId] 用户唯一标识符
  Future<int> deleteAllTasks(String userId) {
    return (_db.delete(_db.tasks)..where((t) => t.userId.equals(userId))).go();
  }

  /// 删除指定状态的所有任务
  ///
  /// 常用场景：批量清除已完成的任务。
  ///
  /// [userId] 用户唯一标识符
  /// [status] 要删除的任务状态
  Future<int> deleteTasksByStatus(String userId, String status) {
    return (_db.delete(_db.tasks)
          ..where((t) => t.userId.equals(userId) & t.status.equals(status)))
        .go();
  }
}
