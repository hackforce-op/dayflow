/// ============================================================================
/// DayFlow - 日记数据访问对象 (DAO)
/// ============================================================================
///
/// 该文件封装了所有日记相关的数据库操作，提供类型安全的 CRUD 接口。
///
/// ## 设计原则
///
/// - **单一职责**：只负责日记表的数据库操作
/// - **响应式查询**：提供 Stream 接口，配合 Riverpod 实现数据变化自动通知 UI
/// - **参数化查询**：所有查询使用参数化 SQL，防止 SQL 注入
///
/// ## 使用方式
///
/// ```dart
/// final db = ref.read(appDatabaseProvider);
/// final diaryDao = DiaryDao(db);
///
/// // 监听某一天的日记
/// final stream = diaryDao.watchEntriesByDate(DateTime.now());
///
/// // 创建新日记
/// await diaryDao.insertEntry(DiaryEntriesCompanion.insert(...));
/// ```
/// ============================================================================
import 'package:drift/drift.dart';

import '../database.dart';

/// 日记数据访问对象
///
/// 封装了 [DiaryEntries] 表的所有数据库操作。
/// 不使用 Drift 的 @DriftAccessor 注解，而是手动编写查询逻辑，
/// 避免额外的代码生成依赖。
///
/// 构造时需要传入 [AppDatabase] 实例作为数据库连接。
class DiaryDao {
  /// 数据库实例引用
  ///
  /// 通过此引用访问数据库连接和表定义。
  final AppDatabase _db;

  /// 构造函数
  ///
  /// [db] 应用数据库实例，通常通过 Riverpod Provider 注入。
  DiaryDao(this._db);

  // ==========================================================================
  // 查询操作 (Read)
  // ==========================================================================

  /// 获取指定用户的所有日记条目
  ///
  /// 返回按日期降序排列的日记列表（最新的日记排在最前面）。
  ///
  /// [userId] 用户唯一标识符
  ///
  /// 返回 [Future<List<DiaryEntry>>]，包含该用户的所有日记。
  Future<List<DiaryEntry>> getAllEntries(String userId) {
    return (_db.select(_db.diaryEntries)
          ..where((t) => t.userId.equals(userId))
          ..orderBy([
            (t) => OrderingTerm(
                  expression: t.date,
                  mode: OrderingMode.desc,
                ),
          ]))
        .get();
  }

  /// 监听指定用户的所有日记条目（响应式）
  ///
  /// 返回一个 Stream，当日记数据发生变化时自动发出新的列表。
  /// 适用于配合 Riverpod 的 StreamProvider 实现实时 UI 更新。
  ///
  /// [userId] 用户唯一标识符
  ///
  /// 返回 [Stream<List<DiaryEntry>>]
  Stream<List<DiaryEntry>> watchAllEntries(String userId) {
    return (_db.select(_db.diaryEntries)
          ..where((t) => t.userId.equals(userId))
          ..orderBy([
            (t) => OrderingTerm(
                  expression: t.date,
                  mode: OrderingMode.desc,
                ),
          ]))
        .watch();
  }

  /// 根据 ID 获取单条日记
  ///
  /// [id] 日记条目的数据库 ID
  ///
  /// 返回 [Future<DiaryEntry?>]，如果不存在则返回 null。
  Future<DiaryEntry?> getEntryById(int id) {
    return (_db.select(_db.diaryEntries)..where((t) => t.id.equals(id)))
        .getSingleOrNull();
  }

  /// 查询指定日期范围内的日记条目
  ///
  /// 返回在 [startDate] 和 [endDate] 之间的所有日记（包含两端），
  /// 按日期降序排列。
  ///
  /// 典型用途：
  /// - 查询某一周的日记
  /// - 查询某个月的日记
  /// - 日历视图中按月加载数据
  ///
  /// [userId] 用户唯一标识符
  /// [startDate] 起始日期（包含）
  /// [endDate] 结束日期（包含）
  Future<List<DiaryEntry>> getEntriesByDateRange(
    String userId,
    DateTime startDate,
    DateTime endDate,
  ) {
    return (_db.select(_db.diaryEntries)
          ..where((t) =>
              t.userId.equals(userId) &
              t.date.isBiggerOrEqualValue(startDate) &
              t.date.isSmallerOrEqualValue(endDate))
          ..orderBy([
            (t) => OrderingTerm(
                  expression: t.date,
                  mode: OrderingMode.desc,
                ),
          ]))
        .get();
  }

