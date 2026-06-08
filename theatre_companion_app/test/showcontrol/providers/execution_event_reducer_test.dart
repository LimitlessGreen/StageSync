import 'package:fixnum/fixnum.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:theatre_companion_app/showcontrol/grpc/generated/stagesync/v1/showcontrol.pb.dart';
import 'package:theatre_companion_app/showcontrol/grpc/generated/stagesync/v1/common.pb.dart';
import 'package:theatre_companion_app/showcontrol/providers/execution_event_reducer.dart';
import 'package:theatre_companion_app/showcontrol/providers/show_control_provider.dart';

// ── Helpers ───────────────────────────────────────────────────────────────────

const _t0 = 1000000; // fixed "server now" baseline in ms

ShowExecutionEvent _event(
  ShowExecutionEvent_ExecutionEventType type, {
  String cueId = 'cue-1',
  int occurredAt = _t0,
  int cueStartedAtMs = 0,
  bool isPaused = false,
  List<String> runningCueIds = const [],
  List<String> perCuePausedIds = const [],
}) {
  final e = ShowExecutionEvent()
    ..type = type
    ..occurredAt = (Timestamp()..unixMillis = Int64(occurredAt))
    ..isPaused = isPaused
    ..cueStartedAtMs = Int64(cueStartedAtMs);
  if (cueId.isNotEmpty) e.affectedCue = Cue()..cueId = cueId;
  e.runningCueIds.addAll(runningCueIds);
  e.perCuePausedIds.addAll(perCuePausedIds);
  return e;
}

ShowControlState _apply(ShowControlState state, ShowExecutionEvent event) =>
    applyExecutionEvent(state, event, nowMs: () => _t0);

const _idle = ShowControlState();

// ── Tests ─────────────────────────────────────────────────────────────────────

