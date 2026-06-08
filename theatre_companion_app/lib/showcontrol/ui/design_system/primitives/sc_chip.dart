import 'package:flutter/material.dart';
import '../sc_colors.dart';
import '../sc_typography.dart';

enum ScChipState { ok, warn, error, idle, syncing }

/// Primitive status chip — no domain knowledge.
/// Used as base for [NodeStatusBadge] and cue-type badges.
class ScChip extends StatelessWidget {
  final String label;
  final ScChipState state;
  final bool showExpandArrow;
  final VoidCallback? onTap;
  final String? tooltip;

  const ScChip({
    super.key,
    required this.label,
    this.state = ScChipState.idle,
    this.showExpandArrow = false,
    this.onTap,
    this.tooltip,
  });

  static Color _color(ScChipState s) => switch (s) {
        ScChipState.ok => ScColors.active,
        ScChipState.warn => ScColors.warn,
        ScChipState.error => ScColors.error,
        ScChipState.idle => ScColors.past,
        ScChipState.syncing => const Color(0xFF42A5F5),
      };

  @override
  Widget build(BuildContext context) {
    final color = _color(state);

    Widget chip = Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        border: Border.all(color: color.withValues(alpha: 0.5)),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Status dot
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 6),
          Text(label, style: ScText.status.copyWith(color: color)),
          if (showExpandArrow) ...[
            const SizedBox(width: 4),
            Icon(Icons.expand_more, size: 12, color: color),
          ],
        ],
      ),
    );

    if (tooltip != null) {
      chip = Tooltip(message: tooltip!, child: chip);
    }

    if (onTap != null) {
      chip = GestureDetector(onTap: onTap, child: chip);
    }

    return chip;
  }
}

/// Small rectangular type badge (e.g. AUDIO, WAIT, MA).
class ScTypeBadge extends StatelessWidget {
  final String label;
  final Color color;

  const ScTypeBadge({super.key, required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Text(
        label,
        style: ScText.labelBold.copyWith(color: color, fontSize: 10),
      ),
    );
  }
}
