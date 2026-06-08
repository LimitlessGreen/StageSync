import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';

import '../embedded/embedded_server.dart';

const _kDefaultEmbeddedPort = 50051;

/// Ob die App auf einer Plattform läuft, die den eingebetteten Server
/// unterstützt (Desktop: Windows/macOS/Linux).
final isEmbeddedSupportedProvider = Provider<bool>(
  (_) => EmbeddedServer.isSupported,
);

/// Startet den eingebetteten Go-gRPC-Server beim ersten Zugriff.
///
/// - Desktop: Server wird in `{appDocuments}/StageSync/server-data` gestartet.
/// - Mobile: Gibt sofort [false] zurück (kein Embedding möglich).
///
/// Auf den Provider aus [ProviderScope] per `ref.watch` oder `ref.read` zugreifen;
/// er stellt sicher dass der Server vor der ersten Session-Operation läuft.
final embeddedServerProvider = FutureProvider<bool>((ref) async {
  if (!EmbeddedServer.isSupported) return false;

  final appDir = await getApplicationDocumentsDirectory();
  final dataDir = '${appDir.path}${Platform.pathSeparator}StageSync'
      '${Platform.pathSeparator}server-data';
  await Directory(dataDir).create(recursive: true);

  final ok = await EmbeddedServer.instance.start(
    port: _kDefaultEmbeddedPort,
    dataDir: dataDir,
  );

  ref.onDispose(EmbeddedServer.instance.stop);
  return ok;
});

/// Der Port des lokalen eingebetteten Servers (nur gültig wenn
/// [embeddedServerProvider] [true] geliefert hat).
final embeddedPortProvider = Provider<int>(
  (_) => EmbeddedServer.isSupported ? _kDefaultEmbeddedPort : 0,
);

/// True wenn der eingebettete Server gerade läuft.
final embeddedServerRunningProvider = Provider<bool>(
  (_) => EmbeddedServer.instance.isRunning,
);
