import '../grpc/generated/stagesync/v1/grid.pb.dart';
import '../domain/grid_run_state.dart';

/// Reiner Reducer: wendet ein [GridExecutionEvent] auf die Map der Clip-Run-States
/// an. Frei von Streams/Riverpod, damit es ohne Server-Infrastruktur testbar ist.
/// Spiegelt das Muster von `applyExecutionEvent` im linearen Cue-System.
Map<String, GridClipRunState> applyGridExecutionEvent(
  Map<String, GridClipRunState> current,
  GridExecutionEvent event,
) {
  final next = Map<String, GridClipRunState>.from(current);

  switch (event.type) {
    case GridExecutionEvent_Type.GRID_SNAPSHOT:
      // Snapshot ersetzt den State vollständig: alle laufenden Clips als playing.
      next.clear();
      for (final id in event.runningClipIds) {
        next[id] = const GridClipRunState(lifecycle: ClipLifecycle.playing);
      }
      return next;

    case GridExecutionEvent_Type.CLIP_LAUNCHED:
      next[event.clipId] = GridClipRunState(
        lifecycle: ClipLifecycle.launched,
        startedServerMs: _startMs(event),
        lengthMs: event.clipLengthMs,
      );
      return next;

    case GridExecutionEvent_Type.CLIP_PLAYING:
      next[event.clipId] = GridClipRunState(
        lifecycle: ClipLifecycle.playing,
        startedServerMs: _startMs(event),
        lengthMs: event.clipLengthMs,
      );
      return next;

    case GridExecutionEvent_Type.CLIP_STOPPED:
      next.remove(event.clipId);
      return next;

    case GridExecutionEvent_Type.CLIP_DONE:
      next.remove(event.clipId);
      return next;

    case GridExecutionEvent_Type.CLIP_ERROR:
      next[event.clipId] = GridClipRunState(
        lifecycle: ClipLifecycle.error,
        error: event.errorMsg.isEmpty ? 'Fehler' : event.errorMsg,
      );
      return next;
  }

  return next;
}

int? _startMs(GridExecutionEvent event) {
  final ms = event.startedAtMs.toInt();
  return ms == 0 ? null : ms;
}
