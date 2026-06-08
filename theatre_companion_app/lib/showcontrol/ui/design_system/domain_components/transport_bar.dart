import 'package:flutter/material.dart';
import '../../../domain/show.dart';
import '../../../domain/playhead.dart';
import '../sc_colors.dart';
import '../sc_typography.dart';
import '../sc_spacing.dart';
import '../sc_tick.dart';
import '../primitives/sc_button.dart';

/// Transport bar — always visible, knows [PlayheadState] and [CueList].
///
/// Desktop layout (left → right):
///   [active cue + timer ............. next-cue preview]  [STOP] [PAUSE/RESUME] [═ GO ═]
///
/// All transport controls are grouped together on the right so the operator
/// never has to jump across the screen. GO is the rightmost dominant element.
///
/// Timing is driven by the shared [ScTick] vsync ticker — no internal timer.
class TransportBar extends StatelessWidget {
  final PlayheadState playhead;
  final CueList? cueList;
  final VoidCallback? onGo;
  final VoidCallback? onStop;
  final VoidCallback? onPause;
  final VoidCallback? onResume;
  final bool compact;
  final DateTime? goLockedUntil;

  const TransportBar({
    super.key,
    required this.playhead,
    this.cueList,
    this.onGo,
    this.onStop,
    this.onPause,
    this.onResume,
    this.compact = false,
    this.goLockedUntil,
  });

  String _elapsedStr() {
    final start = playhead.startedServerMs;
    if (start == null) return '0:00';
    final int nowMs =
        playhead.phase == CueListPhase.idle ? -1 : playhead.effectiveNowMs();
    if (nowMs < 0) return '0:00';
    final ms = (nowMs - start).clamp(0, 99 * 60 * 1000);
    final s = ms ~/ 1000;
    final m = s ~/ 60;
    final rs = (s % 60).toString().padLeft(2, '0');
    return '$m:$rs';
  }

  Color get _timerColor => switch (playhead.phase) {
        CueListPhase.running => ScColors.active,
        CueListPhase.paused => ScColors.warn,
        CueListPhase.done => ScColors.textDim,
        _ => ScColors.textDim,
      };

  IconData get _stateIcon => switch (playhead.phase) {
        CueListPhase.running => Icons.play_arrow,
        CueListPhase.paused => Icons.pause,
        CueListPhase.done => Icons.check,
        _ => Icons.hourglass_empty,
      };

  Color get _stateIconColor => switch (playhead.phase) {
        CueListPhase.running => ScColors.active,
        CueListPhase.paused => ScColors.warn,
        _ => ScColors.textDim,
      };

  Cue? _activeCue() {
    final id = playhead.activeCueId;
    if (id == null || cueList == null) return null;
    return cueList!.cueById(id);
  }

  Cue? _nextCue() {
    final id = playhead.activeCueId;
    if (id == null || cueList == null) return null;
    final cues = cueList!.cues;
    final idx = cues.indexWhere((c) => c.id == id);
    if (idx < 0 || idx + 1 >= cues.length) return null;
    return cues[idx + 1];
  }

  @override
  Widget build(BuildContext context) {
    // Subscribe to shared vsync ticker — rebuilds each frame when live.
    if (playhead.isRunning || playhead.isPaused) ScTick.of(context);

    final active = _activeCue();
    final next = _nextCue();
    final showPhase =
        playhead.isRunning || playhead.isPaused || playhead.isDone;

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
                      style:
                          ScText.cueLabel.copyWith(color: ScColors.textPrimary),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    _elapsedStr(),
                    style:
                        ScText.timer.copyWith(fontSize: 15, color: _timerColor),
                  ),
                ] else
                  Text('—',
                      style: ScText.cueLabel.copyWith(color: ScColors.textDim)),

                // Next cue preview
                if (next != null && !compact) ...[
                  Container(
                    width: 1,
                    height: 20,
                    color: ScColors.divider,
                    margin: const EdgeInsets.symmetric(horizontal: 12),
                  ),
                  const Text('NEXT',
                      style: TextStyle(
                        color: ScColors.textDim,
                        fontSize: 9,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.8,
                      )),
                  const SizedBox(width: 6),
                  Flexible(
                    child: Text(
                      '${next.number}  ${next.label}',
                      style:
                          ScText.label.copyWith(color: ScColors.textSecondary),
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
              onPressed: onStop,
            ),
          ),
          const SizedBox(width: 6),

          // PAUSE / RESUME
          Tooltip(
            message: playhead.isPaused ? 'RESUME  [P]' : 'PAUSE  [P]',
            child: playhead.isPaused
                ? ScButton(
                    label: 'RESUME',
                    icon: Icons.play_arrow,
                    variant: ScButtonVariant.secondary,
                    size: ScButtonSize.compact,
                    onPressed: onResume,
                  )
                : ScButton(
                    label: 'PAUSE',
                    icon: Icons.pause,
                    variant: ScButtonVariant.secondary,
                    size: ScButtonSize.compact,
                    onPressed: onPause,
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
                onPressed: onGo,
                lockEndTime: goLockedUntil,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
