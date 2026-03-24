/// ============================================================================
/// DayFlow - 日记仓库层 (Repository)
/// ============================================================================
///
/// 该文件实现了日记模块的数据仓库，负责协调本地数据库与云端 Supabase 之间的
/// 数据读写和同步操作。
///
/// ## 设计原则
///
/// - **本地优先**：所有写操作先保存到本地 SQLite，再异步同步到云端
/// - **离线可用**：即使没有网络连接，用户仍可正常使用日记功能
/// - **冲突解决**：同步时以 updatedAt 最新的记录为准
/// - **错误隔离**：云端同步失败不影响本地操作
///
/// ## 数据流向
///
/// 写入流程：UI → Repository → DiaryDao (本地) → Supabase (云端)
/// 读取流程：DiaryDao (本地) → Repository → UI
/// 同步流程：Supabase (云端) ↔ DiaryDao (本地)
/// ============================================================================
import 'package:drift/drift.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide Provider;

import 'package:dayflow/core/supabase/supabase_client.dart';
import 'package:dayflow/features/diary/domain/diary_entry.dart';
import 'package:dayflow/shared/database/dao/diary_dao.dart';
import 'package:dayflow/shared/database/database.dart';

/// Supabase 中日记表的名称常量
const _kDiaryTable = 'diary_entries';

/// 日记仓库
///
/// 封装了日记数据的所有读写操作，对上层（Provider / UI）提供统一的接口。
/// 内部同时管理本地 SQLite 数据库和远端 Supabase 数据库。
///
/// 使用示例：
/// ```dart
/// final repo = ref.read(diaryRepositoryProvider);
/// final entries = await repo.getAllEntries('user-123');
/// ```
class DiaryRepository {
  /// 本地数据库访问对象
  final DiaryDao _localDao;

  /// Supabase 客户端，用于云端数据同步
  final SupabaseClient _supabaseClient;

  /// 构造函数
  ///
  /// [localDao] 本地 SQLite 数据访问对象
  /// [supabaseClient] Supabase 客户端实例
  DiaryRepository({
    required DiaryDao localDao,
    required SupabaseClient supabaseClient,
  })  : _localDao = localDao,
        _supabaseClient = supabaseClient;

  // ==========================================================================
  // 读取操作 (Read)
  // ==========================================================================

  /// 获取指定用户的所有日记条目（从本地数据库）
  ///
  /// 返回按日期降序排列的日记列表。
  /// 数据来源为本地 SQLite，确保离线可用。
  ///
  /// [userId] 用户唯一标识符
  Future<List<DiaryEntry>> getAllEntries(String userId) async {
    try {
      final rows = await _localDao.getAllEntries(userId);
      return rows.map(_mapRowToDiaryEntry).toList();
    } catch (e) {
      debugPrint('[DiaryRepository] 获取所有日记失败: $e');
      rethrow;
    }
  }

  /// 监听指定用户的所有日记条目（响应式 Stream）
  ///
  /// 数据库发生变化时自动推送最新列表，适配 Riverpod StreamProvider。
  ///
  /// [userId] 用户唯一标识符
  Stream<List<DiaryEntry>> watchAllEntries(String userId) {
    return _localDao.watchAllEntries(userId).map(
          (rows) => rows.map(_mapRowToDiaryEntry).toList(),
        );
  }

  /// 根据 ID 获取单条日记
  ///
  /// [id] 日记条目的数据库 ID
  Future<DiaryEntry?> getEntryById(int id) async {
    try {
      final row = await _localDao.getEntryById(id);
      return row != null ? _mapRowToDiaryEntry(row) : null;
    } catch (e) {
      debugPrint('[DiaryRepository] 根据ID获取日记失败: $e');
      rethrow;
    }
  }

  /// 查询指定日期范围内的日记条目
  ///
  /// [userId] 用户唯一标识符
  /// [startDate] 起始日期（包含）
  /// [endDate] 结束日期（包含）
  Future<List<DiaryEntry>> getEntriesByDateRange(
    String userId,
    DateTime startDate,
    DateTime endDate,
  ) async {
    try {
      final rows =
          await _localDao.getEntriesByDateRange(userId, startDate, endDate);
      return rows.map(_mapRowToDiaryEntry).toList();
    } catch (e) {
      debugPrint('[DiaryRepository] 按日期范围查询日记失败: $e');
      rethrow;
    }
  }

  /// 搜索日记内容
  ///
  /// 在日记正文中进行模糊搜索。
  ///
  /// [userId] 用户唯一标识符
  /// [keyword] 搜索关键词
  Future<List<DiaryEntry>> searchEntries(String userId, String keyword) async {
    try {
      final rows = await _localDao.searchEntries(userId, keyword);
      return rows.map(_mapRowToDiaryEntry).toList();
    } catch (e) {
      debugPrint('[DiaryRepository] 搜索日记失败: $e');
      rethrow;
    }
  }

