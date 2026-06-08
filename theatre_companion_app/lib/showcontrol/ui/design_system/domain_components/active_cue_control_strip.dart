import 'package:flutter/material.dart';
import '../../../domain/show.dart';
import '../../../domain/cue_params.dart';
import '../../../domain/playhead.dart';
import '../sc_colors.dart';
import '../sc_typography.dart';

/// DAW-style runtime control strip below the active audio cue.
///
/// Adapts layout to available width:
/// - Wide (≥ 480px / desktop): single compact row — duration picker + buttons
/// - Narrow (< 480px / mobile): 2×2 button grid + duration row below
class ActiveCueControlStrip extends StatefulWidget {
  final Cue cue;
  final PlayheadState playhead;
  final ValueChanged<double>? onFadeUp;
  final ValueChanged<double>? onFadeOut;
  final VoidCallback? onStop;
  final VoidCallback? onPause;
  final VoidCallback? onResume;
  /// Called when the user commits a new fade duration (drag end / preset select).
  /// Parent should persist this to both fadeInMs and fadeOutMs of the cue.
  final ValueChanged<double>? onFadeDurationSaved;

  const ActiveCueControlStrip({
    super.key,
    required this.cue,
    required this.playhead,
    this.onFadeUp,
    this.onFadeOut,
    this.onStop,
    this.onPause,
    this.onResume,
    this.onFadeDurationSaved,
  });

  @override
  State<ActiveCueControlStrip> createState() => _ActiveCueControlStripState();
}

class _ActiveCueControlStripState extends State<ActiveCueControlStrip>
    with SingleTickerProviderStateMixin {
  late final AnimationController _slideCtrl;
  late final Animation<double> _slideAnim;
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
    _syncFadeDuration();
  }

  @override
  void didUpdateWidget(ActiveCueControlStrip old) {
    super.didUpdateWidget(old);
    // Re-sync fade duration when the cue params change from server (other device edited).
    if (old.cue.id != widget.cue.id || old.cue.params != widget.cue.params) {
      _syncFadeDuration();
    }
  }

  void _syncFadeDuration() {
    if (widget.cue.params case AudioParams p) {
      final ms = p.fadeOutMs > 0 ? p.fadeOutMs : (p.fadeInMs > 0 ? p.fadeInMs : 1000.0);
      if (ms != _fadeDurationMs) setState(() => _fadeDurationMs = ms);
    }
  }

  @override
  void dispose() {
    _slideCtrl.dispose();
    super.dispose();
  }

  bool get _isCuePaused    => widget.playhead.isCuePaused(widget.cue.id);
  bool get _isGlobalPaused => widget.playhead.isPaused;

  @override
  Widget build(BuildContext context) {
    final params = widget.cue.params;
    if (params is! AudioParams) return const SizedBox.shrink();

    // ── State-dependent button availability ──────────────────────────────────
    // Global pause: Fade Up/Out and per-cue Pause are meaningless — only Stop
    // and the transport-level Resume (in the main transport bar) make sense.
    // Per-cue paused: Fade Out is redundant; Pause is replaced by Resume.
    final canFadeUp  = !_isGlobalPaused && _isCuePaused     && widget.onFadeUp  != null;
    final canFadeOut = !_isGlobalPaused && !_isCuePaused    && widget.onFadeOut != null;
    final canPause   = !_isGlobalPaused && !_isCuePaused    && widget.onPause   != null;
    final canResume  = !_isGlobalPaused && _isCuePaused     && widget.onResume  != null;

    return SizeTransition(
      sizeFactor: _slideAnim,
      axisAlignment: -1,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final compact = constraints.maxWidth < 480;
          return compact
              ? _MobileLayout(
                  params: params,
                  isPaused: _isCuePaused,
                  fadeDurationMs: _fadeDurationMs,
                  onFadeDurationChanged: (v) => setState(() => _fadeDurationMs = v),
                  onFadeDurationSaved: widget.onFadeDurationSaved,
                  onFadeUp:  canFadeUp  ? () => widget.onFadeUp!(_fadeDurationMs)  : null,
                  onFadeOut: canFadeOut ? () => widget.onFadeOut!(_fadeDurationMs) : null,
                  onPause:   canPause   ? widget.onPause   : null,
                  onResume:  canResume  ? widget.onResume  : null,
                  onStop: widget.onStop,
                )
              : _DesktopLayout(
                  params: params,
                  isPaused: _isCuePaused,
                  fadeDurationMs: _fadeDurationMs,
                  onFadeDurationChanged: (v) => setState(() => _fadeDurationMs = v),
                  onFadeDurationSaved: widget.onFadeDurationSaved,
                  onFadeUp:  canFadeUp  ? () => widget.onFadeUp!(_fadeDurationMs)  : null,
                  onFadeOut: canFadeOut ? () => widget.onFadeOut!(_fadeDurationMs) : null,
                  onPause:   canPause   ? widget.onPause   : null,
                  onResume:  canResume  ? widget.onResume  : null,
                  onStop: widget.onStop,
                );
        },
      ),
    );
  }
}

