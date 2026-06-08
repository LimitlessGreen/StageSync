import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../grpc/stage_sync_client.dart';
import '../grpc/generated/stagesync/v1/grid.pb.dart';
import '../domain/grid_run_state.dart';
import 'session_provider.dart';
import 'session_context.dart';
import 'grid_execution_reducer.dart';

const _uuid = Uuid();

// ── State ─────────────────────────────────────────────────────────────────────

class GridState {
  final Grid? grid;
  final Map<String, GridClipRunState> runStates;
  final bool isLoading;
  final String? error;

  const GridState({
    this.grid,
    this.runStates = const {},
    this.isLoading = false,
    this.error,
  });

  GridState copyWith({
    Grid? grid,
    Map<String, GridClipRunState>? runStates,
    bool? isLoading,
    String? error,
  }) =>
      GridState(
        grid: grid ?? this.grid,
        runStates: runStates ?? this.runStates,
        isLoading: isLoading ?? this.isLoading,
        error: error,
      );

  /// Run-State einer Zelle anhand ihrer Position (oder idle).
  GridClipRunState runStateAt(int track, int scene) {
    final g = grid;
    if (g == null) return const GridClipRunState();
    for (final c in g.clips) {
      if (c.trackIndex == track && c.sceneIndex == scene) {
        return runStates[c.clipId] ?? const GridClipRunState();
      }
    }
    return const GridClipRunState();
  }

  /// Clip an einer Position (oder null).
  GridClip? clipAt(int track, int scene) {
    final g = grid;
    if (g == null) return null;
    for (final c in g.clips) {
      if (c.trackIndex == track && c.sceneIndex == scene) return c;
    }
    return null;
  }
}

// ── Provider ──────────────────────────────────────────────────────────────────

final gridProvider =
    StateNotifierProvider<GridNotifier, GridState>((ref) => GridNotifier(ref));

// ── Notifier ──────────────────────────────────────────────────────────────────

class GridNotifier extends StateNotifier<GridState> {
  final Ref _ref;

  StreamSubscription<Grid>? _defSub;
  StreamSubscription<GridExecutionEvent>? _execSub;
  int _lastExecSeq = 0;

  GridNotifier(this._ref) : super(const GridState());

  SessionContext get _ctx => _ref.sessionCtx;
  SessionState get _session => _ref.read(sessionProvider);
  String get _sessionId => _ctx.sessionId;
  String get _token => _ctx.token;
  String get _gridId => state.grid?.gridId ?? 'main';

  /// Grid laden und beide Streams starten.
  Future<void> initialize() async {
    if (!_session.isInSession) return;
    state = state.copyWith(isLoading: true);
    try {
      final client = StageSyncClient.instance;
      final resp = await client.grid.getGrid(GetGridRequest()
        ..sessionId = _sessionId
        ..token = _token
        ..gridId = 'main');
      state = state.copyWith(grid: resp.grid, isLoading: false);
      _subscribeExecution();
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  // ── Transport ──────────────────────────────────────────────────────────────

  Future<void> launchClip(int track, int scene, {bool released = false}) async {
    if (!_session.isInSession) return;
    try {
      await StageSyncClient.instance.grid.launchClip(LaunchClipRequest()
        ..sessionId = _sessionId
        ..token = _token
        ..gridId = _gridId
        ..trackIndex = track
        ..sceneIndex = scene
        ..released = released
        ..commandId = _uuid.v4());
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  Future<void> launchScene(int scene) async {
    if (!_session.isInSession) return;
    try {
      await StageSyncClient.instance.grid.launchScene(LaunchSceneRequest()
        ..sessionId = _sessionId
        ..token = _token
        ..gridId = _gridId
        ..sceneIndex = scene
        ..commandId = _uuid.v4());
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  Future<void> stopTrack(int track) async {
    if (!_session.isInSession) return;
    await StageSyncClient.instance.grid.stopTrack(StopTrackRequest()
      ..sessionId = _sessionId
      ..token = _token
      ..gridId = _gridId
      ..trackIndex = track
      ..commandId = _uuid.v4());
  }

  Future<void> stopAll() async {
    if (!_session.isInSession) return;
    await StageSyncClient.instance.grid.stopAll(StopAllRequest()
      ..sessionId = _sessionId
      ..token = _token
      ..gridId = _gridId
      ..commandId = _uuid.v4());
  }

  // ── Editing ──────────────────────────────────────────────────────────────────

  Future<void> upsertClip(GridClip clip) async {
    if (!_session.isInSession) return;
    try {
      await StageSyncClient.instance.grid.upsertClip(UpsertClipRequest()
        ..sessionId = _sessionId
        ..token = _token
        ..gridId = _gridId
        ..clip = clip);
      // Optimistisch lokal aktualisieren; Definition-Stream bestätigt.
      final g = state.grid;
      if (g != null) {
        final updated = g.deepCopy();
        final idx = updated.clips.indexWhere((c) =>
            c.trackIndex == clip.trackIndex && c.sceneIndex == clip.sceneIndex);
        if (idx >= 0) {
          updated.clips[idx] = clip;
        } else {
          updated.clips.add(clip);
        }
        state = state.copyWith(grid: updated);
      }
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  Future<void> deleteClip(String clipId) async {
    if (!_session.isInSession) return;
    await StageSyncClient.instance.grid.deleteClip(DeleteClipRequest()
      ..sessionId = _sessionId
      ..token = _token
      ..gridId = _gridId
      ..clipId = clipId);
    final g = state.grid;
    if (g != null) {
      final updated = g.deepCopy()
        ..clips.removeWhere((c) => c.clipId == clipId);
      state = state.copyWith(grid: updated);
    }
  }

  // ── Streams ──────────────────────────────────────────────────────────────────

  void _subscribeExecution() {
    _cancelGracefully(_execSub);
    _lastExecSeq = 0;
    final req = WatchGridExecRequest()
      ..sessionId = _sessionId
      ..nodeId = _session.myNode!.nodeId
      ..token = _token
      ..gridId = _gridId;
    _execSub = StageSyncClient.instance.grid.watchGridExecution(req).listen(
        _handleExec,
        onError: (_) => _scheduleReconnect(),
        onDone: _scheduleReconnect);
  }

  void _handleExec(GridExecutionEvent event) {
    final seq = event.seq.toInt();
    if (seq != 0 && seq < _lastExecSeq) return;
    if (seq > _lastExecSeq) _lastExecSeq = seq;
    state = state.copyWith(
        runStates: applyGridExecutionEvent(state.runStates, event));
  }

  void _scheduleReconnect() {
    if (!_session.isInSession) return;
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted && _session.isInSession) _subscribeExecution();
    });
  }

  @override
  void dispose() {
    _cancelGracefully(_defSub);
    _cancelGracefully(_execSub);
    super.dispose();
  }

  static void _cancelGracefully(StreamSubscription? sub) {
    if (sub == null) return;
    Future.microtask(() => sub.cancel().catchError((_) {}));
  }
}
