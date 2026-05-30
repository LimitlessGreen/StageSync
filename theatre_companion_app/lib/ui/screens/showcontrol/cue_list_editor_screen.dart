import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;

import '../../../showcontrol/grpc/generated/stagesync/v1/common.pb.dart';
import '../../../showcontrol/grpc/generated/stagesync/v1/showcontrol.pb.dart';
import '../../../showcontrol/providers/session_provider.dart';
import '../../../showcontrol/providers/show_control_provider.dart';
import '../../../showcontrol/ui/design_system/sc_colors.dart';
import '../../../showcontrol/ui/design_system/sc_typography.dart';
import '../../../showcontrol/ui/design_system/sc_spacing.dart';
import 'cue_inspector_panel.dart';

/// Desktop cue list editor: left = cue list, right = inspector.
///
/// Keyboard shortcuts:
///   Space     → GO (selected cue or next)
///   Escape    → STOP
///   ↑ / ↓    → navigate selection
///   Delete    → delete selected cue (with confirm)
class CueListEditorScreen extends ConsumerStatefulWidget {
  const CueListEditorScreen({super.key});

  @override
  ConsumerState<CueListEditorScreen> createState() =>
      _CueListEditorScreenState();
}

class _CueListEditorScreenState extends ConsumerState<CueListEditorScreen> {
  String? _selectedCueId;
  final Set<String> _expandedGroups = {};
  final FocusNode _keyFocus = FocusNode();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(showControlProvider.notifier).initialize();
      _keyFocus.requestFocus();
    });
  }

  @override
  void dispose() {
    _keyFocus.dispose();
    super.dispose();
  }

  // ── Key handling ──────────────────────────────────────────────────────────

  KeyEventResult _onKey(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent) return KeyEventResult.ignored;
    final key = event.logicalKey;
    final notifier = ref.read(showControlProvider.notifier);
    final cues = _visibleTopLevelCues();

    if (key == LogicalKeyboardKey.space) {
      notifier.go();
      return KeyEventResult.handled;
    }
    if (key == LogicalKeyboardKey.escape) {
      notifier.stop();
      return KeyEventResult.handled;
    }
    if (key == LogicalKeyboardKey.arrowDown) {
      _selectOffset(cues, 1);
      return KeyEventResult.handled;
    }
    if (key == LogicalKeyboardKey.arrowUp) {
      _selectOffset(cues, -1);
      return KeyEventResult.handled;
    }
    if (key == LogicalKeyboardKey.delete ||
        key == LogicalKeyboardKey.backspace) {
      if (_selectedCueId != null) _handleDelete(_selectedCueId!);
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  List<Cue> _visibleTopLevelCues() {
    final show = ref.read(showControlProvider);
    return _topLevelCues(show.cueList?.cues.toList() ?? []);
  }

  void _selectOffset(List<Cue> cues, int delta) {
    if (cues.isEmpty) return;
    final idx = cues.indexWhere((c) => c.cueId == _selectedCueId);
    final next = (idx + delta).clamp(0, cues.length - 1);
    setState(() => _selectedCueId = cues[next].cueId);
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final show = ref.watch(showControlProvider);
    final session = ref.watch(sessionProvider);
    final connectedNodes = session.session?.nodes.toList() ?? <NodeInfo>[];
    final audioNodes = connectedNodes
        .where((n) =>
            n.tasks.contains(NodeTask.NODE_TASK_AUDIO_OUTPUT) &&
            n.mediaServerUrl.isNotEmpty)
        .toList();
    final allCues = show.cueList?.cues.toList() ?? <Cue>[];
    final topLevel = _topLevelCues(allCues);
    final selected = _selectedCue(allCues);

    return Focus(
      focusNode: _keyFocus,
      onKeyEvent: _onKey,
      child: Scaffold(
        backgroundColor: ScColors.bg,
        appBar: _buildAppBar(context, show, audioNodes, allCues),
        body: Row(
          children: [
            // ── Left: cue list ──────────────────────────────────────────
            SizedBox(
              width: 420,
              child: Column(
                children: [
                  _CueListToolbar(
                    onAddCue: () =>
                        _showAddCueDialog(context, allCues.length),
                  ),
                  Expanded(
                    child: _CueListView(
                      cues: topLevel,
                      allCues: allCues,
                      selectedCueId: _selectedCueId,
                      activeCueId: show.activeCue?.cueId,
                      activeCueStartedMs: show.activeCueStartedServerMs,
                      pausedAtMs: show.pausedAtServerMs,
                      isPaused: show.isPaused,
                      cueDoneMs: show.cueDoneServerMs,
                      expandedGroups: _expandedGroups,
                      onSelect: (id) =>
                          setState(() => _selectedCueId = id),
                      onToggleGroup: (id) => setState(() {
                        if (_expandedGroups.contains(id)) {
                          _expandedGroups.remove(id);
                        } else {
                          _expandedGroups.add(id);
                        }
                      }),
                      onReorder: _handleReorder,
                      onDelete: _handleDelete,
                      onGo: _handleGo,
                      onInsertBefore: (cueId) =>
                          _insertCue(context, allCues, cueId, before: true),
                      onInsertAfter: (cueId) =>
                          _insertCue(context, allCues, cueId, before: false),
                      onDuplicate: (cueId) => _duplicateCue(allCues, cueId),
                      onGroup: (cueId) => _groupCue(allCues, cueId),
                    ),
                  ),
                ],
              ),
            ),
            const VerticalDivider(
                width: 1, color: ScColors.divider, thickness: 1),
            // ── Right: inspector ────────────────────────────────────────
            Expanded(
              child: selected != null
                  ? CueInspectorPanel(
                      key: ValueKey(selected.cueId),
                      cue: selected,
                      onSave: _handleSaveCue,
                      connectedNodes: connectedNodes,
                    )
                  : const _EmptyInspector(),
            ),
          ],
        ),
      ),
    );
  }

  AppBar _buildAppBar(BuildContext context, ShowControlState show,
      List<NodeInfo> audioNodes, List<Cue> allCues) {
    return AppBar(
      backgroundColor: ScColors.surface,
      title: Text(
        show.cueList?.name ?? 'CueList-Editor',
        style: ScText.sectionTitle,
      ),
      actions: [
        if (audioNodes.isNotEmpty)
          IconButton(
            icon: const Icon(Icons.cloud_sync),
            tooltip: 'Show Deploy',
            onPressed: () =>
                _showDeployDialog(context, allCues, audioNodes),
          ),
        _TransportBar(),
        const SizedBox(width: 8),
      ],
    );
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

  /// Returns only cues that are NOT children of a group.
  List<Cue> _topLevelCues(List<Cue> all) {
    final childIds = <String>{};
    for (final c in all) {
      if (c.cueType == CueType.CUE_TYPE_GROUP && c.hasGroup()) {
        childIds.addAll(c.group.childCueIds);
      }
    }
    return all.where((c) => !childIds.contains(c.cueId)).toList();
  }

  Cue? _selectedCue(List<Cue> cues) {
    if (_selectedCueId == null) return null;
    try {
      return cues.firstWhere((c) => c.cueId == _selectedCueId);
    } catch (_) {
      return null;
    }
  }

  // ── Actions ───────────────────────────────────────────────────────────────

  Future<void> _showAddCueDialog(
      BuildContext context, int count) async {
    final type = await showDialog<CueType>(
      context: context,
      builder: (_) => const _CueTypeDialog(),
    );
    if (type == null || !mounted) return;
    final newCue = Cue()
      ..cueId = _generateId()
      ..number = (count + 1).toString()
      ..label = _defaultLabel(type)
      ..cueType = type;
    await ref.read(showControlProvider.notifier).upsertCue(newCue);
    setState(() => _selectedCueId = newCue.cueId);
  }

  Future<void> _insertCue(
      BuildContext context, List<Cue> allCues, String relativeCueId,
      {required bool before}) async {
    final type = await showDialog<CueType>(
      context: context,
      builder: (_) => const _CueTypeDialog(),
    );
    if (type == null || !mounted) return;

    final idx = allCues.indexWhere((c) => c.cueId == relativeCueId);
    if (idx < 0) return;
    final insertIdx = before ? idx : idx + 1;

    final newCue = Cue()
      ..cueId = _generateId()
      ..number = _insertNumber(allCues, insertIdx)
      ..label = _defaultLabel(type)
      ..cueType = type;

    final updated = List<Cue>.from(allCues)..insert(insertIdx, newCue);
    final cl = ref.read(showControlProvider).cueList;
    if (cl == null) return;
    final newList = CueList()
      ..cueListId = cl.cueListId
      ..name = cl.name
      ..cues.addAll(updated);
    await ref.read(showControlProvider.notifier).updateCueList(newList);
    setState(() => _selectedCueId = newCue.cueId);
  }

  Future<void> _duplicateCue(List<Cue> allCues, String cueId) async {
    final src = allCues.where((c) => c.cueId == cueId).firstOrNull;
    if (src == null) return;
    final idx = allCues.indexOf(src);
    final dup = src.deepCopy()
      ..cueId = _generateId()
      ..number = _insertNumber(allCues, idx + 1);
    final updated = List<Cue>.from(allCues)..insert(idx + 1, dup);
    final cl = ref.read(showControlProvider).cueList;
    if (cl == null) return;
    final newList = CueList()
      ..cueListId = cl.cueListId
      ..name = cl.name
      ..cues.addAll(updated);
    await ref.read(showControlProvider.notifier).updateCueList(newList);
    setState(() => _selectedCueId = dup.cueId);
  }

  Future<void> _groupCue(List<Cue> allCues, String cueId) async {
    final child = allCues.where((c) => c.cueId == cueId).firstOrNull;
    if (child == null) return;
    final idx = allCues.indexOf(child);

    final group = Cue()
      ..cueId = _generateId()
      ..number = child.number
      ..label = 'Gruppe'
      ..cueType = CueType.CUE_TYPE_GROUP
      ..group = (GroupCueParams()..childCueIds.add(child.cueId));

    final updated = List<Cue>.from(allCues)..insert(idx, group);
    final cl = ref.read(showControlProvider).cueList;
    if (cl == null) return;
    final newList = CueList()
      ..cueListId = cl.cueListId
      ..name = cl.name
      ..cues.addAll(updated);
    await ref.read(showControlProvider.notifier).updateCueList(newList);
    setState(() {
      _selectedCueId = group.cueId;
      _expandedGroups.add(group.cueId);
    });
  }

  Future<void> _handleSaveCue(Cue updated) async {
    await ref.read(showControlProvider.notifier).upsertCue(updated);
  }

  Future<void> _handleDelete(String cueId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: ScColors.surface,
        title: const Text('Cue löschen?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Abbrechen')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: ScColors.error),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Löschen'),
          ),
        ],
      ),
    );
    if (confirm != true) return;
    await ref.read(showControlProvider.notifier).deleteCue(cueId);
    if (_selectedCueId == cueId) setState(() => _selectedCueId = null);
  }

  void _handleGo(String cueId) {
    ref.read(showControlProvider.notifier).goToCue(cueId);
  }

  Future<void> _handleReorder(List<Cue> reordered) async {
    final cl = ref.read(showControlProvider).cueList;
    if (cl == null) return;

    // Keep non-visible children in the list, rebuild with reordered top-level
    final allCues = cl.cues.toList();
    final childIds = <String>{};
    for (final c in allCues) {
      if (c.cueType == CueType.CUE_TYPE_GROUP && c.hasGroup()) {
        childIds.addAll(c.group.childCueIds);
      }
    }
    final children = allCues.where((c) => childIds.contains(c.cueId)).toList();
    final merged = [...reordered, ...children];

    final newList = CueList()
      ..cueListId = cl.cueListId
      ..name = cl.name
      ..cues.addAll(merged);
    await ref.read(showControlProvider.notifier).updateCueList(newList);
  }

  Future<void> _showDeployDialog(
      BuildContext context, List<Cue> cues, List<NodeInfo> audioNodes) async {
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => _ShowDeployDialog(cues: cues, audioNodes: audioNodes),
    );
  }

  // ── Utility ───────────────────────────────────────────────────────────────

  String _generateId() {
    final ms = DateTime.now().millisecondsSinceEpoch;
    final us = DateTime.now().microsecond;
    return ms.toRadixString(36) + us.toRadixString(36);
  }

  String _insertNumber(List<Cue> cues, int idx) {
    if (idx <= 0) return '0.5';
    if (idx >= cues.length) return (cues.length + 1).toString();
    final before = double.tryParse(cues[idx - 1].number) ?? (idx).toDouble();
    final after = idx < cues.length
        ? (double.tryParse(cues[idx].number) ?? (idx + 1).toDouble())
        : before + 1;
    final mid = (before + after) / 2;
    return mid == mid.truncateToDouble()
        ? mid.toInt().toString()
        : mid.toStringAsFixed(1);
  }

  String _defaultLabel(CueType type) => switch (type) {
        CueType.CUE_TYPE_AUDIO  => 'Audio',
        CueType.CUE_TYPE_MA_OSC => 'GrandMA',
        CueType.CUE_TYPE_WAIT   => 'Warten',
        CueType.CUE_TYPE_GROUP  => 'Gruppe',
        CueType.CUE_TYPE_GOTO   => 'Goto',
        _                       => 'Cue',
      };
}

