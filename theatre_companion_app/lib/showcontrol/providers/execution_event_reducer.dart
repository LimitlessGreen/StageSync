import '../grpc/generated/stagesync/v1/showcontrol.pb.dart';
import '../session/clock_sync.dart';
import 'show_control_provider.dart';

/// Pure function: applies one [ShowExecutionEvent] to [state] and returns
/// the new state. No side-effects, no gRPC, no timers — fully unit-testable.
///
/// The notifier calls this instead of mutating state inline so that every
/// state transition can be tested without a Flutter widget tree or mock streams.
ShowControlState applyExecutionEvent(
  ShowControlState state,
  ShowExecutionEvent event, {
  /// Injectable clock — pass a fixed value in tests.
  int Function()? nowMs,
}) {
  final now = nowMs ?? ClockSync.instance.serverNow;

  int eventMs() {
    if (event.hasOccurredAt()) {
      final ms = event.occurredAt.unixMillis.toInt();
      if (ms != 0) return ms;
    }
    return now();
  }

  int startMs() {
    final explicit = event.cueStartedAtMs.toInt();
    return explicit != 0 ? explicit : eventMs();
  }

  switch (event.type) {
    // ── Snapshot ────────────────────────────────────────────────────────────
    case ShowExecutionEvent_ExecutionEventType.EXECUTION_SNAPSHOT:
      final running = event.runningCueIds.isNotEmpty
          ? event.runningCueIds.toSet()
          : <String>{
              ...state.runningCueIds,
              if (event.hasAffectedCue()) event.affectedCue.cueId,
            };
      final starts = Map<String, int>.from(state.runningCueStartedServerMs);
      if (event.hasAffectedCue()) starts[event.affectedCue.cueId] = startMs();
      if (event.runningCueIds.isNotEmpty) {
        starts.removeWhere((id, _) => !running.contains(id));
      }
      final perCuePaused = event.perCuePausedIds.isNotEmpty
          ? event.perCuePausedIds.toSet()
          : state.perCuePausedIds;

      if (event.hasAffectedCue()) {
        return state.copyWith(
          isPaused: event.isPaused,
          activeCue: event.affectedCue,
          activeCueStartedServerMs: startMs(),
          runningCueIds: running,
          runningCueStartedServerMs: starts,
          perCuePausedIds: perCuePaused,
        );
      }
      return state.copyWith(
        isPaused: event.isPaused,
        runningCueIds: running,
        runningCueStartedServerMs: starts,
        perCuePausedIds: perCuePaused,
      );

    // ── CUE_STARTED ─────────────────────────────────────────────────────────
    case ShowExecutionEvent_ExecutionEventType.CUE_STARTED:
      final ms = startMs();
      final running = event.runningCueIds.isNotEmpty
          ? event.runningCueIds.toSet()
          : <String>{
              ...state.runningCueIds,
              if (event.hasAffectedCue()) event.affectedCue.cueId,
            };
      final starts = Map<String, int>.from(state.runningCueStartedServerMs);
      if (event.hasAffectedCue()) starts[event.affectedCue.cueId] = ms;
      starts.removeWhere((id, _) => !running.contains(id));

      return state.copyWith(
        isPaused: false,
        activeCue: event.hasAffectedCue() ? event.affectedCue : state.activeCue,
        activeCueStartedServerMs: ms,
        pausedAtServerMs: null,
        cueDoneServerMs: null,
        runningCueIds: running,
        runningCueStartedServerMs: starts,
        perCuePausedIds: const {},
        perCuePausedAtMs: const {},
        perCueResumedAtMs: const {},
      );

    // ── Global PAUSE / RESUME ────────────────────────────────────────────────
    case ShowExecutionEvent_ExecutionEventType.CUE_PAUSED:
      return state.copyWith(
        isPaused: true,
        pausedAtServerMs: eventMs(),
      );
    case ShowExecutionEvent_ExecutionEventType.CUE_RESUMED:
      return state.copyWith(isPaused: false);

    // ── Global STOP ──────────────────────────────────────────────────────────
    case ShowExecutionEvent_ExecutionEventType.CUE_STOPPED:
      final stoppedId = event.hasAffectedCue() ? event.affectedCue.cueId : '';
      final running = event.runningCueIds.isNotEmpty
          ? event.runningCueIds.toSet()
          : <String>{...state.runningCueIds}..remove(stoppedId);
      final starts = Map<String, int>.from(state.runningCueStartedServerMs)
        ..removeWhere((id, _) => !running.contains(id));
      final perCuePaused = <String>{...state.perCuePausedIds}
        ..removeWhere((id) => !running.contains(id));
      final perCuePausedAt = Map<String, int>.from(state.perCuePausedAtMs)
        ..removeWhere((id, _) => !running.contains(id));

      Cue? nextActive;
      if (running.isNotEmpty) {
        if (stoppedId.isNotEmpty && state.activeCue?.cueId == stoppedId) {
          final fallbackId = running.first;
          for (final c in (state.cueList?.cues ?? const <Cue>[])) {
            if (c.cueId == fallbackId) { nextActive = c; break; }
          }
        } else {
          nextActive = state.activeCue;
        }
      }

      final stoppedResumedAt = Map<String, int>.from(state.perCueResumedAtMs)
        ..removeWhere((id, _) => !running.contains(id));
      return state.copyWith(
        activeCue: nextActive,
        isPaused: false,
        activeCueStartedServerMs: running.isNotEmpty ? state.activeCueStartedServerMs : null,
        pausedAtServerMs: null,
        cueDoneServerMs: running.isEmpty ? eventMs() : null,
        runningCueIds: running,
        runningCueStartedServerMs: starts,
        perCuePausedIds: perCuePaused,
        perCuePausedAtMs: perCuePausedAt,
        perCueResumedAtMs: stoppedResumedAt,
      );

    // ── CUE_DONE / CUE_ERROR (natürliches Ende oder lokaler Stop) ────────────
    case ShowExecutionEvent_ExecutionEventType.CUE_DONE:
    case ShowExecutionEvent_ExecutionEventType.CUE_ERROR:
      final doneId = event.hasAffectedCue() ? event.affectedCue.cueId : '';
      final running = event.runningCueIds.isNotEmpty
          ? event.runningCueIds.toSet()
          : <String>{...state.runningCueIds}..remove(doneId);
      final perCuePaused = <String>{...state.perCuePausedIds}..remove(doneId);
      final perCuePausedAt = Map<String, int>.from(state.perCuePausedAtMs)..remove(doneId);
      final isActiveCue = doneId.isNotEmpty && state.activeCue?.cueId == doneId;

      if (running.isEmpty) {
        return state.copyWith(
          activeCue: isActiveCue ? null : state.activeCue,
          activeCueStartedServerMs: isActiveCue ? null : state.activeCueStartedServerMs,
          runningCueIds: const {},
          runningCueStartedServerMs: const {},
          cueDoneServerMs: isActiveCue ? null : eventMs(),
          perCuePausedIds: const {},
          perCuePausedAtMs: const {},
          perCueResumedAtMs: const {},
        );
      }

      final starts = Map<String, int>.from(state.runningCueStartedServerMs)
        ..removeWhere((id, _) => !running.contains(id));
      final doneResumedAt = Map<String, int>.from(state.perCueResumedAtMs)..remove(doneId);
      return state.copyWith(
        runningCueIds: running,
        runningCueStartedServerMs: starts,
        perCuePausedIds: perCuePaused,
        perCuePausedAtMs: perCuePausedAt,
        perCueResumedAtMs: doneResumedAt,
      );

    // ── Per-Cue PAUSE ────────────────────────────────────────────────────────
    case ShowExecutionEvent_ExecutionEventType.CUE_CUE_PAUSED:
      final cueId = event.hasAffectedCue() ? event.affectedCue.cueId : '';
      final pausedIds = event.perCuePausedIds.isNotEmpty
          ? event.perCuePausedIds.toSet()
          : <String>{...state.perCuePausedIds, if (cueId.isNotEmpty) cueId};
      final pausedAt = Map<String, int>.from(state.perCuePausedAtMs);
      if (cueId.isNotEmpty) pausedAt[cueId] = eventMs();
      return state.copyWith(perCuePausedIds: pausedIds, perCuePausedAtMs: pausedAt);

    // ── Per-Cue RESUME ───────────────────────────────────────────────────────
    case ShowExecutionEvent_ExecutionEventType.CUE_CUE_RESUMED:
      final cueId = event.hasAffectedCue() ? event.affectedCue.cueId : '';
      final resumeTime = eventMs();
      final starts = Map<String, int>.from(state.runningCueStartedServerMs);
      final frozenAt = state.perCuePausedAtMs[cueId];
      final origStart = starts[cueId];
      if (frozenAt != null && origStart != null) {
        // Adjust start so elapsed position is preserved (no jump).
        // elapsed_at_pause = frozenAt - origStart; newStart = resumeTime - elapsed
        starts[cueId] = resumeTime - (frozenAt - origStart);
      }
      final resumedIds = event.perCuePausedIds.isNotEmpty
          ? event.perCuePausedIds.toSet()
          : <String>{...state.perCuePausedIds}..remove(cueId);
      final pausedAt = Map<String, int>.from(state.perCuePausedAtMs)..remove(cueId);
      // Store resume time for fade-in animation window in the UI.
      final resumedAt = Map<String, int>.from(state.perCueResumedAtMs);
      if (cueId.isNotEmpty) resumedAt[cueId] = resumeTime;
      return state.copyWith(
        perCuePausedIds: resumedIds,
        perCuePausedAtMs: pausedAt,
        perCueResumedAtMs: resumedAt,
        runningCueStartedServerMs: starts,
      );

    default:
      return state;
  }
}
