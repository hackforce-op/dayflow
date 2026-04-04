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

  /// 点击卡片回调
  final VoidCallback? onTap;

  /// 卡片背景样式标识
  final String backgroundStyle;

  const TaskCard({
    super.key,
    required this.task,
    this.onStatusToggle,
    this.onDelete,
    this.onTap,
    this.backgroundStyle = 'aurora',
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

    final gradient = switch (backgroundStyle) {
      'sunrise' => const [Color(0xFFFFE2C6), Color(0xFFFFF1E6)],
      'forest' => const [Color(0xFFD9F0E1), Color(0xFFF1FAF3)],
      'ocean' => const [Color(0xFFD8EFFF), Color(0xFFF2F8FF)],
      _ => [
          theme.colorScheme.surfaceContainerLow,
          theme.colorScheme.surface,
        ],
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
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: gradient,
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: ListTile(
            onTap: onTap,
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
                ? Text(
                    task.description!,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  )
                : null,
            // 优先级标识 + 删除按钮
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: priorityColor,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.delete_outline),
                  tooltip: '删除任务',
                  onPressed: onDelete,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