// ── Desktop layout: compact horizontal row ────────────────────────────────────

class _DesktopLayout extends StatelessWidget {
  final AudioParams params;
  final bool isPaused;
  final double fadeDurationMs;
  final ValueChanged<double> onFadeDurationChanged;
  final ValueChanged<double>? onFadeDurationSaved;
  final VoidCallback? onFadeUp;
  final VoidCallback? onFadeOut;
  final VoidCallback? onPause;
  final VoidCallback? onResume;
  final VoidCallback? onStop;

  const _DesktopLayout({
    required this.params,
    required this.isPaused,
    required this.fadeDurationMs,
    required this.onFadeDurationChanged,
    this.onFadeDurationSaved,
    this.onFadeUp,
    this.onFadeOut,
    this.onPause,
    this.onResume,
    this.onStop,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: ScColors.surface2,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: Row(
        children: [
          _FadeDurationPicker(value: fadeDurationMs, onChanged: onFadeDurationChanged, onSaved: onFadeDurationSaved),
          const SizedBox(width: 8),
          _divider(),
          const SizedBox(width: 8),
          _StripButton(icon: Icons.trending_up,   label: 'Fade Up',  color: ScColors.active,         onPressed: onFadeUp),
          const SizedBox(width: 4),
          _StripButton(icon: Icons.trending_down, label: 'Fade Out', color: ScColors.warn,           onPressed: onFadeOut),
          const SizedBox(width: 8),
          _divider(),
          const SizedBox(width: 8),
          _StripButton(
            icon: isPaused ? Icons.play_arrow : Icons.pause,
            label: isPaused ? 'Resume' : 'Pause',
            color: ScColors.textSecondary,
            onPressed: isPaused ? onResume : onPause,
          ),
          const SizedBox(width: 4),
          _StripButton(icon: Icons.stop, label: 'Stop', color: ScColors.error, onPressed: onStop),
          const Spacer(),
          _LevelReadout(params: params),
        ],
      ),
    );
  }

  Widget _divider() => Container(width: 1, height: 20, color: ScColors.divider);
}

// ── Mobile layout: 2×2 grid + duration row ────────────────────────────────────

class _MobileLayout extends StatelessWidget {
  final AudioParams params;
  final bool isPaused;
  final double fadeDurationMs;
  final ValueChanged<double> onFadeDurationChanged;
  final ValueChanged<double>? onFadeDurationSaved;
  final VoidCallback? onFadeUp;
  final VoidCallback? onFadeOut;
  final VoidCallback? onPause;
  final VoidCallback? onResume;
  final VoidCallback? onStop;

