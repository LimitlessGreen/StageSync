import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../grpc/stage_sync_client.dart';
import '../grpc/generated/stagesync/v1/showcontrol.pb.dart' hide PatchConfig;
import '../infrastructure/grpc/show_control_repository.dart' as repo;
import '../domain/show.dart' as domain;
import '../domain/node_status.dart';
import '../domain/patch_config.dart';
import '../session/clock_sync.dart';
import 'session_provider.dart';

const _uuid = Uuid();

// ── State ─────────────────────────────────────────────────────────────────────

/// Sentinel, um in [ShowControlState.copyWith] „nicht übergeben" von „auf null
/// setzen" zu unterscheiden.
const Object _unset = Object();

class ShowControlState {
  final CueList? cueList;
  final Cue? activeCue;
  final Cue? nextCue;
  final bool isLoading;
  final bool isPaused;
  final String? error;

  /// Startzeit der aktiven Cue in Server-Zeit (Unix-Millis).
  final int? activeCueStartedServerMs;

  /// Server-Zeit (Unix-Millis), zu der pausiert wurde.
  final int? pausedAtServerMs;

  /// Alle aktuell ausführenden Cue-IDs (bei Group-Cues mehrere).
  final Set<String> runningCueIds;

  /// Alle Nodes der Session mit aktuellem Health-Status.
  final List<NodeStatus> nodeStatuses;

  /// Aktuelle Patch-Konfiguration (aus WatchShowDefinition-Stream).
  final PatchConfig patchConfig;

  const ShowControlState({
    this.cueList,
    this.activeCue,
    this.nextCue,
    this.isLoading = false,
    this.isPaused = false,
    this.error,
    this.activeCueStartedServerMs,
    this.pausedAtServerMs,
    this.runningCueIds = const {},
    this.nodeStatuses = const [],
    this.patchConfig = PatchConfig.empty,
  });

