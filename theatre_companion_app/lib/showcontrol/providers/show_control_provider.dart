import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../grpc/stage_sync_client.dart';
import '../grpc/generated/stagesync/v1/showcontrol.pb.dart' hide PatchConfig;
import '../grpc/generated/stagesync/v1/node.pb.dart' as node_pb;
import '../grpc/generated/stagesync/v1/common.pbenum.dart' show NodeTask;
import '../infrastructure/grpc/show_control_repository.dart' as repo;
import '../domain/show.dart' as domain;
import '../domain/cue_params.dart' as domain_params;
import '../domain/node_status.dart';
import '../nodes/audio_node/audio_device.dart';
import '../domain/patch_config.dart';
import '../session/clock_sync.dart';
import 'session_provider.dart';
import 'session_context.dart';
import 'async_notifier_ext.dart';
import 'media_provider.dart';
import 'execution_event_reducer.dart';

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

  /// Startzeit je laufender Cue in Server-Zeit (Unix-Millis).
  final Map<String, int> runningCueStartedServerMs;

  /// Cue-IDs die per-Cue pausiert sind (Audio direkt auf Node pausiert).
  /// Unabhängig von der globalen CueList-Pause ([isPaused]).
  final Set<String> perCuePausedIds;

  /// Einfrierzeitpunkte pro per-Cue-pausierter Cue in Unix-ms.
  /// Gesetzt von CUE_CUE_PAUSED (occurredAt), gelöscht bei Resume/Done.
  final Map<String, int> perCuePausedAtMs;

  /// Resume-Zeitpunkte pro Cue in Unix-ms (aus CUE_CUE_RESUMED.occurredAt).
  /// Wird für das Fade-In-Animationsfenster nach Resume genutzt.
  final Map<String, int> perCueResumedAtMs;

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
    this.runningCueStartedServerMs = const {},
    this.perCuePausedIds = const {},
    this.perCuePausedAtMs = const {},
    this.perCueResumedAtMs = const {},
    this.nodeStatuses = const [],
    this.patchConfig = PatchConfig.empty,
  });

  ShowControlState copyWith({
    CueList? cueList,
    bool? isLoading,
    bool? isPaused,
    String? error,
    Set<String>? runningCueIds,
    Map<String, int>? runningCueStartedServerMs,
    Set<String>? perCuePausedIds,
    Map<String, int>? perCuePausedAtMs,
    Map<String, int>? perCueResumedAtMs,
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
        activeCue:
            identical(activeCue, _unset) ? this.activeCue : activeCue as Cue?,
        nextCue: identical(nextCue, _unset) ? this.nextCue : nextCue as Cue?,
        isLoading: isLoading ?? this.isLoading,
        isPaused: isPaused ?? this.isPaused,
        error: error,
        runningCueIds: runningCueIds ?? this.runningCueIds,
        runningCueStartedServerMs:
            runningCueStartedServerMs ?? this.runningCueStartedServerMs,
        perCuePausedIds: perCuePausedIds ?? this.perCuePausedIds,
        perCuePausedAtMs: perCuePausedAtMs ?? this.perCuePausedAtMs,
        perCueResumedAtMs: perCueResumedAtMs ?? this.perCueResumedAtMs,
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

class ShowControlNotifier extends StateNotifier<ShowControlState>
    with AsyncOp<ShowControlState> {
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

  SessionContext get _ctx => _ref.sessionCtx;
  SessionState get _session => _ref.read(sessionProvider);
  String get _sessionId => _ctx.sessionId;
  String get _token => _ctx.token;

  /// CueList laden und beide Event-Streams starten.
  Future<void> initialize() async {
    if (!_session.isInSession) return;
    await runAsync(
      () async {
        final client = StageSyncClient.instance;
        final req = GetCueListRequest()
          ..sessionId = _sessionId
          ..token = _token;
        final resp = await client.showControl.getCueList(req);
        state = state.copyWith(cueList: resp.cueList);
        _subscribeToDefinition();
        _subscribeToExecution();
        _subscribeToNodeHealth();
        // WatchManifest-gRPC-Stream öffnen: liefert Snapshot + Live-Updates.
        _ref.read(mediaProvider.notifier).startWatching();
      },
      setLoading: (s, l) => s.copyWith(isLoading: l, error: null),
      setError: (s, e) => s.copyWith(isLoading: false, error: e),
    );
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
      runningCueIds: const {},
      runningCueStartedServerMs: const {},
      perCuePausedIds: const {},
      perCuePausedAtMs: const {},
    );
  }

  Future<void> pause() async {
    if (!_session.isInSession) return;
    final req = PauseRequest()
      ..sessionId = _sessionId
      ..token = _token
      ..commandId = _uuid.v4();
    await StageSyncClient.instance.showControl.pause(req);
    // Kein optimistisches pausedAtServerMs setzen — der Wert vom Server enthält
    // press-time + fadeMs und ist die korrekte Einfrierposition für den Balken.
    // Ohne den Wert läuft der Balken bis zum Server-Event weiter (< 100ms Lücke),
    // statt sofort einzufrieren und den Fade-Out zu verpassen.
    state = state.copyWith(isPaused: true);
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

  /// Ermittelt die Ziel-Node-IDs für [cueId] über PatchConfig.
  /// Priorität: logicalOutputId → targetNodeId → alle online Audio-Nodes → eigene Node.
  List<String> _resolveTargetNodes(String cueId) {
    if (state.cueList == null) return const [];
    Cue? protoCue;
    for (final c in state.cueList!.cues) {
      if (c.cueId == cueId) {
        protoCue = c;
        break;
      }
    }
    if (protoCue == null) return const [];

    List<String> ids = [];
    if (protoCue.logicalOutputId.isNotEmpty) {
      ids = state.patchConfig.nodesForOutput(protoCue.logicalOutputId);
    }
    if (ids.isEmpty && protoCue.targetNodeId.isNotEmpty) {
      ids = [protoCue.targetNodeId];
    }
    if (ids.isEmpty) {
      ids = state.nodeStatuses
          .where((n) => n.isOnline && n.isAudio)
          .map((n) => n.nodeId)
          .toList();
    }
    if (ids.isEmpty) {
      final myNode = _session.myNode;
      if (myNode != null &&
          myNode.tasks.contains(NodeTask.NODE_TASK_AUDIO_OUTPUT)) {
        ids = [myNode.nodeId];
      }
    }
    return ids;
  }

  /// Sendet einen AudioFadeCommand über NodeService.sendNodeCommand an alle
  /// Nodes, die über [cueId] (via logicalOutputId + PatchConfig) zugeordnet sind.
  ///
  /// [targetVolumeDb]  Ziel-Lautstärke in dB (z.B. 0.0 für fade-up, -40.0 für fade-out).
  /// [durationMs]      Fade-Dauer in Millisekunden.
  /// [stopWhenDone]    Node stoppt Wiedergabe nach dem Fade (für fade-out).
  Future<void> sendAudioFade(
    String cueId, {
    required double targetVolumeDb,
    required double durationMs,
    bool stopWhenDone = false,
  }) async {
    if (!_session.isInSession) return;
    final targetNodeIds = _resolveTargetNodes(cueId);
    if (targetNodeIds.isEmpty) return;

    final fadeCmd = node_pb.AudioFadeCommand(
      cueId: cueId,
      targetVolumeDb: targetVolumeDb,
      durationMs: durationMs,
      stopWhenDone: stopWhenDone,
    );

    for (final nodeId in targetNodeIds) {
      final req = node_pb.SendNodeCommandRequest(
        sessionId: _sessionId,
        token: _token,
        targetNodeId: nodeId,
        command: node_pb.NodeCommandRequest(
          sessionId: _sessionId,
          commandId: _uuid.v4(),
          audioFade: fadeCmd,
        ),
      );
      try {
        await StageSyncClient.instance.node.sendNodeCommand(req);
      } catch (e) {
        // Fehler eines einzelnen Nodes soll andere Nodes nicht blockieren
        state = state.copyWith(error: 'Fade-Fehler ($nodeId): $e');
      }
    }
  }

  /// Blendet eine Cue hoch.
  ///
  /// Ist die Cue per-Cue pausiert (Fade-Out wurde vorher ausgelöst), wird sie
  /// mit einem Fade-In fortgesetzt. Läuft sie bereits, wird nur die Lautstärke
  /// auf den konfigurierten Wert hochgefadet.
  Future<void> fadeUpAudio(String cueId, {double durationMs = 1000.0}) async {
    if (!_session.isInSession) return;

    if (state.perCuePausedIds.contains(cueId)) {
      // Cue ist pausiert → Resume mit Fade-In
      await resumeCueAudio(cueId, fadeInMs: durationMs);
    } else {
      // Cue spielt → Lautstärke auf konfigurierten Wert hochfaden
      Cue? protoCue;
      for (final c in (state.cueList?.cues ?? [])) {
        if (c.cueId == cueId) {
          protoCue = c;
          break;
        }
      }
      final targetVolumeDb =
          (protoCue?.hasAudio() == true) ? protoCue!.audio.volumeDb : 0.0;
      await sendAudioFade(cueId,
          targetVolumeDb: targetVolumeDb,
          durationMs: durationMs,
          stopWhenDone: false);
    }
  }

  /// Blendet eine Cue aus und **pausiert** danach (nicht stoppen).
  /// So kann mit Fade-Up nahtlos fortgesetzt werden.
  Future<void> fadeOutAudio(String cueId, {double durationMs = 1000.0}) async {
    await pauseCueAudio(cueId, fadeOutMs: durationMs);
  }

  /// Stoppt eine laufende Audio-Cue sofort (mit kurzem Fade gegen Knackser).
  /// Der Server serialisiert den Stop, setzt Engine-State und broadcastet CUE_DONE.
  Future<void> stopCueAudio(String cueId, {double fadeOutMs = 200.0}) async {
    if (!_session.isInSession) return;
    try {
      await StageSyncClient.instance.showControl.stopCueAudio(
        StopCueAudioRequest()
          ..sessionId = _sessionId
          ..token = _token
          ..cueId = cueId
          ..fadeOutMs = fadeOutMs,
      );
    } catch (e) {
      state = state.copyWith(error: 'StopCueAudio-Fehler: $e');
    }
  }

  /// Pausiert eine laufende Audio-Cue mit kurzem Fade.
  /// Der Server serialisiert die Pause, setzt Engine-State und broadcastet CUE_CUE_PAUSED.
  Future<void> pauseCueAudio(String cueId, {double fadeOutMs = 120.0}) async {
    if (!_session.isInSession) return;
    try {
      await StageSyncClient.instance.showControl.pauseCueAudio(
        PauseCueAudioRequest()
          ..sessionId = _sessionId
          ..token = _token
          ..cueId = cueId
          ..fadeOutMs = fadeOutMs,
      );
    } catch (e) {
      state = state.copyWith(error: 'PauseCueAudio-Fehler: $e');
    }
  }

  /// Setzt eine pausierte Audio-Cue fort (mit kurzem Fade-In gegen Knackser).
  /// Der Server serialisiert den Resume, setzt Engine-State und broadcastet CUE_CUE_RESUMED.
  Future<void> resumeCueAudio(String cueId, {double fadeInMs = 120.0}) async {
    if (!_session.isInSession) return;
    try {
      await StageSyncClient.instance.showControl.resumeCueAudio(
        ResumeCueAudioRequest()
          ..sessionId = _sessionId
          ..token = _token
          ..cueId = cueId
          ..fadeInMs = fadeInMs,
      );
    } catch (e) {
      state = state.copyWith(error: 'ResumeCueAudio-Fehler: $e');
    }
  }

  Future<void> goToCue(String cueId) => go(cueId: cueId);
  Future<void> deleteCueById(String cueId) => deleteCue(cueId);

  Future<void> upsertDomainCue(domain.Cue domainCue) =>
      upsertCue(repo.ShowControlRepository.cueToProto(domainCue));

  Future<void> reorderCue({required List<String> orderedIds}) async {
    final list = state.cueList;
    if (list == null) return;

    final byId = {for (final c in list.cues) c.cueId: c};
    final reordered =
        orderedIds.map((id) => byId[id]).whereType<Cue>().toList();

    // Renumber sequentially so the list order always matches the numbers.
    for (var i = 0; i < reordered.length; i++) {
      reordered[i] = reordered[i].deepCopy()..number = '${i + 1}';
    }

    final updated = list.deepCopy()
      ..cues.clear()
      ..cues.addAll(reordered);

    await updateCueList(updated);
  }

  Future<domain.Cue?> addCue(
      {domain_params.CueParams params =
          const domain_params.AudioParams(assetId: '')}) async {
    if (!_session.isInSession) return null;
    final domainCue = domain.Cue(
      id: _uuid.v4(),
      number: _nextCueNumber(),
      label: 'Neue Cue',
      params: params,
    );
    await upsertDomainCue(domainCue);
    return domainCue;
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
  /// Returns the new cue's ID.
  Future<String?> insertDomainCue(
    domain_params.CueParams params, {
    String? afterId,
    String label = 'Neue Cue',
  }) async {
    if (!_session.isInSession) return null;
    final list = state.cueList;
    if (list == null) return null;

    final cues = list.cues.toList();
    final insertIdx = afterId != null
        ? (cues.indexWhere((c) => c.cueId == afterId) + 1).clamp(0, cues.length)
        : cues.length;

    final prevNum =
        insertIdx > 0 ? double.tryParse(cues[insertIdx - 1].number) : null;
    final nextNum = insertIdx < cues.length
        ? double.tryParse(cues[insertIdx].number)
        : null;
    final newNum = _midNumber(prevNum, nextNum, insertIdx);

    final newCue = domain.Cue(
      id: _uuid.v4(),
      number: newNum,
      label: label,
      params: params,
    );
    await upsertDomainCue(newCue);

    // Reorder to place it at the right position
    final proto = state.cueList?.cues.firstWhere(
      (c) => c.cueId == newCue.id,
      orElse: () => throw StateError('inserted cue not found'),
    );
    if (proto == null) return newCue.id;
    final newIds = List<String>.from(
      state.cueList!.cues.map((c) => c.cueId),
    );
    newIds.remove(newCue.id);
    newIds.insert(insertIdx, newCue.id);
    await reorderCue(orderedIds: newIds);
    return newCue.id;
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
      return mid == mid.truncateToDouble()
          ? mid.toInt().toString()
          : mid.toStringAsFixed(1);
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
    // The server broadcasts CUE_LIST_CHANGED via WatchShowDefinition which
    // _handleDefinitionEvent handles. No stream restart needed.
  }

  Future<void> deleteCue(String cueId) async {
    if (!_session.isInSession) return;

    // Läuft die Cue gerade → Audio vorher stoppen, damit kein Phantom-Audio bleibt.
    if (state.runningCueIds.contains(cueId)) {
      await stopCueAudio(cueId, fadeOutMs: 150);
    }

    // Lokalen State bereinigen bevor der Server antwortet.
    final isActive = state.activeCue?.cueId == cueId;
    if (isActive) {
      state = state.copyWith(
        activeCue: null,
        activeCueStartedServerMs: null,
        runningCueIds: {...state.runningCueIds}..remove(cueId),
        runningCueStartedServerMs: Map.of(state.runningCueStartedServerMs)
          ..remove(cueId),
        perCuePausedIds: {...state.perCuePausedIds}..remove(cueId),
        perCuePausedAtMs: Map.of(state.perCuePausedAtMs)..remove(cueId),
      );
    } else if (state.runningCueIds.contains(cueId)) {
      state = state.copyWith(
        runningCueIds: {...state.runningCueIds}..remove(cueId),
        runningCueStartedServerMs: Map.of(state.runningCueStartedServerMs)
          ..remove(cueId),
        perCuePausedIds: {...state.perCuePausedIds}..remove(cueId),
        perCuePausedAtMs: Map.of(state.perCuePausedAtMs)..remove(cueId),
      );
    }

    final currentListId = state.cueList?.cueListId ?? 'main';
    final req = DeleteCueRequest()
      ..sessionId = _sessionId
      ..token = _token
      ..cueListId = currentListId
      ..cueId = cueId;
    await StageSyncClient.instance.showControl.deleteCue(req);
    // The server broadcasts CUE_LIST_CHANGED via WatchShowDefinition which
    // _handleDefinitionEvent handles. No stream restart needed.
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
    _cancelGracefully(_defSub);
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
        patchConfig:
            repo.ShowControlRepository.patchConfigFromProto(event.patchConfig),
      );
    }
    if (newState != state) state = newState;
  }

  // ── Stream 2: Show-Execution ────────────────────────────────────────────────

  void _subscribeToExecution() {
    _cancelGracefully(_execSub);
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
    // Gap detected: missed events → resync immediately instead of silently diverging.
    if (_lastExecSeq > 0 && seq > _lastExecSeq + 1) {
      _subscribeToExecution();
      return;
    }
    if (seq > _lastExecSeq) _lastExecSeq = seq;
    state = applyExecutionEvent(state, event);
  }

  // ignore: unused_element — kept for reference during migration
  // ── Stream 3: Node-Health ───────────────────────────────────────────────────

  void _subscribeToNodeHealth() {
    _cancelGracefully(_healthSub);
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
    int? selectedDeviceIndex = existing?.selectedDeviceIndex;
    AudioBackend? activeBackend = existing?.activeBackend;
    List<AudioBackend> backendPriority = existing?.backendPriority ?? const [];
    int? sampleRate = existing?.sampleRate;
    int? channels = existing?.channels;

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
                  backend: audioBackendFromWireName(d.backend),
                  index: d.index,
                ))
            .toList();
      }
      if (caps.hasAudio()) {
        final audio = caps.audio;
        selectedDeviceIndex = audio.selectedDevice;
        activeBackend = audio.activeBackend.isEmpty
            ? null
            : audioBackendFromWireName(audio.activeBackend);
        backendPriority = audio.backendPriority
            .map(audioBackendFromWireName)
            .where((b) => b != AudioBackend.unknown)
            .toList();
        sampleRate = audio.sampleRate == 0 ? null : audio.sampleRate;
        channels = audio.channels == 0 ? null : audio.channels;
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
      selectedDeviceIndex: selectedDeviceIndex,
      activeBackend: activeBackend,
      backendPriority: backendPriority,
      sampleRate: sampleRate,
      channels: channels,
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
    _cancelGracefully(_defSub);
    _cancelGracefully(_execSub);
    _cancelGracefully(_healthSub);
    super.dispose();
  }

  static void _cancelGracefully(StreamSubscription? sub) {
    if (sub == null) return;
    Future.microtask(() => sub.cancel().catchError((_) {}));
  }
}