// ── Transport bar ─────────────────────────────────────────────────────────────

class _TransportBar extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final show = ref.watch(showControlProvider);
    final notifier = ref.read(showControlProvider.notifier);
    final isRunning = show.activeCue != null && !show.isPaused;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // STOP
        _TransportBtn(
          icon: Icons.stop,
          label: 'STOP',
          color: ScColors.error,
          onPressed: notifier.stop,
        ),
        const SizedBox(width: 6),
        // PAUSE / RESUME
        if (isRunning)
          _TransportBtn(
            icon: Icons.pause,
            label: 'PAUSE',
            color: ScColors.warn,
            onPressed: notifier.pause,
          )
        else if (show.isPaused)
          _TransportBtn(
            icon: Icons.play_arrow,
            label: 'RESUME',
            color: ScColors.warn,
            onPressed: notifier.resume,
          ),
        const SizedBox(width: 6),
        // GO
        _TransportBtn(
          icon: Icons.skip_next,
          label: 'GO',
          color: ScColors.active,
          filled: true,
          onPressed: notifier.go,
        ),
      ],
    );
  }
}

class _TransportBtn extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final bool filled;
  final VoidCallback onPressed;

  const _TransportBtn({
    required this.icon,
    required this.label,
    required this.color,
    required this.onPressed,
    this.filled = false,
  });

  @override
  Widget build(BuildContext context) {
    if (filled) {
      return FilledButton.icon(
        style: FilledButton.styleFrom(
          backgroundColor: color,
          foregroundColor: Colors.black,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          minimumSize: Size.zero,
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        ),
        icon: Icon(icon, size: 16),
        label: Text(label,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
        onPressed: onPressed,
      );
    }
    return OutlinedButton.icon(
      style: OutlinedButton.styleFrom(
        foregroundColor: color,
        side: BorderSide(color: color.withValues(alpha: 0.5)),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        minimumSize: Size.zero,
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
      icon: Icon(icon, size: 16),
      label: Text(label,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
      onPressed: onPressed,
    );
  }
}

// ── Toolbar ───────────────────────────────────────────────────────────────────

class _CueListToolbar extends StatelessWidget {
  final VoidCallback onAddCue;
  const _CueListToolbar({required this.onAddCue});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      color: ScColors.surface,
      child: Row(
        children: [
          Text('CUES', style: ScText.panelTitle),
          const Spacer(),
          Text('Space = GO  ·  ↑↓ = Nav  ·  Esc = Stop',
              style: ScText.shortcutHint),
          const SizedBox(width: 12),
          FilledButton.icon(
            style: FilledButton.styleFrom(
              backgroundColor: ScColors.active,
              foregroundColor: Colors.black,
              padding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            icon: const Icon(Icons.add, size: 14),
            label: const Text('Add', style: TextStyle(fontSize: 12)),
            onPressed: onAddCue,
          ),
        ],
      ),
    );
  }
}

// ── Cue list view ─────────────────────────────────────────────────────────────

class _CueListView extends StatelessWidget {
  final List<Cue> cues; // top-level only (children filtered out)
  final List<Cue> allCues;
  final String? selectedCueId;
  final String? activeCueId;
  final int? activeCueStartedMs;
  final int? pausedAtMs;
  final bool isPaused;
  final int? cueDoneMs;
  final Set<String> expandedGroups;

  final ValueChanged<String> onSelect;
  final ValueChanged<String> onToggleGroup;
  final ValueChanged<List<Cue>> onReorder;
  final ValueChanged<String> onDelete;
  final ValueChanged<String> onGo;
  final ValueChanged<String> onInsertBefore;
  final ValueChanged<String> onInsertAfter;
  final ValueChanged<String> onDuplicate;
  final ValueChanged<String> onGroup;

  const _CueListView({
    required this.cues,
    required this.allCues,
    required this.selectedCueId,
    required this.activeCueId,
    required this.activeCueStartedMs,
    required this.pausedAtMs,
    required this.isPaused,
    required this.cueDoneMs,
    required this.expandedGroups,
    required this.onSelect,
    required this.onToggleGroup,
    required this.onReorder,
    required this.onDelete,
    required this.onGo,
    required this.onInsertBefore,
    required this.onInsertAfter,
    required this.onDuplicate,
    required this.onGroup,
  });

  @override
  Widget build(BuildContext context) {
    if (cues.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.list, size: 40, color: ScColors.textDim),
            const SizedBox(height: 8),
            Text('Keine Cues.', style: ScText.label),
            const SizedBox(height: 4),
            Text('Klick auf "Add" um zu beginnen.',
                style: ScText.statusSmall),
          ],
        ),
      );
    }

    return ReorderableListView.builder(
      itemCount: cues.length,
      onReorder: (oldIdx, newIdx) {
        final reordered = List<Cue>.from(cues);
        if (newIdx > oldIdx) newIdx--;
        final item = reordered.removeAt(oldIdx);
        reordered.insert(newIdx, item);
        onReorder(reordered);
      },
      proxyDecorator: (child, index, animation) => Material(
        elevation: 4,
        color: ScColors.surface2,
        borderRadius: BorderRadius.circular(4),
        child: child,
      ),
      itemBuilder: (context, i) {
        final cue = cues[i];
        final isGroup = cue.cueType == CueType.CUE_TYPE_GROUP;
        final isExpanded = expandedGroups.contains(cue.cueId);
        final isActive = cue.cueId == activeCueId;
        final isSelected = cue.cueId == selectedCueId;

        // Resolve group children
        List<Cue>? groupChildren;
        if (isGroup && cue.hasGroup()) {
          groupChildren = cue.group.childCueIds
              .map((id) => allCues.where((c) => c.cueId == id).firstOrNull)
              .whereType<Cue>()
              .toList();
        }

        return _CueRow(
          key: ValueKey(cue.cueId),
          cue: cue,
          dragIndex: i,
          isActive: isActive,
          isSelected: isSelected,
          isExpanded: isExpanded,
          groupChildren: groupChildren,
          activeCueStartedMs: activeCueStartedMs,
          pausedAtMs: pausedAtMs,
          isPaused: isPaused,
          cueDoneMs: cueDoneMs,
          runningChildIds: const {},
          onTap: () => onSelect(cue.cueId),
          onDoubleTap: () => onGo(cue.cueId),
          onToggleExpand: isGroup ? () => onToggleGroup(cue.cueId) : null,
          onGo: () => onGo(cue.cueId),
          onDelete: () => onDelete(cue.cueId),
          onInsertBefore: () => onInsertBefore(cue.cueId),
          onInsertAfter: () => onInsertAfter(cue.cueId),
          onDuplicate: () => onDuplicate(cue.cueId),
          onGroup: () => onGroup(cue.cueId),
        );
      },
    );
  }
}

