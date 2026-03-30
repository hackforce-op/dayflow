/// ============================================================================
/// DayFlow - 新闻数据访问对象 (DAO)
/// ============================================================================
///
/// 该文件封装了所有新闻摘要和新闻书签相关的数据库操作。
///
/// ## 核心功能
///
/// ### 新闻摘要操作
/// - 插入/更新/删除新闻摘要
/// - 按日期查询每日新闻
/// - 按分类筛选新闻
/// - 响应式监听新闻列表
///
/// ### 书签操作
/// - 添加/移除书签
/// - 查询用户收藏列表
/// - 判断新闻是否已收藏
///
/// ## 使用方式
///
/// ```dart
/// final db = ref.read(appDatabaseProvider);
/// final newsDao = NewsDao(db);
///
/// // 获取今天的科技新闻
/// final techNews = await newsDao.getNewsByCategory(
///   DateTime.now(),
///   'technology',
/// );
///
/// // 收藏一条新闻
/// await newsDao.addBookmark('user-123', newsId: 42);
/// ```
/// ============================================================================
import 'package:drift/drift.dart';

import '../database.dart';

/// 新闻数据访问对象
///
/// 封装了 [NewsSummaries] 和 [NewsBookmarks] 两张表的数据库操作。
/// 手动编写查询逻辑，不使用代码生成。
class NewsDao {
  /// 数据库实例引用
  final AppDatabase _db;

  /// 构造函数
  ///
  /// [db] 应用数据库实例
  NewsDao(this._db);

  // ==========================================================================
  // 新闻摘要 - 查询操作 (Read)
  // ==========================================================================

  /// 获取指定日期的所有新闻摘要
  ///
  /// 查询某一天的所有新闻，按创建时间降序排列。
  /// 日期比较只比较年月日。
  ///
  /// [date] 目标日期
  Future<List<NewsSummary>> getNewsByDate(DateTime date) {
    final dayStart = DateTime(date.year, date.month, date.day);
    final dayEnd = DateTime(date.year, date.month, date.day, 23, 59, 59);

    return (_db.select(_db.newsSummaries)
          ..where((t) =>
              t.date.isBiggerOrEqualValue(dayStart) &
              t.date.isSmallerOrEqualValue(dayEnd))
          ..orderBy([
            (t) => OrderingTerm(
                  expression: t.createdAt,
                  mode: OrderingMode.desc,
                ),
          ]))
        .get();
  }

  /// 监听指定日期的新闻摘要（响应式）
  ///
  /// 返回 Stream，当新闻数据变化时自动发出新列表。
  ///
  /// [date] 目标日期
  Stream<List<NewsSummary>> watchNewsByDate(DateTime date) {
    final dayStart = DateTime(date.year, date.month, date.day);
    final dayEnd = DateTime(date.year, date.month, date.day, 23, 59, 59);

    return (_db.select(_db.newsSummaries)
          ..where((t) =>
              t.date.isBiggerOrEqualValue(dayStart) &
              t.date.isSmallerOrEqualValue(dayEnd))
          ..orderBy([
            (t) => OrderingTerm(
                  expression: t.createdAt,
                  mode: OrderingMode.desc,
                ),
          ]))
        .watch();
  }

  /// 按分类查询指定日期的新闻
  ///
  /// 获取某一天特定分类的新闻摘要。
  ///
  /// [date] 目标日期
  /// [category] 新闻分类标识符（如 'technology', 'finance'）
  Future<List<NewsSummary>> getNewsByCategory(
    DateTime date,
    String category,
  ) {
    final dayStart = DateTime(date.year, date.month, date.day);
    final dayEnd = DateTime(date.year, date.month, date.day, 23, 59, 59);

    return (_db.select(_db.newsSummaries)
          ..where((t) =>
              t.date.isBiggerOrEqualValue(dayStart) &
              t.date.isSmallerOrEqualValue(dayEnd) &
              t.category.equals(category))
          ..orderBy([
            (t) => OrderingTerm(
                  expression: t.createdAt,
                  mode: OrderingMode.desc,
                ),
          ]))
        .get();
  }

