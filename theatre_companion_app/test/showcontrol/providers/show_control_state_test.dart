import 'package:flutter_test/flutter_test.dart';
import 'package:theatre_companion_app/showcontrol/grpc/generated/stagesync/v1/showcontrol.pb.dart';
import 'package:theatre_companion_app/showcontrol/domain/node_status.dart';
import 'package:theatre_companion_app/showcontrol/providers/show_control_provider.dart';

void main() {
  // ── ShowControlState.copyWith ────────────────────────────────────────────────

  group('ShowControlState.copyWith', () {
    final baseState = ShowControlState(
      cueList: CueList()
        ..cueListId = 'main'
        ..name = 'Main',
      activeCue: Cue()..cueId = 'cue-1',
      activeCueStartedServerMs: 1000,
      pausedAtServerMs: 2000,
      isPaused: true,
      runningCueIds: const {'cue-1'},
    );

    test('only updates specified fields', () {
      final updated = baseState.copyWith(isPaused: false);
      expect(updated.isPaused, isFalse);
      expect(updated.activeCue?.cueId, 'cue-1'); // unchanged
      expect(updated.activeCueStartedServerMs, 1000);
    });

    test('can clear nullable fields via sentinel', () {
      final cleared = baseState.copyWith(
        activeCue: null,
        activeCueStartedServerMs: null,
        pausedAtServerMs: null,
      );
      expect(cleared.activeCue, isNull);
      expect(cleared.activeCueStartedServerMs, isNull);
      expect(cleared.pausedAtServerMs, isNull);
    });

    test('does not clear nullable fields when not passed', () {
      final unchanged = baseState.copyWith(isPaused: false);
      expect(unchanged.activeCue, isNotNull);
      expect(unchanged.activeCueStartedServerMs, 1000);
    });

    test('updates runningCueIds', () {
      final updated = baseState.copyWith(runningCueIds: const {'cue-1', 'cue-2'});
      expect(updated.runningCueIds, {'cue-1', 'cue-2'});
    });

    test('clears to empty state on stop', () {
      final stopped = baseState.copyWith(
        activeCue: null,
        isPaused: false,
        activeCueStartedServerMs: null,
        pausedAtServerMs: null,
        runningCueIds: const {},
      );
      expect(stopped.activeCue, isNull);
      expect(stopped.isPaused, isFalse);
      expect(stopped.activeCueStartedServerMs, isNull);
      expect(stopped.pausedAtServerMs, isNull);
      expect(stopped.runningCueIds, isEmpty);
    });
  });

  // ── ShowControlState defaults ────────────────────────────────────────────────

  group('ShowControlState defaults', () {
    const empty = ShowControlState();

    test('starts with no cueList', () => expect(empty.cueList, isNull));
    test('starts not loading', () => expect(empty.isLoading, isFalse));
    test('starts not paused', () => expect(empty.isPaused, isFalse));
    test('starts with empty runningCueIds', () => expect(empty.runningCueIds, isEmpty));
    test('starts with no error', () => expect(empty.error, isNull));
  });

  // ── Execution event seq deduplication (unit-level) ───────────────────────────
  // These tests verify the seq guard logic that _handleExecutionEvent applies.

  group('seq deduplication logic', () {
    // Simulate what the notifier does: skip if seq < lastSeq, accept if >=.
    int lastSeq = 0;

    bool shouldAccept(int seq) {
      if (seq != 0 && seq < lastSeq) return false;
      if (seq > lastSeq) lastSeq = seq;
      return true;
    }

    setUp(() => lastSeq = 0);

    test('first event always accepted', () => expect(shouldAccept(1), isTrue));

    test('same seq accepted (snapshot idempotency)', () {
      shouldAccept(5);
      expect(shouldAccept(5), isTrue);
    });

    test('lower seq rejected', () {
      shouldAccept(10);
      expect(shouldAccept(9), isFalse);
    });

    test('higher seq accepted and updates lastSeq', () {
      shouldAccept(5);
      expect(shouldAccept(6), isTrue);
      expect(shouldAccept(4), isFalse); // now 6 is last
    });

    test('seq=0 always accepted (no-seq events)', () {
      shouldAccept(10);
      expect(shouldAccept(0), isTrue);
    });
  });

  // ── ShowExecutionEvent type handling ─────────────────────────────────────────

  group('ShowExecutionEvent type mapping', () {
    test('EXECUTION_SNAPSHOT type has expected int value', () {
      expect(
        ShowExecutionEvent_ExecutionEventType.EXECUTION_SNAPSHOT.value,
        0,
      );
    });

    test('CUE_STARTED type has expected int value', () {
      expect(ShowExecutionEvent_ExecutionEventType.CUE_STARTED.value, 1);
    });

    test('CUE_STOPPED type has expected int value', () {
      expect(ShowExecutionEvent_ExecutionEventType.CUE_STOPPED.value, 4);
    });
  });

  // ── ShowDefinitionEvent type mapping ─────────────────────────────────────────

  group('ShowDefinitionEvent type mapping', () {
    test('DEFINITION_SNAPSHOT has int value 0', () {
      expect(ShowDefinitionEvent_DefinitionEventType.DEFINITION_SNAPSHOT.value, 0);
    });

    test('CUE_LIST_CHANGED has int value 1', () {
      expect(ShowDefinitionEvent_DefinitionEventType.CUE_LIST_CHANGED.value, 1);
    });
  });

  // ── ShowControlState.nodeStatuses ─────────────────────────────────────────────

  group('ShowControlState.nodeStatuses', () {
    const online = NodeStatus(
      nodeId: 'n1',
      name: 'AudioNode1',
      tasks: ['audio'],
      health: NodeHealthPhase.online,
    );
    const offline = NodeStatus(
      nodeId: 'n2',
      name: 'MaNode1',
      tasks: ['ma_osc'],
      health: NodeHealthPhase.offline,
    );

    test('defaults to empty list', () {
      expect(const ShowControlState().nodeStatuses, isEmpty);
    });

    test('copyWith replaces nodeStatuses', () {
      final s = const ShowControlState().copyWith(nodeStatuses: [online]);
      expect(s.nodeStatuses, hasLength(1));
      expect(s.nodeStatuses.first.nodeId, 'n1');
    });

    test('copyWith without nodeStatuses preserves existing', () {
      final s = const ShowControlState(nodeStatuses: [online]);
      final s2 = s.copyWith(isPaused: true);
      expect(s2.nodeStatuses, hasLength(1));
    });

    test('can hold multiple nodes', () {
      final s = const ShowControlState().copyWith(nodeStatuses: [online, offline]);
      expect(s.nodeStatuses, hasLength(2));
      expect(s.nodeStatuses.map((n) => n.health),
          containsAll([NodeHealthPhase.online, NodeHealthPhase.offline]));
    });
  });

  // ── NodeHealthEvent type mapping ──────────────────────────────────────────────

  group('NodeHealthEvent type mapping', () {
    test('HEALTH_SNAPSHOT has int value 0', () {
      expect(NodeHealthEvent_HealthEventType.HEALTH_SNAPSHOT.value, 0);
    });

    test('NODE_ONLINE has int value 1', () {
      expect(NodeHealthEvent_HealthEventType.NODE_ONLINE.value, 1);
    });

    test('NODE_OFFLINE has int value 2', () {
      expect(NodeHealthEvent_HealthEventType.NODE_OFFLINE.value, 2);
    });

    test('NODE_DEGRADED has int value 3', () {
      expect(NodeHealthEvent_HealthEventType.NODE_DEGRADED.value, 3);
    });
  });

  // ── NodeHealthPhase mapping (proto → domain) ──────────────────────────────────

  group('NodeHealthPhase from NodeHealthEvent type', () {
    // This mirrors the switch logic in _handleNodeHealthEvent.
    NodeHealthPhase phaseFromEventType(NodeHealthEvent_HealthEventType type) =>
        switch (type) {
          NodeHealthEvent_HealthEventType.NODE_OFFLINE => NodeHealthPhase.offline,
          NodeHealthEvent_HealthEventType.NODE_DEGRADED => NodeHealthPhase.degraded,
          _ => NodeHealthPhase.online,
        };

    test('NODE_OFFLINE → offline', () {
      expect(
        phaseFromEventType(NodeHealthEvent_HealthEventType.NODE_OFFLINE),
        NodeHealthPhase.offline,
      );
    });

    test('NODE_DEGRADED → degraded', () {
      expect(
        phaseFromEventType(NodeHealthEvent_HealthEventType.NODE_DEGRADED),
        NodeHealthPhase.degraded,
      );
    });

    test('NODE_ONLINE → online', () {
      expect(
        phaseFromEventType(NodeHealthEvent_HealthEventType.NODE_ONLINE),
        NodeHealthPhase.online,
      );
    });

    test('HEALTH_SNAPSHOT → online (initial state)', () {
      expect(
        phaseFromEventType(NodeHealthEvent_HealthEventType.HEALTH_SNAPSHOT),
        NodeHealthPhase.online,
      );
    });
  });
}
