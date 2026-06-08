import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../grpc/stage_sync_client.dart';

/// Standard-Port des autoritativen Medien-HTTP-Servers (s. Server-Flag
/// `--media-port`, Default 50053).
const int kServerMediaPort = 50053;

/// Lokales Cache-/Spiegel-Verzeichnis der Mediendateien auf diesem Gerät.
/// Audio-Nodes spiegeln hierhin die komplette Server-Datenbank.
Future<String> mediaCacheDir() async {
  final docs = await getApplicationDocumentsDirectory();
  final dir = p.join(docs.path, 'StageSync', 'media');
  await Directory(dir).create(recursive: true);
  return dir;
}

/// Technische Audio-Metadaten aus dem Server-Manifest.
class MediaAudioInfo {
  final int durationMs;
  final int channels;
  final int sampleRate;
  final int bitDepth;

  /// EBU R128 integrated loudness in LUFS. null = not yet measured.
  final double? loudnessLufs;

  const MediaAudioInfo({
    this.durationMs = 0,
    this.channels = 0,
    this.sampleRate = 0,
    this.bitDepth = 0,
    this.loudnessLufs,
  });

  factory MediaAudioInfo.fromJson(Map<String, dynamic> j) => MediaAudioInfo(
        durationMs: (j['duration_ms'] as num?)?.toInt() ?? 0,
        channels: (j['channels'] as num?)?.toInt() ?? 0,
        sampleRate: (j['sample_rate'] as num?)?.toInt() ?? 0,
        bitDepth: (j['bit_depth'] as num?)?.toInt() ?? 0,
        loudnessLufs: (j['loudness_lufs'] as num?)?.toDouble(),
      );
}

/// Eine Datei im Medien-Speicher des Servers (Manifest-Eintrag).
class MediaFile {
  final String name;
  final int sizeBytes;
  final String sha256;
  final int modifiedMs;
  final String mimeType;
  final MediaAudioInfo? audio; // null für Nicht-WAV oder Parse-Fehler

  const MediaFile({
    required this.name,
    required this.sizeBytes,
    required this.sha256,
    required this.modifiedMs,
    this.mimeType = 'audio/wav',
    this.audio,
  });

  factory MediaFile.fromJson(Map<String, dynamic> j) {
    final audioJson = j['audio'] as Map<String, dynamic>?;
    return MediaFile(
      name: j['name'] as String,
      sizeBytes: (j['size_bytes'] as num?)?.toInt() ?? 0,
      sha256: j['sha256'] as String? ?? '',
      modifiedMs: (j['modified_ms'] as num?)?.toInt() ?? 0,
      mimeType: j['mime_type'] as String? ?? 'audio/wav',
      audio: audioJson != null ? MediaAudioInfo.fromJson(audioJson) : null,
    );
  }
}

/// HTTP-Client für den autoritativen Medien-Speicher des Sync-Servers.
/// Alle Dateien liegen IMMER auf dem Server; Nodes ziehen sie sich von dort.
///
/// Pass [httpClient] to inject a custom client (e.g. for testing).
/// If null, the global [http.get]/[http.delete] functions are used.
class ServerMediaClient {
  final String baseUrl;
  final http.Client? _http;

  ServerMediaClient(this.baseUrl, {http.Client? httpClient})
      : _http = httpClient;

  /// Erzeugt einen Client aus der aktuellen Server-Verbindung (oder null,
  /// wenn nicht verbunden).
  static ServerMediaClient? fromConnection() {
    final host = StageSyncClient.instance.serverHost;
    if (host == null) return null;
    return ServerMediaClient('http://$host:$kServerMediaPort');
  }

  Uri _u(String path) => Uri.parse('$baseUrl$path');

  Uri downloadUri(String name) =>
      _u('/media/download/${Uri.encodeComponent(name)}');

  Uri eventsUri() => _u('/media/events');

  /// Holt das Server-Manifest: alle Dateien mit Name, SHA256, MIME, Größe.
  /// Nodes nutzen dieses für den Diff: nur fehlende/veränderte Dateien laden.
  Future<List<MediaFile>> manifest() async {
    final resp = await (_http != null
            ? _http.get(_u('/media/manifest'))
            : http.get(_u('/media/manifest')))
        .timeout(const Duration(seconds: 10));
    if (resp.statusCode != 200) {
      throw HttpException('manifest fehlgeschlagen (HTTP ${resp.statusCode})');
    }
    final data = jsonDecode(resp.body) as List;
    return data
        .map((e) => MediaFile.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// Alias für Rückwärtskompatibilität — nutzt jetzt /media/manifest.
  Future<List<MediaFile>> list() => manifest();

  /// Lädt eine einzelne Datei herunter und gibt die rohen Bytes zurück.
  Future<http.Response> download(String name) async {
    final uri = downloadUri(name);
    return _http != null
        ? _http.get(uri).timeout(const Duration(seconds: 60))
        : http.get(uri).timeout(const Duration(seconds: 60));
  }

  /// Lädt eine Datei zum Server hoch.
  Future<MediaFile> upload(String filename, List<int> bytes) async {
    final req = http.MultipartRequest('POST', _u('/media/upload'))
      ..files
          .add(http.MultipartFile.fromBytes('file', bytes, filename: filename));
    final streamed = await (_http ?? http.Client())
        .send(req)
        .timeout(const Duration(seconds: 60));
    final resp = await http.Response.fromStream(streamed);
    if (resp.statusCode != 200) {
      throw HttpException(
          'upload fehlgeschlagen (HTTP ${resp.statusCode}): ${resp.body}');
    }
    return MediaFile.fromJson(jsonDecode(resp.body) as Map<String, dynamic>);
  }

  /// Löscht eine Datei auf dem Server.
  Future<void> delete(String filename) async {
    final resp = await (_http != null
            ? _http.delete(_u('/media/${Uri.encodeComponent(filename)}'))
            : http.delete(_u('/media/${Uri.encodeComponent(filename)}')))
        .timeout(const Duration(seconds: 10));
    if (resp.statusCode != 200 && resp.statusCode != 404) {
      throw HttpException('löschen fehlgeschlagen (HTTP ${resp.statusCode})');
    }
  }
}
