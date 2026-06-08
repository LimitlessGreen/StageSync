import 'package:flutter/material.dart';
import '../sc_colors.dart';
import '../sc_spacing.dart';
import '../sc_typography.dart';

enum ScButtonVariant { primary, danger, secondary, ghost }

/// [large]     → 80px (mobile full-screen GO)
/// [transport] → 44px (desktop transport-bar GO, visually dominant)
/// [normal]    → 36px
/// [compact]   → 28px
enum ScButtonSize { large, transport, normal, compact }

/// Primitive SC button — no domain knowledge.
///
/// [primary]   → GO-style (green fill)
/// [danger]    → STOP-style (red outlined or fill)
/// [secondary] → PAUSE/RESUME-style (amber outlined)
/// [ghost]     → toolbar icon-buttons (transparent)
class ScButton extends StatefulWidget {
  final String label;
  final IconData? icon;
  final VoidCallback? onPressed;
  final ScButtonVariant variant;
  final ScButtonSize size;
  final bool isLoading;
  final String? shortcutHint; // shown below label on desktop

  const ScButton({
    super.key,
    required this.label,
    this.icon,
    this.onPressed,
    this.variant = ScButtonVariant.primary,
    this.size = ScButtonSize.normal,
    this.isLoading = false,
    this.shortcutHint,
  });

  @override
  State<ScButton> createState() => _ScButtonState();
}

class _ScButtonState extends State<ScButton> with TickerProviderStateMixin {
  bool _pressed = false;
  late final AnimationController _bounceCtrl;
  late final Animation<double> _scaleAnim;
  late final AnimationController _pulseCtrl;
  late final Animation<double> _glowAnim;

