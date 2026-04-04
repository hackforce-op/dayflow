/// DayFlow - 日记本数据访问对象 (DAO)
///
/// 封装 [Notebooks] 表的所有数据库操作。
library;

import 'package:drift/drift.dart';

import '../database.dart';

/// 日记本 DAO
///
/// 提供 CRUD 操作和排序管理。
class NotebookDao {
  final AppDatabase _db;

  NotebookDao(this._db);

  // ==========================================================================
  // 查询操作
  // ==========================================================================

  /// 获取指定用户的所有日记本，按 sortOrder 升序排列
  Future<List<Notebook>> getAllNotebooks(String userId) {
    return (_db.select(_db.notebooks)
          ..where((t) => t.userId.equals(userId))
          ..orderBy([
            (t) => OrderingTerm(
                  expression: t.sortOrder,
                  mode: OrderingMode.asc,
                ),
            (t) => OrderingTerm(
                  expression: t.createdAt,
                  mode: OrderingMode.asc,
                ),
          ]))
        .get();
  }

  /// 监听指定用户的所有日记本（响应式）
  Stream<List<Notebook>> watchAllNotebooks(String userId) {
    return (_db.select(_db.notebooks)
          ..where((t) => t.userId.equals(userId))
          ..orderBy([
            (t) => OrderingTerm(
                  expression: t.sortOrder,
                  mode: OrderingMode.asc,
                ),
            (t) => OrderingTerm(
                  expression: t.createdAt,
                  mode: OrderingMode.asc,
                ),
          ]))
        .watch();
  }

  /// 根据 ID 获取单个日记本
  Future<Notebook?> getNotebookById(int id) {
    return (_db.select(_db.notebooks)..where((t) => t.id.equals(id)))
        .getSingleOrNull();
  }

  // ==========================================================================
  // 写入操作
  // ==========================================================================

  /// 插入新日记本，返回自增 ID
  Future<int> insertNotebook(NotebooksCompanion companion) {
    return _db.into(_db.notebooks).insert(companion);
  }

  /// 更新日记本
  Future<bool> updateNotebook(NotebooksCompanion companion) {
    return (_db.update(_db.notebooks)
          ..where((t) => t.id.equals(companion.id.value)))
        .write(companion)
        .then((rows) => rows > 0);
  }

  /// 删除日记本
  Future<int> deleteNotebook(int id) {
    return (_db.delete(_db.notebooks)..where((t) => t.id.equals(id))).go();
  }

  /// 获取指定用户下一个可用的排序序号
  Future<int> getNextSortOrder(String userId) async {
    final result = await (_db.selectOnly(_db.notebooks)
          ..addColumns([_db.notebooks.sortOrder.max()])
          ..where(_db.notebooks.userId.equals(userId)))
        .getSingleOrNull();
    final maxOrder =
        result?.read(_db.notebooks.sortOrder.max());
    return (maxOrder ?? -1) + 1;
  }
}
