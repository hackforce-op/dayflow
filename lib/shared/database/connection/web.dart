import 'package:drift/drift.dart' show LazyDatabase;
import 'package:drift/web.dart';

const _databaseName = 'dayflow_web';

/// 创建 Web 平台的数据库连接。
///
/// 使用 drift 的 `WebDatabase` 将 SQLite 数据持久化到浏览器存储中。
/// 优先使用 IndexedDB，旧浏览器则回退到 localStorage。
LazyDatabase createDatabaseConnection() {
  return LazyDatabase(() async {
    final storage = await DriftWebStorage.indexedDbIfSupported(_databaseName);

    return WebDatabase.withStorage(
      storage,
      logStatements: false,
    );
  });
}
