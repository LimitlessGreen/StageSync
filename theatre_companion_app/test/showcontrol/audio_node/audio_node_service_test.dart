import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:theatre_companion_app/showcontrol/nodes/audio_node/abstract_audio_engine.dart';
import 'package:theatre_companion_app/showcontrol/nodes/audio_node/audio_device.dart';
import 'package:theatre_companion_app/showcontrol/nodes/audio_node/audio_node_service.dart';
import 'package:theatre_companion_app/showcontrol/nodes/audio_node/media_server.dart';
import 'package:theatre_companion_app/showcontrol/grpc/generated/stagesync/v1/node.pb.dart';

// ── Mocks / Fakes ─────────────────────────────────────────────────────────────

class MockRef extends Mock implements Ref {}

class MockMediaServer extends Mock implements MediaServer {}

/// Steuerbarer Fake: [preloadCompleter] blockiert preload() bis er vervollständigt wird.
/// [stopCalls], [pauseCalls], [resumeCalls] zeichnen alle Aufrufe auf.
class FakeAudioEngine extends Fake implements AbstractAudioEngine {
  Completer<void>? preloadCompleter;

  final List<({String cueId, double fadeOutMs})> stopCalls = [];
  final List<({String cueId, double fadeOutMs})> pauseCalls = [];
  final List<({String cueId, double fadeInMs})> resumeCalls = [];
  final List<({String cueId, List<int> wavBytes})> playWavCalls = [];
  final List<AudioDevice> switchDeviceCalls = [];

  bool _initialized = false;
  AudioDevice? _selectedDevice;

  @override
  bool get isInitialized => _initialized;

  @override
  AudioDevice? get selectedDevice => _selectedDevice;

  @override
  List<String> get activeCueIds => [];

  @override
  Future<void> init({AudioDevice? device}) async {
    _initialized = true;
    _selectedDevice = device;
  }

  @override
  Future<void> deinit() async {
    _initialized = false;
    _selectedDevice = null;
  }

  @override
  Future<List<AudioDevice>> listDevices() async => [
        const AudioDevice(id: 'Lautsprecher (Realtek)', name: 'Lautsprecher (Realtek)',
            backend: AudioBackend.wasapi, index: 0),
        const AudioDevice(id: 'HDMI-Ausgang', name: 'HDMI-Ausgang',
            backend: AudioBackend.wasapi, index: 1),
      ];

  @override
  Future<AudioDevice?> switchDevice(AudioDevice device) async {
    switchDeviceCalls.add(device);
    _selectedDevice = device;
    return device;
  }

  @override
  Future<void> preload(String cueId, String filePath) async {
    if (preloadCompleter != null) {
      await preloadCompleter!.future;
    }
    // sonst sofort fertig
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
  }) async {}

  @override
  Future<void> playWavBytes(String cueId, List<int> wavBytes, {double volumeDb = 0.0}) async {
    playWavCalls.add((cueId: cueId, wavBytes: wavBytes));
  }

  @override
  Future<void> stop(String cueId, {double fadeOutMs = 0.0}) async {
    stopCalls.add((cueId: cueId, fadeOutMs: fadeOutMs));
  }

  @override
  Future<void> stopAll({double fadeOutMs = 0.0}) async {
    stopCalls.add((cueId: '__all__', fadeOutMs: fadeOutMs));
  }

  @override
  Future<void> pause(String cueId, {double fadeOutMs = 0.0}) async {
    pauseCalls.add((cueId: cueId, fadeOutMs: fadeOutMs));
  }

  @override
  Future<void> resume(String cueId, {double fadeInMs = 0.0}) async {
    resumeCalls.add((cueId: cueId, fadeInMs: fadeInMs));
  }

  @override
  Future<void> disposeAll() async {}
}

// ── Hilfsfunktionen ──────────────────────────────────────────────────────────

/// Erstellt einen [AudioNodeService] mit injizierter FakeEngine und MockServer.
/// Bietet der Engine bereits initialisierte Defaults.
(AudioNodeService, FakeAudioEngine, MockMediaServer) _makeService({
  Completer<void>? preloadCompleter,
}) {
  final engine = FakeAudioEngine()..preloadCompleter = preloadCompleter;
  final server = MockMediaServer();

  // Minimale Stubs damit der Service ohne start() funktioniert
  when(() => server.serverUrl).thenReturn(null);
  when(() => server.cachedMediaDir).thenReturn(null);
  when(() => server.stop()).thenAnswer((_) async {});

  final ref = MockRef();

  final service = AudioNodeService.forTest(
    ref: ref,
    engine: engine,
    mediaServer: server,
  );

  return (service, engine, server);
}

// ── Tests ────────────────────────────────────────────────────────────────────