// ── Cue row (editor, proto-based) ─────────────────────────────────────────────

class _CueRow extends StatefulWidget {
  final Cue cue;
  final int dragIndex;
  final bool isActive;
  final bool isSelected;
  final bool isExpanded;
  final List<Cue>? groupChildren;
  final Set<String> runningChildIds;

  // Timing from ShowControlState
  final int? activeCueStartedMs;
  final int? pausedAtMs;
  final bool isPaused;
  final int? cueDoneMs;

  // Actions
  final VoidCallback? onTap;
  final VoidCallback? onDoubleTap;
  final VoidCallback? onToggleExpand;
  final VoidCallback? onGo;
  final VoidCallback? onDelete;
  final VoidCallback? onInsertBefore;
  final VoidCallback? onInsertAfter;
  final VoidCallback? onDuplicate;
  final VoidCallback? onGroup;

  const _CueRow({
    super.key,
    required this.cue,
    required this.dragIndex,
    required this.isActive,
    required this.isSelected,
    required this.isExpanded,
    required this.runningChildIds,
    this.groupChildren,
    this.activeCueStartedMs,
    this.pausedAtMs,
    this.isPaused = false,
    this.cueDoneMs,
    this.onTap,
    this.onDoubleTap,
    this.onToggleExpand,
    this.onGo,
    this.onDelete,
    this.onInsertBefore,
    this.onInsertAfter,
    this.onDuplicate,
    this.onGroup,
  });

