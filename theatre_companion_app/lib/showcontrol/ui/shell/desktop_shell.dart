import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/show_control_provider.dart';
import '../../providers/show_control_domain_provider.dart';
import '../design_system/sc_colors.dart';
import '../design_system/sc_spacing.dart';
import '../design_system/sc_typography.dart';
import '../design_system/primitives/sc_button.dart';
import '../design_system/primitives/sc_panel.dart';
import '../design_system/primitives/sc_split_view.dart';
import '../design_system/primitives/sc_inline_field.dart';
import '../design_system/domain_components/transport_bar.dart';
import '../design_system/domain_components/cue_list_row.dart';
import '../design_system/domain_components/active_cue_monitor.dart';
import '../design_system/domain_components/node_status_badge.dart';
import '../design_system/domain_components/audio_cue_minibar.dart';
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

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final domainState = ref.watch(showControlDomainProvider);
    final notifier    = ref.read(showControlProvider.notifier);

    return Scaffold(
      backgroundColor: ScColors.bg,
      body: Column(
        children: [
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
          // ── Bottom tab bar ─────────────────────────────────────────────
          const Divider(height: 1, color: ScColors.divider),
          _BottomBar(controller: _tabController),
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
              IconButton(
                icon: const Icon(Icons.add, size: 18),
                color: ScColors.textSecondary,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
                onPressed: () => notifier.addCue(),
                tooltip: 'Cue hinzufügen',
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

class _CueListView extends StatelessWidget {
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
  Widget build(BuildContext context) {
    return ReorderableListView.builder(
      itemCount: cueList.cues.length,
      onReorder: (oldIndex, newIndex) {
        if (newIndex > oldIndex) newIndex--;
        final ids = cueList.cues.map((c) => c.id).toList();
        final moved = ids.removeAt(oldIndex);
        ids.insert(newIndex, moved);
        notifier.reorderCue(orderedIds: ids);
      },
      itemBuilder: (context, i) {
        final cue = cueList.cues[i];
        final isActive = playhead.activeCueId == cue.id;
        final isPast = _isCuePast(cue, cueList, playhead);

        return CueListRow(
          key: ValueKey(cue.id),
          cue: cue,
          runState: playhead.runStateFor(cue.id),
          isActive: isActive,
          isPast: isPast,
          isSelected: selectedCueId == cue.id,
          showDragHandle: true,
          dragIndex: i,
          onTap: () => onCueSelected(cue.id),
          onDelete: () => notifier.deleteCueById(cue.id),
          onGo: () => notifier.goToCue(cue.id),
        );
      },
    );
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
  // Track unsaved edits locally; commit via [_save].
  late Cue _draft;
  bool _dirty = false;

  @override
  void initState() {
    super.initState();
    _draft = widget.cue;
  }

  @override
  void didUpdateWidget(_CueInspector old) {
    super.didUpdateWidget(old);
    // Reset draft when a different cue is selected (discard unsaved changes).
    if (old.cue.id != widget.cue.id) {
      setState(() {
        _draft = widget.cue;
        _dirty = false;
      });
    }
  }

  void _update(Cue updated) {
    setState(() {
      _draft = updated;
      _dirty = true;
    });
  }

  Future<void> _save() async {
    await widget.notifier.upsertDomainCue(_draft);
    if (mounted) setState(() => _dirty = false);
  }

  void _discard() {
    setState(() {
      _draft = widget.cue;
      _dirty = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return ScPanel(
      title: '${_draft.number} · ${_draft.label}',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(ScSpacing.panelPad),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── General ───────────────────────────────────────────
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
                  // ── Timing ────────────────────────────────────────────
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
                  // ── Params ────────────────────────────────────────────
                  _ParamsSection(
                    params: _draft.params,
                    onChanged: (p) => _update(_draft.copyWith(params: p)),
                  ),
                ],
              ),
            ),
          ),
          // ── Action bar ────────────────────────────────────────────────
          if (_dirty)
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: ScSpacing.panelPad,
                vertical: 8,
              ),
              decoration: const BoxDecoration(
                border: Border(top: BorderSide(color: ScColors.divider)),
                color: ScColors.surface,
              ),
              child: Row(
                children: [
                  ScButton(
                    label: 'Speichern',
                    variant: ScButtonVariant.primary,
                    size: ScButtonSize.compact,
                    onPressed: _save,
                  ),
                  const SizedBox(width: 8),
                  ScButton(
                    label: 'Verwerfen',
                    variant: ScButtonVariant.ghost,
                    size: ScButtonSize.compact,
                    onPressed: _discard,
                  ),
                ],
              ),
            ),
        ],
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
    return switch (params) {
      AudioParams p => _AudioParamsEditor(params: p, onChanged: onChanged),
      WaitParams  p => _WaitParamsEditor(params: p, onChanged: onChanged),
      MaOscParams p => _MaOscParamsEditor(params: p, onChanged: onChanged),
      GotoParams  p => _GotoParamsEditor(params: p, onChanged: onChanged),
      _             => _Section(
          title: 'TYP',
          children: [
            Text(
              params.runtimeType.toString().replaceAll('Params', ''),
              style: ScText.label,
            ),
          ],
        ),
    };
  }
}

class _AudioParamsEditor extends StatelessWidget {
  final AudioParams params;
  final ValueChanged<CueParams> onChanged;

  const _AudioParamsEditor({required this.params, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return _Section(title: 'AUDIO', children: [
      ScInlineField(
        label: 'Asset-ID',
        value: params.assetId,
        readOnly: true, // set via media picker in Phase 5+
        tooltip: 'SHA-256 des Audio-Assets',
      ),
      const SizedBox(height: 6),
      ScInlineField(
        label: 'Volume',
        value: params.volumeDb.toStringAsFixed(1),
        suffix: 'dB',
        keyboardType: TextInputType.numberWithOptions(signed: true, decimal: true),
        onChanged: (v) => onChanged(params.copyWith(
          volumeDb: double.tryParse(v) ?? params.volumeDb,
        )),
      ),
      const SizedBox(height: 6),
      ScInlineField(
        label: 'Fade In',
        value: params.fadeInMs.toStringAsFixed(0),
        suffix: 'ms',
        keyboardType: TextInputType.number,
        onChanged: (v) => onChanged(params.copyWith(
          fadeInMs: double.tryParse(v) ?? params.fadeInMs,
        )),
      ),
      const SizedBox(height: 6),
      ScInlineField(
        label: 'Fade Out',
        value: params.fadeOutMs.toStringAsFixed(0),
        suffix: 'ms',
        keyboardType: TextInputType.number,
        onChanged: (v) => onChanged(params.copyWith(
          fadeOutMs: double.tryParse(v) ?? params.fadeOutMs,
        )),
      ),
      const SizedBox(height: 6),
      ScInlineField(
        label: 'Start',
        value: params.startTimeMs.toStringAsFixed(0),
        suffix: 'ms',
        keyboardType: TextInputType.number,
        onChanged: (v) => onChanged(params.copyWith(
          startTimeMs: double.tryParse(v) ?? params.startTimeMs,
        )),
      ),
      const SizedBox(height: 6),
      ScInlineField(
        label: 'End',
        value: params.endTimeMs.toStringAsFixed(0),
        suffix: 'ms',
        keyboardType: TextInputType.number,
        onChanged: (v) => onChanged(params.copyWith(
          endTimeMs: double.tryParse(v) ?? params.endTimeMs,
        )),
      ),
      const SizedBox(height: 6),
      _BoolField(
        label: 'Loop',
        value: params.loop,
        onChanged: (v) => onChanged(params.copyWith(loop: v)),
      ),
      const SizedBox(height: 8),
      AudioCueMinibar(params: params),
    ]);
  }
}

class _WaitParamsEditor extends StatelessWidget {
  final WaitParams params;
  final ValueChanged<CueParams> onChanged;

  const _WaitParamsEditor({required this.params, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return _Section(title: 'WAIT', children: [
      ScInlineField(
        label: 'Dauer',
        value: params.durationMs.toStringAsFixed(0),
        suffix: 'ms',
        keyboardType: TextInputType.number,
        onChanged: (v) => onChanged(params.copyWith(
          durationMs: double.tryParse(v) ?? params.durationMs,
        )),
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

// ── Bottom Bar ─────────────────────────────────────────────────────────────────

class _BottomBar extends StatelessWidget {
  final TabController controller;
  const _BottomBar({required this.controller});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 36,
      color: ScColors.surface,
      child: Row(
        children: [
          TabBar(
            controller: controller,
            isScrollable: true,
            indicatorColor: ScColors.active,
            labelColor: ScColors.active,
            unselectedLabelColor: ScColors.textDim,
            labelStyle: ScText.labelBold,
            unselectedLabelStyle: ScText.label,
            tabAlignment: TabAlignment.start,
            tabs: const [
              Tab(text: 'PATCH'),
              Tab(text: 'MEDIA'),
            ],
          ),
          const Spacer(),
          // Clock / diagnostic info
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: _ClockInfo(),
          ),
        ],
      ),
    );
  }
}

class _ClockInfo extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Text(
      '●  Show Control',
      style: ScText.statusSmall,
    );
  }
}
