import 'package:drift/drift.dart';

/// 为不受支持的平台提供兜底实现。
QueryExecutor createDatabaseConnection() {
  throw UnsupportedError(
    'DayFlow 当前仅支持 Flutter Web、Android、iOS、Windows、macOS 和 Linux。',
  );
}