  /// 监听指定分类的新闻（响应式）
  ///
  /// [date] 目标日期
  /// [category] 新闻分类标识符
  Stream<List<NewsSummary>> watchNewsByCategory(
    DateTime date,
    String category,
  ) {
    final dayStart = DateTime(date.year, date.month, date.day);
    final dayEnd = DateTime(date.year, date.month, date.day, 23, 59, 59);

    return (_db.select(_db.newsSummaries)
          ..where((t) =>
              t.date.isBiggerOrEqualValue(dayStart) &
              t.date.isSmallerOrEqualValue(dayEnd) &
              t.category.equals(category))
          ..orderBy([
            (t) => OrderingTerm(
                  expression: t.createdAt,
                  mode: OrderingMode.desc,
                ),
          ]))
        .watch();
  }

  /// 根据 ID 获取单条新闻摘要
  ///
  /// [id] 新闻摘要的数据库 ID
  Future<NewsSummary?> getNewsById(int id) {
    return (_db.select(_db.newsSummaries)..where((t) => t.id.equals(id)))
        .getSingleOrNull();
  }

  // ==========================================================================
  // 新闻摘要 - 写入操作 (Create / Update / Delete)
  // ==========================================================================

  /// 插入一条新闻摘要
  ///
  /// [entry] 要插入的新闻数据
  ///
  /// 返回新记录的数据库自增 ID。
  Future<int> insertNews(NewsSummariesCompanion entry) {
    return _db.into(_db.newsSummaries).insert(entry);
  }

  /// 批量插入新闻摘要
  ///
  /// 使用数据库事务确保原子性。
  /// 适用于从后端同步每日新闻数据的场景。
  ///
  /// [entries] 要插入的新闻数据列表
  ///
  /// 使用 [InsertMode.insertOrReplace] 策略：
  /// 如果已存在相同 ID 的记录则替换，否则插入新记录。
  Future<void> insertMultipleNews(List<NewsSummariesCompanion> entries) {
    return _db.batch((batch) {
      batch.insertAll(
        _db.newsSummaries,
        entries,
        mode: InsertMode.insertOrReplace,
      );
    });
  }

  /// 更新一条新闻摘要
  ///
  /// [entry] 要更新的新闻数据（必须包含有效的 id）
  Future<bool> updateNews(NewsSummariesCompanion entry) {
    return (_db.update(_db.newsSummaries)
          ..where((t) => t.id.equals(entry.id.value)))
        .write(entry)
        .then((rows) => rows > 0);
  }

  /// 删除指定 ID 的新闻摘要
  ///
  /// 同时会触发关联的书签记录清理（如果有的话）。
  ///
  /// [id] 新闻摘要的数据库 ID
  Future<int> deleteNews(int id) {
    return (_db.delete(_db.newsSummaries)..where((t) => t.id.equals(id))).go();
  }

  /// 删除指定日期之前的所有新闻摘要
  ///
  /// 用于清理过期的新闻数据，释放存储空间。
  /// 建议定期（如每周）调用此方法清理超过 30 天的旧新闻。
  ///
  /// [beforeDate] 清理此日期之前的所有新闻
  Future<int> deleteOldNews(DateTime beforeDate) {
    return (_db.delete(_db.newsSummaries)
          ..where((t) => t.date.isSmallerThanValue(beforeDate)))
        .go();
  }

  // ==========================================================================
  // 新闻书签 - 操作
  // ==========================================================================

