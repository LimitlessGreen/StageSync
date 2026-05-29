import 'package:grpc/grpc.dart';

import 'generated/stagesync/v1/session.pbgrpc.dart';
import 'generated/stagesync/v1/showcontrol.pbgrpc.dart';
import 'generated/stagesync/v1/node.pbgrpc.dart';

/// Verbindungszustand des Clients.
enum StageSyncConnectionState { disconnected, connecting, connected, error }

/// Zentraler gRPC-Client für alle StageSync-Services.
/// Singleton — über [StageSyncClient.instance] zugreifen.
class StageSyncClient {
  StageSyncClient._();
  static final StageSyncClient instance = StageSyncClient._();

  ClientChannel? _channel;
  String? _host;
  int? _port;

  late SessionServiceClient session;
  late ShowControlServiceClient showControl;
  late NodeServiceClient node;

  StageSyncConnectionState _state = StageSyncConnectionState.disconnected;
  StageSyncConnectionState get state => _state;

  /// Host des aktuell verbundenen Servers (null wenn nicht verbunden).
  String? get serverHost => _host;

  /// Verbindet mit dem StageSync-Server.
  Future<void> connect(String host, int port) async {
    if (_state == StageSyncConnectionState.connected &&
        _host == host &&
        _port == port) {
      return;
    }

    _state = StageSyncConnectionState.connecting;
    _host = host;
    _port = port;

    await _channel?.shutdown();

    _channel = ClientChannel(
      host,
      port: port,
      options: const ChannelOptions(
        credentials: ChannelCredentials.insecure(),
        connectionTimeout: Duration(seconds: 5),
        idleTimeout: Duration(minutes: 5),
        keepAlive: ClientKeepAliveOptions(
          pingInterval: Duration(seconds: 10),
          timeout: Duration(seconds: 5),
        ),
      ),
    );

    session = SessionServiceClient(_channel!);
    showControl = ShowControlServiceClient(_channel!);
    node = NodeServiceClient(_channel!);

    _state = StageSyncConnectionState.connected;
  }

  /// Trennt die Verbindung.
  Future<void> disconnect() async {
    _state = StageSyncConnectionState.disconnected;
    await _channel?.shutdown();
    _channel = null;
  }

  bool get isConnected => _state == StageSyncConnectionState.connected;
}
