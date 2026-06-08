import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../domain/show.dart';
import '../../../providers/show_control_provider.dart';
import '../sc_colors.dart';
import '../sc_spacing.dart';
import '../primitives/sc_button.dart';
import 'cue_inspector.dart';
import 'cue_list_row.dart';

/// Shows a draggable bottom sheet with the full [CueInspector].
///
/// Delegates all editing to [CueInspector] — no separate param logic here,
/// so mobile and desktop always have identical editing capabilities.
Future<void> showCueDetailSheet(
  BuildContext context,
  Cue cue,
  ShowControlNotifier notifier,
) {
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => _CueDetailSheet(cue: cue, notifier: notifier),
  );
}

class _CueDetailSheet extends ConsumerWidget {
  final Cue cue;
  final ShowControlNotifier notifier;

  const _CueDetailSheet({required this.cue, required this.notifier});

  void _goToCue(BuildContext context) {
    notifier.goToCue(cue.id);
    Navigator.pop(context);
  }

  void _deleteCue(BuildContext context) {
    Navigator.pop(context);
    notifier.deleteCueById(cue.id);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final typeColor = CueListRow.typeColor(cue.params);
    final typeIcon = CueListRow.typeIcon(cue.params);

    return DraggableScrollableSheet(
      initialChildSize: 0.75,
      minChildSize: 0.4,
      maxChildSize: 0.95,
      expand: false,
      builder: (_, scrollCtrl) => Container(
        decoration: const BoxDecoration(
          color: ScColors.surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
        ),
        child: Column(
          children: [
            // ── Drag handle ──────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 10),
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: ScColors.divider,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            // ── Cue type badge + label ───────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(
                ScSpacing.panelPad,
                0,
                ScSpacing.panelPad,
                10,
              ),
              child: Row(
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: typeColor.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(typeIcon, size: 16, color: typeColor),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      '${cue.number}  ${cue.label}',
                      style: TextStyle(
                        color: ScColors.textPrimary,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
            const Divider(height: 1, color: ScColors.divider),

            // ── Full inspector ───────────────────────────────────────────
            Expanded(
              child: CueInspector(
                cue: cue,
                notifier: notifier,
                scrollController: scrollCtrl,
                showHeader: false,
              ),
            ),

            // ── Action bar ───────────────────────────────────────────────
            const Divider(height: 1, color: ScColors.divider),
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                  ScSpacing.panelPad,
                  8,
                  ScSpacing.panelPad,
                  12,
                ),
                child: Row(
                  children: [
                    SizedBox(
                      width: 48,
                      height: 48,
                      child: IconButton(
                        icon: const Icon(Icons.delete_outline),
                        color: ScColors.error,
                        onPressed: () => _deleteCue(context),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: ScButton(
                        label: 'ZU DIESEM CUE',
                        variant: ScButtonVariant.primary,
                        size: ScButtonSize.normal,
                        onPressed: () => _goToCue(context),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
