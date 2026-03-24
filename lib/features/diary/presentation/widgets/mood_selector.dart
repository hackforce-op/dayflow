/// DayFlow - 情绪选择器组件
///
/// 提供水平滚动的情绪选项列表，用户可以选择当前心情。
/// 每个情绪选项包含表情符号和中文标签。
library;

import 'package:flutter/material.dart';
import 'package:dayflow/features/diary/domain/diary_entry.dart';

/// 情绪选择器组件
///
/// 显示所有可用的情绪选项，支持单选。
/// [selectedMood] 当前选中的情绪
/// [onMoodSelected] 情绪选择回调
class MoodSelector extends StatelessWidget {
  /// 当前选中的情绪
  final Mood? selectedMood;

  /// 情绪选择变更回调
  final ValueChanged<Mood> onMoodSelected;

  const MoodSelector({
    super.key,
    this.selectedMood,
    required this.onMoodSelected,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SizedBox(
      height: 48,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: Mood.values.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final mood = Mood.values[index];
          final isSelected = mood == selectedMood;
          return ChoiceChip(
            label: Text('${mood.emoji} ${mood.label}'),
            selected: isSelected,
            onSelected: (_) => onMoodSelected(mood),
            selectedColor: theme.colorScheme.primaryContainer,
            labelStyle: TextStyle(
              color: isSelected
                  ? theme.colorScheme.onPrimaryContainer
                  : theme.colorScheme.onSurface,
            ),
          );
        },
      ),
    );
  }
}
