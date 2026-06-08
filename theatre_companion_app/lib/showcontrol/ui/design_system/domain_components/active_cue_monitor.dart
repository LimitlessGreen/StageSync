import 'package:flutter/material.dart';
import '../../../domain/playhead.dart';
import '../../../domain/show.dart';
import '../sc_colors.dart';
import '../sc_tick.dart';
import '../sc_typography.dart';

/// Live active-cue monitor — 60-fps progress bar, per-node execution detail.
/// Receives domain types only; no gRPC/proto knowledge.
class ActiveCueMonitor extends StatefulWidget {
  final PlayheadState playhead;
  final CueList? cueList;

  const ActiveCueMonitor({
    super.key,
    required this.playhead,
    this.cueList,
  });

  @override
  State<ActiveCueMonitor> createState() => _ActiveCueMonitorState();
}

class _ActiveCueMonitorState extends State<ActiveCueMonitor> {
  @override
  Widget build(BuildContext context) {
    final activeId = widget.playhead.activeCueId;
    // Ticker läuft solange Zeit voranschreitet — auch während Fade-Fenstern.
    final fullyPaused = activeId != null &&
        widget.playhead.isCuePaused(activeId) &&
        !widget.playhead.isCueFading(activeId);
    if (widget.playhead.needsTick && !fullyPaused) ScTick.of(context);
    if (activeId == null || widget.playhead.isIdle) {
      return Center(child: Text('Kein aktiver Cue', style: ScText.label));
    }

    final cue = widget.cueList?.cueById(activeId);
    final runState = widget.playhead.runStateFor(activeId);
    final nextCue = widget.playhead.nextCueId != null
        ? widget.cueList?.cueById(widget.playhead.nextCueId!)
        : null;

    // Zeige alle parallel laufenden Cues an (von Group oder Audio-Loop)
    // inklusive derer, die nicht die aktiveCueId sind
    final otherRunningIds =
        widget.playhead.runningCueIds.where((id) => id != activeId).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _ActiveCueHeader(
            cue: cue, runState: runState, playhead: widget.playhead),
        const SizedBox(height: 8),
        if (cue?.displayDurationMs != null)
          _ProgressBar(playhead: widget.playhead, cue: cue!),
        const SizedBox(height: 12),
        // Zeige auch andere laufende Cues (Audio-Loops, Group-Parallels)
        if (otherRunningIds.isNotEmpty) ...[
          Text('LAUFENDE CUES', style: ScText.panelTitle),
          const SizedBox(height: 6),
          ...otherRunningIds.map((childId) {
            final childCue = widget.cueList?.cueById(childId);
            final childState = widget.playhead.runStateFor(childId) ??
                const CueRunState(lifecycle: CueLifecycle.running);
            return _ChildCueRow(
              childId: childId,
              cue: childCue,
              runState: childState,
              playhead: widget.playhead,
            );
          }),
          const SizedBox(height: 8),
        ],
        if (runState != null && runState.nodes.isNotEmpty) ...[
          Text('NODES', style: ScText.panelTitle),
          const SizedBox(height: 6),
          ...runState.nodes.entries
              .map((e) => _NodeRow(nodeId: e.key, state: e.value)),
        ],
        const Spacer(),
        if (nextCue != null) ...[
          const Divider(color: ScColors.divider, height: 1),
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(Icons.arrow_downward,
                  size: 12, color: ScColors.textDim),
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

// ── Active cue header ─────────────────────────────────────────────────────────

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
    if (playhead.isDone) return ScColors.textDim;
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

// ── Elapsed timer — driven by parent ticker ───────────────────────────────────

class _ElapsedTimer extends StatelessWidget {
  final PlayheadState playhead;
  const _ElapsedTimer({required this.playhead});

  String _format(int ms) {
    final s = ms ~/ 1000;
    final m = s ~/ 60;
    final rs = (s % 60).toString().padLeft(2, '0');
    return '$m:$rs';
  }

  @override
  Widget build(BuildContext context) {
    final start = playhead.startedServerMs;
    if (start == null) return Text('0:00', style: ScText.timer);

    final cueId = playhead.activeCueId ?? '';
    final ms =
        (playhead.effectiveNowMsForCue(cueId) - start).clamp(0, 99 * 60 * 1000);

    return Text(
      _format(ms),
      style: ScText.timer.copyWith(
        color: playhead.isPaused
            ? ScColors.warn
            : playhead.isDone
                ? ScColors.textDim
                : ScColors.active,
      ),
    );
  }
}

// ── Progress bar — 60fps via parent ticker ────────────────────────────────────

class _ProgressBar extends StatelessWidget {
  final PlayheadState playhead;
  final Cue cue;

  const _ProgressBar({required this.playhead, required this.cue});

  double get _fraction {
    final start = playhead.startedServerMs;
    final duration = cue.displayDurationMs;
    if (start == null || duration == null || duration == 0) return 0.0;
    return ((playhead.effectiveNowMsForCue(cue.id) - start) / duration)
        .clamp(0.0, 1.0);
  }

  @override
  Widget build(BuildContext context) {
    final fraction = _fraction;
    final barColor = playhead.isPaused
        ? ScColors.warn
        : playhead.isDone
            ? ScColors.textDim
            : ScColors.active;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(4),
            boxShadow: [
              BoxShadow(
                color: barColor.withValues(alpha: playhead.isDone ? 0.0 : 0.35),
                blurRadius: 8,
                spreadRadius: 1,
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: fraction,
              backgroundColor: ScColors.divider,
              valueColor: AlwaysStoppedAnimation(barColor),
              minHeight: 6,
            ),
          ),
        ),
        const SizedBox(height: 2),
        Row(
          children: [
            Text(
              _elapsedText,
              style: ScText.statusSmall,
            ),
            const Spacer(),
            Text(
              _totalText,
              style: ScText.statusSmall,
            ),
          ],
        ),
      ],
    );
  }

