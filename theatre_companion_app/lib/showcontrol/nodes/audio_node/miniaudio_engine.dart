import 'dart:convert';
import 'dart:ffi';
import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:ffi/ffi.dart';
import 'package:flutter/foundation.dart';

import '../../session/clock_sync.dart';
import 'abstract_audio_engine.dart';
import 'audio_device.dart';

// ── Native function typedefs ──────────────────────────────────────────────────

typedef _InitNative = Int32 Function(Int32, Uint32, Uint32);
typedef _InitDart = int Function(int, int, int);

typedef _DeinitNative = Void Function();
typedef _DeinitDart = void Function();

typedef _ListDevNative = Pointer<Utf8> Function();
typedef _ListDevDart = Pointer<Utf8> Function();

typedef _SetDevNative = Int32 Function(Int32);
typedef _SetDevDart = int Function(int);

typedef _PreloadNative = Int32 Function(Pointer<Utf8>, Pointer<Utf8>);
typedef _PreloadDart = int Function(Pointer<Utf8>, Pointer<Utf8>);

typedef _UnloadNative = Void Function(Pointer<Utf8>);
typedef _UnloadDart = void Function(Pointer<Utf8>);

typedef _PlayNative = Int32 Function(
    Pointer<Utf8>, Int64, Float, Float, Float, Int32, Float, Float);
typedef _PlayDart = int Function(
    Pointer<Utf8>, int, double, double, double, int, double, double);

typedef _StopNative = Void Function(Pointer<Utf8>, Float);
typedef _StopDart = void Function(Pointer<Utf8>, double);

typedef _PauseNative = Void Function(Pointer<Utf8>, Float);
typedef _PauseDart = void Function(Pointer<Utf8>, double);

typedef _ResumNative = Void Function(Pointer<Utf8>, Float);
typedef _ResumDart = void Function(Pointer<Utf8>, double);

typedef _FadeVolNative = Void Function(Pointer<Utf8>, Float, Float, Int32);
typedef _FadeVolDart = void Function(Pointer<Utf8>, double, double, int);

typedef _SetMasterVolNative = Void Function(Float);
typedef _SetMasterVolDart = void Function(double);

typedef _DetectSilenceNative = Int32 Function(
    Pointer<Utf8>, Float, Float, Pointer<Float>, Pointer<Float>);
typedef _DetectSilenceDart = int Function(
    Pointer<Utf8>, double, double, Pointer<Float>, Pointer<Float>);

typedef _StopAllNative = Void Function();
typedef _StopAllDart = void Function();

typedef _FreeStrNative = Void Function(Pointer<Utf8>);
typedef _FreeStrDart = void Function(Pointer<Utf8>);

// ── Library loader ────────────────────────────────────────────────────────────

