import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/asset.dart';
import '../media/server_media_client.dart';
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

  ServerMediaClient? get _client => ServerMediaClient.fromConnection();

  /// Loads (or reloads) the asset list from the server.
  Future<void> refresh() async {
    final client = _client;
    if (client == null) {
      state = state.copyWith(
        error: 'Nicht verbunden — kein Server-Host bekannt.',
        clearUploadError: true,
      );
      return;
    }

    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final files = await client.list();
      final assets = files.map(_toAsset).toList()
        ..sort((a, b) => a.name.compareTo(b.name));
      state = state.copyWith(assets: assets, isLoading: false);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Laden fehlgeschlagen: $e',
      );
    }
  }

  /// Uploads [bytes] as [filename] to the server and refreshes the list.
  Future<void> upload(String filename, List<int> bytes) async {
    final client = _client;
    if (client == null) {
      state = state.copyWith(uploadError: 'Nicht verbunden.');
      return;
    }

    state = state.copyWith(isUploading: true, clearUploadError: true);
    try {
      await client.upload(filename, bytes);
      state = state.copyWith(isUploading: false);
      await refresh();
    } catch (e) {
      state = state.copyWith(
        isUploading: false,
        uploadError: 'Upload fehlgeschlagen: $e',
      );
    }
  }

  /// Deletes the asset with [name] from the server and refreshes the list.
  Future<void> delete(String name) async {
    final client = _client;
    if (client == null) return;
    try {
      await client.delete(name);
      // Optimistic removal
      state = state.copyWith(
        assets: state.assets.where((a) => a.name != name).toList(),
      );
    } catch (e) {
      state = state.copyWith(error: 'Löschen fehlgeschlagen: $e');
    }
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
              channelCount:       f.audio?.channels   ?? 0,
              sampleRateHz:       f.audio?.sampleRate ?? 0,
              codec:              codec,
              bitDepth:           f.audio?.bitDepth   ?? 0,
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
