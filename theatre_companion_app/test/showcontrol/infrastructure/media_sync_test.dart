import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:path/path.dart' as p;

import 'package:theatre_companion_app/showcontrol/media/media_sync.dart';
import 'package:theatre_companion_app/showcontrol/media/server_media_client.dart';

// ── Helpers ───────────────────────────────────────────────────────────────────

const _baseUrl = 'http://localhost:50053';

/// Builds a manifest JSON response body.
String _manifestJson(List<Map<String, dynamic>> files) => jsonEncode(files);

Map<String, dynamic> _file(String name, String sha256,
        {int sizeBytes = 1024}) =>
    {'name': name, 'sha256': sha256, 'size_bytes': sizeBytes, 'modified_ms': 0};

/// Creates a [MockClient] that serves a static manifest and per-file downloads.
/// [files]: name → bytes content
MockClient _mockHttp({
  required List<Map<String, dynamic>> manifest,
  Map<String, List<int>> files = const {},
  int manifestStatus = 200,
}) {
  return MockClient((request) async {
    if (request.url.path == '/media/manifest') {
      return http.Response(
        _manifestJson(manifest),
        manifestStatus,
        headers: {'content-type': 'application/json'},
      );
    }
    // /media/download/<name>
    if (request.url.path.startsWith('/media/download/')) {
      final name = Uri.decodeComponent(
          request.url.path.replaceFirst('/media/download/', ''));
      final content = files[name];
      if (content != null) return http.Response.bytes(content, 200);
      return http.Response('not found', 404);
    }
    return http.Response('unexpected: ${request.url}', 500);
  });
}

/// Sets up a MediaSync instance with a temporary cache directory.
/// Returns (sync, cacheDir). Caller must clean up cacheDir.
Future<(MediaSync, String)> _setup({
  required List<Map<String, dynamic>> manifest,
  Map<String, List<int>> files = const {},
  int manifestStatus = 200,
}) async {
  final tmp = await Directory.systemTemp.createTemp('media_sync_test_');
  final client = ServerMediaClient(
    _baseUrl,
    httpClient: _mockHttp(
      manifest: manifest,
      files: files,
      manifestStatus: manifestStatus,
    ),
  );
  final sync = MediaSync(client, tmp.path);
  return (sync, tmp.path);
}

// ── Tests ─────────────────────────────────────────────────────────────────────

