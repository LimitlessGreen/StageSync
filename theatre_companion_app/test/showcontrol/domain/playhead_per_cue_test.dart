import 'package:flutter_test/flutter_test.dart';
import 'package:theatre_companion_app/showcontrol/domain/playhead.dart';

void main() {
  const base = PlayheadState(cueListId: 'list-1');

  // ── isDone / isActive ─────────────────────────────────────────────────────

  group('PlayheadState phases', () {
    test('isDone true only for done phase', () {
      expect(base.copyWith(phase: CueListPhase.done).isDone, isTrue);
      expect(base.copyWith(phase: CueListPhase.running).isDone, isFalse);
      expect(base.copyWith(phase: CueListPhase.idle).isDone, isFalse);
    });

    test('isActive: true for running/paused/done', () {
      for (final phase in [
        CueListPhase.running,
        CueListPhase.paused,
        CueListPhase.done,
      ]) {
        expect(base.copyWith(phase: phase).isActive, isTrue,
            reason: '$phase should be active');
      }
    });

    test('isActive: false for idle/cueing/panic', () {
      for (final phase in [
        CueListPhase.idle,
        CueListPhase.cueing,
        CueListPhase.panic,
      ]) {
        expect(base.copyWith(phase: phase).isActive, isFalse,
            reason: '$phase should not be active');
      }
    });
  });

  // ── needsTick ─────────────────────────────────────────────────────────────

  group('PlayheadTiming.needsTick', () {
    test('true while running', () {
      expect(base.copyWith(phase: CueListPhase.running).needsTick, isTrue);
    });

    test('true while paused (fade still in progress)', () {
      expect(base.copyWith(phase: CueListPhase.paused).needsTick, isTrue);
    });

    test('false when idle', () {
      expect(base.copyWith(phase: CueListPhase.idle).needsTick, isFalse);
    });

    test('false when done', () {
      expect(base.copyWith(phase: CueListPhase.done).needsTick, isFalse);
    });
  });

  // ── isCuePaused ───────────────────────────────────────────────────────────

  group('PlayheadState.isCuePaused', () {
    test('false when perCuePausedIds is empty', () {
      expect(base.isCuePaused('cue-1'), isFalse);
    });

    test('true when cueId is in perCuePausedIds', () {
      final s = base.copyWith(perCuePausedIds: {'cue-1', 'cue-2'});
      expect(s.isCuePaused('cue-1'), isTrue);
      expect(s.isCuePaused('cue-2'), isTrue);
    });

    test('false for cueId not in perCuePausedIds', () {
      final s = base.copyWith(perCuePausedIds: {'cue-1'});
      expect(s.isCuePaused('cue-99'), isFalse);
    });

    test('copyWith replaces perCuePausedIds', () {
      final s = base.copyWith(perCuePausedIds: {'cue-1'});
      final s2 = s.copyWith(perCuePausedIds: {'cue-2', 'cue-3'});
      expect(s2.isCuePaused('cue-1'), isFalse);
      expect(s2.isCuePaused('cue-2'), isTrue);
    });
  });

  // ── perCue run states ─────────────────────────────────────────────────────

  group('PlayheadState.runStateFor', () {
    test('null for unknown cueId', () {
      expect(base.runStateFor('x'), isNull);
    });

    test('returns correct run state', () {
      const runState = CueRunState(lifecycle: CueLifecycle.running);
      final s = base.copyWith(perCue: {'cue-1': runState});
      expect(s.runStateFor('cue-1')?.lifecycle, CueLifecycle.running);
    });

    test('multiple cue states coexist', () {
      final s = base.copyWith(perCue: {
        'cue-a': const CueRunState(lifecycle: CueLifecycle.running),
        'cue-b': const CueRunState(lifecycle: CueLifecycle.paused),
      });
      expect(s.runStateFor('cue-a')?.lifecycle, CueLifecycle.running);
      expect(s.runStateFor('cue-b')?.lifecycle, CueLifecycle.paused);
      expect(s.runStateFor('cue-c'), isNull);
    });
  });

  // ── copyWith nullable clearing ────────────────────────────────────────────

  group('PlayheadState.copyWith nullable fields', () {
    test('activeCueId cleared between copyWiths', () {
      final s = base.copyWith(activeCueId: 'cue-1');
      expect(s.activeCueId, 'cue-1');
      // copyWith without activeCueId always resets to null (by design)
      final s2 = s.copyWith(phase: CueListPhase.idle);
      expect(s2.activeCueId, isNull);
    });

    test('startedServerMs cleared when not passed', () {
      final s = base.copyWith(startedServerMs: 1234);
      final s2 = s.copyWith(phase: CueListPhase.running);
      expect(s2.startedServerMs, isNull);
    });

    test('doneServerMs preserved only when explicitly set', () {
      final s = base.copyWith(
        phase: CueListPhase.done,
        doneServerMs: 9999,
      );
      expect(s.doneServerMs, 9999);
    });
  });

  // ── cueStartedServerMsByCueId ─────────────────────────────────────────────

  group('PlayheadState.cueStartedServerMsByCueId', () {
    test('empty by default', () {
      expect(base.cueStartedServerMsByCueId, isEmpty);
    });

    test('tracks multiple cues', () {
      final s = base.copyWith(cueStartedServerMsByCueId: {
        'cue-1': 1000,
        'cue-2': 1050,
      });
      expect(s.cueStartedServerMsByCueId['cue-1'], 1000);
      expect(s.cueStartedServerMsByCueId['cue-2'], 1050);
    });
  });
}