  /// 监听指定日期的日记条目（响应式）
  ///
  /// 查询某一天的日记，返回 Stream 以实现实时更新。
  /// 日期比较只比较年月日，忽略时分秒。
  ///
  /// [userId] 用户唯一标识符
  /// [date] 目标日期
  Stream<List<DiaryEntry>> watchEntriesByDate(String userId, DateTime date) {
    /// 计算当天的起止时间范围
    final dayStart = DateTime(date.year, date.month, date.day);
    final dayEnd = DateTime(date.year, date.month, date.day, 23, 59, 59);

    return (_db.select(_db.diaryEntries)
          ..where((t) =>
              t.userId.equals(userId) &
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

  /// 按关键词搜索日记内容
  ///
  /// 在日记正文中进行模糊搜索（LIKE '%keyword%'）。
  /// 搜索不区分大小写（由 SQLite 的 LIKE 行为决定）。
  ///
  /// 注意：Drift 的 `.like()` 方法使用参数化查询，不存在 SQL 注入风险。
  /// 关键词中的 LIKE 通配符（% 和 _）会被转义，确保精确匹配用户输入。
  ///
  /// [userId] 用户唯一标识符
  /// [keyword] 搜索关键词
  ///
  /// 返回匹配的日记列表，按日期降序排列。
  Future<List<DiaryEntry>> searchEntries(String userId, String keyword) {
    return (_db.select(_db.diaryEntries)
          ..where((t) =>
              t.userId.equals(userId) & t.content.like('%${keyword.trim()}%'))
          ..orderBy([
            (t) => OrderingTerm(
                  expression: t.date,
                  mode: OrderingMode.desc,
                ),
          ]))
        .get();
  }

  // ==========================================================================
  // 创建操作 (Create)
  // ==========================================================================

  /// 插入一条新的日记条目
  ///
  /// 将日记数据写入数据库，并返回自动生成的自增 ID。
  ///
  /// [entry] 要插入的日记数据（使用 Drift 的 Companion 对象）
  ///
  /// 返回 [Future<int>]，包含新记录的数据库 ID。
  ///
  /// 使用示例：
  /// ```dart
  /// final id = await diaryDao.insertEntry(
  ///   DiaryEntriesCompanion.insert(
  ///     content: '今天学习了 Flutter Drift',
  ///     mood: Value('happy'),
  ///     date: DateTime.now(),
  ///     createdAt: DateTime.now(),
  ///     updatedAt: DateTime.now(),
  ///     userId: 'user-123',
  ///   ),
  /// );
  /// ```
  Future<int> insertEntry(DiaryEntriesCompanion entry) {
    return _db.into(_db.diaryEntries).insert(entry);
  }

  // ==========================================================================
  // 更新操作 (Update)
  // ==========================================================================

  /// 更新一条日记条目
  ///
  /// 根据主键 (id) 更新对应的日记记录。
  /// 只更新 Companion 中标记为 present 的字段。
  ///
  /// [entry] 要更新的日记数据（必须包含有效的 id）
  ///
  /// 返回 [Future<bool>]，true 表示更新成功（找到并修改了记录），
  /// false 表示未找到对应的记录。
  Future<bool> updateEntry(DiaryEntriesCompanion entry) {
    return (_db.update(_db.diaryEntries)
          ..where((t) => t.id.equals(entry.id.value)))
        .write(entry)
        .then((rows) => rows > 0);
  }

  // ==========================================================================
  // 删除操作 (Delete)
  // ==========================================================================

  /// 删除指定 ID 的日记条目
  ///
  /// [id] 要删除的日记条目 ID
  ///
  /// 返回 [Future<int>]，包含被删除的行数（0 或 1）。
  Future<int> deleteEntry(int id) {
    return (_db.delete(_db.diaryEntries)..where((t) => t.id.equals(id))).go();
  }

  /// 删除指定用户的所有日记条目
  ///
  /// ⚠️ 危险操作！将删除该用户的全部日记数据，不可恢复。
  /// 通常在用户注销账号或清除本地数据时使用。
  ///
  /// [userId] 用户唯一标识符
  ///
  /// 返回 [Future<int>]，包含被删除的总行数。
  Future<int> deleteAllEntries(String userId) {
    return (_db.delete(_db.diaryEntries)..where((t) => t.userId.equals(userId)))
        .go();
  }
}
