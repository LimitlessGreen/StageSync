import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/show.dart';
import '../domain/playhead.dart';
import '../domain/node_status.dart';
import '../infrastructure/grpc/show_control_repository.dart';
import 'show_control_provider.dart';
import 'session_provider.dart';

// ── Domain State ──────────────────────────────────────────────────────────────

/// Combined domain state: definition + live execution + node health.
class ShowControlDomainState {
  final CueList? cueList;
  final PlayheadState playhead;
  final List<NodeStatus> nodes;
  final bool isLoading;
  final String? error;

  const ShowControlDomainState({
    this.cueList,
    required this.playhead,
    this.nodes = const [],
    this.isLoading = false,
    this.error,
  });

  static const empty = ShowControlDomainState(playhead: PlayheadState.empty);
}

// ── Providers ─────────────────────────────────────────────────────────────────

/// Domain-typed view of the show control state.
///
/// Reads [showControlProvider] (proto-based) and [sessionProvider] and converts
/// to immutable domain objects via [ShowControlRepository].
///
/// UI layers import only this provider — never the proto-based one directly.
final showControlDomainProvider = Provider<ShowControlDomainState>((ref) {
  final showState = ref.watch(showControlProvider);
  final session   = ref.watch(sessionProvider);

  // ── Map CueList ──────────────────────────────────────────────────────────
  final cueList = showState.cueList != null
      ? ShowControlRepository.cueListFromProto(showState.cueList!)
      : null;

  // ── Build PlayheadState ───────────────────────────────────────────────────
  final playhead = _buildPlayhead(showState, cueList);

  // ── Map Node Statuses ─────────────────────────────────────────────────────
  // Prefer WatchNodeHealth stream (authoritative, real-time) over session nodes.
  // Fall back to session nodes during stream init or when nodeStatuses is empty.
  final nodes = showState.nodeStatuses.isNotEmpty
      ? showState.nodeStatuses
      : ShowControlRepository.nodeStatusesFromNodes(
          session.session?.nodes.toList() ?? [],
          !session.isDisconnected,
        );

  return ShowControlDomainState(
    cueList: cueList,
    playhead: playhead,
    nodes: nodes,
    isLoading: showState.isLoading,
    error: showState.error,
  );
});

/// Convenience: just the [PlayheadState].
final playheadProvider = Provider<PlayheadState>((ref) {
  return ref.watch(showControlDomainProvider).playhead;
});

/// Convenience: just the domain [CueList].
final domainCueListProvider = Provider<CueList?>((ref) {
  return ref.watch(showControlDomainProvider).cueList;
});

/// Convenience: node statuses.
final nodeStatusListProvider = Provider<List<NodeStatus>>((ref) {
  return ref.watch(showControlDomainProvider).nodes;
});

// ── Private helpers ────────────────────────────────────────────────────────────

PlayheadState _buildPlayhead(ShowControlState state, CueList? cueList) {
  final cueListId   = state.cueList?.cueListId ?? '';
  final activeCueId = state.activeCue?.cueId;

  // Derive next cue from domain CueList
  String? nextCueId;
  if (activeCueId != null && cueList != null) {
    nextCueId = cueList.cueAfter(activeCueId)?.id;
  }

  // Phase
  final CueListPhase phase;
  if (state.activeCue == null) {
    phase = CueListPhase.idle;
  } else if (state.isPaused) {
    phase = CueListPhase.paused;
  } else {
    phase = CueListPhase.running;
  }

  // runningCueIds: prefer server-authoritative set; fall back to {activeCueId}.
  final runningCueIds = state.runningCueIds.isNotEmpty
      ? state.runningCueIds
      : (activeCueId != null ? {activeCueId} : const <String>{});

  // Per-cue state: all running IDs get a CueRunState; active cue also tracks
  // pause. This will be superseded by server-sent per-node states in Phase 4.
  final perCue = <String, CueRunState>{};
  for (final id in runningCueIds) {
    perCue[id] = CueRunState(
      lifecycle: (id == activeCueId && state.isPaused)
          ? CueLifecycle.paused
          : CueLifecycle.running,
    );
  }

  return PlayheadState(
    cueListId: cueListId,
    activeCueId: activeCueId,
    runningCueIds: runningCueIds,
    nextCueId: nextCueId,
    phase: phase,
    startedServerMs: state.activeCueStartedServerMs,
    pausedAtServerMs: state.pausedAtServerMs,
    perCue: perCue,
  );
}
