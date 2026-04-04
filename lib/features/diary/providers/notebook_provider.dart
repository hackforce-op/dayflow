/// DayFlow - 日记本状态管理 (Providers)
///
/// 管理日记本列表的加载和操作状态。
library;

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:dayflow/features/diary/data/notebook_repository.dart';
import 'package:dayflow/features/diary/domain/notebook.dart';

// ==========================================================================
// 日记本列表状态
// ==========================================================================

/// 日记本列表状态基类
sealed class NotebookListState {
  const NotebookListState();
}

/// 加载中
class NotebookListLoading extends NotebookListState {
  const NotebookListLoading();
}

/// 已加载
class NotebookListData extends NotebookListState {
  final List<Notebook> notebooks;
  const NotebookListData(this.notebooks);
}

/// 加载失败
class NotebookListError extends NotebookListState {
  final String message;
  const NotebookListError(this.message);
}

// ==========================================================================
// 日记本列表 Notifier
// ==========================================================================

/// 日记本列表状态管理器
class NotebookListNotifier extends StateNotifier<NotebookListState> {
  final NotebookRepository _repository;
  final String _userId;

  NotebookListNotifier(this._repository, this._userId)
      : super(const NotebookListLoading()) {
    loadNotebooks();
  }

  /// 加载日记本列表
  Future<void> loadNotebooks() async {
    state = const NotebookListLoading();
    try {
      final notebooks = await _repository.getAllNotebooks(_userId);
      state = NotebookListData(notebooks);
    } catch (e) {
      debugPrint('[NotebookProvider] 加载日记本失败: $e');
      state = NotebookListError(e.toString());
    }
  }

  /// 刷新列表
  Future<void> refresh() async {
    try {
      final notebooks = await _repository.getAllNotebooks(_userId);
      state = NotebookListData(notebooks);
    } catch (e) {
      debugPrint('[NotebookProvider] 刷新日记本失败: $e');
    }
  }

  /// 创建新日记本
  Future<Notebook?> createNotebook(String name) async {
    try {
      final notebook = await _repository.createNotebook(
        name: name,
        userId: _userId,
      );
      await refresh();
      return notebook;
    } catch (e) {
      debugPrint('[NotebookProvider] 创建日记本失败: $e');
      return null;
    }
  }

  /// 重命名日记本
  Future<void> renameNotebook(int id, String newName) async {
    try {
      await _repository.renameNotebook(id, newName);
      await refresh();
    } catch (e) {
      debugPrint('[NotebookProvider] 重命名日记本失败: $e');
    }
  }

  /// 更新封面
  Future<void> updateCover(int id, String? coverUrl) async {
    try {
      await _repository.updateCover(id, coverUrl);
      await refresh();
    } catch (e) {
      debugPrint('[NotebookProvider] 更新封面失败: $e');
    }
  }

  /// 删除日记本
  Future<void> deleteNotebook(int id) async {
    try {
      await _repository.deleteNotebook(id);
      await refresh();
    } catch (e) {
      debugPrint('[NotebookProvider] 删除日记本失败: $e');
    }
  }

  /// 更新排序
  Future<void> updateSortOrder(int id, int sortOrder) async {
    try {
      await _repository.updateSortOrder(id, sortOrder);
      await refresh();
    } catch (e) {
      debugPrint('[NotebookProvider] 更新排序失败: $e');
    }
  }
}

/// 日记本列表 Provider（按 userId 分隔）
final notebookListProvider = StateNotifierProvider.family<
    NotebookListNotifier, NotebookListState, String>(
  (ref, userId) {
    final repository = ref.read(notebookRepositoryProvider);
    return NotebookListNotifier(repository, userId);
  },
);
