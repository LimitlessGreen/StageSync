import 'dart:async';
import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_soloud/flutter_soloud.dart';
import 'package:path/path.dart' as p;

import '../../grpc/stage_sync_client.dart';
import '../../grpc/generated/stagesync/v1/common.pb.dart';
import '../../grpc/generated/stagesync/v1/node.pb.dart';
import '../../grpc/generated/stagesync/v1/node.pbgrpc.dart';
import '../../media/media_sync.dart';
import '../../media/server_media_client.dart';
import '../../providers/session_provider.dart';
import 'audio_engine.dart';
import 'media_server.dart';
import 'sweep_generator.dart';

enum AudioNodeState { idle, connected, error }

class AudioNodeStatus {
  final AudioNodeState state;
  final String? errorMessage;
  final List<String> playingCueIds;
  final List<PlaybackDevice> availableDevices;
  final PlaybackDevice? selectedDevice;
  final List<NetworkInterfaceInfo> availableInterfaces;
  final NetworkInterfaceInfo? selectedInterface;

  const AudioNodeStatus({
    this.state = AudioNodeState.idle,
    this.errorMessage,
    this.playingCueIds = const [],
    this.availableDevices = const [],
    this.selectedDevice,
    this.availableInterfaces = const [],
    this.selectedInterface,
  });

  AudioNodeStatus copyWith({
    AudioNodeState? state,
    String? errorMessage,
    List<String>? playingCueIds,
    List<PlaybackDevice>? availableDevices,
    PlaybackDevice? selectedDevice,
    List<NetworkInterfaceInfo>? availableInterfaces,
    NetworkInterfaceInfo? selectedInterface,
  }) =>
      AudioNodeStatus(
        state: state ?? this.state,
        errorMessage: errorMessage,
        playingCueIds: playingCueIds ?? this.playingCueIds,
        availableDevices: availableDevices ?? this.availableDevices,
        selectedDevice: selectedDevice ?? this.selectedDevice,
        availableInterfaces: availableInterfaces ?? this.availableInterfaces,
        selectedInterface: selectedInterface ?? this.selectedInterface,
      );
}

/// AudioNodeService registriert dieses Gerät als AUDIO-Node und empfängt
/// Commands vom Server. Wird nur auf Geräten aktiv, die als AudioNode joinen.
class AudioNodeService {
  final AudioEngine _engine;
  final MediaServer _mediaServer;
  final Ref _ref;

  /// Spiegelt die komplette Audio-Datenbank des Servers lokal (best practice:
  /// Medien liegen autoritativ auf dem Server, Nodes ziehen sie sich).
  MediaSync? _mediaSync;

  StreamSubscription<void>? _commandSub;
  final _statusController = StreamController<AudioNodeStatus>.broadcast();

  AudioNodeStatus _status = const AudioNodeStatus();

  // Letzten empfangenen Commands für Diagnose
  final List<String> _cmdLog = [];
  List<String> get cmdLog => List.unmodifiable(_cmdLog);
  void _logCmd(String msg) {
    _cmdLog.insert(0, '[${DateTime.now().toIso8601String().substring(11, 23)}] $msg');
    if (_cmdLog.length > 10) _cmdLog.removeLast();
  }

  AudioNodeService._internal(this._ref, this._engine, this._mediaServer);

  factory AudioNodeService(Ref ref) {
    final engine = AudioEngine();
    return AudioNodeService._internal(ref, engine, MediaServer(engine));
  }

  Stream<AudioNodeStatus> get statusStream => _statusController.stream;
  AudioNodeStatus get status => _status;
  String? get mediaServerUrl => _mediaServer.serverUrl;

