/// DayFlow - 规划模块数据仓库
///
/// 负责任务数据的本地存储和云端同步。
/// 采用本地优先策略：先写入本地数据库，再同步到 Supabase 云端。
library;

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dayflow/features/planner/domain/task_item.dart';
import 'package:dayflow/shared/database/database.dart';
import 'package:dayflow/shared/database/dao/task_dao.dart';
import 'package:dayflow/core/supabase/supabase_client.dart';

/// 任务 DAO 的 Riverpod Provider
final taskDaoProvider = Provider<TaskDao>((ref) {
  final db = ref.watch(databaseProvider);
  return TaskDao(db);
});

/// 任务数据仓库的 Riverpod Provider
final taskRepositoryProvider = Provider<TaskRepository>((ref) {
  return TaskRepository(
    taskDao: ref.watch(taskDaoProvider),
    supabaseService: ref.watch(supabaseServiceProvider),
  );
});

/// 任务数据仓库
///
/// 管理任务的本地存储和云端同步逻辑。
class TaskRepository {
  final TaskDao _taskDao;
  final SupabaseService _supabaseService;

  TaskRepository({
    required TaskDao taskDao,
    required SupabaseService supabaseService,
  })  : _taskDao = taskDao,
        _supabaseService = supabaseService;

  /// 获取所有任务（从本地数据库）
  Future<List<TaskItem>> getAllTasks(String userId) async {
    final rows = await _taskDao.getAllTasks(userId);
    return rows.map(_taskFromRow).toList();
  }

  /// 按状态获取任务
  Future<List<TaskItem>> getTasksByStatus(String userId, TaskStatus status) async {
    final rows = await _taskDao.getTasksByStatus(userId, status.value);
    return rows.map(_taskFromRow).toList();
  }

  /// 获取今日任务
  Future<List<TaskItem>> getTodayTasks(String userId) async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final rows = await _taskDao.getTasksByDate(userId, today);
    return rows.map(_taskFromRow).toList();
  }

  /// 创建新任务
  Future<TaskItem> createTask(TaskItem task) async {
    final companion = TasksCompanion.insert(
      title: task.title,
      description: Value(task.description),
      priority: Value(task.priority.value),
      status: Value(task.status.value),
      dueDate: Value(task.dueDate),
      sortOrder: Value(task.sortOrder),
      createdAt: Value(task.createdAt),
      userId: task.userId,
    );
    final id = await _taskDao.insertTask(companion);
    final created = task.copyWith(id: id);

    // 异步同步到云端
    _syncTaskToCloud(created);

    return created;
  }

  /// 更新任务
  Future<void> updateTask(TaskItem task) async {
    if (task.id == null) return;
    final companion = TasksCompanion(
      title: Value(task.title),
      description: Value(task.description),
      priority: Value(task.priority.value),
      status: Value(task.status.value),
      dueDate: Value(task.dueDate),
      sortOrder: Value(task.sortOrder),
    );
    await _taskDao.updateTask(task.id!, companion);
    _syncTaskToCloud(task);
  }

  /// 更新任务状态
  Future<void> updateTaskStatus(int taskId, TaskStatus status) async {
    await _taskDao.updateTaskStatus(taskId, status.value);
  }

  /// 删除任务
  Future<void> deleteTask(int taskId) async {
    await _taskDao.deleteTask(taskId);
  }

  /// 同步单个任务到云端（异步，不阻塞 UI）
  Future<void> _syncTaskToCloud(TaskItem task) async {
    try {
      await _supabaseService.client
          .from('tasks')
          .upsert(task.toJson())
          .select();
    } catch (e) {
      debugPrint('[TaskRepository] 云端同步失败: $e');
    }
  }

  /// 将数据库行转换为 TaskItem 领域模型
  TaskItem _taskFromRow(Task row) {
    return TaskItem(
      id: row.id,
      title: row.title,
      description: row.description,
      priority: TaskPriority.fromValue(row.priority),
      status: TaskStatus.fromValue(row.status),
      dueDate: row.dueDate,
      sortOrder: row.sortOrder,
      createdAt: row.createdAt,
      userId: row.userId,
    );
  }
}
