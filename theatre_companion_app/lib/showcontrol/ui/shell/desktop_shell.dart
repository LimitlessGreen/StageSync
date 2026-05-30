import 'dart:async';

import 'package:flutter/material.dart';
import 'sc_shortcuts.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/show_control_provider.dart';
import '../../providers/show_control_domain_provider.dart';
import '../../providers/session_provider.dart';
import '../../providers/audio_node_provider.dart';
import '../../providers/ma_node_provider.dart';
import '../../providers/media_provider.dart';
import '../../domain/asset.dart';
import '../../nodes/audio_node/audio_node_service.dart';
import '../../nodes/ma_node/ma_node_service.dart';
import '../../grpc/generated/stagesync/v1/common.pb.dart' show NodeTask;
import '../design_system/sc_colors.dart';
import '../design_system/sc_spacing.dart';
import '../design_system/sc_typography.dart';
import '../design_system/primitives/sc_button.dart';
import '../design_system/primitives/sc_chip.dart';
import '../design_system/primitives/sc_panel.dart';
import '../design_system/primitives/sc_split_view.dart';
import '../design_system/primitives/sc_inline_field.dart';
import '../design_system/primitives/sc_drag_field.dart';
import '../design_system/domain_components/transport_bar.dart';
import '../design_system/domain_components/cue_list_row.dart';
import '../design_system/domain_components/active_cue_monitor.dart';
import '../design_system/domain_components/node_status_badge.dart';
import '../design_system/domain_components/audio_cue_minibar.dart';
import '../design_system/domain_components/cue_type_picker.dart';
import '../screens/nodes/node_management_panel.dart';
import '../screens/settings/settings_screen.dart';
import '../screens/media/media_manager_screen.dart';
import '../screens/audio/local_audio_panel.dart';
import '../design_system/domain_components/patch_matrix.dart';
import '../../domain/show.dart';
import '../../domain/cue_params.dart';
import '../../domain/playhead.dart';

/// Full desktop shell: TransportBar top + three panels + tab bar.
class DesktopShell extends ConsumerStatefulWidget {
  const DesktopShell({super.key});

  @override
  ConsumerState<DesktopShell> createState() => _DesktopShellState();
}

class _DesktopShellState extends ConsumerState<DesktopShell>
    with SingleTickerProviderStateMixin {
  String? _selectedCueId;
  late TabController _tabController;
  late final AppLifecycleListener _lifecycleListener;
  bool _bottomPanelOpen = false;
  int _lastOpenTab = 0;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(showControlProvider.notifier).initialize();
      _handleAutoReconnectNodeStart();
    });
    _lifecycleListener = AppLifecycleListener(
      onResume: () {
        if (!mounted) return;
        if (ref.read(sessionProvider).isInSession) {
          ref.read(showControlProvider.notifier).initialize();
        }
      },
    );
  }

void _handleAutoReconnectNodeStart() {
    final session = ref.read(sessionProvider);
    if (!session.needsNodeStart) return;
    ref.read(sessionProvider.notifier).clearNeedsNodeStart();
    final tasks = session.myNode?.tasks.toList() ?? [];
    if (tasks.contains(NodeTask.NODE_TASK_AUDIO_OUTPUT)) {
      ref.read(audioNodeProvider.notifier).startAudioNode();
    }
  }

  Future<void> _leaveSession() async {
    final tasks = ref.read(sessionProvider).myNode?.tasks ?? [];
    if (tasks.contains(NodeTask.NODE_TASK_AUDIO_OUTPUT)) {
      await ref.read(audioNodeProvider.notifier).stopAudioNode();
    }
    if (tasks.contains(NodeTask.NODE_TASK_MA_OSC)) {
      await ref.read(maNodeProvider.notifier).stopMaNode();
    }
    await ref.read(sessionProvider.notifier).leaveSession();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _lifecycleListener.dispose();
    super.dispose();
  }

  void _selectOffset(int delta) {
    final cues = ref.read(showControlDomainProvider).cueList?.cues ?? [];
    if (cues.isEmpty) return;
    final idx = cues.indexWhere((c) => c.id == _selectedCueId);
    final next = (idx + delta).clamp(0, cues.length - 1);
    setState(() => _selectedCueId = cues[next].id);
  }

  @override
  Widget build(BuildContext context) {
    final domainState  = ref.watch(showControlDomainProvider);
    final sessionState = ref.watch(sessionProvider);
    final notifier     = ref.read(showControlProvider.notifier);

    // Override the noop nav/select/delete shortcuts with real desktop behavior.
    return Actions(
      actions: {
        PrevCueIntent:   CallbackAction<PrevCueIntent>(onInvoke: (_) { _selectOffset(-1); return null; }),
        NextCueIntent:   CallbackAction<NextCueIntent>(onInvoke: (_) { _selectOffset(1); return null; }),
        SelectCueIntent: CallbackAction<SelectCueIntent>(onInvoke: (_) {
          if (_selectedCueId != null) notifier.goToCue(_selectedCueId!);
          return null;
        }),
        DeleteCueIntent: CallbackAction<DeleteCueIntent>(onInvoke: (_) {
          if (_selectedCueId != null) notifier.deleteCueById(_selectedCueId!);
          return null;
        }),
      },
      child: Scaffold(
      backgroundColor: ScColors.bg,
      body: Column(
        children: [
          // ── Header bar (session name + status chips + leave) ─────────
          _HeaderBar(
            sessionName: sessionState.session?.name ?? 'Show Control',
            onLeave: _leaveSession,
          ),
          // ── Connection banner ─────────────────────────────────────────
          if (sessionState.health != ConnectionHealth.connected)
            _ConnectionBanner(health: sessionState.health, onLeave: _leaveSession),
          // ── Transport Bar (always visible) ───────────────────────────
          TransportBar(
            playhead: domainState.playhead,
            cueList: domainState.cueList,
            onGo:    () => notifier.go(),
            onStop:  () => notifier.stop(),
            onPause: () => notifier.pause(),
            onResume: () => notifier.resume(),
          ),
          const Divider(height: 1, color: ScColors.divider),
          // ── Main three-panel area ─────────────────────────────────────
          Expanded(
            child: ScThreePaneView(
              leftWidth:  ScSpacing.cueListWidth,
              rightWidth: ScSpacing.monitoringWidth,
              left: _CueListPanel(
                domainState: domainState,
                selectedCueId: _selectedCueId,
                onCueSelected: (id) => setState(() => _selectedCueId = id),
                notifier: notifier,
              ),
              center: _InspectorPanel(
                selectedCueId: _selectedCueId,
                domainState: domainState,
                notifier: notifier,
              ),
              right: _MonitoringPanel(domainState: domainState),
            ),
          ),
          // ── Bottom tab bar + expandable panel ────────────────────────
          const Divider(height: 1, color: ScColors.divider),
          AnimatedSize(
            duration: const Duration(milliseconds: 180),
            curve: Curves.easeInOut,
            child: _bottomPanelOpen
                ? SizedBox(
                    height: 260,
                    child: _BottomTabPanel(controller: _tabController),
                  )
                : const SizedBox.shrink(),
          ),
          if (_bottomPanelOpen)
            const Divider(height: 1, color: ScColors.divider),
          _BottomBar(
            controller: _tabController,
            onTabTap: (i) => setState(() {
              if (_bottomPanelOpen && _lastOpenTab == i) {
                _bottomPanelOpen = false;
              } else {
                _bottomPanelOpen = true;
                _lastOpenTab = i;
              }
            }),
          ),
        ],
      ),
    )); // Actions + Scaffold
  }
}