  @override
  void initState() {
    super.initState();
    _bounceCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 320),
    );
    _scaleAnim = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween(begin: 1.0, end: 0.93)
            .chain(CurveTween(curve: Curves.easeIn)),
        weight: 25,
      ),
      TweenSequenceItem(
        tween: Tween(begin: 0.93, end: 1.06)
            .chain(CurveTween(curve: Curves.easeOut)),
        weight: 45,
      ),
      TweenSequenceItem(
        tween: Tween(begin: 1.06, end: 1.0)
            .chain(CurveTween(curve: Curves.elasticOut)),
        weight: 30,
      ),
    ]).animate(_bounceCtrl);

    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat(reverse: true);
    _glowAnim = Tween<double>(begin: 0.0, end: 1.0)
        .animate(CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _bounceCtrl.dispose();
    _pulseCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final enabled = widget.onPressed != null && !widget.isLoading;

    final (color, onColor, isFilled) = switch (widget.variant) {
      ScButtonVariant.primary => (ScColors.active, Colors.black, true),
      ScButtonVariant.danger => (ScColors.error, Colors.white, false),
      ScButtonVariant.secondary => (ScColors.warn, Colors.black, false),
      ScButtonVariant.ghost => (ScColors.textDim, Colors.white, false),
    };

    final height = switch (widget.size) {
      ScButtonSize.large => ScSpacing.buttonHeightLarge,
      ScButtonSize.transport => 44.0,
      ScButtonSize.normal => ScSpacing.buttonHeightDefault,
      ScButtonSize.compact => ScSpacing.buttonHeightCompact,
    };

    // Visual states — withValues(alpha:) is the correct way to tint;
    // Color.fromRGBO(.r/.g/.b) is wrong because .r/.g/.b return 0.0–1.0.
    final effectiveColor =
        _pressed && enabled ? color.withValues(alpha: 0.55) : color;

    final content = widget.isLoading
        ? SizedBox(
            width: 18,
            height: 18,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: isFilled ? onColor : color,
            ),
          )
        : Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (widget.size == ScButtonSize.large ||
                  widget.size == ScButtonSize.transport)
                _buildLargeContent(effectiveColor, onColor, enabled)
              else
                _buildNormalContent(effectiveColor, onColor, enabled, isFilled),
              if (widget.shortcutHint != null)
                Text(widget.shortcutHint!, style: ScText.shortcutHint),
            ],
          );

    // Primary+enabled: pulsing halo via AnimatedBuilder.
    // Other variants: static shadow or none.
    final isPrimaryEnabled = isFilled && enabled;

    BoxDecoration buildDeco(double glowT) {
      final blurRadius = isPrimaryEnabled && !_pressed
          ? 12.0 + glowT * 14.0 // 12 → 26
          : 0.0;
      final glowAlpha = isPrimaryEnabled && !_pressed
          ? 0.22 + glowT * 0.22 // 0.22 → 0.44
          : 0.0;
      return BoxDecoration(
        color: isFilled
            ? (enabled ? effectiveColor : ScColors.past)
            : (_pressed && enabled ? color.withValues(alpha: 0.12) : null),
        border: isFilled
            ? null
            : Border.all(
                color: effectiveColor.withValues(alpha: enabled ? 0.7 : 0.3)),
        borderRadius:
            BorderRadius.circular(widget.size == ScButtonSize.large ? 16 : 8),
        boxShadow: blurRadius > 0
            ? [
                BoxShadow(
                  color: color.withValues(alpha: glowAlpha),
                  blurRadius: blurRadius,
                  spreadRadius: 2,
                ),
              ]
            : null,
      );
    }

    return Tooltip(
      message: widget.shortcutHint != null
          ? '${widget.label}  [${widget.shortcutHint}]'
          : widget.label,
      child: GestureDetector(
        onTapDown: enabled ? (_) => setState(() => _pressed = true) : null,
        onTapUp: enabled
            ? (_) {
                setState(() => _pressed = false);
                _bounceCtrl.forward(from: 0);
                widget.onPressed?.call();
              }
            : null,
        onTapCancel: enabled ? () => setState(() => _pressed = false) : null,
        child: ScaleTransition(
          scale: _scaleAnim,
          child: isPrimaryEnabled
              ? AnimatedBuilder(
                  animation: _glowAnim,
                  builder: (context, child) => Container(
                    height: height,
                    decoration: buildDeco(_glowAnim.value),
                    padding: EdgeInsets.symmetric(
                      horizontal: widget.size == ScButtonSize.compact ? 10 : 16,
                    ),
                    child: Center(child: content),
                  ),
                )
              : AnimatedContainer(
                  duration: const Duration(milliseconds: 80),
                  height: height,
                  decoration: buildDeco(0),
                  padding: EdgeInsets.symmetric(
                    horizontal: widget.size == ScButtonSize.compact ? 10 : 16,
                  ),
                  child: Center(child: content),
                ),
        ),
      ),
    );
  }

  Widget _buildLargeContent(Color color, Color onColor, bool enabled) {
    final isTransport = widget.size == ScButtonSize.transport;
    return Text(
      widget.label,
      style: (isTransport
              ? ScText.goButton.copyWith(fontSize: 18, letterSpacing: 4)
              : ScText.goButton)
          .copyWith(
        color: enabled ? onColor : ScColors.textDim,
      ),
    );
  }

  Widget _buildNormalContent(
      Color color, Color onColor, bool enabled, bool isFilled) {
    // Filled buttons (primary): use onColor so text is readable on the fill.
    // Outlined/ghost buttons: use color (the accent) as text color.
    final textColor = enabled ? (isFilled ? onColor : color) : ScColors.textDim;
    if (widget.icon != null) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(widget.icon, size: 16, color: textColor),
          const SizedBox(width: 6),
          Text(
            widget.label,
            style: TextStyle(
              color: textColor,
              fontSize: widget.size == ScButtonSize.compact ? 11 : 13,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      );
    }
    return Text(
      widget.label,
      style: TextStyle(
        color: textColor,
        fontSize: widget.size == ScButtonSize.compact ? 11 : 13,
        fontWeight: FontWeight.w700,
      ),
    );
  }
}
