import 'dart:convert';
import 'dart:io';

import 'package:mime/mime.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart' as io;
import 'package:shelf_router/shelf_router.dart';

import 'audio_engine.dart';

/// HTTP-Dateiserver der auf dem AudioNode läuft.
/// Erreichbar für Editor-Geräte im gleichen LAN.
///
/// Endpunkte:
///   GET  /media              → Dateiliste als JSON
///   POST /media/upload       → multipart/form-data upload
///   DELETE /media/:filename  → Datei löschen
///   GET  /media/preview/:filename → Vorschau starten (spielt ab)
///   DELETE /media/preview    → Vorschau stoppen
class MediaServer {
  static const int defaultPort = 50052;
  static const String _previewCueId = '__preview__';

  final AudioEngine _engine;
  HttpServer? _server;
  String? _mediaDir;
  String? _serverUrl;

  MediaServer(this._engine);

  String? get serverUrl => _serverUrl;

  /// Gibt das gecachte Medienverzeichnis zurück (nur nach start() gültig).
  String? get cachedMediaDir => _mediaDir;

  Future<String> get mediaDir async {
    _mediaDir ??= await _resolveMediaDir();
    return _mediaDir!;
  }

  Future<void> start({int port = defaultPort, required String bindIp}) async {
    final dir = await mediaDir;
    await Directory(dir).create(recursive: true);

    // Reihenfolge wichtig: spezifische Routen (preview) VOR der generischen
    // '/media/<filename>'-Route registrieren, sonst fängt letztere z.B.
    // 'DELETE /media/preview' mit filename="preview" ab.
    final router = Router()
      ..get('/media', _listFiles)
      ..post('/media/upload', _uploadFile)
      ..get('/media/download/<filename>', _downloadFile)
      ..get('/media/preview/<filename>', _startPreview)
      ..delete('/media/preview', _stopPreview)
      ..delete('/media/<filename>', _deleteFile)
      ..get('/health', _health);

    final handler = const Pipeline()
        .addMiddleware(_corsMiddleware())
        .addHandler(router.call);

    _server = await io.serve(handler, InternetAddress.anyIPv4, port);
    _serverUrl = 'http://$bindIp:$port';
  }

  Future<void> stop() async {
    await _server?.close(force: true);
    _server = null;
    _serverUrl = null;
  }

  // ── Handler ───────────────────────────────────────────────────────────────

  Future<Response> _listFiles(Request req) async {
    final dir = Directory(await mediaDir);
    final files = <Map<String, dynamic>>[];

    await for (final entity in dir.list()) {
      if (entity is! File) continue;
      final stat = await entity.stat();
      final name = p.basename(entity.path);
      final ext = p.extension(name).toLowerCase().replaceFirst('.', '');
      if (!_isAudioExtension(ext)) continue;

      files.add({
        'filename': name,
        'size_bytes': stat.size,
        'format': ext,
        'modified_at': stat.modified.millisecondsSinceEpoch,
      });
    }

    files.sort((a, b) => (a['filename'] as String).compareTo(b['filename'] as String));

    return Response.ok(
      jsonEncode(files),
      headers: {'Content-Type': 'application/json'},
    );
  }

  Future<Response> _uploadFile(Request req) async {
    final contentType = req.headers['content-type'] ?? '';
    if (!contentType.contains('multipart/form-data')) {
      return Response(400, body: 'Erwartet multipart/form-data');
    }

    final boundary = _extractBoundary(contentType);
    if (boundary == null) return Response(400, body: 'Kein Boundary gefunden');

    final bodyBytes = await req.read().expand((c) => c).toList();
    final transformer = MimeMultipartTransformer(boundary);
    final parts = await transformer
        .bind(Stream.fromIterable([bodyBytes]))
        .toList();

    if (parts.isEmpty) return Response(400, body: 'Keine Datei gefunden');

    final part = parts.first;
    final disposition = part.headers['content-disposition'] ?? '';
    final filename = _extractFilename(disposition);
    if (filename == null) return Response(400, body: 'Kein Dateiname im Disposition-Header');

    // Sicherheit: Keine Pfad-Traversal
    final safeName = p.basename(filename);
    if (!_isAudioExtension(p.extension(safeName).toLowerCase().replaceFirst('.', ''))) {
      return Response(400, body: 'Nicht unterstütztes Audioformat');
    }

    final targetPath = p.join(await mediaDir, safeName);
    final file = File(targetPath);
    final sink = file.openWrite();
    await sink.addStream(part);
    await sink.close();

    final stat = await file.stat();
    return Response.ok(
      jsonEncode({'filename': safeName, 'size_bytes': stat.size}),
      headers: {'Content-Type': 'application/json'},
    );
  }