// ── Header Bar ────────────────────────────────────────────────────────────────

class _HeaderBar extends ConsumerWidget {
  final String sessionName;
  final VoidCallback onLeave;

  const _HeaderBar({required this.sessionName, required this.onLeave});

  void _openSettings(BuildContext context) {
    Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => const SettingsScreen(),
    ));
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final audioStatus = ref.watch(audioNodeProvider);
    final maStatus    = ref.watch(maNodeProvider);
    final tasks       = ref.watch(sessionProvider).myNode?.tasks.toList() ?? [];

    return Container(
      height: 36,
      color: ScColors.surface,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Row(
        children: [
          const Icon(Icons.theater_comedy, size: 14, color: ScColors.textDim),
          const SizedBox(width: 8),
          Text(sessionName, style: ScText.panelTitle),
          const Spacer(),
          if (tasks.contains(NodeTask.NODE_TASK_AUDIO_OUTPUT)) ...[
            _AudioChip(status: audioStatus),
            const SizedBox(width: 8),
          ],
          if (tasks.contains(NodeTask.NODE_TASK_MA_OSC)) ...[
            _MaChip(status: maStatus),
            const SizedBox(width: 8),
          ],
          IconButton(
            icon: const Icon(Icons.settings, size: 16),
            color: ScColors.textDim,
            tooltip: 'Einstellungen',
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
            onPressed: () => _openSettings(context),
          ),
          IconButton(
            icon: const Icon(Icons.logout, size: 16),
            color: ScColors.textDim,
            tooltip: 'Session verlassen',
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
            onPressed: onLeave,
          ),
        ],
      ),
    );
  }
}

class _AudioChip extends StatelessWidget {
  final AudioNodeStatus status;
  const _AudioChip({required this.status});

  @override
  Widget build(BuildContext context) {
    final chipState = switch (status.state) {
      AudioNodeState.connected => ScChipState.ok,
      AudioNodeState.error     => ScChipState.error,
      _                        => ScChipState.idle,
    };
    return ScChip(label: 'AUDIO', state: chipState);
  }
}

class _MaChip extends StatelessWidget {
  final MaNodeStatus status;
  const _MaChip({required this.status});

  @override
  Widget build(BuildContext context) {
    final chipState = switch (status.state) {
      MaNodeState.connected => ScChipState.ok,
      MaNodeState.error     => ScChipState.error,
      _                     => ScChipState.idle,
    };
    return ScChip(label: 'MA', state: chipState);
  }
}

// ── Connection Banner ─────────────────────────────────────────────────────────

class _ConnectionBanner extends StatelessWidget {
  final ConnectionHealth health;
  final VoidCallback onLeave;

  const _ConnectionBanner({required this.health, required this.onLeave});

  @override
  Widget build(BuildContext context) {
    final isDisconnected = health == ConnectionHealth.disconnected;
    final color  = isDisconnected ? ScColors.error : ScColors.warn;
    final label  = isDisconnected
        ? 'Verbindung zum Server getrennt'
        : 'Verbindung wird wiederhergestellt…';

    return Container(
      color: color.withValues(alpha: 0.12),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: Row(
        children: [
          Icon(
            isDisconnected ? Icons.cloud_off : Icons.cloud_sync,
            size: 14, color: color,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(label, style: ScText.label.copyWith(color: color)),
          ),
          if (isDisconnected)
            TextButton(
              style: TextButton.styleFrom(
                foregroundColor: color,
                padding: const EdgeInsets.symmetric(horizontal: 8),
                minimumSize: const Size(0, 28),
              ),
              onPressed: onLeave,
              child: const Text('Verlassen', style: TextStyle(fontSize: 12)),
            )
          else
            SizedBox(
              width: 12, height: 12,
              child: CircularProgressIndicator(strokeWidth: 2, color: color),
            ),
        ],
      ),
    );
  }
}

// ── Left Panel: CueList ────────────────────────────────────────────────────────

class _CueListPanel extends StatelessWidget {
  final ShowControlDomainState domainState;
  final String? selectedCueId;
  final ValueChanged<String?> onCueSelected;
  final ShowControlNotifier notifier;

  const _CueListPanel({
    required this.domainState,
    required this.selectedCueId,
    required this.onCueSelected,
    required this.notifier,
  });

