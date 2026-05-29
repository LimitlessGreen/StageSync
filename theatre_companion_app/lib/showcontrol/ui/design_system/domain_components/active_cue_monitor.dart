import 'package:flutter/material.dart';
import '../../../domain/playhead.dart';
import '../../../domain/show.dart';
import '../sc_colors.dart';
import '../sc_typography.dart';

/// Live active-cue monitor — shows cue progress and per-node execution state.
/// No gRPC/proto knowledge; receives domain types only.
class ActiveCueMonitor extends StatelessWidget {
  final PlayheadState playhead;
  final CueList? cueList;

  const ActiveCueMonitor({
    super.key,
    required this.playhead,
    this.cueList,
  });

  @override
  Widget build(BuildContext context) {
    final activeId = playhead.activeCueId;
    if (activeId == null || playhead.isIdle) {
      return Center(
        child: Text('Kein aktiver Cue', style: ScText.label),
      );
    }

    final cue = cueList?.cueById(activeId);
    final runState = playhead.runStateFor(activeId);
    final nextCue = playhead.nextCueId != null
        ? cueList?.cueById(playhead.nextCueId!)
        : null;

    // Parallel children = running IDs minus the group/active cue itself
    final childIds = playhead.runningCueIds
        .where((id) => id != activeId)
        .toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Active cue header ────────────────────────────────────────
        _ActiveCueHeader(cue: cue, runState: runState, playhead: playhead),
        const SizedBox(height: 8),
        // ── Progress bar ──────────────────────────────────────────────
        if (cue?.displayDurationMs != null)
          _ProgressBar(playhead: playhead, cue: cue!),
        const SizedBox(height: 12),
        // ── Parallel group children ───────────────────────────────────
        if (childIds.isNotEmpty) ...[
          Text('PARALLEL', style: ScText.panelTitle),
          const SizedBox(height: 6),
          ...childIds.map((childId) {
            final childCue = cueList?.cueById(childId);
            final childState = playhead.runStateFor(childId);
            return _ChildCueRow(
              childId: childId,
              cue: childCue,
              runState: childState,
            );
          }),
          const SizedBox(height: 8),
        ],
        // ── Per-node state ────────────────────────────────────────────
        if (runState != null && runState.nodes.isNotEmpty) ...[
          Text('NODES', style: ScText.panelTitle),
          const SizedBox(height: 6),
          ...runState.nodes.entries.map(
            (e) => _NodeRow(nodeId: e.key, state: e.value),
          ),
        ],
        const Spacer(),
        // ── Next cue ─────────────────────────────────────────────────
        if (nextCue != null) ...[
          const Divider(color: ScColors.divider, height: 1),
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(Icons.arrow_downward, size: 12, color: ScColors.textDim),
              const SizedBox(width: 6),
              Text('Nächster:', style: ScText.label),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  '${nextCue.number}  ${nextCue.label}',
                  style: ScText.cueLabel.copyWith(fontSize: 12),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }
}

class _ActiveCueHeader extends StatelessWidget {
  final Cue? cue;
  final CueRunState? runState;
  final PlayheadState playhead;

  const _ActiveCueHeader({
    required this.cue,
    required this.runState,
    required this.playhead,
  });

  Color get _stateColor {
    if (runState?.lifecycle == CueLifecycle.error) return ScColors.error;
    if (playhead.isPaused) return ScColors.warn;
    return ScColors.active;
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 4,
          height: 40,
          decoration: BoxDecoration(
            color: _stateColor,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (cue != null)
                Text(
                  '${cue!.number}  ${cue!.label}',
                  style: ScText.cueLabelActive,
                  overflow: TextOverflow.ellipsis,
                )
              else
                Text(playhead.activeCueId ?? '', style: ScText.cueLabelActive),
              const SizedBox(height: 2),
              Text(
                playhead.isPaused ? 'PAUSIERT' : 'LÄUFT',
                style: ScText.status.copyWith(color: _stateColor),
              ),
            ],
          ),
        ),
        _ElapsedTimer(playhead: playhead),
      ],
    );
  }
}

class _ElapsedTimer extends StatefulWidget {
  final PlayheadState playhead;
  const _ElapsedTimer({required this.playhead});

  @override
  State<_ElapsedTimer> createState() => _ElapsedTimerState();
}

