import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../grpc/stage_sync_client.dart';
import '../grpc/generated/stagesync/v1/showcontrol.pb.dart';
import '../session/clock_sync.dart';
import 'session_provider.dart';

// ── State ─────────────────────────────────────────────────────────────────────

/// Sentinel, um in [ShowControlState.copyWith] „nicht übergeben" von „auf null
/// setzen" zu unterscheiden (das alte `?? this`-Muster konnte nullable Felder
/// nicht löschen — dadurch blieb z.B. beim Stop die aktive Cue erhalten).
const Object _unset = Object();

class ShowControlState {
  final CueList? cueList;
  final Cue? activeCue;
  final Cue? nextCue;
  final bool isLoading;
  final bool isPaused;
  final String? error;

  /// Startzeit der aktiven Cue in **Server-Zeit** (Unix-Millis). Vom Master per
  /// ShowStateEvent gesetzt → über [ClockSync] zeigen alle Geräte dieselbe
  /// verstrichene Zeit (statt lokal hochzuzählen).
  final int? activeCueStartedServerMs;

  /// Server-Zeit (Unix-Millis), zu der pausiert wurde. Nicht-null = Transport
  /// eingefroren → die verstrichene Zeit bleibt stehen.
  final int? pausedAtServerMs;

  const ShowControlState({
    this.cueList,
    this.activeCue,
    this.nextCue,
    this.isLoading = false,
    this.isPaused = false,
    this.error,
    this.activeCueStartedServerMs,
    this.pausedAtServerMs,
  });

  ShowControlState copyWith({
    CueList? cueList,
    bool? isLoading,
    bool? isPaused,
    String? error,
    Object? activeCue = _unset,
    Object? nextCue = _unset,
    Object? activeCueStartedServerMs = _unset,
    Object? pausedAtServerMs = _unset,
  }) =>
      ShowControlState(
        cueList: cueList ?? this.cueList,
        activeCue: identical(activeCue, _unset) ? this.activeCue : activeCue as Cue?,
        nextCue: identical(nextCue, _unset) ? this.nextCue : nextCue as Cue?,
        isLoading: isLoading ?? this.isLoading,
        isPaused: isPaused ?? this.isPaused,
        error: error,
        activeCueStartedServerMs: identical(activeCueStartedServerMs, _unset)
            ? this.activeCueStartedServerMs
            : activeCueStartedServerMs as int?,
        pausedAtServerMs: identical(pausedAtServerMs, _unset)
            ? this.pausedAtServerMs
            : pausedAtServerMs as int?,
      );
}

// ── Provider ──────────────────────────────────────────────────────────────────

final showControlProvider =
    StateNotifierProvider<ShowControlNotifier, ShowControlState>((ref) {
  return ShowControlNotifier(ref);
});

// ── Notifier ──────────────────────────────────────────────────────────────────

class ShowControlNotifier extends StateNotifier<ShowControlState> {
  final Ref _ref;
  StreamSubscription<ShowStateEvent>? _stateSub;
  // Letzte angewandte Server-Sequenz → veraltete/out-of-order Events verwerfen.
  int _lastSeq = 0;

  ShowControlNotifier(this._ref) : super(const ShowControlState());

  SessionState get _session => _ref.read(sessionProvider);

  String get _sessionId => _session.session!.sessionId;
  String get _token => _session.token!;

