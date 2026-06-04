import 'package:flutter/material.dart';

import '../../../domain/show.dart';
import '../../../domain/cue_params.dart';
import '../../../domain/playhead.dart';
import '../../../providers/show_control_provider.dart';
import '../sc_colors.dart';
import '../sc_spacing.dart';
import '../sc_typography.dart';
import 'cue_list_row.dart';
import 'cue_list_header.dart';
import 'active_cue_control_strip.dart';
import 'cue_type_picker.dart';

/// Reusable cue list panel: header bar, column headers, scrollable cue rows.
///
/// Features:
/// - ReorderableListView with drag handles
/// - Group expansion with SEQUENTIAL/PARALLEL badge
/// - ActiveCueControlStrip below running audio cues
/// - Context menu (insert before/after, duplicate, group, delete)
/// - Past-cue dimming
///
/// Used by [DesktopShell] (left panel) and [CueEditorScreen].
class CueListPanel extends StatelessWidget {
  final CueList? cueList;
  final PlayheadState playhead;
  final String? selectedCueId;
  final ValueChanged<String?> onCueSelected;
  final ShowControlNotifier notifier;

  const CueListPanel({
    super.key,
    required this.cueList,
    required this.playhead,
    required this.selectedCueId,
    required this.onCueSelected,
    required this.notifier,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // ── Header bar ─────────────────────────────────────────────────
        Container(
          height: 36,
          color: ScColors.surface,
          padding: const EdgeInsets.symmetric(horizontal: ScSpacing.panelPad),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  cueList?.name.toUpperCase() ?? 'CUE LIST',
                  style: ScText.panelTitle,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Builder(
                builder: (btnCtx) => IconButton(
                  icon: const Icon(Icons.add, size: 18),
                  color: ScColors.textSecondary,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
                  tooltip: 'Cue hinzufügen',
                  onPressed: () async {
                    final params = await showCueTypePicker(btnCtx);
                    if (params != null) notifier.addCue(params: params);
                  },
                ),
              ),
            ],
          ),
        ),
        const Divider(height: 1, color: ScColors.divider),
        const CueListHeader(showDragHandle: true),
        const Divider(height: 1, color: ScColors.divider),
        // ── Cue rows ───────────────────────────────────────────────────
        Expanded(
          child: cueList == null
              ? const Center(
                  child: Text('Keine CueList',
                      style: TextStyle(color: ScColors.textDim)))
              : _CueListView(
                  cueList: cueList!,
                  playhead: playhead,
                  selectedCueId: selectedCueId,
                  onCueSelected: onCueSelected,
                  notifier: notifier,
                ),
        ),
      ],
    );
  }
}

// ── Scrollable reorderable cue list ──────────────────────────────────────────

class _CueListView extends StatefulWidget {
  final CueList cueList;
  final PlayheadState playhead;
  final String? selectedCueId;
  final ValueChanged<String?> onCueSelected;
  final ShowControlNotifier notifier;

  const _CueListView({
    required this.cueList,
    required this.playhead,
    required this.selectedCueId,
    required this.onCueSelected,
    required this.notifier,
  });

  @override
  State<_CueListView> createState() => _CueListViewState();
}

class _CueListViewState extends State<_CueListView> {
  final Set<String> _expandedGroups = {};

  Set<String> _childIds(List<Cue> cues) {
    final s = <String>{};
    for (final c in cues) {
      if (c.params case GroupParams gp) s.addAll(gp.childCueIds);
    }
    return s;
  }

  static bool _isCuePast(Cue cue, CueList list, PlayheadState playhead) {
    final activeId = playhead.activeCueId;
    if (activeId == null) return false;
    final activeIdx = list.cues.indexWhere((c) => c.id == activeId);
    final thisIdx   = list.cues.indexWhere((c) => c.id == cue.id);
    return thisIdx < activeIdx;
  }

