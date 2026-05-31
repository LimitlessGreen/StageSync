import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../grpc/stage_sync_client.dart';
import '../grpc/generated/stagesync/v1/showcontrol.pb.dart' hide PatchConfig;
import '../infrastructure/grpc/show_control_repository.dart' as repo;
import '../domain/show.dart' as domain;
import '../domain/cue_params.dart' as domain_params;
import '../domain/node_status.dart';
import '../nodes/audio_node/audio_device.dart';
import '../domain/patch_config.dart';
import '../session/clock_sync.dart';
import 'session_provider.dart';
import 'media_provider.dart';

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

  /// Server-Zeit (Unix-Millis), zu der die Cue natürlich endete (CUE_DONE).
  final int? cueDoneServerMs;

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
    this.cueDoneServerMs,
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
    Object? cueDoneServerMs = _unset,
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
        cueDoneServerMs: identical(cueDoneServerMs, _unset)
            ? this.cueDoneServerMs
            : cueDoneServerMs as int?,
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
      // WatchManifest-gRPC-Stream öffnen: liefert Snapshot + Live-Updates.
      _ref.read(mediaProvider.notifier).startWatching();
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

    // Renumber sequentially so the list order always matches the numbers.
    for (var i = 0; i < reordered.length; i++) {
      reordered[i] = reordered[i].deepCopy()..number = '${i + 1}';
    }

    final updated = list.deepCopy()
      ..cues.clear()
      ..cues.addAll(reordered);

    await updateCueList(updated);
  }

  Future<void> addCue({domain_params.CueParams params = const domain_params.AudioParams(assetId: '')}) async {
    if (!_session.isInSession) return;
    final domainCue = domain.Cue(
      id: _uuid.v4(),
      number: _nextCueNumber(),
      label: 'Neue Cue',
      params: params,
    );
    await upsertDomainCue(domainCue);
  }

  String _nextCueNumber() {
    final cues = state.cueList?.cues ?? [];
    if (cues.isEmpty) return '1';
    final last = cues.last.number;
    final n = int.tryParse(last);
    if (n != null) return '${n + 1}';
    return '${cues.length + 1}';
  }

  /// Insert a new cue directly after [afterId] (or at end if null).
  Future<void> insertDomainCue(
    domain_params.CueParams params, {
    String? afterId,
  }) async {
    if (!_session.isInSession) return;
    final list = state.cueList;
    if (list == null) return;

    final cues = list.cues.toList();
    final insertIdx = afterId != null
        ? (cues.indexWhere((c) => c.cueId == afterId) + 1).clamp(0, cues.length)
        : cues.length;

    final prevNum = insertIdx > 0 ? double.tryParse(cues[insertIdx - 1].number) : null;
    final nextNum = insertIdx < cues.length ? double.tryParse(cues[insertIdx].number) : null;
    final newNum = _midNumber(prevNum, nextNum, insertIdx);

    final newCue = domain.Cue(
      id: _uuid.v4(),
      number: newNum,
      label: 'Neue Cue',
      params: params,
    );
    await upsertDomainCue(newCue);

    // Reorder to place it at the right position
    final proto = state.cueList?.cues.firstWhere(
      (c) => c.cueId == newCue.id,
      orElse: () => throw StateError('inserted cue not found'),
    );
    if (proto == null) return;
    final newIds = List<String>.from(
      state.cueList!.cues.map((c) => c.cueId),
    );
    newIds.remove(newCue.id);
    newIds.insert(insertIdx, newCue.id);
    await reorderCue(orderedIds: newIds);
  }

  /// Duplicate [cueId] and insert the copy directly after it.
  Future<void> duplicateDomainCue(String cueId) async {
    if (!_session.isInSession) return;
    final list = state.cueList;
    if (list == null) return;
    final src = list.cues.firstWhere(
      (c) => c.cueId == cueId,
      orElse: () => Cue(),
    );
    if (src.cueId.isEmpty) return;
    final srcDomain = repo.ShowControlRepository.cueFromProto(src);
    await insertDomainCue(srcDomain.params, afterId: cueId);
  }

  /// Wrap [cueId] in a new sequential group cue inserted before it.
  Future<void> wrapInGroup(String cueId) async {
    if (!_session.isInSession) return;
    final list = state.cueList;
    if (list == null) return;

    final idx = list.cues.indexWhere((c) => c.cueId == cueId);
    if (idx < 0) return;

    final prevNum = idx > 0 ? double.tryParse(list.cues[idx - 1].number) : null;
    final thisNum = double.tryParse(list.cues[idx].number);
    final groupNum = _midNumber(prevNum, thisNum, idx);

    final group = domain.Cue(
      id: _uuid.v4(),
      number: groupNum,
      label: 'Gruppe',
      params: domain_params.GroupParams(childCueIds: [cueId], sequential: true),
    );
    await upsertDomainCue(group);

    // Place group before the wrapped cue
    final newIds = List<String>.from(state.cueList!.cues.map((c) => c.cueId));
    newIds.remove(group.id);
    newIds.insert(idx, group.id);
    await reorderCue(orderedIds: newIds);
  }

  String _midNumber(double? prev, double? next, int idx) {
    if (prev != null && next != null) {
      final mid = (prev + next) / 2;
      return mid == mid.truncateToDouble() ? mid.toInt().toString() : mid.toStringAsFixed(1);
    }
    if (prev != null) return (prev + 1).toInt().toString();
    if (next != null && next > 1) return (next - 1).toInt().toString();
    return (idx + 1).toString();
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

  void _scheduleReconnect() {
    if (!_session.isInSession) return;
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted && _session.isInSession) initialize();
    });
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
        .listen(_handleDefinitionEvent,
            onError: (_) => _scheduleReconnect(),
            onDone: () => _scheduleReconnect());
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
        .listen(_handleExecutionEvent,
            onError: (_) => _scheduleReconnect(),
            onDone: () => _scheduleReconnect());
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
          cueDoneServerMs: null, // neuer GO/Resume → done-Zustand löschen
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
          cueDoneServerMs: null,
          runningCueIds: const {},
        );
      case ShowExecutionEvent_ExecutionEventType.CUE_DONE:
      case ShowExecutionEvent_ExecutionEventType.CUE_ERROR:
        final updatedRunning = event.runningCueIds.isNotEmpty
            ? event.runningCueIds.toSet()
            : const <String>{};
        if (updatedRunning.isEmpty) {
          // Keine Cues mehr aktiv → done-Zustand: Timer einfrieren, nicht weiter zählen
          state = state.copyWith(
            runningCueIds: const {},
            cueDoneServerMs: _eventServerMs(event),
          );
        } else {
          state = state.copyWith(runningCueIds: updatedRunning);
        }
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
        .listen(_handleNodeHealthEvent,
            onError: (_) => _scheduleReconnect(),
            onDone: () => _scheduleReconnect());
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
    List<AudioDevice> availableDevices = existing?.availableDevices ?? const [];

    if (event.hasCapabilities()) {
      final caps = event.capabilities;
      if (caps.auditionSupported) {
        audition = AuditionCapability(
          supported: true,
          deviceName: caps.auditionDevice.isEmpty ? null : caps.auditionDevice,
        );
      } else {
        audition = existing?.audition ?? AuditionCapability.none;
      }
      if (caps.hasAudio() && caps.audio.availableDevices.isNotEmpty) {
        availableDevices = caps.audio.availableDevices
            .map((d) => AudioDevice(
                  id: d.name, // proto has no opaque id — use name as stable key
                  name: d.name,
                  index: d.index,
                ))
            .toList();
      }
    }

    _nodeMap[info.nodeId] = NodeStatus(
      nodeId: info.nodeId,
      name: info.name,
      tasks: repo.ShowControlRepository.tasksFromProto(info.tasks.toList()),
      health: health,
      clockDeltaMs: existing?.clockDeltaMs,
      audition: audition,
      availableDevices: availableDevices,
    );

    state = state.copyWith(nodeStatuses: _nodeMap.values.toList());
  }

  // ── Stream 4: Media-Sync ────────────────────────────────────────────────────

  // _subscribeToMediaSync entfernt: WatchManifest (MediaService) übernimmt
  // Snapshot + inkrementelle Events direkt im MediaNotifier.

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