  @override
  Widget build(BuildContext context) {
    final cueList = domainState.cueList;
    final playhead = domainState.playhead;

    return Column(
      children: [
        // Panel header
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
        // Cue rows
        Expanded(
          child: cueList == null
              ? const Center(
                  child: Text('Keine CueList', style: TextStyle(color: ScColors.textDim)),
                )
              : _CueListView(
                  cueList: cueList,
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

  /// Cue IDs that are children of any group (hidden from top-level list).
  Set<String> _childIds(List<Cue> cues) {
    final s = <String>{};
    for (final c in cues) {
      if (c.params case GroupParams gp) s.addAll(gp.childCueIds);
    }
    return s;
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
        // Map top-level reorder back to full ordered ID list
        final tlIds = topLevel.map((c) => c.id).toList();
        final moved = tlIds.removeAt(oldIndex);
        tlIds.insert(newIndex, moved);
        // Rebuild full list: top-level in new order + children (preserved)
        final childCues = cues.where((c) => childIds.contains(c.id)).toList();
        widget.notifier.reorderCue(orderedIds: [...tlIds, ...childCues.map((c) => c.id)]);
      },
      proxyDecorator: (child, _, __) => Material(
        elevation: 4, color: ScColors.surface2,
        borderRadius: BorderRadius.circular(4), child: child,
      ),
      itemBuilder: (context, i) {
        final cue = topLevel[i];
        final isGroup = cue.params is GroupParams;
        final isExpanded = _expandedGroups.contains(cue.id);
        final isActive = widget.playhead.activeCueId == cue.id;
        final isPast = _isCuePast(cue, widget.cueList, widget.playhead);

        final groupChildren = isGroup
            ? (cue.params as GroupParams)
                .childCueIds
                .map((id) => cues.firstWhere((c) => c.id == id,
                    orElse: () => cue))
                .where((c) => c.id != cue.id)
                .toList()
            : null;

        return CueListRow(
          key: ValueKey(cue.id),
          cue: cue,
          runState: widget.playhead.runStateFor(cue.id),
          playhead: widget.playhead,
          isActive: isActive,
          isPast: isPast,
          isSelected: widget.selectedCueId == cue.id,
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
      },
    );
  }

  Future<void> _insertCue(BuildContext context, {String? afterId, String? beforeId}) async {
    final params = await showCueTypePicker(context);
    if (params == null) return;
    // If beforeId, find the cue before it and insert after that
    if (beforeId != null) {
      final idx = widget.cueList.cues.indexWhere((c) => c.id == beforeId);
      final prevId = idx > 0 ? widget.cueList.cues[idx - 1].id : null;
      await widget.notifier.insertDomainCue(params, afterId: prevId);
    } else {
      await widget.notifier.insertDomainCue(params, afterId: afterId);
    }
  }

  static bool _isCuePast(Cue cue, CueList list, PlayheadState playhead) {
    final activeId = playhead.activeCueId;
    if (activeId == null) return false;
    final activeIdx = list.cues.indexWhere((c) => c.id == activeId);
    final thisIdx   = list.cues.indexWhere((c) => c.id == cue.id);
    return thisIdx < activeIdx;
  }
}

// ── Center Panel: Inspector ────────────────────────────────────────────────────

class _InspectorPanel extends ConsumerWidget {
  final String? selectedCueId;
  final ShowControlDomainState domainState;
  final ShowControlNotifier notifier;

  const _InspectorPanel({
    required this.selectedCueId,
    required this.domainState,
    required this.notifier,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cue = selectedCueId != null
        ? domainState.cueList?.cueById(selectedCueId!)
        : null;

    if (cue == null) {
      return Container(
        color: ScColors.surface,
        child: Center(
          child: Text(
            'Cue auswählen',
            style: TextStyle(color: ScColors.textDim),
          ),
        ),
      );
    }

    return _CueInspector(cue: cue, notifier: notifier);
  }
}

/// Vollständiger Cue-Inspector mit ScInlineField-Komponenten.
/// Kennt nur Domain-Typen — kein gRPC/Proto-Import.
class _CueInspector extends StatefulWidget {
  final Cue cue;
  final ShowControlNotifier notifier;

  const _CueInspector({required this.cue, required this.notifier});

  @override
  State<_CueInspector> createState() => _CueInspectorState();
}

class _CueInspectorState extends State<_CueInspector> {
  late Cue _draft;
  bool _saving = false;
  Timer? _debounce;

  /// Saves params per type so switching types and back restores previous values.
  final Map<Type, CueParams> _paramsCache = {};

  @override
  void initState() {
    super.initState();
    _draft = widget.cue;
  }

  @override
  void didUpdateWidget(_CueInspector old) {
    super.didUpdateWidget(old);
    if (old.cue.id != widget.cue.id) {
      // Different cue selected — reset everything.
      _debounce?.cancel();
      _paramsCache.clear();
      setState(() { _draft = widget.cue; _saving = false; });
    } else if (_debounce?.isActive != true && !_saving && widget.cue != _draft) {
      // Same cue, no pending local edit, server sent updated data
      // → accept server version so other devices' changes appear immediately.
      setState(() => _draft = widget.cue);
    }
  }

  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
  }

  void _update(Cue updated) {
    setState(() => _draft = updated);
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 350), _flush);
  }

  /// Called by _ParamsSection for both type switches and param edits.
  void _onParamsChanged(CueParams newParams) {
    if (newParams.runtimeType != _draft.params.runtimeType) {
      // Type switch: cache current params, restore if user comes back.
      _paramsCache[_draft.params.runtimeType] = _draft.params;
      final restored = _paramsCache[newParams.runtimeType];
      _update(_draft.copyWith(params: restored ?? newParams));
    } else {
      _update(_draft.copyWith(params: newParams));
    }
  }

  Future<void> _flush() async {
    _debounce = null; // mark as no longer pending so sync can resume
    if (!mounted) return;
    setState(() => _saving = true);
    await widget.notifier.upsertDomainCue(_draft);
    if (mounted) setState(() => _saving = false);
  }

  @override
  Widget build(BuildContext context) {
    return ScPanel(
      title: '${_draft.number} · ${_draft.label}',
      trailing: _saving
          ? const SizedBox(
              width: 12, height: 12,
              child: CircularProgressIndicator(strokeWidth: 1.5, color: ScColors.active),
            )
          : null,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(ScSpacing.panelPad),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _Section(title: 'ALLGEMEIN', children: [
              ScInlineField(
                label: 'Nummer',
                value: _draft.number,
                onChanged: (v) => _update(_draft.copyWith(number: v)),
              ),
              const SizedBox(height: 6),
              ScInlineField(
                label: 'Label',
                value: _draft.label,
                onChanged: (v) => _update(_draft.copyWith(label: v)),
              ),
            ]),
            const SizedBox(height: 12),
            _Section(title: 'TIMING', children: [
              ScInlineField(
                label: 'Pre-Wait',
                value: _draft.timing.preWaitMs.toStringAsFixed(0),
                suffix: 'ms',
                keyboardType: TextInputType.number,
                onChanged: (v) => _update(_draft.copyWith(
                  timing: _draft.timing.copyWith(
                    preWaitMs: double.tryParse(v) ?? _draft.timing.preWaitMs,
                  ),
                )),
              ),
              const SizedBox(height: 6),
              ScInlineField(
                label: 'Post-Wait',
                value: _draft.timing.postWaitMs.toStringAsFixed(0),
                suffix: 'ms',
                keyboardType: TextInputType.number,
                onChanged: (v) => _update(_draft.copyWith(
                  timing: _draft.timing.copyWith(
                    postWaitMs: double.tryParse(v) ?? _draft.timing.postWaitMs,
                  ),
                )),
              ),
              const SizedBox(height: 6),
              _BoolField(
                label: 'Auto-Continue',
                value: _draft.timing.autoContinue,
                onChanged: (v) => _update(_draft.copyWith(
                  timing: _draft.timing.copyWith(autoContinue: v),
                )),
              ),
            ]),
            const SizedBox(height: 12),
            _ParamsSection(
              params: _draft.params,
              onChanged: _onParamsChanged,
            ),
          ],
        ),
      ),
    );
  }
}