  Future<Response> _downloadFile(Request req, String filename) async {
    final safeName = p.basename(filename);
    final file = File(p.join(await mediaDir, safeName));
    if (!await file.exists()) return Response.notFound('Datei nicht gefunden');
    final bytes = await file.readAsBytes();
    return Response.ok(
      bytes,
      headers: {
        'Content-Type': 'application/octet-stream',
        'Content-Disposition': 'attachment; filename="$safeName"',
      },
    );
  }

  Future<Response> _deleteFile(Request req, String filename) async {
    final safeName = p.basename(filename);
    final file = File(p.join(await mediaDir, safeName));
    if (!await file.exists()) return Response.notFound('Datei nicht gefunden');
    await file.delete();
    return Response.ok('{}', headers: {'Content-Type': 'application/json'});
  }

  Future<Response> _startPreview(Request req, String filename) async {
    final safeName = p.basename(filename);
    final filePath = p.join(await mediaDir, safeName);

    if (!await File(filePath).exists()) {
      return Response.notFound('Datei nicht gefunden');
    }

    try {
      await _engine.stop(_previewCueId);
      // Immer frisch laden: sonst würde unter dem festen Preview-Cue-Id eine
      // zuvor vorgehörte (andere) Datei erneut abgespielt.
      await _engine.preload(_previewCueId, filePath);
      await _engine.playAt(
        cueId: _previewCueId,
        filePath: filePath,
        startUnixMillis: DateTime.now().millisecondsSinceEpoch + 50,
        volumeDb: 0.0,
      );
      return Response.ok('{"status":"playing"}', headers: {'Content-Type': 'application/json'});
    } catch (e) {
      return Response.internalServerError(
        body: '{"error":"${e.toString().replaceAll('"', "'")}"}',
        headers: {'Content-Type': 'application/json'},
      );
    }
  }

  Future<Response> _stopPreview(Request req) async {
    await _engine.stop(_previewCueId, fadeOutMs: 300);
    return Response.ok('{"status":"stopped"}', headers: {'Content-Type': 'application/json'});
  }

  Future<Response> _health(Request req) async =>
      Response.ok('{"status":"ok","url":"$_serverUrl"}',
          headers: {'Content-Type': 'application/json'});

  // ── Helpers ───────────────────────────────────────────────────────────────

  static Future<String> _resolveMediaDir() async {
    final docs = await getApplicationDocumentsDirectory();
    return p.join(docs.path, 'StageSync', 'media');
  }

  /// Listet alle verfügbaren Netzwerk-Interfaces mit ihren IPv4-Adressen auf.
  static Future<List<NetworkInterfaceInfo>> listInterfaces() async {
    final result = <NetworkInterfaceInfo>[];
    final interfaces = await NetworkInterface.list(type: InternetAddressType.IPv4);
    for (final iface in interfaces) {
      for (final addr in iface.addresses) {
        result.add(NetworkInterfaceInfo(name: iface.name, address: addr.address));
      }
    }
    return result;
  }

  static Middleware _corsMiddleware() {
    return (Handler inner) => (Request req) async {
          if (req.method == 'OPTIONS') {
            return Response.ok('', headers: _corsHeaders);
          }
          final resp = await inner(req);
          return resp.change(headers: _corsHeaders);
        };
  }

  static const _corsHeaders = {
    'Access-Control-Allow-Origin': '*',
    'Access-Control-Allow-Methods': 'GET, POST, DELETE, OPTIONS',
    'Access-Control-Allow-Headers': 'Content-Type',
  };

  static bool _isAudioExtension(String ext) =>
      {'wav', 'mp3', 'flac', 'aac', 'ogg', 'm4a', 'aiff'}.contains(ext);

  static String? _extractBoundary(String contentType) {
    for (final part in contentType.split(';')) {
      final trimmed = part.trim();
      if (trimmed.startsWith('boundary=')) {
        return trimmed.substring('boundary='.length).replaceAll('"', '');
      }
    }
    return null;
  }

  static String? _extractFilename(String disposition) {
    final match = RegExp(r'filename="?([^";]+)"?').firstMatch(disposition);
    return match?.group(1);
  }
}

class NetworkInterfaceInfo {
  final String name;
  final String address;

  const NetworkInterfaceInfo({required this.name, required this.address});

  @override
  String toString() => '$name ($address)';
}
