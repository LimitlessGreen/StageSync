import 'package:flutter/material.dart';
import '../../../domain/show.dart';
import '../../../domain/cue_params.dart';
import '../../../domain/playhead.dart';
import '../sc_colors.dart';
import '../sc_typography.dart';
import '../sc_tick.dart';

/// DAW-style runtime control strip that slides in below the active cue row.
///
/// Design rationale (QLab / Reaper best-practice):
/// - Inline row controls are reserved for non-runtime interactions (edit, drag, delete).
/// - Runtime controls (fade, pause, stop) live in a dedicated strip below the cue,
///   visually attached to it but clearly separated from the list chrome.
/// - Fade duration is adjustable via a compact drag-field, not hardcoded.
///
/// The strip is only rendered when the cue is an AudioCue and [isVisible] is true.
class ActiveCueControlStrip extends StatefulWidget {
  final Cue cue;
  final PlayheadState playhead;

  /// Callbacks wired to ShowControlNotifier — all take fade-duration in ms.
  final ValueChanged<double>? onFadeUp;
  final ValueChanged<double>? onFadeOut;
  final VoidCallback? onStop;
  final VoidCallback? onPause;
  final VoidCallback? onResume;

  const ActiveCueControlStrip({
    super.key,
    required this.cue,
    required this.playhead,
    this.onFadeUp,
    this.onFadeOut,
    this.onStop,
    this.onPause,
    this.onResume,
  });

  @override
  State<ActiveCueControlStrip> createState() => _ActiveCueControlStripState();
}

class _ActiveCueControlStripState extends State<ActiveCueControlStrip>
    with SingleTickerProviderStateMixin {
  late final AnimationController _slideCtrl;
  late final Animation<double> _slideAnim;

  /// User-adjustable fade duration (ms). Defaults from cue params.
  double _fadeDurationMs = 1000.0;

  @override
  void initState() {
    super.initState();
    _slideCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 180),
    );
    _slideAnim = CurvedAnimation(parent: _slideCtrl, curve: Curves.easeOut);
    _slideCtrl.forward();
    _initFadeDuration();
  }

  void _initFadeDuration() {
    if (widget.cue.params case AudioParams p) {
      if (p.fadeOutMs > 0) _fadeDurationMs = p.fadeOutMs;
    }
  }

  @override
  void dispose() {
    _slideCtrl.dispose();
    super.dispose();
  }

  bool get _isPaused => widget.playhead.isCuePaused(widget.cue.id);

  @override
  Widget build(BuildContext context) {
    // Subscribe to shared ticker for live volume display.
    ScTick.of(context);

    final params = widget.cue.params;
    if (params is! AudioParams) return const SizedBox.shrink();

    return SizeTransition(
      sizeFactor: _slideAnim,
      axisAlignment: -1,
      child: Container(
        color: ScColors.surface2,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        child: Row(
          children: [
            // ── Fade duration picker ────────────────────────────────────
            _FadeDurationPicker(
              value: _fadeDurationMs,
              onChanged: (v) => setState(() => _fadeDurationMs = v),
            ),
            const SizedBox(width: 8),
            Container(width: 1, height: 20, color: ScColors.divider),
            const SizedBox(width: 8),

            // ── Fade Up ─────────────────────────────────────────────────
            _StripButton(
              icon: Icons.trending_up,
              label: 'Fade Up',
              color: ScColors.active,
              onPressed: widget.onFadeUp != null
                  ? () => widget.onFadeUp!(_fadeDurationMs)
                  : null,
            ),
            const SizedBox(width: 4),

            // ── Fade Out ────────────────────────────────────────────────
            _StripButton(
              icon: Icons.trending_down,
              label: 'Fade Out',
              color: ScColors.warn,
              onPressed: widget.onFadeOut != null
                  ? () => widget.onFadeOut!(_fadeDurationMs)
                  : null,
            ),
            const SizedBox(width: 8),
            Container(width: 1, height: 20, color: ScColors.divider),
            const SizedBox(width: 8),

            // ── Pause / Resume ──────────────────────────────────────────
            _StripButton(
              icon: _isPaused ? Icons.play_arrow : Icons.pause,
              label: _isPaused ? 'Resume' : 'Pause',
              color: ScColors.textSecondary,
              onPressed: _isPaused ? widget.onResume : widget.onPause,
            ),
            const SizedBox(width: 4),

            // ── Stop ────────────────────────────────────────────────────
            _StripButton(
              icon: Icons.stop,
              label: 'Stop',
              color: ScColors.error,
              onPressed: widget.onStop,
            ),

            // ── Level indicator (read-only) ─────────────────────────────
            const Spacer(),
            _LevelReadout(params: params),
          ],
        ),
      ),
    );
  }
}

