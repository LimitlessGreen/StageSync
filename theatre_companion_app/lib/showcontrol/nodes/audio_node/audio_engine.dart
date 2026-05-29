import 'dart:async';
import 'dart:io';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter_soloud/flutter_soloud.dart';

import '../../session/clock_sync.dart';

/// Verwaltet simultane Cue-Wiedergabe via SoLoud.
/// Unterstützt Geräteauswahl (Windows/macOS/Linux/Android/iOS).
class AudioEngine {
  final _soloud = SoLoud.instance;

  /// Maximale erlaubte Vorlauf-Zeit für synchronisierte Starts. Größere Werte
  /// deuten auf Uhren-Drift zwischen Geräten hin (Android↔PC) und nicht auf
  /// echte Latenz — dann wird sofort abgespielt statt sekundenlang zu warten.
  static const int _maxScheduleAheadMs = 2000;

  /// Kleiner Output-Buffer für niedrige Ausgabe-Latenz (1024 @ 44,1 kHz ≈ 23 ms
  /// statt ~46 ms beim Default 2048). Reduziert die hörbare Trigger-Latenz.
  static const int _bufferSize = 1024;

  /// Ab dieser Restzeit wird aktiv gepollt statt per Timer gewartet — gegen den
  /// Event-Loop-Jitter (bis ~16 ms), der sonst hörbaren Versatz zwischen
  /// mehreren Audio-Geräten verursacht.
  static const int _spinThresholdMs = 12;

  final Map<String, AudioSource> _sources = {};
  final Map<String, SoundHandle> _handles = {};
  // Pfad der je Cue zuletzt geladenen Quelle → erneutes Laden vermeiden, wenn
  // dieselbe Datei via Arming bereits vorgeladen wurde (sofortiger Trigger).
  final Map<String, String> _loadedPaths = {};
  // Ziel-Lautstärke (linear) je laufender Cue → korrektes Wiederherstellen nach
  // Resume / Fade.
  final Map<String, double> _targetVolumes = {};
  // Generationszähler je Cue, um eine laufende Pause-Fade-Sequenz zu entwerten,
  // wenn zwischenzeitlich resume/stop/ein neuer Play kommt (Race-Schutz).
  final Map<String, int> _fadeGen = {};

  bool _initialized = false;
  PlaybackDevice? _selectedDevice;

  // ── Init / Gerät ──────────────────────────────────────────────────────────

  Future<void> init({PlaybackDevice? device}) async {
    if (_soloud.isInitialized) {
      _soloud.deinit();
      _initialized = false;
    }

    // Strategie 1: gewünschtes Gerät
    if (device != null) {
      try {
        await _soloud.init(device: device, bufferSize: _bufferSize);
        if (_soloud.isInitialized) {
          _initialized = true;
          _selectedDevice = device;
          debugPrint('[AudioEngine] init OK device=${device.name}');
          return;
        }
      } catch (e) {
        debugPrint('[AudioEngine] init mit "${device.name}" fehlgeschlagen: $e');
        if (_soloud.isInitialized) _soloud.deinit();
      }
    }

    // Strategie 2: Default ohne Gerätespezifikation
    try {
      await _soloud.init(bufferSize: _bufferSize);
      if (_soloud.isInitialized) {
        _initialized = true;
        _selectedDevice = null;
        debugPrint('[AudioEngine] init OK device=default');
        return;
      }
    } catch (e) {
      debugPrint('[AudioEngine] init FEHLER (default): $e');
      if (_soloud.isInitialized) _soloud.deinit();
    }

    // Strategie 3 (Windows-Fallback): explizit erstes Gerät aus der Liste
    try {
      final devices = listDevices();
      if (devices.isNotEmpty) {
        await _soloud.init(device: devices.first, bufferSize: _bufferSize);
        if (_soloud.isInitialized) {
          _initialized = true;
          _selectedDevice = devices.first;
          debugPrint('[AudioEngine] init OK device=${devices.first.name} (Windows-Fallback)');
          return;
        }
      }
    } catch (e) {
      debugPrint('[AudioEngine] init FEHLER (Windows-Fallback): $e');
      if (_soloud.isInitialized) _soloud.deinit();
    }

    throw Exception('SoLoud konnte auf keinem Gerät initialisiert werden');
  }