  /// Startet den Audio-Node: Engine init, MediaServer, dann Server-Verbindung.
  Future<void> start() async {
    final session = _ref.read(sessionProvider);
    if (!session.isInSession) return;

    try {
      // Engine nur initialisieren wenn nötig (deinit vermeiden auf Windows)
      if (!_engine.isInitialized) {
        await _engine.init(device: _status.selectedDevice);
      }

      // Verfügbare Geräte und Netzwerk-Interfaces lesen
      final devices = _engine.listDevices();
      final interfaces = await MediaServer.listInterfaces();
      final selectedIface = _status.selectedInterface ??
          (interfaces.isNotEmpty ? interfaces.first : null);

      if (selectedIface == null) {
        throw Exception('Kein Netzwerk-Interface verfügbar');
      }

      await _mediaServer.start(bindIp: selectedIface.address);

      final client = StageSyncClient.instance;

      final audioDevices = devices.asMap().entries.map((e) {
        return AudioDeviceInfo()
          ..index = e.value.id
          ..name = e.value.name
          ..isDefault = e.key == 0;
      }).toList();

      final caps = NodeCapabilities()
        ..audio = (AudioCapabilities()
          ..maxSimultaneous = 8
          ..supportedFormats.addAll(['wav', 'mp3', 'flac', 'aac', 'ogg', 'm4a', 'aiff'])
          ..mediaServerUrl = _mediaServer.serverUrl ?? ''
          ..availableDevices.addAll(audioDevices)
          ..selectedDevice = _status.selectedDevice?.id ?? 0);

      final registerReq = RegisterNodeRequest()
        ..sessionId = session.session!.sessionId
        ..token = session.token!
        ..node = (NodeInfo()
          ..nodeId = session.myNode!.nodeId
          ..name = session.myNode!.name
          ..nodeType = NodeType.NODE_TYPE_AUDIO
          ..tasks.addAll(session.myNode!.tasks)
          ..online = true
          ..mediaServerUrl = _mediaServer.serverUrl ?? '')  // URL direkt in NodeInfo
        ..capabilities = caps;

      await client.node.registerNode(registerReq);

      // Direkt nach RegisterNode die URL im lokalen Session-State setzen,
      // ohne auf das Broadcast-Event zu warten (Race Condition vermeiden).
      final mediaUrl = _mediaServer.serverUrl ?? '';
      if (mediaUrl.isNotEmpty) {
        _ref.read(sessionProvider.notifier).updateMyNodeMediaUrl(mediaUrl);
      }

      final streamReq = StreamNodeCommandsRequest()
        ..sessionId = session.session!.sessionId
        ..nodeId = session.myNode!.nodeId
        ..token = session.token!;

      final commandStream = client.node.streamNodeCommands(streamReq);

      // asyncMap serialisiert Commands: jeder Command (v.a. Preload) ist vollständig
      // abgeschlossen, bevor der nächste verarbeitet wird. Verhindert Race-Condition
      // zwischen Preload und Play.
      // ABER: Stop/Pause werden sofort ausgeführt (via _stopImmediate), ohne in der
      // Warteschlange zu warten — das löst das "kann nicht stoppen" Problem auf Android.
      _commandSub = commandStream.listen(
        _handleCommandRaw,
        onError: _handleStreamError,
        onDone: _handleStreamDone,
      );

      // _engine.selectedDevice ist die Source of Truth: null bedeutet
      // System-Default (z. B. Fallback auf Windows). Das ist ehrlicher als
      // devices.first anzuzeigen, das nicht zwingend dem SoLoud-Default
      // entspricht.
      _updateStatus(AudioNodeStatus(
        state: AudioNodeState.connected,
        availableDevices: devices,
        selectedDevice: _engine.selectedDevice,
        availableInterfaces: interfaces,
        selectedInterface: selectedIface,
      ));

      // Komplette Audio-Datenbank vom Server spiegeln (im Hintergrund, damit
      // der Join nicht blockiert). Lazy-Fetch im Preload deckt Lücken ab.
      await _startMediaSync();
    } catch (e) {
      _updateStatus(AudioNodeStatus(
        state: AudioNodeState.error,
        errorMessage: e.toString(),
      ));
    }
  }

  /// Richtet den Medien-Spiegel ein und startet ihn im Hintergrund.
  Future<void> _startMediaSync() async {
    await _mediaSync?.stop();
    final client = ServerMediaClient.fromConnection();
    if (client == null) {
      _logCmd('MEDIA-SYNC: Server-Host unbekannt → übersprungen');
      return;
    }
    final dir = _mediaServer.cachedMediaDir ?? await mediaCacheDir();
    final sync = MediaSync(client, dir);
    _mediaSync = sync;
    // Nicht awaiten: Voll-Sync läuft im Hintergrund; Preloads nutzen Lazy-Fetch.
    sync.start().then((_) => _logCmd('MEDIA-SYNC: Voll-Sync abgeschlossen'))
        .catchError((Object e) => _logCmd('MEDIA-SYNC FEHLER: $e'));
  }

