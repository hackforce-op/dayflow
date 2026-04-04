/// ============================================================================
/// DayFlow - 主数据库定义文件
/// ============================================================================
///
/// 该文件定义了 DayFlow 应用的本地 SQLite 数据库，使用 Drift 框架。
///
/// ## 数据库架构
///
/// 包含以下四张表：
/// - [DiaryEntries]：日记条目表，存储用户的每日日记
/// - [Tasks]：任务表，存储用户的待办任务
/// - [NewsSummaries]：新闻摘要表，存储 AI 生成的每日新闻
/// - [NewsBookmarks]：新闻书签表，存储用户收藏的新闻
///
/// ## 使用方式
///
/// 通过 Riverpod Provider 获取数据库实例：
/// ```dart
/// final db = ref.read(appDatabaseProvider);
/// ```
///
/// ## 代码生成
///
/// 修改表结构后需要运行以下命令重新生成代码：
/// ```bash
/// dart run build_runner build --delete-conflicting-outputs
/// ```
/// ============================================================================
import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'connection/connection.dart';

// Drift 代码生成器会生成此文件
// 运行 `dart run build_runner build` 以生成
part 'database.g.dart';

/// ============================================================================
/// 日记条目表 (diary_entries)
/// ============================================================================
///
/// 存储用户的每日日记记录。
///
/// 每条日记包含正文内容、心情标记、所属日期等信息。
/// 通过 [userId] 字段实现多用户数据隔离。
///
/// 数据库表结构：
/// | 列名       | 类型     | 约束                | 说明           |
/// |-----------|----------|--------------------|--------------  |
/// | id        | INTEGER  | PRIMARY KEY, AUTO  | 自增主键        |
/// | content   | TEXT     | NOT NULL           | 日记正文内容     |
/// | mood      | TEXT     | NULLABLE           | 心情标记        |
/// | date      | DATETIME | NOT NULL           | 日记所属日期     |
/// | createdAt | DATETIME | NOT NULL           | 创建时间        |
/// | updatedAt | DATETIME | NOT NULL           | 最后更新时间     |
/// | userId    | TEXT     | NOT NULL           | 所属用户 ID     |
class DiaryEntries extends Table {
  /// 自增主键 - 日记条目的唯一标识符
  IntColumn get id => integer().autoIncrement()();

  /// 云端主键 ID（Supabase UUID）
  ///
  /// 本地 SQLite 与云端 Supabase 使用不同的主键策略：
  /// - 本地使用自增整数，便于 Drift 查询和关联
  /// - 云端使用稳定 UUID，支持多设备同步
  TextColumn get cloudId => text().nullable()();

  /// 日记正文内容
  ///
  /// 存储用户通过富文本编辑器输入的日记内容。
  /// 可以是纯文本，也可以是 Flutter Quill 的 Delta JSON 格式。
  TextColumn get content => text()();

  /// 心情标记（可选）
  ///
  /// 存储用户选择的心情值（如 'happy', 'sad' 等）。
  /// 对应 [Mood] 枚举的 value 属性。
  /// 允许为 null，表示用户未选择心情。
  TextColumn get mood => text().nullable()();

  /// 日记所属日期
  ///
  /// 注意：这是日记"记录的"日期，不一定等于创建日期。
  /// 用户可能会补写之前日期的日记。
  DateTimeColumn get date => dateTime()();

  /// 记录创建时间
  DateTimeColumn get createdAt => dateTime()();

  /// 记录最后更新时间
  ///
  /// 每次编辑日记时应更新此字段。
  DateTimeColumn get updatedAt => dateTime()();

  /// 所属用户 ID
  ///
  /// 关联 Supabase Auth 中的用户标识符。
  /// 用于数据隔离，确保每个用户只能访问自己的日记。
  TextColumn get userId => text()();

  /// 地理位置字符串（可选），格式："纬度,经度"
  ///
  /// 记录写日记时的地理坐标，用于展示记录地点。
  TextColumn get location => text().nullable()();