  // ==========================================================================
  // 写入操作 (Create / Update / Delete) - 本地优先，异步云端同步
  // ==========================================================================

  /// 创建新日记条目
  ///
  /// 先写入本地数据库获取自增 ID，然后异步推送到云端 Supabase。
  /// 即使云端同步失败，本地数据仍然保留。
  ///
  /// [entry] 日记领域模型对象（id 应为 null）
  ///
  /// 返回包含数据库生成 ID 的完整日记对象
  Future<DiaryEntry> createEntry(DiaryEntry entry) async {
    try {
      // 步骤 1：写入本地数据库
      final companion = DiaryEntriesCompanion.insert(
        content: entry.content,
        mood: Value(entry.mood?.value),
        date: entry.date,
        createdAt: entry.createdAt,
        updatedAt: entry.updatedAt,
        userId: entry.userId,
      );
      final localId = await _localDao.insertEntry(companion);

      // 步骤 2：获取完整的本地记录（包含自增 ID）
      final savedEntry = entry.copyWith(id: localId);

      // 步骤 3：异步推送到云端（不阻塞主流程）
      _syncToCloud(savedEntry);

      return savedEntry;
    } catch (e) {
      debugPrint('[DiaryRepository] 创建日记失败: $e');
      rethrow;
    }
  }

  /// 更新日记条目
  ///
  /// 先更新本地数据库，然后异步同步到云端。
  ///
  /// [entry] 要更新的日记对象（必须包含有效 id）
  ///
  /// 返回更新后的日记对象
  Future<DiaryEntry> updateEntry(DiaryEntry entry) async {
    try {
      // 步骤 1：更新本地数据库
      final companion = DiaryEntriesCompanion(
        id: Value(entry.id!),
        content: Value(entry.content),
        mood: Value(entry.mood?.value),
        date: Value(entry.date),
        updatedAt: Value(entry.updatedAt),
        userId: Value(entry.userId),
      );
      await _localDao.updateEntry(companion);

      // 步骤 2：异步推送到云端
      _syncToCloud(entry);

      return entry;
    } catch (e) {
      debugPrint('[DiaryRepository] 更新日记失败: $e');
      rethrow;
    }
  }

  /// 删除日记条目
  ///
  /// 先从本地数据库删除，然后异步从云端删除。
  ///
  /// [id] 日记条目 ID
  /// [userId] 用户 ID（用于云端删除的权限校验）
  Future<void> deleteEntry(int id, String userId) async {
    try {
      // 步骤 1：从本地数据库删除
      await _localDao.deleteEntry(id);

      // 步骤 2：异步从云端删除
      _deleteFromCloud(id, userId);
    } catch (e) {
      debugPrint('[DiaryRepository] 删除日记失败: $e');
      rethrow;
    }
  }

  // ==========================================================================
  // 云端同步操作 (Sync)
  // ==========================================================================

  /// 全量同步：从云端拉取数据，与本地合并，再推送变更
  ///
  /// 同步策略：
  /// 1. 从 Supabase 拉取该用户的所有日记
  /// 2. 与本地数据进行合并（以 updatedAt 最新的为准）
  /// 3. 将本地新增/修改的数据推送到云端
  ///
  /// [userId] 用户唯一标识符
  Future<void> syncWithCloud(String userId) async {
    try {
      // 步骤 1：从云端拉取数据
      final cloudData = await _supabaseClient
          .from(_kDiaryTable)
          .select()
          .eq('user_id', userId)
          .order('updated_at', ascending: false);

      final cloudEntries =
          cloudData.map((json) => DiaryEntry.fromJson(json)).toList();

      // 步骤 2：获取本地数据
      final localRows = await _localDao.getAllEntries(userId);
      final localEntries = localRows.map(_mapRowToDiaryEntry).toList();

      // 步骤 3：合并数据 - 以 updatedAt 较新的为准
      await _mergeEntries(localEntries, cloudEntries, userId);

      debugPrint('[DiaryRepository] 同步完成：云端 ${cloudEntries.length} 条，'
          '本地 ${localEntries.length} 条');
    } catch (e) {
      debugPrint('[DiaryRepository] 云端同步失败: $e');
      // 同步失败不抛出异常，不影响本地操作
    }
  }

  // ==========================================================================
  // 私有辅助方法
  // ==========================================================================

  /// 将 Drift 数据库行对象转换为领域模型 [DiaryEntry]
  ///
  /// Drift 生成的 DiaryEntry 类（数据库行）与我们的领域模型 DiaryEntry 同名，
  /// 但属于不同的类型。此方法负责类型映射。
  DiaryEntry _mapRowToDiaryEntry(dynamic row) {
    return DiaryEntry(
      id: row.id as int,
      content: row.content as String,
      mood: Mood.fromValue(row.mood as String?),
      date: row.date as DateTime,
      createdAt: row.createdAt as DateTime,
      updatedAt: row.updatedAt as DateTime,
      userId: row.userId as String,
    );
  }

