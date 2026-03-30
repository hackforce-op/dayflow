/// DayFlow - 规划模块数据仓库
///
/// 负责任务数据的本地存储和云端同步。
/// 采用本地优先策略：先写入本地数据库，再同步到 Supabase 云端。
library;

import 'package:drift/drift.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

import 'package:dayflow/core/supabase/supabase_client.dart';
import 'package:dayflow/features/planner/domain/task_item.dart';
import 'package:dayflow/shared/database/database.dart';
import 'package:dayflow/shared/database/dao/task_dao.dart';

/// 任务 DAO 的 Riverpod Provider
final taskDaoProvider = Provider<TaskDao>((ref) {
  final db = ref.watch(appDatabaseProvider);
  return TaskDao(db);
});

/// 任务数据仓库的 Riverpod Provider
final taskRepositoryProvider = Provider<TaskRepository>((ref) {
  return TaskRepository(
    taskDao: ref.watch(taskDaoProvider),
    supabaseClient: ref.watch(supabaseClientProvider),
  );
});

/// 任务数据仓库
///
/// 管理任务的本地存储和云端同步逻辑。
class TaskRepository {
  final TaskDao _taskDao;
  final SupabaseClient _supabaseClient;
  final Uuid _uuid = const Uuid();

  TaskRepository({
    required TaskDao taskDao,
    required SupabaseClient supabaseClient,
  })  : _taskDao = taskDao,
        _supabaseClient = supabaseClient;

  /// 获取所有任务（从本地数据库）
  Future<List<TaskItem>> getAllTasks(String userId) async {
    final rows = await _taskDao.getAllTasks(userId);
    return rows.map(_taskFromRow).toList();
  }

  /// 按状态获取任务
  Future<List<TaskItem>> getTasksByStatus(
      String userId, TaskStatus status) async {
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
    final syncedTask =
        task.cloudId == null ? task.copyWith(cloudId: _uuid.v4()) : task;

    final companion = TasksCompanion.insert(
      cloudId: Value(syncedTask.cloudId),
      title: syncedTask.title,
      description: Value(syncedTask.description),
      priority: Value(syncedTask.priority.value),
      status: Value(syncedTask.status.value),
      dueDate: Value(syncedTask.dueDate),
      sortOrder: Value(syncedTask.sortOrder),
      createdAt: syncedTask.createdAt,
      userId: syncedTask.userId,
    );
    final id = await _taskDao.insertTask(companion);
    final created = syncedTask.copyWith(id: id);

    // 异步同步到云端
    _syncTaskToCloud(created);

    return created;
  }

  /// 更新任务
  Future<void> updateTask(TaskItem task) async {
    if (task.id == null) return;
    final syncedTask = await _ensureLocalCloudId(task);

    final companion = TasksCompanion(
      id: Value(syncedTask.id!),
      cloudId: Value(syncedTask.cloudId),
      title: Value(syncedTask.title),
      description: Value(syncedTask.description),
      priority: Value(syncedTask.priority.value),
      status: Value(syncedTask.status.value),
      dueDate: Value(syncedTask.dueDate),
      sortOrder: Value(syncedTask.sortOrder),
      userId: Value(syncedTask.userId),
    );
    await _taskDao.updateTask(companion);
    _syncTaskToCloud(syncedTask);
  }

  /// 更新任务状态
  Future<void> updateTaskStatus(int taskId, TaskStatus status) async {
    final row = await _taskDao.getTaskById(taskId);
    if (row == null) {
      return;
    }

    final syncedTask = await _ensureLocalCloudId(_taskFromRow(row));
    final updatedTask = syncedTask.copyWith(status: status);

    await _taskDao.updateTask(
      TasksCompanion(
        id: Value(taskId),
        cloudId: Value(updatedTask.cloudId),
        status: Value(status.value),
      ),
    );

    _syncTaskToCloud(updatedTask);
  }

  /// 删除任务
  Future<void> deleteTask(int taskId) async {
    final existingRow = await _taskDao.getTaskById(taskId);
    final existingTask = existingRow != null ? _taskFromRow(existingRow) : null;

    await _taskDao.deleteTask(taskId);

    final cloudId = existingTask?.cloudId;
    if (cloudId != null) {
      await _deleteTaskFromCloud(cloudId, existingTask!.userId);
    }
  }

  /// 同步单个任务到云端（异步，不阻塞 UI）
  Future<void> _syncTaskToCloud(TaskItem task) async {
    try {
      await _supabaseClient.from('tasks').upsert(task.toJson());
    } catch (e) {
      debugPrint('[TaskRepository] 云端同步失败: $e');
    }
  }

  Future<void> _deleteTaskFromCloud(String cloudId, String userId) async {
    try {
      await _supabaseClient
          .from('tasks')
          .delete()
          .eq('id', cloudId)
          .eq('user_id', userId);
    } catch (e) {
      debugPrint('[TaskRepository] 云端删除失败: $e');
    }
  }

  Future<TaskItem> _ensureLocalCloudId(TaskItem task) async {
    if (task.id == null || task.cloudId != null) {
      return task;
    }

    final cloudId = _uuid.v4();
    await _taskDao.updateTask(
      TasksCompanion(
        id: Value(task.id!),
        cloudId: Value(cloudId),
      ),
    );

    return task.copyWith(cloudId: cloudId);
  }

  /// 将数据库行转换为 TaskItem 领域模型
  TaskItem _taskFromRow(Task row) {
    return TaskItem(
      id: row.id,
      cloudId: row.cloudId,
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