  /// 位置地名（可选），存储经 geocoding 解析后的可读地址
  ///
  /// 例如："酸奶紫米露(西华记忆店)西华..."
  TextColumn get locationName => text().nullable()();

  /// 图片 URL 列表（可选），以英文逗号分隔
  ///
  /// 日记中插入的所有图片的 URL，逗号分隔。
  /// 展示时取第一张作为封面缩略图。
  TextColumn get imageUrls => text().nullable()();

  /// 所属日记本 ID（可选）
  ///
  /// 关联 [Notebooks] 表的主键。为 null 时归属默认日记本。
  IntColumn get notebookId => integer().nullable()();
}

/// ============================================================================
/// 日记本表 (notebooks)
/// ============================================================================
///
/// 存储用户自定义的日记本，用于对日记条目进行分组管理。
///
/// 每个日记本有独立的名称和封面图片，用户可自行创建、重命名、删除。
class Notebooks extends Table {
  /// 自增主键
  IntColumn get id => integer().autoIncrement()();

  /// 云端主键 ID（Supabase UUID）
  TextColumn get cloudId => text().nullable()();

  /// 日记本名称
  TextColumn get name => text()();

  /// 封面图片 URL（可选）
  TextColumn get coverUrl => text().nullable()();

  /// 排序序号（数值越小越靠前）
  IntColumn get sortOrder => integer().withDefault(const Constant(0))();

  /// 记录创建时间
  DateTimeColumn get createdAt => dateTime()();

  /// 记录最后更新时间
  DateTimeColumn get updatedAt => dateTime()();

  /// 所属用户 ID
  TextColumn get userId => text()();
}

/// ============================================================================
/// 任务表 (tasks)
/// ============================================================================
///
/// 存储用户的待办任务/计划项目。
///
/// 支持优先级设置、状态跟踪、截止日期和自定义排序。
/// 通过 [userId] 字段实现多用户数据隔离。
///
/// 数据库表结构：
/// | 列名        | 类型     | 约束                     | 说明              |
/// |------------|----------|------------------------|-----------------  |
/// | id         | INTEGER  | PRIMARY KEY, AUTO      | 自增主键           |
/// | title      | TEXT     | NOT NULL               | 任务标题           |
/// | description| TEXT     | NULLABLE               | 任务详细描述        |
/// | priority   | INTEGER  | NOT NULL, DEFAULT 2    | 优先级 (1高/2中/3低)|
/// | status     | TEXT     | NOT NULL, DEFAULT todo | 状态              |
/// | dueDate    | DATETIME | NULLABLE               | 截止日期           |
/// | sortOrder  | INTEGER  | NOT NULL, DEFAULT 0    | 排序序号           |
/// | createdAt  | DATETIME | NOT NULL               | 创建时间           |
/// | userId     | TEXT     | NOT NULL               | 所属用户 ID        |
class Tasks extends Table {
  /// 自增主键 - 任务的唯一标识符
  IntColumn get id => integer().autoIncrement()();

  /// 云端主键 ID（Supabase UUID）
  TextColumn get cloudId => text().nullable()();

  /// 任务标题
  ///
  /// 简洁描述任务内容的一句话文本。
  TextColumn get title => text()();

  /// 任务详细描述（可选）
  ///
  /// 对任务的补充说明、操作步骤等详细信息。
  TextColumn get description => text().nullable()();

  /// 任务优先级
  ///
  /// 使用整数表示：1 = 高优先级，2 = 中优先级（默认），3 = 低优先级。
  /// 数字越小优先级越高，便于按优先级升序排列。
  IntColumn get priority => integer().withDefault(const Constant(2))();

  /// 任务状态
  ///
  /// 可选值：'todo'（待办）、'in_progress'（进行中）、'done'（已完成）。
  /// 默认为 'todo'。
  TextColumn get status => text().withDefault(const Constant('todo'))();

  /// 截止日期（可选）
  ///
  /// 任务的预期完成时间。允许为 null，表示没有截止日期。
  DateTimeColumn get dueDate => dateTime().nullable()();

