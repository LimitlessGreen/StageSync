import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../domain/show.dart';
import '../../../domain/cue_params.dart';
import '../../../providers/show_control_provider.dart';
import '../../../providers/media_provider.dart';
import '../sc_colors.dart';
import '../sc_typography.dart';
import '../sc_spacing.dart';
import '../primitives/sc_button.dart';
import '../primitives/sc_drag_field.dart';
import '../primitives/sc_inline_field.dart';
import 'cue_list_row.dart';

/// Shows a draggable bottom sheet with cue details.
///
/// Directly editable — changes are auto-saved with a 350 ms debounce.
/// The sheet does NOT stop audio or change any transport state by itself.
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

class _CueDetailSheet extends ConsumerStatefulWidget {
  final Cue cue;
  final ShowControlNotifier notifier;

  const _CueDetailSheet({required this.cue, required this.notifier});

  @override
  ConsumerState<_CueDetailSheet> createState() => _CueDetailSheetState();
}

class _CueDetailSheetState extends ConsumerState<_CueDetailSheet> {
  late Cue _draft;
  bool _saving = false;
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _draft = widget.cue;
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

  Future<void> _flush() async {
    if (!mounted) return;
    setState(() => _saving = true);
    await widget.notifier.upsertDomainCue(_draft);
    if (mounted) setState(() => _saving = false);
  }

