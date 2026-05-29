import 'package:meta/meta.dart';

enum CueListPhase { idle, cueing, running, paused, panic }

enum CueLifecycle { armed, loading, running, paused, done, error }

/// Per-node execution phase for a single cue.
///
/// Fachlich distinct phases — each requires a different operator response:
///   [awaitingAsset]  → MediaSync hasn't delivered the file yet; node cannot preload.
///   [preloading]     → File is local; engine is loading it from disk to memory.
///   [buffering]      → File is in memory; engine is preparing the playback pipeline.
///   [degraded]       → Playing but with reduced quality (e.g. fallback device).
enum NodeExecPhase {
  idle,
  awaitingAsset,
  preloading,
  buffering,
  ready,
  playing,
  paused,
  done,
  degraded,
  error,
}

@immutable
class NodeExecState {
  final NodeExecPhase phase;
  final double? bufferPct; // 0.0–1.0, meaningful only during [buffering]
  final String? errorMessage;

  const NodeExecState({
    required this.phase,
    this.bufferPct,
    this.errorMessage,
  });

  static const NodeExecState idle =
      NodeExecState(phase: NodeExecPhase.idle);

  bool get isActive =>
      phase == NodeExecPhase.playing ||
      phase == NodeExecPhase.buffering ||
      phase == NodeExecPhase.preloading;

  bool get hasError => phase == NodeExecPhase.error;

  NodeExecState copyWith({
    NodeExecPhase? phase,
    double? bufferPct,
    String? errorMessage,
  }) =>
      NodeExecState(
        phase: phase ?? this.phase,
        bufferPct: bufferPct ?? this.bufferPct,
        errorMessage: errorMessage ?? this.errorMessage,
      );
}

@immutable
class CueRunState {
  final CueLifecycle lifecycle;

  /// nodeId → per-node execution state.
  final Map<String, NodeExecState> nodes;
  final String? errorMessage;

  const CueRunState({
    required this.lifecycle,
    this.nodes = const {},
    this.errorMessage,
  });

  CueRunState copyWith({
    CueLifecycle? lifecycle,
    Map<String, NodeExecState>? nodes,
    String? errorMessage,
  }) =>
      CueRunState(
        lifecycle: lifecycle ?? this.lifecycle,
        nodes: nodes ?? this.nodes,
        errorMessage: errorMessage ?? this.errorMessage,
      );

  bool get hasNodeError =>
      nodes.values.any((n) => n.phase == NodeExecPhase.error);
}

@immutable
class PlayheadState {
  final String cueListId;
  final String? activeCueId;

  /// All currently executing cue IDs (includes Group sub-cues running in parallel).
  final Set<String> runningCueIds;
  final String? nextCueId;
  final CueListPhase phase;

  /// Server-authoritative start time in Unix-ms (set by TYPE_CUE_STARTED event).
  final int? startedServerMs;

  /// Server-authoritative pause time in Unix-ms (freezes elapsed display).
  final int? pausedAtServerMs;

  /// Per-cue runtime state map. Key = cueId.
  final Map<String, CueRunState> perCue;

  const PlayheadState({
    required this.cueListId,
    this.activeCueId,
    this.runningCueIds = const {},
    this.nextCueId,
    this.phase = CueListPhase.idle,
    this.startedServerMs,
    this.pausedAtServerMs,
    this.perCue = const {},
  });

  static const PlayheadState empty = PlayheadState(cueListId: '');

  bool get isRunning => phase == CueListPhase.running;
  bool get isPaused  => phase == CueListPhase.paused;
  bool get isIdle    => phase == CueListPhase.idle;

  CueRunState? runStateFor(String cueId) => perCue[cueId];

  PlayheadState copyWith({
    String? cueListId,
    String? activeCueId,
    Set<String>? runningCueIds,
    String? nextCueId,
    CueListPhase? phase,
    int? startedServerMs,
    int? pausedAtServerMs,
    Map<String, CueRunState>? perCue,
  }) =>
      PlayheadState(
        cueListId: cueListId ?? this.cueListId,
        // Nullable fields: pass sentinel `Object()` trick avoided via named params
        activeCueId: activeCueId,
        runningCueIds: runningCueIds ?? this.runningCueIds,
        nextCueId: nextCueId,
        phase: phase ?? this.phase,
        startedServerMs: startedServerMs,
        pausedAtServerMs: pausedAtServerMs,
        perCue: perCue ?? this.perCue,
      );
}