  @override
  State<_CueRow> createState() => _CueRowState();
}

class _CueRowState extends State<_CueRow> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _syncTimer();
  }

  @override
  void didUpdateWidget(_CueRow old) {
    super.didUpdateWidget(old);
    _syncTimer();
  }

  void _syncTimer() {
    final needsTick =
        widget.isActive && !widget.isPaused && widget.cueDoneMs == null;
    if (needsTick && _timer == null) {
      _timer = Timer.periodic(const Duration(milliseconds: 50), (_) {
        if (mounted) setState(() {});
      });
    } else if (!needsTick && _timer != null) {
      _timer!.cancel();
      _timer = null;
    }
  }

  @override
  void deactivate() {
    _timer?.cancel();
    _timer = null;
    super.deactivate();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  double get _progressFraction {
    if (!widget.isActive) return 0.0;
    final start = widget.activeCueStartedMs;
    final duration = _cueDurationMs;
    if (start == null || duration == null || duration == 0) return 0.0;
    final now = widget.isPaused
        ? (widget.pausedAtMs ?? DateTime.now().millisecondsSinceEpoch)
        : widget.cueDoneMs ?? DateTime.now().millisecondsSinceEpoch;
    return ((now - start) / duration).clamp(0.0, 1.0);
  }

  double? get _cueDurationMs {
    if (widget.cue.cueType == CueType.CUE_TYPE_AUDIO && widget.cue.hasAudio()) {
      final d = widget.cue.audio.declaredDurationMs;
      return d > 0 ? d : null;
    }
    if (widget.cue.cueType == CueType.CUE_TYPE_WAIT && widget.cue.hasWait()) {
      return widget.cue.wait.durationMs;
    }
    return null;
  }

  String _fmtDuration(double? ms) {
    if (ms == null) return '';
    if (ms < 1000) return '${ms.toInt()}ms';
    final s = ms / 1000;
    if (s < 60) return '${s.toStringAsFixed(1)}s';
    final m = (s / 60).floor();
    final rs = (s % 60).toStringAsFixed(0).padLeft(2, '0');
    return '$m:$rs';
  }

  Color get _typeColor => switch (widget.cue.cueType) {
        CueType.CUE_TYPE_AUDIO  => const Color(0xFF1E88E5),
        CueType.CUE_TYPE_WAIT   => const Color(0xFF8E24AA),
        CueType.CUE_TYPE_MA_OSC => const Color(0xFFF4511E),
        CueType.CUE_TYPE_GROUP  => const Color(0xFF00897B),
        CueType.CUE_TYPE_GOTO   => const Color(0xFF00ACC1),
        _                       => ScColors.textDim,
      };

  IconData get _typeIcon => switch (widget.cue.cueType) {
        CueType.CUE_TYPE_AUDIO  => Icons.volume_up,
        CueType.CUE_TYPE_WAIT   => Icons.timer_outlined,
        CueType.CUE_TYPE_MA_OSC => Icons.light_mode,
        CueType.CUE_TYPE_GROUP  => Icons.folder_outlined,
        CueType.CUE_TYPE_GOTO   => Icons.redo,
        _                       => Icons.help_outline,
      };

  @override
  Widget build(BuildContext context) {
    final fraction = _progressFraction;
    final isGroup = widget.cue.cueType == CueType.CUE_TYPE_GROUP;
    final duration = _cueDurationMs;

    // Compute remaining time for display
    String timingLabel = _fmtDuration(duration);
    if (widget.isActive && duration != null && widget.activeCueStartedMs != null) {
      final start = widget.activeCueStartedMs!;
      final now = widget.isPaused
          ? (widget.pausedAtMs ?? DateTime.now().millisecondsSinceEpoch)
          : widget.cueDoneMs ?? DateTime.now().millisecondsSinceEpoch;
      final elapsed = (now - start).clamp(0, 99 * 60 * 1000).toDouble();
      final remaining = (duration - elapsed).clamp(0.0, duration);
      timingLabel = '-${_fmtDuration(remaining)}';
    }

    Widget row = SizedBox(
      height: ScSpacing.rowHeight,
      child: Stack(
        children: [
          // Progress fill
          if (widget.isActive && fraction > 0)
            Positioned.fill(
              child: FractionallySizedBox(
                alignment: Alignment.centerLeft,
                widthFactor: fraction,
                child: Container(color: _typeColor.withValues(alpha: 0.10)),
              ),
            ),
          // Background
          Container(
            color: widget.isSelected
                ? ScColors.selected
                : widget.isActive
                    ? ScColors.active.withValues(alpha: 0.04)
                    : Colors.transparent,
          ),
          // Left accent
          if (widget.isActive)
            Positioned(
              left: 0, top: 0, bottom: 0,
              child: Container(width: 3, color: ScColors.active),
            ),
          // Bottom progress line
          if (widget.isActive)
            Positioned(
              left: 0, right: 0, bottom: 0,
              child: LinearProgressIndicator(
                value: fraction,
                backgroundColor: Colors.transparent,
                valueColor: AlwaysStoppedAnimation(
                  widget.isPaused
                      ? ScColors.warn
                      : _typeColor.withValues(alpha: 0.8),
                ),
                minHeight: 2,
              ),
            ),
          // Content
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Row(
              children: [
                // Group expand toggle or type icon
                if (isGroup)
                  GestureDetector(
                    onTap: widget.onToggleExpand,
                    child: SizedBox(
                      width: 24,
                      child: Icon(
                        widget.isExpanded
                            ? Icons.expand_more
                            : Icons.chevron_right,
                        size: 18,
                        color: _typeColor,
                      ),
                    ),
                  )
                else
                  SizedBox(
                    width: 24,
                    child: Icon(_typeIcon, size: 14, color: _typeColor),
                  ),
                const SizedBox(width: 4),
                // Number
                SizedBox(
                  width: 40,
                  child: Text(
                    widget.cue.number,
                    style: ScText.number.copyWith(
                        color: widget.isActive
                            ? ScColors.active
                            : ScColors.textSecondary),
                    textAlign: TextAlign.right,
                  ),
                ),
                const SizedBox(width: 8),
                // Label
                Expanded(
                  child: Text(
                    widget.cue.label.isEmpty ? '—' : widget.cue.label,
                    style: widget.isActive
                        ? ScText.cueLabelActive
                        : ScText.cueLabel,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                // Duration / remaining
                if (timingLabel.isNotEmpty)
                  Text(
                    timingLabel,
                    style: ScText.numberSmall.copyWith(
                      color: widget.isActive
                          ? (widget.isPaused ? ScColors.warn : ScColors.active)
                          : ScColors.textSecondary,
                    ),
                  ),
                const SizedBox(width: 6),
                // Delete
                IconButton(
                  icon: const Icon(Icons.delete_outline, size: 15),
                  onPressed: widget.onDelete,
                  color: ScColors.error,
                  padding: EdgeInsets.zero,
                  constraints:
                      const BoxConstraints(minWidth: 24, minHeight: 24),
                ),
                // Drag handle
                ReorderableDragStartListener(
                  index: widget.dragIndex,
                  child: const Icon(Icons.drag_handle,
                      size: 16, color: ScColors.textDim),
                ),
              ],
            ),
          ),
        ],
      ),
    );

    // Gesture
    row = GestureDetector(
      onTap: widget.onTap,
      onDoubleTap: widget.onDoubleTap,
      onSecondaryTapUp: (details) =>
          _showContextMenu(context, details.localPosition),
      child: row,
    );

    // Group expansion
    if (isGroup &&
        widget.isExpanded &&
        widget.groupChildren != null &&
        widget.groupChildren!.isNotEmpty) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          row,
          // Mode label
          Padding(
            padding: const EdgeInsets.only(left: 36, bottom: 2),
            child: Text(
              widget.cue.hasGroup() && widget.cue.group.sequential
                  ? 'SEQUENTIAL'
                  : 'PARALLEL',
              style: ScText.statusSmall.copyWith(color: _typeColor),
            ),
          ),
          // Children
          ...widget.groupChildren!.map((child) => _ChildCueRow(
                cue: child,
                isActive: widget.runningChildIds.contains(child.cueId),
              )),
          Container(
            height: 1,
            margin: const EdgeInsets.only(left: 36),
            color: _typeColor.withValues(alpha: 0.25),
          ),
          const SizedBox(height: 2),
        ],
      );
    }

    return row;
  }

  void _showContextMenu(BuildContext context, Offset localPos) {
    final box = context.findRenderObject() as RenderBox;
    final global = box.localToGlobal(localPos);
    final size = MediaQuery.sizeOf(context);
    showMenu<String>(
      context: context,
      position: RelativeRect.fromLTRB(
          global.dx, global.dy,
          size.width - global.dx, size.height - global.dy),
      color: ScColors.surface2,
      items: [
        if (widget.onGo != null)
          const PopupMenuItem(value: 'go', child: Text('GO here')),
        const PopupMenuDivider(),
        if (widget.onInsertBefore != null)
          const PopupMenuItem(
              value: 'insert_before', child: Text('Insert Before')),
        if (widget.onInsertAfter != null)
          const PopupMenuItem(
              value: 'insert_after', child: Text('Insert After')),
        if (widget.onDuplicate != null)
          const PopupMenuItem(value: 'duplicate', child: Text('Duplicate')),
        if (widget.onGroup != null)
          const PopupMenuItem(value: 'group', child: Text('Group')),
        const PopupMenuDivider(),
        if (widget.onDelete != null)
          PopupMenuItem(
            value: 'delete',
            child: Text('Delete',
                style: const TextStyle(color: ScColors.error)),
          ),
      ],
    ).then((v) {
      switch (v) {
        case 'go':
          widget.onGo?.call();
        case 'insert_before':
          widget.onInsertBefore?.call();
        case 'insert_after':
          widget.onInsertAfter?.call();
        case 'duplicate':
          widget.onDuplicate?.call();
        case 'group':
          widget.onGroup?.call();
        case 'delete':
          widget.onDelete?.call();
      }
    });
  }
}

