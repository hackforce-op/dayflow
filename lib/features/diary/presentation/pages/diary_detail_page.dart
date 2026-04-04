/// DayFlow - 日记详情页面
///
/// 用于只读浏览整篇日记内容，右上角提供编辑入口。
library;

import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:dayflow/core/constants/app_constants.dart';
import 'package:dayflow/core/router/app_router.dart';
import 'package:dayflow/features/diary/domain/diary_entry.dart';
import 'package:dayflow/features/diary/providers/diary_provider.dart';
import 'package:dayflow/features/diary/presentation/widgets/diary_image_embed.dart';
import 'package:dayflow/shared/utils/date_utils.dart';

class DiaryDetailPage extends ConsumerStatefulWidget {
  const DiaryDetailPage({
    super.key,
    required this.diaryId,
  });

  final int diaryId;

  @override
  ConsumerState<DiaryDetailPage> createState() => _DiaryDetailPageState();
}

class _DiaryDetailPageState extends ConsumerState<DiaryDetailPage> {
  QuillController? _quillController;
  String? _boundSignature;

  /// 「点击即可编辑」开关状态
  bool _tapToEdit = false;

  @override
  void initState() {
    super.initState();
    _loadTapToEditPref();
  }

  /// 从 SharedPreferences 加载「点击即可编辑」偏好
  Future<void> _loadTapToEditPref() async {
    final prefs = await SharedPreferences.getInstance();
    if (mounted) {
      setState(() {
        _tapToEdit = prefs.getBool(AppConstants.tapToEditPrefsKey) ?? false;
      });
    }
  }

  @override
  void dispose() {
    _quillController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final entryAsync = ref.watch(diaryEntryProvider(widget.diaryId));
    final theme = Theme.of(context);

    final entry = entryAsync.valueOrNull;
    if (entry != null) {
      _bindController(entry);
    }

    return Scaffold(
      appBar: AppBar(
        // 将日期和心情显示在标题栏，替代原来的「日记详情」
        title: entry != null
            ? Row(
                children: [
                  Flexible(
                    child: Text(
                      '${AppDateUtils.formatChineseDate(entry.date)} ${AppDateUtils.formatWeekday(entry.date)}',
                      style: Theme.of(context).textTheme.titleMedium,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (entry.mood != null) ...[
                    const SizedBox(width: 8),
                    Text(
                      '${entry.mood!.emoji} ${entry.mood!.label}',
                      style: Theme.of(context).textTheme.labelLarge,
                    ),
                  ],
                ],
              )
            : null,
        actions: [
          if (entry != null)
            IconButton(
              icon: const Icon(Icons.edit_outlined),
              tooltip: '编辑',
              onPressed: _navigateToEdit,
            ),
        ],
      ),
      body: entryAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '加载日记失败: $error',
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: theme.colorScheme.error,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                FilledButton(
                  onPressed: () =>
                      ref.invalidate(diaryEntryProvider(widget.diaryId)),
                  child: const Text('重试'),
                ),
              ],
            ),
          ),
        ),
        data: (loadedEntry) {
          if (loadedEntry == null || _quillController == null) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '这篇日记不存在或已经被删除。',
                      style: theme.textTheme.bodyLarge,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 12),
                    FilledButton(
                      onPressed: () => context.pop(),
                      child: const Text('返回列表'),
                    ),
                  ],
                ),
              ),
            );
          }

          return Column(
            children: [
              _buildMetaHeader(loadedEntry, theme),
              const Divider(height: 1),
              Expanded(
                child: Stack(
                  children: [
                    // 底层：QuillEditor 保持正常滚动功能
                    Padding(
                      padding: const EdgeInsets.fromLTRB(12, 8, 12, 16),
                      child: QuillEditor.basic(
                        controller: _quillController!,
                        config: QuillEditorConfig(
                          padding: const EdgeInsets.all(8),
                          showCursor: false,
                          scrollPhysics: const ClampingScrollPhysics(),
                          embedBuilders: [
                            DiaryImageEmbedBuilder(),
                          ],
                        ),
                      ),
                    ),
                    // 顶层透明层：仅在启用「点击即可编辑」时捕获 tap，不阻断滚动
                    if (_tapToEdit)
                      Positioned.fill(
                        child: GestureDetector(
                          behavior: HitTestBehavior.translucent,
                          onTap: () => _navigateToEdit(),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  /// 构建精简元信息行（时间+位置），日期和心情已移至 AppBar
  Widget _buildMetaHeader(DiaryEntry entry, ThemeData theme) {
    final locationLabel = _displayLocationLabel(entry.locationName);

    // 如果没有位置信息，只显示时间
    return Container(
      width: double.infinity,
      color: theme.colorScheme.surfaceContainerLowest,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          Text(
            AppDateUtils.formatTimeWithSeconds(entry.date),
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          if (locationLabel != null) ...[
            const SizedBox(width: 12),
            Icon(
              Icons.location_on,
              size: 14,
              color: theme.colorScheme.tertiary,
            ),
            const SizedBox(width: 4),
            Expanded(
              child: Text(
                locationLabel,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.tertiary,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ],
      ),
    );
  }

  /// 跳转到编辑页面并在返回后刷新数据
  Future<void> _navigateToEdit() async {
    await context.push('${RoutePaths.diaryEdit}/${widget.diaryId}');
    if (!mounted) return;
    ref.invalidate(diaryEntryProvider(widget.diaryId));
  }

  void _bindController(DiaryEntry entry) {
    final signature =
        '${entry.id}:${entry.updatedAt.microsecondsSinceEpoch}:${entry.content.hashCode}';
    if (_boundSignature == signature) {
      return;
    }

    final oldController = _quillController;
    final newController = QuillController(
      document: _documentFromContent(entry.content),
      selection: const TextSelection.collapsed(offset: 0),
    )..readOnly = true;

    _quillController = newController;
    _boundSignature = signature;
    oldController?.dispose();
  }

  Document _documentFromContent(String content) {
    try {
      if (content.trim().isEmpty) {
        return Document();
      }

      final decoded = jsonDecode(content);
      if (decoded is List) {
        // 兼容历史图片 embed 数据，确保详情页也能稳定回显图片。
        return Document.fromJson(normalizeDiaryDeltaImageInserts(decoded));
      }
    } catch (_) {
      // 旧纯文本内容降级为普通文档展示。
    }

    final document = Document();
    document.insert(0, content);
    return document;
  }

  String? _displayLocationLabel(String? rawLabel) {
    final label = rawLabel?.trim();
    if (label == null || label.isEmpty) {
      return null;
    }
    if (_looksLikeCoordinates(label)) {
      return '当前位置附近';
    }
    return label;
  }

  bool _looksLikeCoordinates(String value) {
    return RegExp(r'^-?\d+(?:\.\d+)?\s*,\s*-?\d+(?:\.\d+)?$').hasMatch(value);
  }
}
