import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../domain/show.dart';
import '../../../domain/cue_params.dart';
import '../../../domain/playhead.dart';
import '../../../providers/show_control_provider.dart';
import '../../../providers/show_control_domain_provider.dart';
import '../../design_system/sc_colors.dart';
import '../../design_system/sc_spacing.dart';
import '../../design_system/sc_typography.dart';
import '../../design_system/primitives/sc_button.dart';
import '../../design_system/primitives/sc_inline_field.dart';
import '../../design_system/primitives/sc_split_view.dart';
import '../../design_system/domain_components/cue_list_row.dart';
import '../../design_system/domain_components/audio_cue_minibar.dart';
import '../../design_system/domain_components/cue_type_picker.dart';

/// Standalone CueList-Editor + Inspector screen.
///
/// Suitable as a full-screen desktop editor or as an embedded tab.
/// Uses [ScSplitView] with persisted divider position.
class CueEditorScreen extends ConsumerStatefulWidget {
  const CueEditorScreen({super.key});

  @override
  ConsumerState<CueEditorScreen> createState() => _CueEditorScreenState();
}

class _CueEditorScreenState extends ConsumerState<CueEditorScreen> {
  String? _selectedCueId;

  @override
  Widget build(BuildContext context) {
    final domain   = ref.watch(showControlDomainProvider);
    final notifier = ref.read(showControlProvider.notifier);
    final cueList  = domain.cueList;
    final playhead = domain.playhead;

    return ScSplitView(
      persistKey: 'editor.main',
      initialFraction: 0.38,
      left: _CueListPane(
        cueList:       cueList,
        playhead:      playhead,
        selectedCueId: _selectedCueId,
        onSelected:    (id) => setState(() => _selectedCueId = id),
        onDelete:      notifier.deleteCueById,
        onAddCue:      (params) => notifier.addCue(params: params),
      ),
      right: _InspectorPane(
        cue:      cueList?.cueById(_selectedCueId ?? ''),
        notifier: notifier,
      ),
    );
  }
}

// ── Cue list pane ─────────────────────────────────────────────────────────────

class _CueListPane extends StatelessWidget {
  final CueList? cueList;
  final PlayheadState playhead;
  final String? selectedCueId;
  final ValueChanged<String?> onSelected;
  final ValueChanged<String> onDelete;
  final ValueChanged<CueParams> onAddCue;

  const _CueListPane({
    required this.cueList,
    required this.playhead,
    required this.selectedCueId,
    required this.onSelected,
    required this.onDelete,
    required this.onAddCue,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Toolbar
        Container(
          height: 36,
          color: ScColors.surface,
          padding: const EdgeInsets.symmetric(horizontal: ScSpacing.panelPad),
          child: Row(
            children: [
              Text('CUE LIST', style: ScText.panelTitle),
              const Spacer(),
              ScButton(
                label: '+ CUE',
                variant: ScButtonVariant.ghost,
                size: ScButtonSize.compact,
                onPressed: () async {
                  final box = context.findRenderObject() as RenderBox?;
                  if (box == null) return;
                  final pos = box.localToGlobal(Offset(box.size.width, box.size.height));
                  final params = await showCueTypePicker(context, pos);
                  if (params != null) onAddCue(params);
                },
              ),
            ],
          ),
        ),
        const Divider(height: 1, color: ScColors.divider),
        // List
        Expanded(child: _buildList()),
      ],
    );
  }

  Widget _buildList() {
    final list = cueList;
    if (list == null || list.cues.isEmpty) {
      return Center(
        child: Text('Keine Cues', style: ScText.label.copyWith(color: ScColors.textDim)),
      );
    }
    return ListView.builder(
      itemCount: list.cues.length,
      itemBuilder: (_, i) {
        final cue     = list.cues[i];
        final activeIdx = list.cues.indexWhere((c) => c.id == playhead.activeCueId);
        final isPast  = activeIdx >= 0 && i < activeIdx;
        return CueListRow(
          cue:        cue,
          isActive:   cue.id == playhead.activeCueId,
          isPast:     isPast,
          isSelected: cue.id == selectedCueId,
          onTap:      () => onSelected(cue.id),
          onDelete:   () => onDelete(cue.id),
        );
      },
    );
  }
}