void main() {
  group('MediaSync — manifest-based sync', () {
    test('downloads only files missing locally', () async {
      final fileContent = [1, 2, 3, 4];
      final (sync, cacheDir) = await _setup(
        manifest: [_file('intro.wav', 'sha-abc')],
        files: {'intro.wav': fileContent},
      );
      addTearDown(() => Directory(cacheDir).deleteSync(recursive: true));

      await sync.syncAll();

      final local = File(p.join(cacheDir, 'intro.wav'));
      expect(local.existsSync(), isTrue);
      expect(local.readAsBytesSync(), fileContent);
    });

    test('skips files already present with matching sha256', () async {
      final (sync, cacheDir) = await _setup(
        manifest: [_file('existing.wav', 'sha-xyz')],
        files: {'existing.wav': [9, 8, 7]},
      );
      addTearDown(() => Directory(cacheDir).deleteSync(recursive: true));

      // Pre-populate: write the file and the manifest so sha256 matches.
      final localFile = File(p.join(cacheDir, 'existing.wav'));
      await localFile.writeAsBytes([9, 8, 7]);
      final manifestFile = File(p.join(cacheDir, '.manifest.json'));
      await manifestFile.writeAsString(jsonEncode({'existing.wav': 'sha-xyz'}));

      // Track modification time to verify no re-download happened.
      final beforeSync = await localFile.lastModified();
      // Give the filesystem at least 1 ms resolution.
      await Future.delayed(const Duration(milliseconds: 5));

      await sync.syncAll();

      final afterSync = await localFile.lastModified();
      expect(afterSync, beforeSync,
          reason: 'file should not have been re-downloaded');
    });

    test('re-downloads files with changed sha256', () async {
      final newContent = [0xDE, 0xAD, 0xBE, 0xEF];
      final (sync, cacheDir) = await _setup(
        manifest: [_file('changed.wav', 'sha-new')],
        files: {'changed.wav': newContent},
      );
      addTearDown(() => Directory(cacheDir).deleteSync(recursive: true));

      // Pre-populate with wrong sha.
      final localFile = File(p.join(cacheDir, 'changed.wav'));
      await localFile.writeAsBytes([1, 2]);
      final manifestFile = File(p.join(cacheDir, '.manifest.json'));
      await manifestFile.writeAsString(jsonEncode({'changed.wav': 'sha-old'}));

      await sync.syncAll();

      expect(localFile.readAsBytesSync(), newContent);
    });

    test('prunes local files absent from server manifest', () async {
      final (sync, cacheDir) = await _setup(
        // Server has only file-b; file-a was deleted on server.
        manifest: [_file('file-b.wav', 'sha-b')],
        files: {'file-b.wav': [2]},
      );
      addTearDown(() => Directory(cacheDir).deleteSync(recursive: true));

      // Pre-populate stale file-a.
      final staleFile = File(p.join(cacheDir, 'file-a.wav'));
      await staleFile.writeAsBytes([1]);
      final manifestFile = File(p.join(cacheDir, '.manifest.json'));
      await manifestFile
          .writeAsString(jsonEncode({'file-a.wav': 'sha-a', 'file-b.wav': 'sha-b-old'}));

      await sync.syncAll();

      expect(staleFile.existsSync(), isFalse,
          reason: 'file-a.wav was removed from server → must be pruned');
      expect(File(p.join(cacheDir, 'file-b.wav')).existsSync(), isTrue);
    });

    test('manifest preserved after sync', () async {
      final (sync, cacheDir) = await _setup(
        manifest: [
          _file('a.wav', 'sha-a'),
          _file('b.wav', 'sha-b'),
        ],
        files: {
          'a.wav': [1],
          'b.wav': [2],
        },
      );
      addTearDown(() => Directory(cacheDir).deleteSync(recursive: true));

      await sync.syncAll();

      final manifestFile = File(p.join(cacheDir, '.manifest.json'));
      expect(manifestFile.existsSync(), isTrue);
      final saved =
          jsonDecode(await manifestFile.readAsString()) as Map<String, dynamic>;
      expect(saved['a.wav'], 'sha-a');
      expect(saved['b.wav'], 'sha-b');
    });

    test('server unreachable: logs and returns without throwing', () async {
      final (sync, cacheDir) = await _setup(
        manifest: [],
        manifestStatus: 500,
      );
      addTearDown(() => Directory(cacheDir).deleteSync(recursive: true));

      // Should not throw.
      await expectLater(sync.syncAll(), completes);
    });

    test('concurrent syncAll calls are serialised (only one runs at a time)',
        () async {
      var downloadCount = 0;
      final client = ServerMediaClient(
        _baseUrl,
        httpClient: MockClient((request) async {
          if (request.url.path == '/media/manifest') {
            return http.Response(
              _manifestJson([_file('track.wav', 'sha-t')]),
              200,
              headers: {'content-type': 'application/json'},
            );
          }
          downloadCount++;
          await Future.delayed(const Duration(milliseconds: 10));
          return http.Response.bytes([0], 200);
        }),
      );
      final tmp = await Directory.systemTemp.createTemp('media_sync_conc_');
      addTearDown(() => tmp.deleteSync(recursive: true));
      final sync = MediaSync(client, tmp.path);

      // Fire two concurrent syncs — only one download should happen
      // because the second call returns the already-running Future.
      await Future.wait([sync.syncAll(), sync.syncAll()]);

      expect(downloadCount, 1,
          reason: 'concurrent syncAll must not trigger duplicate downloads');
    });
  });

  group('MediaSync — ensureLocal (lazy-fetch)', () {
    test('returns local path when file already present', () async {
      final (sync, cacheDir) = await _setup(
        manifest: [],
        files: {'present.wav': [5, 6, 7]},
      );
      addTearDown(() => Directory(cacheDir).deleteSync(recursive: true));

      final local = File(p.join(cacheDir, 'present.wav'));
      await local.writeAsBytes([5, 6, 7]);

      final result = await sync.ensureLocal('present.wav');
      expect(result, local.path);
    });

    test('fetches and returns path when file is missing', () async {
      final (sync, cacheDir) = await _setup(
        manifest: [],
        files: {'lazy.wav': [1, 2, 3]},
      );
      addTearDown(() => Directory(cacheDir).deleteSync(recursive: true));

      final result = await sync.ensureLocal('lazy.wav');
      expect(result, isNotNull);
      expect(File(result!).existsSync(), isTrue);
      expect(File(result).readAsBytesSync(), [1, 2, 3]);
    });

    test('returns null when file not found on server', () async {
      final (sync, cacheDir) = await _setup(manifest: [], files: {});
      addTearDown(() => Directory(cacheDir).deleteSync(recursive: true));

      final result = await sync.ensureLocal('ghost.wav');
      expect(result, isNull);
    });

    test('accepts legacy absolute paths that exist on disk', () async {
      final (sync, cacheDir) = await _setup(manifest: [], files: {});
      addTearDown(() => Directory(cacheDir).deleteSync(recursive: true));

      final file = File(p.join(cacheDir, 'abs.wav'));
      await file.writeAsBytes([9]);

      final result = await sync.ensureLocal(file.path);
      expect(result, file.path);
    });

    test('duplicate ensureLocal calls use inflight dedup', () async {
      var downloadCount = 0;
      final client = ServerMediaClient(
        _baseUrl,
        httpClient: MockClient((request) async {
          if (request.url.path == '/media/manifest') {
            return http.Response('[]', 200,
                headers: {'content-type': 'application/json'});
          }
          downloadCount++;
          await Future.delayed(const Duration(milliseconds: 10));
          return http.Response.bytes([42], 200);
        }),
      );
      final tmp = await Directory.systemTemp.createTemp('media_sync_dedup_');
      addTearDown(() => tmp.deleteSync(recursive: true));
      final sync = MediaSync(client, tmp.path);

      final results =
          await Future.wait([sync.ensureLocal('dup.wav'), sync.ensureLocal('dup.wav')]);

      expect(downloadCount, 1, reason: 'inflight dedup must prevent double download');
      expect(results[0], results[1]);
    });
  });

  group('ServerMediaClient — manifest parsing', () {
    test('parses manifest with audio metadata', () async {
      final manifest = jsonEncode([
        {
          'name': 'track.wav',
          'sha256': 'abc123',
          'size_bytes': 2048,
          'modified_ms': 0,
          'mime_type': 'audio/wav',
          'audio': {
            'duration_ms': 30000,
            'channels': 2,
            'sample_rate': 48000,
            'bit_depth': 24,
          },
        }
      ]);
      final client = ServerMediaClient(
        _baseUrl,
        httpClient: MockClient((_) async => http.Response(manifest, 200,
            headers: {'content-type': 'application/json'})),
      );
      final files = await client.manifest();
      expect(files, hasLength(1));
      expect(files.first.name, 'track.wav');
      expect(files.first.sha256, 'abc123');
      expect(files.first.audio?.sampleRate, 48000);
      expect(files.first.audio?.channels, 2);
    });

    test('parses manifest without audio metadata', () async {
      final manifest = jsonEncode([
        {'name': 'script.ogg', 'sha256': 'xyz', 'size_bytes': 100, 'modified_ms': 0}
      ]);
      final client = ServerMediaClient(
        _baseUrl,
        httpClient: MockClient((_) async => http.Response(manifest, 200,
            headers: {'content-type': 'application/json'})),
      );
      final files = await client.manifest();
      expect(files.first.audio, isNull);
    });

    test('throws HttpException on non-200 response', () async {
      final client = ServerMediaClient(
        _baseUrl,
        httpClient: MockClient((_) async => http.Response('error', 503)),
      );
      expect(client.manifest(), throwsA(isA<HttpException>()));
    });
  });
}
