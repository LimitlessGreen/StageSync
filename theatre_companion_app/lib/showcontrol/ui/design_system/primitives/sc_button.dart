import 'package:flutter/material.dart';
import '../sc_colors.dart';
import '../sc_spacing.dart';
import '../sc_typography.dart';

enum ScButtonVariant { primary, danger, secondary, ghost }
enum ScButtonSize { large, normal, compact }

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

class _ScButtonState extends State<ScButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final enabled = widget.onPressed != null && !widget.isLoading;

    final (color, onColor, isFilled) = switch (widget.variant) {
      ScButtonVariant.primary   => (ScColors.active, Colors.black, true),
      ScButtonVariant.danger    => (ScColors.error, Colors.white, false),
      ScButtonVariant.secondary => (ScColors.warn, Colors.black, false),
      ScButtonVariant.ghost     => (ScColors.textDim, Colors.white, false),
    };

    final height = switch (widget.size) {
      ScButtonSize.large   => ScSpacing.buttonHeightLarge,
      ScButtonSize.normal  => ScSpacing.buttonHeightDefault,
      ScButtonSize.compact => ScSpacing.buttonHeightCompact,
    };

    // Visual states
    final pressAlpha = _pressed && enabled ? 0.55 : 1.0;
    final effectiveColor = Color.fromRGBO(
      color.r.round(), color.g.round(), color.b.round(),
      pressAlpha,
    );

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
              if (widget.size == ScButtonSize.large)
                _buildLargeContent(effectiveColor, onColor, enabled)
              else
                _buildNormalContent(effectiveColor, onColor, enabled, isFilled),
              if (widget.shortcutHint != null)
                Text(widget.shortcutHint!, style: ScText.shortcutHint),
            ],
          );

    final decoration = BoxDecoration(
      color: isFilled
          ? (enabled
              ? (isFilled ? effectiveColor : null)
              : ScColors.past)
          : (_pressed && enabled
              ? color.withValues(alpha: 0.12)
              : null),
      border: isFilled
          ? null
          : Border.all(color: effectiveColor.withValues(alpha: enabled ? 0.7 : 0.3)),
      borderRadius: BorderRadius.circular(widget.size == ScButtonSize.large ? 16 : 8),
      boxShadow: isFilled && enabled && !_pressed
          ? [
              BoxShadow(
                color: color.withValues(alpha: 0.3),
                blurRadius: 16,
                spreadRadius: 1,
              )
            ]
          : null,
    );

    return Tooltip(
      message: widget.shortcutHint != null
          ? '${widget.label}  [${widget.shortcutHint}]'
          : widget.label,
      child: GestureDetector(
        onTapDown: enabled ? (_) => setState(() => _pressed = true) : null,
        onTapUp: enabled
            ? (_) {
                setState(() => _pressed = false);
                widget.onPressed?.call();
              }
            : null,
        onTapCancel: enabled ? () => setState(() => _pressed = false) : null,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 80),
          height: height,
          decoration: decoration,
          padding: EdgeInsets.symmetric(
            horizontal: widget.size == ScButtonSize.compact ? 10 : 16,
          ),
          child: Center(child: content),
        ),
      ),
    );
  }

  Widget _buildLargeContent(Color color, Color onColor, bool enabled) {
    return Text(
      widget.label,
      style: ScText.goButton.copyWith(
        color: enabled ? onColor : ScColors.textDim,
      ),
    );
  }

  Widget _buildNormalContent(Color color, Color onColor, bool enabled, bool isFilled) {
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
