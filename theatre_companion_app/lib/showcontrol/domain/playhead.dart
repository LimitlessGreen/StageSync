import 'package:meta/meta.dart';
import '../session/clock_sync.dart';

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

  /// Server start timestamps per running cue id.
  final Map<String, int> cueStartedServerMsByCueId;
  final String? nextCueId;
  final CueListPhase phase;

  /// Server-authoritative start time in Unix-ms (set by TYPE_CUE_STARTED event).
  final int? startedServerMs;

  /// Server-authoritative pause time in Unix-ms (freezes elapsed display).
  final int? pausedAtServerMs;

  /// Server-Zeit (Unix-ms) zu der die Cue natürlich endete (CUE_DONE).
  /// Gesetzt → phase = done, Timer eingefroren bei (doneServerMs - startedServerMs).
  final int? doneServerMs;

  /// Per-cue runtime state map. Key = cueId.
  final Map<String, CueRunState> perCue;

  /// Cue-IDs die per-Cue pausiert sind (server-autoritativ).
  /// Unabhängig von globaler CueList-Pause ([phase] == paused).
  final Set<String> perCuePausedIds;

  /// Einfrierzeitpunkte pro per-Cue-pausierter Cue in Unix-ms.
  /// Gesetzt wenn CUE_CUE_PAUSED eintrifft; gelöscht bei CUE_CUE_RESUMED/CUE_DONE.
  /// Wird von [effectiveNowMsForCue] genutzt um Fortschrittsbalken einzufrieren.
  final Map<String, int> perCuePausedAtServerMs;

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
  });

  static const PlayheadState empty = PlayheadState(cueListId: '');

  bool get isRunning => phase == CueListPhase.running;
  bool get isPaused  => phase == CueListPhase.paused;
  bool get isDone    => phase == CueListPhase.done;
  bool get isIdle    => phase == CueListPhase.idle;
  bool get isActive  => isRunning || isPaused || isDone;

  CueRunState? runStateFor(String cueId) => perCue[cueId];

  /// true wenn diese Cue per-Cue auf dem Audio-Node pausiert ist.
  /// Unabhängig von der globalen CueList-Pause.
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
      );
}

// ── Timing-Hilfsfunktion ──────────────────────────────────────────────────────

extension PlayheadTiming on PlayheadState {
  /// Effektive "jetzt"-Zeit in Unix-Millisekunden, Pause-Fade-Fenster berücksichtigt.
  ///
  /// - Running  → laufende Serveruhr
  /// - Paused, Fade noch aktiv (now < pausedAtServerMs) → laufende Serveruhr
  /// - Paused, Fade abgeschlossen (now ≥ pausedAtServerMs) → eingefroren bei pausedAtServerMs
  /// - Done     → eingefroren bei doneServerMs
  /// - pausedAtServerMs == null (Server-Event noch nicht angekommen) → laufende Serveruhr
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

  /// Effektive "jetzt"-Zeit für eine bestimmte Cue.
  ///
  /// Berücksichtigt zusätzlich per-Cue-Pause: wenn die Cue per-Cue pausiert ist,
  /// wird der Einfrierzeitpunkt zurückgegeben statt der laufenden Uhr.
  /// Für alle anderen Fälle: identisch mit [effectiveNowMs].
  int effectiveNowMsForCue(String cueId) {
    if (perCuePausedIds.contains(cueId)) {
      return perCuePausedAtServerMs[cueId] ?? effectiveNowMs();
    }
    return effectiveNowMs();
  }

  /// true solange der Widget-Ticker laufen muss.
  bool get needsTick => isRunning || isPaused;
}
