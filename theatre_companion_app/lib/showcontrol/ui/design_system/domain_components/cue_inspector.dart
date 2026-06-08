import 'dart:async';
import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:crypto/crypto.dart' as crypto;
import 'package:desktop_drop/desktop_drop.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../domain/show.dart';
import '../../../domain/cue_params.dart';
import '../../../domain/asset.dart';
import '../../../providers/show_control_provider.dart';
import '../../../providers/show_control_domain_provider.dart';
import '../../../providers/audio_node_provider.dart';
import '../../../providers/media_provider.dart';
import '../../../nodes/audio_node/audio_node_service.dart';
import '../sc_colors.dart';
import '../sc_typography.dart';
import '../sc_spacing.dart';
import '../primitives/sc_panel.dart';
import '../primitives/sc_button.dart';
import '../primitives/sc_inline_field.dart';
import '../primitives/sc_drag_field.dart';
import '../primitives/sc_waveform.dart';
import '../../../providers/waveform_provider.dart';
import '../../../providers/asset_silence_provider.dart';
import 'audio_cue_minibar.dart';

/// Full cue inspector — edit label, timing, and type-specific params.
/// Auto-saves with 350ms debounce. Handles multi-device sync.
///
/// Accepts [ShowControlNotifier] rather than a provider ref to stay decoupled
/// from the shell's state. ConsumerWidgets inside use ref directly.
class CueInspector extends StatefulWidget {
  final Cue cue;
  final ShowControlNotifier notifier;

  /// Optional scroll controller — pass the DraggableScrollableSheet controller
  /// when embedding inside a bottom sheet so drag-to-resize works correctly.
  final ScrollController? scrollController;

  /// Whether to show the ScPanel title bar. Set to false when the parent
  /// already provides a header (e.g. inside a bottom sheet).
  final bool showHeader;

  const CueInspector({
    super.key,
    required this.cue,
    required this.notifier,
    this.scrollController,
    this.showHeader = true,
  });

  @override
  State<CueInspector> createState() => _CueInspectorState();
}

class _CueInspectorState extends State<CueInspector> {
  late Cue _draft;
  bool _saving = false;
  bool _dirty = false;
  Timer? _debounce;

  final Map<Type, CueParams> _paramsCache = {};

  @override
  void initState() {
    super.initState();
    _draft = widget.cue;
  }

  @override
  void didUpdateWidget(CueInspector old) {
    super.didUpdateWidget(old);
    if (old.cue.id != widget.cue.id) {
      _debounce?.cancel();
      _paramsCache.clear();
      setState(() {
        _draft = widget.cue;
        _saving = false;
        _dirty = false;
      });
    } else if (!_dirty && !_saving && _debounce?.isActive != true) {
      setState(() => _draft = widget.cue);
    }
  }

  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
  }

  void _update(Cue updated) {
    _dirty = true;
    setState(() => _draft = updated);
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 350), _flush);
  }

  String? _pendingAssetName;

  void _onAssetPicked(String assetName) {
    _pendingAssetName = assetName;
  }

  void _onParamsChanged(CueParams newParams) {
    if (newParams.runtimeType != _draft.params.runtimeType) {
      _paramsCache[_draft.params.runtimeType] = _draft.params;
      final restored = _paramsCache[newParams.runtimeType];
      _update(_draft.copyWith(params: restored ?? newParams));
    } else {
      var updated = _draft.copyWith(params: newParams);
      // Neu gewähltes Audio-Asset + Cue hat noch generisches Label → automatisch umbenennen.
      final name = _pendingAssetName;
      if (name != null &&
          newParams is AudioParams &&
          newParams.assetId.isNotEmpty &&
          (_draft.label == 'Neue Cue' || _draft.label.isEmpty)) {
        final baseName = name.contains('.')
            ? name.substring(0, name.lastIndexOf('.'))
            : name;
        updated = updated.copyWith(label: baseName);
        _pendingAssetName = null;
      }
      _update(updated);
    }
  }

  Future<void> _flush() async {
    _debounce = null;
    if (!mounted) return;
    setState(() => _saving = true);
    await widget.notifier.upsertDomainCue(_draft);
    if (mounted)
      setState(() {
        _saving = false;
        _dirty = false;
      });
  }

  @override
  Widget build(BuildContext context) {
    return ScPanel(
      title: widget.showHeader ? '${_draft.number} · ${_draft.label}' : null,
      trailing: _saving
          ? const SizedBox(
              width: 12,
              height: 12,
              child: CircularProgressIndicator(
                  strokeWidth: 1.5, color: ScColors.active),
            )
          : null,
      child: SingleChildScrollView(
        controller: widget.scrollController,
        padding: const EdgeInsets.all(ScSpacing.panelPad),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _Section(title: 'ALLGEMEIN', children: [
              ScInlineField(
                label: 'Nummer',
                value: _draft.number,
                readOnly: true,
                tooltip:
                    'Nummern werden automatisch aus der Reihenfolge vergeben.',
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
                value: (_draft.timing.preWaitMs / 1000).toStringAsFixed(2),
                suffix: 's',
                tooltip: '${_draft.timing.preWaitMs.toStringAsFixed(0)} ms',
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                onChanged: (v) => _update(_draft.copyWith(
                  timing: _draft.timing.copyWith(
                    preWaitMs:
                        (double.tryParse(v) ?? _draft.timing.preWaitMs / 1000) *
                            1000,
                  ),
                )),
              ),
              const SizedBox(height: 6),
              ScInlineField(
                label: 'Post-Wait',
                value: (_draft.timing.postWaitMs / 1000).toStringAsFixed(2),
                suffix: 's',
                tooltip: '${_draft.timing.postWaitMs.toStringAsFixed(0)} ms',
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                onChanged: (v) => _update(_draft.copyWith(
                  timing: _draft.timing.copyWith(
                    postWaitMs: (double.tryParse(v) ??
                            _draft.timing.postWaitMs / 1000) *
                        1000,
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
                onAssetPicked: _onAssetPicked),
          ],
        ),
      ),
    );
  }
}

// ── Section header ────────────────────────────────────────────────────────────

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

// ── Bool toggle field ─────────────────────────────────────────────────────────

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

// ── Generic enum dropdown ─────────────────────────────────────────────────────

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
            child: Text(label, style: ScText.label)),
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
                items: items
                    .map(
                        (e) => DropdownMenuItem(value: e.$1, child: Text(e.$2)))
                    .toList(),
                onChanged: (v) {
                  if (v != null) onChanged(v);
                },
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// ── Params section (type switcher + editor) ───────────────────────────────────

class _ParamsSection extends StatelessWidget {
  final CueParams params;
  final ValueChanged<CueParams> onChanged;
  final ValueChanged<String>? onAssetPicked;

  const _ParamsSection(
      {required this.params, required this.onChanged, this.onAssetPicked});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _CueTypeSwitcher(current: params, onSwitch: onChanged),
        const SizedBox(height: 12),
        switch (params) {
          AudioParams p => _AudioParamsEditor(
              params: p, onChanged: onChanged, onAssetPicked: onAssetPicked),
          WaitParams p => _WaitParamsEditor(params: p, onChanged: onChanged),
          MaOscParams p => _MaOscParamsEditor(params: p, onChanged: onChanged),
          GotoParams p => _GotoParamsEditor(params: p, onChanged: onChanged),
          NoteParams p => _NoteParamsEditor(params: p, onChanged: onChanged),
          FadeParams p => _FadeParamsEditor(params: p, onChanged: onChanged),
          _ => const SizedBox.shrink(),
        },
      ],
    );
  }
}