  bool get isInitialized => _initialized && _soloud.isInitialized;
  PlaybackDevice? get selectedDevice => _selectedDevice;

  List<PlaybackDevice> listDevices() {
    try {
      return _soloud.listPlaybackDevices();
    } catch (_) {
      return [];
    }
  }

  /// Wechselt das Ausgabegerät.
  ///
  /// flutter_soloud v4: Nutzt [SoLoud.changeDevice()] für einen HOT-Wechsel
  /// wenn die Engine bereits initialisiert ist. Das ist der entscheidende
  /// Unterschied zu einem deinit+reinit:
  ///   - Alle geladenen [AudioSource]s bleiben gültig (kein Datenverlust)
  ///   - Alle [SoundHandle]s bleiben gültig (kein Ton-Ausfall)
  ///   - gRPC-Verbindung bleibt unberührt
  ///
  /// Falls changeDevice() scheitert (Gerät nicht gefunden / Android / Web),
  /// fällt es auf den System-Default zurück. Im worst case: deinit+reinit.
  ///
  /// Gibt das tatsächlich aktivierte Gerät zurück, oder `null` für Default.
  Future<PlaybackDevice?> switchDevice(PlaybackDevice device) async {
    if (_soloud.isInitialized) {
      // HOT-Wechsel: Engine bleibt live, Quellen/Handles bleiben gültig.
      try {
        _soloud.changeDevice(newDevice: device);
        _selectedDevice = device;
        debugPrint('[AudioEngine] changeDevice OK: ${device.name}');
        return device;
      } catch (e) {
        debugPrint('[AudioEngine] changeDevice "${device.name}" fehlgeschlagen: $e');
        // Fallback auf System-Default (e.g. Android/Web unterstützt kein changeDevice)
        try {
          _soloud.changeDevice(); // newDevice: null → System-Default
          _selectedDevice = null;
          debugPrint('[AudioEngine] changeDevice → System-Default');
          return null;
        } catch (e2) {
          debugPrint('[AudioEngine] changeDevice Default fehlgeschlagen: $e2 → deinit+reinit');
        }
      }
    }

    // Fallback: deinit + reinit (Engine war nicht initialisiert oder changeDevice
    // hat komplett versagt). Verliert geladene Quellen!
    _initialized = false;
    _selectedDevice = null;
    if (_soloud.isInitialized) _soloud.deinit();
    try {
      await _soloud.init(device: device, bufferSize: _bufferSize);
      if (_soloud.isInitialized) {
        _initialized = true;
        _selectedDevice = device;
        debugPrint('[AudioEngine] switchDevice (reinit) OK: ${device.name}');
        return device;
      }
    } catch (e) {
      debugPrint('[AudioEngine] switchDevice (reinit) fehlgeschlagen: $e');
      if (_soloud.isInitialized) _soloud.deinit();
    }
    try { await _soloud.init(bufferSize: _bufferSize); } catch (_) {}
    _initialized = _soloud.isInitialized;
    _selectedDevice = null;
    return null;
  }

  // ── Preload / Play / Stop ─────────────────────────────────────────────────