  /// CueList laden und Show-State-Stream starten.
  Future<void> initialize() async {
    if (!_session.isInSession) return;

    state = state.copyWith(isLoading: true);
    try {
      final client = StageSyncClient.instance;
      final req = GetCueListRequest()
        ..sessionId = _sessionId
        ..token = _token;

      final resp = await client.showControl.getCueList(req);
      state = state.copyWith(
        cueList: resp.cueList,
        isLoading: false,
      );

      _subscribeToState();
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  /// GO — nächste oder spezifische Cue ausführen.
  Future<void> go({String cueId = ''}) async {
    if (!_session.isInSession) return;
    final client = StageSyncClient.instance;

    final req = GoRequest()
      ..sessionId = _sessionId
      ..token = _token
      ..cueId = cueId;

    try {
      final resp = await client.showControl.go(req);
      // Startzeit NICHT lokal setzen — das autoritative TYPE_CUE_STARTED-Event
      // vom Master liefert die Server-Startzeit für alle Geräte einheitlich.
      state = state.copyWith(
        activeCue: resp.executingCue,
        nextCue: resp.nextCue,
      );
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  /// STOP — bricht die laufende Cue ab und setzt die Queue zurück.
  Future<void> stop() async {
    if (!_session.isInSession) return;
    final req = StopRequest()
      ..sessionId = _sessionId
      ..token = _token;
    await StageSyncClient.instance.showControl.stop(req);
    // Aktive Cue + Timer wirklich zurücksetzen (nicht nur isPaused).
    state = state.copyWith(
      activeCue: null,
      isPaused: false,
      activeCueStartedServerMs: null,
      pausedAtServerMs: null,
    );
  }

  /// PAUSE — hält die laufende Cue an und friert die verstrichene Zeit ein.
  Future<void> pause() async {
    if (!_session.isInSession) return;
    final req = PauseRequest()
      ..sessionId = _sessionId
      ..token = _token;
    await StageSyncClient.instance.showControl.pause(req);
    state = state.copyWith(
      isPaused: true,
      pausedAtServerMs: ClockSync.instance.serverNow(),
    );
  }

  /// RESUME — setzt eine pausierte Cue fort. Die korrekte Fortsetzung der Zeit
  /// liefert das vom Master gesendete TYPE_CUE_STARTED (mit angepasster
  /// Startzeit); hier nur optimistisch isPaused lösen.
  Future<void> resume() async {
    if (!_session.isInSession) return;
    final req = ResumeRequest()
      ..sessionId = _sessionId
      ..token = _token;
    await StageSyncClient.instance.showControl.resume(req);
    state = state.copyWith(isPaused: false);
  }

  /// Cue hinzufügen oder aktualisieren.
  Future<void> upsertCue(Cue cue) async {
    if (!_session.isInSession) return;
    final currentListId = state.cueList?.cueListId ?? 'main';
    final req = UpsertCueRequest()
      ..sessionId = _sessionId
      ..token = _token
      ..cueListId = currentListId
      ..cue = cue;
    await StageSyncClient.instance.showControl.upsertCue(req);
    await initialize(); // CueList neu laden
  }

  /// Cue löschen.
  Future<void> deleteCue(String cueId) async {
    if (!_session.isInSession) return;
    final currentListId = state.cueList?.cueListId ?? 'main';
    final req = DeleteCueRequest()
      ..sessionId = _sessionId
      ..token = _token
      ..cueListId = currentListId
      ..cueId = cueId;
    await StageSyncClient.instance.showControl.deleteCue(req);
    await initialize();
  }

  /// Komplette CueList ersetzen (z.B. nach Reorder).
  Future<void> updateCueList(CueList updated) async {
    if (!_session.isInSession) return;
    final req = UpdateCueListRequest()
      ..sessionId = _sessionId
      ..token = _token
      ..cueList = updated;
    final resp = await StageSyncClient.instance.showControl.updateCueList(req);
    state = state.copyWith(cueList: resp.cueList);
  }

  void _subscribeToState() {
    _stateSub?.cancel();
    _lastSeq = 0; // neuer Stream → Sequenz zurücksetzen
    final req = WatchShowStateRequest()
      ..sessionId = _sessionId
      ..nodeId = _session.myNode!.nodeId
      ..token = _token;

    _stateSub = StageSyncClient.instance.showControl
        .watchShowState(req)
        .listen(_handleEvent);
  }

  void _handleEvent(ShowStateEvent event) {
    // Veraltete Events verwerfen (Sequenz pro Session, monoton). Gleiche Seq
    // (z.B. Snapshot-Events) werden zugelassen — Anwendungen sind idempotent.
    final seq = event.seq.toInt();
    if (seq != 0 && seq < _lastSeq) return;
    if (seq > _lastSeq) _lastSeq = seq;

    // Cue-Liste immer übernehmen, wenn das Event sie mitliefert.
    final cueList = event.hasCueList() ? event.cueList : state.cueList;

    switch (event.type) {
      case ShowStateEvent_Type.TYPE_CUE_STARTED:
        // Einzige autoritative Quelle für „aktive Cue + Timerstart" (auch Resume:
        // der Master schickt eine angepasste Startzeit). NUR hier wird gestartet.
        state = state.copyWith(
          cueList: cueList,
          isPaused: false,
          activeCue: event.hasAffectedCue() ? event.affectedCue : state.activeCue,
          activeCueStartedServerMs: _eventServerMs(event),
          pausedAtServerMs: null,
        );
      case ShowStateEvent_Type.TYPE_CUE_PAUSED:
        // Auf die Server-Pausenzeit einfrieren → alle Geräte zeigen denselben Wert.
        state = state.copyWith(
          cueList: cueList,
          isPaused: true,
          pausedAtServerMs: _eventServerMs(event),
        );
      case ShowStateEvent_Type.TYPE_CUE_STOPPED:
        state = state.copyWith(
          cueList: cueList,
          activeCue: null,
          isPaused: false,
          activeCueStartedServerMs: null,
          pausedAtServerMs: null,
        );
      default:
        // LIST_UPDATED, CUE_DONE, CUE_ERROR: NUR die Liste aktualisieren.
        // Das Hinzufügen/Ändern einer Cue darf NICHT die aktive Cue setzen oder
        // den Timer starten (sonst „läuft" ein neu hinzugefügter Eintrag los).
        state = state.copyWith(cueList: cueList);
    }
  }

  /// Server-Zeitstempel eines Events in Unix-Millis (Fallback: jetzige Serverzeit).
  int _eventServerMs(ShowStateEvent event) {
    if (event.hasOccurredAt()) {
      final ms = event.occurredAt.unixMillis.toInt();
      if (ms != 0) return ms;
    }
    return ClockSync.instance.serverNow();
  }

  @override
  void dispose() {
    _stateSub?.cancel();
    super.dispose();
  }
}