DynamicLibrary _loadLib() {
  if (Platform.isWindows) return DynamicLibrary.open('miniaudio_wrapper.dll');
  if (Platform.isAndroid) return DynamicLibrary.open('libminiaudio_wrapper.so');
  if (Platform.isLinux) return DynamicLibrary.open('libminiaudio_wrapper.so');
  if (Platform.isMacOS) return DynamicLibrary.process();
  if (Platform.isIOS) return DynamicLibrary.process();
  throw UnsupportedError(
      'miniaudio_wrapper: unsupported platform ${Platform.operatingSystem}');
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

  late final _InitDart _init;
  late final _DeinitDart _deinit;
  late final _ListDevDart _listDev;
  late final _SetDevDart _setDev;
  late final _PreloadDart _preload;
  late final _UnloadDart _unload;
  late final _PlayDart _play;
  late final _StopDart _stop;
  late final _PauseDart _pause;
  late final _ResumDart _resume;
  late final _FadeVolDart _fadeVol;
  late final _SetMasterVolDart _setMasterVol;
  late final _StopAllDart _stopAll;
  late final _FreeStrDart _freeStr;
  late final _DetectSilenceDart _detectSilence;

  bool _initialized = false;
  AudioDevice? _selectedDevice;
  final Set<String> _activeCueIds = {};

  MiniaudioEngine() {
    _lib = _loadLib();
    _init = _lib.lookupFunction<_InitNative, _InitDart>('ma_wrapper_init');
    _deinit =
        _lib.lookupFunction<_DeinitNative, _DeinitDart>('ma_wrapper_deinit');
    _listDev = _lib.lookupFunction<_ListDevNative, _ListDevDart>(
        'ma_wrapper_list_devices');
    _setDev = _lib
        .lookupFunction<_SetDevNative, _SetDevDart>('ma_wrapper_set_device');
    _preload =
        _lib.lookupFunction<_PreloadNative, _PreloadDart>('ma_wrapper_preload');
    _unload =
        _lib.lookupFunction<_UnloadNative, _UnloadDart>('ma_wrapper_unload');
    _play = _lib.lookupFunction<_PlayNative, _PlayDart>('ma_wrapper_play');
    _stop = _lib.lookupFunction<_StopNative, _StopDart>('ma_wrapper_stop');
    _pause = _lib.lookupFunction<_PauseNative, _PauseDart>('ma_wrapper_pause');
    _resume = _lib.lookupFunction<_ResumNative, _ResumDart>('ma_wrapper_resume');
    _fadeVol = _lib.lookupFunction<_FadeVolNative, _FadeVolDart>('ma_wrapper_fade_volume');
    _setMasterVol = _lib.lookupFunction<_SetMasterVolNative, _SetMasterVolDart>('ma_wrapper_set_master_volume');
    _stopAll = _lib.lookupFunction<_StopAllNative, _StopAllDart>('ma_wrapper_stop_all');
    _freeStr = _lib.lookupFunction<_FreeStrNative, _FreeStrDart>('ma_wrapper_free_string');
    _detectSilence = _lib.lookupFunction<_DetectSilenceNative, _DetectSilenceDart>('ma_wrapper_detect_silence');
  }

  // ── AbstractAudioEngine ────────────────────────────────────────────────────

  double _masterVolumeDb = 0.0;

  @override
  double get masterVolumeDb => _masterVolumeDb;

  @override
  void setMasterVolume(double db) {
    _masterVolumeDb = db;
    _setMasterVol(db);
  }

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
      debugPrint(
          '[MiniaudioEngine] init failed (code=$result), trying default');
      final fallback = _init(-1, 48000, 2);
      if (fallback != 0) {
        throw Exception(
            'MiniaudioEngine: failed to initialise (code=$fallback)');
      }
      _selectedDevice = null;
    } else {
      _selectedDevice = device;
    }
    _initialized = true;
    debugPrint(
        '[MiniaudioEngine] init OK device=${_selectedDevice?.name ?? "default"}');
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
      final json = _ptrToString(ptr);
      final list = (jsonDecode(json) as List).cast<Map<String, dynamic>>();
      return list
          .map((e) => AudioDevice(
                id: e['name'] as String,
                name: e['name'] as String,
                backend: _parseBackend(e['backend'] as String? ?? ''),
                index: e['index'] as int,
              ))
          .toList();
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
    final cuePtr = cueId.toNativeUtf8();
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
    double volumeDb = 0.0,
    double fadeInMs = 0.0,
    double fadeOutMs = 0.0,
    bool loop = false,
    double startTimeMs = 0.0,
    double endTimeMs = 0.0,
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
        startTimeMs,
        endTimeMs,
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
      _pause(ptr, fadeOutMs);
    } finally {
      malloc.free(ptr);
    }
  }

  @override
  Future<void> resume(String cueId, {double fadeInMs = 0.0}) async {
    final ptr = cueId.toNativeUtf8();
    try {
      _resume(ptr, fadeInMs);
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
    final targetDb = targetLinear <= 0.0
        ? -100.0
        : 20.0 * (math.log(targetLinear) / math.ln10);
    final ptr = cueId.toNativeUtf8();
    try {
      _fadeVol(ptr, targetDb, durationMs, stopWhenDone ? 1 : 0);
      if (pauseWhenDone && !stopWhenDone) {
        // Pause after fade: fade to silent then stop (native side will stop).
        _fadeVol(ptr, -100.0, durationMs, 1);
      }
    } finally {
      malloc.free(ptr);
    }
  }

  @override
  Future<({double startMs, double endMs})?> detectSilence(
    String filePath, {
    double thresholdDb = -60.0,
    double padMs = 50.0,
  }) async {
    final pathPtr = filePath.toNativeUtf8();
    final outStart = calloc<Float>();
    final outEnd = calloc<Float>();
    try {
      final result = _detectSilence(pathPtr, thresholdDb, padMs, outStart, outEnd);
      if (result != 0) return null;
      return (startMs: outStart.value.toDouble(), endMs: outEnd.value.toDouble());
    } finally {
      malloc.free(pathPtr);
      calloc.free(outStart);
      calloc.free(outEnd);
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

  /// Reads a C string pointer as UTF-8 with malformed-byte tolerance.
  /// Avoids [FormatException] when Windows device names contain bytes that
  /// miniaudio could not fully convert to UTF-8 (e.g. truncated surrogates).
  static String _ptrToString(Pointer<Utf8> ptr) {
    final bytes = ptr.cast<Uint8>();
    var len = 0;
    while (bytes[len] != 0) len++;
    return utf8.decode(bytes.asTypedList(len), allowMalformed: true);
  }

  static AudioBackend _parseBackend(String name) =>
      audioBackendFromWireName(name);

  static Future<String> _writeTempWav(String cueId, List<int> bytes) async {
    final dir = Directory.systemTemp;
    final path = '${dir.path}/ma_tmp_$cueId.wav';
    await File(path).writeAsBytes(bytes);
    return path;
  }
}