// ── Cue type switcher chips ───────────────────────────────────────────────────

class _CueTypeSwitcher extends StatelessWidget {
  final CueParams current;
  final ValueChanged<CueParams> onSwitch;

  const _CueTypeSwitcher({required this.current, required this.onSwitch});

  static const _types = [
    (icon: Icons.volume_up, label: 'Audio', key: 'audio'),
    (icon: Icons.timer_outlined, label: 'Wait', key: 'wait'),
    (icon: Icons.tune, label: 'Fade', key: 'fade'),
    (icon: Icons.settings_remote, label: 'MA', key: 'maOsc'),
    (icon: Icons.redo, label: 'GOTO', key: 'goto'),
    (icon: Icons.account_tree_outlined, label: 'Group', key: 'group'),
    (icon: Icons.text_fields, label: 'Note', key: 'note'),
  ];

  String get _currentKey => switch (current) {
        AudioParams() => 'audio',
        WaitParams() => 'wait',
        MaOscParams() => 'maOsc',
        GotoParams() => 'goto',
        GroupParams() => 'group',
        NoteParams() => 'note',
        FadeParams() => 'fade',
        _ => '',
      };

  CueParams _defaultFor(String key) => switch (key) {
        'audio' => const AudioParams(assetId: ''),
        'wait' => const WaitParams(durationMs: 5000),
        'maOsc' => const MaOscParams(oscAddress: '/gma2/cmd'),
        'goto' => const GotoParams(targetCueId: ''),
        'group' => const GroupParams(childCueIds: [], sequential: false),
        'note' => const NoteParams(text: ''),
        'fade' => const FadeParams(),
        _ => const AudioParams(assetId: ''),
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
                    color: isSelected ? ScColors.active : ScColors.divider),
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

// ── Audio params editor ───────────────────────────────────────────────────────

const _kTargetLufs = -23.0;

class _AudioParamsEditor extends ConsumerStatefulWidget {
  final AudioParams params;
  final ValueChanged<CueParams> onChanged;
  final ValueChanged<String>? onAssetPicked;

  const _AudioParamsEditor(
      {required this.params, required this.onChanged, this.onAssetPicked});

  @override
  ConsumerState<_AudioParamsEditor> createState() => _AudioParamsEditorState();
}

class _AudioParamsEditorState extends ConsumerState<_AudioParamsEditor> {
  bool _isDragOver = false;