class _ElapsedTimerState extends State<_ElapsedTimer> {
  @override
  Widget build(BuildContext context) {
    if (widget.playhead.isRunning) {
      Future.delayed(const Duration(seconds: 1), () {
        if (mounted) setState(() {});
      });
    }

    final start = widget.playhead.startedServerMs;
    final pause = widget.playhead.pausedAtServerMs;
    String elapsed = '0:00';
    if (start != null) {
      final now = widget.playhead.isPaused
          ? (pause ?? DateTime.now().millisecondsSinceEpoch)
          : DateTime.now().millisecondsSinceEpoch;
      final ms = (now - start).clamp(0, 99 * 60 * 1000);
      final s = ms ~/ 1000;
      final m = s ~/ 60;
      final rs = (s % 60).toString().padLeft(2, '0');
      elapsed = '$m:$rs';
    }

    return Text(
      elapsed,
      style: ScText.timer.copyWith(
        color: widget.playhead.isPaused ? ScColors.warn : ScColors.active,
      ),
    );
  }
}

class _ProgressBar extends StatelessWidget {
  final PlayheadState playhead;
  final Cue cue;

  const _ProgressBar({required this.playhead, required this.cue});

  double get _fraction {
    final start = playhead.startedServerMs;
    final duration = cue.displayDurationMs;
    if (start == null || duration == null || duration == 0) return 0;
    final now = playhead.isPaused
        ? (playhead.pausedAtServerMs ?? DateTime.now().millisecondsSinceEpoch)
        : DateTime.now().millisecondsSinceEpoch;
    return ((now - start) / duration).clamp(0.0, 1.0);
  }

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(4),
      child: LinearProgressIndicator(
        value: _fraction,
        backgroundColor: ScColors.divider,
        valueColor: AlwaysStoppedAnimation(
          playhead.isPaused ? ScColors.warn : ScColors.active,
        ),
        minHeight: 6,
      ),
    );
  }
}

class _ChildCueRow extends StatelessWidget {
  final String childId;
  final Cue? cue;
  final CueRunState? runState;

  const _ChildCueRow({
    required this.childId,
    required this.cue,
    required this.runState,
  });

  Color get _color => switch (runState?.lifecycle) {
        CueLifecycle.running => ScColors.active,
        CueLifecycle.paused  => ScColors.warn,
        CueLifecycle.error   => ScColors.error,
        _                    => ScColors.textDim,
      };

  @override
  Widget build(BuildContext context) {
    final label = cue != null
        ? '${cue!.number}  ${cue!.label}'
        : childId.substring(0, childId.length.clamp(0, 8));
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(color: _color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              label,
              style: ScText.label.copyWith(color: _color),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Text(
            runState?.lifecycle.name ?? '',
            style: ScText.label.copyWith(color: ScColors.textDim, fontSize: 10),
          ),
        ],
      ),
    );
  }
}

class _NodeRow extends StatelessWidget {
  final String nodeId;
  final NodeExecState state;

  const _NodeRow({required this.nodeId, required this.state});

  Color get _color => switch (state.phase) {
        NodeExecPhase.error    => ScColors.error,
        NodeExecPhase.degraded => ScColors.warn,
        NodeExecPhase.playing  => ScColors.active,
        NodeExecPhase.buffering => ScColors.warn,
        NodeExecPhase.awaitingAsset => Colors.orange,
        _                     => ScColors.textDim,
      };

  String get _phaseLabel => switch (state.phase) {
        NodeExecPhase.idle          => 'idle',
        NodeExecPhase.awaitingAsset => '⏳ Datei wird geladen',
        NodeExecPhase.preloading    => 'Preloading…',
        NodeExecPhase.buffering     => 'Buffering…',
        NodeExecPhase.ready         => 'Bereit',
        NodeExecPhase.playing       => '▶ Playing',
        NodeExecPhase.paused        => '⏸ Paused',
        NodeExecPhase.done          => '✓ Done',
        NodeExecPhase.degraded      => '⚠ Degraded',
        NodeExecPhase.error         => '✗ ${state.errorMessage ?? "Fehler"}',
      };

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              color: _color,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              nodeId.length > 8 ? nodeId.substring(0, 8) : nodeId,
              style: ScText.labelBold,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Text(_phaseLabel, style: ScText.label.copyWith(color: _color)),
        ],
      ),
    );
  }
}
