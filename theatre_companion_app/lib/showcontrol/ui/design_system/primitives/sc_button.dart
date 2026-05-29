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
class ScButton extends StatelessWidget {
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
  Widget build(BuildContext context) {
    final (color, onColor, isFilled) = switch (variant) {
      ScButtonVariant.primary   => (ScColors.active, Colors.black, true),
      ScButtonVariant.danger    => (ScColors.error, Colors.white, false),
      ScButtonVariant.secondary => (ScColors.warn, Colors.black, false),
      ScButtonVariant.ghost     => (ScColors.textDim, Colors.white, false),
    };

    final height = switch (size) {
      ScButtonSize.large   => ScSpacing.buttonHeightLarge,
      ScButtonSize.normal  => ScSpacing.buttonHeightDefault,
      ScButtonSize.compact => ScSpacing.buttonHeightCompact,
    };

    final content = isLoading
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
              if (size == ScButtonSize.large)
                _buildLargeContent(color, onColor)
              else
                _buildNormalContent(color, onColor),
              if (shortcutHint != null)
                Text(shortcutHint!, style: ScText.shortcutHint),
            ],
          );

    final decoration = BoxDecoration(
      color: isFilled ? (onPressed != null ? color : ScColors.past) : null,
      border: isFilled ? null : Border.all(color: color.withValues(alpha: 0.7)),
      borderRadius: BorderRadius.circular(size == ScButtonSize.large ? 16 : 8),
      boxShadow: isFilled && onPressed != null
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
      message: shortcutHint != null ? '$label  [$shortcutHint]' : label,
      child: GestureDetector(
        onTap: onPressed,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 120),
          height: height,
          decoration: decoration,
          padding: EdgeInsets.symmetric(
            horizontal: size == ScButtonSize.compact ? 10 : 16,
          ),
          child: Center(child: content),
        ),
      ),
    );
  }

  Widget _buildLargeContent(Color color, Color onColor) {
    return Text(
      label,
      style: ScText.goButton.copyWith(
        color: onPressed != null ? onColor : ScColors.textDim,
      ),
    );
  }

  Widget _buildNormalContent(Color color, Color onColor) {
    final textColor = onPressed != null ? color : ScColors.textDim;
    if (icon != null) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: textColor),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              color: textColor,
              fontSize: size == ScButtonSize.compact ? 11 : 13,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      );
    }
    return Text(
      label,
      style: TextStyle(
        color: textColor,
        fontSize: size == ScButtonSize.compact ? 11 : 13,
        fontWeight: FontWeight.w700,
      ),
    );
  }
}