// ── Inspector pane ────────────────────────────────────────────────────────────

class _InspectorPane extends StatelessWidget {
  final Cue? cue;
  final ShowControlNotifier notifier;
  const _InspectorPane({required this.cue, required this.notifier});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          height: 36,
          color: ScColors.surface,
          padding: const EdgeInsets.symmetric(horizontal: ScSpacing.panelPad),
          child: Align(alignment: Alignment.centerLeft, child: Text('INSPECTOR', style: ScText.panelTitle)),
        ),
        const Divider(height: 1, color: ScColors.divider),
        Expanded(
          child: cue == null
              ? Center(
                  child: Text(
                    'Cue auswählen',
                    style: ScText.label.copyWith(color: ScColors.textDim),
                  ),
                )
              : _InspectorContent(cue: cue!, notifier: notifier),
        ),
      ],
    );
  }
}

class _InspectorContent extends StatelessWidget {
  final Cue cue;
  final ShowControlNotifier notifier;
  const _InspectorContent({required this.cue, required this.notifier});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(ScSpacing.panelPad),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ScInlineField(
            label: 'Nr.',
            value: cue.number,
            onChanged: (v) => notifier.upsertDomainCue(cue.copyWith(number: v)),
          ),
          ScInlineField(
            label: 'Label',
            value: cue.label,
            onChanged: (v) => notifier.upsertDomainCue(cue.copyWith(label: v)),
          ),
          if (cue.logicalOutputId != null)
            ScInlineField(label: 'Bus', value: cue.logicalOutputId!),
          const SizedBox(height: 12),
          Text('TIMING', style: ScText.sectionTitle),
          const SizedBox(height: 4),
          ScInlineField(
            label: 'Pre-Wait',
            value: cue.timing.preWaitMs.toStringAsFixed(0),
            suffix: 'ms',
            keyboardType: TextInputType.number,
            onChanged: (v) {
              final ms = double.tryParse(v);
              if (ms != null) {
                notifier.upsertDomainCue(
                    cue.copyWith(timing: cue.timing.copyWith(preWaitMs: ms)));
              }
            },
          ),
          ScInlineField(
            label: 'Post-Wait',
            value: cue.timing.postWaitMs.toStringAsFixed(0),
            suffix: 'ms',
            keyboardType: TextInputType.number,
            onChanged: (v) {
              final ms = double.tryParse(v);
              if (ms != null) {
                notifier.upsertDomainCue(
                    cue.copyWith(timing: cue.timing.copyWith(postWaitMs: ms)));
              }
            },
          ),
          const SizedBox(height: 12),
          Text('PARAMETER', style: ScText.sectionTitle),
          const SizedBox(height: 4),
          _EditorCueTypeSwitcher(
            current: cue.params,
            onSwitch: (p) => notifier.upsertDomainCue(cue.copyWith(params: p)),
          ),
          const SizedBox(height: 8),
          _ParamsContent(cue: cue, notifier: notifier),
        ],
      ),
    );
  }
}

class _ParamsContent extends StatelessWidget {
  final Cue cue;
  final ShowControlNotifier notifier;
  const _ParamsContent({required this.cue, required this.notifier});

