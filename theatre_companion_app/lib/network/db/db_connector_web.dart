// db_connector_web.dart
// ──────────────────────
// Öffnet eine Drift-Datenbank via sql.js / IndexedDB im Browser.
// Wird nur für Web kompiliert (dart.library.html verfügbar).
//
// VORAUSSETZUNG: sql.js muss in web/index.html geladen werden:
//   <script src="https://cdnjs.cloudflare.com/ajax/libs/sql.js/1.10.2/sql-wasm.js"></script>
//
// Alternativ modernes Setup mit WasmDatabase:
//   flutter pub run drift_dev:make_executors  (generiert sqlite3.wasm + worker)
import 'package:drift/web.dart';
import 'package:drift/drift.dart';

/// Öffnet die Drift-Datenbank via IndexedDB im Browser.
/// [path] wird als Datenbankname verwendet (kein Dateipfad).
QueryExecutor openDatabaseForPlatform(String path) =>
    WebDatabase(path, logStatements: false);