  static double _autoVolume(double lufs) =>
      (_kTargetLufs - lufs).clamp(-40.0, 20.0);

  AudioParams get params => widget.params;
  ValueChanged<CueParams> get onChanged => widget.onChanged;
  ValueChanged<String>? get onAssetPicked => widget.onAssetPicked;

  void _pickAsset(Asset asset, AudioParams current) {
    final lufs = asset.audio?.loudnessLufs;
    onAssetPicked?.call(asset.name);
    onChanged(current.copyWith(
      assetId: asset.id,
      volumeDb: lufs != null ? _autoVolume(lufs) : current.volumeDb,
      declaredDurationMs: asset.audio?.declaredDurationMs,
    ));
  }

  static const _audioExtensions = {
    'wav',
    'mp3',
    'flac',
    'aac',
    'ogg',
    'm4a',
    'aiff'
  };

  Future<void> _onDrop(DropDoneDetails details) async {
    setState(() => _isDragOver = false);
    final files = details.files
        .where((f) =>
            _audioExtensions.contains(f.name.split('.').last.toLowerCase()))
        .toList();
    if (files.isEmpty) return;
    final f = files.first;

    // Duplicate detection: check SHA-256 against known assets.
    final bytes = Uint8List.fromList(await File(f.path).readAsBytes());
    final hash = crypto.sha256.convert(bytes).toString();
    final existing = ref.read(mediaProvider).assetById(hash);
    if (existing != null) {
      _pickAsset(existing, params);
      return;
    }

    // Upload the file and wait for it to appear in the manifest.
    final notifier = ref.read(mediaProvider.notifier);
    await notifier.uploadFiles([(filename: f.name, bytes: bytes)]);

    // Poll until the asset appears (server confirms after analysis).
    for (var i = 0; i < 30; i++) {
      await Future.delayed(const Duration(milliseconds: 200));
      final uploaded = ref.read(mediaProvider).assetById(hash);
      if (uploaded != null) {
        _pickAsset(uploaded, params);
        return;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final audioNotifier = ref.read(audioNodeProvider.notifier);
    final isAudioConnected =
        ref.watch(audioNodeProvider).state == AudioNodeState.connected;
    final asset = ref.watch(assetWithReadinessProvider(params.assetId));
    final allAssets = ref
        .watch(enrichedAssetsProvider)
        .where((a) => a.mimeType.startsWith('audio/'))
        .toList();
    final waveformAsync = ref.watch(waveformProvider(params.assetId));

    final lufs = asset?.audio?.loudnessLufs;
    final autoVolDb = lufs != null ? _autoVolume(lufs) : null;
    final isAutoVol =
        autoVolDb != null && (params.volumeDb - autoVolDb).abs() < 0.05;

    // Duration for dynamic max values — prefer live waveform data, fall back
    // to declared duration stored in params, then a generous default.
    final wfDurMs = waveformAsync.valueOrNull?.durationMs;
    final durMs = (wfDurMs != null && wfDurMs > 0)
        ? wfDurMs
        : (params.declaredDurationMs ?? 120000.0);
    final fadeMax = durMs;
    final seekMax = durMs;
    final pauseFadeMax = (durMs / 4).clamp(500.0, 10000.0);

    final audioSection = _Section(title: 'AUDIO', children: [
      if (asset != null) _AssetReadinessBadge(asset: asset),
      if (asset != null) const SizedBox(height: 6),
      _AssetPicker(
        current: asset,
        allAssets: allAssets,
        onPick: (a) => _pickAsset(a, params),
        onClear: () => onChanged(params.copyWith(assetId: '')),
      ),
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
          value:
              '${asset!.audio!.channelLabel}  ${asset.audio!.sampleRateHz} Hz  ${asset.audio!.codec.toUpperCase()}',
          readOnly: true,
        ),
      ],
      const SizedBox(height: 6),
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
                child: Text('EBU',
                    style: ScText.label.copyWith(
                        color: ScColors.active,
                        fontSize: 9,
                        fontWeight: FontWeight.w800)),
              ),
            ),
          ] else if (autoVolDb != null) ...[
            const SizedBox(width: 6),
            Tooltip(
              message:
                  'Auf EBU R128 normieren (${autoVolDb.toStringAsFixed(1)} dB)',
              child: GestureDetector(
                onTap: () => onChanged(params.copyWith(volumeDb: autoVolDb)),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                  decoration: BoxDecoration(
                      border: Border.all(color: ScColors.textDim),
                      borderRadius: BorderRadius.circular(4)),
                  child: Text('EBU',
                      style: ScText.label.copyWith(
                          color: ScColors.textDim,
                          fontSize: 9,
                          fontWeight: FontWeight.w700)),
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
          max: fadeMax,
          step: 10,
          suffix: 'ms',
          decimalPlaces: 0,
          onChanged: (v) => onChanged(params.copyWith(fadeInMs: v))),
      const SizedBox(height: 6),
      ScDragField(
          label: 'Fade Out',
          value: params.fadeOutMs,
          min: 0,
          max: fadeMax,
          step: 10,
          suffix: 'ms',
          decimalPlaces: 0,
          onChanged: (v) => onChanged(params.copyWith(fadeOutMs: v))),
      const SizedBox(height: 6),
      _SilenceSkipField(
        startTimeMs: params.startTimeMs,
        assetId: params.assetId,
        maxMs: seekMax,
        onChanged: (v) => onChanged(params.copyWith(startTimeMs: v)),
      ),
      const SizedBox(height: 6),
      ScDragField(
          label: 'End',
          value: params.endTimeMs,
          min: 0,
          max: seekMax,
          step: 10,
          suffix: 'ms',
          decimalPlaces: 0,
          onChanged: (v) => onChanged(params.copyWith(endTimeMs: v))),
      const SizedBox(height: 6),
      _BoolField(
          label: 'Loop',
          value: params.loop,
          onChanged: (v) => onChanged(params.copyWith(loop: v))),
      const SizedBox(height: 12),
      // ── Waveform ─────────────────────────────────────────────────────────
      if (params.assetId.isNotEmpty)
        _WaveformSection(
          params: params,
          durMs: durMs,
          waveformAsync: waveformAsync,
          onChanged: onChanged,
        ),
      const SizedBox(height: 8),
      _Section(title: 'PAUSE / RESUME', children: [
        _EnumField<PauseBehavior>(
          label: 'Bei Pause',
          value: params.pauseBehavior,
          items: const [
            (PauseBehavior.hard, 'Hart (sofort)'),
            (PauseBehavior.fadeOut, 'Ausblenden')
          ],
          onChanged: (v) => onChanged(params.copyWith(pauseBehavior: v)),
        ),
        if (params.pauseBehavior == PauseBehavior.fadeOut) ...[
          const SizedBox(height: 6),
          ScDragField(
              label: 'Pause-Fade',
              value: params.pauseFadeMs,
              min: 0,
              max: pauseFadeMax,
              step: 50,
              suffix: 'ms',
              decimalPlaces: 0,
              onChanged: (v) => onChanged(params.copyWith(pauseFadeMs: v))),
        ],
        const SizedBox(height: 6),
        _EnumField<ResumeBehavior>(
          label: 'Fortsetzen',
          value: params.resumeBehavior,
          items: const [
            (ResumeBehavior.continuePlaying, 'Nahtlos weiter'),
            (ResumeBehavior.fadeIn, 'Einblenden'),
            (ResumeBehavior.fromStart, 'Von vorne'),
          ],
          onChanged: (v) => onChanged(params.copyWith(resumeBehavior: v)),
        ),
        if (params.resumeBehavior == ResumeBehavior.fadeIn) ...[
          const SizedBox(height: 6),
          ScDragField(
              label: 'Resume-Fade',
              value: params.resumeFadeMs,
              min: 0,
              max: pauseFadeMax,
              step: 50,
              suffix: 'ms',
              decimalPlaces: 0,
              onChanged: (v) => onChanged(params.copyWith(resumeFadeMs: v))),
        ],
      ]),
      const SizedBox(height: 8),
      AudioCueMinibar(params: params, asset: asset),
      const SizedBox(height: 8),
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
              onPressed:
                  isAudioConnected && params.assetId.isNotEmpty && asset != null
                      ? () => audioNotifier.auditionPlay(
                          assetId: asset.name,
                          volumeDb: params.volumeDb,
                          startMs: params.startTimeMs)
                      : null,
            ),
          ),
          const SizedBox(width: 8),
          ScButton(
            label: 'Stopp',
            icon: Icons.stop,
            variant: ScButtonVariant.ghost,
            size: ScButtonSize.compact,
            onPressed:
                isAudioConnected ? () => audioNotifier.auditionStop() : null,
          ),
        ],
      ),
    ]);

    return DropTarget(
      onDragEntered: (_) => setState(() => _isDragOver = true),
      onDragExited: (_) => setState(() => _isDragOver = false),
      onDragDone: _onDrop,
      child: Stack(
        children: [
          audioSection,
          if (_isDragOver)
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  color: ScColors.active.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: ScColors.active, width: 1.5),
                ),
                child: const Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.audio_file, size: 28, color: ScColors.active),
                      SizedBox(height: 6),
                      Text(
                        'Audio-Datei ablegen',
                        style: TextStyle(
                            color: ScColors.active,
                            fontSize: 12,
                            fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// ── Asset picker ──────────────────────────────────────────────────────────────

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

  void _open(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => _AssetSearchDialog(
        allAssets: allAssets,
        current: current,
        onPick: (a) {
          Navigator.of(ctx).pop();
          onPick(a);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: GestureDetector(
            onTap: () => _open(context),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 7),
              decoration: BoxDecoration(
                border: Border.all(color: ScColors.divider),
                borderRadius: BorderRadius.circular(6),
                color: ScColors.surface,
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      current?.name ?? 'Asset auswählen…',
                      style: ScText.label.copyWith(
                        color: current != null
                            ? ScColors.textPrimary
                            : ScColors.textDim,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const Icon(Icons.unfold_more,
                      size: 16, color: ScColors.textDim),
                ],
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
                child:
                    const Icon(Icons.close, size: 14, color: ScColors.textDim)),
          ),
        ],
      ],
    );
  }
}

