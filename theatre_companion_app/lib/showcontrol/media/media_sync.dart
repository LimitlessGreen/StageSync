import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;

import 'media_grpc_client.dart';
import 'server_media_client.dart' show MediaFile;

/// Spiegelt die Audio-Datenbank des Servers in das lokale Cache-Verzeichnis.
///
/// Transportschicht: ausschließlich gRPC (kein HTTP mehr).
/// - [WatchManifest] liefert beim Start einen Snapshot und danach inkrementelle
///   Events → kein polling, kein HTTP SSE mehr.
/// - Downloads per [StreamFile] gRPC-Streaming → atomar auf Disk geschrieben.
/// - Lokales Disk-Cache als L2: bei Netzwerkausfall während einer Show können
///   bereits gecachte Dateien weiterhin abgespielt werden.
class MediaSync {
  final MediaGrpcClient _grpc;
  final String cacheDir;

  static const _manifestName = '.manifest.json';

  // name → sha256 aller lokal bekannten Dateien.
  final Map<String, String> _manifest = {};
  // Verhindert parallele Downloads derselben Datei.
  final Map<String, Future<String?>> _inflight = {};

  StreamSubscription<ManifestSnapshot>? _manifestSub;
  bool _disposed = false;
  Future<void>? _runningSync;

  MediaSync(this._grpc, this.cacheDir);

  /// Startet den Spiegel: lädt das lokale Manifest, öffnet den WatchManifest-
  /// Stream und startet Downloads im Hintergrund.
  Future<void> start() async {
    await _loadManifest();
    _listenManifestStream();
  }

  Future<void> stop() async {
    _disposed = true;
    await _manifestSub?.cancel();
    _manifestSub = null;
  }

  String _pathFor(String name) => p.join(cacheDir, p.basename(name));

  // ── Manifest-Stream (gRPC WatchManifest) ─────────────────────────────────

  void _listenManifestStream() {
    if (_disposed) return;
    () async {
      try {
        _manifestSub = _grpc.watchManifest().listen(
          _onManifestEvent,
          onError: (_) => _scheduleReconnect(),
          onDone: _scheduleReconnect,
          cancelOnError: true,
        );
      } catch (_) {
        _scheduleReconnect();
      }
    }();
  }

  void _onManifestEvent(ManifestSnapshot event) {
    switch (event.type) {
      case ManifestEventType.snapshot:
        // Vollständige Liste → sync anstoßen
        syncAllFromList(event.assets);
      case ManifestEventType.added:
      case ManifestEventType.updated:
        for (final f in event.assets) {
          if (_manifest[f.name] != f.sha256 || !File(_pathFor(f.name)).existsSync()) {
            _download(f.name, expectedSha: f.sha256);
          }
        }
      case ManifestEventType.removed:
        if (event.removedName.isNotEmpty) {
          _pruneOne(event.removedName);
        }
    }
  }

  void _scheduleReconnect() {
    _manifestSub?.cancel();
    _manifestSub = null;
    if (_disposed) return;
    // Exponentielles Backoff: 5 s → 10 s → 20 s … max 60 s
    Future.delayed(const Duration(seconds: 5), () {
      if (!_disposed) _listenManifestStream();
    });
  }

  // ── Voll-Sync ─────────────────────────────────────────────────────────────

  /// Wird nach einem Snapshot-Event aufgerufen.
  /// Mehrfachaufrufe werden serialisiert.
  Future<void> syncAllFromList(List<MediaFile> remote) {
    final running = _runningSync;
    if (running != null) return running;
    final fut = _doSyncAll(remote).whenComplete(() => _runningSync = null);
    _runningSync = fut;
    return fut;
  }

  Future<void> _doSyncAll(List<MediaFile> remote) async {
    final remoteNames = <String>{};
    for (final f in remote) {
      remoteNames.add(f.name);
      // Manifest-Eintrag sofort setzen (filenameForSha256 funktioniert direkt)
      _manifest[f.name] = f.sha256;
      if (_isLocalCurrent(f.name, f.sha256)) continue;
      await _download(f.name, expectedSha: f.sha256);
    }
    await _pruneMissing(remoteNames);
    await _saveManifest();
  }

