import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../embedded/embedded_server.dart';
import '../grpc/stage_sync_client.dart';
import '../grpc/generated/stagesync/v1/common.pb.dart';
import '../preferences/device_preferences.dart';
import 'audio_node_provider.dart';
import 'embedded_server_provider.dart';
import 'session_provider.dart';

/// Ob der automatische Standalone-Start unterstützt wird (Desktop + embedded server).
final isStandaloneSupportedProvider = Provider<bool>(
  (_) => EmbeddedServer.isSupported,
);

/// Führt den automatischen Standalone-Start durch:
///   1. Wartet auf den eingebetteten Go-Server.
///   2. Verbindet sich mit localhost:50051.
///   3. Erstellt eine lokale Session mit Master + Audio-Tasks.
///   4. Startet den Audio-Node mit dem bevorzugten Ausgabegerät.
///
/// Gibt [true] zurück wenn der Start vollständig erfolgreich war,
/// [false] wenn ein nicht-fataler Fehler aufgetreten ist (Audio-Start
/// fehlgeschlagen, aber Session ist trotzdem aktiv).
/// Wirft eine Exception wenn der Server oder die Session nicht erreichbar ist.
final standaloneBootstrapProvider = FutureProvider<bool>((ref) async {
  if (!EmbeddedServer.isSupported) return false;

  // 1. Embedded server hochfahren lassen.
  final serverOk = await ref.watch(embeddedServerProvider.future);
  if (!serverOk) throw Exception('Embedded server konnte nicht gestartet werden.');

  // 2. Geräte-Identität laden.
  final prefs = await DevicePreferences.loadConnectDefaults();
  final deviceId = await DevicePreferences.getDeviceId();
  final deviceName = prefs.deviceName.isNotEmpty
      ? prefs.deviceName
      : _defaultDeviceName(deviceId);

  // 3. Mit lokalem Server verbinden.
  final port = ref.read(embeddedPortProvider);
  await StageSyncClient.instance.connect('127.0.0.1', port);

  // 4. Lokale Session erstellen (Master + Audio).
  await ref.read(sessionProvider.notifier).createSession(
    host: '127.0.0.1',
    port: port,
    sessionName: 'Lokale Session',
    showName: 'Meine Show',
    deviceName: deviceName,
    nodeType: NodeType.NODE_TYPE_MASTER,
    tasks: [NodeTask.NODE_TASK_MASTER, NodeTask.NODE_TASK_AUDIO_OUTPUT],
    password: '',
    persistent: false,
    deviceId: deviceId,
  );

  final session = ref.read(sessionProvider);
  if (!session.isInSession) {
    throw Exception('Session konnte nicht erstellt werden.');
  }

  // 5. Audio-Node mit Standard-Ausgabegerät starten.
  try {
    await ref.read(audioNodeProvider.notifier).startAudioNode();
  } catch (_) {
    // Audio-Fehler nicht fatal — App ist trotzdem nutzbar.
    return false;
  }

  return true;
});

String _defaultDeviceName(String deviceId) {
  final suffix = deviceId.substring(deviceId.length.clamp(4, deviceId.length) - 4).toUpperCase();
  try {
    return '${Platform.localHostname} ($suffix)';
  } catch (_) {
    return 'Gerät $suffix';
  }
}