  Future<void> preload(String cueId, String filePath) async {
    if (!_initialized) await init();
    if (filePath.isEmpty) return;
    // Bereits dieselbe Datei vorgeladen (z.B. via Arming) → No-Op, damit der
    // Trigger-Pfad ohne Lade-Latenz sofort feuern kann.
    if (_loadedPaths[cueId] == filePath && _sources.containsKey(cueId)) return;

    await _disposeSource(cueId);
    // Bytes in Dart lesen und via loadMem laden. Das umgeht die Pfad- und
    // Encoding-Probleme von miniaudios loadFile auf Windows und ist exakt der
    // Weg, über den die generierten Debug-Töne zuverlässig abspielen.
    try {
      final bytes = await File(filePath).readAsBytes();
      _sources[cueId] = await _soloud.loadMem(filePath, bytes);
      _loadedPaths[cueId] = filePath;
    } catch (e) {
      debugPrint('[AudioEngine] preload FEHLER ($cueId ← $filePath): $e');
      rethrow;
    }
  }

  Future<void> playAt({
    required String cueId,
    required String filePath,
    required int startUnixMillis,
    double volumeDb = 0.0,
    double fadeInMs = 0.0,
    bool loop = false,
  }) async {
    if (!_initialized) await init();

    if (!_sources.containsKey(cueId) && filePath.isNotEmpty) {
      await preload(cueId, filePath);
    }

    final source = _sources[cueId];
    if (source == null) {
      debugPrint('[AudioEngine] playAt: kein Source für $cueId');
      return;
    }

    final volume = _dbToLinear(volumeDb);
    _targetVolumes[cueId] = volume;
    // Neuer Start entwertet eine evtl. noch laufende Pause-Fade-Sequenz.
    _fadeGen[cueId] = (_fadeGen[cueId] ?? 0) + 1;

    // startUnixMillis ist Serverzeit. Über den synchronisierten Offset prüfen,
    // wie viel echter Vorlauf bleibt (s. ClockSync). Sicherheitsnetz: ohne
    // Clock-Sync oder bei starker Drift wäre der Wert unplausibel → sofort starten.
    final lead = startUnixMillis - ClockSync.instance.serverNow();
    final scheduled = lead > 0 && lead <= _maxScheduleAheadMs;
    if (lead > _maxScheduleAheadMs) {
      debugPrint('[AudioEngine] playAt: Vorlauf ${lead}ms unplausibel '
          '(synced=${ClockSync.instance.isSynced}) → sofort abspielen');
    }

    // Re-Trigger derselben Cue: vorherige Instanz hart stoppen, damit sich
    // mehrfaches GO NICHT überlagert (eine Cue-ID = genau eine Voice).
    await _stopHandleNow(cueId);

    try {
      // Pre-Roll: Voice sofort PAUSIERT in den Mixer laden. Der eigentliche Start
      // ist dann nur noch ein leichtgewichtiges Unpause zum exakten Zeitpunkt —
      // das minimiert die Start-Varianz (QLab-artig) und damit den Versatz
      // zwischen mehreren Audio-Geräten.
      // flutter_soloud v4+: play() ist synchron (kein await).
      final handle = _soloud.play(
        source,
        volume: fadeInMs > 0 ? 0.0 : volume,
        looping: loop,
        paused: true,
      );
      _handles[cueId] = handle;

      if (scheduled) {
        await _waitUntilServerMillis(startUnixMillis);
      }
      _soloud.setPause(handle, false);
      debugPrint('[AudioEngine] play OK: $cueId handle=$handle (lead=${lead}ms)');

      if (fadeInMs > 0) {
        // Native, nicht-blockierende Fade-Rampe (statt manueller Step-Schleife).
        _soloud.fadeVolume(handle, volume, Duration(milliseconds: fadeInMs.round()));
      }
    } catch (e) {
      debugPrint('[AudioEngine] play FEHLER ($cueId): $e');
      rethrow;
    }
  }