  bool _isLocalCurrent(String name, String sha256) {
    return _manifest[name] == sha256 && File(_pathFor(name)).existsSync();
  }

  // ── Download / Lazy-Fetch ─────────────────────────────────────────────────

  /// Stellt sicher, dass die Datei lokal vorliegt, und gibt den Pfad zurück.
  /// [filenameOrPath]: Dateiname oder absoluter Legacy-Pfad.
  ///
  /// Fallback: Existiert die Datei bereits lokal, wird sie ohne Netzwerkzugriff
  /// zurückgegeben (Netzwerkausfall während Show → weiter abspielbar).
  Future<String?> ensureLocal(String filenameOrPath) async {
    if (filenameOrPath.isEmpty) return null;
    // Legacy: absoluter Pfad
    if (File(filenameOrPath).existsSync() && p.isAbsolute(filenameOrPath)) {
      return filenameOrPath;
    }
    final name = p.basename(filenameOrPath);
    final local = _pathFor(name);
    if (File(local).existsSync()) return local; // L2 Disk-Hit
    return _download(name);
  }

  /// Dedupliziert parallele Downloads desselben Dateinamens.
  Future<String?> _download(String name, {String? expectedSha}) {
    final existing = _inflight[name];
    if (existing != null) return existing;
    final fut = _doDownload(name, expectedSha).whenComplete(() => _inflight.remove(name));
    _inflight[name] = fut;
    return fut;
  }

  Future<String?> _doDownload(String name, String? expectedSha) async {
    final dst = _pathFor(name);
    final tmp = '$dst.part';

    // Netzwerk-Fallback: Wenn Datei lokal vorhanden (eventuell veralteter Hash),
    // trotzdem zurückgeben — verhindert Ausfall während Show bei kurzem Netzwerkausfall.
    final localExists = File(dst).existsSync();

    try {
      final bytes = await _grpc.streamFile(name: name);
      final tmpFile = File(tmp);
      await tmpFile.writeAsBytes(bytes, flush: true);
      await tmpFile.rename(dst);
      _manifest[name] = expectedSha ?? '';
      debugPrint('[MediaSync] geladen: $name (${bytes.length} B)');
      return dst;
    } catch (e) {
      debugPrint('[MediaSync] Download-Fehler $name: $e');
      try {
        final t = File(tmp);
        if (t.existsSync()) await t.delete();
      } catch (_) {}
      // Fallback auf veraltete lokale Kopie
      if (localExists) {
        debugPrint('[MediaSync] Fallback auf lokale Kopie: $name');
        return dst;
      }
      return null;
    }
  }

  // ── Aufräumen ─────────────────────────────────────────────────────────────

  Future<void> _pruneMissing(Set<String> keep) async {
    final dir = Directory(cacheDir);
    if (!dir.existsSync()) return;
    for (final entity in dir.listSync()) {
      if (entity is! File) continue;
      final name = p.basename(entity.path);
      if (name == _manifestName) continue;
      if (!ServerMediaClientNames.isAudio(name)) continue;
      if (!keep.contains(name)) {
        try {
          await entity.delete();
        } catch (_) {/* löschen fehlgeschlagen, ignorieren */}
        _manifest.remove(name);
        debugPrint('[MediaSync] lokal entfernt (nicht auf Server): $name');
      }
    }
  }

  void _pruneOne(String name) {
    final local = File(_pathFor(name));
    if (local.existsSync()) {
      local.delete().catchError((_) => local);
    }
    _manifest.remove(name);
    debugPrint('[MediaSync] lokal entfernt: $name');
  }

  // ── Manifest ──────────────────────────────────────────────────────────────

  Future<void> _loadManifest() async {
    try {
      final f = File(p.join(cacheDir, _manifestName));
      if (!f.existsSync()) return;
      final data = jsonDecode(await f.readAsString()) as Map<String, dynamic>;
      _manifest
        ..clear()
        ..addAll(data.map((k, v) => MapEntry(k, v as String)));
    } catch (_) {
      _manifest.clear();
    }
  }

  Future<void> _saveManifest() async {
    try {
      final f = File(p.join(cacheDir, _manifestName));
      await f.writeAsString(jsonEncode(_manifest));
    } catch (_) {}
  }

