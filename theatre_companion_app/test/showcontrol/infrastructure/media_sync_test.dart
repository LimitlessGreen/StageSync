import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;

import 'package:theatre_companion_app/showcontrol/media/media_grpc_client.dart';
import 'package:theatre_companion_app/showcontrol/media/media_sync.dart';
import 'package:theatre_companion_app/showcontrol/media/server_media_client.dart'
    show MediaFile;

// ── Helpers ───────────────────────────────────────────────────────────────────

/// Builds a [MediaFile] for testing.
MediaFile _file(String name, String sha256, {int sizeBytes = 4}) =>
    MediaFile(name: name, sha256: sha256, sizeBytes: sizeBytes, modifiedMs: 0);

/// A [FakeMediaGrpcClient] that always throws on [streamFile].
class _FailingMediaGrpcClient extends FakeMediaGrpcClient {
  _FailingMediaGrpcClient() : super({});

  @override
  Future<Uint8List> streamFile({
    String? assetId,
    String? name,
    int offset = 0,
    void Function(int, int)? onProgress,
  }) async {
    throw Exception('Simulated server failure');
  }
}

/// Wraps a [FakeMediaGrpcClient] and counts [streamFile] calls.
class _TrackingGrpcClient extends FakeMediaGrpcClient {
  final FakeMediaGrpcClient _inner;
  final void Function() onDownload;

  _TrackingGrpcClient(this._inner, {required this.onDownload})
      : super(_inner.files);

  @override
  Future<Uint8List> streamFile({
    String? assetId,
    String? name,
    int offset = 0,
    void Function(int, int)? onProgress,
  }) {
    onDownload();
    return _inner.streamFile(
        assetId: assetId, name: name, offset: offset, onProgress: onProgress);
  }
}

/// Sets up a [MediaSync] with a temporary cache directory.
Future<(MediaSync, String)> _setup({
  Map<String, List<int>> files = const {},
}) async {
  final tmp = await Directory.systemTemp.createTemp('media_sync_test_');
  final fakeFiles = {
    for (final e in files.entries) e.key: Uint8List.fromList(e.value)
  };
  final client = FakeMediaGrpcClient(fakeFiles);
  final sync = MediaSync(client, tmp.path);
  return (sync, tmp.path);
}

// ── Tests ─────────────────────────────────────────────────────────────────────

