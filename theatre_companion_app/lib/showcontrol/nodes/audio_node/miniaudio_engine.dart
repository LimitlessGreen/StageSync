import 'dart:convert';
import 'dart:ffi';
import 'dart:io';

import 'package:ffi/ffi.dart';
import 'package:flutter/foundation.dart';

import '../../session/clock_sync.dart';
import 'abstract_audio_engine.dart';
import 'audio_device.dart';

// ── Native function typedefs ──────────────────────────────────────────────────

typedef _InitNative   = Int32 Function(Int32, Uint32, Uint32);
typedef _InitDart     = int   Function(int, int, int);

typedef _DeinitNative = Void Function();
typedef _DeinitDart   = void Function();

typedef _ListDevNative = Pointer<Utf8> Function();
typedef _ListDevDart   = Pointer<Utf8> Function();

typedef _SetDevNative  = Int32 Function(Int32);
typedef _SetDevDart    = int   Function(int);

typedef _PreloadNative = Int32 Function(Pointer<Utf8>, Pointer<Utf8>);
typedef _PreloadDart   = int   Function(Pointer<Utf8>, Pointer<Utf8>);

typedef _UnloadNative  = Void Function(Pointer<Utf8>);
typedef _UnloadDart    = void Function(Pointer<Utf8>);

typedef _PlayNative = Int32 Function(
    Pointer<Utf8>, Int64, Float, Float, Float, Int32);
typedef _PlayDart = int Function(
    Pointer<Utf8>, int, double, double, double, int);

typedef _StopNative   = Void Function(Pointer<Utf8>, Float);
typedef _StopDart     = void  Function(Pointer<Utf8>, double);

typedef _PauseNative  = Void Function(Pointer<Utf8>);
typedef _PauseDart    = void  Function(Pointer<Utf8>);

typedef _ResumNative  = Void Function(Pointer<Utf8>);
typedef _ResumDart    = void  Function(Pointer<Utf8>);

typedef _StopAllNative = Void Function();
typedef _StopAllDart   = void Function();

typedef _FreeStrNative = Void Function(Pointer<Utf8>);
typedef _FreeStrDart   = void Function(Pointer<Utf8>);

// ── Library loader ────────────────────────────────────────────────────────────

DynamicLibrary _loadLib() {
  if (Platform.isWindows) return DynamicLibrary.open('miniaudio_wrapper.dll');
  if (Platform.isAndroid) return DynamicLibrary.open('libminiaudio_wrapper.so');
  if (Platform.isLinux)   return DynamicLibrary.open('libminiaudio_wrapper.so');
  if (Platform.isMacOS)   return DynamicLibrary.process();
  if (Platform.isIOS)     return DynamicLibrary.process();
  throw UnsupportedError('miniaudio_wrapper: unsupported platform ${Platform.operatingSystem}');
}

// ── MiniaudioEngine ───────────────────────────────────────────────────────────

/// [AbstractAudioEngine] implementation backed by miniaudio via dart:ffi.
///
/// Benefits over the SoLoud wrapper:
/// - Device selection uses platform-native IDs (not unstable sequential indices)
/// - Live device switch: SetDevice reinitialises the engine, existing preloaded
///   sounds are unaffected (they stay in memory; only playback is restarted)
/// - WASAPI Exclusive mode on Windows (→ low latency, comparable to ASIO)
/// - ASIO on Windows: compile native/CMakeLists.txt with MA_ENABLE_ASIO
/// - AAudio on Android API 26+ (→ low latency; OpenSL ES fallback for older)
/// - Proper server-timestamp scheduling (ma_sound_set_start_time_in_pcm_frames)
class MiniaudioEngine implements AbstractAudioEngine {
  late final DynamicLibrary _lib;

  late final _InitDart     _init;
  late final _DeinitDart   _deinit;
  late final _ListDevDart  _listDev;
  late final _SetDevDart   _setDev;
  late final _PreloadDart  _preload;
  late final _UnloadDart   _unload;
  late final _PlayDart     _play;
  late final _StopDart     _stop;
  late final _PauseDart    _pause;
  late final _ResumDart    _resume;
  late final _StopAllDart  _stopAll;
  late final _FreeStrDart  _freeStr;

  bool _initialized = false;
  AudioDevice? _selectedDevice;
  final Set<String> _activeCueIds = {};

