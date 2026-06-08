import 'dart:io';
import 'dart:typed_data';

import 'package:crypto/crypto.dart' as crypto;
import 'package:desktop_drop/desktop_drop.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../providers/media_provider.dart';
import '../../../providers/audio_node_provider.dart';
import '../../../providers/show_control_domain_provider.dart';
import '../../../nodes/audio_node/audio_node_service.dart';
import '../../design_system/sc_colors.dart';
import '../../design_system/sc_spacing.dart';
import '../../design_system/sc_typography.dart';
import '../../design_system/primitives/sc_button.dart';
import '../../design_system/primitives/sc_chip.dart';
import '../../design_system/primitives/sc_floating_panel.dart';
import '../../../domain/asset.dart';

enum _SortCol { name, format, loudness, size, status, uploaded }

/// Desktop-only media manager.
/// Lists all server assets with readiness, size, codec and upload/delete actions.
class MediaManagerScreen extends ConsumerStatefulWidget {
  const MediaManagerScreen({super.key});

  @override
  ConsumerState<MediaManagerScreen> createState() => _MediaManagerScreenState();
}

class _MediaManagerScreenState extends ConsumerState<MediaManagerScreen> {
  String? _auditingAssetId;
  bool _queueVisible = false;
  String _searchQuery = '';
  _SortCol _sortBy = _SortCol.name;
  bool _sortAsc = true;
  bool _isDragOver = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (ref.read(mediaProvider).assets.isEmpty) {
        ref.read(mediaProvider.notifier).refresh();
      }
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        ref.read(audioNodeProvider.notifier).ensureEngineInitialized();
      }
    });
  }

  List<Asset> _filteredSorted(List<Asset> assets) {
    var result = assets;
    if (_searchQuery.isNotEmpty) {
      final q = _searchQuery.toLowerCase();
      result = result.where((a) => a.name.toLowerCase().contains(q)).toList();
    }
    return List<Asset>.from(result)..sort(_cmp);
  }

  int _cmp(Asset a, Asset b) {
    final c = switch (_sortBy) {
      _SortCol.name => naturalCompare(a.name, b.name),
      _SortCol.format => (a.audio?.codec ?? '').compareTo(b.audio?.codec ?? ''),
      _SortCol.loudness => (a.audio?.loudnessLufs ?? double.negativeInfinity)
          .compareTo(b.audio?.loudnessLufs ?? double.negativeInfinity),
      _SortCol.size => a.sizeBytes.compareTo(b.sizeBytes),
      _SortCol.status => a.readiness.index.compareTo(b.readiness.index),
      _SortCol.uploaded => a.uploadedAt.compareTo(b.uploadedAt),
    };
    return _sortAsc ? c : -c;
  }

  void _onSort(_SortCol col) => setState(() {
        if (_sortBy == col) {
          _sortAsc = !_sortAsc;
        } else {
          _sortBy = col;
          _sortAsc = true;
        }
      });

  void _closeQueue() {
    setState(() => _queueVisible = false);
    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted) ref.read(mediaProvider.notifier).clearUploadQueue();
    });
  }

  /// Handles files dropped onto the media browser.
  /// Skips files already on the server (SHA-256 dedup check).
  Future<void> _dropFiles(DropDoneDetails details) async {
    const allowed = {'wav', 'mp3', 'flac', 'aac', 'ogg', 'm4a', 'aiff'};
    final existingIds = ref.read(mediaProvider).assets.map((a) => a.id).toSet();

    final files = <({String filename, Uint8List bytes})>[];
    for (final f in details.files) {
      final ext = f.name.split('.').last.toLowerCase();
      if (!allowed.contains(ext)) continue;
      final bytes = Uint8List.fromList(await f.readAsBytes());
      final hash = crypto.sha256.convert(bytes).toString();
      if (existingIds.contains(hash)) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text('"${f.name}" ist bereits vorhanden'),
            backgroundColor: ScColors.surface2,
            duration: const Duration(seconds: 2),
          ));
        }
        continue;
      }
      files.add((filename: f.name, bytes: bytes));
    }
    if (files.isEmpty) return;
    setState(() {
      _queueVisible = true;
      _isDragOver = false;
    });
    await ref.read(mediaProvider.notifier).uploadFiles(files);
    if (mounted) {
      Future.delayed(const Duration(seconds: 4), () {
        if (mounted) _closeQueue();
      });
    }
  }

  Future<void> _pickAndUpload() async {
    final result = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['wav', 'mp3', 'flac', 'aac', 'ogg', 'm4a', 'aiff'],
      allowMultiple: true,
    );
    if (result == null || result.files.isEmpty) return;

    final files = <({String filename, Uint8List bytes})>[];
    for (final f in result.files) {
      if (f.path == null) continue;
      final bytes = await File(f.path!).readAsBytes();
      files.add((filename: f.name, bytes: bytes));
    }
    if (files.isEmpty) return;

    setState(() => _queueVisible = true);
    await ref.read(mediaProvider.notifier).uploadFiles(files);

    // Auto-Dismiss nach 4s wenn alle fertig
    if (mounted) {
      Future.delayed(const Duration(seconds: 4), () {
        if (mounted) _closeQueue();
      });
    }
  }

  bool get _isAudioConnected {
    final isLocal =
        ref.watch(audioNodeProvider).state == AudioNodeState.connected;
    final hasOnline =
        ref.watch(nodeStatusListProvider).any((n) => n.isAudio && n.isOnline);
    return isLocal || hasOnline;
  }

  void _showUploadQueueSheet(BuildContext context, List<UploadItem> queue) {
    showModalBottomSheet(
      context: context,
      backgroundColor: ScColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
              child: Row(
                children: [
                  Expanded(
                    child: Text('UPLOADS', style: ScText.panelTitle),
                  ),
                  Text(
                    '${queue.length} Datei${queue.length == 1 ? "" : "en"}',
                    style: ScText.label.copyWith(color: ScColors.textDim),
                  ),
                ],
              ),
            ),
            const Divider(height: 1, color: ScColors.divider),
            _UploadQueueContent(queue: queue),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(mediaProvider);
    final assets = _filteredSorted(ref.watch(enrichedAssetsProvider));
    final queue = state.uploadQueue;

    return LayoutBuilder(
      builder: (context, constraints) {
        final isMobile = constraints.maxWidth < 720;
        return isMobile
            ? _buildMobile(context, state, assets, queue)
            : _buildDesktop(context, state, assets, queue);
      },
    );
  }

  Widget _buildDesktop(BuildContext context, MediaState state,
      List<Asset> assets, List<UploadItem> queue) {
    return DropTarget(
      onDragEntered: (_) => setState(() => _isDragOver = true),
      onDragExited: (_) => setState(() => _isDragOver = false),
      onDragDone: (d) {
        setState(() => _isDragOver = false);
        _dropFiles(d);
      },
      child: Stack(
        children: [
          _buildDesktopInner(context, state, assets, queue),
          if (_isDragOver)
            Container(
              color: ScColors.active.withValues(alpha: 0.12),
              child: const Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.upload_file, size: 48, color: ScColors.active),
                    SizedBox(height: 12),
                    Text(
                      'Audio-Datei hier ablegen',
                      style: TextStyle(
                          color: ScColors.active,
                          fontSize: 16,
                          fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildDesktopInner(BuildContext context, MediaState state,
      List<Asset> assets, List<UploadItem> queue) {
    return Column(
      children: [
        _Toolbar(
          isLoading: state.isLoading,
          activeUploads: queue
              .where((u) =>
                  u.status == UploadStatus.uploading ||
                  u.status == UploadStatus.pending ||
                  u.status == UploadStatus.analyzing)
              .length,
          searchQuery: _searchQuery,
          onSearchChanged: (v) => setState(() => _searchQuery = v),
          onRefresh: () => ref.read(mediaProvider.notifier).refresh(),
          onUpload: _pickAndUpload,
        ),
        const Divider(height: 1, color: ScColors.divider),
        if (state.error != null)
          _ErrorBanner(
            message: state.error!,
            type: _BannerType.error,
            onDismiss: () => ref.read(mediaProvider.notifier).clearError(),
          ),
        Expanded(
          child: Stack(
            children: [
              state.isLoading && assets.isEmpty
                  ? const Center(
                      child: CircularProgressIndicator(color: ScColors.active))
                  : assets.isEmpty
                      ? _EmptyState(onUpload: _pickAndUpload)
                      : _AssetTable(
                          assets: assets,
                          sortBy: _sortBy,
                          sortAsc: _sortAsc,
                          onSort: _onSort,
                          isAudioConnected: _isAudioConnected,
                          auditingAssetId: _auditingAssetId,
                          onDelete: (name) =>
                              ref.read(mediaProvider.notifier).delete(name),
                          onAudition: (asset) {
                            final lufs = asset.audio?.loudnessLufs;
                            final volumeDb = lufs != null
                                ? (-23.0 - lufs).clamp(-40.0, 20.0)
                                : 0.0;
                            setState(() => _auditingAssetId = asset.id);
                            ref.read(audioNodeProvider.notifier).auditionPlay(
                                  assetId: asset.id,
                                  volumeDb: volumeDb,
                                );
                          },
                          onAuditionStop: () {
                            setState(() => _auditingAssetId = null);
                            ref.read(audioNodeProvider.notifier).auditionStop();
                          },
                        ),
              Positioned(
                right: 12,
                bottom: 12,
                width: 340,
                child: ScFloatingPanel(
                  visible: _queueVisible,
                  title: 'UPLOADS',
                  subtitle:
                      '${queue.length} Datei${queue.length == 1 ? "" : "en"}',
                  onClose: _closeQueue,
                  actions: [
                    if (queue.any((u) =>
                        u.status == UploadStatus.done ||
                        u.status == UploadStatus.error))
                      _ClearDoneButton(
                        onTap: () =>
                            ref.read(mediaProvider.notifier).clearUploadQueue(),
                      ),
                  ],
                  child: _UploadQueueContent(queue: queue),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMobile(BuildContext context, MediaState state,
      List<Asset> assets, List<UploadItem> queue) {
    final activeUploads = queue
        .where((u) =>
            u.status == UploadStatus.uploading ||
            u.status == UploadStatus.pending ||
            u.status == UploadStatus.analyzing)
        .length;

    return Scaffold(
      backgroundColor: ScColors.bg,
      body: Column(
        children: [
          // ── Mobile toolbar ─────────────────────────────────────────────
          Container(
            height: 44,
            color: ScColors.surface,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    style: ScText.label,
                    decoration: InputDecoration(
                      hintText: 'Suchen…',
                      hintStyle: ScText.label.copyWith(color: ScColors.textDim),
                      prefixIcon: const Icon(Icons.search,
                          size: 16, color: ScColors.textDim),
                      prefixIconConstraints: const BoxConstraints(minWidth: 32),
                      isDense: true,
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 8),
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
                    onChanged: (v) => setState(() => _searchQuery = v),
                  ),
                ),
                const SizedBox(width: 8),
                if (activeUploads > 0)
                  IconButton(
                    icon: const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: ScColors.active),
                    ),
                    onPressed: () => _showUploadQueueSheet(context, queue),
                  )
                else
                  IconButton(
                    icon: const Icon(Icons.refresh,
                        size: 18, color: ScColors.textSecondary),
                    onPressed: state.isLoading
                        ? null
                        : () => ref.read(mediaProvider.notifier).refresh(),
                  ),
              ],
            ),
          ),
          const Divider(height: 1, color: ScColors.divider),
          if (state.error != null)
            _ErrorBanner(
              message: state.error!,
              type: _BannerType.error,
              onDismiss: () => ref.read(mediaProvider.notifier).clearError(),
            ),
          // ── Asset list ─────────────────────────────────────────────────
          Expanded(
            child: state.isLoading && assets.isEmpty
                ? const Center(
                    child: CircularProgressIndicator(color: ScColors.active))
                : assets.isEmpty
                    ? _EmptyState(onUpload: _pickAndUpload)
                    : _AssetList(
                        assets: assets,
                        isAudioConnected: _isAudioConnected,
                        auditingAssetId: _auditingAssetId,
                        onDelete: (name) =>
                            ref.read(mediaProvider.notifier).delete(name),
                        onAudition: (asset) {
                          final lufs = asset.audio?.loudnessLufs;
                          final volumeDb = lufs != null
                              ? (-23.0 - lufs).clamp(-40.0, 20.0)
                              : 0.0;
                          setState(() => _auditingAssetId = asset.id);
                          ref.read(audioNodeProvider.notifier).auditionPlay(
                                assetId: asset.id,
                                volumeDb: volumeDb,
                              );
                        },
                        onAuditionStop: () {
                          setState(() => _auditingAssetId = null);
                          ref.read(audioNodeProvider.notifier).auditionStop();
                        },
                      ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: ScColors.active,
        foregroundColor: Colors.white,
        onPressed: _pickAndUpload,
        child: const Icon(Icons.upload_file),
      ),
    );
  }
}

// ── Toolbar ────────────────────────────────────────────────────────────────────

class _Toolbar extends StatefulWidget {
  final bool isLoading;
  final int activeUploads;
  final String searchQuery;
  final ValueChanged<String> onSearchChanged;
  final VoidCallback onRefresh;
  final VoidCallback onUpload;

  const _Toolbar({
    required this.isLoading,
    required this.activeUploads,
    required this.searchQuery,
    required this.onSearchChanged,
    required this.onRefresh,
    required this.onUpload,
  });

  @override
  State<_Toolbar> createState() => _ToolbarState();
}

class _ToolbarState extends State<_Toolbar> {
  late final TextEditingController _searchCtrl =
      TextEditingController(text: widget.searchQuery);

  @override
  void didUpdateWidget(_Toolbar old) {
    super.didUpdateWidget(old);
    if (widget.searchQuery != _searchCtrl.text) {
      _searchCtrl.value = TextEditingValue(
        text: widget.searchQuery,
        selection: TextSelection.collapsed(offset: widget.searchQuery.length),
      );
    }
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 44,
      color: ScColors.surface,
      padding: const EdgeInsets.symmetric(horizontal: ScSpacing.panelPad),
      child: Row(
        children: [
          Text('MEDIA', style: ScText.panelTitle),
          const SizedBox(width: 16),
          SizedBox(
            width: 220,
            height: 28,
            child: TextField(
              controller: _searchCtrl,
              style: ScText.label,
              decoration: InputDecoration(
                hintText: 'Suchen…',
                hintStyle: ScText.label.copyWith(color: ScColors.textDim),
                prefixIcon:
                    const Icon(Icons.search, size: 14, color: ScColors.textDim),
                prefixIconConstraints: const BoxConstraints(minWidth: 28),
                suffixIcon: widget.searchQuery.isNotEmpty
                    ? GestureDetector(
                        onTap: () {
                          _searchCtrl.clear();
                          widget.onSearchChanged('');
                        },
                        child: const Icon(Icons.close,
                            size: 13, color: ScColors.textDim),
                      )
                    : null,
                isDense: true,
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(5),
                  borderSide: const BorderSide(color: ScColors.divider),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(5),
                  borderSide: const BorderSide(color: ScColors.divider),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(5),
                  borderSide: const BorderSide(color: ScColors.active),
                ),
              ),
              onChanged: widget.onSearchChanged,
            ),
          ),
          const Spacer(),
          if (widget.activeUploads > 0) ...[
            const SizedBox(
              width: 14,
              height: 14,
              child: CircularProgressIndicator(
                  strokeWidth: 2, color: ScColors.active),
            ),
            const SizedBox(width: 8),
            Text(
              widget.activeUploads == 1
                  ? '1 Upload läuft…'
                  : '${widget.activeUploads} Uploads laufen…',
              style: ScText.label,
            ),
            const SizedBox(width: 16),
          ],
          ScButton(
            label: 'Aktualisieren',
            icon: Icons.refresh,
            variant: ScButtonVariant.ghost,
            size: ScButtonSize.compact,
            onPressed: widget.isLoading ? null : widget.onRefresh,
          ),
          const SizedBox(width: 8),
          ScButton(
            label: 'Hochladen',
            icon: Icons.upload_file,
            variant: ScButtonVariant.secondary,
            size: ScButtonSize.compact,
            onPressed: widget.onUpload,
          ),
        ],
      ),
    );
  }
}

// ── Upload Queue Content ───────────────────────────────────────────────────────

class _UploadQueueContent extends StatelessWidget {
  final List<UploadItem> queue;
  const _UploadQueueContent({required this.queue});

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(maxHeight: 180),
      child: ListView.builder(
        shrinkWrap: true,
        padding: const EdgeInsets.symmetric(vertical: 4),
        itemCount: queue.length,
        itemBuilder: (_, i) => _UploadRow(item: queue[i]),
      ),
    );
  }
}

class _ClearDoneButton extends StatelessWidget {
  final VoidCallback onTap;
  const _ClearDoneButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: 'Abgeschlossene entfernen',
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(4),
        child: const Padding(
          padding: EdgeInsets.symmetric(horizontal: 6, vertical: 4),
          child: Icon(Icons.playlist_remove, size: 14, color: ScColors.textDim),
        ),
      ),
    );
  }
}

class _UploadRow extends StatelessWidget {
  final UploadItem item;
  const _UploadRow({required this.item});

  @override
  Widget build(BuildContext context) {
    final (icon, iconColor) = switch (item.status) {
      UploadStatus.done => (Icons.check_circle_outline, ScColors.active),
      UploadStatus.error => (Icons.error_outline, ScColors.error),
      UploadStatus.pending => (Icons.schedule, ScColors.textDim),
      _ => (Icons.upload, ScColors.active),
    };

    final statusText = switch (item.status) {
      UploadStatus.pending => 'Wartend',
      UploadStatus.uploading => '${(item.progress * 100).toStringAsFixed(0)}%',
      UploadStatus.analyzing => 'Analysiere…',
      UploadStatus.done => 'Fertig',
      UploadStatus.error => item.error ?? 'Fehler',
    };

    return Padding(
      padding: const EdgeInsets.symmetric(
          horizontal: ScSpacing.panelPad, vertical: 3),
      child: Row(
        children: [
          Icon(icon, size: 14, color: iconColor),
          const SizedBox(width: 8),
          Expanded(
            flex: 3,
            child: Text(
              item.filename,
              style: ScText.label,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            flex: 2,
            child: item.status == UploadStatus.uploading ||
                    item.status == UploadStatus.analyzing
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(2),
                    child: LinearProgressIndicator(
                      value: item.status == UploadStatus.analyzing
                          ? null // indeterminate während Server analysiert
                          : item.progress,
                      minHeight: 4,
                      backgroundColor: ScColors.divider,
                      valueColor:
                          const AlwaysStoppedAnimation<Color>(ScColors.active),
                    ),
                  )
                : const SizedBox.shrink(),
          ),
          const SizedBox(width: 8),
          SizedBox(
            width: 80,
            child: Text(
              statusText,
              style: ScText.statusSmall.copyWith(
                color: switch (item.status) {
                  UploadStatus.done => ScColors.active,
                  UploadStatus.error => ScColors.error,
                  _ => ScColors.textSecondary,
                },
              ),
              textAlign: TextAlign.right,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Asset List (Mobile) ────────────────────────────────────────────────────────

class _AssetList extends StatelessWidget {
  final List<Asset> assets;
  final bool isAudioConnected;
  final String? auditingAssetId;
  final ValueChanged<String> onDelete;
  final ValueChanged<Asset> onAudition;
  final VoidCallback onAuditionStop;

  const _AssetList({
    required this.assets,
    required this.isAudioConnected,
    required this.auditingAssetId,
    required this.onDelete,
    required this.onAudition,
    required this.onAuditionStop,
  });

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      itemCount: assets.length,
      separatorBuilder: (_, __) =>
          const Divider(height: 1, color: ScColors.divider),
      itemBuilder: (_, i) {
        final a = i < assets.length ? assets[i] : null;
        if (a == null) return const SizedBox.shrink();
        final isAuditing = auditingAssetId == a.id;
        final lufs = a.audio?.loudnessLufs;
        final info = [
          if (a.audio?.codec != null) a.audio!.codec.toUpperCase(),
          if (a.audio != null) a.audio!.channelLabel,
          if (lufs != null) '${lufs.toStringAsFixed(1)} LUFS',
          _formatBytes(a.sizeBytes),
        ].join(' · ');

        return Dismissible(
          key: ValueKey(a.id),
          direction: DismissDirection.endToStart,
          background: Container(
            color: ScColors.error,
            alignment: Alignment.centerRight,
            padding: const EdgeInsets.only(right: 16),
            child:
                const Icon(Icons.delete_outline, color: Colors.white, size: 20),
          ),
          confirmDismiss: (_) async {
            return await showDialog<bool>(
                  context: context,
                  builder: (_) => AlertDialog(
                    backgroundColor: ScColors.surface,
                    title: Text(
                      '${a.name} löschen?',
                      style: ScText.label.copyWith(color: ScColors.textPrimary),
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(false),
                        child: Text('Abbrechen',
                            style: ScText.label
                                .copyWith(color: ScColors.textSecondary)),
                      ),
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(true),
                        child: Text('Löschen',
                            style:
                                ScText.label.copyWith(color: ScColors.error)),
                      ),
                    ],
                  ),
                ) ??
                false;
          },
          onDismissed: (_) => onDelete(a.name),
          child: ListTile(
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            leading: Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: ScColors.surface2,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Icon(
                Icons.audio_file,
                size: 18,
                color: _readinessColor(a.readiness),
              ),
            ),
            title: Text(
              a.name,
              style: ScText.label.copyWith(color: ScColors.textPrimary),
              overflow: TextOverflow.ellipsis,
            ),
            subtitle: info.isNotEmpty
                ? Text(
                    info,
                    style: ScText.label
                        .copyWith(color: ScColors.textDim, fontSize: 10),
                  )
                : null,
            trailing: isAudioConnected && a.audio != null
                ? IconButton(
                    icon: Icon(
                      isAuditing
                          ? Icons.stop_circle_outlined
                          : Icons.play_circle_outline,
                      size: 22,
                      color:
                          isAuditing ? ScColors.active : ScColors.textSecondary,
                    ),
                    onPressed:
                        isAuditing ? onAuditionStop : () => onAudition(a),
                  )
                : null,
          ),
        );
      },
    );
  }

  static Color _readinessColor(AssetReadiness r) {
    if (r == AssetReadiness.patched) return ScColors.active;
    return ScColors.textSecondary;
  }

  static String _formatBytes(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(0)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }
}

// ── Asset Table ────────────────────────────────────────────────────────────────

class _AssetTable extends StatelessWidget {
  final List<Asset> assets;
  final bool isAudioConnected;
  final String? auditingAssetId;
  final _SortCol sortBy;
  final bool sortAsc;
  final ValueChanged<_SortCol> onSort;
  final ValueChanged<String> onDelete;
  final ValueChanged<Asset> onAudition;
  final VoidCallback onAuditionStop;

  const _AssetTable({
    required this.assets,
    required this.isAudioConnected,
    required this.auditingAssetId,
    required this.sortBy,
    required this.sortAsc,
    required this.onSort,
    required this.onDelete,
    required this.onAudition,
    required this.onAuditionStop,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          height: 32,
          color: ScColors.surface,
          padding: const EdgeInsets.symmetric(horizontal: ScSpacing.panelPad),
          child: Row(
            children: [
              _HeaderCell('NAME',
                  col: _SortCol.name,
                  flex: 4,
                  sortBy: sortBy,
                  sortAsc: sortAsc,
                  onSort: onSort),
              _HeaderCell('FORMAT',
                  col: _SortCol.format,
                  flex: 1,
                  sortBy: sortBy,
                  sortAsc: sortAsc,
                  onSort: onSort),
              _HeaderCell('LAUTHEIT',
                  col: _SortCol.loudness,
                  flex: 1,
                  sortBy: sortBy,
                  sortAsc: sortAsc,
                  onSort: onSort),
              _HeaderCell('GRÖßE',
                  col: _SortCol.size,
                  flex: 1,
                  sortBy: sortBy,
                  sortAsc: sortAsc,
                  onSort: onSort),
              _HeaderCell('STATUS',
                  col: _SortCol.status,
                  flex: 1,
                  sortBy: sortBy,
                  sortAsc: sortAsc,
                  onSort: onSort),
              _HeaderCell('HOCHGELADEN',
                  col: _SortCol.uploaded,
                  flex: 2,
                  sortBy: sortBy,
                  sortAsc: sortAsc,
                  onSort: onSort),
              const SizedBox(width: 80),
            ],
          ),
        ),
        const Divider(height: 1, color: ScColors.divider),
        Expanded(
          child: ListView.separated(
            itemCount: assets.length,
            separatorBuilder: (_, __) =>
                const Divider(height: 1, color: ScColors.divider),
            itemBuilder: (context, i) => _AssetRow(
              asset: assets[i],
              isAudioConnected: isAudioConnected,
              auditingAssetId: auditingAssetId,
              onDelete: () => onDelete(assets[i].name),
              onAudition: () => onAudition(assets[i]),
              onAuditionStop: onAuditionStop,
            ),
          ),
        ),
        Container(
          height: 28,
          color: ScColors.surface,
          padding: const EdgeInsets.symmetric(horizontal: ScSpacing.panelPad),
          child: Row(
            children: [
              Text(
                '${assets.length} Asset${assets.length == 1 ? "" : "s"}',
                style: ScText.statusSmall,
              ),
              const Spacer(),
              if (isAudioConnected)
                Tooltip(
                  message: 'Vorhören stoppen',
                  child: InkWell(
                    onTap: onAuditionStop,
                    borderRadius: BorderRadius.circular(4),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 4),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.stop,
                              size: 12, color: ScColors.textDim),
                          const SizedBox(width: 4),
                          Text('Stop Vorhören', style: ScText.statusSmall),
                        ],
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

class _HeaderCell extends StatelessWidget {
  final String label;
  final _SortCol col;
  final int flex;
  final _SortCol sortBy;
  final bool sortAsc;
  final ValueChanged<_SortCol> onSort;

  const _HeaderCell(
    this.label, {
    required this.col,
    required this.flex,
    required this.sortBy,
    required this.sortAsc,
    required this.onSort,
  });

  @override
  Widget build(BuildContext context) {
    final active = sortBy == col;
    return Expanded(
      flex: flex,
      child: InkWell(
        onTap: () => onSort(col),
        borderRadius: BorderRadius.circular(3),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                label,
                style: ScText.panelTitle.copyWith(
                  color: active ? ScColors.active : null,
                ),
              ),
              const SizedBox(width: 2),
              Icon(
                active
                    ? (sortAsc ? Icons.arrow_upward : Icons.arrow_downward)
                    : Icons.unfold_more,
                size: 11,
                color: active ? ScColors.active : ScColors.textDim,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AssetRow extends StatefulWidget {
  final Asset asset;
  final bool isAudioConnected;
  final String? auditingAssetId;
  final VoidCallback onDelete;
  final VoidCallback onAudition;
  final VoidCallback onAuditionStop;

  const _AssetRow({
    required this.asset,
    required this.isAudioConnected,
    required this.auditingAssetId,
    required this.onDelete,
    required this.onAudition,
    required this.onAuditionStop,
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
            Expanded(
              flex: 1,
              child: Text(
                a.audio?.codec.toUpperCase() ?? '—',
                style: ScText.label,
              ),
            ),
            Expanded(
              flex: 1,
              child: a.audio?.loudnessLufs != null
                  ? Tooltip(
                      message: 'EBU R128 integrierte Lautheit',
                      child: Text(
                        '${a.audio!.loudnessLufs!.toStringAsFixed(1)} LUFS',
                        style: ScText.numberSmall,
                      ),
                    )
                  : Text('—',
                      style: ScText.label.copyWith(color: ScColors.textDim)),
            ),
            Expanded(
              flex: 1,
              child: Text(
                _formatSize(a.sizeBytes),
                style: ScText.numberSmall,
              ),
            ),
            Expanded(
              flex: 1,
              child: _ReadinessChip(readiness: a.readiness),
            ),
            Expanded(
              flex: 2,
              child: Text(
                _formatDate(a.uploadedAt),
                style: ScText.label,
              ),
            ),
            SizedBox(
              width: 72,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  if (isAudio) ...[
                    () {
                      final isPlaying =
                          widget.auditingAssetId == widget.asset.id;
                      return Tooltip(
                        message: !widget.isAudioConnected
                            ? 'Audio-Node nicht verbunden'
                            : isPlaying
                                ? 'Vorhören stoppen'
                                : 'Vorhören',
                        child: InkWell(
                          onTap: widget.isAudioConnected
                              ? (isPlaying
                                  ? widget.onAuditionStop
                                  : widget.onAudition)
                              : null,
                          borderRadius: BorderRadius.circular(4),
                          child: Padding(
                            padding: const EdgeInsets.all(4),
                            child: isPlaying
                                ? const Icon(Icons.graphic_eq,
                                    size: 15, color: ScColors.active)
                                : Icon(Icons.headphones,
                                    size: 15,
                                    color: widget.isAudioConnected
                                        ? ScColors.textSecondary
                                        : ScColors.textDim),
                          ),
                        ),
                      );
                    }(),
                    const SizedBox(width: 2),
                  ],
                  if (_hovered)
                    _confirmDelete
                        ? _IconBtn(
                            icon: Icons.check,
                            tooltip: 'Löschen bestätigen',
                            color: ScColors.error,
                            onTap: widget.onDelete,
                          )
                        : _IconBtn(
                            icon: Icons.delete_outline,
                            tooltip: 'Löschen',
                            color: ScColors.error,
                            onTap: () => setState(() => _confirmDelete = true),
                          )
                  else
                    const SizedBox(width: 20),
                ],
              ),
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
        AssetReadiness.patched => ScChipState.ok,
        AssetReadiness.renderable => ScChipState.warn,
        AssetReadiness.validated => ScChipState.idle,
        AssetReadiness.present => ScChipState.warn,
      };

  String get _label => switch (readiness) {
        AssetReadiness.patched => 'Bereit',
        AssetReadiness.renderable => 'Abspielbar',
        AssetReadiness.validated => 'Verifiziert',
        AssetReadiness.present => 'Vorhanden',
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

enum _BannerType { error }

class _ErrorBanner extends StatelessWidget {
  final String message;
  final _BannerType type;
  final VoidCallback? onDismiss;
  const _ErrorBanner(
      {required this.message, required this.type, this.onDismiss});

  @override
  Widget build(BuildContext context) {
    final color = ScColors.error;
    return Container(
      width: double.infinity,
      color: color.withValues(alpha: 0.1),
      padding: const EdgeInsets.symmetric(
          horizontal: ScSpacing.panelPad, vertical: 6),
      child: Row(
        children: [
          Icon(Icons.warning_amber_rounded, size: 14, color: color),
          const SizedBox(width: 8),
          Expanded(
              child: Text(message, style: ScText.label.copyWith(color: color))),
          if (onDismiss != null)
            InkWell(
              onTap: onDismiss,
              borderRadius: BorderRadius.circular(4),
              child: Padding(
                padding: const EdgeInsets.all(4),
                child: Icon(Icons.close, size: 13, color: color),
              ),
            ),
        ],
      ),
    );
  }
}
