/// DayFlow - 日记卡片组件
///
/// 在日记列表中展示单条日记摘要，包含日期、情绪和内容预览。
library;

import 'package:flutter/material.dart';
import 'package:dayflow/features/diary/domain/diary_entry.dart';
import 'package:dayflow/shared/utils/date_utils.dart';

/// 日记卡片组件
///
/// 使用 Material 3 Card 风格展示日记条目摘要。
/// 支持点击进入详情和滑动删除。
class DiaryCard extends StatelessWidget {
  /// 日记条目数据
  final DiaryEntry entry;

  /// 点击卡片的回调
  final VoidCallback? onTap;

  /// 滑动删除的回调
  final VoidCallback? onDelete;

  const DiaryCard({
    super.key,
    required this.entry,
    this.onTap,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // 获取内容预览（取前 100 个字符）
    final preview = entry.content.length > 100
        ? '${entry.content.substring(0, 100)}...'
        : entry.content;

    final card = Card(
      elevation: 1,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 顶部：日期 + 情绪表情
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    AppDateUtils.formatChineseDate(entry.date),
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: theme.colorScheme.primary,
                    ),
                  ),
                  if (entry.mood != null)
                    Text(
                      '${entry.mood!.emoji} ${entry.mood!.label}',
                      style: theme.textTheme.labelMedium,
                    ),
                ],
              ),
              const SizedBox(height: 8),
              // 内容预览
              Text(
                preview,
                style: theme.textTheme.bodyMedium,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );

    // 如果提供了删除回调，则包装 Dismissible 支持滑动删除
    if (onDelete != null) {
      return Dismissible(
        key: ValueKey(entry.id),
        direction: DismissDirection.endToStart,
        background: Container(
          alignment: Alignment.centerRight,
          padding: const EdgeInsets.only(right: 20),
          color: theme.colorScheme.error,
          child: Icon(Icons.delete, color: theme.colorScheme.onError),
        ),
        onDismissed: (_) => onDelete!(),
        child: card,
      );
    }
    return card;
  }
}
