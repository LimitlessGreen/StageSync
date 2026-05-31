import 'dart:async';

import 'package:fixnum/fixnum.dart' show Int64;
import 'package:flutter/foundation.dart';

import '../grpc/stage_sync_client.dart';
import '../grpc/generated/stagesync/v1/media.pb.dart' as pb;
import '../grpc/generated/stagesync/v1/media.pbgrpc.dart';
import 'server_media_client.dart' show MediaFile, MediaAudioInfo;

/// gRPC-Client für den MediaService.
///
/// Ersetzt den HTTP-basierten [ServerMediaClient] für alle Dateioperationen:
/// - [watchManifest]  : Stream aller Asset-Änderungen (Snapshot + Inkremente)
/// - [streamFile]     : Datei chunk-weise herunterladen
/// - [uploadFile]     : Datei chunk-weise hochladen
/// - [deleteFile]     : Datei auf dem Server löschen
///
/// Authentifizierung: session_id + token werden automatisch aus
/// [StageSyncClient.instance] übernommen.
class MediaGrpcClient {
  static const _chunkSize = 64 * 1024; // 64 KiB — muss mit Server übereinstimmen

  MediaServiceClient get _stub => StageSyncClient.instance.media;

  // ── WatchManifest ──────────────────────────────────────────────────────────

  /// Liefert einen Stream von Manifest-Events.
  /// Erstes Event ist immer ein SNAPSHOT mit der vollständigen Asset-Liste.
  /// Folgende Events sind inkrementelle Änderungen.
  Stream<ManifestSnapshot> watchManifest() {
    final req = pb.WatchManifestRequest(
      sessionId: StageSyncClient.instance.sessionId ?? '',
      token: StageSyncClient.instance.token ?? '',
    );
    return _stub.watchManifest(req).map(_eventToSnapshot);
  }

  static ManifestSnapshot _eventToSnapshot(pb.ManifestEvent event) {
    return ManifestSnapshot(
      type: switch (event.type) {
        pb.ManifestEvent_EventType.MANIFEST_SNAPSHOT => ManifestEventType.snapshot,
        pb.ManifestEvent_EventType.ASSET_ADDED       => ManifestEventType.added,
        pb.ManifestEvent_EventType.ASSET_REMOVED     => ManifestEventType.removed,
        pb.ManifestEvent_EventType.ASSET_UPDATED     => ManifestEventType.updated,
        _                                             => ManifestEventType.snapshot,
      },
      seq: event.seq.toInt(),
      assets: event.assets.map(_assetInfoToMediaFile).toList(),
      removedName: event.removedName,
    );
  }

  static MediaFile _assetInfoToMediaFile(pb.AssetInfo a) {
    final audio = a.hasAudio() ? MediaAudioInfo(
      durationMs:   a.audio.durationMs.toInt(),
      channels:     a.audio.channels,
      sampleRate:   a.audio.sampleRate,
      bitDepth:     a.audio.bitDepth,
      loudnessLufs: a.audio.hasLoudness ? a.audio.loudnessLufs : null,
    ) : null;
    return MediaFile(
      name:       a.name,
      sizeBytes:  a.sizeBytes.toInt(),
      sha256:     a.assetId,
      modifiedMs: a.modifiedMs.toInt(),
      mimeType:   a.mimeType,
      audio:      audio,
    );
  }

  // ── StreamFile ─────────────────────────────────────────────────────────────

