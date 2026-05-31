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
import '../../design_system/primitives/sc_drag_field.dart';
import '../../design_system/primitives/sc_split_view.dart';
import '../../design_system/domain_components/cue_list_row.dart';
import '../../../providers/media_provider.dart';
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
              Builder(
                builder: (btnCtx) => ScButton(
                  label: '+ CUE',
                  variant: ScButtonVariant.ghost,
                  size: ScButtonSize.compact,
                  onPressed: () async {
                    final params = await showCueTypePicker(btnCtx);
                    if (params != null) onAddCue(params);
                  },
                ),
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
          ScInlineField(
            label: 'Bus',
            value: cue.logicalOutputId ?? '',
            onChanged: (v) => notifier.upsertDomainCue(
                cue.copyWith(logicalOutputId: v.isEmpty ? null : v)),
          ),
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
          _AutoContinueRow(cue: cue, notifier: notifier),
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

const _kTargetLufs = -23.0;

class _ParamsContent extends ConsumerWidget {
  final Cue cue;
  final ShowControlNotifier notifier;
  const _ParamsContent({required this.cue, required this.notifier});

  static double _autoVolume(double lufs) =>
      (_kTargetLufs - lufs).clamp(-40.0, 40.0);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return switch (cue.params) {
      AudioParams ap => _buildAudioParams(context, ref, ap),
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
      GotoParams gp => _buildGotoParams(context, ref, gp),
      GroupParams gp => _buildGroupParams(context, ref, gp),
      _ => Text(cue.params.runtimeType.toString(), style: ScText.label),
    };
  }

  Widget _buildGotoParams(BuildContext context, WidgetRef ref, GotoParams gp) {
    final cueList = ref.watch(domainCueListProvider);
    return ScInlineField(
      label: 'Ziel',
      value: gp.targetNumber,
      onChanged: (v) {
        final matched = cueList?.cues.firstWhere(
          (c) => c.number == v,
          orElse: () => Cue(id: '', number: v, label: v, params: gp),
        );
        notifier.upsertDomainCue(
          cue.copyWith(
            params: gp.copyWith(
              targetCueId: matched?.id ?? '',
              targetNumber: v,
            ),
          ),
        );
      },
    );
  }

  Widget _buildGroupParams(BuildContext context, WidgetRef ref, GroupParams gp) {
    final cueList = ref.watch(domainCueListProvider);
    final otherCues = cueList?.cues.where((c) => c.id != cue.id).toList() ?? [];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Sequential toggle
        Row(
          children: [
            SizedBox(
              width: ScSpacing.inspectorLabelWidth,
              child: Text('Sequentiell', style: ScText.label),
            ),
            Switch(
              value: gp.sequential,
              onChanged: (v) => notifier.upsertDomainCue(
                cue.copyWith(params: gp.copyWith(sequential: v)),
              ),
              activeColor: ScColors.active,
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
          ],
        ),
        const SizedBox(height: 4),
        // Child cue list
        ...gp.childCueIds.map((id) {
          final child = cueList?.cueById(id);
          final label = child != null ? '${child.number}  ${child.label}' : id;
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 2),
            child: Row(
              children: [
                Expanded(
                  child: Text(label,
                      style: ScText.label.copyWith(color: ScColors.textSecondary),
                      overflow: TextOverflow.ellipsis),
                ),
                GestureDetector(
                  onTap: () {
                    final newIds = List<String>.from(gp.childCueIds)..remove(id);
                    notifier.upsertDomainCue(
                      cue.copyWith(params: gp.copyWith(childCueIds: newIds)),
                    );
                  },
                  child: const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 4),
                    child: Icon(Icons.close, size: 14, color: ScColors.textDim),
                  ),
                ),
              ],
            ),
          );
        }),
        const SizedBox(height: 6),
        // Add child button
        ScButton(
          label: '+ Kind-Cue',
          variant: ScButtonVariant.ghost,
          size: ScButtonSize.compact,
          onPressed: otherCues.isEmpty
              ? null
              : () async {
                  final picked = await showDialog<String>(
                    context: context,
                    builder: (ctx) => _PickChildCueDialog(
                      candidates: otherCues
                          .where((c) => !gp.childCueIds.contains(c.id))
                          .toList(),
                    ),
                  );
                  if (picked != null) {
                    final newIds = [...gp.childCueIds, picked];
                    notifier.upsertDomainCue(
                      cue.copyWith(params: gp.copyWith(childCueIds: newIds)),
                    );
                  }
                },
        ),
      ],
    );
  }

  Widget _buildAudioParams(BuildContext context, WidgetRef ref, AudioParams ap) {
    final asset     = ref.watch(assetWithReadinessProvider(ap.assetId));
    final lufs      = asset?.audio?.loudnessLufs;
    final autoVolDb = lufs != null ? _autoVolume(lufs) : null;

    // startTimeMs == 0 → Auto-Skip-Silence aktiv (Server erkennt automatisch)
    final autoSkipActive = ap.startTimeMs == 0 && ap.assetId.isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AudioCueMinibar(params: ap, asset: asset),
        const SizedBox(height: 8),
        _AudioVolumeRow(
          volumeDb: ap.volumeDb,
          fileLufs: lufs,
          autoVolDb: autoVolDb,
          onChanged: (v) => notifier.upsertDomainCue(
            cue.copyWith(params: ap.copyWith(volumeDb: v)),
          ),
        ),
        ScDragField(
          label: 'Fade In',
          value: ap.fadeInMs,
          min: 0, max: 60000, step: 10,
          suffix: 'ms', decimalPlaces: 0,
          onChanged: (v) => notifier.upsertDomainCue(
            cue.copyWith(params: ap.copyWith(fadeInMs: v)),
          ),
        ),
        ScDragField(
          label: 'Fade Out',
          value: ap.fadeOutMs,
          min: 0, max: 60000, step: 10,
          suffix: 'ms', decimalPlaces: 0,
          onChanged: (v) => notifier.upsertDomainCue(
            cue.copyWith(params: ap.copyWith(fadeOutMs: v)),
          ),
        ),
        if (ap.endTimeMs > 0)
          ScDragField(
            label: 'End',
            value: ap.endTimeMs,
            min: 0, max: 3600000, step: 10,
            suffix: 'ms', decimalPlaces: 0,
            onChanged: (v) => notifier.upsertDomainCue(
              cue.copyWith(params: ap.copyWith(endTimeMs: v)),
            ),
          ),
        const SizedBox(height: 6),

        // ── Stille überspringen ─────────────────────────────────────────────
        if (ap.assetId.isNotEmpty) ...[
          _SilenceSkipToggle(
            autoSkipActive: autoSkipActive,
            startTimeMs: ap.startTimeMs,
            onToggle: (enabled) => notifier.upsertDomainCue(
              cue.copyWith(
                params: ap.copyWith(
                  startTimeMs: enabled ? 0 : 0.001,
                ),
              ),
            ),
            onStartTimeMsChanged: (ms) => notifier.upsertDomainCue(
              cue.copyWith(params: ap.copyWith(startTimeMs: ms)),
            ),
          ),
        ],
      ],
    );
  }
}