class _AssetSearchDialog extends StatefulWidget {
  final List<Asset> allAssets;
  final Asset? current;
  final ValueChanged<Asset> onPick;

  const _AssetSearchDialog({
    required this.allAssets,
    required this.current,
    required this.onPick,
  });

  @override
  State<_AssetSearchDialog> createState() => _AssetSearchDialogState();
}

class _AssetSearchDialogState extends State<_AssetSearchDialog> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final filtered = _query.isEmpty
        ? widget.allAssets
        : widget.allAssets
            .where((a) => a.name.toLowerCase().contains(_query.toLowerCase()))
            .toList();

    return Dialog(
      backgroundColor: ScColors.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 480, maxHeight: 500),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: TextField(
                autofocus: true,
                style: ScText.label,
                decoration: InputDecoration(
                  hintText: 'Suchen…',
                  hintStyle: ScText.label.copyWith(color: ScColors.textDim),
                  prefixIcon: const Icon(Icons.search,
                      size: 16, color: ScColors.textDim),
                  prefixIconConstraints: const BoxConstraints(minWidth: 32),
                  isDense: true,
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(6),
                    borderSide: const BorderSide(color: ScColors.divider),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(6),
                    borderSide: const BorderSide(color: ScColors.divider),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(6),
                    borderSide: const BorderSide(color: ScColors.active),
                  ),
                ),
                onChanged: (v) => setState(() => _query = v),
              ),
            ),
            const Divider(height: 1, color: ScColors.divider),
            if (filtered.isEmpty)
              Padding(
                padding: const EdgeInsets.all(24),
                child: Center(
                  child: Text(
                    'Keine Ergebnisse',
                    style: ScText.label.copyWith(color: ScColors.textDim),
                  ),
                ),
              )
            else
              Flexible(
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: filtered.length,
                  itemBuilder: (_, i) {
                    final a = filtered[i];
                    final isCurrent = widget.current?.id == a.id;
                    final lufs = a.audio?.loudnessLufs;
                    final info = [
                      if (a.audio != null) a.audio!.channelLabel,
                      if (a.audio?.sampleRateHz != null)
                        '${a.audio!.sampleRateHz} Hz',
                      if (lufs != null) '${lufs.toStringAsFixed(1)} LUFS',
                    ].join(' · ');
                    return ListTile(
                      dense: true,
                      selected: isCurrent,
                      selectedColor: ScColors.active,
                      selectedTileColor:
                          ScColors.active.withValues(alpha: 0.08),
                      leading: Icon(
                        Icons.audio_file,
                        size: 16,
                        color: isCurrent ? ScColors.active : ScColors.textDim,
                      ),
                      title: Text(
                        a.name,
                        style: ScText.label.copyWith(
                          color: isCurrent
                              ? ScColors.active
                              : ScColors.textPrimary,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      subtitle: info.isNotEmpty
                          ? Text(
                              info,
                              style: ScText.label.copyWith(
                                color: ScColors.textDim,
                                fontSize: 10,
                              ),
                            )
                          : null,
                      onTap: () => widget.onPick(a),
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// ── Asset readiness badge ─────────────────────────────────────────────────────

class _AssetReadinessBadge extends StatelessWidget {
  final Asset asset;
  const _AssetReadinessBadge({required this.asset});

  @override
  Widget build(BuildContext context) {
    final (color, icon, label) = switch (asset.readiness) {
      AssetReadiness.patched => (
          ScColors.active,
          Icons.check_circle_outline,
          asset.readinessLabel
        ),
      AssetReadiness.renderable => (
          ScColors.active,
          Icons.play_circle_outline,
          asset.readinessLabel
        ),
      AssetReadiness.validated => (
          ScColors.warn,
          Icons.verified_outlined,
          asset.readinessLabel
        ),
      AssetReadiness.present => (
          ScColors.warn,
          Icons.download_done_outlined,
          asset.readinessLabel
        ),
    };
    return Row(
      children: [
        Icon(icon, size: 13, color: color),
        const SizedBox(width: 5),
        Text('${asset.name}  ·  $label',
            style: ScText.label.copyWith(color: color),
            overflow: TextOverflow.ellipsis),
      ],
    );
  }
}

// ── Wait params editor ────────────────────────────────────────────────────────

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
          onChanged: (v) => onChanged(params.copyWith(durationMs: v))),
    ]);
  }
}

