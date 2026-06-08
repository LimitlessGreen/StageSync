import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../domain/asset.dart';
import '../../../domain/cue_params.dart' show AudioParams;
import '../../../providers/media_provider.dart';
import '../../../providers/show_control_provider.dart';
import '../sc_colors.dart';
import '../sc_typography.dart';

/// Shows a dialog that lets the user pick multiple assets and creates one
/// audio cue per selected asset. Cues are inserted after [afterCueId]
/// (or appended when null).
Future<void> showBulkAddCuesDialog(
  BuildContext context,
  WidgetRef ref, {
  String? afterCueId,
}) {
  return showDialog<void>(
    context: context,
    builder: (_) => _BulkAddCuesDialog(ref: ref, afterCueId: afterCueId),
  );
}

enum _ItemStatus { pending, ok, error }

class _BulkAddCuesDialog extends StatefulWidget {
  final WidgetRef ref;
  final String? afterCueId;

  const _BulkAddCuesDialog({required this.ref, this.afterCueId});

  @override
  State<_BulkAddCuesDialog> createState() => _BulkAddCuesDialogState();
}

class _BulkAddCuesDialogState extends State<_BulkAddCuesDialog> {
  String _query = '';
  final Set<String> _selectedIds = {};

  // Progress tracking
  bool _adding = false;
  int _done = 0;
  int _total = 0;
  final Map<String, _ItemStatus> _statusMap = {};
  bool _hasErrors = false;

  List<Asset> get _audioAssets =>
      widget.ref.read(enrichedAssetsProvider).where((a) => a.audio != null).toList();

  List<Asset> get _filtered {
    final audioOnly = _audioAssets;
    if (_query.isEmpty) return audioOnly;
    final q = _query.toLowerCase();
    return audioOnly.where((a) => a.name.toLowerCase().contains(q)).toList();
  }

  Future<void> _confirm() async {
    if (_selectedIds.isEmpty) return;

    final assets = _audioAssets;
    final ordered = assets.where((a) => _selectedIds.contains(a.id)).toList();

    setState(() {
      _adding = true;
      _done = 0;
      _total = ordered.length;
      _hasErrors = false;
      for (final a in ordered) {
        _statusMap[a.id] = _ItemStatus.pending;
      }
    });

    final notifier = widget.ref.read(showControlProvider.notifier);
    String? prevId = widget.afterCueId;

    for (final asset in ordered) {
      final baseName = asset.name.contains('.')
          ? asset.name.substring(0, asset.name.lastIndexOf('.'))
          : asset.name;
      try {
        final id = await notifier.insertDomainCue(
          AudioParams(assetId: asset.id),
          afterId: prevId,
          label: baseName,
        );
        if (id != null) {
          prevId = id;
          if (mounted) setState(() { _statusMap[asset.id] = _ItemStatus.ok; _done++; });
        } else {
          if (mounted) setState(() { _statusMap[asset.id] = _ItemStatus.error; _done++; _hasErrors = true; });
        }
      } catch (_) {
        if (mounted) setState(() { _statusMap[asset.id] = _ItemStatus.error; _done++; _hasErrors = true; });
      }
    }

    if (mounted) setState(() => _adding = false);

    // Auto-close only when everything succeeded.
    if (!_hasErrors && mounted) Navigator.of(context).pop();
  }

  bool get _allFilteredSelected =>
      _filtered.isNotEmpty && _selectedIds.containsAll(_filtered.map((a) => a.id));