  /// Wechselt das Ausgabegerät via [AudioEngine.switchDevice()].
  ///
  /// Kernfix: verwendet [SoLoud.changeDevice()] (flutter_soloud v4+) für einen
  /// HOT-Wechsel ohne deinit+reinit. Dadurch:
  ///   - Alle geladenen AudioSources bleiben gültig → kein erneutes PRELOAD nötig
  ///   - Die gRPC-Verbindung bleibt unberührt → kein Ton-Ausfall nach Wechsel
  ///   - Auf Android/Web (kein changeDevice) fällt es still auf System-Default zurück
  Future<void> switchDevice(PlaybackDevice device) async {
    // Wunsch-Gerät vormerken für UI-Feedback
    _updateStatus(_status.copyWith(selectedDevice: device));
    // HOT-Wechsel via changeDevice() – kein Stop, kein Restart
    final actual = await _engine.switchDevice(device);
    _updateStatus(_status.copyWith(
      // actual == null → Fallback auf Default, zeige trotzdem Wunsch-Gerät
      // damit der User sieht was er gewählt hat (auch wenn es Default ist)
      selectedDevice: actual,
      availableDevices: _engine.listDevices(),
    ));
  }

  /// Setzt auf Default-Gerät zurück und re-initialisiert SoLoud.
  /// Zuverlässiger als ein spezifisches Gerät — besonders auf Windows.
  /// Stellt sicher dass die Engine initialisiert ist — ohne deinit.
  /// Schneller Warm-Up für Audio-Ingenieur-Screen.
  Future<void> ensureEngineInitialized() async {
    if (!_engine.isInitialized) {
      await _engine.init(device: _status.selectedDevice);
    }
    // Geräteliste im Status befüllen, damit die UI Geräte zeigen kann
    // – auch wenn der Node noch nicht als Audio-Node verbunden ist.
    if (_status.availableDevices.isEmpty) {
      final devices = _engine.listDevices();
      if (devices.isNotEmpty) {
        _updateStatus(_status.copyWith(
          availableDevices: devices,
        ));
      }
    }
  }

  Future<void> resetToDefaultDevice() async {
    _updateStatus(_status.copyWith(selectedDevice: null));
    // Engine komplett neu initialisieren ohne Gerät — zuverlässigste Methode auf Windows
    await _engine.deinit();
    await Future.delayed(const Duration(milliseconds: 100));
    await _engine.init(); // kein Gerät = System-Default
  }

  /// Wechselt das Netzwerk-Interface und startet den Node neu.
  Future<void> switchInterface(NetworkInterfaceInfo iface) async {
    final wasConnected = _status.state == AudioNodeState.connected;
    _updateStatus(_status.copyWith(selectedInterface: iface));
    if (wasConnected) {
      await stop();
      await start();
    }
  }

  /// Stoppt den Audio-Node.
  /// Engine bleibt initialisiert — auf Windows ist deinit+reinit unzuverlässig.
  Future<void> stop() async {
    await _commandSub?.cancel();
    _commandSub = null;
    await _mediaSync?.stop();
    _mediaSync = null;
    await _mediaServer.stop();
    await _engine.disposeAll(); // Quellen freigeben, aber SoLoud-Instanz behalten
    _updateStatus(AudioNodeStatus(
      state: AudioNodeState.idle,
      availableDevices: _status.availableDevices,
      selectedDevice: _status.selectedDevice,
      availableInterfaces: _status.availableInterfaces,
      selectedInterface: _status.selectedInterface,
    ));
  }

  // ── Pfad-Auflösung ────────────────────────────────────────────────────────

  /// Löst einen Dateinamen oder Pfad auf den vollständigen lokalen Pfad auf.
  String _resolveFilePath(String filePathOrName) {
    if (filePathOrName.isEmpty) return '';
    if (File(filePathOrName).existsSync()) return filePathOrName;

    // Nur Dateiname → im MediaServer-Verzeichnis suchen
    final dir = _mediaServer.cachedMediaDir;
    if (dir != null) {
      final resolved = p.join(dir, p.basename(filePathOrName));
      return resolved;
    }
    return filePathOrName;
  }

  // ── Command-Handler ────────────────────────────────────────────────────────

  // Sequentielle Queue für langlaufende Commands (Preload, Play, Test).
  // Verhindert Race-Condition zwischen Preload und Play.
  Future<void> _pendingCommand = Future.value();

