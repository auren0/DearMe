import 'package:sembast/sembast.dart';

import 'app_database_stub.dart'
    if (dart.library.io) 'app_database_io.dart'
    if (dart.library.js_interop) 'app_database_web.dart'
    as platform;

/// Thin wrapper around the platform database.
///
/// Native platforms use a Sembast file database in the application support
/// directory. Web uses Sembast's IndexedDB backend. No letter content leaves
/// the device.
class AppDatabase {
  AppDatabase._(this.database);

  final Database database;

  static const String lettersStoreName = 'letters';

  final StoreRef<String, Map<String, Object?>> lettersStore =
      stringMapStoreFactory.store(lettersStoreName);

  static const int currentSchemaVersion = 1;
  static const String _metaStoreName = 'meta';

  static Future<AppDatabase> open() async {
    final database = await platform.openAppDatabase();
    await _migrate(database);
    return AppDatabase._(database);
  }

  /// Database-level migration runner.
  ///
  /// Letters themselves carry a `schemaVersion` and are decoded tolerantly, so
  /// adding fields does not require rewriting every record. Structural changes
  /// can be added here as ordered, idempotent steps.
  static Future<void> _migrate(Database database) async {
    final metaStore = stringMapStoreFactory.store(_metaStoreName);
    final metaRecord = metaStore.record('database');
    final existing = await metaRecord.get(database);
    final version = existing?['schemaVersion'];
    final currentVersion = version is int ? version : 0;

    if (currentVersion < 1) {
      await metaRecord.put(database, <String, Object?>{
        'schemaVersion': 1,
        'migratedAt': DateTime.now().toUtc().toIso8601String(),
      });
    }

    // Future:
    // if (currentVersion < 2) { ... ; await metaRecord.put(...); }
  }

  /// Exposed for tests that construct an in-memory database.
  static AppDatabase fromDatabase(Database database) {
    return AppDatabase._(database);
  }

  Future<void> close() => database.close();
}