// ── Fade Duration Picker ──────────────────────────────────────────────────────

/// Compact drag-field for fade duration selection.
/// Drag left/right to adjust; double-tap to reset to 1s.
class _FadeDurationPicker extends StatefulWidget {
  final double value;
  final ValueChanged<double> onChanged;

  const _FadeDurationPicker({required this.value, required this.onChanged});

  @override
  State<_FadeDurationPicker> createState() => _FadeDurationPickerState();
}

class _FadeDurationPickerState extends State<_FadeDurationPicker> {
  double _dragStart = 0;
  double _startValue = 0;

  static const _presets = [250.0, 500.0, 1000.0, 2000.0, 5000.0];

  String _fmt(double ms) {
    if (ms < 1000) return '${ms.toInt()}ms';
    return '${(ms / 1000).toStringAsFixed(1)}s';
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onHorizontalDragStart: (d) {
        _dragStart = d.globalPosition.dx;
        _startValue = widget.value;
      },
      onHorizontalDragUpdate: (d) {
        final delta = d.globalPosition.dx - _dragStart;
        final newVal = (_startValue + delta * 20).clamp(100.0, 30000.0);
        widget.onChanged(newVal);
      },
      onDoubleTap: () => widget.onChanged(1000.0),
      child: Tooltip(
        message: 'Fade-Dauer — Drag links/rechts, Doppelklick = 1s\nPresets: ${_presets.map(_fmt).join(', ')}',
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: ScColors.bg,
            borderRadius: BorderRadius.circular(4),
            border: Border.all(color: ScColors.divider),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.timer_outlined, size: 11, color: ScColors.textDim),
              const SizedBox(width: 4),
              Text(
                _fmt(widget.value),
                style: ScText.numberSmall.copyWith(fontSize: 11),
              ),
              const SizedBox(width: 2),
              const Icon(Icons.unfold_more, size: 11, color: ScColors.textDim),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Strip Button ──────────────────────────────────────────────────────────────

class _StripButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback? onPressed;

  const _StripButton({
    required this.icon,
    required this.label,
    required this.color,
    this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final enabled = onPressed != null;
    return Tooltip(
      message: label,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(4),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: enabled ? color.withValues(alpha: 0.10) : Colors.transparent,
            borderRadius: BorderRadius.circular(4),
            border: Border.all(
              color: enabled ? color.withValues(alpha: 0.35) : ScColors.divider,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 13,
                color: enabled ? color : ScColors.textDim,
              ),
              const SizedBox(width: 4),
              Text(
                label,
                style: ScText.label.copyWith(
                  color: enabled ? color : ScColors.textDim,
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Level Readout ─────────────────────────────────────────────────────────────

/// Read-only volume display from cue params — shows configured volume.
class _LevelReadout extends StatelessWidget {
  final AudioParams params;

  const _LevelReadout({required this.params});

  @override
  Widget build(BuildContext context) {
    final vol = params.volumeDb;
    final sign = vol >= 0 ? '+' : '';
    final color = vol > 0 ? ScColors.warn : ScColors.textDim;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.volume_up, size: 11, color: color),
        const SizedBox(width: 4),
        Text(
          '$sign${vol.toStringAsFixed(1)} dB',
          style: ScText.numberSmall.copyWith(fontSize: 11, color: color),
        ),
      ],
    );
  }
}