  void _toggleAll() {
    setState(() {
      if (_allFilteredSelected) {
        _selectedIds.removeAll(_filtered.map((a) => a.id));
      } else {
        _selectedIds.addAll(_filtered.map((a) => a.id));
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _filtered;
    final inProgress = _adding;
    final isDone = !_adding && _total > 0;

    return Dialog(
      backgroundColor: ScColors.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 520, maxHeight: 580),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ── Header ───────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      inProgress
                          ? 'ERSTELLE CUES… $_done / $_total'
                          : isDone && _hasErrors
                              ? 'ABGESCHLOSSEN MIT FEHLERN'
                              : 'CUES IN BULK HINZUFÜGEN',
                      style: TextStyle(
                        color: isDone && _hasErrors ? ScColors.error : ScColors.textPrimary,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.0,
                      ),
                    ),
                  ),
                  if (!inProgress && !isDone && _selectedIds.isNotEmpty)
                    Text(
                      '${_selectedIds.length} ausgewählt',
                      style: ScText.label.copyWith(color: ScColors.active),
                    ),
                ],
              ),
            ),

            // ── Progress bar ─────────────────────────────────────────────
            if (inProgress || isDone) ...[
              const SizedBox(height: 10),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(3),
                  child: LinearProgressIndicator(
                    value: _total > 0 ? _done / _total : null,
                    minHeight: 4,
                    backgroundColor: ScColors.divider,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      _hasErrors ? ScColors.error : ScColors.active,
                    ),
                  ),
                ),
              ),
            ],

            // ── Search (hidden during progress) ──────────────────────────
            if (!inProgress && !isDone) ...[
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                child: TextField(
                  autofocus: true,
                  style: ScText.label,
                  decoration: InputDecoration(
                    hintText: 'Suchen…',
                    hintStyle: ScText.label.copyWith(color: ScColors.textDim),
                    prefixIcon: const Icon(Icons.search, size: 16, color: ScColors.textDim),
                    prefixIconConstraints: const BoxConstraints(minWidth: 32),
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
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
              // ── Select all row ──────────────────────────────────────────
              if (filtered.isNotEmpty)
                InkWell(
                  onTap: _toggleAll,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                    child: Row(
                      children: [
                        Checkbox(
                          value: _allFilteredSelected,
                          tristate: true,
                          onChanged: (_) => _toggleAll(),
                          activeColor: ScColors.active,
                          side: const BorderSide(color: ScColors.textDim),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Alle auswählen',
                          style: ScText.label.copyWith(color: ScColors.textSecondary),
                        ),
                      ],
                    ),
                  ),
                ),
              const Divider(height: 1, color: ScColors.divider),
            ] else ...[
              const SizedBox(height: 6),
              const Divider(height: 1, color: ScColors.divider),
            ],

            // ── Asset list ────────────────────────────────────────────────
            Expanded(
              child: _buildList(filtered, inProgress, isDone),
            ),

            // ── Action bar ────────────────────────────────────────────────
            const Divider(height: 1, color: ScColors.divider),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 14),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  if (isDone && _hasErrors)
                    Expanded(
                      child: Text(
                        '${_statusMap.values.where((s) => s == _ItemStatus.error).length} Fehler — Session verbunden?',
                        style: ScText.label.copyWith(color: ScColors.error, fontSize: 10),
                      ),
                    ),
                  TextButton(
                    onPressed: inProgress ? null : () => Navigator.of(context).pop(),
                    child: Text(
                      isDone ? 'Schließen' : 'Abbrechen',
                      style: ScText.label.copyWith(color: ScColors.textSecondary),
                    ),
                  ),
                  if (!isDone) ...[
                    const SizedBox(width: 8),
                    FilledButton(
                      style: FilledButton.styleFrom(
                        backgroundColor: _selectedIds.isEmpty ? ScColors.textDim : ScColors.active,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                      ),
                      onPressed: inProgress || _selectedIds.isEmpty ? null : _confirm,
                      child: inProgress
                          ? const SizedBox(
                              width: 14,
                              height: 14,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                            )
                          : Text(
                              _selectedIds.isEmpty
                                  ? 'Cues erstellen'
                                  : '${_selectedIds.length} Cue${_selectedIds.length > 1 ? 's' : ''} erstellen',
                              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                            ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildList(List<Asset> filtered, bool inProgress, bool isDone) {
    // During/after progress: show only selected assets with status
    if (inProgress || isDone) {
      final assets = _audioAssets.where((a) => _selectedIds.contains(a.id)).toList();
      if (assets.isEmpty) {
        return Center(
          child: Text('Keine Assets ausgewählt', style: ScText.label.copyWith(color: ScColors.textDim)),
        );
      }
      return ListView.builder(
        itemCount: assets.length,
        itemBuilder: (_, i) {
          final a = assets[i];
          final status = _statusMap[a.id] ?? _ItemStatus.pending;
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
            child: Row(
              children: [
                SizedBox(
                  width: 18,
                  height: 18,
                  child: switch (status) {
                    _ItemStatus.ok      => const Icon(Icons.check_circle_outline, size: 16, color: ScColors.active),
                    _ItemStatus.error   => const Icon(Icons.error_outline, size: 16, color: ScColors.error),
                    _ItemStatus.pending => const CircularProgressIndicator(strokeWidth: 2, color: ScColors.active),
                  },
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    a.name,
                    style: ScText.label.copyWith(
                      color: switch (status) {
                        _ItemStatus.ok      => ScColors.textSecondary,
                        _ItemStatus.error   => ScColors.error,
                        _ItemStatus.pending => ScColors.textPrimary,
                      },
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          );
        },
      );
    }

    // Selection mode
    if (filtered.isEmpty) {
      return Center(
        child: Text('Keine Audio-Dateien vorhanden', style: ScText.label.copyWith(color: ScColors.textDim)),
      );
    }

    return ListView.builder(
      itemCount: filtered.length,
      itemBuilder: (_, i) {
        final a = filtered[i];
        final selected = _selectedIds.contains(a.id);
        final lufs = a.audio?.loudnessLufs;
        final info = [
          if (a.audio != null) a.audio!.channelLabel,
          if (a.audio?.sampleRateHz != null) '${a.audio!.sampleRateHz} Hz',
          if (lufs != null) '${lufs.toStringAsFixed(1)} LUFS',
        ].join(' · ');

        return InkWell(
          onTap: () => setState(() {
            if (selected) _selectedIds.remove(a.id); else _selectedIds.add(a.id);
          }),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            child: Row(
              children: [
                Checkbox(
                  value: selected,
                  onChanged: (_) => setState(() {
                    if (selected) _selectedIds.remove(a.id); else _selectedIds.add(a.id);
                  }),
                  activeColor: ScColors.active,
                  side: const BorderSide(color: ScColors.textDim),
                ),
                const Icon(Icons.audio_file, size: 16, color: ScColors.textDim),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        a.name,
                        style: ScText.label.copyWith(
                          color: selected ? ScColors.active : ScColors.textPrimary,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (info.isNotEmpty)
                        Text(
                          info,
                          style: ScText.label.copyWith(color: ScColors.textDim, fontSize: 10),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
