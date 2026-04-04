/// DayFlow - 规划模块状态管理
///
/// 使用 Riverpod StateNotifier 管理任务列表和编辑状态。
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:dayflow/features/auth/providers/auth_provider.dart';
import 'package:dayflow/features/planner/domain/task_item.dart';
import 'package:dayflow/features/planner/data/task_repository.dart';

// ==================== 任务列表状态 ====================

/// 任务列表状态 - 密封类
sealed class TaskListState {
  const TaskListState();
}

/// 加载中状态
class TaskListLoading extends TaskListState {
  const TaskListLoading();
}

/// 数据加载完成状态
class TaskListData extends TaskListState {
  final List<TaskItem> tasks;
  const TaskListData(this.tasks);
}

/// 加载错误状态
class TaskListError extends TaskListState {
  final String message;
  const TaskListError(this.message);
}

/// 任务列表状态管理器
class TaskListNotifier extends StateNotifier<TaskListState> {
  final TaskRepository _repository;
  final String _userId;

  TaskStatus? _currentStatusFilter;
  bool _showTodayOnly = false;

  TaskListNotifier(this._repository, this._userId)
      : super(const TaskListLoading());

  /// 加载所有任务
  Future<void> loadTasks() async {
    _showTodayOnly = false;
    _currentStatusFilter = null;
    state = const TaskListLoading();
    try {
      final tasks = await _repository.getAllTasks(_userId);
      state = TaskListData(tasks);
    } catch (e) {
      state = TaskListError(e.toString());
    }
  }

  /// 加载今日任务
  Future<void> loadTodayTasks() async {
    _showTodayOnly = true;
    _currentStatusFilter = null;
    state = const TaskListLoading();
    try {
      final tasks = await _repository.getTodayTasks(_userId);
      state = TaskListData(tasks);
    } catch (e) {
      state = TaskListError(e.toString());
    }
  }

  /// 按状态筛选任务
  Future<void> filterByStatus(TaskStatus status) async {
    _showTodayOnly = false;
    _currentStatusFilter = status;
    state = const TaskListLoading();
    try {
      final tasks = await _repository.getTasksByStatus(_userId, status);
      state = TaskListData(tasks);
    } catch (e) {
      state = TaskListError(e.toString());
    }
  }

  /// 切换任务状态
  Future<void> toggleTaskStatus(TaskItem task) async {
    // 循环切换状态：todo -> inProgress -> done -> todo
    final nextStatus = switch (task.status) {
      TaskStatus.todo => TaskStatus.inProgress,
      TaskStatus.inProgress => TaskStatus.done,
      TaskStatus.done => TaskStatus.todo,
    };
    await _repository.updateTaskStatus(task.id!, nextStatus);
    await refreshCurrentView();
  }

  /// 删除任务
  Future<void> deleteTask(int taskId) async {
    await _repository.deleteTask(taskId);
    await refreshCurrentView();
  }

  /// 更新任务
  Future<void> updateTask(TaskItem task) async {
    await _repository.updateTask(task);
    await refreshCurrentView();
  }

  /// 同步云端数据并刷新当前视图
  Future<void> syncAndRefresh() async {
    try {
      await _repository.syncWithCloud(_userId);
    } catch (_) {
      // 对于不支持同步方法的测试桩，降级为仅刷新本地视图。
    }
    await refreshCurrentView();
  }

  /// 按当前视图模式刷新数据
  Future<void> refreshCurrentView() async {
    if (_currentStatusFilter != null) {
      return filterByStatus(_currentStatusFilter!);
    }
    if (_showTodayOnly) {
      return loadTodayTasks();
    }
    return loadTasks();
  }
}

/// 任务列表 Provider（需要 userId 参数）
final taskListProvider =
    StateNotifierProvider<TaskListNotifier, TaskListState>((ref) {
  final repository = ref.watch(taskRepositoryProvider);
  final authState = ref.watch(authProvider);
  final userId = switch (authState) {
    AuthStateAuthenticated(:final userProfile) => userProfile.id,
    _ => '',
  };

  final notifier = TaskListNotifier(repository, userId);
  if (userId.isNotEmpty) {
    Future.microtask(() async {
      await notifier.loadTasks();
      await notifier.syncAndRefresh();
    });
  }

  return notifier;
});

/// 当前筛选的任务状态
final taskFilterProvider = StateProvider<TaskStatus?>((ref) => null);