  Future<void> _insertCue(BuildContext context, {String? afterId, String? beforeId}) async {
    final params = await showCueTypePicker(context);
    if (params == null) return;
    if (beforeId != null) {
      final idx = widget.cueList.cues.indexWhere((c) => c.id == beforeId);
      final prevId = idx > 0 ? widget.cueList.cues[idx - 1].id : null;
      await widget.notifier.insertDomainCue(params, afterId: prevId);
    } else {
      await widget.notifier.insertDomainCue(params, afterId: afterId);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cues = widget.cueList.cues;
    final childIds = _childIds(cues);
    final topLevel = cues.where((c) => !childIds.contains(c.id)).toList();

    return ReorderableListView.builder(
      itemCount: topLevel.length,
      onReorder: (oldIndex, newIndex) {
        if (newIndex > oldIndex) newIndex--;
        final tlIds = topLevel.map((c) => c.id).toList();
        final moved = tlIds.removeAt(oldIndex);
        tlIds.insert(newIndex, moved);
        final childCues = cues.where((c) => childIds.contains(c.id)).toList();
        widget.notifier.reorderCue(
            orderedIds: [...tlIds, ...childCues.map((c) => c.id)]);
      },
      proxyDecorator: (child, _, __) => Material(
        elevation: 4,
        color: ScColors.surface2,
        borderRadius: BorderRadius.circular(4),
        child: child,
      ),
      itemBuilder: (context, i) {
        final cue = topLevel[i];
        final isGroup    = cue.params is GroupParams;
        final isExpanded = _expandedGroups.contains(cue.id);
        final isRunning  = widget.playhead.runningCueIds.contains(cue.id);
        final isActive   = widget.playhead.activeCueId == cue.id;
        final isPast     = !isRunning && _isCuePast(cue, widget.cueList, widget.playhead);

        final groupChildren = isGroup
            ? (cue.params as GroupParams)
                .childCueIds
                .map((id) => cues.firstWhere((c) => c.id == id, orElse: () => cue))
                .where((c) => c.id != cue.id)
                .toList()
            : null;

        final row = CueListRow(
          key: ValueKey('row_${cue.id}'),
          cue: cue,
          runState: widget.playhead.runStateFor(cue.id),
          playhead: widget.playhead,
          isActive: isActive,
          isPast: isPast,
          isSelected: widget.selectedCueId == cue.id,
          expanded: isRunning,
          showDragHandle: true,
          dragIndex: i,
          groupChildren: groupChildren,
          isGroupExpanded: isExpanded,
          childRunStates: {
            for (final child in groupChildren ?? <Cue>[])
              if (widget.playhead.runStateFor(child.id) != null)
                child.id: widget.playhead.runStateFor(child.id)!,
          },
          onToggleExpand: isGroup
              ? () => setState(() {
                    if (_expandedGroups.contains(cue.id)) {
                      _expandedGroups.remove(cue.id);
                    } else {
                      _expandedGroups.add(cue.id);
                    }
                  })
              : null,
          onTap: () => widget.onCueSelected(cue.id),
          onDelete: () => widget.notifier.deleteCueById(cue.id),
          onGo: () => widget.notifier.goToCue(cue.id),
          onInsertBefore: () => _insertCue(context, afterId: null, beforeId: cue.id),
          onInsertAfter: () => _insertCue(context, afterId: cue.id),
          onDuplicate: () => widget.notifier.duplicateDomainCue(cue.id),
          onGroup: () => widget.notifier.wrapInGroup(cue.id),
        );

        final showStrip = isRunning && cue.params is AudioParams;

        return Column(
          key: ValueKey(cue.id),
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            row,
            if (showStrip)
              ActiveCueControlStrip(
                key: ValueKey('strip_${cue.id}'),
                cue: cue,
                playhead: widget.playhead,
                onFadeUp: (ms) => widget.notifier.fadeUpAudio(cue.id, durationMs: ms),
                onFadeOut: (ms) => widget.notifier.fadeOutAudio(cue.id, durationMs: ms),
                onStop: () => widget.notifier.stopCueAudio(cue.id),
                onPause: () => widget.notifier.pauseCueAudio(cue.id),
                onResume: () => widget.notifier.resumeCueAudio(cue.id),
              ),
          ],
        );
      },
    );
  }
}
