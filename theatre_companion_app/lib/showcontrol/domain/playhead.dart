import 'package:freezed_annotation/freezed_annotation.dart';
import '../session/clock_sync.dart';

part 'playhead.freezed.dart';

enum CueListPhase {
  idle,    // kein aktiver Eintrag, Timer = 0:00
  cueing,  // GO-Befehl gesendet, noch kein CUE_STARTED
  running, // Cue läuft, Timer zählt hoch
  paused,  // Cue pausiert, Timer eingefroren (gelb)
  done,    // Cue natürlich beendet, Timer eingefroren bei Enddauer (gedimmt)
  panic,
}

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

@freezed
class NodeExecState with _$NodeExecState {
  const NodeExecState._();

  const factory NodeExecState({
    required NodeExecPhase phase,
    double? bufferPct, // 0.0–1.0, meaningful only during [buffering]
    String? errorMessage,
  }) = _NodeExecState;

  static const NodeExecState idle = NodeExecState(phase: NodeExecPhase.idle);

  bool get isActive =>
      phase == NodeExecPhase.playing ||
      phase == NodeExecPhase.buffering ||
      phase == NodeExecPhase.preloading;

  bool get hasError => phase == NodeExecPhase.error;
}

@freezed
class CueRunState with _$CueRunState {
  const CueRunState._();

  const factory CueRunState({
    required CueLifecycle lifecycle,
    /// nodeId → per-node execution state.
    @Default({}) Map<String, NodeExecState> nodes,
    String? errorMessage,
  }) = _CueRunState;

  bool get hasNodeError =>
      nodes.values.any((n) => n.phase == NodeExecPhase.error);
}

// ── PlayheadState bleibt manuell ─────────────────────────────────────────────
// Die copyWith-Semantik von PlayheadState nutzt direktes null-Durchreichen
// (keine ?? Fallbacks) für nullable Felder, was sich von freezed unterscheidet.

class PlayheadState {
  final String cueListId;
  final String? activeCueId;

  /// All currently executing cue IDs (includes Group sub-cues running in parallel).
  final Set<String> runningCueIds;

  /// Server start timestamps per running cue id.
  final Map<String, int> cueStartedServerMsByCueId;
  final String? nextCueId;
  final CueListPhase phase;

  /// Server-authoritative start time in Unix-ms (set by TYPE_CUE_STARTED event).
  final int? startedServerMs;

  /// Server-authoritative pause time in Unix-ms (freezes elapsed display).
  final int? pausedAtServerMs;

  /// Server-Zeit (Unix-ms) zu der die Cue natürlich endete (CUE_DONE).
  final int? doneServerMs;

  /// Per-cue runtime state map. Key = cueId.
  final Map<String, CueRunState> perCue;

  /// Cue-IDs die per-Cue pausiert sind (server-autoritativ).
  final Set<String> perCuePausedIds;

  /// Einfrierzeitpunkte pro per-Cue-pausierter Cue in Unix-ms.
  final Map<String, int> perCuePausedAtServerMs;

  /// Zeitpunkt des letzten CUE_CUE_RESUMED pro Cue in Unix-ms.
  final Map<String, int> perCueResumedAtServerMs;

  const PlayheadState({
    required this.cueListId,
    this.activeCueId,
    this.runningCueIds = const {},
    this.cueStartedServerMsByCueId = const {},
    this.nextCueId,
    this.phase = CueListPhase.idle,
    this.startedServerMs,
    this.pausedAtServerMs,
    this.doneServerMs,
    this.perCue = const {},
    this.perCuePausedIds = const {},
    this.perCuePausedAtServerMs = const {},
    this.perCueResumedAtServerMs = const {},
  });

  static const PlayheadState empty = PlayheadState(cueListId: '');

  bool get isRunning => phase == CueListPhase.running;
  bool get isPaused  => phase == CueListPhase.paused;
  bool get isDone    => phase == CueListPhase.done;
  bool get isIdle    => phase == CueListPhase.idle;
  bool get isActive  => isRunning || isPaused || isDone;

  CueRunState? runStateFor(String cueId) => perCue[cueId];

  bool isCuePaused(String cueId) => perCuePausedIds.contains(cueId);

  PlayheadState copyWith({
    String? cueListId,
    String? activeCueId,
    Set<String>? runningCueIds,
    Map<String, int>? cueStartedServerMsByCueId,
    String? nextCueId,
    CueListPhase? phase,
    int? startedServerMs,
    int? pausedAtServerMs,
    int? doneServerMs,
    Map<String, CueRunState>? perCue,
    Set<String>? perCuePausedIds,
    Map<String, int>? perCuePausedAtServerMs,
    Map<String, int>? perCueResumedAtServerMs,
  }) =>
      PlayheadState(
        cueListId: cueListId ?? this.cueListId,
        activeCueId: activeCueId,
        runningCueIds: runningCueIds ?? this.runningCueIds,
        cueStartedServerMsByCueId:
            cueStartedServerMsByCueId ?? this.cueStartedServerMsByCueId,
        nextCueId: nextCueId,
        phase: phase ?? this.phase,
        startedServerMs: startedServerMs,
        pausedAtServerMs: pausedAtServerMs,
        doneServerMs: doneServerMs,
        perCue: perCue ?? this.perCue,
        perCuePausedIds: perCuePausedIds ?? this.perCuePausedIds,
        perCuePausedAtServerMs: perCuePausedAtServerMs ?? this.perCuePausedAtServerMs,
        perCueResumedAtServerMs: perCueResumedAtServerMs ?? this.perCueResumedAtServerMs,
      );
}

// ── Timing-Hilfsfunktion ──────────────────────────────────────────────────────

extension PlayheadTiming on PlayheadState {
  int effectiveNowMs() {
    if (isDone) return doneServerMs ?? ClockSync.instance.serverNow();
    if (isPaused) {
      final p = pausedAtServerMs;
      if (p == null) return ClockSync.instance.serverNow();
      final now = ClockSync.instance.serverNow();
      return now < p ? now : p;
    }
    return ClockSync.instance.serverNow();
  }

  int effectiveNowMsForCue(String cueId) {
    if (perCuePausedIds.contains(cueId)) {
      final frozenAt = perCuePausedAtServerMs[cueId];
      if (frozenAt == null) return effectiveNowMs();
      final now = ClockSync.instance.serverNow();
      return now < frozenAt ? now : frozenAt;
    }
    return effectiveNowMs();
  }

  bool isCueFading(String cueId) {
    if (!perCuePausedIds.contains(cueId)) return false;
    final frozenAt = perCuePausedAtServerMs[cueId];
    if (frozenAt == null) return false;
    return ClockSync.instance.serverNow() < frozenAt;
  }

  bool isCuePaused(String cueId) =>
      perCuePausedIds.contains(cueId) && !isCueFading(cueId);

  bool isCueResuming(String cueId, double resumeFadeMs) {
    if (resumeFadeMs <= 0) return false;
    final resumedAt = perCueResumedAtServerMs[cueId];
    if (resumedAt == null) return false;
    return ClockSync.instance.serverNow() < resumedAt + resumeFadeMs;
  }

  bool get needsTick => isRunning || isPaused;
}