  String get _elapsedText {
    final start = playhead.startedServerMs;
    if (start == null) return '';
    return _fmtMs((playhead.effectiveNowMs() - start)
        .clamp(0, 99 * 60 * 1000)
        .toDouble());
  }

  String get _totalText {
    final d = cue.displayDurationMs;
    if (d == null) return '';
    return _fmtMs(d);
  }

  static String _fmtMs(double ms) {
    if (ms < 1000) return '${ms.toInt()}ms';
    final s = ms / 1000;
    if (s < 60) return '${s.toStringAsFixed(1)}s';
    final m = (s / 60).floor();
    final rs = (s % 60).toStringAsFixed(0).padLeft(2, '0');
    return '$m:$rs';
  }
}

// ── Parallel child row ────────────────────────────────────────────────────────

class _ChildCueRow extends StatelessWidget {
  final String childId;
  final Cue? cue;
  final CueRunState? runState;
  final PlayheadState playhead;

  const _ChildCueRow({
    required this.childId,
    required this.cue,
    required this.runState,
    required this.playhead,
  });

  Color get _color => switch (runState?.lifecycle) {
        CueLifecycle.running => ScColors.active,
        CueLifecycle.paused => ScColors.warn,
        CueLifecycle.error => ScColors.error,
        _ => ScColors.textDim,
      };

  @override
  Widget build(BuildContext context) {
    final label = cue != null
        ? '${cue!.number}  ${cue!.label}'
        : childId.substring(0, childId.length.clamp(0, 8));
    final startMs = playhead.cueStartedServerMsByCueId[childId];
    final elapsedMs = startMs != null
        ? (playhead.effectiveNowMsForCue(childId) - startMs)
            .clamp(0, 99 * 60 * 1000)
            .toDouble()
        : null;
    final durationMs = cue?.displayDurationMs;
    final fraction = (elapsedMs != null && durationMs != null && durationMs > 0)
        ? (elapsedMs / durationMs).clamp(0.0, 1.0)
        : null;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 6,
                height: 6,
                decoration:
                    BoxDecoration(color: _color, shape: BoxShape.circle),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(label,
                    style: ScText.label.copyWith(color: _color),
                    overflow: TextOverflow.ellipsis),
              ),
              Text(
                runState?.lifecycle.name ?? '',
                style: ScText.label
                    .copyWith(color: ScColors.textDim, fontSize: 10),
              ),
              if (elapsedMs != null) ...[
                const SizedBox(width: 8),
                Text(
                  _fmtMs(elapsedMs),
                  style: ScText.statusSmall.copyWith(color: ScColors.textDim),
                ),
              ],
            ],
          ),
          if (fraction != null)
            Padding(
              padding: const EdgeInsets.only(left: 14, top: 3),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(3),
                child: LinearProgressIndicator(
                  value: fraction,
                  minHeight: 4,
                  backgroundColor: ScColors.divider,
                  valueColor: AlwaysStoppedAnimation(_color),
                ),
              ),
            ),
        ],
      ),
    );
  }

  static String _fmtMs(double ms) {
    if (ms < 1000) return '${ms.toInt()}ms';
    final s = ms / 1000;
    if (s < 60) return '${s.toStringAsFixed(1)}s';
    final m = (s / 60).floor();
    final rs = (s % 60).toStringAsFixed(0).padLeft(2, '0');
    return '$m:$rs';
  }
}

// ── Node row ──────────────────────────────────────────────────────────────────

class _NodeRow extends StatelessWidget {
  final String nodeId;
  final NodeExecState state;

  const _NodeRow({required this.nodeId, required this.state});

  Color get _color => switch (state.phase) {
        NodeExecPhase.error => ScColors.error,
        NodeExecPhase.degraded => ScColors.warn,
        NodeExecPhase.playing => ScColors.active,
        NodeExecPhase.buffering => ScColors.warn,
        NodeExecPhase.awaitingAsset => Colors.orange,
        _ => ScColors.textDim,
      };

  String get _phaseLabel => switch (state.phase) {
        NodeExecPhase.idle => 'idle',
        NodeExecPhase.awaitingAsset => '⏳ Datei wird geladen',
        NodeExecPhase.preloading => 'Preloading…',
        NodeExecPhase.buffering => 'Buffering…',
        NodeExecPhase.ready => 'Bereit',
        NodeExecPhase.playing => '▶ Playing',
        NodeExecPhase.paused => '⏸ Paused',
        NodeExecPhase.done => '✓ Done',
        NodeExecPhase.degraded => '⚠ Degraded',
        NodeExecPhase.error => '✗ ${state.errorMessage ?? "Fehler"}',
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
            decoration: BoxDecoration(color: _color, shape: BoxShape.circle),
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