/// Bool toggle field (inline checkbox row).
class _BoolField extends StatelessWidget {
  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _BoolField({
    required this.label,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SizedBox(
          width: ScSpacing.inspectorLabelWidth,
          child: Text(label, style: ScText.label),
        ),
        SizedBox(
          height: 20,
          width: 36,
          child: Transform.scale(
            scale: 0.75,
            child: Switch(
              value: value,
              onChanged: onChanged,
              activeThumbColor: ScColors.active,
            ),
          ),
        ),
      ],
    );
  }
}

/// Labeled section with a compact header.
class _Section extends StatelessWidget {
  final String title;
  final List<Widget> children;

  const _Section({required this.title, required this.children});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: ScText.panelTitle),
        const SizedBox(height: 6),
        ...children,
      ],
    );
  }
}

/// Renders param-specific fields based on sealed [CueParams] type.
class _ParamsSection extends StatelessWidget {
  final CueParams params;
  final ValueChanged<CueParams> onChanged;

  const _ParamsSection({required this.params, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Typ-Wechsler
        _CueTypeSwitcher(current: params, onSwitch: onChanged),
        const SizedBox(height: 12),
        // Param-Editor für den gewählten Typ
        switch (params) {
          AudioParams p => _AudioParamsEditor(params: p, onChanged: onChanged),
          WaitParams  p => _WaitParamsEditor(params: p, onChanged: onChanged),
          MaOscParams p => _MaOscParamsEditor(params: p, onChanged: onChanged),
          GotoParams  p => _GotoParamsEditor(params: p, onChanged: onChanged),
          NoteParams  p => _NoteParamsEditor(params: p, onChanged: onChanged),
          FadeParams  p => _FadeParamsEditor(params: p, onChanged: onChanged),
          _             => const SizedBox.shrink(),
        },
      ],
    );
  }
}

/// Kompakte Chip-Leiste zum Wechsel des Cue-Typs.
class _CueTypeSwitcher extends StatelessWidget {
  final CueParams current;
  final ValueChanged<CueParams> onSwitch;

  const _CueTypeSwitcher({required this.current, required this.onSwitch});

  static const _types = [
    (icon: Icons.volume_up,            label: 'Audio', key: 'audio'),
    (icon: Icons.timer_outlined,       label: 'Wait',  key: 'wait'),
    (icon: Icons.tune,                 label: 'Fade',  key: 'fade'),
    (icon: Icons.settings_remote,      label: 'MA',    key: 'maOsc'),
    (icon: Icons.redo,                 label: 'GOTO',  key: 'goto'),
    (icon: Icons.account_tree_outlined,label: 'Group', key: 'group'),
    (icon: Icons.text_fields,          label: 'Note',  key: 'note'),
  ];

  String get _currentKey => switch (current) {
    AudioParams() => 'audio',
    WaitParams()  => 'wait',
    MaOscParams() => 'maOsc',
    GotoParams()  => 'goto',
    GroupParams() => 'group',
    NoteParams()  => 'note',
    FadeParams()  => 'fade',
    _             => '',
  };