// ── MA OSC params editor ──────────────────────────────────────────────────────

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
          onChanged: (v) => onChanged(params.copyWith(oscAddress: v))),
      const SizedBox(height: 6),
      ScInlineField(
          label: 'Argument',
          value: params.oscArgument,
          onChanged: (v) => onChanged(params.copyWith(oscArgument: v))),
      const SizedBox(height: 6),
      ScInlineField(
          label: 'Executor',
          value: params.executorNo.toString(),
          keyboardType: TextInputType.number,
          onChanged: (v) => onChanged(params.copyWith(
              executorNo: int.tryParse(v) ?? params.executorNo))),
      const SizedBox(height: 6),
      ScInlineField(
          label: 'Page',
          value: params.executorPage.toString(),
          keyboardType: TextInputType.number,
          onChanged: (v) => onChanged(params.copyWith(
              executorPage: int.tryParse(v) ?? params.executorPage))),
    ]);
  }
}

// ── GOTO params editor ────────────────────────────────────────────────────────

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
          tooltip: 'Cue-ID: ${params.targetCueId}'),
    ]);
  }
}

// ── Note params editor ────────────────────────────────────────────────────────

class _NoteParamsEditor extends StatefulWidget {
  final NoteParams params;
  final ValueChanged<CueParams> onChanged;
  const _NoteParamsEditor({required this.params, required this.onChanged});