// ── Child cue row (inside group, read-only display) ───────────────────────────

class _ChildCueRow extends StatelessWidget {
  final Cue cue;
  final bool isActive;

  const _ChildCueRow({required this.cue, this.isActive = false});

  Color get _typeColor => switch (cue.cueType) {
        CueType.CUE_TYPE_AUDIO  => const Color(0xFF1E88E5),
        CueType.CUE_TYPE_WAIT   => const Color(0xFF8E24AA),
        CueType.CUE_TYPE_MA_OSC => const Color(0xFFF4511E),
        _                       => ScColors.textDim,
      };

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 36,
      color: isActive ? ScColors.active.withValues(alpha: 0.05) : Colors.transparent,
      padding: const EdgeInsets.only(left: 36, right: 8),
      child: Row(
        children: [
          Container(
            width: 2, height: 20,
            margin: const EdgeInsets.only(right: 8),
            color: _typeColor.withValues(alpha: 0.5),
          ),
          SizedBox(
            width: 36,
            child: Text(cue.number,
                style: ScText.numberSmall, textAlign: TextAlign.right),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(cue.label.isEmpty ? '—' : cue.label,
                style: ScText.label.copyWith(
                    color: isActive
                        ? ScColors.active
                        : ScColors.textSecondary),
                overflow: TextOverflow.ellipsis),
          ),
          if (isActive)
            Container(
              width: 6, height: 6,
              decoration: const BoxDecoration(
                  color: ScColors.active, shape: BoxShape.circle),
            ),
        ],
      ),
    );
  }
}

