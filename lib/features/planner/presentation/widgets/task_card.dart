/// DayFlow - 任务卡片组件
///
/// 展示单个任务条目，支持状态切换和滑动删除。
library;

import 'package:flutter/material.dart';
import 'package:dayflow/features/planner/domain/task_item.dart';

/// 任务卡片组件
class TaskCard extends StatelessWidget {
  /// 任务数据
  final TaskItem task;

  /// 状态切换回调
  final VoidCallback? onStatusToggle;

  /// 删除回调
  final VoidCallback? onDelete;

  const TaskCard({
    super.key,
    required this.task,
    this.onStatusToggle,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // 根据状态设置视觉样式
    final isDone = task.status == TaskStatus.done;
    final statusIcon = switch (task.status) {
      TaskStatus.todo => Icons.radio_button_unchecked,
      TaskStatus.inProgress => Icons.timelapse,
      TaskStatus.done => Icons.check_circle,
    };
    final statusColor = switch (task.status) {
      TaskStatus.todo => theme.colorScheme.outline,
      TaskStatus.inProgress => Colors.orange,
      TaskStatus.done => Colors.green,
    };

    // 优先级标识颜色
    final priorityColor = switch (task.priority) {
      TaskPriority.high => Colors.red,
      TaskPriority.medium => Colors.orange,
      TaskPriority.low => Colors.blue,
    };

    return Dismissible(
      key: ValueKey(task.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        color: theme.colorScheme.error,
        child: Icon(Icons.delete, color: theme.colorScheme.onError),
      ),
      onDismissed: (_) => onDelete?.call(),
      child: Card(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        child: ListTile(
          // 状态切换图标
          leading: IconButton(
            icon: Icon(statusIcon, color: statusColor),
            onPressed: onStatusToggle,
          ),
          // 任务标题
          title: Text(
            task.title,
            style: isDone
                ? theme.textTheme.bodyLarge?.copyWith(
                    decoration: TextDecoration.lineThrough,
                    color: theme.colorScheme.outline,
                  )
                : theme.textTheme.bodyLarge,
          ),
          // 描述和截止日期
          subtitle: task.description != null
              ? Text(task.description!, maxLines: 1, overflow: TextOverflow.ellipsis)
              : null,
          // 优先级标识
          trailing: Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: priorityColor,
              shape: BoxShape.circle,
            ),
          ),
        ),
      ),
    );
  }
}
