/// DayFlow - 规划模块主页面（今日视图）
///
/// 展示今日任务列表，支持创建、编辑和状态切换。
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dayflow/features/planner/domain/task_item.dart';
import 'package:dayflow/features/planner/providers/task_provider.dart';
import 'package:dayflow/features/planner/presentation/widgets/task_card.dart';
import 'package:dayflow/features/planner/presentation/widgets/task_create_dialog.dart';

/// 规划模块主页面
///
/// 显示今日任务列表，可按状态筛选，支持快速创建和状态切换。
class PlannerPage extends ConsumerStatefulWidget {
  const PlannerPage({super.key});

  @override
  ConsumerState<PlannerPage> createState() => _PlannerPageState();
}

class _PlannerPageState extends ConsumerState<PlannerPage> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      ref.read(taskListProvider.notifier).loadTodayTasks();
    });
  }

  @override
  Widget build(BuildContext context) {
    final taskState = ref.watch(taskListProvider);
    final filter = ref.watch(taskFilterProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('今日规划'),
        actions: [
          // 状态筛选菜单
          PopupMenuButton<TaskStatus?>(
            icon: const Icon(Icons.filter_list),
            onSelected: (status) {
              ref.read(taskFilterProvider.notifier).state = status;
              if (status == null) {
                ref.read(taskListProvider.notifier).loadTodayTasks();
              } else {
                ref.read(taskListProvider.notifier).filterByStatus(status);
              }
            },
            itemBuilder: (_) => [
              const PopupMenuItem(value: null, child: Text('全部')),
              const PopupMenuItem(value: TaskStatus.todo, child: Text('📋 待办')),
              const PopupMenuItem(value: TaskStatus.inProgress, child: Text('🔄 进行中')),
              const PopupMenuItem(value: TaskStatus.done, child: Text('✅ 已完成')),
            ],
          ),
        ],
      ),
      body: _buildBody(taskState, theme),
      // 新建任务按钮
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showCreateDialog(context),
        child: const Icon(Icons.add),
      ),
    );
  }

  /// 构建页面主体内容
  Widget _buildBody(TaskListState state, ThemeData theme) {
    return switch (state) {
      TaskListLoading() => const Center(child: CircularProgressIndicator()),
      TaskListError(message: final msg) => Center(
          child: Text('加载失败: $msg', style: TextStyle(color: theme.colorScheme.error)),
        ),
      TaskListData(tasks: final tasks) => tasks.isEmpty
          ? const Center(child: Text('今天还没有任务，点击 + 创建一个吧！'))
          : ListView.builder(
              padding: const EdgeInsets.only(top: 8, bottom: 80),
              itemCount: tasks.length,
              itemBuilder: (context, index) {
                final task = tasks[index];
                return TaskCard(
                  task: task,
                  onStatusToggle: () {
                    ref.read(taskListProvider.notifier).toggleTaskStatus(task);
                  },
                  onDelete: () {
                    ref.read(taskListProvider.notifier).deleteTask(task.id!);
                  },
                );
              },
            ),
    };
  }

  /// 显示创建任务对话框
  void _showCreateDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => const TaskCreateDialog(),
    );
  }
}
