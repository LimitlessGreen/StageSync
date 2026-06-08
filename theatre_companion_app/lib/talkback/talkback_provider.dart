import 'dart:async';
import 'dart:typed_data';

import 'package:fixnum/fixnum.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../showcontrol/grpc/stage_sync_client.dart';
import '../showcontrol/grpc/generated/stagesync/v1/talkback.pb.dart'
    as tb_proto;
import 'mic_capture.dart';
import 'opus_encoder.dart';

// ── State ─────────────────────────────────────────────────────────────────────

enum TalkbackStatus { idle, requesting, active, error }

/// Live = sofort übertragen; Delayed = aufnehmen, beim Loslassen abspielen.
enum TalkbackMode { live, delayed }

class TalkbackState {
  final TalkbackStatus status;
  final List<tb_proto.ActiveTalker> activeTalkers;
  final String? errorMessage;
  final List<String> targetBusIds;
  final TalkbackMode mode;

  /// Eigene Client-ID — wird in der UI herausgefiltert damit man sich nicht
  /// selbst als aktiven Sprecher sieht.
  final String? ownClientId;

  const TalkbackState({
    this.status = TalkbackStatus.idle,
    this.activeTalkers = const <tb_proto.ActiveTalker>[],
    this.errorMessage,
    this.targetBusIds = const [],
    this.mode = TalkbackMode.live,
    this.ownClientId,
  });

  TalkbackState copyWith({
    TalkbackStatus? status,
    List<tb_proto.ActiveTalker>? activeTalkers,
    String? errorMessage,
    List<String>? targetBusIds,
    TalkbackMode? mode,
    String? ownClientId,
  }) =>
      TalkbackState(
        status: status ?? this.status,
        activeTalkers: activeTalkers ?? this.activeTalkers,
        errorMessage: errorMessage,
        targetBusIds: targetBusIds ?? this.targetBusIds,
        mode: mode ?? this.mode,
        ownClientId: ownClientId ?? this.ownClientId,
      );
}

// ── Provider ──────────────────────────────────────────────────────────────────

final talkbackProvider = AsyncNotifierProvider<TalkbackNotifier, TalkbackState>(
    TalkbackNotifier.new);

class TalkbackNotifier extends AsyncNotifier<TalkbackState> {
  StreamController<tb_proto.TalkbackFrame>? _outgoing;
  StreamSubscription<tb_proto.TalkbackStatus>? _statusSub;
  int _sequence = 0;

  // Delayed-Modus: aufgenommene PCM-Frames zwischenspeichern
  final List<Int16List> _recordedFrames = [];

  // Gecachte Credentials — einmalig beim Start geladen, danach sofort verfügbar.
  String? _cachedClientId;
  String? _cachedDisplayName;
  bool _permissionGranted = false;

  @override
  FutureOr<TalkbackState> build() {
    // Vorbereitung im Hintergrund: Prefs, Opus, Permission — nicht abwarten.
    _preInit();
    return const TalkbackState();
  }

