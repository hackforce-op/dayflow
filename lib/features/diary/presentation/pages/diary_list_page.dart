/// DayFlow - 日记列表页面
///
/// 展示用户所有日记条目，支持按日期筛选和搜索。
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:dayflow/features/auth/providers/auth_provider.dart';
import 'package:dayflow/features/diary/providers/diary_provider.dart';
import 'package:dayflow/features/diary/presentation/widgets/diary_card.dart';

/// 日记列表页面
///
/// 主要功能：
/// - 按日期分组展示日记列表
/// - 支持搜索和日期筛选
/// - 下拉刷新同步云端数据
/// - 点击 FAB 创建新日记
class DiaryListPage extends ConsumerStatefulWidget {
  const DiaryListPage({super.key});

  @override
  ConsumerState<DiaryListPage> createState() => _DiaryListPageState();
}

class _DiaryListPageState extends ConsumerState<DiaryListPage> {
  /// 是否处于搜索模式
  bool _isSearching = false;

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
    final diaryState = ref.watch(diaryListProvider(userId));

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
        ],
      ),
      body: _buildBody(diaryState, theme, userId),
      // 新建日记浮动按钮
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.push('/diary/edit'),
        child: const Icon(Icons.add),
      ),
    );
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
          ? const Center(child: Text('还没有日记，点击 + 开始写第一篇吧！'))
          : RefreshIndicator(
              onRefresh: () =>
                  ref.read(diaryListProvider(userId).notifier).syncAndRefresh(),
              child: ListView.builder(
                padding: const EdgeInsets.only(top: 8, bottom: 80),
                itemCount: entries.length,
                itemBuilder: (context, index) {
                  final entry = entries[index];
                  return DiaryCard(
                    entry: entry,
                    onTap: () => context.push('/diary/edit/${entry.id}'),
                    onDelete: () {
                      ref
                          .read(diaryListProvider(userId).notifier)
                          .deleteEntry(entry.id!);
                    },
                  );
                },
              ),
            ),
    };
  }

  /// 显示日期选择器进行筛选
  Future<void> _showDatePicker(BuildContext context) async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      locale: const Locale('zh', 'CN'),
    );
    if (picked != null) {
      final authState = ref.read(authProvider);
      if (authState is! AuthStateAuthenticated) {
        return;
      }

      ref
          .read(diaryListProvider(authState.userProfile.id).notifier)
          .loadByDateRange(
            picked.start,
            picked.end,
          );
    }
  }
}
