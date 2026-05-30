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
/// No gRPC/proto knowledge; callbacks go up to the shell/notifier.
///
/// Desktop: shows all buttons + cue name + timer + shortcut hints.
/// Mobile: shows only buttons + compact cue name.
class TransportBar extends StatefulWidget {
  final PlayheadState playhead;
  final CueList? cueList;
  final VoidCallback? onGo;
  final VoidCallback? onStop;
  final VoidCallback? onPause;
  final VoidCallback? onResume;
  final VoidCallback? onPanic;
  final bool compact; // true for mobile

  const TransportBar({
    super.key,
    required this.playhead,
    this.cueList,
    this.onGo,
    this.onStop,
    this.onPause,
    this.onResume,
    this.onPanic,
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
    if (old.playhead.phase != widget.playhead.phase) {
      _updateTicker();
    }
  }

  void _updateTicker() {
    _ticker?.cancel();
    _ticker = null;
    if (widget.playhead.isRunning) {
      _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
        if (mounted) setState(() {});
      });
    }
    // done/paused/idle: kein Ticker nötig, Timer ist eingefroren oder 0:00
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  String get _elapsedStr {
    final start = widget.playhead.startedServerMs;
    if (start == null) return '0:00';

    final int nowServerMs;
    switch (widget.playhead.phase) {
      case CueListPhase.running:
        nowServerMs = ClockSync.instance.serverNow();
      case CueListPhase.paused:
        nowServerMs = widget.playhead.pausedAtServerMs ?? ClockSync.instance.serverNow();
      case CueListPhase.done:
        // Timer eingefroren beim genauen Endezeitpunkt der Cue
        nowServerMs = widget.playhead.doneServerMs ?? ClockSync.instance.serverNow();
      default:
        return '0:00';
    }

    final ms = (nowServerMs - start).clamp(0, 99 * 60 * 1000);
    final s = ms ~/ 1000;
    final m = s ~/ 60;
    final rs = (s % 60).toString().padLeft(2, '0');
    return '$m:$rs';
  }

  Color get _timerColor {
    return switch (widget.playhead.phase) {
      CueListPhase.running => ScColors.active,
      CueListPhase.paused  => ScColors.warn,
      CueListPhase.done    => ScColors.textDim, // gedimmt = fertig
      _                    => ScColors.textDim,
    };
  }

  String get _activeCueLabel {
    final id = widget.playhead.activeCueId;
    if (id == null || widget.cueList == null) return '';
    final cue = widget.cueList!.cueById(id);
    if (cue == null) return '';
    return '${cue.number}  ${cue.label}';
  }

  @override
  Widget build(BuildContext context) {
    // shortcutHint text adds a second line — only show when bar is tall enough.
    // Transport bar is fixed at 48px; hint labels need ~56px. Use tooltip only.
    return Container(
      height: ScSpacing.transportBarHeight,
      color: ScColors.surface,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Row(
        children: [
          // GO
          Tooltip(
            message: 'GO  [Space]',
            child: ScButton(
              label: 'GO',
              variant: ScButtonVariant.primary,
              size: ScButtonSize.compact,
              onPressed: widget.onGo,
            ),
          ),
          const SizedBox(width: 8),
          // STOP
          Tooltip(
            message: 'STOP  [Esc]',
            child: ScButton(
              label: 'STOP',
              variant: ScButtonVariant.danger,
              size: ScButtonSize.compact,
              onPressed: widget.onStop,
            ),
          ),
          const SizedBox(width: 8),
          // PAUSE / RESUME
          if (widget.playhead.isPaused)
            Tooltip(
              message: 'RESUME  [P]',
              child: ScButton(
                label: 'RESUME',
                icon: Icons.play_arrow,
                variant: ScButtonVariant.secondary,
                size: ScButtonSize.compact,
                onPressed: widget.onResume,
              ),
            )
          else
            Tooltip(
              message: 'PAUSE  [P]',
              child: ScButton(
                label: 'PAUSE',
                icon: Icons.pause,
                variant: ScButtonVariant.secondary,
                size: ScButtonSize.compact,
                onPressed: widget.onPause,
              ),
            ),
          const SizedBox(width: 16),
          // Active cue + timer
          if (!widget.compact || widget.playhead.activeCueId != null)
            Expanded(
              child: Row(
                children: [
                  if (widget.playhead.isRunning)
                    const Icon(Icons.play_arrow, size: 14, color: ScColors.active),
                  if (widget.playhead.isPaused)
                    const Icon(Icons.pause, size: 14, color: ScColors.warn),
                  if (widget.playhead.isDone)
                    const Icon(Icons.check, size: 14, color: ScColors.textDim),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      _activeCueLabel,
                      style: ScText.cueLabel,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    _elapsedStr,
                    style: (widget.playhead.isRunning
                            ? ScText.timer
                            : ScText.numberSmall)
                        .copyWith(color: _timerColor),
                  ),
                ],
              ),
            )
          else
            const Spacer(),
        ],
      ),
    );
  }
}
