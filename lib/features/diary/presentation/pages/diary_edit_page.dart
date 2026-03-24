/// DayFlow - 日记编辑页面
///
/// 支持创建新日记和编辑已有日记，使用富文本编辑器。
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:dayflow/features/diary/domain/diary_entry.dart';
import 'package:dayflow/features/diary/providers/diary_provider.dart';
import 'package:dayflow/features/diary/presentation/widgets/mood_selector.dart';
import 'package:dayflow/shared/utils/date_utils.dart';

/// 日记编辑页面
///
/// 功能：
/// - 富文本编辑（简化版，使用 TextField multiline）
/// - 情绪标签选择
/// - 保存/删除操作
/// - 支持新建和编辑两种模式
class DiaryEditPage extends ConsumerStatefulWidget {
  /// 日记 ID，为 null 表示新建模式
  final int? diaryId;

  const DiaryEditPage({super.key, this.diaryId});

  @override
  ConsumerState<DiaryEditPage> createState() => _DiaryEditPageState();
}

class _DiaryEditPageState extends ConsumerState<DiaryEditPage> {
  /// 内容文本控制器
  final _contentController = TextEditingController();

  /// 当前选中的情绪
  Mood? _selectedMood;

  /// 当前日期
  DateTime _date = DateTime.now();

  /// 是否为编辑模式
  bool get _isEditing => widget.diaryId != null;

  @override
  void initState() {
    super.initState();
    if (_isEditing) {
      // 编辑模式：加载已有日记
      Future.microtask(() {
        ref.read(diaryEditorProvider.notifier).loadEntry(widget.diaryId!);
      });
    } else {
      // 新建模式：初始化空白日记
      Future.microtask(() {
        ref.read(diaryEditorProvider.notifier).initNew();
      });
    }
  }

  @override
  void dispose() {
    _contentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final editorState = ref.watch(diaryEditorProvider);
    final theme = Theme.of(context);

    // 监听编辑器状态变化，更新 UI
    ref.listen<DiaryEditorState>(diaryEditorProvider, (prev, next) {
      if (next is DiaryEditorLoaded && prev is! DiaryEditorLoaded) {
        // 加载完成时填充数据
        _contentController.text = next.entry.content;
        setState(() {
          _selectedMood = next.entry.mood;
          _date = next.entry.date;
        });
      } else if (next is DiaryEditorSaved) {
        // 保存成功提示并返回
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('日记已保存')),
        );
        context.pop();
      } else if (next is DiaryEditorError) {
        // 显示错误提示
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('操作失败: ${next.message}')),
        );
      }
    });

    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? '编辑日记' : '写日记'),
        actions: [
          // 保存按钮
          if (editorState is DiaryEditorSaving)
            const Padding(
              padding: EdgeInsets.all(16),
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            )
          else
            IconButton(
              icon: const Icon(Icons.check),
              onPressed: _saveEntry,
            ),
          // 编辑模式下显示删除按钮
          if (_isEditing)
            IconButton(
              icon: const Icon(Icons.delete_outline),
              onPressed: () => _confirmDelete(context),
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 日期显示
            Text(
              AppDateUtils.formatChineseDate(_date),
              style: theme.textTheme.titleMedium?.copyWith(
                color: theme.colorScheme.primary,
              ),
            ),
            const SizedBox(height: 16),

            // 情绪选择器
            Text('今天的心情', style: theme.textTheme.labelLarge),
            const SizedBox(height: 8),
            MoodSelector(
              selectedMood: _selectedMood,
              onMoodSelected: (mood) => setState(() => _selectedMood = mood),
            ),
            const SizedBox(height: 24),

            // 内容编辑区域（简化版富文本，使用多行 TextField）
            Text('日记内容', style: theme.textTheme.labelLarge),
            const SizedBox(height: 8),
            TextField(
              controller: _contentController,
              maxLines: null,
              minLines: 15,
              decoration: InputDecoration(
                hintText: '记录今天的故事...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                fillColor: theme.colorScheme.surfaceContainerLowest,
              ),
              style: theme.textTheme.bodyLarge,
            ),
          ],
        ),
      ),
    );
  }

  /// 保存日记条目
  void _saveEntry() {
    final content = _contentController.text.trim();
    if (content.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('请输入日记内容')),
      );
      return;
    }

    final entry = DiaryEntry(
      id: widget.diaryId,
      content: content,
      mood: _selectedMood,
      date: _date,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      userId: '', // 由 repository 层填充实际用户 ID
    );

    ref.read(diaryEditorProvider.notifier).saveEntry(entry);
  }

  /// 确认删除对话框
  Future<void> _confirmDelete(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('确认删除'),
        content: const Text('确定要删除这篇日记吗？此操作不可撤销。'),
        actions: [
          TextButton(onPressed: () => ctx.pop(false), child: const Text('取消')),
          TextButton(
            onPressed: () => ctx.pop(true),
            style: TextButton.styleFrom(foregroundColor: Theme.of(context).colorScheme.error),
            child: const Text('删除'),
          ),
        ],
      ),
    );
    if (confirmed == true && widget.diaryId != null) {
      ref.read(diaryEditorProvider.notifier).deleteEntry(widget.diaryId!);
      if (mounted) context.pop();
    }
  }
}