  const _MobileLayout({
    required this.params,
    required this.isPaused,
    required this.fadeDurationMs,
    required this.onFadeDurationChanged,
    this.onFadeDurationSaved,
    this.onFadeUp,
    this.onFadeOut,
    this.onPause,
    this.onResume,
    this.onStop,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: ScColors.surface2,
      padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // ── 2×2 button grid ───────────────────────────────────────────
          Row(
            children: [
              Expanded(
                child: _MobileButton(
                  icon: Icons.trending_up,
                  label: 'Fade Up',
                  color: ScColors.active,
                  onPressed: onFadeUp,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _MobileButton(
                  icon: Icons.trending_down,
                  label: 'Fade Out',
                  color: ScColors.warn,
                  onPressed: onFadeOut,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              Expanded(
                child: _MobileButton(
                  icon: isPaused ? Icons.play_arrow : Icons.pause,
                  label: isPaused ? 'Resume' : 'Pause',
                  color: ScColors.textSecondary,
                  onPressed: isPaused ? onResume : onPause,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _MobileButton(
                  icon: Icons.stop,
                  label: 'Stop',
                  color: ScColors.error,
                  onPressed: onStop,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          // ── Fade duration + level: compact bottom row ─────────────────
          Row(
            children: [
              _FadeDurationPicker(
                value: fadeDurationMs,
                onChanged: onFadeDurationChanged,
                onSaved: onFadeDurationSaved,
                mobilePresets: true,
              ),
              const Spacer(),
              _LevelReadout(params: params),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Mobile button — full-width, taller touch target ───────────────────────────

class _MobileButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback? onPressed;

  const _MobileButton({
    required this.icon,
    required this.label,
    required this.color,
    this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final enabled = onPressed != null;
    return Material(
      color: enabled ? color.withValues(alpha: 0.10) : Colors.transparent,
      borderRadius: BorderRadius.circular(6),
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(6),
        child: Container(
          height: 44,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(6),
            border: Border.all(
              color: enabled ? color.withValues(alpha: 0.40) : ScColors.divider,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 16, color: enabled ? color : ScColors.textDim),
              const SizedBox(width: 6),
              Text(
                label,
                style: ScText.label.copyWith(
                  color: enabled ? color : ScColors.textDim,
                  fontSize: 12,
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

// ── Desktop strip button ──────────────────────────────────────────────────────

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
              Icon(icon, size: 13, color: enabled ? color : ScColors.textDim),
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

// ── Fade Duration Picker ──────────────────────────────────────────────────────

class _FadeDurationPicker extends StatefulWidget {
  final double value;
  final ValueChanged<double> onChanged;
  /// Called when user commits a value (drag end or preset picked).
  final ValueChanged<double>? onSaved;
  final bool mobilePresets;

  const _FadeDurationPicker({
    required this.value,
    required this.onChanged,
    this.onSaved,
    this.mobilePresets = false,
  });

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

  void _showPresetsMenu(BuildContext context) {
    final box = context.findRenderObject() as RenderBox?;
    if (box == null) return;
    final pos = box.localToGlobal(Offset.zero);
    final size = MediaQuery.sizeOf(context);
    showMenu<double>(
      context: context,
      color: ScColors.surface2,
      position: RelativeRect.fromLTRB(
        pos.dx, pos.dy + box.size.height,
        size.width - pos.dx - box.size.width, 0,
      ),
      items: _presets.map((p) => PopupMenuItem(
        value: p,
        height: 36,
        child: Text(_fmt(p), style: ScText.label),
      )).toList(),
    ).then((v) {
      if (v != null) {
        widget.onChanged(v);
        widget.onSaved?.call(v);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    // On mobile: tap opens preset menu (easier than horizontal drag)
    // On desktop: drag to adjust, double-tap to reset
    final inner = Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: ScColors.bg,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: ScColors.divider),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.timer_outlined, size: 12, color: ScColors.textDim),
          const SizedBox(width: 5),
          Text(
            _fmt(widget.value),
            style: ScText.numberSmall.copyWith(fontSize: 12),
          ),
          const SizedBox(width: 3),
          const Icon(Icons.expand_more, size: 12, color: ScColors.textDim),
        ],
      ),
    );

    if (widget.mobilePresets) {
      // Mobile: tap = preset menu
      return GestureDetector(
        onTap: () => _showPresetsMenu(context),
        child: inner,
      );
    }

    // Desktop: drag to adjust, double-tap = 1s, long-press = preset menu
    return GestureDetector(
      onHorizontalDragStart: (d) {
        _dragStart = d.globalPosition.dx;
        _startValue = widget.value;
      },
      onHorizontalDragUpdate: (d) {
        final delta = d.globalPosition.dx - _dragStart;
        widget.onChanged((_startValue + delta * 20).clamp(100.0, 30000.0));
      },
      onHorizontalDragEnd: (_) => widget.onSaved?.call(widget.value),
      onDoubleTap: () {
        widget.onChanged(1000.0);
        widget.onSaved?.call(1000.0);
      },
      onLongPress: () => _showPresetsMenu(context),
      child: Tooltip(
        message: 'Fade-Dauer — Drag, Doppelklick = 1s, Gedrückt halten = Presets',
        child: inner,
      ),
    );
  }
}

// ── Level Readout ─────────────────────────────────────────────────────────────

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
        Icon(Icons.volume_up, size: 12, color: color),
        const SizedBox(width: 4),
        Text(
          '$sign${vol.toStringAsFixed(1)} dB',
          style: ScText.numberSmall.copyWith(fontSize: 11, color: color),
        ),
      ],
    );
  }
}
