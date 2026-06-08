import 'package:flutter_test/flutter_test.dart';
import 'package:theatre_companion_app/showcontrol/domain/playhead.dart';

void main() {
  group('NodeExecState', () {
    test('idle constant has idle phase', () {
      expect(NodeExecState.idle.phase, NodeExecPhase.idle);
    });

    test('isActive for playing/buffering/preloading', () {
      for (final phase in [
        NodeExecPhase.playing,
        NodeExecPhase.buffering,
        NodeExecPhase.preloading,
      ]) {
        expect(NodeExecState(phase: phase).isActive, isTrue,
            reason: '$phase should be active');
      }
    });

    test('isActive false for idle/done/error/degraded', () {
      for (final phase in [
        NodeExecPhase.idle,
        NodeExecPhase.done,
        NodeExecPhase.error,
        NodeExecPhase.degraded,
        NodeExecPhase.awaitingAsset,
      ]) {
        expect(NodeExecState(phase: phase).isActive, isFalse,
            reason: '$phase should not be active');
      }
    });

    test('hasError only for error phase', () {
      expect(NodeExecState(phase: NodeExecPhase.error).hasError, isTrue);
      expect(NodeExecState(phase: NodeExecPhase.playing).hasError, isFalse);
    });

    test('copyWith preserves unset fields', () {
      final s = NodeExecState(phase: NodeExecPhase.buffering, bufferPct: 0.5);
      final u = s.copyWith(bufferPct: 0.9);
      expect(u.phase, NodeExecPhase.buffering);
      expect(u.bufferPct, 0.9);
    });
  });

  group('CueRunState', () {
    test('hasNodeError true when any node is in error', () {
      final state = CueRunState(
        lifecycle: CueLifecycle.running,
        nodes: {
          'node-1': NodeExecState(phase: NodeExecPhase.playing),
          'node-2': NodeExecState(phase: NodeExecPhase.error),
        },
      );
      expect(state.hasNodeError, isTrue);
    });

    test('hasNodeError false when all nodes healthy', () {
      final state = CueRunState(
        lifecycle: CueLifecycle.running,
        nodes: {
          'node-1': NodeExecState(phase: NodeExecPhase.playing),
          'node-2': NodeExecState(phase: NodeExecPhase.done),
        },
      );
      expect(state.hasNodeError, isFalse);
    });
  });

  group('PlayheadState', () {
    const idle = PlayheadState(cueListId: 'list-1');

    test('empty has empty cueListId and idle phase', () {
      expect(PlayheadState.empty.cueListId, '');
      expect(PlayheadState.empty.isIdle, isTrue);
    });

    test('isIdle/isRunning/isPaused predicates', () {
      expect(idle.isIdle, isTrue);
      expect(idle.isRunning, isFalse);
      expect(idle.isPaused, isFalse);

      final running = idle.copyWith(phase: CueListPhase.running);
      expect(running.isRunning, isTrue);
      expect(running.isIdle, isFalse);

      final paused = idle.copyWith(phase: CueListPhase.paused);
      expect(paused.isPaused, isTrue);
    });

    test('copyWith sets activeCueId and nextCueId independently', () {
      final state = idle.copyWith(
          phase: CueListPhase.running,
          activeCueId: 'cue-1',
          nextCueId: 'cue-2');
      expect(state.activeCueId, 'cue-1');
      expect(state.nextCueId, 'cue-2');
      expect(state.phase, CueListPhase.running);
    });

    test('copyWith clears nullable fields when not passed', () {
      final withCue = idle.copyWith(activeCueId: 'cue-1');
      // copyWith without activeCueId resets to null (nullable field)
      final cleared = withCue.copyWith(phase: CueListPhase.idle);
      expect(cleared.activeCueId, isNull);
    });

    test('runStateFor returns null for unknown cueId', () {
      expect(idle.runStateFor('unknown'), isNull);
    });

    test('runStateFor returns correct state', () {
      final runState = CueRunState(lifecycle: CueLifecycle.running);
      final state = idle.copyWith(perCue: {'cue-1': runState});
      expect(state.runStateFor('cue-1')?.lifecycle, CueLifecycle.running);
    });

    test('runningCueIds tracks parallel execution', () {
      final state = idle.copyWith(
          phase: CueListPhase.running,
          runningCueIds: {'cue-a', 'cue-b', 'cue-c'});
      expect(state.runningCueIds, hasLength(3));
      expect(state.runningCueIds, contains('cue-b'));
    });
  });
}