  @override
  State<_NoteParamsEditor> createState() => _NoteParamsEditorState();
}

class _NoteParamsEditorState extends State<_NoteParamsEditor> {
  static const _palette = [
    null,
    Color(0xFFEF5350),
    Color(0xFFFF9800),
    Color(0xFFFFEE58),
    Color(0xFF66BB6A),
    Color(0xFF42A5F5),
    Color(0xFFAB47BC),
    Color(0xFFFFFFFF),
  ];

  @override
  Widget build(BuildContext context) {
    return _Section(title: 'NOTE', children: [
      ScInlineField(
          label: 'Text',
          value: widget.params.text,
          onChanged: (v) => widget.onChanged(widget.params.copyWith(text: v))),
      const SizedBox(height: 8),
      Row(
        children: [
          SizedBox(
              width: ScSpacing.inspectorLabelWidth,
              child: Text('GO-Verhalten', style: ScText.label)),
          const SizedBox(width: 6),
          Expanded(
            child: DropdownButtonHideUnderline(
              child: DropdownButton<bool>(
                value: widget.params.landable,
                isDense: true,
                isExpanded: true,
                dropdownColor: ScColors.surface,
                style: ScText.label.copyWith(color: ScColors.textPrimary),
                items: const [
                  DropdownMenuItem(value: false, child: Text('Überspringen')),
                  DropdownMenuItem(value: true, child: Text('Landen')),
                ],
                onChanged: (v) {
                  if (v != null)
                    widget.onChanged(widget.params.copyWith(landable: v));
                },
              ),
            ),
          ),
        ],
      ),
      const SizedBox(height: 8),
      Row(
        children: [
          SizedBox(
              width: ScSpacing.inspectorLabelWidth,
              child: Text('Farbe', style: ScText.label)),
          const SizedBox(width: 6),
          Wrap(
            spacing: 6,
            children: _palette.map((c) {
              final isSelected = c == widget.params.color ||
                  (c == null && widget.params.color == null);
              return GestureDetector(
                onTap: () => widget.onChanged(widget.params.copyWith(color: c)),
                child: Container(
                  width: 20,
                  height: 20,
                  decoration: BoxDecoration(
                    color: c ?? ScColors.textDim,
                    shape: BoxShape.circle,
                    border: Border.all(
                        color:
                            isSelected ? ScColors.active : Colors.transparent,
                        width: 2),
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

// ── Fade params editor ────────────────────────────────────────────────────────

class _FadeParamsEditor extends ConsumerWidget {
  final FadeParams params;
  final ValueChanged<CueParams> onChanged;
  const _FadeParamsEditor({required this.params, required this.onChanged});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cueList = ref.watch(domainCueListProvider);
    final cues = cueList?.cues ?? [];

    return _Section(title: 'FADE / CONTROL', children: [
      Row(
        children: [
          SizedBox(
              width: ScSpacing.inspectorLabelWidth,
              child: Text('Ziel', style: ScText.label)),
          const SizedBox(width: 6),
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              decoration: BoxDecoration(
                  color: ScColors.bg,
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: ScColors.divider)),
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
                                overflow: TextOverflow.ellipsis))),
                  ],
                  onChanged: (id) {
                    if (id == null) return;
                    final cue = cues.firstWhere((c) => c.id == id,
                        orElse: () => cues.first);
                    onChanged(params.copyWith(
                        targetCueId: id,
                        targetCueNumber: id.isEmpty ? '' : cue.number));
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
          (FadeAction.stop, 'Mit Fade stoppen'),
          (FadeAction.pause, 'Mit Fade pausieren'),
          (FadeAction.resume, 'Mit Fade fortsetzen'),
        ],
        onChanged: (v) => onChanged(params.copyWith(action: v)),
      ),
      if (params.action != FadeAction.resume) ...[
        const SizedBox(height: 6),
        ScDragField(
            label: 'Ziel-Vol.',
            value: params.targetVolumeDb,
            min: -60,
            max: 6,
            step: 0.5,
            suffix: 'dB',
            decimalPlaces: 1,
            onChanged: (v) => onChanged(params.copyWith(targetVolumeDb: v))),
      ],
      const SizedBox(height: 6),
      ScDragField(
          label: 'Dauer',
          value: params.durationMs,
          min: 0,
          max: 30000,
          step: 100,
          suffix: 'ms',
          decimalPlaces: 0,
          onChanged: (v) => onChanged(params.copyWith(durationMs: v))),
      if (params.action == FadeAction.volume) ...[
        const SizedBox(height: 6),
        _BoolField(
            label: 'Stopp danach',
            value: params.stopWhenDone,
            onChanged: (v) => onChanged(params.copyWith(stopWhenDone: v))),
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

// ── Waveform Section ──────────────────────────────────────────────────────────

class _WaveformSection extends ConsumerWidget {
  final AudioParams params;
  final double durMs;
  final AsyncValue<WaveformData> waveformAsync;
  final ValueChanged<CueParams> onChanged;

  const _WaveformSection({
    required this.params,
    required this.durMs,
    required this.waveformAsync,
    required this.onChanged,
  });

  bool get _autoSilenceActive =>
      params.startTimeMs == 0 && params.assetId.isNotEmpty;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Wenn Auto-Silence aktiv: Server-seitig erkannten Offset abfragen.
    final detectedSilenceMs = _autoSilenceActive
        ? ref.watch(assetSilenceProvider(params.assetId)).valueOrNull
        : null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('WAVEFORM', style: ScText.panelTitle),
        const SizedBox(height: 6),
        waveformAsync.when(
          loading: () => const SizedBox(
            height: 80,
            child: Center(
              child: SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                    strokeWidth: 1.5, color: ScColors.textDim),
              ),
            ),
          ),
          error: (_, __) => const SizedBox.shrink(),
          data: (wf) {
            if (wf.isEmpty) return const SizedBox.shrink();
            final dur = wf.durationMs > 0 ? wf.durationMs : durMs;

            // Effektiver Startpunkt: bei Auto-Mode den detektierten Offset nutzen,
            // sonst den manuell gesetzten Wert.
            final effectiveStartMs = _autoSilenceActive
                ? (detectedSilenceMs ?? 0.0)
                : params.startTimeMs;

            final endFraction = params.endTimeMs > 0
                ? (params.endTimeMs / dur).clamp(0.0, 1.0)
                : 1.0;

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Hinweis wenn Auto-Silence-Offset erkannt wurde
                if (_autoSilenceActive &&
                    detectedSilenceMs != null &&
                    detectedSilenceMs > 0) ...[
                  Row(
                    children: [
                      const Icon(Icons.skip_next,
                          size: 12, color: ScColors.active),
                      const SizedBox(width: 4),
                      Text(
                        'Stille erkannt: ${_fmtMs(detectedSilenceMs)}',
                        style:
                            ScText.statusSmall.copyWith(color: ScColors.active),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                ],
                SizedBox(
                  height: 90,
                  child: ScWaveform(
                    data: wf,
                    startFraction: (effectiveStartMs / dur).clamp(0.0, 1.0),
                    endFraction: endFraction,
                    fadeInFraction: (params.fadeInMs / dur).clamp(0.0, 1.0),
                    fadeOutFraction: (params.fadeOutMs / dur).clamp(0.0, 1.0),
                    // Im Auto-Mode: kein manuelles Ziehen des In-Markers
                    onSeekStart: _autoSilenceActive
                        ? null
                        : (f) =>
                            onChanged(params.copyWith(startTimeMs: f * dur)),
                    onSeekEnd: (f) => onChanged(params.copyWith(
                      endTimeMs: f >= 0.999 ? 0.0 : f * dur,
                    )),
                  ),
                ),
              ],
            );
          },
        ),
        const SizedBox(height: 4),
      ],
    );
  }

  static String _fmtMs(double ms) {
    if (ms < 1000) return '${ms.toInt()} ms';
    return '${(ms / 1000).toStringAsFixed(2)} s';
  }
}

// ── Silence-Skip Field ────────────────────────────────────────────────────────
//
// startTimeMs == 0      → Auto-Silence-Skip aktiv (Server erkennt Stille automatisch).
// startTimeMs == 0.001  → Sentinel: kein Auto-Skip, Ton startet von vorne.
// startTimeMs > 0.001   → Manueller Start-Offset.

class _SilenceSkipField extends ConsumerStatefulWidget {
  final double startTimeMs;
  final String assetId;
  final double maxMs;
  final ValueChanged<double> onChanged;

  const _SilenceSkipField({
    required this.startTimeMs,
    required this.assetId,
    required this.onChanged,
    this.maxMs = 3600000,
  });

  @override
  ConsumerState<_SilenceSkipField> createState() => _SilenceSkipFieldState();
}

class _SilenceSkipFieldState extends ConsumerState<_SilenceSkipField> {
  double _thresholdDb = -60.0;

  bool get _autoActive => widget.startTimeMs == 0;

  /// Erster Bucket-Index, dessen absoluter Pegel den linearen Schwellwert überschreitet.
  double? _estimateFromWaveform(WaveformData wf) {
    if (wf.isEmpty || wf.durationMs <= 0) return null;
    final threshold = math.pow(10.0, _thresholdDb / 20.0).toDouble();
    for (var i = 0; i < wf.buckets; i++) {
      if (wf.maxs[i].abs() > threshold) {
        return (i / wf.buckets) * wf.durationMs;
      }
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final waveformAsync = _autoActive && widget.assetId.isNotEmpty
        ? ref.watch(waveformProvider(widget.assetId))
        : null;
    final wf = waveformAsync?.valueOrNull;
    final estimated = wf != null ? _estimateFromWaveform(wf) : null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Auto/Manuell Toggle ──────────────────────────────────────────────
        Row(
          children: [
            SizedBox(
              width: ScSpacing.inspectorLabelWidth,
              child: Text('Start', style: ScText.label),
            ),
            Expanded(
              child: Row(
                children: [
                  Switch(
                    value: _autoActive,
                    onChanged: (on) => widget.onChanged(on ? 0 : 0.001),
                    activeThumbColor: ScColors.active,
                    activeTrackColor: ScColors.active.withValues(alpha: 0.3),
                    inactiveThumbColor: ScColors.textDim,
                    inactiveTrackColor: ScColors.surface2,
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  const SizedBox(width: 6),
                  if (_autoActive)
                    Tooltip(
                      message:
                          'Server erkennt und überspringt führende Stille automatisch beim Preload.',
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 5, vertical: 2),
                        decoration: BoxDecoration(
                          color: ScColors.active.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          'AUTO',
                          style: ScText.label.copyWith(
                            color: ScColors.active,
                            fontSize: 9,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    )
                  else
                    Text(
                      widget.startTimeMs > 0.001
                          ? _fmtMs(widget.startTimeMs)
                          : 'Von vorne',
                      style: ScText.label.copyWith(color: ScColors.textDim),
                    ),
                ],
              ),
            ),
          ],
        ),

        // ── Auto-Modus: Schwellwert-Slider + Vorschau ────────────────────────
        if (_autoActive) ...[
          const SizedBox(height: 6),
          Row(
            children: [
              SizedBox(
                width: ScSpacing.inspectorLabelWidth,
                child: Text('Schwelle', style: ScText.label),
              ),
              Expanded(
                child: Row(
                  children: [
                    Expanded(
                      child: SliderTheme(
                        data: SliderTheme.of(context).copyWith(
                          trackHeight: 2,
                          thumbShape: const RoundSliderThumbShape(
                              enabledThumbRadius: 6),
                          overlayShape:
                              const RoundSliderOverlayShape(overlayRadius: 12),
                          activeTrackColor: ScColors.active,
                          inactiveTrackColor: ScColors.surface2,
                          thumbColor: ScColors.active,
                          overlayColor: ScColors.active.withValues(alpha: 0.15),
                        ),
                        child: Slider(
                          value: _thresholdDb,
                          min: -80,
                          max: -20,
                          divisions: 60,
                          onChanged: (v) => setState(() => _thresholdDb = v),
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    SizedBox(
                      width: 52,
                      child: Text(
                        '${_thresholdDb.toStringAsFixed(0)} dBFS',
                        style: ScText.label.copyWith(color: ScColors.textDim),
                        textAlign: TextAlign.end,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (estimated != null) ...[
            const SizedBox(height: 4),
            Row(
              children: [
                SizedBox(width: ScSpacing.inspectorLabelWidth),
                Expanded(
                  child: Row(
                    children: [
                      Text(
                        'Ton ab ${_fmtMs(estimated)}',
                        style: ScText.label
                            .copyWith(color: ScColors.textDim, fontSize: 10),
                      ),
                      const SizedBox(width: 8),
                      GestureDetector(
                        onTap: () =>
                            widget.onChanged(estimated > 0 ? estimated : 0.001),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            border: Border.all(color: ScColors.textDim),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            'Anwenden',
                            style: ScText.label
                                .copyWith(color: ScColors.textDim, fontSize: 9),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ],

        // ── Manueller Modus: Startzeit-Slider ────────────────────────────────
        if (!_autoActive) ...[
          const SizedBox(height: 6),
          ScDragField(
            label: 'Startzeit',
            value: widget.startTimeMs > 0.001 ? widget.startTimeMs : 0,
            min: 0,
            max: widget.maxMs,
            step: 10,
            suffix: 'ms',
            decimalPlaces: 0,
            onChanged: (v) => widget.onChanged(v > 0 ? v : 0.001),
          ),
        ],
      ],
    );
  }

  static String _fmtMs(double ms) {
    if (ms < 1000) return '${ms.toInt()} ms';
    return '${(ms / 1000).toStringAsFixed(1)} s';
  }
}
