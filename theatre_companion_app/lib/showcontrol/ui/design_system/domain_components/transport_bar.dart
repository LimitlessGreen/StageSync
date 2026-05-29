import 'package:flutter/material.dart';
import '../../../domain/show.dart';
import '../../../domain/playhead.dart';
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
  // Elapsed time update ticker
  late final _ticker = Stopwatch();

  @override
  void initState() {
    super.initState();
    _startTicker();
  }

  @override
  void didUpdateWidget(TransportBar old) {
    super.didUpdateWidget(old);
    if (old.playhead.startedServerMs != widget.playhead.startedServerMs) {
      _startTicker();
    }
  }

  void _startTicker() {
    _ticker
      ..reset()
      ..start();
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _ticker.stop();
    super.dispose();
  }

  String get _elapsedStr {
    final start = widget.playhead.startedServerMs;
    final pause = widget.playhead.pausedAtServerMs;
    if (start == null || !widget.playhead.isRunning && !widget.playhead.isPaused) {
      return '0:00';
    }
    final now = widget.playhead.isPaused
        ? pause!
        : DateTime.now().millisecondsSinceEpoch;
    final ms = (now - start).clamp(0, 99 * 60 * 1000);
    final s = ms ~/ 1000;
    final m = s ~/ 60;
    final rs = (s % 60).toString().padLeft(2, '0');
    return '$m:$rs';
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
    // Rebuild every second when running
    if (widget.playhead.isRunning) {
      Future.delayed(const Duration(seconds: 1), () {
        if (mounted) setState(() {});
      });
    }

    return Container(
      height: ScSpacing.transportBarHeight,
      color: ScColors.surface,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Row(
        children: [
          // GO
          ScButton(
            label: 'GO',
            variant: ScButtonVariant.primary,
            size: ScButtonSize.compact,
            shortcutHint: widget.compact ? null : 'Space',
            onPressed: widget.onGo,
          ),
          const SizedBox(width: 8),
          // STOP
          ScButton(
            label: 'STOP',
            variant: ScButtonVariant.danger,
            size: ScButtonSize.compact,
            shortcutHint: widget.compact ? null : 'Esc',
            onPressed: widget.onStop,
          ),
          const SizedBox(width: 8),
          // PAUSE / RESUME
          if (widget.playhead.isPaused)
            ScButton(
              label: 'RESUME',
              icon: Icons.play_arrow,
              variant: ScButtonVariant.secondary,
              size: ScButtonSize.compact,
              shortcutHint: widget.compact ? null : 'P',
              onPressed: widget.onResume,
            )
          else
            ScButton(
              label: 'PAUSE',
              icon: Icons.pause,
              variant: ScButtonVariant.secondary,
              size: ScButtonSize.compact,
              shortcutHint: widget.compact ? null : 'P',
              onPressed: widget.onPause,
            ),
          const SizedBox(width: 16),
          // Active cue + timer
          if (!widget.compact || widget.playhead.activeCueId != null)
            Expanded(
              child: Row(
                children: [
                  if (widget.playhead.isRunning)
                    const Icon(Icons.play_arrow,
                        size: 14, color: ScColors.active),
                  if (widget.playhead.isPaused)
                    const Icon(Icons.pause, size: 14, color: ScColors.warn),
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
                    style: widget.playhead.isRunning
                        ? ScText.timer
                        : ScText.numberSmall,
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