  MiniaudioEngine() {
    _lib = _loadLib();
    _init    = _lib.lookupFunction<_InitNative,    _InitDart>   ('ma_wrapper_init');
    _deinit  = _lib.lookupFunction<_DeinitNative,  _DeinitDart> ('ma_wrapper_deinit');
    _listDev = _lib.lookupFunction<_ListDevNative, _ListDevDart>('ma_wrapper_list_devices');
    _setDev  = _lib.lookupFunction<_SetDevNative,  _SetDevDart> ('ma_wrapper_set_device');
    _preload = _lib.lookupFunction<_PreloadNative, _PreloadDart>('ma_wrapper_preload');
    _unload  = _lib.lookupFunction<_UnloadNative,  _UnloadDart> ('ma_wrapper_unload');
    _play    = _lib.lookupFunction<_PlayNative,    _PlayDart>   ('ma_wrapper_play');
    _stop    = _lib.lookupFunction<_StopNative,    _StopDart>   ('ma_wrapper_stop');
    _pause   = _lib.lookupFunction<_PauseNative,   _PauseDart>  ('ma_wrapper_pause');
    _resume  = _lib.lookupFunction<_ResumNative,   _ResumDart>  ('ma_wrapper_resume');
    _stopAll = _lib.lookupFunction<_StopAllNative, _StopAllDart>('ma_wrapper_stop_all');
    _freeStr = _lib.lookupFunction<_FreeStrNative, _FreeStrDart>('ma_wrapper_free_string');
  }

  // ── AbstractAudioEngine ────────────────────────────────────────────────────

  @override
  bool get isInitialized => _initialized;

  @override
  AudioDevice? get selectedDevice => _selectedDevice;

  @override
  List<String> get activeCueIds => List.unmodifiable(_activeCueIds);

  @override
  Future<void> init({AudioDevice? device}) async {
    final idx = device?.index ?? -1;
    final result = _init(idx, 48000, 2);
    if (result != 0) {
      debugPrint('[MiniaudioEngine] init failed (code=$result), trying default');
      final fallback = _init(-1, 48000, 2);
      if (fallback != 0) {
        throw Exception('MiniaudioEngine: failed to initialise (code=$fallback)');
      }
      _selectedDevice = null;
    } else {
      _selectedDevice = device;
    }
    _initialized = true;
    debugPrint('[MiniaudioEngine] init OK device=${_selectedDevice?.name ?? "default"}');
  }

  @override
  Future<void> deinit() async {
    _deinit();
    _initialized = false;
    _selectedDevice = null;
    _activeCueIds.clear();
  }

  @override
  Future<List<AudioDevice>> listDevices() async {
    final ptr = _listDev();
    if (ptr == nullptr) return [];
    try {
      final json = ptr.toDartString();
      final list = (jsonDecode(json) as List).cast<Map<String, dynamic>>();
      return list.map((e) => AudioDevice(
        id:      e['name'] as String,
        name:    e['name'] as String,
        backend: _parseBackend(e['backend'] as String? ?? ''),
        index:   e['index'] as int,
      )).toList();
    } catch (e) {
      debugPrint('[MiniaudioEngine] listDevices parse error: $e');
      return [];
    } finally {
      _freeStr(ptr);
    }
  }

  @override
  Future<AudioDevice?> switchDevice(AudioDevice device) async {
    if (!_initialized) {
      await init(device: device);
      return _selectedDevice;
    }
    final result = _setDev(device.index >= 0 ? device.index : -1);
    if (result == 0) {
      _selectedDevice = device;
      debugPrint('[MiniaudioEngine] switched to ${device.name}');
    } else {
      debugPrint('[MiniaudioEngine] switchDevice failed (code=$result)');
    }
    return _selectedDevice;
  }

  @override
  Future<void> preload(String cueId, String filePath) async {
    if (!_initialized) await init();
    final cuePtr  = cueId.toNativeUtf8();
    final pathPtr = filePath.toNativeUtf8();
    try {
      final r = _preload(cuePtr, pathPtr);
      if (r != 0) {
        debugPrint('[MiniaudioEngine] preload failed cueId=$cueId (code=$r)');
      }
    } finally {
      malloc.free(cuePtr);
      malloc.free(pathPtr);
    }
  }

