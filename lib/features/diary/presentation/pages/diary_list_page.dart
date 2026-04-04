/// DayFlow - 日记列表页面
///
/// 展示用户所有日记条目，按年/月分组显示区段标题。
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:dayflow/features/auth/providers/auth_provider.dart';
import 'package:dayflow/features/diary/domain/diary_entry.dart';
import 'package:dayflow/features/diary/providers/diary_provider.dart';
import 'package:dayflow/features/diary/presentation/widgets/diary_card.dart';
import 'package:dayflow/features/settings/presentation/pages/settings_page.dart';
import 'package:dayflow/shared/widgets/blur_dialog.dart';

/// 日记列表页面
///
/// 主要功能：
/// - 按年/月分组展示日记列表，顶部显示 "YYYY年 M月" 标题
/// - 支持搜索和日期筛选
/// - 下拉刷新同步云端数据
/// - 点击 FAB 创建新日记
class DiaryListPage extends ConsumerStatefulWidget {
  /// 所属日记本 ID（为 null 时显示所有日记）
  final int? notebookId;

  const DiaryListPage({super.key, this.notebookId});

  @override
  ConsumerState<DiaryListPage> createState() => _DiaryListPageState();
}

class _DiaryListPageState extends ConsumerState<DiaryListPage> {
  /// 是否处于搜索模式
  bool _isSearching = false;

  /// 是否应用了日期筛选
  bool _hasDateFilter = false;

  /// 搜索文本控制器
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final theme = Theme.of(context);

