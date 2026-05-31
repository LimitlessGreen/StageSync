import 'dart:async';

import 'package:flutter/material.dart';
import '../../../domain/show.dart';
import '../../../domain/playhead.dart';
import '../../../session/clock_sync.dart';
import '../sc_colors.dart';
import '../sc_typography.dart';
import '../sc_spacing.dart';
import '../primitives/sc_button.dart';

/// Transport bar — always visible, knows [PlayheadState] and [CueList].
///
/// Desktop layout (left → right):
///   [active cue + timer ............. next-cue preview]  [STOP] [PAUSE/RESUME] [═ GO ═]
///
/// All transport controls are grouped together on the right so the operator
/// never has to jump across the screen. GO is the rightmost dominant element.
class TransportBar extends StatefulWidget {
  final PlayheadState playhead;
  final CueList? cueList;
  final VoidCallback? onGo;
  final VoidCallback? onStop;
  final VoidCallback? onPause;
  final VoidCallback? onResume;
  final bool compact;

  const TransportBar({
    super.key,
    required this.playhead,
    this.cueList,
    this.onGo,
    this.onStop,
    this.onPause,
    this.onResume,
    this.compact = false,
  });

  @override
  State<TransportBar> createState() => _TransportBarState();
}

class _TransportBarState extends State<TransportBar> {
  Timer? _ticker;

  @override
  void initState() {
    super.initState();
    _updateTicker();
  }

  @override
  void didUpdateWidget(TransportBar old) {
    super.didUpdateWidget(old);
    if (old.playhead.phase != widget.playhead.phase) _updateTicker();
  }

  void _updateTicker() {
    _ticker?.cancel();
    _ticker = null;
    // Ticker auch während paused laufen lassen: Im Fade-Out-Fenster muss
    // _elapsedStr weiter hochzählen. Nach dem Fade friert _elapsedStr von
    // selbst ein (gibt pausedAtServerMs zurück), setState ist dann billig.
    if (widget.playhead.isRunning || widget.playhead.isPaused) {
      _ticker = Timer.periodic(const Duration(milliseconds: 100), (_) {
        if (mounted) setState(() {});
      });
    }
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  String get _elapsedStr {
    final start = widget.playhead.startedServerMs;
    if (start == null) return '0:00';
    // pausedAtServerMs = press-time + fade duration = actual audio-silence position.
    // During the fade window (now < pausedAt) show live advancing time; afterwards freeze.
    final int nowMs = switch (widget.playhead.phase) {
      CueListPhase.running => ClockSync.instance.serverNow(),
      CueListPhase.paused  => () {
          final pausedAt = widget.playhead.pausedAtServerMs;
          if (pausedAt == null) return ClockSync.instance.serverNow();
          final now = ClockSync.instance.serverNow();
          return now < pausedAt ? now : pausedAt;
        }(),
      CueListPhase.done    => widget.playhead.doneServerMs ?? ClockSync.instance.serverNow(),
      _                    => -1,
    };
    if (nowMs < 0) return '0:00';
    final ms = (nowMs - start).clamp(0, 99 * 60 * 1000);
    final s = ms ~/ 1000;
    final m = s ~/ 60;
    final rs = (s % 60).toString().padLeft(2, '0');
    return '$m:$rs';
  }

  Color get _timerColor => switch (widget.playhead.phase) {
    CueListPhase.running => ScColors.active,
    CueListPhase.paused  => ScColors.warn,
    CueListPhase.done    => ScColors.textDim,
    _                    => ScColors.textDim,
  };

  IconData get _stateIcon => switch (widget.playhead.phase) {
    CueListPhase.running => Icons.play_arrow,
    CueListPhase.paused  => Icons.pause,
    CueListPhase.done    => Icons.check,
    _                    => Icons.hourglass_empty,
  };

  Color get _stateIconColor => switch (widget.playhead.phase) {
    CueListPhase.running => ScColors.active,
    CueListPhase.paused  => ScColors.warn,
    _                    => ScColors.textDim,
  };

  Cue? get _activeCue {
    final id = widget.playhead.activeCueId;
    if (id == null || widget.cueList == null) return null;
    return widget.cueList!.cueById(id);
  }

  Cue? get _nextCue {
    final id = widget.playhead.activeCueId;
    if (id == null || widget.cueList == null) return null;
    final cues = widget.cueList!.cues;
    final idx = cues.indexWhere((c) => c.id == id);
    if (idx < 0 || idx + 1 >= cues.length) return null;
    return cues[idx + 1];
  }

  @override
  Widget build(BuildContext context) {
    final active = _activeCue;
    final next   = _nextCue;
    final showPhase = widget.playhead.isRunning ||
        widget.playhead.isPaused ||
        widget.playhead.isDone;

    return Container(
      height: ScSpacing.transportBarHeight,
      color: ScColors.surface,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Row(
        children: [
          // ── Left/Center: informational ───────────────────────────────
          Expanded(
            child: Row(
              children: [
                // Active cue state + label + timer
                if (showPhase && active != null) ...[
                  Icon(_stateIcon, size: 13, color: _stateIconColor),
                  const SizedBox(width: 6),
                  Flexible(
                    child: Text(
                      '${active.number}  ${active.label}',
                      style: ScText.cueLabel.copyWith(color: ScColors.textPrimary),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    _elapsedStr,
                    style: ScText.timer.copyWith(fontSize: 15, color: _timerColor),
                  ),
                ] else
                  Text('—', style: ScText.cueLabel.copyWith(color: ScColors.textDim)),

                // Next cue preview
                if (next != null && !widget.compact) ...[
                  Container(
                    width: 1, height: 20,
                    color: ScColors.divider,
                    margin: const EdgeInsets.symmetric(horizontal: 12),
                  ),
                  const Text('NEXT', style: TextStyle(
                    color: ScColors.textDim,
                    fontSize: 9,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.8,
                  )),
                  const SizedBox(width: 6),
                  Flexible(
                    child: Text(
                      '${next.number}  ${next.label}',
                      style: ScText.label.copyWith(color: ScColors.textSecondary),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ],
            ),
          ),

          // ── Right: ALL transport controls grouped together ───────────
          const SizedBox(width: 12),
          Container(width: 1, height: 24, color: ScColors.divider),
          const SizedBox(width: 12),

          // STOP
          Tooltip(
            message: 'STOP  [Esc]',
            child: ScButton(
              label: 'STOP',
              icon: Icons.stop,
              variant: ScButtonVariant.danger,
              size: ScButtonSize.compact,
              onPressed: widget.onStop,
            ),
          ),
          const SizedBox(width: 6),

          // PAUSE / RESUME
          Tooltip(
            message: widget.playhead.isPaused ? 'RESUME  [P]' : 'PAUSE  [P]',
            child: widget.playhead.isPaused
                ? ScButton(
                    label: 'RESUME',
                    icon: Icons.play_arrow,
                    variant: ScButtonVariant.secondary,
                    size: ScButtonSize.compact,
                    onPressed: widget.onResume,
                  )
                : ScButton(
                    label: 'PAUSE',
                    icon: Icons.pause,
                    variant: ScButtonVariant.secondary,
                    size: ScButtonSize.compact,
                    onPressed: widget.onPause,
                  ),
          ),
          const SizedBox(width: 10),

          // GO — dominant, rightmost anchor
          Tooltip(
            message: 'GO  [Space]',
            child: SizedBox(
              width: 120,
              child: ScButton(
                label: 'GO',
                variant: ScButtonVariant.primary,
                size: ScButtonSize.transport,
                onPressed: widget.onGo,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
