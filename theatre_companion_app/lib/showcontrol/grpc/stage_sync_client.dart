import 'package:grpc/grpc.dart';
import 'package:grpc/grpc_or_grpcweb.dart';

import 'generated/stagesync/v1/session.pbgrpc.dart';
import 'generated/stagesync/v1/showcontrol.pbgrpc.dart';
import 'generated/stagesync/v1/node.pbgrpc.dart';
import 'generated/stagesync/v1/media.pbgrpc.dart';
import 'generated/stagesync/v1/talkback.pbgrpc.dart';
import 'generated/stagesync/v1/grid.pbgrpc.dart';

/// Verbindungszustand des Clients.
enum StageSyncConnectionState { disconnected, connecting, connected, error }

/// Zentraler gRPC-Client für alle StageSync-Services.
/// Singleton — über [StageSyncClient.instance] zugreifen.
class StageSyncClient {
  StageSyncClient._();
  static final StageSyncClient instance = StageSyncClient._();

  GrpcOrGrpcWebClientChannel? _channel;
  String? _host;
  int? _port;

  late SessionServiceClient session;
  late ShowControlServiceClient showControl;
  late NodeServiceClient node;
  late MediaServiceClient media;
  late TalkbackServiceClient talkback;
  late GridServiceClient grid;

  // Session-Kontext für MediaService-Aufrufe (werden nach dem Join gesetzt).
  String? sessionId;
  String? token;

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

    // On native platforms this opens a plain gRPC (HTTP/2) channel; on the
    // web it transparently uses gRPC-Web (XHR) against the same host/port,
    // which the Go server exposes via the -web-ui flag.
    _channel = GrpcOrGrpcWebClientChannel.grpc(
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
    media = MediaServiceClient(_channel!);
    talkback = TalkbackServiceClient(_channel!);
    grid = GridServiceClient(_channel!);

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