  Future<void> stop(String cueId, {double fadeOutMs = 0.0}) async {
    final handle = _handles.remove(cueId);
    _targetVolumes.remove(cueId);
    // Laufende Pause-Fade-Sequenz entwerten, damit sie nicht nachträglich pausiert.
    _fadeGen[cueId] = (_fadeGen[cueId] ?? 0) + 1;
    if (handle == null) return;
    if (!_soloud.isInitialized) return;

    // Beim Stoppen sicherstellen, dass eine evtl. pausierte Voice nicht „hängt":
    // erst entpausieren, damit Fade/Stop greifen.
    if (_soloud.getIsValidVoiceHandle(handle) && _soloud.getPause(handle)) {
      _soloud.setPause(handle, false);
    }

    if (fadeOutMs > 0 && _soloud.getIsValidVoiceHandle(handle)) {
      final dur = Duration(milliseconds: fadeOutMs.round());
      _soloud.fadeVolume(handle, 0.0, dur);
      _soloud.scheduleStop(handle, dur);
      // Dart-seitiger Fallback: scheduleStop ist auf einigen Backends (Android)
      // unzuverlässig. Nach Fade-Dauer + Puffer nochmals explizit stoppen.
      Future.delayed(dur + const Duration(milliseconds: 80), () async {
        try {
          if (_soloud.isInitialized && _soloud.getIsValidVoiceHandle(handle)) {
            await _soloud.stop(handle);
          }
        } catch (_) {}
      });
    } else {
      try {
        if (_soloud.getIsValidVoiceHandle(handle)) await _soloud.stop(handle);
      } catch (_) {}
    }
  }

  /// Stoppt ALLE aktiven Cues sofort — unabhängig von der Cue-ID.
  /// Wird für "alles stoppen" genutzt, z. B. bei Notfall-Stop oder wenn
  /// einzelne Handles nicht mehr nachverfolgbar sind (Android-Quirk).
  Future<void> stopAll({double fadeOutMs = 0.0}) async {
    final ids = List<String>.from(_handles.keys);
    for (final id in ids) {
      await stop(id, fadeOutMs: fadeOutMs);
    }
  }

  void _forgetHandle(String cueId) {
    _handles.remove(cueId);
    _targetVolumes.remove(cueId);
  }

  /// Stoppt sofort (ohne Fade) eine evtl. laufende Voice dieser Cue und
  /// entwertet eine laufende Pause-Fade-Sequenz.
  Future<void> _stopHandleNow(String cueId) async {
    _fadeGen[cueId] = (_fadeGen[cueId] ?? 0) + 1;
    final handle = _handles.remove(cueId);
    if (handle == null) return;
    try {
      if (_soloud.isInitialized && _soloud.getIsValidVoiceHandle(handle)) {
        await _soloud.stop(handle);
      }
    } catch (_) {}
  }

  /// Lädt WAV-Bytes direkt (ohne Datei) und spielt ab.
  Future<void> playWavBytes(String cueId, List<int> wavBytes, {double volumeDb = 0.0}) async {
    if (!_initialized) await init();
    await _stopHandleNow(cueId); // Re-Trigger ersetzt vorherige Instanz
    await _disposeSource(cueId);
    try {
      _sources[cueId] = await _soloud.loadMem(cueId, Uint8List.fromList(wavBytes));
      final volume = _dbToLinear(volumeDb);
      _targetVolumes[cueId] = volume;
      // flutter_soloud v4+: play() ist synchron (kein await).
      final handle = _soloud.play(_sources[cueId]!, volume: volume);
      _handles[cueId] = handle;
      debugPrint('[AudioEngine] playWavBytes OK: $cueId');
    } catch (e) {
      debugPrint('[AudioEngine] playWavBytes FEHLER: $e');
      rethrow;
    }
  }

  /// Cue-IDs, die aktuell eine (gültige) Voice haben.
  List<String> get activeCueIds => _handles.keys.toList(growable: false);