  @override
  Widget build(BuildContext context) {
    return switch (cue.params) {
      AudioParams ap => Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AudioCueMinibar(params: ap, knownDurationMs: cue.displayDurationMs),
            const SizedBox(height: 8),
            ScInlineField(
              label: 'Lautstärke',
              value: '${ap.volumeDb.toStringAsFixed(1)} dB',
              onChanged: (v) {
                final db = double.tryParse(v.replaceAll(' dB', '').trim());
                if (db != null) {
                  notifier.upsertDomainCue(
                    cue.copyWith(params: ap.copyWith(volumeDb: db)),
                  );
                }
              },
            ),
            ScInlineField(
              label: 'Fade In',
              value: ap.fadeInMs.toStringAsFixed(0),
              suffix: 'ms',
              keyboardType: TextInputType.number,
              onChanged: (v) {
                final ms = double.tryParse(v);
                if (ms != null) {
                  notifier.upsertDomainCue(
                      cue.copyWith(params: ap.copyWith(fadeInMs: ms)));
                }
              },
            ),
            ScInlineField(
              label: 'Fade Out',
              value: ap.fadeOutMs.toStringAsFixed(0),
              suffix: 'ms',
              keyboardType: TextInputType.number,
              onChanged: (v) {
                final ms = double.tryParse(v);
                if (ms != null) {
                  notifier.upsertDomainCue(
                      cue.copyWith(params: ap.copyWith(fadeOutMs: ms)));
                }
              },
            ),
          ],
        ),
      WaitParams wp => ScInlineField(
          label: 'Dauer',
          value: '${wp.durationMs.toStringAsFixed(0)} ms',
        ),
      MaOscParams mp => Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ScInlineField(label: 'OSC',  value: mp.oscAddress),
            ScInlineField(label: 'Arg',  value: mp.oscArgument),
            ScInlineField(label: 'Page', value: '${mp.executorPage}'),
            ScInlineField(label: 'Exec', value: '${mp.executorNo}'),
          ],
        ),
      GotoParams gp => ScInlineField(label: 'Ziel', value: gp.targetNumber),
      GroupParams gp => Text(
          '${gp.childCueIds.length} Cues (${gp.sequential ? 'sequentiell' : 'parallel'})',
          style: ScText.label,
        ),
      _ => Text(cue.params.runtimeType.toString(), style: ScText.label),
    };
  }
}

/// Kompakte Chip-Leiste zum Wechsel des Cue-Typs (Editor-Screen-Variante).
class _EditorCueTypeSwitcher extends StatelessWidget {
  final CueParams current;
  final ValueChanged<CueParams> onSwitch;

  const _EditorCueTypeSwitcher({required this.current, required this.onSwitch});

  static const _types = [
    (icon: Icons.volume_up,            label: 'Audio', key: 'audio'),
    (icon: Icons.timer_outlined,        label: 'Wait',  key: 'wait'),
    (icon: Icons.settings_remote,       label: 'MA',    key: 'maOsc'),
    (icon: Icons.redo,                  label: 'GOTO',  key: 'goto'),
    (icon: Icons.account_tree_outlined, label: 'Group', key: 'group'),
  ];

  String get _currentKey => switch (current) {
    AudioParams() => 'audio',
    WaitParams()  => 'wait',
    MaOscParams() => 'maOsc',
    GotoParams()  => 'goto',
    GroupParams() => 'group',
    _             => '',
  };

  CueParams _defaultFor(String key) => switch (key) {
    'audio' => const AudioParams(assetId: ''),
    'wait'  => const WaitParams(durationMs: 5000),
    'maOsc' => const MaOscParams(oscAddress: '/gma2/cmd'),
    'goto'  => const GotoParams(targetCueId: ''),
    'group' => const GroupParams(childCueIds: [], sequential: false),
    _       => const AudioParams(assetId: ''),
  };

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 4,
      runSpacing: 4,
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
                  Icon(t.icon,
                      size: 12,
                      color: isSelected ? ScColors.active : ScColors.textDim),
                  const SizedBox(width: 4),
                  Text(
                    t.label,
                    style: TextStyle(
                      color: isSelected ? ScColors.active : ScColors.textDim,
                      fontSize: 10,
                      fontWeight:
                          isSelected ? FontWeight.w700 : FontWeight.normal,
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
