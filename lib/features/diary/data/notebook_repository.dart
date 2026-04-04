/// DayFlow - 日记本仓库层
///
/// 负责日记本的 CRUD 操作，协调本地数据库。
library;

import 'package:drift/drift.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:dayflow/core/supabase/supabase_client.dart';
import 'package:dayflow/features/diary/domain/notebook.dart' as domain;
import 'package:dayflow/shared/database/dao/notebook_dao.dart';
import 'package:dayflow/shared/database/database.dart' as db;

/// 日记本封面存储桶名称
const _kCoverBucket = 'notebook-covers';

/// 日记本仓库
class NotebookRepository {
  final NotebookDao _localDao;
  final SupabaseClient _supabaseClient;

  NotebookRepository({
    required NotebookDao localDao,
    required SupabaseClient supabaseClient,
  })  : _localDao = localDao,
        _supabaseClient = supabaseClient;

  /// 获取所有日记本
  Future<List<domain.Notebook>> getAllNotebooks(String userId) async {
    final rows = await _localDao.getAllNotebooks(userId);
    return rows.map(_mapRow).toList();
  }

  /// 监听所有日记本
  Stream<List<domain.Notebook>> watchAllNotebooks(String userId) {
    return _localDao
        .watchAllNotebooks(userId)
        .map((rows) => rows.map(_mapRow).toList());
  }

  /// 创建新日记本
  Future<domain.Notebook> createNotebook({
    required String name,
    required String userId,
    String? coverUrl,
  }) async {
    final now = DateTime.now();
    final sortOrder = await _localDao.getNextSortOrder(userId);

    final companion = db.NotebooksCompanion.insert(
      name: name,
      coverUrl: Value(coverUrl),
      sortOrder: Value(sortOrder),
      createdAt: now,
      updatedAt: now,
      userId: userId,
    );

    final id = await _localDao.insertNotebook(companion);
    return domain.Notebook(
      id: id,
      name: name,
      coverUrl: coverUrl,
      sortOrder: sortOrder,
      createdAt: now,
      updatedAt: now,
      userId: userId,
    );
  }

  /// 重命名日记本
  Future<void> renameNotebook(int id, String newName) async {
    final companion = db.NotebooksCompanion(
      id: Value(id),
      name: Value(newName),
      updatedAt: Value(DateTime.now()),
    );
    await _localDao.updateNotebook(companion);
  }

  /// 更新日记本封面
  Future<void> updateCover(int id, String? coverUrl) async {
    final companion = db.NotebooksCompanion(
      id: Value(id),
      coverUrl: Value(coverUrl),
      updatedAt: Value(DateTime.now()),
    );
    await _localDao.updateNotebook(companion);
  }

  /// 更新日记本排序
  Future<void> updateSortOrder(int id, int sortOrder) async {
    final companion = db.NotebooksCompanion(
      id: Value(id),
      sortOrder: Value(sortOrder),
      updatedAt: Value(DateTime.now()),
    );
    await _localDao.updateNotebook(companion);
  }

  /// 删除日记本（不删除其中的日记，日记的 notebookId 变为 null）
  Future<void> deleteNotebook(int id) async {
    await _localDao.deleteNotebook(id);
  }

  /// 上传日记本封面到 Supabase Storage
  Future<String> uploadCover({
    required String userId,
    required int notebookId,
    required Uint8List bytes,
    required String mimeType,
  }) async {
    final storagePath = '$userId/notebook_$notebookId.png';

    try {
      await _supabaseClient.storage.from(_kCoverBucket).uploadBinary(
            storagePath,
            bytes,
            fileOptions: FileOptions(contentType: mimeType, upsert: true),
          );
    } catch (e) {
      debugPrint('[NotebookRepository] 上传封面失败: $e');
      rethrow;
    }

    final publicUrl =
        _supabaseClient.storage.from(_kCoverBucket).getPublicUrl(storagePath);
    return '$publicUrl?t=${DateTime.now().millisecondsSinceEpoch}';
  }

  domain.Notebook _mapRow(db.Notebook row) {
    return domain.Notebook(
      id: row.id,
      cloudId: row.cloudId,
      name: row.name,
      coverUrl: row.coverUrl,
      sortOrder: row.sortOrder,
      createdAt: row.createdAt,
      updatedAt: row.updatedAt,
      userId: row.userId,
    );
  }
}

/// 日记本仓库 Provider
final notebookRepositoryProvider = Provider<NotebookRepository>((ref) {
  final database = ref.read(db.appDatabaseProvider);
  final supabase = ref.read(supabaseClientProvider);
  return NotebookRepository(
    localDao: NotebookDao(database),
    supabaseClient: supabase,
  );
});