  /// Hält die Voice an (Playhead bleibt stehen). Optionaler Fade gegen Knackser.
  /// Idempotent und robust gegen bereits beendete/ungültige Voices.
  Future<void> pause(String cueId, {double fadeOutMs = 0.0}) async {
    final handle = _handles[cueId];
    if (handle == null) return;
    if (!_soloud.getIsValidVoiceHandle(handle)) {
      _forgetHandle(cueId);
      return;
    }
    if (_soloud.getPause(handle)) return; // bereits pausiert → No-Op

    final gen = (_fadeGen[cueId] ?? 0) + 1;
    _fadeGen[cueId] = gen;

    if (fadeOutMs > 0) {
      _soloud.fadeVolume(handle, 0.0, Duration(milliseconds: fadeOutMs.round()));
      await Future.delayed(Duration(milliseconds: fadeOutMs.round()));
      // Inzwischen resume/stop/neuer Play? → diese Pause verwerfen.
      if (_fadeGen[cueId] != gen || _handles[cueId] != handle) return;
      if (!_soloud.getIsValidVoiceHandle(handle)) {
        _forgetHandle(cueId);
        return;
      }
    }
    _soloud.setPause(handle, true);
  }

  /// Setzt eine angehaltene Voice fort. Optionaler Fade gegen Knackser.
  /// Idempotent und robust gegen bereits beendete/ungültige Voices.
  Future<void> resume(String cueId, {double fadeInMs = 0.0}) async {
    final handle = _handles[cueId];
    if (handle == null) return;
    if (!_soloud.getIsValidVoiceHandle(handle)) {
      _forgetHandle(cueId);
      return;
    }
    // Eine evtl. noch laufende Pause-Fade-Sequenz entwerten.
    _fadeGen[cueId] = (_fadeGen[cueId] ?? 0) + 1;

    final target = _targetVolumes[cueId] ?? 1.0;
    _soloud.setPause(handle, false);
    if (fadeInMs > 0) {
      _soloud.setVolume(handle, 0.0);
      _soloud.fadeVolume(handle, target, Duration(milliseconds: fadeInMs.round()));
    } else {
      _soloud.setVolume(handle, target);
    }
  }

  Future<void> _disposeSource(String cueId) async {
    _loadedPaths.remove(cueId);
    final existing = _sources.remove(cueId);
    if (existing != null) {
      try { await _soloud.disposeSource(existing); } catch (_) {}
    }
  }

  Future<void> disposeAll() async {
    for (final handle in _handles.values) {
      try {
        if (_soloud.isInitialized && _soloud.getIsValidVoiceHandle(handle)) {
          await _soloud.stop(handle);
        }
      } catch (_) {}
    }
    _handles.clear();
    for (final source in _sources.values) {
      try { await _soloud.disposeSource(source); } catch (_) {}
    }
    _sources.clear();
    _loadedPaths.clear();
    _targetVolumes.clear();
    _fadeGen.clear();
  }

  Future<void> deinit() async {
    await disposeAll();
    if (_soloud.isInitialized) {
      _soloud.deinit(); // synchron in flutter_soloud v4
    }
    _initialized = false;
    _selectedDevice = null;
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

  double _dbToLinear(double db) {
    if (db <= -60) return 0.0;
    if (db >= 0) return 1.0;
    return math.pow(10.0, db / 20.0).toDouble();
  }

  /// Wartet präzise bis [targetServerMs] (Serverzeit erreicht). Grob via Timer,
  /// die letzten [_spinThresholdMs] werden aktiv gepollt — das eliminiert den
  /// Event-Loop-Jitter, der sonst hörbaren Versatz zwischen Geräten erzeugt.
  Future<void> _waitUntilServerMillis(int targetServerMs) async {
    while (true) {
      final remaining = targetServerMs - ClockSync.instance.serverNow();
      if (remaining <= 0) return;
      if (remaining > _spinThresholdMs) {
        await Future.delayed(Duration(milliseconds: remaining - _spinThresholdMs));
      } else {
        await Future.delayed(Duration.zero); // eng pollen ohne CPU zu blockieren
      }
    }
  }
}
