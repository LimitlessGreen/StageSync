import 'dart:async';
import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/asset.dart';
import '../media/media_grpc_client.dart';
import '../media/server_media_client.dart' show MediaFile;
import 'show_control_domain_provider.dart';

// ── State ─────────────────────────────────────────────────────────────────────

class MediaState {
  final List<Asset> assets;
  final bool isLoading;
  final bool isUploading;
  final String? error;
  final String? uploadError;

  const MediaState({
    this.assets = const [],
    this.isLoading = false,
    this.isUploading = false,
    this.error,
    this.uploadError,
  });

  MediaState copyWith({
    List<Asset>? assets,
    bool? isLoading,
    bool? isUploading,
    String? error,
    String? uploadError,
    bool clearError = false,
    bool clearUploadError = false,
  }) =>
      MediaState(
        assets: assets ?? this.assets,
        isLoading: isLoading ?? this.isLoading,
        isUploading: isUploading ?? this.isUploading,
        error: clearError ? null : (error ?? this.error),
        uploadError:
            clearUploadError ? null : (uploadError ?? this.uploadError),
      );

  /// Returns the asset with the given [id] (SHA-256), or null.
  Asset? assetById(String id) {
    for (final a in assets) {
      if (a.id == id) return a;
    }
    return null;
  }

  /// Returns the asset with the given [name], or null.
  Asset? assetByName(String name) {
    for (final a in assets) {
      if (a.name == name) return a;
    }
    return null;
  }
}

// ── Provider ──────────────────────────────────────────────────────────────────

final mediaProvider =
    StateNotifierProvider<MediaNotifier, MediaState>((ref) {
  return MediaNotifier(ref);
});

/// Convenience: look up a single asset by id or name (used by the inspector).
final assetLookupProvider = Provider.family<Asset?, String>((ref, idOrName) {
  final state = ref.watch(mediaProvider);
  return state.assetById(idOrName) ?? state.assetByName(idOrName);
});

/// Like [assetLookupProvider] but elevates [AssetReadiness] to [patched]
/// when the asset's id is in [patchedAssetIdsProvider].
/// Use this in the inspector and cue editor so the UI reflects the true status.
final assetWithReadinessProvider =
    Provider.family<Asset?, String>((ref, idOrName) {
  final asset = ref.watch(assetLookupProvider(idOrName));
  if (asset == null) return null;
  final isPatchedId = ref.watch(patchedAssetIdsProvider).contains(asset.id);
  if (!isPatchedId) return asset;
  return asset.readiness == AssetReadiness.patched
      ? asset
      : asset.copyWith(readiness: AssetReadiness.patched);
});

/// Full asset list with [AssetReadiness] correctly elevated for patched assets.
/// Use this in the MediaManagerScreen so the Readiness column is accurate.
final enrichedAssetsProvider = Provider<List<Asset>>((ref) {
  final assets  = ref.watch(mediaProvider).assets;
  final patched = ref.watch(patchedAssetIdsProvider);
  if (patched.isEmpty) return assets;
  return [
    for (final a in assets)
      if (patched.contains(a.id) && a.readiness != AssetReadiness.patched)
        a.copyWith(readiness: AssetReadiness.patched)
      else
        a,
  ];
});

// ── Notifier ──────────────────────────────────────────────────────────────────

class MediaNotifier extends StateNotifier<MediaState> {
  MediaNotifier(Ref ref) : super(const MediaState());

  final _grpc = MediaGrpcClient();
  StreamSubscription<ManifestSnapshot>? _manifestSub;

  /// Startet den WatchManifest-Stream und hält die Asset-Liste aktuell.
  /// Wird automatisch neu verbunden bei Verbindungsabbruch.
  void startWatching() {
    _manifestSub?.cancel();
    _manifestSub = _grpc.watchManifest().listen(
      _onManifestEvent,
      onError: (e) {
        state = state.copyWith(error: 'Verbindungsfehler: $e');
        // Reconnect nach 5 s
        Future.delayed(const Duration(seconds: 5), () {
          if (mounted) startWatching();
        });
      },
    );
  }