  /// Eintrittspunkt für alle eingehenden Commands.
  /// Stop/Pause/Resume: SOFORT ausführen (nicht in Queue einreihen!).
  /// Preload/Play/Test: in der sequenziellen Queue abarbeiten.
  void _handleCommandRaw(NodeCommandRequest cmd) {
    final which = cmd.whichCommand();

    // Prioritäts-Commands: sofort und parallel zur laufenden Queue ausführen.
    // Dadurch kann Stop einen laufenden (langsamen) Preload nicht blockieren.
    if (which == NodeCommandRequest_Command.audioStop ||
        which == NodeCommandRequest_Command.audioPause ||
        which == NodeCommandRequest_Command.audioResume) {
      _handleCommandAsync(cmd).catchError((Object e) {
        _logCmd('PRIO-CMD FEHLER: $e');
      });
      return;
    }

    // Normale Commands: sequenziell in Queue – Race-Schutz für Preload→Play.
    _pendingCommand = _pendingCommand
        .then((_) => _handleCommandAsync(cmd))
        .catchError((Object e) { _logCmd('CMD FEHLER: $e'); });
  }

  Future<void> _handleCommandAsync(NodeCommandRequest cmd) async {
    switch (cmd.whichCommand()) {
      case NodeCommandRequest_Command.audioPreload:
        await _handlePreload(cmd.audioPreload);
      case NodeCommandRequest_Command.audioPlay:
        await _handlePlay(cmd.audioPlay);
      case NodeCommandRequest_Command.audioStop:
        await _handleStop(cmd.audioStop);
      case NodeCommandRequest_Command.audioPause:
        await _handlePause(cmd.audioPause);
      case NodeCommandRequest_Command.audioResume:
        await _handleResume(cmd.audioResume);
      case NodeCommandRequest_Command.audioTest:
        await _handleTestSignal(cmd.audioTest);
      case NodeCommandRequest_Command.maOsc:
        break;
      case NodeCommandRequest_Command.notSet:
        break;
    }
  }

  Future<void> _handlePreload(AudioPreloadCommand cmd) async {
    final path = await _resolveMediaPath(cmd.filePath);
    if (path == null) {
      _logCmd('PRELOAD FEHLER: Datei nicht beschaffbar: "${cmd.filePath}"');
      return;
    }
    try {
      await _engine.preload(cmd.cueId, path);
      _logCmd('PRELOAD OK: ${cmd.cueId}');
    } catch (e) {
      _logCmd('PRELOAD FEHLER: $e');
    }
  }

  /// Liefert den lokalen Pfad einer Mediendatei und lädt sie bei Bedarf vom
  /// Server nach (Lazy-Fetch). Fallback auf lokale Auflösung ohne Sync.
  Future<String?> _resolveMediaPath(String filePathOrName) async {
    final sync = _mediaSync;
    if (sync != null) {
      return sync.ensureLocal(filePathOrName);
    }
    final path = _resolveFilePath(filePathOrName);
    if (path.isEmpty || !File(path).existsSync()) return null;
    return path;
  }

  Future<void> _handlePlay(AudioPlayCommand cmd) async {
    _logCmd('PLAY: ${cmd.cueId} vol=${cmd.volumeDb}dB');
    final playing = List<String>.from(_status.playingCueIds)..add(cmd.cueId);
    _updateStatus(_status.copyWith(playingCueIds: playing));
    try {
      await _engine.playAt(
        cueId: cmd.cueId,
        filePath: '',
        startUnixMillis: cmd.startUnixMillis.toInt(),
        volumeDb: cmd.volumeDb,
        fadeInMs: cmd.fadeInMs,
      );
      _logCmd('PLAY OK: ${cmd.cueId}');
    } catch (e) {
      _logCmd('PLAY FEHLER: $e');
    } finally {
      final done = List<String>.from(_status.playingCueIds)..remove(cmd.cueId);
      _updateStatus(_status.copyWith(playingCueIds: done));
    }
  }

  Future<void> _handleStop(AudioStopCommand cmd) async {
    // Leere cueId → alle aktiven Cues stoppen (Notfall-Stop / Android-Fallback)
    if (cmd.cueId.isEmpty) {
      _logCmd('STOP ALL');
      try {
        await _engine.stopAll(fadeOutMs: cmd.fadeOutMs);
      } catch (e) {
        _logCmd('STOP ALL FEHLER: $e');
      }
      _updateStatus(_status.copyWith(playingCueIds: []));
      return;
    }
    _logCmd('STOP: ${cmd.cueId}');
    try {
      await _engine.stop(cmd.cueId, fadeOutMs: cmd.fadeOutMs);
    } catch (e) {
      _logCmd('STOP FEHLER: $e');
    }
    final playing = List<String>.from(_status.playingCueIds)..remove(cmd.cueId);
    _updateStatus(_status.copyWith(playingCueIds: playing));
  }

