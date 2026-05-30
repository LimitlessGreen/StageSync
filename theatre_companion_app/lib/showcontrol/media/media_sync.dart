import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:path/path.dart' as p;

import 'server_media_client.dart';

/// Spiegelt die komplette Audio-Datenbank des Sync-Servers in das lokale
/// Cache-Verzeichnis dieses Geräts. Läuft auf Audio-Nodes.
///
/// - Voll-Sync beim Start und bei jeder Server-Änderung (via SSE).
/// - Inhalts-Vergleich über sha256 (vom Server geliefert), lokal in einem
///   Manifest gespeichert → kein erneutes Hashen lokaler Dateien nötig.
/// - Lazy-Fetch: fehlt eine angeforderte Datei, wird sie sofort nachgeladen.
class MediaSync {
  final ServerMediaClient _client;
  final String cacheDir;

  static const _manifestName = '.manifest.json';

  // name → sha256 der lokal vorhandenen Datei.
  final Map<String, String> _manifest = {};
  // Verhindert parallele Downloads derselben Datei (Lazy-Fetch vs. Voll-Sync).
  final Map<String, Future<String?>> _inflight = {};

  StreamSubscription<String>? _eventSub;
  http.Client? _eventClient;
  bool _disposed = false;
  Future<void>? _runningSync;

  MediaSync(this._client, this.cacheDir);

  /// Startet den Spiegel: lädt das Manifest, macht einen Voll-Sync und
  /// abonniert Server-Änderungen.
  Future<void> start() async {
    await _loadManifest();
    await syncAll();
    _listenEvents();
  }

  Future<void> stop() async {
    _disposed = true;
    await _eventSub?.cancel();
    _eventSub = null;
    _eventClient?.close();
    _eventClient = null;
  }

  String _pathFor(String name) => p.join(cacheDir, p.basename(name));

  // ── Voll-Sync ───────────────────────────────────────────────────────────

  /// Gleicht das lokale Verzeichnis vollständig mit dem Server ab.
  /// Mehrfachaufrufe werden serialisiert (kein paralleler Sync).
  Future<void> syncAll() {
    final running = _runningSync;
    if (running != null) return running;
    final fut = _doSyncAll().whenComplete(() => _runningSync = null);
    _runningSync = fut;
    return fut;
  }

  Future<void> _doSyncAll() async {
    final List<MediaFile> remote;
    try {
      remote = await _client.list();
    } catch (e) {
      debugPrint('[MediaSync] Server-Liste nicht erreichbar: $e');
      return; // später erneut versuchen (Event/Reconnect)
    }

    final remoteNames = <String>{};
    for (final f in remote) {
      remoteNames.add(f.name);
      if (_manifest[f.name] == f.sha256 && File(_pathFor(f.name)).existsSync()) {
        continue; // bereits aktuell
      }
      await _download(f.name, expectedSha: f.sha256);
    }

    // Lokale Dateien entfernen, die es auf dem Server nicht (mehr) gibt
    // → echter Spiegel der kompletten Datenbank.
    await _pruneMissing(remoteNames);
    await _saveManifest();
  }

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
        } catch (_) {}
        _manifest.remove(name);
        debugPrint('[MediaSync] lokal entfernt (nicht auf Server): $name');
      }
    }
  }

  // ── Download / Lazy-Fetch ─────────────────────────────────────────────────

  /// Stellt sicher, dass [filenameOrPath] lokal vorliegt, und gibt den lokalen
  /// Pfad zurück (oder null, wenn nicht beschaffbar).
  /// Akzeptiert auch absolute Pfade (Legacy) — existiert dieser, wird er genutzt.
  Future<String?> ensureLocal(String filenameOrPath) async {
    if (filenameOrPath.isEmpty) return null;
    // Legacy: bereits ein gültiger absoluter Pfad.
    if (File(filenameOrPath).existsSync() && p.isAbsolute(filenameOrPath)) {
      return filenameOrPath;
    }
    final name = p.basename(filenameOrPath);
    final local = _pathFor(name);
    if (File(local).existsSync()) return local;
    return _download(name);
  }

  /// Lädt eine Datei vom Server (atomar via temp+rename). Dedupliziert parallele
  /// Anfragen für denselben Namen.
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
    try {
      final resp = await _client.download(name);
      if (resp.statusCode != 200) {
        debugPrint('[MediaSync] Download $name → HTTP ${resp.statusCode}');
        return null;
      }
      final tmpFile = File(tmp);
      await tmpFile.writeAsBytes(resp.bodyBytes, flush: true);
      await tmpFile.rename(dst);
      // sha vom Server merken (oder leer, falls unbekannt → erzwingt re-check).
      _manifest[name] = expectedSha ?? '';
      debugPrint('[MediaSync] geladen: $name (${resp.bodyBytes.length} B)');
      return dst;
    } catch (e) {
      debugPrint('[MediaSync] Download-Fehler $name: $e');
      try {
        final t = File(tmp);
        if (t.existsSync()) await t.delete();
      } catch (_) {}
      return null;
    }
  }

  // ── Server-Events (SSE) ───────────────────────────────────────────────────

  void _listenEvents() {
    if (_disposed) return;
    () async {
      try {
        final client = http.Client();
        _eventClient = client;
        final req = http.Request('GET', _client.eventsUri());
        req.headers['Accept'] = 'text/event-stream';
        final resp = await client.send(req);
        _eventSub = resp.stream
            .transform(utf8.decoder)
            .transform(const LineSplitter())
            .listen(
          (line) {
            // Jede "data:"-Zeile signalisiert eine Änderung → re-syncen.
            if (line.startsWith('data:')) syncAll();
          },
          onError: (_) => _scheduleReconnect(),
          onDone: _scheduleReconnect,
          cancelOnError: true,
        );
      } catch (_) {
        _scheduleReconnect();
      }
    }();
  }

  void _scheduleReconnect() {
    _eventClient?.close();
    _eventClient = null;
    if (_disposed) return;
    Future.delayed(const Duration(seconds: 5), () {
      if (!_disposed) _listenEvents();
    });
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
      _manifest.clear(); // korruptes Manifest ignorieren
    }
  }

  Future<void> _saveManifest() async {
    try {
      final f = File(p.join(cacheDir, _manifestName));
      await f.writeAsString(jsonEncode(_manifest));
    } catch (_) {}
  }
}

/// Kleiner Helfer (vermeidet Import-Zyklus mit der Server-Endungsprüfung).
class ServerMediaClientNames {
  static const _exts = {'.wav', '.mp3', '.flac', '.aac', '.ogg', '.m4a', '.aiff'};
  static bool isAudio(String name) =>
      _exts.contains(p.extension(name).toLowerCase());
}
