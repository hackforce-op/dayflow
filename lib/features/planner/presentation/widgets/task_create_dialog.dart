/// DayFlow - 新建任务对话框
///
/// 用于快速创建新任务的弹窗表单。
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:dayflow/features/auth/providers/auth_provider.dart';
import 'package:dayflow/features/planner/domain/task_item.dart';
import 'package:dayflow/features/planner/data/task_repository.dart';
import 'package:dayflow/features/planner/providers/task_provider.dart';

/// 新建任务对话框
class TaskCreateDialog extends ConsumerStatefulWidget {
  const TaskCreateDialog({super.key});

  @override
  ConsumerState<TaskCreateDialog> createState() => _TaskCreateDialogState();
}

class _TaskCreateDialogState extends ConsumerState<TaskCreateDialog> {
  final _titleController = TextEditingController();
  final _descController = TextEditingController();
  TaskPriority _priority = TaskPriority.medium;
  DateTime? _dueDate;

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('新建任务'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 标题输入
            TextField(
              controller: _titleController,
              decoration: const InputDecoration(
                labelText: '任务标题',
                hintText: '输入任务标题...',
              ),
              autofocus: true,
            ),
            const SizedBox(height: 12),
            // 描述输入
            TextField(
              controller: _descController,
              decoration: const InputDecoration(
                labelText: '描述（可选）',
                hintText: '输入任务描述...',
              ),
              maxLines: 2,
            ),
            const SizedBox(height: 12),
            // 优先级选择
            Row(
              children: [
                const Text('优先级：'),
                const SizedBox(width: 8),
                ChoiceChip(
                  label: const Text('高'),
                  selected: _priority == TaskPriority.high,
                  onSelected: (_) =>
                      setState(() => _priority = TaskPriority.high),
                  selectedColor: Colors.red.shade100,
                ),
                const SizedBox(width: 4),
                ChoiceChip(
                  label: const Text('中'),
                  selected: _priority == TaskPriority.medium,
                  onSelected: (_) =>
                      setState(() => _priority = TaskPriority.medium),
                  selectedColor: Colors.orange.shade100,
                ),
                const SizedBox(width: 4),
                ChoiceChip(
                  label: const Text('低'),
                  selected: _priority == TaskPriority.low,
                  onSelected: (_) =>
                      setState(() => _priority = TaskPriority.low),
                  selectedColor: Colors.blue.shade100,
                ),
              ],
            ),
            const SizedBox(height: 12),
            // 截止日期选择
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(_dueDate != null
                  ? '截止：${_dueDate!.month}/${_dueDate!.day}'
                  : '设置截止日期'),
              trailing: const Icon(Icons.calendar_today),
              onTap: () async {
                final date = await showDatePicker(
                  context: context,
                  initialDate: DateTime.now(),
                  firstDate: DateTime.now(),
                  lastDate: DateTime.now().add(const Duration(days: 365)),
                );
                if (date != null) setState(() => _dueDate = date);
              },
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('取消'),
        ),
        FilledButton(
          onPressed: _createTask,
          child: const Text('创建'),
        ),
      ],
    );
  }

  /// 创建任务
  Future<void> _createTask() async {
    final title = _titleController.text.trim();
    if (title.isEmpty) return;

    final authState = ref.read(authProvider);
    if (authState is! AuthStateAuthenticated) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('请先登录后再创建任务')),
      );
      return;
    }

    final task = TaskItem(
      title: title,
      description: _descController.text.trim().isNotEmpty
          ? _descController.text.trim()
          : null,
      priority: _priority,
      status: TaskStatus.todo,
      dueDate: _dueDate,
      sortOrder: 0,
      createdAt: DateTime.now(),
      userId: authState.userProfile.id,
    );

    await ref.read(taskRepositoryProvider).createTask(task);
    await ref.read(taskListProvider.notifier).loadTodayTasks();

    if (!mounted) {
      return;
    }

    Navigator.pop(context);
  }
}