// ── Stille-überspringen-Toggle ────────────────────────────────────────────────

/// Wiederverwendbarer Toggle für den Auto-Skip-Silence-Modus.
///
/// Wenn [autoSkipActive] → startTimeMs == 0 → Server erkennt den ersten
/// nicht-stillen Frame und verwendet ihn als Startpunkt.
/// Wenn deaktiviert → startTimeMs = 0.001ms (Sentinel) oder manueller Wert.
class _SilenceSkipToggle extends StatelessWidget {
  final bool autoSkipActive;
  final double startTimeMs;
  final ValueChanged<bool> onToggle;
  final ValueChanged<double> onStartTimeMsChanged;

  const _SilenceSkipToggle({
    required this.autoSkipActive,
    required this.startTimeMs,
    required this.onToggle,
    required this.onStartTimeMsChanged,
  });

  static String _fmtMs(double ms) {
    if (ms < 1000) return '${ms.round()}ms';
    return '${(ms / 1000).toStringAsFixed(1)}s';
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            SizedBox(
              width: ScSpacing.inspectorLabelWidth,
              child: Row(
                children: [
                  const Icon(Icons.skip_next, size: 13, color: ScColors.textSecondary),
                  const SizedBox(width: 4),
                  Flexible(child: Text('Stille skip', style: ScText.label)),
                ],
              ),
            ),
            Switch(
              value: autoSkipActive,
              onChanged: onToggle,
              activeColor: ScColors.active,
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            const SizedBox(width: 6),
            if (autoSkipActive)
              _Badge(label: 'AUTO', color: ScColors.active)
            else if (startTimeMs > 0.001)
              Text(_fmtMs(startTimeMs),
                  style: ScText.numberSmall.copyWith(color: ScColors.textSecondary)),
          ],
        ),
        // Manuelles Startzeit-Feld wenn Auto-Skip deaktiviert und ein manueller Wert gesetzt
        if (!autoSkipActive && startTimeMs > 0.001) ...[
          ScDragField(
            label: 'Startzeit',
            value: startTimeMs,
            min: 0, max: 600000, step: 10,
            suffix: 'ms', decimalPlaces: 0,
            onChanged: onStartTimeMsChanged,
          ),
        ],
      ],
    );
  }
}

