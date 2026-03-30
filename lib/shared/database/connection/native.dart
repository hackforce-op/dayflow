/// ============================================================================
/// DayFlow - 原生平台数据库连接
/// ============================================================================
///
/// 该文件提供了移动端（iOS/Android）和桌面端（macOS/Windows/Linux）
/// 平台的 SQLite 数据库连接实现。
///
/// ## 工作原理
///
/// 1. 通过 [path_provider] 获取应用文档目录路径
/// 2. 在文档目录下创建 `dayflow.db` 数据库文件
/// 3. 使用 [NativeDatabase] 打开 SQLite 连接
///
/// ## 依赖说明
///
/// - [sqlite3_flutter_libs]：提供预编译的 SQLite 动态库
///   - Android: 包含 armeabi-v7a, arm64-v8a, x86, x86_64 架构
///   - iOS: 使用系统自带的 SQLite
///   - macOS/Windows/Linux: 包含对应平台的动态库
/// - [path_provider]：跨平台获取应用数据存储路径
/// - [path]：跨平台的文件路径拼接工具
///
/// ## 注意事项
///
/// - 数据库文件名为 `dayflow.db`，位于应用文档目录下
/// - 卸载应用时数据库文件会被自动清除（随应用沙箱删除）
/// - 开启了 WAL（Write-Ahead Logging）模式以提升并发读写性能
/// ============================================================================
import 'dart:io';

import 'package:drift/drift.dart' show LazyDatabase;
import 'package:drift/native.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sqlite3/sqlite3.dart';
import 'package:sqlite3_flutter_libs/sqlite3_flutter_libs.dart';

/// 数据库文件名常量
///
/// 所有平台共用同一文件名，存储在各平台的应用文档目录下。
const _databaseFileName = 'dayflow.db';

/// 创建原生平台的数据库连接
///
/// 返回一个 [LazyDatabase] 实例，该实例在首次执行查询时才会真正打开数据库。
/// 这种懒加载方式确保了异步初始化（获取文件路径）不会阻塞应用启动。
///
/// ## 执行流程
///
/// 1. 调用 [_openDatabase] 获取数据库文件对象
/// 2. 创建 [NativeDatabase] 连接并配置日志
/// 3. 返回可供 Drift 使用的 [QueryExecutor]
///
/// ## 使用方式
///
/// 该函数通常在创建 [AppDatabase] 实例时调用：
/// ```dart
/// final db = AppDatabase(createNativeConnection());
/// ```
LazyDatabase createNativeConnection() {
  return LazyDatabase(() async {
    /// 获取数据库文件路径
    final dbFile = await _openDatabase();

    /// 创建原生数据库连接
    ///
    /// [logStatements] 参数控制是否在控制台输出 SQL 语句。
    /// 调试时可设为 true 以查看所有执行的 SQL 查询。
    /// 生产环境建议设为 false 以减少性能开销。
    return NativeDatabase.createInBackground(
      dbFile,
      logStatements: false,
    );
  });
}

/// 暴露统一的平台连接工厂，供条件导入文件调用。
LazyDatabase createDatabaseConnection() {
  return createNativeConnection();
}

/// 获取数据库文件对象
///
/// 根据运行平台获取合适的应用文档目录，并返回数据库文件的 [File] 对象。
///
/// ## Android 平台特殊处理
///
/// 在 Android 上需要额外调用 [applyWorkaroundToOpenSqlite3OnOldAndroidVersions]
/// 来确保旧版本 Android（API < 24）能正确加载 SQLite 动态库。
/// 这是 sqlite3_flutter_libs 包提供的兼容性修复。
///
/// ## 数据库路径示例
///
/// - Android: `/data/data/com.example.dayflow/files/dayflow.db`
/// - iOS: `~/Documents/dayflow.db`
/// - macOS: `~/Library/Containers/.../Documents/dayflow.db`
/// - Windows: `C:\Users\xxx\AppData\Roaming\com.example\dayflow\dayflow.db`
/// - Linux: `/home/xxx/.local/share/dayflow/dayflow.db`
Future<File> _openDatabase() async {
  /// 获取应用文档目录
  ///
  /// 该目录在不同平台有不同的位置，但都保证：
  /// - 只有当前应用可以访问（沙箱隔离）
  /// - 卸载应用时自动清除
  /// - 有足够的存储空间
  final documentsDir = await getApplicationDocumentsDirectory();

  /// 拼接完整的数据库文件路径
  final dbPath = p.join(documentsDir.path, _databaseFileName);

  /// Android 平台兼容性修复
  ///
  /// 旧版本 Android 的系统 SQLite 可能版本过低，
  /// 需要使用包中自带的 SQLite 动态库来替代。
  if (Platform.isAndroid) {
    await applyWorkaroundToOpenSqlite3OnOldAndroidVersions();
  }

  /// 配置 SQLite 临时文件目录
  ///
  /// 某些 SQLite 操作（如大型排序）需要临时文件，
  /// 默认的 /tmp 目录在某些 Android 设备上可能无法访问。
  /// 将临时目录设置为应用缓存目录可以避免权限问题。
  final cacheDir = await getTemporaryDirectory();
  sqlite3.tempDirectory = cacheDir.path;

  return File(dbPath);
}