  void _goToCue() {
    widget.notifier.goToCue(widget.cue.id);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final typeColor = CueListRow.typeColor(_draft.params);
    final typeIcon  = CueListRow.typeIcon(_draft.params);

    return DraggableScrollableSheet(
      initialChildSize: 0.65,
      minChildSize: 0.40,
      maxChildSize: 0.95,
      expand: false,
      builder: (_, scrollCtrl) => Container(
        decoration: const BoxDecoration(
          color: ScColors.surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
        ),
        child: Column(
          children: [
            // ── Drag handle ─────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 10),
              child: Container(
                width: 40, height: 4,
                decoration: BoxDecoration(
                  color: ScColors.divider,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),

            // ── Header ──────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(
                ScSpacing.panelPad, 0, ScSpacing.panelPad, 10,
              ),
              child: Row(
                children: [
                  Container(
                    width: 36, height: 36,
                    decoration: BoxDecoration(
                      color: typeColor.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(typeIcon, size: 18, color: typeColor),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${_draft.number}  ${_draft.label}',
                          style: ScText.cueLabelActive,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          _typeLabel(_draft.params),
                          style: ScText.statusSmall.copyWith(color: typeColor),
                        ),
                      ],
                    ),
                  ),
                  // Auto-save indicator
                  if (_saving)
                    const SizedBox(
                      width: 14, height: 14,
                      child: CircularProgressIndicator(
                        strokeWidth: 1.5, color: ScColors.active,
                      ),
                    )
                  else
                    const Icon(Icons.check, size: 14, color: ScColors.textDim),
                ],
              ),
            ),
            const Divider(height: 1, color: ScColors.divider),

            // ── Scrollable content ───────────────────────────────────────
            Expanded(
              child: ListView(
                controller: scrollCtrl,
                padding: const EdgeInsets.all(ScSpacing.panelPad),
                children: [
                  // Allgemein
                  _SheetSection(title: 'ALLGEMEIN', children: [
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
                  // Timing
                  _SheetSection(title: 'TIMING', children: [
                    ScInlineField(
                      label: 'Pre-Wait',
                      value: (_draft.timing.preWaitMs / 1000).toStringAsFixed(2),
                      suffix: 's',
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      onChanged: (v) => _update(_draft.copyWith(
                        timing: _draft.timing.copyWith(
                          preWaitMs: (double.tryParse(v) ?? _draft.timing.preWaitMs / 1000) * 1000,
                        ),
                      )),
                    ),
                    const SizedBox(height: 6),
                    ScInlineField(
                      label: 'Post-Wait',
                      value: (_draft.timing.postWaitMs / 1000).toStringAsFixed(2),
                      suffix: 's',
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      onChanged: (v) => _update(_draft.copyWith(
                        timing: _draft.timing.copyWith(
                          postWaitMs: (double.tryParse(v) ?? _draft.timing.postWaitMs / 1000) * 1000,
                        ),
                      )),
                    ),
                    const SizedBox(height: 6),
                    _BoolRow(
                      label: 'Auto-Continue',
                      value: _draft.timing.autoContinue,
                      onChanged: (v) => _update(_draft.copyWith(
                        timing: _draft.timing.copyWith(autoContinue: v),
                      )),
                    ),
                  ]),
                  const SizedBox(height: 12),
                  // Type-specific
                  _paramsSection(_draft.params),
                ],
              ),
            ),

            // ── Bottom action bar ────────────────────────────────────────
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                  ScSpacing.panelPad, 8, ScSpacing.panelPad, 12,
                ),
                child: SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ScButton(
                    label: 'ZU DIESEM CUE',
                    variant: ScButtonVariant.primary,
                    size: ScButtonSize.normal,
                    onPressed: _goToCue,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _paramsSection(CueParams params) {
    return switch (params) {
      AudioParams p => _AudioSection(
          params: p,
          onChanged: (updated) => _update(_draft.copyWith(params: updated)),
        ),
      WaitParams p => _SheetSection(title: 'WAIT', children: [
          ScDragField(
            label: 'Dauer',
            value: p.durationMs,
            min: 0, max: 3600000, step: 50,
            suffix: 'ms', decimalPlaces: 0,
            onChanged: (v) => _update(_draft.copyWith(params: p.copyWith(durationMs: v))),
          ),
        ]),
      MaOscParams p => _SheetSection(title: 'GRANDMA OSC', children: [
          ScInlineField(
            label: 'Adresse',
            value: p.oscAddress,
            onChanged: (v) => _update(_draft.copyWith(params: p.copyWith(oscAddress: v))),
          ),
          const SizedBox(height: 6),
          ScInlineField(
            label: 'Argument',
            value: p.oscArgument,
            onChanged: (v) => _update(_draft.copyWith(params: p.copyWith(oscArgument: v))),
          ),
        ]),
      NoteParams p => _SheetSection(title: 'NOTIZ', children: [
          _NoteContent(params: p),
        ]),
      GotoParams p => _SheetSection(title: 'GOTO', children: [
          _InfoRow(icon: Icons.redo, label: 'Ziel', value: p.targetNumber.isEmpty ? p.targetCueId : p.targetNumber),
        ]),
      FadeParams p => _SheetSection(title: 'FADE', children: [
          _InfoRow(icon: Icons.tune, label: 'Aktion', value: p.action.name),
          const SizedBox(height: 4),
          ScDragField(
            label: 'Dauer',
            value: p.durationMs,
            min: 0, max: 30000, step: 100,
            suffix: 'ms', decimalPlaces: 0,
            onChanged: (v) => _update(_draft.copyWith(params: p.copyWith(durationMs: v))),
          ),
        ]),
      _ => const SizedBox.shrink(),
    };
  }

  static String _typeLabel(CueParams p) => switch (p) {
    AudioParams()  => 'Audio',
    WaitParams()   => 'Wait',
    MaOscParams()  => 'GrandMA OSC',
    GotoParams()   => 'GOTO',
    GroupParams()  => 'Gruppe',
    NoteParams()   => 'Notiz',
    FadeParams()   => 'Fade',
    _              => 'Cue',
  };
}

// ── Audio-specific section ─────────────────────────────────────────────────────

class _AudioSection extends ConsumerWidget {
  final AudioParams params;
  final ValueChanged<AudioParams> onChanged;

  const _AudioSection({required this.params, required this.onChanged});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asset = ref.watch(assetWithReadinessProvider(params.assetId));

    return _SheetSection(title: 'AUDIO', children: [
      if (asset != null) ...[
        _InfoRow(icon: Icons.audio_file_outlined, label: 'Asset', value: asset.name),
        if (asset.audio != null) ...[
          const SizedBox(height: 4),
          _InfoRow(
            icon: Icons.bar_chart,
            label: 'Lautheit',
            value: asset.audio!.loudnessLufs != null
                ? '${asset.audio!.loudnessLufs!.toStringAsFixed(1)} LUFS'
                : '—',
          ),
        ],
        const SizedBox(height: 8),
      ],
      ScDragField(
        label: 'Volume',
        value: params.volumeDb,
        min: -40, max: 20, step: 0.2,
        suffix: 'dB', decimalPlaces: 1,
        onChanged: (v) => onChanged(params.copyWith(volumeDb: v)),
      ),
      const SizedBox(height: 6),
      ScDragField(
        label: 'Fade In',
        value: params.fadeInMs,
        min: 0, max: 60000, step: 50,
        suffix: 'ms', decimalPlaces: 0,
        onChanged: (v) => onChanged(params.copyWith(fadeInMs: v)),
      ),
      const SizedBox(height: 6),
      ScDragField(
        label: 'Fade Out',
        value: params.fadeOutMs,
        min: 0, max: 60000, step: 50,
        suffix: 'ms', decimalPlaces: 0,
        onChanged: (v) => onChanged(params.copyWith(fadeOutMs: v)),
      ),
      if (params.loop) ...[
        const SizedBox(height: 4),
        _InfoRow(icon: Icons.loop, label: 'Loop', value: 'AN', valueColor: ScColors.active),
      ],
    ]);
  }
}

// ── Subwidgets ────────────────────────────────────────────────────────────────

class _SheetSection extends StatelessWidget {
  final String title;
  final List<Widget> children;
  const _SheetSection({required this.title, required this.children});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: ScText.panelTitle),
        const SizedBox(height: 8),
        ...children,
      ],
    );
  }
}

class _BoolRow extends StatelessWidget {
  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;
  const _BoolRow({required this.label, required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SizedBox(
          width: ScSpacing.inspectorLabelWidth,
          child: Text(label, style: ScText.label),
        ),
        Switch(
          value: value,
          onChanged: onChanged,
          activeThumbColor: ScColors.active,
          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
        ),
      ],
    );
  }
}

class _NoteContent extends StatelessWidget {
  final NoteParams params;
  const _NoteContent({required this.params});

  @override
  Widget build(BuildContext context) {
    final color = params.color ?? ScColors.textSecondary;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(
        params.text.isEmpty ? '(Keine Notiz)' : params.text,
        style: ScText.cueLabel.copyWith(
          color: params.text.isEmpty ? ScColors.textDim : color,
          fontStyle: params.text.isEmpty ? FontStyle.italic : FontStyle.normal,
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color? valueColor;

  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 13, color: ScColors.textDim),
        const SizedBox(width: 6),
        SizedBox(
          width: 70,
          child: Text(label, style: ScText.statusSmall),
        ),
        Expanded(
          child: Text(
            value,
            style: ScText.label.copyWith(
              color: valueColor ?? ScColors.textPrimary,
              fontWeight: FontWeight.w500,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}
