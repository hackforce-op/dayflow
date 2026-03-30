import 'package:drift/drift.dart';

import 'connection_stub.dart'
    if (dart.library.html) 'web.dart'
    if (dart.library.io) 'native.dart' as impl;

/// 根据当前平台创建合适的 Drift 数据库连接。
QueryExecutor createDatabaseConnection() {
  return impl.createDatabaseConnection();
}
