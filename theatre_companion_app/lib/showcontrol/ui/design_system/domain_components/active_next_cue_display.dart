import 'package:flutter/material.dart';
import '../../../domain/show.dart';
import '../../../domain/playhead.dart';
import '../sc_colors.dart';
import '../sc_typography.dart';
import '../sc_spacing.dart';
import 'cue_list_row.dart';

/// Compact header showing the active cue and the upcoming cue with a progress bar.
///
/// Replaces the old _ProgressHeader on mobile. Also usable on desktop monitor panel.
class ActiveNextCueDisplay extends StatelessWidget {
  final CueList? cueList;
  final PlayheadState playhead;

  const ActiveNextCueDisplay({
    super.key,
    required this.cueList,
    required this.playhead,
  });

  @override
  Widget build(BuildContext context) {
    final cues = cueList?.cues ?? [];
    final total = cues.length;
    final activeIdx = playhead.activeCueId != null
        ? cues.indexWhere((c) => c.id == playhead.activeCueId)
        : -1;
    final activeCue = activeIdx >= 0 ? cues[activeIdx] : null;
    final nextCue =
        (activeIdx >= 0 && activeIdx + 1 < total) ? cues[activeIdx + 1] : null;
    final progress =
        total == 0 ? 0.0 : ((activeIdx + 1) / total).clamp(0.0, 1.0);

    return Container(
      color: ScColors.surface,
      padding: const EdgeInsets.fromLTRB(
        ScSpacing.panelPad,
        8,
        ScSpacing.panelPad,
        10,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Active cue row
          if (activeCue != null) ...[
            _CueInfoRow(
              cue: activeCue,
              roleLabel: 'AKTIV',
              roleColor: ScColors.active,
              labelColor: ScColors.textPrimary,
              bold: true,
            ),
            const SizedBox(height: 4),
          ],

          // Next cue row
          if (nextCue != null)
            _CueInfoRow(
              cue: nextCue,
              roleLabel: 'NEXT',
              roleColor: ScColors.textDim,
              labelColor: ScColors.textSecondary,
              bold: false,
            )
          else if (activeCue == null)
            Text(
              total == 0 ? 'Keine Cues' : '$total Cues · Bereit',
              style: ScText.statusSmall,
            ),

          const SizedBox(height: 8),

          // Progress bar + counter
          Row(
            children: [
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(2),
                  child: LinearProgressIndicator(
                    value: progress,
                    backgroundColor: ScColors.divider,
                    valueColor:
                        const AlwaysStoppedAnimation<Color>(ScColors.active),
                    minHeight: 3,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                activeIdx >= 0 ? '${activeIdx + 1} / $total' : '$total',
                style: ScText.statusSmall.copyWith(color: ScColors.textDim),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _CueInfoRow extends StatelessWidget {
  final Cue cue;
  final String roleLabel;
  final Color roleColor;
  final Color labelColor;
  final bool bold;

  const _CueInfoRow({
    required this.cue,
    required this.roleLabel,
    required this.roleColor,
    required this.labelColor,
    required this.bold,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        // Role pill
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
          decoration: BoxDecoration(
            color: roleColor.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(3),
          ),
          child: Text(
            roleLabel,
            style: ScText.statusSmall.copyWith(
              color: roleColor,
              fontWeight: FontWeight.w700,
              fontSize: 9,
            ),
          ),
        ),
        const SizedBox(width: 6),

        // Type icon
        Icon(
          CueListRow.typeIcon(cue.params),
          size: 12,
          color: CueListRow.typeColor(cue.params),
        ),
        const SizedBox(width: 4),

        // Cue number
        Text(
          cue.number,
          style: ScText.numberSmall.copyWith(
            color: labelColor,
            fontWeight: bold ? FontWeight.w700 : FontWeight.w500,
          ),
        ),
        const SizedBox(width: 4),

        // Cue label
        Expanded(
          child: Text(
            cue.label,
            style: ScText.cueLabel.copyWith(
              color: labelColor,
              fontSize: bold ? 13 : 12,
              fontWeight: bold ? FontWeight.w600 : FontWeight.normal,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}
