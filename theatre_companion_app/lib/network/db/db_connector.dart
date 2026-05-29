// db_connector.dart
// ──────────────────
// Konditionaler Export: Auf nativer Plattform wird db_connector_native.dart
// verwendet (NativeDatabase/SQLite), auf Web db_connector_web.dart (IndexedDB).
//
// Verwendung in app_database.dart:
//   import 'db_connector.dart';
//   final db = AppDatabase(openDatabaseForPlatform('/pfad/zur/db.sqlite'));
export 'db_connector_native.dart'
    if (dart.library.html) 'db_connector_web.dart';

