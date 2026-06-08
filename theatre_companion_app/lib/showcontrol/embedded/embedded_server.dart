import 'dart:ffi';
import 'dart:io';

import 'package:ffi/ffi.dart';

// ── C-Funktions-Signaturen ────────────────────────────────────────────────────

typedef _StartNative = Int32 Function(Int32 port, Pointer<Utf8> dataDir);
typedef _StartDart = int Function(int port, Pointer<Utf8> dataDir);
typedef _StopNative = Void Function();
typedef _StopDart = void Function();

/// Thin FFI-Wrapper um die stagesync_core shared library (Go-Corelib).
///
/// Auf Desktop-Plattformen (Windows/macOS/Linux) startet er den Go-gRPC-Server
/// im selben Prozess. Mobile-Plattformen sind nicht unterstützt — dort verbindet
/// sich die App mit einem Netzwerk-Server.
class EmbeddedServer {
  EmbeddedServer._();
  static final EmbeddedServer instance = EmbeddedServer._();

  DynamicLibrary? _lib;
  _StartDart? _startFn;
  _StopDart? _stopFn;

  bool _running = false;
  int _port = 0;

  /// True wenn der embedded Server läuft.
  bool get isRunning => _running;

  /// Port auf dem der eingebettete Server lauscht (0 wenn nicht gestartet).
  int get port => _port;

  /// True auf Plattformen wo embedding unterstützt wird.
  static bool get isSupported =>
      Platform.isWindows || Platform.isLinux || Platform.isMacOS;

  /// Startet den eingebetteten gRPC-Server.
  /// Gibt [true] zurück wenn der Start erfolgreich war.
  Future<bool> start({required int port, required String dataDir}) async {
    if (!isSupported) return false;
    if (_running) return true;

    _lib ??= _openLibrary();
    if (_lib == null) return false;

    try {
      _startFn ??= _lib!.lookupFunction<_StartNative, _StartDart>(
        'stagesync_start',
      );
      _stopFn ??= _lib!.lookupFunction<_StopNative, _StopDart>(
        'stagesync_stop',
      );
    } catch (e) {
      return false;
    }

    final dataDirPtr = dataDir.toNativeUtf8();
    try {
      final result = _startFn!(port, dataDirPtr);
      if (result == 0) {
        _running = true;
        _port = port;
        return true;
      }
      return false;
    } finally {
      calloc.free(dataDirPtr);
    }
  }

  /// Stoppt den eingebetteten Server.
  void stop() {
    if (!_running || _stopFn == null) return;
    _stopFn!();
    _running = false;
    _port = 0;
  }

  // ── Library laden ─────────────────────────────────────────────────────────────

  static DynamicLibrary? _openLibrary() {
    final name = _libraryName();
    try {
      return DynamicLibrary.open(name);
    } catch (_) {
      // Library nicht gefunden — App läuft im Netzwerk-only-Modus.
      return null;
    }
  }

  static String _libraryName() {
    if (Platform.isWindows) return 'stagesync_core.dll';
    if (Platform.isMacOS) return 'libstagesync_core.dylib';
    return 'libstagesync_core.so';
  }
}