  /// 排序序号
  ///
  /// 用于用户自定义排序（如拖拽排序）。
  /// 数值越小越靠前显示，默认为 0。
  IntColumn get sortOrder => integer().withDefault(const Constant(0))();

  /// 记录创建时间
  DateTimeColumn get createdAt => dateTime()();

  /// 所属用户 ID
  TextColumn get userId => text()();
}

/// ============================================================================
/// 新闻摘要表 (news_summaries)
/// ============================================================================
///
/// 存储由 AI 后端服务生成的每日新闻摘要。
///
/// 新闻数据从 Supabase 后端同步到本地，支持离线浏览。
/// 按日期和分类组织，方便用户快速浏览当日要闻。
///
/// 数据库表结构：
/// | 列名      | 类型     | 约束               | 说明         |
/// |----------|----------|-------------------|-----------   |
/// | id       | INTEGER  | PRIMARY KEY, AUTO | 自增主键      |
/// | date     | DATETIME | NOT NULL          | 新闻日期      |
/// | category | TEXT     | NOT NULL          | 新闻分类      |
/// | headline | TEXT     | NOT NULL          | 新闻标题      |
/// | summary  | TEXT     | NOT NULL          | 摘要正文      |
/// | sourceUrl| TEXT     | NULLABLE          | 来源链接      |
/// | createdAt| DATETIME | NOT NULL          | 创建时间      |
class NewsSummaries extends Table {
  /// 自增主键 - 新闻摘要的唯一标识符
  IntColumn get id => integer().autoIncrement()();

  /// 新闻所属日期
  ///
  /// 用于按日期分组和查询新闻列表。
  DateTimeColumn get date => dateTime()();

  /// 新闻分类
  ///
  /// 存储分类标识符（如 'technology', 'finance' 等）。
  /// 对应 [NewsCategory] 枚举的 value 属性。
  TextColumn get category => text()();

  /// 新闻标题
  ///
  /// 简洁概括新闻核心内容的一句话。
  TextColumn get headline => text()();

  /// 新闻摘要正文
  ///
  /// AI 生成的新闻内容摘要。
  TextColumn get summary => text()();

  /// 新闻来源 URL（可选）
  ///
  /// 原始新闻文章的链接。允许为 null。
  TextColumn get sourceUrl => text().nullable()();

  /// 记录创建时间
  DateTimeColumn get createdAt => dateTime()();
}

/// ============================================================================
/// 新闻书签表 (news_bookmarks)
/// ============================================================================
///
/// 存储用户收藏的新闻摘要记录。
///
/// 这是一个关联表，将用户和新闻摘要进行多对多关联。
/// 通过 [userId] 和 [newsId] 的组合来标识一条收藏记录。
///
/// 数据库表结构：
/// | 列名    | 类型     | 约束               | 说明            |
/// |--------|----------|-------------------|---------------  |
/// | id     | INTEGER  | PRIMARY KEY, AUTO | 自增主键         |
/// | userId | TEXT     | NOT NULL          | 收藏用户 ID      |
/// | newsId | INTEGER  | NOT NULL          | 新闻摘要 ID      |
class NewsBookmarks extends Table {
  /// 自增主键 - 书签的唯一标识符
  IntColumn get id => integer().autoIncrement()();

  /// 收藏该新闻的用户 ID
  TextColumn get userId => text()();

  /// 被收藏的新闻摘要 ID
  ///
  /// 对应 [NewsSummaries] 表中的 id 字段。
  IntColumn get newsId => integer()();
}