  /// Streamt eine Datei vom Server und gibt alle Bytes als [Uint8List] zurück.
  ///
  /// Für Nodes: danach atomar auf Disk schreiben (temp + rename).
  /// Für Preview: Bytes direkt in den Audio-Engine übergeben.
  ///
  /// [assetId] oder [name] muss gesetzt sein.
  Future<Uint8List> streamFile({
    String? assetId,
    String? name,
    int offset = 0,
    void Function(int received, int total)? onProgress,
  }) async {
    assert(assetId != null || name != null, 'assetId oder name erforderlich');

    final req = pb.StreamFileRequest(
      sessionId: StageSyncClient.instance.sessionId ?? '',
      token:     StageSyncClient.instance.token ?? '',
      assetId:   assetId ?? '',
      name:      name ?? '',
      offset:    Int64(offset),
    );

    final chunks = <Uint8List>[];
    int totalBytes = 0;

    await for (final chunk in _stub.streamFile(req)) {
      chunks.add(Uint8List.fromList(chunk.data));
      if (onProgress != null) {
        onProgress(
          chunks.fold<int>(0, (s, c) => s + c.length),
          chunk.totalBytes.toInt(),
        );
      }
      totalBytes = chunk.totalBytes.toInt();
    }

    final result = Uint8List(totalBytes > 0 ? totalBytes : chunks.fold(0, (s, c) => s + c.length));
    var pos = 0;
    for (final chunk in chunks) {
      result.setRange(pos, pos + chunk.length, chunk);
      pos += chunk.length;
    }
    return result;
  }

  // ── UploadFile ─────────────────────────────────────────────────────────────

  /// Lädt [bytes] als [filename] auf den Server hoch.
  /// [onProgress] wird nach jedem gesendeten Chunk aufgerufen: (bytesSent, totalBytes).
  /// Gibt das [MediaFile] des neu gespeicherten Assets zurück.
  Future<MediaFile> uploadFile(
    String filename,
    Uint8List bytes, {
    void Function(int sent, int total)? onProgress,
  }) async {
    final controller = StreamController<pb.UploadChunk>();

    controller.add(pb.UploadChunk(meta: pb.UploadMeta(
      sessionId:  StageSyncClient.instance.sessionId ?? '',
      token:      StageSyncClient.instance.token ?? '',
      filename:   filename,
      totalBytes: Int64(bytes.length),
    )));

    var sent = 0;
    for (var off = 0; off < bytes.length; off += _chunkSize) {
      final end = (off + _chunkSize).clamp(0, bytes.length);
      controller.add(pb.UploadChunk(data: bytes.sublist(off, end)));
      sent += end - off;
      onProgress?.call(sent, bytes.length);
    }
    controller.close();

    final resp = await _stub.uploadFile(controller.stream);
    debugPrint('[MediaGrpc] upload ok: ${resp.name} ${resp.sizeBytes} B sha=${resp.assetId.substring(0, 8)}');

    return MediaFile(
      name:       resp.name,
      sizeBytes:  resp.sizeBytes.toInt(),
      sha256:     resp.assetId,
      modifiedMs: DateTime.now().millisecondsSinceEpoch,
      audio: resp.hasAudio() ? MediaAudioInfo(
        durationMs:   resp.audio.durationMs.toInt(),
        channels:     resp.audio.channels,
        sampleRate:   resp.audio.sampleRate,
        bitDepth:     resp.audio.bitDepth,
        loudnessLufs: resp.audio.hasLoudness ? resp.audio.loudnessLufs : null,
      ) : null,
    );
  }

  // ── DeleteFile ─────────────────────────────────────────────────────────────

  /// Löscht eine Datei auf dem Server.
  Future<void> deleteFile(String name) async {
    await _stub.deleteFile(pb.DeleteFileRequest(
      sessionId: StageSyncClient.instance.sessionId ?? '',
      token:     StageSyncClient.instance.token ?? '',
      name:      name,
    ));
    debugPrint('[MediaGrpc] deleted: $name');
  }
}

// ── Domain-Typen für Manifest-Events ─────────────────────────────────────────

enum ManifestEventType { snapshot, added, removed, updated }

class ManifestSnapshot {
  final ManifestEventType type;
  final int seq;
  final List<MediaFile> assets;
  final String removedName;

  const ManifestSnapshot({
    required this.type,
    required this.seq,
    required this.assets,
    this.removedName = '',
  });
}