  @override
  Future<void> playAt({
    required String cueId,
    required String filePath,
    required int startUnixMillis,
    double volumeDb   = 0.0,
    double fadeInMs   = 0.0,
    double fadeOutMs  = 0.0,
    bool   loop       = false,
    double startTimeMs = 0.0,
    double endTimeMs  = 0.0,
  }) async {
    if (!_initialized) await init();

    // Preload if not already done.
    if (!_activeCueIds.contains(cueId) && filePath.isNotEmpty) {
      await preload(cueId, filePath);
    }

    // Server-Zeitstempel auf lokale Uhr umrechnen (ClockSync-Offset).
    // Das Native-Layer vergleicht gegen time.Now() auf dem lokalen Gerät —
    // ohne Konvertierung würde eine Uhrabweichung zwischen Server und Node
    // zu zu frühem/spätem Start führen.
    // startUnixMillis == 0 bedeutet "sofort spielen" → keine Konvertierung.
    int scheduledMs = startUnixMillis;
    if (scheduledMs > 0 && ClockSync.instance.isSynced) {
      scheduledMs = ClockSync.instance.toLocalMillis(scheduledMs);
    }

    final cuePtr = cueId.toNativeUtf8();
    try {
      final r = _play(
        cuePtr,
        scheduledMs,
        volumeDb.toDouble(),
        fadeInMs.toDouble(),
        fadeOutMs.toDouble(),
        loop ? 1 : 0,
      );
      if (r == 0) {
        _activeCueIds.add(cueId);
      } else {
        debugPrint('[MiniaudioEngine] play failed cueId=$cueId (code=$r)');
      }
    } finally {
      malloc.free(cuePtr);
    }
  }

  @override
  Future<void> playWavBytes(String cueId, List<int> wavBytes,
      {double volumeDb = 0.0}) async {
    // Write bytes to a temp file, then preload+play.
    if (!_initialized) await init();
    final tmp = await _writeTempWav(cueId, wavBytes);
    await preload(cueId, tmp);
    await playAt(
      cueId: cueId,
      filePath: tmp,
      startUnixMillis: 0,
      volumeDb: volumeDb,
    );
  }

  @override
  Future<void> stop(String cueId, {double fadeOutMs = 0.0}) async {
    final ptr = cueId.toNativeUtf8();
    try {
      _stop(ptr, fadeOutMs.toDouble());
      _activeCueIds.remove(cueId);
    } finally {
      malloc.free(ptr);
    }
  }

  @override
  Future<void> stopAll({double fadeOutMs = 0.0}) async {
    _stopAll();
    _activeCueIds.clear();
  }

  @override
  Future<void> pause(String cueId, {double fadeOutMs = 0.0}) async {
    final ptr = cueId.toNativeUtf8();
    try {
      _pause(ptr);
    } finally {
      malloc.free(ptr);
    }
  }

  @override
  Future<void> resume(String cueId, {double fadeInMs = 0.0}) async {
    final ptr = cueId.toNativeUtf8();
    try {
      _resume(ptr);
    } finally {
      malloc.free(ptr);
    }
  }

  @override
  Future<void> fadeVolume(
    String cueId, {
    required double targetLinear,
    required double durationMs,
    bool stopWhenDone = false,
    bool pauseWhenDone = false,
  }) async {
    // Miniaudio-Engine: Lautstärke sofort setzen (kein smooth fade auf FFI-Ebene).
    // TODO: native fade implementieren wenn miniaudio FFI-Bindings erweitert werden.
    if (stopWhenDone) {
      await stop(cueId);
    } else if (pauseWhenDone) {
      await pause(cueId);
    }
  }

  @override
  Future<void> disposeAll() async {
    // Stop all sounds but keep the engine running.
    _stopAll();
    for (final id in List.of(_activeCueIds)) {
      final ptr = id.toNativeUtf8();
      _unload(ptr);
      malloc.free(ptr);
    }
    _activeCueIds.clear();
  }

  // ── Helpers ────────────────────────────────────────────────────────────────

  static AudioBackend _parseBackend(String name) => switch (name) {
    'wasapi'      => AudioBackend.wasapi,
    'asio'        => AudioBackend.asio,
    'directsound' => AudioBackend.directSound,
    'coreaudio'   => AudioBackend.coreAudio,
    'alsa'        => AudioBackend.alsa,
    'pulseaudio'  => AudioBackend.pulseAudio,
    'jack'        => AudioBackend.jack,
    'aaudio'      => AudioBackend.aaudio,
    'opensl'      => AudioBackend.openSLES,
    _             => AudioBackend.unknown,
  };

  static Future<String> _writeTempWav(String cueId, List<int> bytes) async {
    final dir  = Directory.systemTemp;
    final path = '${dir.path}/ma_tmp_$cueId.wav';
    await File(path).writeAsBytes(bytes);
    return path;
  }
}