/// ============================================================================
/// 应用数据库主类
/// ============================================================================
///
/// DayFlow 的核心数据库类，管理所有本地 SQLite 表。
///
/// 该类由 Drift 代码生成器自动生成具体实现（在 database.g.dart 中）。
/// 使用 [@DriftDatabase] 注解声明包含的表列表。
///
/// ## 数据库版本管理
///
/// 当前版本：1（初始版本）
///
/// 后续版本升级时，需要在 [migration] getter 中编写迁移逻辑，
/// 并递增 [schemaVersion]。
///
/// ## 单例模式
///
/// 数据库实例通过 Riverpod Provider ([appDatabaseProvider]) 管理，
/// 确保整个应用生命周期中只有一个数据库连接。
@DriftDatabase(tables: [DiaryEntries, Tasks, NewsSummaries, NewsBookmarks, Notebooks])
class AppDatabase extends _$AppDatabase {
  /// 构造函数
  ///
  /// 接收一个 [QueryExecutor] 参数，由平台特定的连接工厂提供。
  /// - 移动端/桌面端：使用本地 SQLite 文件连接
  /// - Web 端：使用 drift 的 `WebDatabase` 持久化到浏览器存储
  AppDatabase(super.e);

  /// 根据运行平台创建数据库实例
  ///
  /// 这是推荐的创建方式，内部会根据平台自动切换连接实现。
  AppDatabase.platform() : super(createDatabaseConnection());

  /// 数据库 Schema 版本号
  ///
  /// 当前版本为 2。
  ///
  /// v2 新增 `cloudId` 字段，用于将本地自增 ID 与 Supabase UUID 解耦。
  /// v3 新增 `location`、`locationName`、`imageUrls` 字段，支持地理位置与图片存储。
  /// v4 新增 `Notebooks` 表和 `DiaryEntries.notebookId` 字段，支持日记本分组。
  /// 每次修改表结构时需要递增此版本号，并在 [migration] 中编写对应的数据迁移逻辑。
  @override
  int get schemaVersion => 4;

  /// 数据库迁移策略
  ///
  /// 定义从旧版本到新版本的数据迁移步骤。
  @override
  MigrationStrategy get migration => MigrationStrategy(
        /// 首次创建数据库时，自动创建所有表
        onCreate: (Migrator m) async {
          await m.createAll();
        },
        onUpgrade: (Migrator m, int from, int to) async {
          // v1→v2：新增 cloudId 字段
          if (from < 2) {
            await m.addColumn(
              diaryEntries,
              diaryEntries.cloudId as GeneratedColumn<Object>,
            );
            await m.addColumn(
              tasks,
              tasks.cloudId as GeneratedColumn<Object>,
            );
          }
          // v2→v3：新增地理位置与图片字段（均为可选，无需迁移数据）
          if (from < 3) {
            await m.addColumn(
              diaryEntries,
              diaryEntries.location as GeneratedColumn<Object>,
            );
            await m.addColumn(
              diaryEntries,
              diaryEntries.locationName as GeneratedColumn<Object>,
            );
            await m.addColumn(
              diaryEntries,
              diaryEntries.imageUrls as GeneratedColumn<Object>,
            );
          }
          // v3→v4：新增日记本表和 notebookId 字段
          if (from < 4) {
            await m.createTable(notebooks);
            await m.addColumn(
              diaryEntries,
              diaryEntries.notebookId as GeneratedColumn<Object>,
            );
          }
        },
      );
}

/// ============================================================================
/// Riverpod Provider - 应用数据库单例
/// ============================================================================
///
/// 通过此 Provider 在整个应用中共享同一个数据库实例。
///
/// 使用方式：
/// ```dart
/// // 在 Widget 中获取数据库实例
/// final db = ref.read(appDatabaseProvider);
///
/// // 在 Provider 中使用数据库
/// final diaryDao = DiaryDao(ref.read(appDatabaseProvider));
/// ```
///
/// 注意：使用懒加载单例模式（lazy singleton），数据库只在首次访问时创建。
final appDatabaseProvider = Provider<AppDatabase>((ref) {
  /// 根据平台自动创建数据库连接
  final database = AppDatabase.platform();

  /// 当 Provider 被销毁时（通常是应用关闭时），关闭数据库连接
  /// 释放底层 SQLite 资源，防止文件锁残留
  ref.onDispose(() => database.close());

  return database;
});