  ShowControlState copyWith({
    CueList? cueList,
    bool? isLoading,
    bool? isPaused,
    String? error,
    Set<String>? runningCueIds,
    List<NodeStatus>? nodeStatuses,
    PatchConfig? patchConfig,
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
        runningCueIds: runningCueIds ?? this.runningCueIds,
        nodeStatuses: nodeStatuses ?? this.nodeStatuses,
        patchConfig: patchConfig ?? this.patchConfig,
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

  // Stream 1: Show-Definition (CueList-Änderungen)
  StreamSubscription<ShowDefinitionEvent>? _defSub;
  int _lastDefSeq = 0;

  // Stream 2: Show-Execution (Transport-Events)
  StreamSubscription<ShowExecutionEvent>? _execSub;
  int _lastExecSeq = 0;

  // Stream 3: Node-Health (Online/Offline-Events)
  StreamSubscription<NodeHealthEvent>? _healthSub;
  int _lastHealthSeq = 0;
  // Lokale Kopie für Merge-Operationen (nodeId → NodeStatus).
  final Map<String, NodeStatus> _nodeMap = {};

  ShowControlNotifier(this._ref) : super(const ShowControlState());

  SessionState get _session => _ref.read(sessionProvider);
  String get _sessionId => _session.session!.sessionId;
  String get _token => _session.token!;

  /// CueList laden und beide Event-Streams starten.
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

      _subscribeToDefinition();
      _subscribeToExecution();
      _subscribeToNodeHealth();
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  // ── Transport Commands ──────────────────────────────────────────────────────

  Future<void> go({String cueId = ''}) async {
    if (!_session.isInSession) return;
    final req = GoRequest()
      ..sessionId = _sessionId
      ..token = _token
      ..cueId = cueId
      ..commandId = _uuid.v4();

    try {
      final resp = await StageSyncClient.instance.showControl.go(req);
      // Startzeit NICHT lokal setzen — das autoritative CUE_STARTED-Event
      // vom Server liefert die Server-Startzeit für alle Geräte einheitlich.
      state = state.copyWith(
        activeCue: resp.executingCue,
        nextCue: resp.nextCue,
      );
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  Future<void> stop() async {
    if (!_session.isInSession) return;
    final req = StopRequest()
      ..sessionId = _sessionId
      ..token = _token
      ..commandId = _uuid.v4();
    await StageSyncClient.instance.showControl.stop(req);
    state = state.copyWith(
      activeCue: null,
      isPaused: false,
      activeCueStartedServerMs: null,
      pausedAtServerMs: null,
    );
  }

  Future<void> pause() async {
    if (!_session.isInSession) return;
    final req = PauseRequest()
      ..sessionId = _sessionId
      ..token = _token
      ..commandId = _uuid.v4();
    await StageSyncClient.instance.showControl.pause(req);
    state = state.copyWith(
      isPaused: true,
      pausedAtServerMs: ClockSync.instance.serverNow(),
    );
  }

  Future<void> resume() async {
    if (!_session.isInSession) return;
    final req = ResumeRequest()
      ..sessionId = _sessionId
      ..token = _token
      ..commandId = _uuid.v4();
    await StageSyncClient.instance.showControl.resume(req);
    state = state.copyWith(isPaused: false);
  }

  Future<void> goToCue(String cueId) => go(cueId: cueId);
  Future<void> deleteCueById(String cueId) => deleteCue(cueId);

  Future<void> upsertDomainCue(domain.Cue domainCue) =>
      upsertCue(repo.ShowControlRepository.cueToProto(domainCue));

  Future<void> reorderCue({required List<String> orderedIds}) async {
    final list = state.cueList;
    if (list == null) return;

    final byId = {for (final c in list.cues) c.cueId: c};
    final reordered = orderedIds
        .map((id) => byId[id])
        .whereType<Cue>()
        .toList();

    final updated = list.deepCopy()
      ..cues.clear()
      ..cues.addAll(reordered);

    await updateCueList(updated);
  }

  Future<void> addCue() async {
    if (!_session.isInSession) return;
    final newCue = Cue()
      ..cueId = _uuid.v4()
      ..number = _nextCueNumber()
      ..label = 'Neue Cue';
    await upsertCue(newCue);
  }

  String _nextCueNumber() {
    final cues = state.cueList?.cues ?? [];
    if (cues.isEmpty) return '1';
    final last = cues.last.number;
    final n = int.tryParse(last);
    if (n != null) return '${n + 1}';
    return '${cues.length + 1}';
  }

  Future<void> upsertCue(Cue cue) async {
    if (!_session.isInSession) return;
    final currentListId = state.cueList?.cueListId ?? 'main';
    final req = UpsertCueRequest()
      ..sessionId = _sessionId
      ..token = _token
      ..cueListId = currentListId
      ..cue = cue;
    await StageSyncClient.instance.showControl.upsertCue(req);
    await initialize();
  }

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

  /// Patch-Konfiguration auf dem Server aktualisieren.
  Future<void> updatePatchConfig(PatchConfig config) async {
    if (!_session.isInSession) return;
    final req = UpdatePatchConfigRequest()
      ..sessionId = _sessionId
      ..token = _token
      ..patchConfig = repo.ShowControlRepository.patchConfigToProto(config);
    await StageSyncClient.instance.showControl.updatePatchConfig(req);
    // Optimistic: Update kommt auch per WatchShowDefinition zurück.
    state = state.copyWith(patchConfig: config);
  }

  Future<void> updateCueList(CueList updated) async {
    if (!_session.isInSession) return;
    final req = UpdateCueListRequest()
      ..sessionId = _sessionId
      ..token = _token
      ..cueList = updated;
    final resp = await StageSyncClient.instance.showControl.updateCueList(req);
    state = state.copyWith(cueList: resp.cueList);
  }

  // ── Stream 1: Show-Definition ───────────────────────────────────────────────

  void _subscribeToDefinition() {
    _defSub?.cancel();
    _lastDefSeq = 0;
    final req = WatchShowDefinitionRequest()
      ..sessionId = _sessionId
      ..nodeId = _session.myNode!.nodeId
      ..token = _token;

    _defSub = StageSyncClient.instance.showControl
        .watchShowDefinition(req)
        .listen(_handleDefinitionEvent);
  }

  void _handleDefinitionEvent(ShowDefinitionEvent event) {
    final seq = event.seq.toInt();
    if (seq != 0 && seq < _lastDefSeq) return;
    if (seq > _lastDefSeq) _lastDefSeq = seq;

    var newState = state;
    if (event.hasCueList()) {
      newState = newState.copyWith(cueList: event.cueList);
    }
    if (event.hasPatchConfig()) {
      newState = newState.copyWith(
        patchConfig: repo.ShowControlRepository.patchConfigFromProto(event.patchConfig),
      );
    }
    if (newState != state) state = newState;
  }

  // ── Stream 2: Show-Execution ────────────────────────────────────────────────

  void _subscribeToExecution() {
    _execSub?.cancel();
    _lastExecSeq = 0;
    final req = WatchShowExecutionRequest()
      ..sessionId = _sessionId
      ..nodeId = _session.myNode!.nodeId
      ..token = _token;

    _execSub = StageSyncClient.instance.showControl
        .watchShowExecution(req)
        .listen(_handleExecutionEvent);
  }

  void _handleExecutionEvent(ShowExecutionEvent event) {
    final seq = event.seq.toInt();
    if (seq != 0 && seq < _lastExecSeq) return;
    if (seq > _lastExecSeq) _lastExecSeq = seq;

    switch (event.type) {
      case ShowExecutionEvent_ExecutionEventType.EXECUTION_SNAPSHOT:
        // Snapshot: Transport-State beim Verbinden synchronisieren.
        if (event.hasAffectedCue()) {
          final startMs = event.cueStartedAtMs.toInt() != 0
              ? event.cueStartedAtMs.toInt()
              : _eventServerMs(event);
          state = state.copyWith(
            isPaused: event.isPaused,
            activeCue: event.affectedCue,
            activeCueStartedServerMs: startMs,
          );
        }
      case ShowExecutionEvent_ExecutionEventType.CUE_STARTED:
        final startMs = event.cueStartedAtMs.toInt() != 0
            ? event.cueStartedAtMs.toInt()
            : _eventServerMs(event);
        state = state.copyWith(
          isPaused: false,
          activeCue: event.hasAffectedCue() ? event.affectedCue : state.activeCue,
          activeCueStartedServerMs: startMs,
          pausedAtServerMs: null,
          runningCueIds: event.runningCueIds.isNotEmpty
              ? event.runningCueIds.toSet()
              : (event.hasAffectedCue() ? {event.affectedCue.cueId} : state.runningCueIds),
        );
      case ShowExecutionEvent_ExecutionEventType.CUE_PAUSED:
        state = state.copyWith(
          isPaused: true,
          pausedAtServerMs: _eventServerMs(event),
        );
      case ShowExecutionEvent_ExecutionEventType.CUE_RESUMED:
        // Resume schickt CUE_STARTED mit angepasster Startzeit — hier nur
        // isPaused optimistisch lösen falls das Event separat kommt.
        state = state.copyWith(isPaused: false);
      case ShowExecutionEvent_ExecutionEventType.CUE_STOPPED:
        state = state.copyWith(
          activeCue: null,
          isPaused: false,
          activeCueStartedServerMs: null,
          pausedAtServerMs: null,
          runningCueIds: const {},
        );
      case ShowExecutionEvent_ExecutionEventType.CUE_DONE:
      case ShowExecutionEvent_ExecutionEventType.CUE_ERROR:
        final updatedRunning = event.runningCueIds.isNotEmpty
            ? event.runningCueIds.toSet()
            : state.runningCueIds;
        state = state.copyWith(runningCueIds: updatedRunning);
      default:
        break;
    }
  }

  // ── Stream 3: Node-Health ───────────────────────────────────────────────────

  void _subscribeToNodeHealth() {
    _healthSub?.cancel();
    _lastHealthSeq = 0;
    _nodeMap.clear();
    final req = WatchNodeHealthRequest()
      ..sessionId = _sessionId
      ..nodeId = _session.myNode!.nodeId
      ..token = _token;

    _healthSub = StageSyncClient.instance.showControl
        .watchNodeHealth(req)
        .listen(_handleNodeHealthEvent);
  }

  void _handleNodeHealthEvent(NodeHealthEvent event) {
    final seq = event.seq.toInt();
    if (seq != 0 && seq < _lastHealthSeq) return;
    if (seq > _lastHealthSeq) _lastHealthSeq = seq;

    if (!event.hasNode()) return;

    final info = event.node;
    final health = switch (event.type) {
      NodeHealthEvent_HealthEventType.NODE_OFFLINE => NodeHealthPhase.offline,
      NodeHealthEvent_HealthEventType.NODE_DEGRADED => NodeHealthPhase.degraded,
      _ => NodeHealthPhase.online, // HEALTH_SNAPSHOT + NODE_ONLINE
    };

    final existing = _nodeMap[info.nodeId];

    // Capabilities aus dem Event oder vorherigem Eintrag übernehmen.
    AuditionCapability audition = AuditionCapability.none;
    if (event.hasCapabilities() && event.capabilities.auditionSupported) {
      audition = AuditionCapability(
        supported: true,
        deviceName: event.capabilities.auditionDevice.isEmpty
            ? null
            : event.capabilities.auditionDevice,
      );
    } else {
      audition = existing?.audition ?? AuditionCapability.none;
    }

    _nodeMap[info.nodeId] = NodeStatus(
      nodeId: info.nodeId,
      name: info.name,
      tasks: repo.ShowControlRepository.tasksFromProto(info.tasks.toList()),
      health: health,
      clockDeltaMs: existing?.clockDeltaMs,
      audition: audition,
    );

    state = state.copyWith(nodeStatuses: _nodeMap.values.toList());
  }

  int _eventServerMs(ShowExecutionEvent event) {
    if (event.hasOccurredAt()) {
      final ms = event.occurredAt.unixMillis.toInt();
      if (ms != 0) return ms;
    }
    return ClockSync.instance.serverNow();
  }

  @override
  void dispose() {
    _defSub?.cancel();
    _execSub?.cancel();
    _healthSub?.cancel();
    super.dispose();
  }
}
