// db_connector_native.dart
// ─────────────────────────
// Öffnet eine SQLite-Datenbank via dart:ffi / sqlite3 (Android, iOS, Windows,
// macOS, Linux). Wird nur für native Plattformen kompiliert.
import 'dart:io';

import 'package:drift/native.dart';
import 'package:drift/drift.dart';

/// Öffnet die Drift-Datenbank unter dem angegebenen Dateipfad [path].
QueryExecutor openDatabaseForPlatform(String path) =>
    NativeDatabase(File(path), logStatements: false);
