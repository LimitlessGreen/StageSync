import 'package:flutter/material.dart';
import '../../../domain/show.dart';
import '../../../domain/cue_params.dart';
import '../../../domain/playhead.dart';
import '../sc_colors.dart';
import '../sc_typography.dart';
import '../sc_spacing.dart';
import '../primitives/sc_chip.dart';

/// A single row in the cue list.
/// Knows the domain [Cue] type and optional [CueRunState] — no proto/gRPC.
///
/// Compact variant (48px): used in the desktop cue list editor.
/// Expanded variant (80px): used in GoScreen for the active cue.
class CueListRow extends StatelessWidget {
  final Cue cue;
  final CueRunState? runState;
  final bool isActive;
  final bool isPast;
  final bool isSelected;
  final bool expanded; // 80px active mode vs 48px compact

  /// Desktop: show drag handle for reorder.
  final bool showDragHandle;
  final int? dragIndex; // required when showDragHandle = true

  final VoidCallback? onTap;
  final VoidCallback? onDelete;
  final VoidCallback? onGo; // context menu "Go here"

  const CueListRow({
    super.key,
    required this.cue,
    this.runState,
    this.isActive = false,
    this.isPast = false,
    this.isSelected = false,
    this.expanded = false,
    this.showDragHandle = false,
    this.dragIndex,
    this.onTap,
    this.onDelete,
    this.onGo,
  });

  bool get hasError => runState?.lifecycle == CueLifecycle.error;
  bool get isPaused => runState?.lifecycle == CueLifecycle.paused;

  Color get _stateColor => ScColors.forCueState(
        isActive: isActive,
        isPast: isPast,
        isError: hasError,
        isPaused: isPaused,
      );

  @override
  Widget build(BuildContext context) {
    final height = expanded ? ScSpacing.rowHeightActive : ScSpacing.rowHeight;

    Widget row = Container(
      height: height,
      color: isSelected
          ? ScColors.selected
          : isActive
              ? ScColors.active.withValues(alpha: 0.06)
              : Colors.transparent,
      child: Stack(
        children: [
          // Left accent bar for active/error state
          if (isActive || hasError)
            Positioned(
              left: 0,
              top: 0,
              bottom: 0,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: 3,
                color: _stateColor,
              ),
            ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Row(
              children: [
                // Cue number
                SizedBox(
                  width: ScSpacing.cueNumberWidth,
                  child: Text(
                    cue.number,
                    style: (isActive
                            ? ScText.numberLarge
                            : ScText.number)
                        .copyWith(color: _stateColor),
                    textAlign: TextAlign.right,
                  ),
                ),
                const SizedBox(width: 8),
                // Type icon
                SizedBox(
                  width: ScSpacing.cueTypeIconWidth,
                  child: Icon(
                    _typeIcon(cue.params),
                    size: 14,
                    color: _typeColor(cue.params),
                  ),
                ),
                const SizedBox(width: 8),
                // Label
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        cue.label,
                        style: isPast
                            ? ScText.cueLabelPast
                            : isActive
                                ? ScText.cueLabelActive
                                : ScText.cueLabel,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (expanded && runState != null)
                        _NodeStateRow(runState: runState!),
                    ],
                  ),
                ),
                // Duration
                SizedBox(
                  width: ScSpacing.cueDurationWidth,
                  child: Text(
                    _formatDuration(cue.displayDurationMs),
                    style: ScText.numberSmall,
                    textAlign: TextAlign.right,
                  ),
                ),
                // Status dot
                SizedBox(
                  width: ScSpacing.cueStatusDotWidth,
                  child: Center(child: _statusDot()),
                ),
                // Desktop controls
                if (showDragHandle && onDelete != null) ...[
                  IconButton(
                    icon: const Icon(Icons.delete_outline, size: 16),
                    onPressed: onDelete,
                    color: ScColors.error,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
                  ),
                ],
                if (showDragHandle && dragIndex != null)
                  ReorderableDragStartListener(
                    index: dragIndex!,
                    child: const Icon(
                      Icons.drag_handle,
                      size: 18,
                      color: ScColors.textDim,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );

    if (onTap != null || onGo != null) {
      row = GestureDetector(
        onTap: onTap,
        onSecondaryTapUp: onGo != null
            ? (details) => _showContextMenu(context, details.localPosition)
            : null,
        child: row,
      );
    }

    return row;
  }

  void _showContextMenu(BuildContext context, Offset localPosition) {
    // Context menu for desktop right-click — opens at cursor position.
    final RenderBox box = context.findRenderObject() as RenderBox;
    final Offset global = box.localToGlobal(localPosition);
    final size = MediaQuery.sizeOf(context);
    showMenu<String>(
      context: context,
      position: RelativeRect.fromLTRB(
        global.dx,
        global.dy,
        size.width - global.dx,
        size.height - global.dy,
      ),
      color: ScColors.surface2,
      items: [
        if (onGo != null)
          const PopupMenuItem(value: 'go', child: Text('GO here')),
        if (onDelete != null)
          const PopupMenuItem(value: 'delete', child: Text('Delete')),
      ],
    ).then((v) {
      if (v == 'go') onGo?.call();
      if (v == 'delete') onDelete?.call();
    });
  }

  Widget _statusDot() {
    if (!isActive && !hasError && !isPaused) return const SizedBox.shrink();
    return Container(
      width: 8,
      height: 8,
      decoration: BoxDecoration(
        color: _stateColor,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(color: _stateColor.withValues(alpha: 0.5), blurRadius: 4),
        ],
      ),
    );
  }

  static String _formatDuration(double? ms) {
    if (ms == null) return '';
    if (ms < 1000) return '${ms.toInt()}ms';
    final s = ms / 1000;
    if (s < 60) return '${s.toStringAsFixed(1)}s';
    final m = (s / 60).floor();
    final rs = (s % 60).toStringAsFixed(0).padLeft(2, '0');
    return '$m:$rs';
  }

  static IconData _typeIcon(CueParams p) => switch (p) {
        AudioParams()  => Icons.volume_up,
        WaitParams()   => Icons.timer_outlined,
        MaOscParams()  => Icons.light_mode,
        GroupParams()  => Icons.folder_outlined,
        GotoParams()   => Icons.redo,
        OscParams()    => Icons.settings_ethernet,
        MidiParams()   => Icons.piano,
        ScriptParams() => Icons.code,
      };

  static Color _typeColor(CueParams p) => switch (p) {
        AudioParams()  => Colors.blue,
        WaitParams()   => Colors.purple,
        MaOscParams()  => Colors.orange,
        GroupParams()  => Colors.teal,
        GotoParams()   => Colors.cyan,
        OscParams()    => Colors.lime,
        MidiParams()   => Colors.pink,
        ScriptParams() => Colors.grey,
      };
}

class _NodeStateRow extends StatelessWidget {
  final CueRunState runState;
  const _NodeStateRow({required this.runState});

  @override
  Widget build(BuildContext context) {
    if (runState.nodes.isEmpty) return const SizedBox.shrink();
    return Wrap(
      spacing: 4,
      children: runState.nodes.entries.map((e) {
        final phase = e.value.phase;
        return ScChip(
          label: e.key.substring(0, 4).toUpperCase(),
          state: phase == NodeExecPhase.error
              ? ScChipState.error
              : phase == NodeExecPhase.playing
                  ? ScChipState.ok
                  : ScChipState.idle,
        );
      }).toList(),
    );
  }
}