// ── Cue type dialog ───────────────────────────────────────────────────────────

class _CueTypeDialog extends StatelessWidget {
  const _CueTypeDialog();

  @override
  Widget build(BuildContext context) {
    return SimpleDialog(
      backgroundColor: ScColors.surface,
      title: Text('Cue-Typ wählen', style: ScText.sectionTitle),
      children: [
        _Option(
          icon: Icons.volume_up, label: 'Audio',
          sub: 'WAV · MP3 · FLAC · OGG',
          color: const Color(0xFF1E88E5),
          type: CueType.CUE_TYPE_AUDIO,
        ),
        _Option(
          icon: Icons.light_mode, label: 'GrandMA-OSC',
          sub: 'Executor Go / Off / Pause',
          color: const Color(0xFFF4511E),
          type: CueType.CUE_TYPE_MA_OSC,
        ),
        _Option(
          icon: Icons.timer_outlined, label: 'Wait',
          sub: 'Zeitverzögerung',
          color: const Color(0xFF8E24AA),
          type: CueType.CUE_TYPE_WAIT,
        ),
        _Option(
          icon: Icons.folder_outlined, label: 'Group',
          sub: 'Sequential oder parallel',
          color: const Color(0xFF00897B),
          type: CueType.CUE_TYPE_GROUP,
        ),
        _Option(
          icon: Icons.redo, label: 'Goto',
          sub: 'Zu einer Cue springen',
          color: const Color(0xFF00ACC1),
          type: CueType.CUE_TYPE_GOTO,
        ),
      ],
    );
  }
}