class _Badge extends StatelessWidget {
  final String label;
  final Color color;
  const _Badge({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 9,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.8,
        ),
      ),
    );
  }
}

// ── Auto-Continue toggle row ──────────────────────────────────────────────────

class _AutoContinueRow extends StatelessWidget {
  final Cue cue;
  final ShowControlNotifier notifier;
  const _AutoContinueRow({required this.cue, required this.notifier});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SizedBox(
          width: ScSpacing.inspectorLabelWidth,
          child: Text('Auto-Continue', style: ScText.label),
        ),
        Switch(
          value: cue.timing.autoContinue,
          onChanged: (v) => notifier.upsertDomainCue(
            cue.copyWith(timing: cue.timing.copyWith(autoContinue: v)),
          ),
          activeColor: ScColors.active,
          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
        ),
      ],
    );
  }
}

// ── Pick-child-cue dialog ─────────────────────────────────────────────────────

class _PickChildCueDialog extends StatelessWidget {
  final List<Cue> candidates;
  const _PickChildCueDialog({required this.candidates});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: ScColors.surface,
      title: Text('Kind-Cue hinzufügen', style: ScText.label.copyWith(color: ScColors.textPrimary)),
      content: SizedBox(
        width: 280,
        child: candidates.isEmpty
            ? Text('Keine weiteren Cues verfügbar.', style: ScText.label)
            : ListView.builder(
                shrinkWrap: true,
                itemCount: candidates.length,
                itemBuilder: (_, i) {
                  final c = candidates[i];
                  return ListTile(
                    dense: true,
                    title: Text(
                      '${c.number}  ${c.label}',
                      style: ScText.label.copyWith(color: ScColors.textSecondary),
                    ),
                    onTap: () => Navigator.of(context).pop(c.id),
                  );
                },
              ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text('Abbrechen', style: ScText.label),
        ),
      ],
    );
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

// ── Audio Volume Row (dB / LUFS Toggle) ──────────────────────────────────────

/// Lautstärke-Zeile mit umschaltbarem dB- und LUFS-Slider.
/// Der LUFS-Slider ist nur verfügbar wenn [fileLufs] bekannt ist (aus Asset-Metadaten).
/// Beide Slider sind gekoppelt: LUFS = fileLufs + volumeDb.
class _AudioVolumeRow extends StatefulWidget {
  final double volumeDb;
  final double? fileLufs;
  final double? autoVolDb;
  final ValueChanged<double> onChanged;

