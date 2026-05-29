import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../providers/media_provider.dart';
import '../../design_system/sc_colors.dart';
import '../../design_system/sc_spacing.dart';
import '../../design_system/sc_typography.dart';
import '../../design_system/primitives/sc_button.dart';
import '../../design_system/primitives/sc_chip.dart';
import '../../../domain/asset.dart';

/// Desktop-only media manager.
/// Lists all server assets with readiness, size, codec and upload/delete actions.
class MediaManagerScreen extends ConsumerStatefulWidget {
  const MediaManagerScreen({super.key});

  @override
  ConsumerState<MediaManagerScreen> createState() => _MediaManagerScreenState();
}

class _MediaManagerScreenState extends ConsumerState<MediaManagerScreen> {
  @override
  void initState() {
    super.initState();
    // Load on first open; don't block if already loaded.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (ref.read(mediaProvider).assets.isEmpty) {
        ref.read(mediaProvider.notifier).refresh();
      }
    });
  }

  Future<void> _pickAndUpload() async {
    final result = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['wav', 'mp3', 'flac', 'aac', 'ogg', 'm4a', 'aiff'],
      allowMultiple: true,
    );
    if (result == null || result.files.isEmpty) return;

    for (final f in result.files) {
      if (f.path == null) continue;
      final bytes = await File(f.path!).readAsBytes();
      await ref.read(mediaProvider.notifier).upload(f.name, bytes);
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(mediaProvider);

    return Column(
      children: [
        // ── Toolbar ──────────────────────────────────────────────────────
        _Toolbar(
          isLoading: state.isLoading,
          isUploading: state.isUploading,
          onRefresh: () => ref.read(mediaProvider.notifier).refresh(),
          onUpload: _pickAndUpload,
        ),
        const Divider(height: 1, color: ScColors.divider),
        // ── Error banners ─────────────────────────────────────────────────
        if (state.error != null)
          _ErrorBanner(message: state.error!, type: _BannerType.error),
        if (state.uploadError != null)
          _ErrorBanner(message: state.uploadError!, type: _BannerType.warn),
        // ── Content ───────────────────────────────────────────────────────
        Expanded(
          child: state.isLoading && state.assets.isEmpty
              ? const Center(child: CircularProgressIndicator(color: ScColors.active))
              : state.assets.isEmpty
                  ? _EmptyState(onUpload: _pickAndUpload)
                  : _AssetTable(
                      assets: state.assets,
                      isUploading: state.isUploading,
                      onDelete: (name) =>
                          ref.read(mediaProvider.notifier).delete(name),
                      onAudition: (_) {/* Phase 4+: wire to audioNodeProvider */},
                    ),
        ),
      ],
    );
  }
}

// ── Toolbar ────────────────────────────────────────────────────────────────────

class _Toolbar extends StatelessWidget {
  final bool isLoading;
  final bool isUploading;
  final VoidCallback onRefresh;
  final VoidCallback onUpload;

  const _Toolbar({
    required this.isLoading,
    required this.isUploading,
    required this.onRefresh,
    required this.onUpload,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 44,
      color: ScColors.surface,
      padding: const EdgeInsets.symmetric(horizontal: ScSpacing.panelPad),
      child: Row(
        children: [
          Text('MEDIA', style: ScText.panelTitle),
          const Spacer(),
          if (isUploading) ...[
            const SizedBox(
              width: 14,
              height: 14,
              child: CircularProgressIndicator(
                  strokeWidth: 2, color: ScColors.active),
            ),
            const SizedBox(width: 8),
            Text('Uploading…', style: ScText.label),
            const SizedBox(width: 16),
          ],
          ScButton(
            label: 'Aktualisieren',
            icon: Icons.refresh,
            variant: ScButtonVariant.ghost,
            size: ScButtonSize.compact,
            onPressed: isLoading ? null : onRefresh,
          ),
          const SizedBox(width: 8),
          ScButton(
            label: 'Hochladen',
            icon: Icons.upload_file,
            variant: ScButtonVariant.secondary,
            size: ScButtonSize.compact,
            onPressed: isUploading ? null : onUpload,
          ),
        ],
      ),
    );
  }
}

// ── Asset Table ────────────────────────────────────────────────────────────────