class _Option extends StatelessWidget {
  final IconData icon;
  final String label;
  final String sub;
  final Color color;
  final CueType type;

  const _Option({
    required this.icon, required this.label, required this.sub,
    required this.color, required this.type,
  });

  @override
  Widget build(BuildContext context) {
    return SimpleDialogOption(
      onPressed: () => Navigator.pop(context, type),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 14),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label,
                  style: ScText.cueLabel.copyWith(fontWeight: FontWeight.w600)),
              Text(sub, style: ScText.label),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Empty state ───────────────────────────────────────────────────────────────

class _EmptyInspector extends StatelessWidget {
  const _EmptyInspector();

  @override
  Widget build(BuildContext context) => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.touch_app_outlined, size: 32, color: ScColors.textDim),
            const SizedBox(height: 8),
            Text('Cue auswählen', style: ScText.label),
            const SizedBox(height: 2),
            Text('Doppelklick = GO here · Leertaste = GO',
                style: ScText.statusSmall),
          ],
        ),
      );
}

// ── Show Deploy dialog ────────────────────────────────────────────────────────

class _ShowDeployDialog extends StatefulWidget {
  final List<Cue> cues;
  final List<NodeInfo> audioNodes;
  const _ShowDeployDialog({required this.cues, required this.audioNodes});