  CueParams _defaultFor(String key) => switch (key) {
    'audio' => const AudioParams(assetId: ''),
    'wait'  => const WaitParams(durationMs: 5000),
    'maOsc' => const MaOscParams(oscAddress: '/gma2/cmd'),
    'goto'  => const GotoParams(targetCueId: ''),
    'group' => const GroupParams(childCueIds: [], sequential: false),
    'note'  => const NoteParams(text: ''),
    'fade'  => const FadeParams(),
    _       => const AudioParams(assetId: ''),
  };

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 4,
      children: _types.map((t) {
        final isSelected = t.key == _currentKey;
        return Tooltip(
          message: t.label,
          child: GestureDetector(
            onTap: isSelected ? null : () => onSwitch(_defaultFor(t.key)),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 120),
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: isSelected
                    ? ScColors.active.withValues(alpha: 0.15)
                    : Colors.transparent,
                border: Border.all(
                  color: isSelected ? ScColors.active : ScColors.divider,
                ),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    t.icon,
                    size: 12,
                    color: isSelected ? ScColors.active : ScColors.textDim,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    t.label,
                    style: TextStyle(
                      color: isSelected ? ScColors.active : ScColors.textDim,
                      fontSize: 10,
                      fontWeight: isSelected ? FontWeight.w700 : FontWeight.normal,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}

/// EBU R128 Ziellautstärke für Theater.
const _kTargetLufs = -23.0;

class _AudioParamsEditor extends ConsumerWidget {
  final AudioParams params;
  final ValueChanged<CueParams> onChanged;

  const _AudioParamsEditor({required this.params, required this.onChanged});

  /// Berechnet volumeDb sodass das Asset mit [lufs] auf [_kTargetLufs] normiert
  /// gespielt wird. Ergibt z.B. −5.0 dB wenn Asset −18 LUFS hat.
  static double _autoVolume(double lufs) =>
      (_kTargetLufs - lufs).clamp(-40.0, 20.0);

  void _pickAsset(Asset asset, AudioParams current) {
    final lufs = asset.audio?.loudnessLufs;
    onChanged(current.copyWith(
      assetId:  asset.id,
      volumeDb: lufs != null ? _autoVolume(lufs) : current.volumeDb,
      declaredDurationMs: asset.audio?.declaredDurationMs,
    ));
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final audioNotifier    = ref.read(audioNodeProvider.notifier);
    final isAudioConnected =
        ref.watch(audioNodeProvider).state == AudioNodeState.connected;
    final asset   = ref.watch(assetWithReadinessProvider(params.assetId));
    final allAssets = ref.watch(enrichedAssetsProvider)
        .where((a) => a.mimeType.startsWith('audio/'))
        .toList();

    // Ist der aktuelle volumeDb eine Auto-Normierung?
    final lufs = asset?.audio?.loudnessLufs;
    final autoVolDb = lufs != null ? _autoVolume(lufs) : null;
    final isAutoVol = autoVolDb != null &&
        (params.volumeDb - autoVolDb).abs() < 0.05;

    return _Section(title: 'AUDIO', children: [
      // ── Asset-Picker ───────────────────────────────────────────────
      if (asset != null) _AssetReadinessBadge(asset: asset),
      if (asset != null) const SizedBox(height: 6),
      _AssetPicker(
        current: asset,
        allAssets: allAssets,
        onPick: (a) => _pickAsset(a, params),
        onClear: () => onChanged(params.copyWith(assetId: '')),
      ),
      // Lautheit & Technische Infos (read-only)
      if (asset?.audio != null) ...[
        const SizedBox(height: 6),
        ScInlineField(
          label: 'Lautheit',
          value: lufs != null ? lufs.toStringAsFixed(1) : '—',
          suffix: 'LUFS',
          readOnly: true,
          tooltip: 'EBU R128 integrierte Lautheit (K-gewichtet)',
        ),
        const SizedBox(height: 4),
        ScInlineField(
          label: 'Format',
          value: '${asset!.audio!.channelLabel}  '
              '${asset.audio!.sampleRateHz} Hz  '
              '${asset.audio!.codec.toUpperCase()}',
          readOnly: true,
        ),
      ],
      const SizedBox(height: 6),
      // ── Volume mit Auto-Badge ──────────────────────────────────────
      Row(
        children: [
          Expanded(
            child: ScDragField(
              label: 'Volume',
              value: params.volumeDb,
              min: -40,
              max: 20,
              step: 0.2,
              suffix: 'dB',
              decimalPlaces: 1,
              onChanged: (v) => onChanged(params.copyWith(volumeDb: v)),
            ),
          ),
          if (isAutoVol) ...[
            const SizedBox(width: 6),
            Tooltip(
              message: 'Automatisch normiert auf $_kTargetLufs LUFS (EBU R128)',
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                decoration: BoxDecoration(
                  color: ScColors.active.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  'EBU',
                  style: ScText.label.copyWith(
                      color: ScColors.active,
                      fontSize: 9,
                      fontWeight: FontWeight.w800),
                ),
              ),
            ),
          ] else if (autoVolDb != null) ...[
            const SizedBox(width: 6),
            Tooltip(
              message: 'Auf EBU R128 normieren (${autoVolDb.toStringAsFixed(1)} dB)',
              child: GestureDetector(
                onTap: () => onChanged(params.copyWith(volumeDb: autoVolDb)),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                  decoration: BoxDecoration(
                    border: Border.all(color: ScColors.textDim),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    'EBU',
                    style: ScText.label.copyWith(
                        color: ScColors.textDim,
                        fontSize: 9,
                        fontWeight: FontWeight.w700),
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
      const SizedBox(height: 6),
      ScDragField(
        label: 'Fade In',
        value: params.fadeInMs,
        min: 0,
        max: 60000,
        step: 10,
        suffix: 'ms',
        decimalPlaces: 0,
        onChanged: (v) => onChanged(params.copyWith(fadeInMs: v)),
      ),
      const SizedBox(height: 6),
      ScDragField(
        label: 'Fade Out',
        value: params.fadeOutMs,
        min: 0,
        max: 60000,
        step: 10,
        suffix: 'ms',
        decimalPlaces: 0,
        onChanged: (v) => onChanged(params.copyWith(fadeOutMs: v)),
      ),
      const SizedBox(height: 6),
      ScDragField(
        label: 'Start',
        value: params.startTimeMs,
        min: 0,
        max: 3600000,
        step: 10,
        suffix: 'ms',
        decimalPlaces: 0,
        onChanged: (v) => onChanged(params.copyWith(startTimeMs: v)),
      ),
      const SizedBox(height: 6),
      ScDragField(
        label: 'End',
        value: params.endTimeMs,
        min: 0,
        max: 3600000,
        step: 10,
        suffix: 'ms',
        decimalPlaces: 0,
        onChanged: (v) => onChanged(params.copyWith(endTimeMs: v)),
      ),
      const SizedBox(height: 6),
      _BoolField(
        label: 'Loop',
        value: params.loop,
        onChanged: (v) => onChanged(params.copyWith(loop: v)),
      ),
      const SizedBox(height: 12),
      // ── Pause / Resume ─────────────────────────────────────────────
      _Section(title: 'PAUSE / RESUME', children: [
        _EnumField<PauseBehavior>(
          label: 'Bei Pause',
          value: params.pauseBehavior,
          items: const [
            (PauseBehavior.hard,    'Hart (sofort)'),
            (PauseBehavior.fadeOut, 'Ausblenden'),
          ],
          onChanged: (v) => onChanged(params.copyWith(pauseBehavior: v)),
        ),
        if (params.pauseBehavior == PauseBehavior.fadeOut) ...[
          const SizedBox(height: 6),
          ScDragField(
            label: 'Pause-Fade',
            value: params.pauseFadeMs,
            min: 0, max: 10000, step: 50,
            suffix: 'ms', decimalPlaces: 0,
            onChanged: (v) => onChanged(params.copyWith(pauseFadeMs: v)),
          ),
        ],
        const SizedBox(height: 6),
        _EnumField<ResumeBehavior>(
          label: 'Fortsetzen',
          value: params.resumeBehavior,
          items: const [
            (ResumeBehavior.continuePlaying, 'Nahtlos weiter'),
            (ResumeBehavior.fadeIn,          'Einblenden'),
            (ResumeBehavior.fromStart,       'Von vorne'),
          ],
          onChanged: (v) => onChanged(params.copyWith(resumeBehavior: v)),
        ),
        if (params.resumeBehavior == ResumeBehavior.fadeIn) ...[
          const SizedBox(height: 6),
          ScDragField(
            label: 'Resume-Fade',
            value: params.resumeFadeMs,
            min: 0, max: 10000, step: 50,
            suffix: 'ms', decimalPlaces: 0,
            onChanged: (v) => onChanged(params.copyWith(resumeFadeMs: v)),
          ),
        ],
      ]),
      const SizedBox(height: 8),
      AudioCueMinibar(params: params, asset: asset),
      const SizedBox(height: 8),
      // ── Audition ──────────────────────────────────────────────────
      Row(
        children: [
          Tooltip(
            message: !isAudioConnected
                ? 'Audio-Engine starten (Audio-Tab → Starten)'
                : params.assetId.isEmpty
                    ? 'Kein Asset ausgewählt'
                    : '',
            child: ScButton(
              label: 'Vorhören',
              icon: Icons.headphones,
              variant: ScButtonVariant.secondary,
              size: ScButtonSize.compact,
              onPressed: isAudioConnected && params.assetId.isNotEmpty && asset != null
                  ? () => audioNotifier.auditionPlay(
                        assetId: asset.name,   // Dateiname, nicht SHA-256
                        volumeDb: params.volumeDb,
                        startMs: params.startTimeMs,
                      )
                  : null,
            ),
          ),
          const SizedBox(width: 8),
          ScButton(
            label: 'Stopp',
            icon: Icons.stop,
            variant: ScButtonVariant.ghost,
            size: ScButtonSize.compact,
            onPressed: isAudioConnected
                ? () => audioNotifier.auditionStop()
                : null,
          ),
        ],
      ),
    ]);
  }
}

/// Dropdown-Picker für Audio-Assets.
/// Zeigt Dateinamen statt SHA-256. SHA-256 + technische Infos als Tooltip.
class _AssetPicker extends StatelessWidget {
  final Asset? current;
  final List<Asset> allAssets;
  final ValueChanged<Asset> onPick;
  final VoidCallback onClear;

  const _AssetPicker({
    required this.current,
    required this.allAssets,
    required this.onPick,
    required this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              border: Border.all(color: ScColors.divider),
              borderRadius: BorderRadius.circular(6),
              color: ScColors.surface,
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                isExpanded: true,
                value: current != null &&
                        allAssets.any((a) => a.id == current!.id)
                    ? current!.id
                    : null,
                hint: Text(
                  current != null
                      ? current!.name
                      : 'Asset auswählen…',
                  style: ScText.label.copyWith(
                    color: current != null
                        ? ScColors.textPrimary
                        : ScColors.textDim,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                dropdownColor: ScColors.surface,
                icon: const Icon(Icons.unfold_more,
                    size: 16, color: ScColors.textDim),
                items: allAssets.map((a) {
                  final lufs = a.audio?.loudnessLufs;
                  final info = [
                    if (a.audio != null) a.audio!.channelLabel,
                    if (a.audio?.sampleRateHz != null)
                      '${a.audio!.sampleRateHz} Hz',
                    if (lufs != null) '${lufs.toStringAsFixed(1)} LUFS',
                  ].join(' · ');
                  return DropdownMenuItem<String>(
                    value: a.id,
                    child: Tooltip(
                      message: '${a.id.substring(0, 12)}…  ${_formatSize(a.sizeBytes)}',
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            a.name,
                            style: ScText.label
                                .copyWith(color: ScColors.textPrimary),
                            overflow: TextOverflow.ellipsis,
                          ),
                          if (info.isNotEmpty)
                            Text(
                              info,
                              style: ScText.label.copyWith(
                                  color: ScColors.textDim, fontSize: 10),
                            ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
                onChanged: (id) {
                  if (id == null) return;
                  final picked = allAssets.firstWhere((a) => a.id == id);
                  onPick(picked);
                },
              ),
            ),
          ),
        ),
        if (current != null) ...[
          const SizedBox(width: 6),
          Tooltip(
            message: 'Asset entfernen',
            child: GestureDetector(
              onTap: onClear,
              child: const Icon(Icons.close, size: 14, color: ScColors.textDim),
            ),
          ),
        ],
      ],
    );
  }
}

class _WaitParamsEditor extends StatelessWidget {
  final WaitParams params;
  final ValueChanged<CueParams> onChanged;

  const _WaitParamsEditor({required this.params, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return _Section(title: 'WAIT', children: [
      ScDragField(
        label: 'Dauer',
        value: params.durationMs,
        min: 0,
        max: 3600000,
        step: 50,
        suffix: 'ms',
        decimalPlaces: 0,
        onChanged: (v) => onChanged(params.copyWith(durationMs: v)),
      ),
    ]);
  }
}

class _MaOscParamsEditor extends StatelessWidget {
  final MaOscParams params;
  final ValueChanged<CueParams> onChanged;

  const _MaOscParamsEditor({required this.params, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return _Section(title: 'GrandMA OSC', children: [
      ScInlineField(
        label: 'Adresse',
        value: params.oscAddress,
        onChanged: (v) => onChanged(params.copyWith(oscAddress: v)),
      ),
      const SizedBox(height: 6),
      ScInlineField(
        label: 'Argument',
        value: params.oscArgument,
        onChanged: (v) => onChanged(params.copyWith(oscArgument: v)),
      ),
      const SizedBox(height: 6),
      ScInlineField(
        label: 'Executor',
        value: params.executorNo.toString(),
        keyboardType: TextInputType.number,
        onChanged: (v) => onChanged(params.copyWith(
          executorNo: int.tryParse(v) ?? params.executorNo,
        )),
      ),
      const SizedBox(height: 6),
      ScInlineField(
        label: 'Page',
        value: params.executorPage.toString(),
        keyboardType: TextInputType.number,
        onChanged: (v) => onChanged(params.copyWith(
          executorPage: int.tryParse(v) ?? params.executorPage,
        )),
      ),
    ]);
  }
}

class _GotoParamsEditor extends StatelessWidget {
  final GotoParams params;
  final ValueChanged<CueParams> onChanged;

  const _GotoParamsEditor({required this.params, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return _Section(title: 'GOTO', children: [
      ScInlineField(
        label: 'Cue-Nr.',
        value: params.targetNumber,
        readOnly: true,
        tooltip: 'Cue-ID: ${params.targetCueId}',
      ),
    ]);
  }
}

// ── Note Params Editor ────────────────────────────────────────────────────────

class _NoteParamsEditor extends StatefulWidget {
  final NoteParams params;
  final ValueChanged<CueParams> onChanged;
  const _NoteParamsEditor({required this.params, required this.onChanged});
  @override
  State<_NoteParamsEditor> createState() => _NoteParamsEditorState();
}

class _NoteParamsEditorState extends State<_NoteParamsEditor> {
  late TextEditingController _textCtrl;

  @override
  void initState() {
    super.initState();
    _textCtrl = TextEditingController(text: widget.params.text);
  }

  @override
  void didUpdateWidget(_NoteParamsEditor old) {
    super.didUpdateWidget(old);
    if (old.params.text != widget.params.text) _textCtrl.text = widget.params.text;
  }

  @override
  void dispose() { _textCtrl.dispose(); super.dispose(); }

  static const _palette = [
    null,                        // default grey
    Color(0xFFEF5350),           // red
    Color(0xFFFF9800),           // orange
    Color(0xFFFFEE58),           // yellow
    Color(0xFF66BB6A),           // green
    Color(0xFF42A5F5),           // blue
    Color(0xFFAB47BC),           // purple
    Color(0xFFFFFFFF),           // white
  ];

  @override
  Widget build(BuildContext context) {
    return _Section(title: 'NOTE', children: [
      ScInlineField(
        label: 'Text',
        value: widget.params.text,
        onChanged: (v) => widget.onChanged(widget.params.copyWith(text: v)),
      ),
      const SizedBox(height: 8),
      Row(
        children: [
          SizedBox(
            width: ScSpacing.inspectorLabelWidth,
            child: Text('Farbe', style: ScText.label),
          ),
          const SizedBox(width: 6),
          Wrap(
            spacing: 6,
            children: _palette.map((c) {
              final isSelected = c == widget.params.color ||
                  (c == null && widget.params.color == null);
              return GestureDetector(
                onTap: () => widget.onChanged(widget.params.copyWith(color: c)),
                child: Container(
                  width: 20, height: 20,
                  decoration: BoxDecoration(
                    color: c ?? ScColors.textDim,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isSelected ? ScColors.active : Colors.transparent,
                      width: 2,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    ]);
  }
}

// ── Fade Params Editor ────────────────────────────────────────────────────────

class _FadeParamsEditor extends ConsumerWidget {
  final FadeParams params;
  final ValueChanged<CueParams> onChanged;
  const _FadeParamsEditor({required this.params, required this.onChanged});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cueList = ref.watch(domainCueListProvider);
    final cues = cueList?.cues ?? [];

    return _Section(title: 'FADE / CONTROL', children: [
      // Target cue picker
      Row(
        children: [
          SizedBox(
            width: ScSpacing.inspectorLabelWidth,
            child: Text('Ziel', style: ScText.label),
          ),
          const SizedBox(width: 6),
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              decoration: BoxDecoration(
                color: ScColors.bg,
                borderRadius: BorderRadius.circular(4),
                border: Border.all(color: ScColors.divider),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: cues.any((c) => c.id == params.targetCueId)
                      ? params.targetCueId
                      : '',
                  isDense: true,
                  isExpanded: true,
                  dropdownColor: ScColors.surface2,
                  style: ScText.cueLabel.copyWith(fontSize: 13),
                  items: [
                    const DropdownMenuItem(value: '', child: Text('— Keine —')),
                    ...cues.where((c) => c.params is AudioParams).map((c) =>
                        DropdownMenuItem(
                          value: c.id,
                          child: Text('${c.number}  ${c.label}',
                              overflow: TextOverflow.ellipsis),
                        )),
                  ],
                  onChanged: (id) {
                    if (id == null) return;
                    final cue = cues.firstWhere((c) => c.id == id,
                        orElse: () => cues.first);
                    onChanged(params.copyWith(
                      targetCueId: id,
                      targetCueNumber: id.isEmpty ? '' : cue.number,
                    ));
                  },
                ),
              ),
            ),
          ),
        ],
      ),
      const SizedBox(height: 6),
      _EnumField<FadeAction>(
        label: 'Aktion',
        value: params.action,
        items: const [
          (FadeAction.volume, 'Lautstärke'),
          (FadeAction.stop,   'Mit Fade stoppen'),
          (FadeAction.pause,  'Mit Fade pausieren'),
          (FadeAction.resume, 'Mit Fade fortsetzen'),
        ],
        onChanged: (v) => onChanged(params.copyWith(action: v)),
      ),
      if (params.action != FadeAction.resume) ...[
        const SizedBox(height: 6),
        ScDragField(
          label: 'Ziel-Vol.',
          value: params.targetVolumeDb,
          min: -60, max: 6, step: 0.5,
          suffix: 'dB', decimalPlaces: 1,
          onChanged: (v) => onChanged(params.copyWith(targetVolumeDb: v)),
        ),
      ],
      const SizedBox(height: 6),
      ScDragField(
        label: 'Dauer',
        value: params.durationMs,
        min: 0, max: 30000, step: 100,
        suffix: 'ms', decimalPlaces: 0,
        onChanged: (v) => onChanged(params.copyWith(durationMs: v)),
      ),
      if (params.action == FadeAction.volume) ...[
        const SizedBox(height: 6),
        _BoolField(
          label: 'Stopp danach',
          value: params.stopWhenDone,
          onChanged: (v) => onChanged(params.copyWith(stopWhenDone: v)),
        ),
      ],
      const SizedBox(height: 8),
      Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: ScColors.warn.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(4),
          border: Border.all(color: ScColors.warn.withValues(alpha: 0.3)),
        ),
        child: Text(
          'Fade-Cues benötigen Server-Unterstützung (v2). '
          'Aktuell wird die Konfiguration gespeichert; '
          'Ausführung ab nächstem Server-Update.',
          style: ScText.statusSmall.copyWith(color: ScColors.warn),
        ),
      ),
    ]);
  }
}

// ── Generic enum dropdown field ───────────────────────────────────────────────

class _EnumField<T> extends StatelessWidget {
  final String label;
  final T value;
  final List<(T, String)> items;
  final ValueChanged<T> onChanged;

  const _EnumField({
    required this.label,
    required this.value,
    required this.items,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SizedBox(
          width: ScSpacing.inspectorLabelWidth,
          child: Text(label, style: ScText.label),
        ),
        const SizedBox(width: 6),
        Expanded(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            decoration: BoxDecoration(
              color: ScColors.bg,
              borderRadius: BorderRadius.circular(4),
              border: Border.all(color: ScColors.divider),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<T>(
                value: value,
                isDense: true,
                isExpanded: true,
                dropdownColor: ScColors.surface2,
                style: ScText.cueLabel.copyWith(fontSize: 13),
                items: items.map((e) => DropdownMenuItem(
                  value: e.$1,
                  child: Text(e.$2),
                )).toList(),
                onChanged: (v) { if (v != null) onChanged(v); },
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// ── Right Panel: Monitoring ────────────────────────────────────────────────────

class _MonitoringPanel extends StatelessWidget {
  final ShowControlDomainState domainState;

  const _MonitoringPanel({required this.domainState});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Node health strip
        Container(
          color: ScColors.surface,
          padding: const EdgeInsets.all(ScSpacing.panelPad),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('NODES', style: ScText.panelTitle),
              const SizedBox(height: 8),
              NodeHealthStrip(
                nodes: domainState.nodes,
              ),
            ],
          ),
        ),
        const Divider(height: 1, color: ScColors.divider),
        // Active cue monitor
        Expanded(
          child: ScPanel(
            title: 'Aktiver Cue',
            child: ActiveCueMonitor(
              playhead: domainState.playhead,
              cueList: domainState.cueList,
            ),
          ),
        ),
      ],
    );
  }
}

// ── Bottom Tab Panel (expandable content) ────────────────────────────────────

class _BottomTabPanel extends ConsumerWidget {
  final TabController controller;
  const _BottomTabPanel({required this.controller});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final domainState = ref.watch(showControlDomainProvider);
    final notifier    = ref.read(showControlProvider.notifier);

    return TabBarView(
      controller: controller,
      physics: const NeverScrollableScrollPhysics(),
      children: [
        PatchMatrix(
          config: domainState.patchConfig,
          nodes: domainState.nodes,
          onChanged: (updated) => notifier.updatePatchConfig(updated),
        ),
        const MediaManagerScreen(),
        const NodeManagementPanel(),
        const LocalAudioPanel(),
      ],
    );
  }
}

// ── Bottom Bar ─────────────────────────────────────────────────────────────────

class _BottomBar extends StatelessWidget {
  final TabController controller;
  final ValueChanged<int> onTabTap;

  const _BottomBar({required this.controller, required this.onTabTap});

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: ScColors.surface,
      child: Row(
        children: [
          TabBar(
            controller: controller,
            isScrollable: true,
            dividerHeight: 0,
            indicatorColor: ScColors.active,
            labelColor: ScColors.active,
            unselectedLabelColor: ScColors.textDim,
            labelStyle: ScText.labelBold,
            unselectedLabelStyle: ScText.label,
            tabAlignment: TabAlignment.start,
            onTap: onTabTap,
            tabs: const [
              Tab(text: 'PATCH',  height: 36),
              Tab(text: 'MEDIA',  height: 36),
              Tab(text: 'NODES',  height: 36),
              Tab(text: 'AUDIO',  height: 36),
            ],
          ),
          const Spacer(),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: _ClockInfo(),
          ),
        ],
      ),
    );
  }
}

class _ClockInfo extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _hint('Space', 'GO'),
        const SizedBox(width: 12),
        _hint('Esc', 'STOP'),
        const SizedBox(width: 12),
        _hint('P', 'PAUSE'),
        const SizedBox(width: 12),
        _hint('↑↓', 'Nav'),
        const SizedBox(width: 12),
        _hint('Del', '🗑'),
      ],
    );
  }

  Widget _hint(String key, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
          decoration: BoxDecoration(
            border: Border.all(color: ScColors.divider),
            borderRadius: BorderRadius.circular(3),
          ),
          child: Text(key, style: ScText.statusSmall),
        ),
        const SizedBox(width: 3),
        Text(label, style: ScText.statusSmall),
      ],
    );
  }
}

// ── Asset-Readiness Badge ──────────────────────────────────────────────────────

class _AssetReadinessBadge extends StatelessWidget {
  final Asset asset;
  const _AssetReadinessBadge({required this.asset});

  @override
  Widget build(BuildContext context) {
    final (color, icon, label) = switch (asset.readiness) {
      AssetReadiness.patched    => (ScColors.active, Icons.check_circle_outline, asset.readinessLabel),
      AssetReadiness.renderable => (ScColors.active, Icons.play_circle_outline, asset.readinessLabel),
      AssetReadiness.validated  => (ScColors.warn,   Icons.verified_outlined, asset.readinessLabel),
      AssetReadiness.present    => (ScColors.warn,   Icons.download_done_outlined, asset.readinessLabel),
    };

    return Row(
      children: [
        Icon(icon, size: 13, color: color),
        const SizedBox(width: 5),
        Text(
          '${asset.name}  ·  $label',
          style: ScText.label.copyWith(color: color),
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }
}

String _formatSize(int bytes) {
  if (bytes < 1024) return '$bytes B';
  if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
  return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
}