  /// 添加新闻书签（收藏新闻）
  ///
  /// 将指定新闻添加到用户的收藏列表中。
  ///
  /// [userId] 用户唯一标识符
  /// [newsId] 要收藏的新闻摘要 ID
  ///
  /// 返回书签记录的数据库自增 ID。
  Future<int> addBookmark(String userId, {required int newsId}) {
    return _db.into(_db.newsBookmarks).insert(
          NewsBookmarksCompanion.insert(
            userId: userId,
            newsId: newsId,
          ),
        );
  }

  /// 移除新闻书签（取消收藏）
  ///
  /// 从用户的收藏列表中移除指定新闻。
  ///
  /// [userId] 用户唯一标识符
  /// [newsId] 要取消收藏的新闻摘要 ID
  ///
  /// 返回被删除的行数（0 或 1）。
  Future<int> removeBookmark(String userId, {required int newsId}) {
    return (_db.delete(_db.newsBookmarks)
          ..where((t) => t.userId.equals(userId) & t.newsId.equals(newsId)))
        .go();
  }

  /// 判断某条新闻是否已被用户收藏
  ///
  /// [userId] 用户唯一标识符
  /// [newsId] 新闻摘要 ID
  ///
  /// 返回 true 表示已收藏，false 表示未收藏。
  Future<bool> isBookmarked(String userId, {required int newsId}) async {
    final result = await (_db.select(_db.newsBookmarks)
          ..where((t) => t.userId.equals(userId) & t.newsId.equals(newsId)))
        .getSingleOrNull();
    return result != null;
  }

  /// 获取用户收藏的所有新闻摘要
  ///
  /// 通过 JOIN 查询将书签表和新闻摘要表关联，
  /// 返回用户收藏的完整新闻摘要数据。
  ///
  /// [userId] 用户唯一标识符
  ///
  /// 返回收藏的新闻摘要列表，按收藏时间（书签 ID）降序排列。
  Future<List<NewsSummary>> getBookmarkedNews(String userId) async {
    /// 使用 Drift 的 JOIN 查询语法
    ///
    /// 将 newsBookmarks 表与 newsSummaries 表通过 newsId 关联，
    /// 筛选出属于当前用户的收藏记录。
    final query = _db.select(_db.newsSummaries).join([
      innerJoin(
        _db.newsBookmarks,
        _db.newsBookmarks.newsId.equalsExp(_db.newsSummaries.id),
      ),
    ])
      ..where(_db.newsBookmarks.userId.equals(userId))
      ..orderBy([
        OrderingTerm(
          expression: _db.newsBookmarks.id,
          mode: OrderingMode.desc,
        ),
      ]);

    final rows = await query.get();

    /// 从 JOIN 结果中提取 NewsSummaries 表的数据行
    return rows.map((row) => row.readTable(_db.newsSummaries)).toList();
  }

  /// 监听用户的收藏列表（响应式）
  ///
  /// 返回 Stream，当收藏数据变化时自动发出新列表。
  ///
  /// [userId] 用户唯一标识符
  Stream<List<NewsSummary>> watchBookmarkedNews(String userId) {
    final query = _db.select(_db.newsSummaries).join([
      innerJoin(
        _db.newsBookmarks,
        _db.newsBookmarks.newsId.equalsExp(_db.newsSummaries.id),
      ),
    ])
      ..where(_db.newsBookmarks.userId.equals(userId))
      ..orderBy([
        OrderingTerm(
          expression: _db.newsBookmarks.id,
          mode: OrderingMode.desc,
        ),
      ]);

    return query.watch().map(
        (rows) => rows.map((r) => r.readTable(_db.newsSummaries)).toList());
  }

  /// 获取用户收藏的新闻总数
  ///
  /// [userId] 用户唯一标识符
  Future<int> getBookmarkCount(String userId) async {
    final count = _db.newsBookmarks.id.count();
    final query = _db.selectOnly(_db.newsBookmarks)
      ..addColumns([count])
      ..where(_db.newsBookmarks.userId.equals(userId));

    final result = await query.getSingle();
    return result.read(count) ?? 0;
  }
}