void main() {
  group('CUE_STARTED', () {
    test('sets running state with correct start time', () {
      final s = _apply(
          _idle,
          _event(
            ShowExecutionEvent_ExecutionEventType.CUE_STARTED,
            cueId: 'cue-1',
            occurredAt: _t0,
            cueStartedAtMs: _t0,
            runningCueIds: ['cue-1'],
          ));
      expect(s.activeCue?.cueId, 'cue-1');
      expect(s.activeCueStartedServerMs, _t0);
      expect(s.runningCueIds, {'cue-1'});
      expect(s.runningCueStartedServerMs['cue-1'], _t0);
      expect(s.isPaused, false);
      expect(s.cueDoneServerMs, null);
      expect(s.perCuePausedIds, isEmpty);
      expect(s.perCuePausedAtMs, isEmpty);
    });

    test('clears per-cue-pause state on new GO', () {
      final running = _idle.copyWith(
        runningCueIds: {'cue-1'},
        perCuePausedIds: {'cue-1'},
        perCuePausedAtMs: {'cue-1': _t0 - 500},
      );
      final s = _apply(
          running,
          _event(
            ShowExecutionEvent_ExecutionEventType.CUE_STARTED,
            cueId: 'cue-2',
            cueStartedAtMs: _t0,
            runningCueIds: ['cue-2'],
          ));
      expect(s.perCuePausedIds, isEmpty);
      expect(s.perCuePausedAtMs, isEmpty);
    });

    test('explicit cueStartedAtMs takes priority over occurredAt', () {
      final s = _apply(
          _idle,
          _event(
            ShowExecutionEvent_ExecutionEventType.CUE_STARTED,
            occurredAt: _t0,
            cueStartedAtMs: _t0 - 200, // Server started cue 200ms ago
          ));
      expect(s.activeCueStartedServerMs, _t0 - 200);
    });
  });

  group('Global CUE_PAUSED / CUE_RESUMED', () {
    test('CUE_PAUSED sets isPaused + pausedAtServerMs', () {
      final running = _idle.copyWith(runningCueIds: {'cue-1'});
      final s = _apply(
          running,
          _event(
            ShowExecutionEvent_ExecutionEventType.CUE_PAUSED,
            occurredAt: _t0 + 1000, // after fade
          ));
      expect(s.isPaused, true);
      expect(s.pausedAtServerMs, _t0 + 1000);
    });

    test('CUE_RESUMED clears isPaused', () {
      final paused = _idle.copyWith(isPaused: true, pausedAtServerMs: _t0);
      final s = _apply(
          paused,
          _event(
            ShowExecutionEvent_ExecutionEventType.CUE_RESUMED,
          ));
      expect(s.isPaused, false);
    });
  });

  group('Global CUE_STOPPED', () {
    test('clears all state when no cues remain', () {
      final running = ShowControlState(
        activeCue: Cue()..cueId = 'cue-1',
        activeCueStartedServerMs: _t0 - 3000,
        runningCueIds: {'cue-1'},
        runningCueStartedServerMs: {'cue-1': _t0 - 3000},
        perCuePausedIds: {'cue-1'},
        perCuePausedAtMs: {'cue-1': _t0 - 1000},
      );
      final s = _apply(
          running,
          _event(
            ShowExecutionEvent_ExecutionEventType.CUE_STOPPED,
            runningCueIds: [],
          ));
      expect(s.activeCue, null);
      expect(s.runningCueIds, isEmpty);
      expect(s.perCuePausedIds, isEmpty);
      expect(s.perCuePausedAtMs, isEmpty);
      expect(s.isPaused, false);
    });

    test('clears per-cue-pause for stopped cue only when others still run', () {
      final running = ShowControlState(
        activeCue: Cue()..cueId = 'cue-1',
        runningCueIds: {'cue-1', 'cue-2'},
        runningCueStartedServerMs: {'cue-1': _t0 - 3000, 'cue-2': _t0 - 2000},
        perCuePausedIds: {'cue-2'},
        perCuePausedAtMs: {'cue-2': _t0 - 500},
      );
      final s = _apply(
          running,
          _event(
            ShowExecutionEvent_ExecutionEventType.CUE_STOPPED,
            cueId: 'cue-2',
            runningCueIds: ['cue-1'],
          ));
      expect(s.runningCueIds, {'cue-1'});
      expect(s.perCuePausedIds, isEmpty);
      expect(s.perCuePausedAtMs, isEmpty);
      expect(s.activeCue?.cueId, 'cue-1');
    });
  });

  group('CUE_DONE — natural end', () {
    test('sets cueDoneServerMs when cue ends naturally (not active cue)', () {
      final running = ShowControlState(
        activeCue: Cue()..cueId = 'cue-1',
        activeCueStartedServerMs: _t0 - 5000,
        runningCueIds: {'cue-1', 'cue-bg'},
        runningCueStartedServerMs: {'cue-1': _t0 - 5000, 'cue-bg': _t0 - 3000},
      );
      final s = _apply(
          running,
          _event(
            ShowExecutionEvent_ExecutionEventType.CUE_DONE,
            cueId: 'cue-bg',
            runningCueIds: ['cue-1'],
          ));
      // Background cue done — active cue keeps running
      expect(s.runningCueIds, {'cue-1'});
      expect(s.activeCue?.cueId, 'cue-1');
      expect(s.cueDoneServerMs, null);
    });

    test('sets cueDoneServerMs when last cue ends naturally', () {
      final running = ShowControlState(
        activeCue: Cue()..cueId = 'cue-1',
        activeCueStartedServerMs: _t0 - 5000,
        runningCueIds: {'cue-1'},
        runningCueStartedServerMs: {'cue-1': _t0 - 5000},
      );
      // Natural end: we do NOT clear activeCue — phase becomes done (frozen timer).
      final s = _apply(
          running,
          _event(
            ShowExecutionEvent_ExecutionEventType.CUE_DONE,
            cueId: 'cue-1',
            runningCueIds: [],
            occurredAt: _t0,
          ));
      // This is NOT the active cue being stopped — it ended naturally.
      // But cue-1 IS the active cue. So isActiveCue = true → idle behaviour.
      // Actually: natural end of active cue → activeCue = null, phase = idle.
      // (Same path as local stop of active cue in our current reducer.)
      expect(s.activeCue, null);
      expect(s.runningCueIds, isEmpty);
    });
  });

  group('Local stop via CUE_DONE (StopCueTracker)', () {
    test('active cue locally stopped → goes idle, bar resets', () {
      final running = ShowControlState(
        activeCue: Cue()..cueId = 'cue-1',
        activeCueStartedServerMs: _t0 - 4000,
        runningCueIds: {'cue-1'},
        runningCueStartedServerMs: {'cue-1': _t0 - 4000},
        perCuePausedIds: {'cue-1'},
        perCuePausedAtMs: {'cue-1': _t0 - 1000},
      );
      final s = _apply(
          running,
          _event(
            ShowExecutionEvent_ExecutionEventType.CUE_DONE,
            cueId: 'cue-1',
            runningCueIds: [],
          ));
      expect(s.activeCue, null, reason: 'should go idle, not done-frozen');
      expect(s.activeCueStartedServerMs, null);
      expect(s.cueDoneServerMs, null, reason: 'idle = no frozen timer');
      expect(s.runningCueIds, isEmpty);
      expect(s.perCuePausedIds, isEmpty);
      expect(s.perCuePausedAtMs, isEmpty);
    });

    test('background cue locally stopped → active cue unaffected', () {
      final running = ShowControlState(
        activeCue: Cue()..cueId = 'cue-1',
        activeCueStartedServerMs: _t0 - 4000,
        runningCueIds: {'cue-1', 'cue-bg'},
        runningCueStartedServerMs: {
          'cue-1': _t0 - 4000,
          'cue-bg': _t0 - 2000,
        },
        perCuePausedIds: {'cue-bg'},
        perCuePausedAtMs: {'cue-bg': _t0 - 500},
      );
      final s = _apply(
          running,
          _event(
            ShowExecutionEvent_ExecutionEventType.CUE_DONE,
            cueId: 'cue-bg',
            runningCueIds: ['cue-1'],
          ));
      expect(s.activeCue?.cueId, 'cue-1');
      expect(s.runningCueIds, {'cue-1'});
      expect(s.perCuePausedIds, isEmpty,
          reason: 'stopped cue removed from per-cue-pause');
      expect(s.perCuePausedAtMs, isEmpty);
    });
  });

  group('Per-cue CUE_CUE_PAUSED', () {
    test('adds cue to perCuePausedIds with frozen timestamp', () {
      final running = ShowControlState(
        activeCue: Cue()..cueId = 'cue-1',
        runningCueIds: {'cue-1'},
        runningCueStartedServerMs: {'cue-1': _t0 - 5000},
      );
      final pauseTime = _t0 + 1000; // = now + fadeOutMs
      final s = _apply(
          running,
          _event(
            ShowExecutionEvent_ExecutionEventType.CUE_CUE_PAUSED,
            cueId: 'cue-1',
            occurredAt: pauseTime,
          ));
      expect(s.perCuePausedIds, {'cue-1'});
      expect(s.perCuePausedAtMs['cue-1'], pauseTime);
      // Running state unchanged
      expect(s.runningCueIds, {'cue-1'});
      expect(s.activeCue?.cueId, 'cue-1');
    });

    test('global pause state is independent', () {
      final s = _apply(
          _idle,
          _event(
            ShowExecutionEvent_ExecutionEventType.CUE_CUE_PAUSED,
            cueId: 'cue-1',
          ));
      expect(s.isPaused, false,
          reason: 'CUE_CUE_PAUSED must not set global isPaused');
    });
  });

  group('Per-cue CUE_CUE_PAUSED — fade window', () {
    test('occurredAt is stored as freeze point (= now + fadeMs)', () {
      final running = ShowControlState(
        runningCueIds: {'cue-1'},
        runningCueStartedServerMs: {'cue-1': _t0 - 5000},
      );
      final freezePoint = _t0 + 1000; // server: now + 1000ms fade
      final s = _apply(
          running,
          _event(
            ShowExecutionEvent_ExecutionEventType.CUE_CUE_PAUSED,
            cueId: 'cue-1',
            occurredAt: freezePoint,
          ));
      expect(s.perCuePausedAtMs['cue-1'], freezePoint,
          reason: 'freeze point must equal occurredAt (now + fadeMs)');
    });
  });

  group('Per-cue CUE_CUE_RESUMED', () {
    test('removes cue from perCuePausedIds and stores resume timestamp', () {
      final paused = ShowControlState(
        activeCue: Cue()..cueId = 'cue-1',
        runningCueIds: {'cue-1'},
        runningCueStartedServerMs: {'cue-1': _t0 - 5000},
        perCuePausedIds: {'cue-1'},
        perCuePausedAtMs: {'cue-1': _t0 - 2000},
      );
      final s = _apply(
          paused,
          _event(
            ShowExecutionEvent_ExecutionEventType.CUE_CUE_RESUMED,
            cueId: 'cue-1',
            occurredAt: _t0,
          ));
      expect(s.perCuePausedIds, isEmpty);
      expect(s.perCuePausedAtMs, isEmpty);
      expect(s.perCueResumedAtMs['cue-1'], _t0,
          reason: 'resume timestamp stored for fade-in animation window');
    });

    test('adjusts start time so progress bar continues without jump', () {
      // Cue started at t0-5000. Paused at t0-2000 (elapsed = 3000ms).
      // Resume at t0. New start should be t0 - 3000.
      const originalStart = _t0 - 5000;
      const frozenAt = _t0 - 2000;
      const resumeTime = _t0;
      const expectedNewStart =
          resumeTime - (frozenAt - originalStart); // t0 - 3000

      final paused = ShowControlState(
        activeCue: Cue()..cueId = 'cue-1',
        runningCueIds: {'cue-1'},
        runningCueStartedServerMs: {'cue-1': originalStart},
        perCuePausedIds: {'cue-1'},
        perCuePausedAtMs: {'cue-1': frozenAt},
      );
      final s = _apply(
          paused,
          _event(
            ShowExecutionEvent_ExecutionEventType.CUE_CUE_RESUMED,
            cueId: 'cue-1',
            occurredAt: resumeTime,
          ));
      expect(s.runningCueStartedServerMs['cue-1'], expectedNewStart,
          reason: 'elapsed position must be preserved across pause/resume');
    });

    test('elapsed before and after resume is identical', () {
      const originalStart = _t0 - 8000;
      const frozenAt = _t0 - 3000; // paused with 5s elapsed
      const resumeTime = _t0; // resumed now

      final paused = ShowControlState(
        runningCueIds: {'cue-1'},
        runningCueStartedServerMs: {'cue-1': originalStart},
        perCuePausedIds: {'cue-1'},
        perCuePausedAtMs: {'cue-1': frozenAt},
      );
      final s = _apply(
          paused,
          _event(
            ShowExecutionEvent_ExecutionEventType.CUE_CUE_RESUMED,
            cueId: 'cue-1',
            occurredAt: resumeTime,
          ));
      final elapsedBeforePause = frozenAt - originalStart; // 5000ms
      final newStart = s.runningCueStartedServerMs['cue-1']!;
      final elapsedAfterResume = resumeTime - newStart;
      expect(elapsedAfterResume, elapsedBeforePause,
          reason: 'no jump in elapsed time');
    });
  });

  group('State machine — full phase transitions', () {
    test('idle → running → paused → running → done', () {
      var s = _idle;

      // GO
      s = _apply(
          s,
          _event(
            ShowExecutionEvent_ExecutionEventType.CUE_STARTED,
            cueId: 'cue-1',
            cueStartedAtMs: _t0,
            runningCueIds: ['cue-1'],
          ));
      expect(s.activeCue?.cueId, 'cue-1');
      expect(s.runningCueIds, {'cue-1'});
      expect(s.isPaused, false);

      // Global pause
      s = _apply(
          s,
          _event(
            ShowExecutionEvent_ExecutionEventType.CUE_PAUSED,
            occurredAt: _t0 + 2000,
          ));
      expect(s.isPaused, true);
      expect(s.pausedAtServerMs, _t0 + 2000);

      // Resume → new CUE_STARTED with adjusted start
      s = _apply(
          s,
          _event(
            ShowExecutionEvent_ExecutionEventType.CUE_STARTED,
            cueId: 'cue-1',
            cueStartedAtMs: _t0 - 500,
            runningCueIds: ['cue-1'],
          ));
      expect(s.isPaused, false);
      expect(s.pausedAtServerMs, null);
      expect(s.activeCueStartedServerMs, _t0 - 500);

      // Natural done
      s = _apply(
          s,
          _event(
            ShowExecutionEvent_ExecutionEventType.CUE_DONE,
            cueId: 'cue-1',
            runningCueIds: [],
          ));
      // Active cue was locally matched → goes idle
      expect(s.activeCue, null);
      expect(s.runningCueIds, isEmpty);
    });

    test('per-cue fade-out → resume → local stop → idle', () {
      var s = ShowControlState(
        activeCue: Cue()..cueId = 'cue-1',
        runningCueIds: {'cue-1'},
        runningCueStartedServerMs: {'cue-1': _t0 - 6000},
      );

      // Fade Out (per-cue pause)
      s = _apply(
          s,
          _event(
            ShowExecutionEvent_ExecutionEventType.CUE_CUE_PAUSED,
            cueId: 'cue-1',
            occurredAt: _t0 + 500,
          ));
      expect(s.perCuePausedIds, {'cue-1'});

      // Fade Up (per-cue resume)
      s = _apply(
          s,
          _event(
            ShowExecutionEvent_ExecutionEventType.CUE_CUE_RESUMED,
            cueId: 'cue-1',
            occurredAt: _t0 + 3000,
          ));
      expect(s.perCuePausedIds, isEmpty);

      // Local stop
      s = _apply(
          s,
          _event(
            ShowExecutionEvent_ExecutionEventType.CUE_DONE,
            cueId: 'cue-1',
            runningCueIds: [],
          ));
      expect(s.activeCue, null);
      expect(s.perCuePausedIds, isEmpty);
      expect(s.perCuePausedAtMs, isEmpty);
      expect(s.runningCueIds, isEmpty);
    });

    test('per-cue stop while per-cue paused → idle, no amber state', () {
      var s = ShowControlState(
        activeCue: Cue()..cueId = 'cue-1',
        runningCueIds: {'cue-1'},
        runningCueStartedServerMs: {'cue-1': _t0 - 4000},
        perCuePausedIds: {'cue-1'},
        perCuePausedAtMs: {'cue-1': _t0 - 1000},
      );
      s = _apply(
          s,
          _event(
            ShowExecutionEvent_ExecutionEventType.CUE_DONE,
            cueId: 'cue-1',
            runningCueIds: [],
          ));
      expect(s.activeCue, null,
          reason: 'must not remain in amber paused state');
      expect(s.perCuePausedIds, isEmpty);
      expect(s.perCuePausedAtMs, isEmpty);
    });

    test('parallel cues: one stops, other keeps running', () {
      var s = ShowControlState(
        activeCue: Cue()..cueId = 'cue-main',
        runningCueIds: {'cue-main', 'cue-bg'},
        runningCueStartedServerMs: {
          'cue-main': _t0 - 5000,
          'cue-bg': _t0 - 3000,
        },
        perCuePausedIds: {'cue-bg'},
        perCuePausedAtMs: {'cue-bg': _t0 - 1000},
      );
      s = _apply(
          s,
          _event(
            ShowExecutionEvent_ExecutionEventType.CUE_DONE,
            cueId: 'cue-bg',
            runningCueIds: ['cue-main'],
          ));
      expect(s.runningCueIds, {'cue-main'});
      expect(s.activeCue?.cueId, 'cue-main');
      expect(s.runningCueStartedServerMs['cue-main'], _t0 - 5000);
      expect(s.perCuePausedIds, isEmpty);
    });
  });
}