  /// Generiert ein Testsignal (Ton/Sweep) LOKAL und spielt es ab — es wird
  /// kein Audio über das Netz übertragen, nur die Anweisung.
  Future<void> _handleTestSignal(AudioTestSignalCommand cmd) async {
    _logCmd('TEST: ${cmd.kind.name} ${cmd.cueId}');
    try {
      final amp = cmd.amplitude > 0 ? cmd.amplitude : 0.8;
      final durSec = (cmd.durationMs > 0 ? cmd.durationMs : 1000) / 1000.0;
      final List<int> wav;
      if (cmd.kind == AudioTestSignalCommand_Kind.KIND_SWEEP) {
        wav = SweepGenerator.generateSweep(
          startHz: cmd.startHz > 0 ? cmd.startHz : 20,
          endHz: cmd.endHz > 0 ? cmd.endHz : 20000,
          durationSeconds: durSec,
          amplitude: amp,
        );
      } else {
        wav = SweepGenerator.generateTone(
          frequencyHz: cmd.frequencyHz > 0 ? cmd.frequencyHz : 1000,
          durationSeconds: durSec,
          amplitude: amp,
        );
      }
      await _engine.playWavBytes(cmd.cueId, wav);
    } catch (e) {
      _logCmd('TEST FEHLER: $e');
    }
  }

  Future<void> _handlePause(AudioPauseCommand cmd) async {
    final targets = _resolveCueTargets(cmd.cueId);
    _logCmd('PAUSE: ${cmd.cueId.isEmpty ? "(alle)" : cmd.cueId}');
    for (final id in targets) {
      try {
        await _engine.pause(id, fadeOutMs: cmd.fadeOutMs);
      } catch (e) {
        _logCmd('PAUSE FEHLER ($id): $e');
      }
    }
  }

  Future<void> _handleResume(AudioResumeCommand cmd) async {
    final targets = _resolveCueTargets(cmd.cueId);
    _logCmd('RESUME: ${cmd.cueId.isEmpty ? "(alle)" : cmd.cueId}');
    for (final id in targets) {
      try {
        await _engine.resume(id, fadeInMs: cmd.fadeInMs);
      } catch (e) {
        _logCmd('RESUME FEHLER ($id): $e');
      }
    }
  }

  /// Leere cueId → alle aktiven Cues, sonst die eine.
  List<String> _resolveCueTargets(String cueId) =>
      cueId.isEmpty ? _engine.activeCueIds : [cueId];

  void _handleStreamError(Object error) {
    _updateStatus(AudioNodeStatus(
      state: AudioNodeState.error,
      errorMessage: error.toString(),
      availableDevices: _status.availableDevices,
      selectedDevice: _status.selectedDevice,
    ));
  }

  void _handleStreamDone() {
    _updateStatus(AudioNodeStatus(
      state: AudioNodeState.idle,
      availableDevices: _status.availableDevices,
      selectedDevice: _status.selectedDevice,
    ));
  }

  void _updateStatus(AudioNodeStatus s) {
    _status = s;
    _statusController.add(s);
  }

  /// Spielt WAV-Bytes direkt auf diesem Gerät ab (für Audio-Ingenieur).
  /// Funktioniert auch wenn der Node nicht als Audio-Node verbunden ist.
  Future<void> playWavBytesLocally(String cueId, List<int> wavBytes) async {
    if (!_engine.isInitialized) {
      await _engine.init(device: _status.selectedDevice);
    }
    await _engine.playWavBytes(cueId, wavBytes);
  }

  Future<void> stopLocalPlayback(String cueId) async {
    await _engine.stop(cueId, fadeOutMs: 200);
  }

  /// Stoppt ALLE lokal spielenden Sounds — zuverlässiger als stopLocalPlayback,
  /// da keine cueId-Kenntnis benötigt wird. Wichtig für Android-Fallback.
  Future<void> stopAllLocalPlayback() async {
    await _engine.stopAll(fadeOutMs: 200);
  }

  void dispose() {
    _commandSub?.cancel();
    _engine.deinit();
    _statusController.close();
  }
}