  const _AudioVolumeRow({
    required this.volumeDb,
    required this.onChanged,
    this.fileLufs,
    this.autoVolDb,
  });

  @override
  State<_AudioVolumeRow> createState() => _AudioVolumeRowState();
}

class _AudioVolumeRowState extends State<_AudioVolumeRow> {
  bool _showLufs = false;

  static const _kMinDb   = -40.0;
  static const _kMaxDb   = 40.0;
  static const _kTargetL = _kTargetLufs; // -23 LUFS (EBU R128)

  double get _effectiveLufs => (widget.fileLufs ?? 0.0) + widget.volumeDb;
  double get _lufsMin => (widget.fileLufs ?? 0.0) + _kMinDb;
  double get _lufsMax => (widget.fileLufs ?? 0.0) + _kMaxDb;

  bool get _canShowLufs => widget.fileLufs != null;
  bool get _isEbuNormed =>
      widget.autoVolDb != null && (widget.volumeDb - widget.autoVolDb!).abs() < 0.05;

  void _onDbChanged(double db) => widget.onChanged(db);

  void _onLufsChanged(double lufs) {
    final db = (lufs - (widget.fileLufs ?? 0.0)).clamp(_kMinDb, _kMaxDb);
    widget.onChanged(db);
  }

  void _onEbuTap() {
    if (widget.autoVolDb != null) {
      widget.onChanged(widget.autoVolDb!);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        // ── Slider (dB oder LUFS) ───────────────────────────────────────────
        Expanded(
          child: _showLufs && _canShowLufs
              ? ScDragField(
                  label: 'Lautstärke',
                  value: _effectiveLufs,
                  min: _lufsMin,
                  max: _lufsMax,
                  step: 0.1,
                  suffix: 'LUFS',
                  decimalPlaces: 1,
                  onChanged: _onLufsChanged,
                )
              : ScDragField(
                  label: 'Lautstärke',
                  value: widget.volumeDb,
                  min: _kMinDb,
                  max: _kMaxDb,
                  step: 0.2,
                  suffix: 'dB',
                  decimalPlaces: 1,
                  onChanged: _onDbChanged,
                ),
        ),

        // ── dB / LUFS Toggle ────────────────────────────────────────────────
        if (_canShowLufs) ...[
          const SizedBox(width: 6),
          Tooltip(
            message: _showLufs ? 'Auf dB umschalten' : 'Auf LUFS umschalten',
            child: GestureDetector(
              onTap: () => setState(() => _showLufs = !_showLufs),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                decoration: BoxDecoration(
                  color: _showLufs
                      ? ScColors.active.withValues(alpha: 0.15)
                      : Colors.transparent,
                  border: Border.all(
                    color: _showLufs ? ScColors.active : ScColors.textDim,
                  ),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  _showLufs ? 'LUFS' : 'dB',
                  style: ScText.label.copyWith(
                    color: _showLufs ? ScColors.active : ScColors.textDim,
                    fontSize: 9,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ),
        ],

        // ── EBU R128 Button ─────────────────────────────────────────────────
        if (widget.autoVolDb != null) ...[
          const SizedBox(width: 6),
          Tooltip(
            message: _isEbuNormed
                ? 'Normiert auf $_kTargetL LUFS (EBU R128)'
                : 'Auf EBU R128 normieren (${widget.autoVolDb!.toStringAsFixed(1)} dB)',
            child: GestureDetector(
              onTap: _isEbuNormed ? null : _onEbuTap,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                decoration: BoxDecoration(
                  color: _isEbuNormed
                      ? ScColors.active.withValues(alpha: 0.15)
                      : Colors.transparent,
                  border: Border.all(
                    color: _isEbuNormed ? ScColors.active : ScColors.textDim,
                  ),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  'EBU',
                  style: ScText.label.copyWith(
                    color: _isEbuNormed ? ScColors.active : ScColors.textDim,
                    fontSize: 9,
                    fontWeight: _isEbuNormed ? FontWeight.w800 : FontWeight.w700,
                  ),
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }
}