    if (authState is AuthStateInitial || authState is AuthStateLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (authState is! AuthStateAuthenticated) {
      return const Scaffold(
        body: Center(child: Text('请先登录后查看日记')),
      );
    }

    final userId = authState.userProfile.id;
    final rawDiaryState = ref.watch(diaryListProvider(userId));
    final diaryState = _filterDiaryState(rawDiaryState);

    return Scaffold(
      appBar: AppBar(
        title: _isSearching
            ? TextField(
                controller: _searchController,
                autofocus: true,
                decoration: const InputDecoration(
                  hintText: '搜索日记...',
                  border: InputBorder.none,
                ),
                onSubmitted: (value) {
                  ref.read(diaryListProvider(userId).notifier).search(value);
                },
              )
            : const Text('我的日记'),
        actions: [
          // 移动端：显示设置入口（桌面端通过侧边栏设置按钮访问）
          if (MediaQuery.sizeOf(context).width < 960)
            IconButton(
              icon: const Icon(Icons.settings_outlined),
              tooltip: '设置',
              onPressed: () => showSettingsDialog(context),
            ),
          // 搜索按钮
          IconButton(
            icon: Icon(_isSearching ? Icons.close : Icons.search),
            onPressed: () {
              setState(() {
                _isSearching = !_isSearching;
                if (!_isSearching) {
                  _searchController.clear();
                  ref.read(diaryListProvider(userId).notifier).loadEntries();
                }
              });
            },
          ),
          // 日期筛选按钮
          IconButton(
            icon: const Icon(Icons.calendar_month),
            onPressed: () => _showDatePicker(context),
          ),
          // 重置筛选按钮（仅在筛选激活时显示）
          if (_hasDateFilter)
            IconButton(
              icon: const Icon(Icons.filter_alt_off),
              tooltip: '重置筛选',
              onPressed: _resetFilter,
            ),
        ],
      ),
      body: _buildBody(diaryState, theme, userId),
      // 新建日记浮动按钮
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final notebookParam = widget.notebookId != null
              ? '?notebookId=${widget.notebookId}'
              : '';
          await context.push('/diary/edit$notebookParam');
          if (!mounted) {
            return;
          }
          await ref.read(diaryListProvider(userId).notifier).refresh();
        },
        child: const Icon(Icons.add),
      ),
    );
  }

  /// 根据当前日记本 ID 对列表状态做本地过滤。
  ///
  /// 当前数据层仍以“用户全部日记”为基础状态，笔记本页面在 UI 层按
  /// [widget.notebookId] 做二次过滤，确保“日记本内只展示所属日记”。
  DiaryListState _filterDiaryState(DiaryListState state) {
    final notebookId = widget.notebookId;
    if (notebookId == null || state is! DiaryListData) {
      return state;
    }

    final filteredEntries = state.entries
        .where((entry) => entry.notebookId == notebookId)
        .toList(growable: false);
    return DiaryListData(filteredEntries);
  }

  /// 根据状态构建页面主体
  Widget _buildBody(DiaryListState state, ThemeData theme, String userId) {
    return switch (state) {
      DiaryListLoading() => const Center(child: CircularProgressIndicator()),
      DiaryListError(message: final msg) => Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('加载失败: $msg',
                  style: TextStyle(color: theme.colorScheme.error)),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () =>
                    ref.read(diaryListProvider(userId).notifier).loadEntries(),
                child: const Text('重试'),
              ),
            ],
          ),
        ),
      DiaryListData(entries: final entries) => entries.isEmpty
          ? Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    _isSearching
                        ? '未找到匹配的日记'
                        : _hasDateFilter
                            ? '所选日期范围内没有日记'
                            : '还没有日记，点击 + 开始写第一篇吧！',
                    style: theme.textTheme.bodyLarge?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  if (_hasDateFilter) ...[
                    const SizedBox(height: 12),
                    TextButton.icon(
                      onPressed: _resetFilter,
                      icon: const Icon(Icons.refresh, size: 18),
                      label: const Text('重置筛选'),
                    ),
                  ],
                ],
              ),
            )
          : RefreshIndicator(
              onRefresh: () =>
                  ref.read(diaryListProvider(userId).notifier).syncAndRefresh(),
              child: _buildGroupedList(entries, theme, userId),
            ),
    };
  }

  /// 将日记列表按年/月分组后渲染，每组前加 "YYYY年 M月" 标题行
  Widget _buildGroupedList(
      List<DiaryEntry> entries, ThemeData theme, String userId) {
    // 构建分组后的 item 列表（字符串表示区段标题，DiaryEntry 表示卡片）
    final List<Object> items = [];
    // 记录每条 entry 是否为当天第一条/最后一条（用于 DiaryCard 日期融合）
    final Map<int, bool> isFirstOfDayMap = {};
    final Map<int, bool> isLastOfDayMap = {};
    String? lastGroupKey;
    String? lastDayKey;

    for (var i = 0; i < entries.length; i++) {
      final entry = entries[i];
      // 按 date 字段分组（年 + 月）
      final groupKey = '${entry.date.year}年 ${entry.date.month}月';
      if (groupKey != lastGroupKey) {
        items.add(groupKey); // 区段标题
        lastGroupKey = groupKey;
        lastDayKey = null; // 新的月份组，重置天标记
      }

      // 判断是否为当天第一条
      final dayKey = '${entry.date.year}-${entry.date.month}-${entry.date.day}';
      final isFirst = dayKey != lastDayKey;
      isFirstOfDayMap[items.length] = isFirst;
      lastDayKey = dayKey;

      items.add(entry);

      // 检查下一条是否同一天，以确定 isLastOfDay
      String? nextDayKey;
      if (i + 1 < entries.length) {
        final nextEntry = entries[i + 1];
        // 如果下一条属于不同月份组，也视为最后一条
        final nextGroupKey = '${nextEntry.date.year}年 ${nextEntry.date.month}月';
        if (nextGroupKey == groupKey) {
          nextDayKey =
              '${nextEntry.date.year}-${nextEntry.date.month}-${nextEntry.date.day}';
        }
      }
      isLastOfDayMap[items.length - 1] = nextDayKey != dayKey;
    }

    return ListView.builder(
      padding: const EdgeInsets.only(top: 8, bottom: 80),
      itemCount: items.length,
      itemBuilder: (context, index) {
        final item = items[index];

        // 区段标题行
        if (item is String) {
          return _buildSectionHeader(item, theme);
        }

        // 日记卡片
        final entry = item as DiaryEntry;
        return RepaintBoundary(
          child: DiaryCard(
            entry: entry,
            isFirstOfDay: isFirstOfDayMap[index] ?? true,
            isLastOfDay: isLastOfDayMap[index] ?? true,
            onTap: () async {
              await context.push('/diary/view/${entry.id}');
              if (!mounted) return;
              await ref.read(diaryListProvider(userId).notifier).refresh();
            },
            onDelete: () async {
              await ref
                  .read(diaryListProvider(userId).notifier)
                  .deleteEntry(entry.id!);
            },
          ),
        );
      },
    );
  }

  /// 构建年/月分组标题行（如 "2025年 6月"）
  Widget _buildSectionHeader(String title, ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.only(left: 20, right: 16, top: 16, bottom: 4),
      child: Text(
        title,
        style: theme.textTheme.titleSmall?.copyWith(
          color: theme.colorScheme.primary,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  /// 重置日期筛选，恢复显示全部日记
  void _resetFilter() {
    final authState = ref.read(authProvider);
    if (authState is! AuthStateAuthenticated) return;
    setState(() => _hasDateFilter = false);
    ref
        .read(diaryListProvider(authState.userProfile.id).notifier)
        .loadEntries();
  }

  /// 显示日期范围选择器进行筛选
  Future<void> _showDatePicker(BuildContext context) async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
      locale: const Locale('zh', 'CN'),
      builder: blurPopupBuilder,
    );
    if (picked != null) {
      final authState = ref.read(authProvider);
      if (authState is! AuthStateAuthenticated) {
        return;
      }

      setState(() => _hasDateFilter = true);

      ref
          .read(diaryListProvider(authState.userProfile.id).notifier)
          .loadByDateRange(
            picked.start,
            picked.end,
          );
    }
  }
}