  void _onManifestEvent(ManifestSnapshot event) {
    if (event.type == ManifestEventType.snapshot) {
      final assets = event.assets.map(_toAsset).toList()
        ..sort((a, b) => a.name.compareTo(b.name));
      state = state.copyWith(assets: assets, isLoading: false, clearError: true);
    } else if (event.type == ManifestEventType.added ||
               event.type == ManifestEventType.updated) {
      for (final f in event.assets) {
        final updated = _toAsset(f);
        final existing = state.assets.indexWhere((a) => a.name == f.name);
        final next = List<Asset>.from(state.assets);
        if (existing >= 0) {
          next[existing] = updated;
        } else {
          next.add(updated);
          next.sort((a, b) => a.name.compareTo(b.name));
        }
        state = state.copyWith(assets: next);
      }
    } else if (event.type == ManifestEventType.removed) {
      state = state.copyWith(
        assets: state.assets.where((a) => a.name != event.removedName).toList(),
      );
    }
  }

  /// Manueller Refresh: WatchManifest neu starten → frischen Snapshot holen.
  Future<void> refresh() async {
    state = state.copyWith(isLoading: true, clearError: true);
    startWatching();
  }

  /// Lädt [bytes] als [filename] per gRPC-Streaming auf den Server.
  Future<void> upload(String filename, List<int> bytes) async {
    state = state.copyWith(isUploading: true, clearUploadError: true);
    try {
      await _grpc.uploadFile(filename, Uint8List.fromList(bytes));
      state = state.copyWith(isUploading: false);
      // Kein manuelles refresh nötig — WatchManifest liefert ASSET_ADDED-Event
    } catch (e) {
      state = state.copyWith(
        isUploading: false,
        uploadError: 'Upload fehlgeschlagen: $e',
      );
    }
  }

  void clearError() => state = state.copyWith(clearError: true, clearUploadError: true);

  /// Löscht ein Asset per gRPC.
  Future<void> delete(String name) async {
    try {
      // Optimistisch aus der Liste entfernen
      state = state.copyWith(
        assets: state.assets.where((a) => a.name != name).toList(),
      );
      await _grpc.deleteFile(name);
      // WatchManifest liefert ASSET_REMOVED-Event zur Bestätigung
    } catch (e) {
      state = state.copyWith(error: 'Löschen fehlgeschlagen: $e');
      refresh(); // Zustand reparieren
    }
  }

  @override
  void dispose() {
    _manifestSub?.cancel();
    super.dispose();
  }

  // ── Helpers ────────────────────────────────────────────────────────────────

  static Asset _toAsset(MediaFile f) {
    final mime = _mimeFor(f.name);
    final isAudio = mime.startsWith('audio/');
    final codec = _codecFor(f.name);

    return Asset(
      id: f.sha256.isNotEmpty ? f.sha256 : f.name,
      name: f.name,
      sizeBytes: f.sizeBytes,
      mimeType: mime,
      uploadedAt: f.modifiedMs > 0
          ? DateTime.fromMillisecondsSinceEpoch(f.modifiedMs)
          : DateTime.now(),
      audio: isAudio
          ? AudioMetadata(
              declaredDurationMs: f.audio?.durationMs.toDouble() ?? 0,
              channelCount:       f.audio?.channels    ?? 0,
              sampleRateHz:       f.audio?.sampleRate  ?? 0,
              loudnessLufs:       f.audio?.loudnessLufs,
              codec:              codec,
              bitDepth:           f.audio?.bitDepth    ?? 0,
            )
          : null,
      readiness: AssetReadiness.present,
    );
  }

  static String _mimeFor(String name) {
    final ext = name.toLowerCase().split('.').last;
    return switch (ext) {
      'wav'  => 'audio/wav',
      'mp3'  => 'audio/mpeg',
      'flac' => 'audio/flac',
      'aac'  => 'audio/aac',
      'ogg'  => 'audio/ogg',
      'm4a'  => 'audio/mp4',
      'aiff' => 'audio/aiff',
      _      => 'application/octet-stream',
    };
  }

  static String _codecFor(String name) {
    return name.toLowerCase().split('.').last;
  }
}