void main() {
  group('MediaSync — syncAllFromList', () {
    test('downloads only files missing locally', () async {
      final fileContent = [1, 2, 3, 4];
      final (sync, cacheDir) =
          await _setup(files: {'intro.wav': fileContent});
      addTearDown(() => Directory(cacheDir).deleteSync(recursive: true));

      await sync.syncAllFromList([_file('intro.wav', 'sha-abc')]);

      final local = File(p.join(cacheDir, 'intro.wav'));
      expect(local.existsSync(), isTrue);
      expect(local.readAsBytesSync(), fileContent);
    });

    test('skips files already present with matching sha256', () async {
      final (sync, cacheDir) =
          await _setup(files: {'existing.wav': [9, 8, 7]});
      addTearDown(() => Directory(cacheDir).deleteSync(recursive: true));

      final localFile = File(p.join(cacheDir, 'existing.wav'));
      await localFile.writeAsBytes([9, 8, 7]);
      final manifestFile = File(p.join(cacheDir, '.manifest.json'));
      await manifestFile.writeAsString('{"existing.wav":"sha-xyz"}');

      final beforeSync = await localFile.lastModified();
      await Future.delayed(const Duration(milliseconds: 5));

      await sync.syncAllFromList([_file('existing.wav', 'sha-xyz')]);

      final afterSync = await localFile.lastModified();
      expect(afterSync, beforeSync,
          reason: 'file should not have been re-downloaded');
    });

    test('re-downloads files with changed sha256', () async {
      final newContent = [0xDE, 0xAD, 0xBE, 0xEF];
      final (sync, cacheDir) =
          await _setup(files: {'changed.wav': newContent});
      addTearDown(() => Directory(cacheDir).deleteSync(recursive: true));

      final localFile = File(p.join(cacheDir, 'changed.wav'));
      await localFile.writeAsBytes([1, 2]);
      final manifestFile = File(p.join(cacheDir, '.manifest.json'));
      await manifestFile.writeAsString('{"changed.wav":"sha-old"}');

      await sync.syncAllFromList([_file('changed.wav', 'sha-new')]);

      expect(localFile.readAsBytesSync(), newContent);
    });

    test('prunes local files absent from server manifest', () async {
      final (sync, cacheDir) = await _setup(files: {'file-b.wav': [2]});
      addTearDown(() => Directory(cacheDir).deleteSync(recursive: true));

      final staleFile = File(p.join(cacheDir, 'file-a.wav'));
      await staleFile.writeAsBytes([1]);
      final manifestFile = File(p.join(cacheDir, '.manifest.json'));
      await manifestFile.writeAsString(
          '{"file-a.wav":"sha-a","file-b.wav":"sha-b-old"}');

      await sync.syncAllFromList([_file('file-b.wav', 'sha-b')]);

      expect(staleFile.existsSync(), isFalse,
          reason: 'file-a.wav was removed from server → must be pruned');
      expect(File(p.join(cacheDir, 'file-b.wav')).existsSync(), isTrue);
    });

    test('manifest preserved after sync', () async {
      final (sync, cacheDir) =
          await _setup(files: {'a.wav': [1], 'b.wav': [2]});
      addTearDown(() => Directory(cacheDir).deleteSync(recursive: true));

      await sync.syncAllFromList([
        _file('a.wav', 'sha-a'),
        _file('b.wav', 'sha-b'),
      ]);

      final manifestFile = File(p.join(cacheDir, '.manifest.json'));
      expect(manifestFile.existsSync(), isTrue);
      final saved = manifestFile.readAsStringSync();
      expect(saved, contains('a.wav'));
      expect(saved, contains('sha-a'));
      expect(saved, contains('b.wav'));
      expect(saved, contains('sha-b'));
    });

    test('server unreachable: syncAllFromList does not throw', () async {
      final tmp =
          await Directory.systemTemp.createTemp('media_sync_fail_');
      addTearDown(() => tmp.deleteSync(recursive: true));
      final sync = MediaSync(_FailingMediaGrpcClient(), tmp.path);

      await expectLater(
        sync.syncAllFromList([_file('track.wav', 'sha-t')]),
        completes,
      );
    });

    test('concurrent syncAllFromList calls are serialised', () async {
      var downloadCount = 0;
      final inner = FakeMediaGrpcClient(
          {'track.wav': Uint8List.fromList([0])});
      final trackingClient =
          _TrackingGrpcClient(inner, onDownload: () => downloadCount++);
      final tmp =
          await Directory.systemTemp.createTemp('media_sync_conc_');
      addTearDown(() => tmp.deleteSync(recursive: true));
      final sync = MediaSync(trackingClient, tmp.path);

      final manifest = [_file('track.wav', 'sha-t')];
      await Future.wait([
        sync.syncAllFromList(manifest),
        sync.syncAllFromList(manifest),
      ]);

      expect(downloadCount, lessThanOrEqualTo(1),
          reason:
              'concurrent syncAllFromList must not trigger duplicate downloads');
    });
  });

  group('MediaSync — ensureLocal (lazy-fetch)', () {
    test('returns local path when file already present', () async {
      final (sync, cacheDir) = await _setup(files: {});
      addTearDown(() => Directory(cacheDir).deleteSync(recursive: true));

      final local = File(p.join(cacheDir, 'present.wav'));
      await local.writeAsBytes([5, 6, 7]);

      final result = await sync.ensureLocal('present.wav');
      expect(result, local.path);
    });

    test('fetches and returns path when file is missing', () async {
      final (sync, cacheDir) =
          await _setup(files: {'lazy.wav': [1, 2, 3]});
      addTearDown(() => Directory(cacheDir).deleteSync(recursive: true));

      final result = await sync.ensureLocal('lazy.wav');
      expect(result, isNotNull);
      expect(File(result!).existsSync(), isTrue);
      expect(File(result).readAsBytesSync(), [1, 2, 3]);
    });

    test('returns null when file not found on server', () async {
      final (sync, cacheDir) = await _setup(files: {});
      addTearDown(() => Directory(cacheDir).deleteSync(recursive: true));

      final result = await sync.ensureLocal('ghost.wav');
      expect(result, isNull);
    });

    test('accepts legacy absolute paths that exist on disk', () async {
      final (sync, cacheDir) = await _setup(files: {});
      addTearDown(() => Directory(cacheDir).deleteSync(recursive: true));

      final file = File(p.join(cacheDir, 'abs.wav'));
      await file.writeAsBytes([9]);

      final result = await sync.ensureLocal(file.path);
      expect(result, file.path);
    });

    test('duplicate ensureLocal calls use inflight dedup', () async {
      var downloadCount = 0;
      final inner = FakeMediaGrpcClient(
          {'dup.wav': Uint8List.fromList([42])});
      final trackingClient =
          _TrackingGrpcClient(inner, onDownload: () => downloadCount++);
      final tmp =
          await Directory.systemTemp.createTemp('media_sync_dedup_');
      addTearDown(() => tmp.deleteSync(recursive: true));
      final sync = MediaSync(trackingClient, tmp.path);

      final results = await Future.wait([
        sync.ensureLocal('dup.wav'),
        sync.ensureLocal('dup.wav'),
      ]);

      expect(downloadCount, 1,
          reason: 'inflight dedup must prevent double download');
      expect(results[0], results[1]);
    });
  });

  group('MediaSync — filenameForSha256', () {
    test('returns filename when sha256 is known', () async {
      final (sync, cacheDir) =
          await _setup(files: {'track.wav': [1]});
      addTearDown(() => Directory(cacheDir).deleteSync(recursive: true));
      await sync.syncAllFromList([_file('track.wav', 'sha-track')]);
      expect(sync.filenameForSha256('sha-track'), 'track.wav');
    });

    test('returns null for unknown sha256', () async {
      final (sync, cacheDir) = await _setup(files: {});
      addTearDown(() => Directory(cacheDir).deleteSync(recursive: true));
      expect(sync.filenameForSha256('unknown-sha'), isNull);
    });
  });
}