  /// Stellt sicher dass das Asset mit SHA-256 [assetId] lokal vorliegt.
  ///
  /// Strategie:
  /// 1. Manifest-Lookup (name→sha256 Reverse): falls Dateiname bekannt → [ensureLocal]
  /// 2. Direkt-Download per assetId (korrekte gRPC-Übergabe) — vermeidet den
  ///    Bug wo SHA-256 als Dateiname an streamFile(name:) übergeben wird.
  Future<String?> ensureLocalByAssetId(String assetId) async {
    // Lokalen Dateinamen ermitteln (Manifest reverse-lookup)
    final name = filenameForSha256(assetId);
    if (name != null) return ensureLocal(name);

    // Deduplizieren: gleicher assetId läuft nur einmal
    final existing = _inflight[assetId];
    if (existing != null) return existing;
    final fut = _doDownloadByAssetId(assetId).whenComplete(() => _inflight.remove(assetId));
    _inflight[assetId] = fut;
    return fut;
  }

  /// Lädt eine Datei direkt per assetId (SHA-256) herunter.
  /// Speichert als `assetId`-Dateiname (miniaudio erkennt Format aus Magic-Bytes).
  Future<String?> _doDownloadByAssetId(String assetId) async {
    final dst = _pathFor(assetId); // ohne Extension — miniaudio detektiert Format
    final tmp = '$dst.part';
    final localExists = File(dst).existsSync();
    try {
      final bytes = await _grpc.streamFile(assetId: assetId); // korrekt: assetId nicht name
      await File(tmp).writeAsBytes(bytes, flush: true);
      await File(tmp).rename(dst);
      _manifest[assetId] = assetId;
      debugPrint('[MediaSync] geladen per assetId: ${assetId.substring(0, 8)}… (${bytes.length} B)');
      return dst;
    } catch (e) {
      debugPrint('[MediaSync] Download-Fehler assetId=${assetId.substring(0, 8)}…: $e');
      try {
        if (File(tmp).existsSync()) await File(tmp).delete();
      } catch (_) {/* ignorieren */}
      if (localExists) {
        debugPrint('[MediaSync] Fallback auf veraltete lokale Kopie: $assetId');
        return dst;
      }
      return null;
    }
  }

  /// Gibt den Dateinamen für einen SHA-256-Hash zurück, oder null wenn unbekannt.
  String? filenameForSha256(String sha256) {
    for (final entry in _manifest.entries) {
      if (entry.value == sha256) return entry.key;
    }
    return null;
  }
}

// ── Hilfsmethoden ────────────────────────────────────────────────────────────

class ServerMediaClientNames {
  static const _exts = {'.wav', '.mp3', '.flac', '.aac', '.ogg', '.m4a', '.aiff'};
  static bool isAudio(String name) =>
      _exts.contains(p.extension(name).toLowerCase());
}

// ── Tests-Hilfsmethoden (Testbarkeit ohne echten gRPC-Client) ─────────────────

/// Fake-Implementierung von [MediaGrpcClient] für Tests.
/// Ermöglicht simulierten Netzwerkausfall und Disk-Fallback-Verifikation.
@visibleForTesting
class FakeMediaGrpcClient extends MediaGrpcClient {
  final Map<String, Uint8List> _files;
  bool failNext = false;

  FakeMediaGrpcClient(this._files);

  @override
  Stream<ManifestSnapshot> watchManifest() async* {
    final assets = _files.keys.map((name) {
      return MediaFile(
        name: name,
        sizeBytes: _files[name]!.length,
        sha256: name.hashCode.toRadixString(16).padLeft(64, '0'),
        modifiedMs: 0,
      );
    }).toList();
    yield ManifestSnapshot(
      type: ManifestEventType.snapshot,
      seq: 0,
      assets: assets,
    );
  }

  @override
  Future<Uint8List> streamFile({String? assetId, String? name, int offset = 0, void Function(int, int)? onProgress}) async {
    if (failNext) {
      failNext = false;
      throw Exception('Simulierter Netzwerkfehler');
    }
    final n = name ?? assetId ?? '';
    final data = _files[n];
    if (data == null) throw Exception('Datei nicht gefunden: $n');
    return data;
  }
}