  /// Lädt Prefs, initialisiert Opus und prüft Mikrofon-Permission vorab.
  /// Läuft im Hintergrund; startTalking() verwendet gecachte Werte.
  Future<void> _preInit() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _cachedClientId = prefs.getString('device_id');
      _cachedDisplayName = prefs.getString('display_name');
    } catch (_) {}

    try {
      await ref.read(opusEncoderProvider).init();
    } catch (_) {}

    _permissionGranted = await Permission.microphone.isGranted;
  }

  /// Modus umschalten (nur im Idle-Zustand).
  void toggleMode() {
    final current = state.valueOrNull ?? const TalkbackState();
    if (current.status != TalkbackStatus.idle) return;
    final newMode = current.mode == TalkbackMode.live
        ? TalkbackMode.delayed
        : TalkbackMode.live;
    state = AsyncData(current.copyWith(mode: newMode));
  }

  // ── Öffentliche API ────────────────────────────────────────────────────────

  /// Startet Talkback: Mikrofon öffnen, gRPC-Stream aufbauen, Opus-Encode starten.
  Future<void> startTalking({List<String> targetBusIds = const []}) async {
    final current = state.valueOrNull ?? const TalkbackState();
    if (current.status != TalkbackStatus.idle) return;

    state = AsyncData(current.copyWith(status: TalkbackStatus.requesting));

    // Mikrofon-Permission — gecacht wenn bereits geprüft
    if (!_permissionGranted) {
      final perm = await Permission.microphone.request();
      if (!perm.isGranted) {
        state = AsyncData(current.copyWith(
          status: TalkbackStatus.error,
          errorMessage: 'Mikrofon-Berechtigung verweigert',
        ));
        return;
      }
      _permissionGranted = true;
    }

    // Opus init — idempotent, fast wenn bereits initialisiert
    final enc = ref.read(opusEncoderProvider);
    try {
      await enc.init();
    } catch (e) {
      state = AsyncData(current.copyWith(
        status: TalkbackStatus.error,
        errorMessage: 'Opus-Init fehlgeschlagen: $e',
      ));
      return;
    }

    final client = StageSyncClient.instance;
    final sessionId = client.sessionId;
    final token = client.token;
    if (sessionId == null || token == null) {
      state = AsyncData(current.copyWith(
        status: TalkbackStatus.error,
        errorMessage: 'Nicht mit Session verbunden',
      ));
      return;
    }

    // Gecachte Credentials verwenden; auf Prefs warten falls _preInit() noch läuft
    if (_cachedClientId == null || _cachedDisplayName == null) {
      try {
        final prefs = await SharedPreferences.getInstance();
        _cachedClientId ??= prefs.getString('device_id');
        _cachedDisplayName ??= prefs.getString('display_name');
      } catch (_) {}
    }
    final clientId = _cachedClientId ?? sessionId;
    final displayName =
        _cachedDisplayName ?? clientId; // Client-ID statt "Unbekannt"

    _outgoing = StreamController<tb_proto.TalkbackFrame>();

    // Init-Frame senden
    _outgoing!.add(tb_proto.TalkbackFrame(
      init: tb_proto.TalkbackInitFrame(
        sessionId: sessionId,
        token: token,
        clientId: clientId,
        displayName: displayName,
        targetBusIds: targetBusIds,
        sampleRate: 48000,
        channels: 1,
      ),
    ));

    // gRPC-Stream öffnen
    try {
      final responseStream = client.talkback.streamTalkback(_outgoing!.stream);

      _statusSub = responseStream.listen(
        (status) {
          final current = state.valueOrNull ?? const TalkbackState();
          state = AsyncData(TalkbackState(
            status: TalkbackStatus.active,
            // Eigenes Gerät herausfiltern — man sieht sich nicht selbst als Sprecher
            activeTalkers: status.activeTalkers
                .where((t) => t.clientId != current.ownClientId)
                .toList(),
            targetBusIds: targetBusIds,
            mode: current.mode,
            ownClientId: current.ownClientId,
          ));
        },
        onError: (e) {
          _cleanup();
          state = AsyncData(TalkbackState(
            status: TalkbackStatus.error,
            errorMessage: 'Stream-Fehler: $e',
          ));
        },
        onDone: () {
          _cleanup();
          state = const AsyncData(TalkbackState(status: TalkbackStatus.idle));
        },
      );
    } catch (e) {
      _outgoing?.close();
      state = AsyncData(current.copyWith(
        status: TalkbackStatus.error,
        errorMessage: 'Verbindungsfehler: $e',
      ));
      return;
    }

    final currentMode = state.valueOrNull?.mode ?? TalkbackMode.live;

    // Mikrofon starten
    final mic = ref.read(micCaptureProvider);
    try {
      if (currentMode == TalkbackMode.delayed) {
        // Delayed-Modus: nur aufnehmen, noch nicht senden
        _recordedFrames.clear();
        await mic.start(
          onFrame: (Int16List pcm) =>
              _recordedFrames.add(Int16List.fromList(pcm)),
        );
      } else {
        // Live-Modus: sofort senden
        await mic.start(
          onFrame: (Int16List pcm) {
            final opusData = enc.encode(pcm);
            if (opusData == null || _outgoing == null || _outgoing!.isClosed)
              return;
            _outgoing!.add(tb_proto.TalkbackFrame(
              audio: tb_proto.AudioChunk(
                opusData: opusData,
                timestampMs: Int64(DateTime.now().millisecondsSinceEpoch),
                sequence: _sequence++,
              ),
            ));
          },
        );
      }
    } catch (e) {
      _cleanup();
      state = AsyncData(TalkbackState(
        status: TalkbackStatus.error,
        errorMessage: 'Mikrofon-Fehler: $e',
        mode: currentMode,
      ));
      return;
    }

    state = AsyncData(TalkbackState(
      status: TalkbackStatus.active,
      targetBusIds: targetBusIds,
      mode: currentMode,
      ownClientId: clientId,
    ));
  }

  /// Stoppt Talkback: Mikrofon schließen, ggf. Aufnahme absenden, Stream beenden.
  Future<void> stopTalking() async {
    final mic = ref.read(micCaptureProvider);
    await mic.stop();

    final currentMode = state.valueOrNull?.mode ?? TalkbackMode.live;

    if (currentMode == TalkbackMode.delayed && _recordedFrames.isNotEmpty) {
      // Delayed-Modus: alle Frames ohne künstliches Pacing burst-senden.
      // Der Server-Ring-Buffer wächst dynamisch → kein Überlauf, kein Kratzen.
      final enc = ref.read(opusEncoderProvider);
      final frames = List<Int16List>.from(_recordedFrames);
      _recordedFrames.clear();

      for (final pcm in frames) {
        final opusData = enc.encode(pcm);
        if (opusData == null || _outgoing == null || _outgoing!.isClosed) break;
        _outgoing!.add(tb_proto.TalkbackFrame(
          audio: tb_proto.AudioChunk(
            opusData: opusData,
            timestampMs: Int64(DateTime.now().millisecondsSinceEpoch),
            sequence: _sequence++,
          ),
        ));
      }
      // Kurze Pause damit die letzten Frames den Server erreichen
      await Future<void>.delayed(const Duration(milliseconds: 50));
    } else {
      // Live-Modus: Ring-Buffer auf dem Server leer spielen lassen bevor Stream
      // geschlossen wird — verhindert Abschneiden des Endes.
      await Future<void>.delayed(const Duration(milliseconds: 60));
    }

    await _cleanup();
    state = AsyncData(TalkbackState(
      status: TalkbackStatus.idle,
      mode: currentMode,
    ));
  }

  /// Verwirft eine laufende Delayed-Aufnahme ohne sie zu senden.
  /// Im Live-Modus identisch mit stopTalking() ohne Drain-Wait.
  Future<void> cancelTalking() async {
    final mic = ref.read(micCaptureProvider);
    await mic.stop();
    _recordedFrames.clear();
    await _cleanup();
    state = AsyncData(TalkbackState(
      status: TalkbackStatus.idle,
      mode: state.valueOrNull?.mode ?? TalkbackMode.live,
    ));
  }

  Future<void> _cleanup() async {
    await _statusSub?.cancel();
    _statusSub = null;
    await _outgoing?.close();
    _outgoing = null;
    _sequence = 0;
  }
}