class _AssetTable extends StatelessWidget {
  final List<Asset> assets;
  final bool isUploading;
  final ValueChanged<String> onDelete;
  final ValueChanged<Asset> onAudition;

  const _AssetTable({
    required this.assets,
    required this.isUploading,
    required this.onDelete,
    required this.onAudition,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Header row
        Container(
          height: 32,
          color: ScColors.surface,
          padding: const EdgeInsets.symmetric(horizontal: ScSpacing.panelPad),
          child: const Row(
            children: [
              _HeaderCell('NAME', flex: 4),
              _HeaderCell('FORMAT', flex: 1),
              _HeaderCell('GRÖßE', flex: 1),
              _HeaderCell('STATUS', flex: 1),
              _HeaderCell('HOCHGELADEN', flex: 2),
              SizedBox(width: 80), // actions column
            ],
          ),
        ),
        const Divider(height: 1, color: ScColors.divider),
        // Asset rows
        Expanded(
          child: ListView.separated(
            itemCount: assets.length,
            separatorBuilder: (_, __) =>
                const Divider(height: 1, color: ScColors.divider),
            itemBuilder: (context, i) => _AssetRow(
              asset: assets[i],
              onDelete: () => onDelete(assets[i].name),
              onAudition: () => onAudition(assets[i]),
            ),
          ),
        ),
        // Footer: asset count
        Container(
          height: 28,
          color: ScColors.surface,
          padding: const EdgeInsets.symmetric(horizontal: ScSpacing.panelPad),
          alignment: Alignment.centerLeft,
          child: Text(
            '${assets.length} Asset${assets.length == 1 ? "" : "s"}',
            style: ScText.statusSmall,
          ),
        ),
      ],
    );
  }
}

class _HeaderCell extends StatelessWidget {
  final String label;
  final int flex;
  const _HeaderCell(this.label, {required this.flex});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      flex: flex,
      child: Text(label, style: ScText.panelTitle),
    );
  }
}

class _AssetRow extends StatefulWidget {
  final Asset asset;
  final VoidCallback onDelete;
  final VoidCallback onAudition;

  const _AssetRow({
    required this.asset,
    required this.onDelete,
    required this.onAudition,
  });

  @override
  State<_AssetRow> createState() => _AssetRowState();
}

class _AssetRowState extends State<_AssetRow> {
  bool _hovered = false;
  bool _confirmDelete = false;

  @override
  Widget build(BuildContext context) {
    final a = widget.asset;
    final isAudio = a.mimeType.startsWith('audio/');

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() {
        _hovered = false;
        _confirmDelete = false;
      }),
      child: Container(
        height: ScSpacing.rowHeight,
        color: _hovered ? ScColors.hover : Colors.transparent,
        padding: const EdgeInsets.symmetric(horizontal: ScSpacing.panelPad),
        child: Row(
          children: [
            // Name + icon
            Expanded(
              flex: 4,
              child: Row(
                children: [
                  Icon(
                    isAudio ? Icons.audio_file : Icons.insert_drive_file,
                    size: 14,
                    color: isAudio ? Colors.blue : ScColors.textDim,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      a.name,
                      style: ScText.cueLabel.copyWith(fontSize: 12),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
            // Format / codec
            Expanded(
              flex: 1,
              child: Text(
                a.audio?.codec.toUpperCase() ?? '—',
                style: ScText.label,
              ),
            ),
            // Size
            Expanded(
              flex: 1,
              child: Text(
                _formatSize(a.sizeBytes),
                style: ScText.numberSmall,
              ),
            ),
            // Readiness status
            Expanded(
              flex: 1,
              child: _ReadinessChip(readiness: a.readiness),
            ),
            // Upload date
            Expanded(
              flex: 2,
              child: Text(
                _formatDate(a.uploadedAt),
                style: ScText.label,
              ),
            ),
            // Action buttons (visible on hover)
            SizedBox(
              width: 80,
              child: _hovered
                  ? Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        if (isAudio)
                          _IconBtn(
                            icon: Icons.headphones,
                            tooltip: 'Vorhören',
                            onTap: widget.onAudition,
                          ),
                        const SizedBox(width: 4),
                        if (!_confirmDelete)
                          _IconBtn(
                            icon: Icons.delete_outline,
                            tooltip: 'Löschen',
                            color: ScColors.error,
                            onTap: () =>
                                setState(() => _confirmDelete = true),
                          )
                        else
                          _IconBtn(
                            icon: Icons.check,
                            tooltip: 'Löschen bestätigen',
                            color: ScColors.error,
                            onTap: widget.onDelete,
                          ),
                      ],
                    )
                  : const SizedBox.shrink(),
            ),
          ],
        ),
      ),
    );
  }