  /// 异步将单条日记推送到云端 Supabase
  ///
  /// 使用 upsert 操作：如果云端已存在则更新，不存在则插入。
  /// 该方法不会抛出异常，失败时仅打印日志。
  ///
  /// [entry] 要同步的日记对象
  Future<void> _syncToCloud(DiaryEntry entry) async {
    try {
      await _supabaseClient.from(_kDiaryTable).upsert(entry.toJson());
      debugPrint('[DiaryRepository] 云端同步成功: id=${entry.id}');
    } catch (e) {
      debugPrint('[DiaryRepository] 云端同步失败: $e');
    }
  }

  /// 异步从云端删除指定日记
  ///
  /// [id] 日记条目 ID
  /// [userId] 用户 ID
  Future<void> _deleteFromCloud(int id, String userId) async {
    try {
      await _supabaseClient
          .from(_kDiaryTable)
          .delete()
          .eq('id', id)
          .eq('user_id', userId);
      debugPrint('[DiaryRepository] 云端删除成功: id=$id');
    } catch (e) {
      debugPrint('[DiaryRepository] 云端删除失败: $e');
    }
  }

  /// 合并本地与云端数据
  ///
  /// 合并策略：
  /// - 云端有、本地无 → 插入本地
  /// - 本地有、云端无 → 推送到云端
  /// - 两边都有 → 以 updatedAt 较新的为准
  ///
  /// [localEntries] 本地日记列表
  /// [cloudEntries] 云端日记列表
  /// [userId] 用户 ID
  Future<void> _mergeEntries(
    List<DiaryEntry> localEntries,
    List<DiaryEntry> cloudEntries,
    String userId,
  ) async {
    // 构建本地数据的 ID 映射，便于快速查找
    final localMap = {for (final e in localEntries) e.id: e};
    // 构建云端数据的 ID 映射
    final cloudMap = {for (final e in cloudEntries) e.id: e};

    // 情况 1：云端有但本地没有的条目 → 插入本地
    for (final cloudEntry in cloudEntries) {
      if (cloudEntry.id != null && !localMap.containsKey(cloudEntry.id)) {
        final companion = DiaryEntriesCompanion.insert(
          content: cloudEntry.content,
          mood: Value(cloudEntry.mood?.value),
          date: cloudEntry.date,
          createdAt: cloudEntry.createdAt,
          updatedAt: cloudEntry.updatedAt,
          userId: cloudEntry.userId,
        );
        await _localDao.insertEntry(companion);
      }
    }

    // 情况 2：本地有但云端没有的条目 → 推送到云端
    for (final localEntry in localEntries) {
      if (localEntry.id != null && !cloudMap.containsKey(localEntry.id)) {
        await _syncToCloud(localEntry);
      }
    }

    // 情况 3：两边都有的条目 → 以 updatedAt 较新的为准
    for (final localEntry in localEntries) {
      final cloudEntry = cloudMap[localEntry.id];
      if (cloudEntry == null) continue;

      if (localEntry.updatedAt.isAfter(cloudEntry.updatedAt)) {
        // 本地较新 → 推送到云端
        await _syncToCloud(localEntry);
      } else if (cloudEntry.updatedAt.isAfter(localEntry.updatedAt)) {
        // 云端较新 → 更新本地
        final companion = DiaryEntriesCompanion(
          id: Value(localEntry.id!),
          content: Value(cloudEntry.content),
          mood: Value(cloudEntry.mood?.value),
          date: Value(cloudEntry.date),
          updatedAt: Value(cloudEntry.updatedAt),
          userId: Value(cloudEntry.userId),
        );
        await _localDao.updateEntry(companion);
      }
    }
  }
}

// ==============================================================================
// Riverpod Providers（手动定义，非代码生成）
// ==============================================================================

/// DiaryDao Provider
///
/// 提供 [DiaryDao] 单例实例，依赖 [appDatabaseProvider]。
final diaryDaoProvider = Provider<DiaryDao>((ref) {
  final db = ref.watch(appDatabaseProvider);
  return DiaryDao(db);
});

/// DiaryRepository Provider
///
/// 提供 [DiaryRepository] 单例实例。
/// 依赖 [diaryDaoProvider] 和 [supabaseClientProvider]。
///
/// 使用方式：
/// ```dart
/// final repo = ref.read(diaryRepositoryProvider);
/// ```
final diaryRepositoryProvider = Provider<DiaryRepository>((ref) {
  final dao = ref.watch(diaryDaoProvider);
  final supabase = ref.watch(supabaseClientProvider);
  return DiaryRepository(localDao: dao, supabaseClient: supabase);
});