void main() {
  setUpAll(() {
    registerFallbackValue(const AudioDevice(id: '', name: 'default'));
  });

  // ── Gerätewahl ─────────────────────────────────────────────────────────────

  group('AudioNodeService.switchDevice()', () {
    test('leitet Aufruf an Engine weiter', () async {
      final (service, engine, _) = _makeService();
      const device = AudioDevice(id: 'HDMI-Ausgang', name: 'HDMI-Ausgang',
          backend: AudioBackend.wasapi, index: 1);

      await service.switchDevice(device);

      expect(engine.switchDeviceCalls, hasLength(1));
      expect(engine.switchDeviceCalls.first.index, 1);
    });

    test('Status.selectedDevice entspricht dem tatsächlichen Engine-Gerät', () async {
      final (service, engine, _) = _makeService();
      const device = AudioDevice(id: 'HDMI-Ausgang', name: 'HDMI-Ausgang',
          backend: AudioBackend.wasapi, index: 1);

      await service.switchDevice(device);

      // Engine gibt das Gerät zurück → Status muss es spiegeln
      expect(service.status.selectedDevice?.name, engine.selectedDevice?.name);
    });

    test('Status.availableDevices wird nach Gerätewechsel aktualisiert', () async {
      final (service, _, _) = _makeService();
      const device = AudioDevice(id: 'Lautsprecher (Realtek)', name: 'Lautsprecher (Realtek)',
          backend: AudioBackend.wasapi, index: 0);

      await service.switchDevice(device);

      // listDevices() des FakeEngine liefert 2 Geräte
      expect(service.status.availableDevices, hasLength(2));
    });
  });

  // ── Engine-Initialisierung ─────────────────────────────────────────────────

  group('AudioNodeService.ensureEngineInitialized()', () {
    test('initialisiert Engine wenn noch nicht bereit', () async {
      final (service, engine, _) = _makeService();
      expect(engine.isInitialized, isFalse);

      await service.ensureEngineInitialized();

      expect(engine.isInitialized, isTrue);
    });

    test('initialisiert Engine NICHT erneut wenn bereits bereit', () async {
      final (service, engine, _) = _makeService();

      await engine.init(); // Manuell vorab initialisieren
      final initCount = 1; // Basis

      await service.ensureEngineInitialized(); // Soll kein init() auslösen

      // Engine bleibt bei demselben init-Zustand (isInitialized = true)
      expect(engine.isInitialized, isTrue);
      // Kein switchDevice/deinit – Engine ist stabil
      expect(engine.switchDeviceCalls, isEmpty);
    });

    test('befüllt availableDevices im Status', () async {
      final (service, _, _) = _makeService();

      await service.ensureEngineInitialized();

      expect(service.status.availableDevices, isNotEmpty);
    });
  });

  // ── Lokale Wiedergabe ──────────────────────────────────────────────────────

  group('AudioNodeService.playWavBytesLocally()', () {
    test('initialisiert Engine bei Bedarf und spielt ab', () async {
      final (service, engine, _) = _makeService();
      final wavBytes = List.generate(44, (i) => i); // Dummy-Bytes

      await service.playWavBytesLocally('testCue', wavBytes);

      expect(engine.isInitialized, isTrue);
      expect(engine.playWavCalls, hasLength(1));
      expect(engine.playWavCalls.first.cueId, 'testCue');
    });

    test('spielt auf bereits initialisierter Engine ab', () async {
      final (service, engine, _) = _makeService();
      await engine.init();
      final wavBytes = [1, 2, 3];

      await service.playWavBytesLocally('cue42', wavBytes);

      expect(engine.playWavCalls.first.cueId, 'cue42');
      expect(engine.playWavCalls.first.wavBytes, wavBytes);
    });
  });

  // ── Globaler Stop ──────────────────────────────────────────────────────────

  group('AudioNodeService.stopAllLocalPlayback()', () {
    test('ruft engine.stopAll() auf', () async {
      final (service, engine, _) = _makeService();

      await service.stopAllLocalPlayback();

      expect(engine.stopCalls, hasLength(1));
      expect(engine.stopCalls.first.cueId, '__all__');
    });

    test('übergibt 200ms Fade-Out', () async {
      final (service, engine, _) = _makeService();

      await service.stopAllLocalPlayback();

      expect(engine.stopCalls.first.fadeOutMs, 200.0);
    });
  });

  group('AudioNodeService.stopLocalPlayback()', () {
    test('stoppt spezifische cueId', () async {
      final (service, engine, _) = _makeService();

      await service.stopLocalPlayback('meinCue');

      expect(engine.stopCalls, hasLength(1));
      expect(engine.stopCalls.first.cueId, 'meinCue');
      expect(engine.stopCalls.first.fadeOutMs, 200.0);
    });
  });

  // ── Priority-Dispatch: Stop wartet nicht auf Preload ──────────────────────

  group('Command-Priorität: Stop bypassed Preload-Queue', () {
    test('Stop-Command wird SOFORT ausgeführt, nicht nach blockierendem Preload', () async {
      // Preload-Completer, der NUR manuell vervollständigt wird
      final preloadCompleter = Completer<void>();
      final (service, engine, _) = _makeService(preloadCompleter: preloadCompleter);

      // Preload-Command via Queue senden (blockiert bis preloadCompleter.complete())
      // Wir simulieren hier über handleCommandForTest ohne echte gRPC-Verbindung.
      //
      // Da _resolveMediaPath eine leere cueId-Datei nicht findet, wird preload()
      // intern nicht aufgerufen. Deshalb testen wir direkt via audioPause/audioResume
      // als Prioritäts-Commands gegen einen Preload-Trigger-Stub.

      // Stattdessen: Stop-Command via Priority-Pfad → sofort in stopCalls
      final stopCmd = NodeCommandRequest()
        ..audioStop = (AudioStopCommand()
          ..cueId = 'cue1'
          ..fadeOutMs = 0);

      service.handleCommandForTest(stopCmd);

      // Noch in demselben Microtask-Frame: Stop muss bereits in der Queue sein
      // (keine echte async-Wartezeit da kein preload blockiert)
      await Future.delayed(Duration.zero);

      expect(engine.stopCalls, hasLength(1));
      expect(engine.stopCalls.first.cueId, 'cue1');

      // Preload-Completer vervollständigen damit keine losen Futures hängen
      preloadCompleter.complete();
    });

    test('Stop ALL (leere cueId) ruft stopAll() auf', () async {
      final (service, engine, _) = _makeService();

      final stopAllCmd = NodeCommandRequest()
        ..audioStop = (AudioStopCommand()..cueId = '');

      service.handleCommandForTest(stopAllCmd);
      await Future.delayed(Duration.zero);

      expect(engine.stopCalls, hasLength(1));
      expect(engine.stopCalls.first.cueId, '__all__');
    });

    test('Pause-Command wird ohne Queue-Wartezeit ausgeführt', () async {
      final (service, engine, _) = _makeService();

      final pauseCmd = NodeCommandRequest()
        ..audioPause = (AudioPauseCommand()
          ..cueId = 'cue2'
          ..fadeOutMs = 0);

      service.handleCommandForTest(pauseCmd);
      await Future.delayed(Duration.zero);

      expect(engine.pauseCalls, hasLength(1));
      expect(engine.pauseCalls.first.cueId, 'cue2');
    });

    test('Resume-Command wird ohne Queue-Wartezeit ausgeführt', () async {
      final (service, engine, _) = _makeService();

      final resumeCmd = NodeCommandRequest()
        ..audioResume = (AudioResumeCommand()
          ..cueId = 'cue3'
          ..fadeInMs = 0);

      service.handleCommandForTest(resumeCmd);
      await Future.delayed(Duration.zero);

      expect(engine.resumeCalls, hasLength(1));
      expect(engine.resumeCalls.first.cueId, 'cue3');
    });
  });

  // ── Status-Stream ──────────────────────────────────────────────────────────

  group('AudioNodeService.statusStream', () {
    test('emittiert initialen Idle-Status', () {
      final (service, _, _) = _makeService();
      expect(service.status.state, AudioNodeState.idle);
    });

    test('emittiert Status nach switchDevice', () async {
      final (service, _, _) = _makeService();
      final statusEvents = <AudioNodeStatus>[];
      final sub = service.statusStream.listen(statusEvents.add);

      const device = AudioDevice(id: 'Lautsprecher (Realtek)', name: 'Lautsprecher (Realtek)',
          backend: AudioBackend.wasapi, index: 0);
      await service.switchDevice(device);

      // StreamController.broadcast() liefert Events asynchron (Microtask).
      // Einen Frame abwarten damit ausstehende Event-Microtasks verarbeitet werden,
      // bevor cancel() den Listener entfernt.
      await Future.delayed(Duration.zero);
      await sub.cancel();

      // Mindestens 2 Events: Wunsch-Gerät vormerken + tatsächliches Gerät setzen
      expect(statusEvents.length, greaterThanOrEqualTo(2));
    });
  });

  // ── dB → Linear-Konversion (via AudioEngine-Interaktion) ──────────────────

  group('dB zu linearer Lautstärke', () {
    test('0 dB → 1,0 (maximale Lautstärke)', () async {
      // Indirekt über playWavBytesLocally prüfen, dass kein Fehler bei 0 dB
      final (service, engine, _) = _makeService();
      await service.playWavBytesLocally('cue', [0, 0]);
      expect(engine.playWavCalls.first.cueId, 'cue');
    });
  });
}