  static String _formatSize(int bytes) {
    if (bytes < 1024) return '${bytes}B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(0)}KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)}MB';
  }

  static String _formatDate(DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt);
    if (diff.inDays == 0) {
      return '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
    }
    if (diff.inDays < 7) return 'vor ${diff.inDays}d';
    return '${dt.day.toString().padLeft(2, '0')}.${dt.month.toString().padLeft(2, '0')}.${dt.year}';
  }
}

class _IconBtn extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final Color color;
  final VoidCallback onTap;

  const _IconBtn({
    required this.icon,
    required this.tooltip,
    required this.onTap,
    this.color = ScColors.textSecondary,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(4),
        child: Padding(
          padding: const EdgeInsets.all(4),
          child: Icon(icon, size: 16, color: color),
        ),
      ),
    );
  }
}

// ── Readiness Chip ─────────────────────────────────────────────────────────────

class _ReadinessChip extends StatelessWidget {
  final AssetReadiness readiness;
  const _ReadinessChip({required this.readiness});

  ScChipState get _chipState => switch (readiness) {
        AssetReadiness.patched    => ScChipState.ok,
        AssetReadiness.renderable => ScChipState.warn,
        AssetReadiness.validated  => ScChipState.idle,
        AssetReadiness.present    => ScChipState.warn,
      };

  String get _label => switch (readiness) {
        AssetReadiness.patched    => 'Bereit',
        AssetReadiness.renderable => 'Abspielbar',
        AssetReadiness.validated  => 'Verifiziert',
        AssetReadiness.present    => 'Vorhanden',
      };

  String get _tooltip => switch (readiness) {
        AssetReadiness.patched =>
          'Datei vorhanden, verifiziert, abspielbar und einem Output zugeordnet.',
        AssetReadiness.renderable =>
          'Datei abspielbar, aber noch kein Output-Patch.',
        AssetReadiness.validated =>
          'Datei lokal vorhanden und SHA-256 verifiziert.',
        AssetReadiness.present =>
          'Datei lokal vorhanden, aber noch nicht verifiziert.',
      };

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: _tooltip,
      child: ScChip(label: _label, state: _chipState),
    );
  }
}

// ── Empty State ────────────────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  final VoidCallback onUpload;
  const _EmptyState({required this.onUpload});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.audio_file, size: 48, color: ScColors.textDim),
          const SizedBox(height: 16),
          Text('Keine Medien auf dem Server', style: ScText.label),
          const SizedBox(height: 8),
          Text(
            'Lade Audio-Dateien hoch um sie in Cues zu verwenden.',
            style: ScText.label.copyWith(color: ScColors.textDim),
          ),
          const SizedBox(height: 24),
          ScButton(
            label: 'Dateien hochladen',
            icon: Icons.upload_file,
            variant: ScButtonVariant.secondary,
            size: ScButtonSize.normal,
            onPressed: onUpload,
          ),
        ],
      ),
    );
  }
}

// ── Error Banner ───────────────────────────────────────────────────────────────

enum _BannerType { error, warn }

class _ErrorBanner extends StatelessWidget {
  final String message;
  final _BannerType type;
  const _ErrorBanner({required this.message, required this.type});

  @override
  Widget build(BuildContext context) {
    final color = type == _BannerType.error ? ScColors.error : ScColors.warn;
    return Container(
      width: double.infinity,
      color: color.withValues(alpha: 0.1),
      padding: const EdgeInsets.symmetric(
          horizontal: ScSpacing.panelPad, vertical: 6),
      child: Row(
        children: [
          Icon(Icons.warning_amber_rounded, size: 14, color: color),
          const SizedBox(width: 8),
          Expanded(child: Text(message, style: ScText.label.copyWith(color: color))),
        ],
      ),
    );
  }
}
