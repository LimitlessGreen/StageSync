import 'package:flutter/material.dart';
import '../sc_colors.dart';
import '../sc_spacing.dart';

/// Column headers for the cue list — mirrors the exact spacings of [CueListRow].
///
/// Domain-aware (knows column meanings) but carries no state or callbacks.
class CueListHeader extends StatelessWidget {
  /// True when drag handles are shown, so the header can reserve the same space.
  final bool showDragHandle;

  const CueListHeader({super.key, this.showDragHandle = false});

  static const _labelStyle = TextStyle(
    color: ScColors.textDim,
    fontSize: 9,
    fontWeight: FontWeight.w700,
    letterSpacing: 0.8,
  );

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 24,
      color: ScColors.surface,
      padding: const EdgeInsets.symmetric(horizontal: 6),
      child: Row(
        children: [
          // Type icon placeholder
          SizedBox(width: ScSpacing.cueTypeIconWidth),
          const SizedBox(width: 6),

          // Cue number column
          SizedBox(
            width: ScSpacing.cueNumberWidth,
            child: const Text('#', style: _labelStyle),
          ),

          // Label — fills remaining space
          const Expanded(
            child: Text('BEZEICHNUNG', style: _labelStyle),
          ),

          // Duration column
          SizedBox(
            width: ScSpacing.cueDurationWidth,
            child: const Text(
              'DAUER',
              style: _labelStyle,
              textAlign: TextAlign.right,
            ),
          ),
          const SizedBox(width: 4),

          // Pre-wait column
          SizedBox(
            width: 44,
            child: const Text(
              'PRE',
              style: _labelStyle,
              textAlign: TextAlign.right,
            ),
          ),
          const SizedBox(width: 4),

          // Status dot column
          SizedBox(width: ScSpacing.cueStatusDotWidth),

          // Drag handle placeholder
          if (showDragHandle) const SizedBox(width: 24),

          const SizedBox(width: 2), // right padding
        ],
      ),
    );
  }
}