  @override
  State<_ShowDeployDialog> createState() => _ShowDeployDialogState();
}

class _ShowDeployDialogState extends State<_ShowDeployDialog> {
  bool _running = false;
  final List<(String, bool?)> _log = [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _deploy());
  }

  Future<void> _deploy() async {
    setState(() { _running = true; _log.clear(); });
    final files = <String>{};
    for (final cue in widget.cues) {
      if (cue.cueType == CueType.CUE_TYPE_AUDIO && cue.hasAudio()) {
        final fp = cue.audio.filePath;
        if (fp.isNotEmpty) files.add(fp);
      }
    }
    if (files.isEmpty) {
      _add('Keine Audio-Cues.', ok: true);
      setState(() => _running = false);
      return;
    }
    _add('${files.length} Datei(en) · ${widget.audioNodes.length} Node(s)');
    for (final node in widget.audioNodes) {
      _add('Node: ${node.name}');
      Set<String> existing = {};
      try {
        final resp = await http
            .get(Uri.parse('${node.mediaServerUrl}/media'))
            .timeout(const Duration(seconds: 5));
        if (resp.statusCode == 200) {
          existing = (jsonDecode(resp.body) as List)
              .map((e) => e['filename'] as String)
              .toSet();
        }
      } catch (e) {
        _add('  ✗ $e', ok: false);
        continue;
      }
      for (final filename in files) {
        if (existing.contains(filename)) {
          _add('  ✓ $filename', ok: true);
          continue;
        }
        NodeInfo? source;
        List<int>? bytes;
        for (final other in widget.audioNodes) {
          if (other.nodeId == node.nodeId) continue;
          try {
            final dl = await http
                .get(Uri.parse(
                    '${other.mediaServerUrl}/media/download/$filename'))
                .timeout(const Duration(seconds: 15));
            if (dl.statusCode == 200) {
              source = other;
              bytes = dl.bodyBytes;
              break;
            }
          } catch (_) {}
        }
        if (bytes == null) {
          _add('  ✗ $filename — nicht gefunden!', ok: false);
          continue;
        }
        _add('  ↑ $filename von ${source!.name}…');
        try {
          final req = http.MultipartRequest(
              'POST', Uri.parse('${node.mediaServerUrl}/media/upload'))
            ..files.add(
                http.MultipartFile.fromBytes('file', bytes, filename: filename));
          final up = await req.send().timeout(const Duration(seconds: 30));
          _add(up.statusCode == 200 ? '  ✓ $filename' : '  ✗ HTTP ${up.statusCode}',
              ok: up.statusCode == 200);
        } catch (e) {
          _add('  ✗ $e', ok: false);
        }
      }
    }
    _add('Fertig.', ok: true);
    setState(() => _running = false);
  }

  void _add(String msg, {bool? ok}) =>
      setState(() => _log.add((msg, ok)));

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: ScColors.surface,
      title: Row(children: [
        const Icon(Icons.cloud_sync),
        const SizedBox(width: 8),
        const Text('Show Deploy'),
        if (_running) ...[
          const SizedBox(width: 12),
          const SizedBox(
              width: 16, height: 16,
              child: CircularProgressIndicator(strokeWidth: 2)),
        ],
      ]),
      content: SizedBox(
        width: 480, height: 320,
        child: ListView.builder(
          itemCount: _log.length,
          itemBuilder: (ctx, i) {
            final (msg, ok) = _log[i];
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 1),
              child: Text(msg,
                  style: TextStyle(
                    fontSize: 12,
                    fontFamily: 'monospace',
                    color: ok == null
                        ? ScColors.textSecondary
                        : ok
                            ? ScColors.active
                            : ScColors.error,
                  )),
            );
          },
        ),
      ),
      actions: [
        TextButton(
          onPressed: _running ? null : () => Navigator.pop(context),
          child: const Text('Schließen'),
        ),
        if (!_running)
          FilledButton.icon(
            icon: const Icon(Icons.refresh),
            label: const Text('Nochmal'),
            onPressed: _deploy,
          ),
      ],
    );
  }
}
