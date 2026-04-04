/// DayFlow - 日记本列表页面
///
/// 以网格形式展示用户的所有日记本，支持创建、重命名、换封面、删除等操作。
/// 点击日记本后进入该日记本的日记列表。
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:dayflow/features/auth/providers/auth_provider.dart';
import 'package:dayflow/features/diary/data/notebook_repository.dart';
import 'package:dayflow/features/diary/domain/notebook.dart';
import 'package:dayflow/features/diary/providers/notebook_provider.dart';
import 'package:dayflow/features/diary/presentation/widgets/notebook_card.dart';
import 'package:dayflow/features/diary/presentation/widgets/notebook_cover_crop_dialog.dart';
import 'package:dayflow/features/settings/presentation/pages/settings_page.dart';
import 'package:dayflow/shared/widgets/blur_dialog.dart';

/// 日记本列表页面
class NotebookListPage extends ConsumerWidget {
  const NotebookListPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);
    final theme = Theme.of(context);

    if (authState is! AuthStateAuthenticated) {
      return const Scaffold(
        body: Center(child: Text('请先登录后查看日记')),
      );
    }

    final userId = authState.userProfile.id;
    final notebookState = ref.watch(notebookListProvider(userId));

    return Scaffold(
      appBar: AppBar(
        title: const Text('我的日记本'),
        actions: [
          if (MediaQuery.sizeOf(context).width < 960)
            IconButton(
              icon: const Icon(Icons.settings_outlined),
              tooltip: '设置',
              onPressed: () => showSettingsDialog(context),
            ),
        ],
      ),
      body: _buildBody(context, ref, notebookState, theme, userId),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showCreateDialog(context, ref, userId),
        tooltip: '新建日记本',
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildBody(
    BuildContext context,
    WidgetRef ref,
    NotebookListState state,
    ThemeData theme,
    String userId,
  ) {
    return switch (state) {
      NotebookListLoading() =>
        const Center(child: CircularProgressIndicator()),
      NotebookListError(message: final msg) => Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('加载失败: $msg',
                  style: TextStyle(color: theme.colorScheme.error)),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => ref
                    .read(notebookListProvider(userId).notifier)
                    .loadNotebooks(),
                child: const Text('重试'),
              ),
            ],
          ),
        ),
      NotebookListData(notebooks: final notebooks) => notebooks.isEmpty
          ? Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.book_outlined,
                    size: 64,
                    color: theme.colorScheme.onSurfaceVariant.withAlpha(100),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    '还没有日记本，点击 + 创建第一本吧！',
                    style: theme.textTheme.bodyLarge?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            )
          : _buildGrid(context, ref, notebooks, userId),
    };
  }

  /// 构建日记本网格
  Widget _buildGrid(
    BuildContext context,
    WidgetRef ref,
    List<Notebook> notebooks,
    String userId,
  ) {
    // 根据屏幕宽度自适应列数
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final crossAxisCount = width > 960
            ? 5
            : width > 600
                ? 4
                : width > 400
                    ? 3
                    : 2;

        return GridView.builder(
          padding: const EdgeInsets.all(16),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            mainAxisSpacing: 16,
            crossAxisSpacing: 16,
            // 封面 3:4 + 名称区域约 40px
            childAspectRatio: 3 / 5.2,
          ),
          itemCount: notebooks.length,
          itemBuilder: (context, index) {
            final notebook = notebooks[index];
            return NotebookCard(
              notebook: notebook,
              onTap: () {
                // 进入日记本内的日记列表
                context.push('/diary/notebook/${notebook.id}');
              },
              onAction: (action) => _handleAction(
                context,
                ref,
                action,
                notebook,
                userId,
              ),
            );
          },
        );
      },
    );
  }

  /// 处理日记本菜单操作
  Future<void> _handleAction(
    BuildContext context,
    WidgetRef ref,
    NotebookAction action,
    Notebook notebook,
    String userId,
  ) async {
    switch (action) {
      case NotebookAction.rename:
        await _showRenameDialog(context, ref, notebook, userId);
      case NotebookAction.changeCover:
        await _changeCover(context, ref, notebook, userId);
      case NotebookAction.moveTo:
        await _showMoveToDialog(context, ref, notebook, userId);
      case NotebookAction.delete:
        await _confirmDelete(context, ref, notebook, userId);
    }
  }

  /// 显示创建日记本对话框
  Future<void> _showCreateDialog(
    BuildContext context,
    WidgetRef ref,
    String userId,
  ) async {
    final controller = TextEditingController();
    final name = await showBlurDialog<String>(
      context: context,
      barrierLabel: '新建日记本',
      builder: (dialogContext) => AlertDialog(
        title: const Text('新建日记本'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(
            hintText: '输入日记本名称',
            border: OutlineInputBorder(),
          ),
          onSubmitted: (value) =>
              Navigator.of(dialogContext).pop(value.trim()),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(null),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () =>
                Navigator.of(dialogContext).pop(controller.text.trim()),
            child: const Text('创建'),
          ),
        ],
      ),
    );

    controller.dispose();
    if (name == null || name.isEmpty) return;

    await ref.read(notebookListProvider(userId).notifier).createNotebook(name);
  }

  /// 显示重命名对话框
  Future<void> _showRenameDialog(
    BuildContext context,
    WidgetRef ref,
    Notebook notebook,
    String userId,
  ) async {
    final controller = TextEditingController(text: notebook.name);
    final newName = await showBlurDialog<String>(
      context: context,
      barrierLabel: '重命名日记本',
      builder: (dialogContext) => AlertDialog(
        title: const Text('重命名日记本'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(
            border: OutlineInputBorder(),
          ),
          onSubmitted: (value) =>
              Navigator.of(dialogContext).pop(value.trim()),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(null),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () =>
                Navigator.of(dialogContext).pop(controller.text.trim()),
            child: const Text('确定'),
          ),
        ],
      ),
    );

    controller.dispose();
    if (newName == null || newName.isEmpty || newName == notebook.name) return;

    await ref
        .read(notebookListProvider(userId).notifier)
        .renameNotebook(notebook.id!, newName);
  }

  /// 更换封面
  Future<void> _changeCover(
    BuildContext context,
    WidgetRef ref,
    Notebook notebook,
    String userId,
  ) async {
    final result = await pickAndCropCoverImage(context);
    if (result == null || !context.mounted) return;

    // 上传到 Supabase Storage
    try {
      final repo = ref.read(notebookRepositoryProvider);
      final coverUrl = await repo.uploadCover(
        userId: userId,
        notebookId: notebook.id!,
        bytes: result.bytes,
        mimeType: result.mimeType,
      );

      await ref
          .read(notebookListProvider(userId).notifier)
          .updateCover(notebook.id!, coverUrl);
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('上传封面失败: $e')),
        );
      }
    }
  }

  /// 移动至对话框（调整排序位置）
  Future<void> _showMoveToDialog(
    BuildContext context,
    WidgetRef ref,
    Notebook notebook,
    String userId,
  ) async {
    final state = ref.read(notebookListProvider(userId));
    if (state is! NotebookListData) return;

    final notebooks = state.notebooks;
    if (notebooks.length <= 1) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('只有一个日记本，无需移动')),
      );
      return;
    }

    // 构建可选位置列表（排除当前日记本）
    final targets = notebooks.where((n) => n.id != notebook.id).toList();

    final targetId = await showBlurDialog<int>(
      context: context,
      barrierLabel: '移动至',
      builder: (dialogContext) => AlertDialog(
        title: const Text('移动至'),
        content: SizedBox(
          width: 300,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('选择目标位置（将移动到该日记本前面）：'),
              const SizedBox(height: 12),
              ...targets.map(
                (target) => ListTile(
                  leading: const Icon(Icons.book_outlined),
                  title: Text(target.name),
                  onTap: () => Navigator.of(dialogContext).pop(target.id),
                ),
              ),
              // 移动到最后
              ListTile(
                leading: const Icon(Icons.last_page),
                title: const Text('移动到最后'),
                onTap: () => Navigator.of(dialogContext).pop(-1),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(null),
            child: const Text('取消'),
          ),
        ],
      ),
    );

    if (targetId == null) return;

    // 计算新排序值
    int newSortOrder;
    if (targetId == -1) {
      // 移动到最后
      newSortOrder = notebooks.last.sortOrder + 1;
    } else {
      // 移动到目标日记本前面
      final targetNotebook = notebooks.firstWhere((n) => n.id == targetId);
      newSortOrder = targetNotebook.sortOrder;
    }

    await ref
        .read(notebookListProvider(userId).notifier)
        .updateSortOrder(notebook.id!, newSortOrder);
  }

  /// 删除确认
  Future<void> _confirmDelete(
    BuildContext context,
    WidgetRef ref,
    Notebook notebook,
    String userId,
  ) async {
    final confirmed = await showBlurDialog<bool>(
      context: context,
      barrierLabel: '删除日记本',
      builder: (dialogContext) => AlertDialog(
        title: const Text('确认删除'),
        content: Text(
          '确定要删除日记本「${notebook.name}」吗？\n\n'
          '日记本中的日记不会被删除，它们将归入未分类。',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('取消'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('删除'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    await ref
        .read(notebookListProvider(userId).notifier)
        .deleteNotebook(notebook.id!);
  }
}
