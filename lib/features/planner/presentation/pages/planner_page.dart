/// DayFlow - 规划模块主页面（今日视图）
///
/// 展示今日任务列表，支持创建、编辑和状态切换。
library;

import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:dayflow/features/auth/providers/auth_provider.dart';
import 'package:dayflow/features/planner/domain/task_item.dart';
import 'package:dayflow/features/planner/providers/task_provider.dart';
import 'package:dayflow/features/planner/providers/task_card_preferences_provider.dart';
import 'package:dayflow/features/planner/presentation/widgets/task_card.dart';
import 'package:dayflow/features/planner/presentation/widgets/task_create_dialog.dart';
import 'package:dayflow/shared/widgets/blur_dialog.dart';
import 'package:dayflow/shared/widgets/custom_date_picker.dart';

/// 规划模块主页面
///
/// 显示今日任务列表，可按状态筛选，支持快速创建和状态切换。
class PlannerPage extends ConsumerStatefulWidget {
  const PlannerPage({super.key});

  @override
  ConsumerState<PlannerPage> createState() => _PlannerPageState();
}

class _PlannerPageState extends ConsumerState<PlannerPage> {
  static const _backgroundStyles = <String>[
    'aurora',
    'sunrise',
    'forest',
    'ocean',
  ];

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    if (authState is AuthStateInitial || authState is AuthStateLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (authState is! AuthStateAuthenticated) {
      return const Scaffold(
        body: Center(child: Text('请先登录后查看规划')),
      );
    }

    final taskState = ref.watch(taskListProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('我的规划'),
        actions: [
          // 状态筛选菜单
          PopupMenuButton<String>(
            icon: const Icon(Icons.filter_list),
            onSelected: (value) {
              final notifier = ref.read(taskListProvider.notifier);
              switch (value) {
                case 'all':
                  ref.read(taskFilterProvider.notifier).state = null;
                  notifier.loadTasks();
                  break;
                case 'today':
                  ref.read(taskFilterProvider.notifier).state = null;
                  notifier.loadTodayTasks();
                  break;
                case 'todo':
                  ref.read(taskFilterProvider.notifier).state = TaskStatus.todo;
                  notifier.filterByStatus(TaskStatus.todo);
                  break;
                case 'in_progress':
                  ref.read(taskFilterProvider.notifier).state =
                      TaskStatus.inProgress;
                  notifier.filterByStatus(TaskStatus.inProgress);
                  break;
                case 'done':
                  ref.read(taskFilterProvider.notifier).state = TaskStatus.done;
                  notifier.filterByStatus(TaskStatus.done);
                  break;
              }
            },
            itemBuilder: (_) => [
              const PopupMenuItem(value: 'all', child: Text('全部任务')),
              const PopupMenuItem(value: 'today', child: Text('今日视图')),
              const PopupMenuItem(value: 'todo', child: Text('📋 待办')),
              const PopupMenuItem(value: 'in_progress', child: Text('🔄 进行中')),
              const PopupMenuItem(value: 'done', child: Text('✅ 已完成')),
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
          child: Text('加载失败: $msg',
              style: TextStyle(color: theme.colorScheme.error)),
        ),
      TaskListData(tasks: final tasks) => tasks.isEmpty
          ? const Center(child: Text('今天还没有任务，点击 + 创建一个吧！'))
          : RefreshIndicator(
              onRefresh: () =>
                  ref.read(taskListProvider.notifier).syncAndRefresh(),
              child: ListView.builder(
                padding: const EdgeInsets.only(top: 8, bottom: 80),
                itemCount: tasks.length,
                itemBuilder: (context, index) {
                  final task = tasks[index];
                  final prefKey = taskPreferenceKey(task);
                  final preference =
                      ref.watch(taskCardPreferencesProvider)[prefKey] ??
                          const TaskCardPreferences();

                  return TaskCard(
                    task: task,
                    backgroundStyle: preference.backgroundStyle,
                    onTap: () => _showTaskDetailCard(context, task),
                    onStatusToggle: () {
                      if (task.id == null) {
                        return;
                      }
                      ref
                          .read(taskListProvider.notifier)
                          .toggleTaskStatus(task);
                    },
                    onDelete: () {
                      if (task.id == null) {
                        return;
                      }
                      ref.read(taskListProvider.notifier).deleteTask(task.id!);
                    },
                  );
                },
              ),
            ),
    };
  }

  /// 显示创建任务对话框
  Future<void> _showCreateDialog(BuildContext context) async {
    final created = await showBlurDialog<bool>(
      context: context,
      builder: (_) => const TaskCreateDialog(),
      barrierLabel: '新建规划',
    );

    if (created == true && mounted) {
      await ref.read(taskListProvider.notifier).refreshCurrentView();
    }
  }

  Future<void> _showTaskDetailCard(BuildContext context, TaskItem task) async {
    final prefKey = taskPreferenceKey(task);
    final preference =
        ref.read(taskCardPreferencesProvider.notifier).preferenceOf(prefKey);

    final titleController = TextEditingController(text: task.title);
    final descController = TextEditingController(text: task.description ?? '');

    var selectedPriority = task.priority;
    var selectedStatus = task.status;
    var selectedDueDate = task.dueDate;
    var reminderCount = preference.reminderCount;
    var backgroundStyle = preference.backgroundStyle;

    await showGeneralDialog<void>(
      context: context,
      barrierDismissible: true,
      barrierLabel: '任务详情',
      barrierColor: Colors.black.withAlpha(90),
      pageBuilder: (dialogContext, _, __) {
        return StatefulBuilder(
          builder: (dialogContext, setDialogState) {
            return BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 560),
                  child: Card(
                    margin: const EdgeInsets.symmetric(horizontal: 20),
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: SingleChildScrollView(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              '任务详情',
                              style: Theme.of(context).textTheme.titleLarge,
                            ),
                            const SizedBox(height: 12),
                            TextField(
                              controller: titleController,
                              decoration: const InputDecoration(
                                labelText: '标题',
                              ),
                            ),
                            const SizedBox(height: 12),
                            TextField(
                              controller: descController,
                              decoration: const InputDecoration(
                                labelText: '内容描述',
                              ),
                              maxLines: 3,
                            ),
                            const SizedBox(height: 12),
                            DropdownButtonFormField<TaskPriority>(
                              value: selectedPriority,
                              decoration: const InputDecoration(
                                labelText: '优先级',
                              ),
                              items: TaskPriority.values
                                  .map(
                                    (priority) => DropdownMenuItem(
                                      value: priority,
                                      child: Text(priority.label),
                                    ),
                                  )
                                  .toList(),
                              onChanged: (value) {
                                if (value == null) {
                                  return;
                                }
                                setDialogState(() {
                                  selectedPriority = value;
                                });
                              },
                            ),
                            const SizedBox(height: 12),
                            DropdownButtonFormField<TaskStatus>(
                              value: selectedStatus,
                              decoration: const InputDecoration(
                                labelText: '状态',
                              ),
                              items: TaskStatus.values
                                  .map(
                                    (status) => DropdownMenuItem(
                                      value: status,
                                      child: Text(status.label),
                                    ),
                                  )
                                  .toList(),
                              onChanged: (value) {
                                if (value == null) {
                                  return;
                                }
                                setDialogState(() {
                                  selectedStatus = value;
                                });
                              },
                            ),
                            const SizedBox(height: 12),
                            ListTile(
                              contentPadding: EdgeInsets.zero,
                              title: Text(
                                selectedDueDate == null
                                    ? '未设置截止日期'
                                    : '截止：${selectedDueDate!.year}-${selectedDueDate!.month.toString().padLeft(2, '0')}-${selectedDueDate!.day.toString().padLeft(2, '0')}',
                              ),
                              trailing: const Icon(Icons.calendar_month),
                              onTap: () async {
                                final picked = await showCustomDatePicker(
                                  context: dialogContext,
                                  initialDate:
                                      selectedDueDate ?? DateTime.now(),
                                  firstDate: DateTime(2020),
                                  lastDate: DateTime(2100),
                                );
                                if (picked == null) {
                                  return;
                                }
                                setDialogState(() {
                                  selectedDueDate = picked;
                                });
                              },
                            ),
                            const SizedBox(height: 8),
                            Text(
                              '提醒次数',
                              style: Theme.of(context).textTheme.labelLarge,
                            ),
                            Slider(
                              value: reminderCount.toDouble(),
                              min: 0,
                              max: 10,
                              divisions: 10,
                              label: '$reminderCount 次',
                              onChanged: (value) {
                                setDialogState(() {
                                  reminderCount = value.round();
                                });
                              },
                            ),
                            const SizedBox(height: 8),
                            Text(
                              '背景样式',
                              style: Theme.of(context).textTheme.labelLarge,
                            ),
                            const SizedBox(height: 8),
                            Wrap(
                              spacing: 8,
                              children: _backgroundStyles
                                  .map(
                                    (style) => ChoiceChip(
                                      label: Text(style),
                                      selected: backgroundStyle == style,
                                      onSelected: (_) {
                                        setDialogState(() {
                                          backgroundStyle = style;
                                        });
                                      },
                                    ),
                                  )
                                  .toList(),
                            ),
                            const SizedBox(height: 20),
                            Row(
                              children: [
                                TextButton.icon(
                                  onPressed: () async {
                                    if (task.id == null) {
                                      return;
                                    }
                                    await ref
                                        .read(taskListProvider.notifier)
                                        .deleteTask(task.id!);
                                    if (!mounted) {
                                      return;
                                    }
                                    Navigator.of(dialogContext).pop();
                                  },
                                  icon: const Icon(Icons.delete_outline),
                                  label: const Text('删除'),
                                  style: TextButton.styleFrom(
                                    foregroundColor:
                                        Theme.of(context).colorScheme.error,
                                  ),
                                ),
                                const Spacer(),
                                TextButton(
                                  onPressed: () =>
                                      Navigator.of(dialogContext).pop(),
                                  child: const Text('取消'),
                                ),
                                const SizedBox(width: 8),
                                FilledButton(
                                  onPressed: () async {
                                    if (task.id == null) {
                                      return;
                                    }

                                    final updatedTask = task.copyWith(
                                      title: titleController.text.trim().isEmpty
                                          ? task.title
                                          : titleController.text.trim(),
                                      description:
                                          descController.text.trim().isEmpty
                                              ? null
                                              : descController.text.trim(),
                                      priority: selectedPriority,
                                      status: selectedStatus,
                                      dueDate: selectedDueDate,
                                    );

                                    await ref
                                        .read(taskListProvider.notifier)
                                        .updateTask(updatedTask);

                                    await ref
                                        .read(taskCardPreferencesProvider
                                            .notifier)
                                        .setPreference(
                                          prefKey,
                                          TaskCardPreferences(
                                            reminderCount: reminderCount,
                                            backgroundStyle: backgroundStyle,
                                          ),
                                        );

                                    if (!mounted) {
                                      return;
                                    }
                                    Navigator.of(dialogContext).pop();
                                  },
                                  child: const Text('保存'),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );

    titleController.dispose();
    descController.dispose();
  }
}
