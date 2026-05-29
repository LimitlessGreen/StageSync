import 'package:fixnum/fixnum.dart';
import 'package:grpc/grpc.dart';

import '../grpc/stage_sync_client.dart';
import '../grpc/generated/stagesync/v1/session.pb.dart';
import '../grpc/generated/stagesync/v1/common.pb.dart';

/// Ergebnis einer Session-Operation.
class SessionResult {
  final Session session;
  final String token;
  final NodeInfo assignedNode;

  const SessionResult({
    required this.session,
    required this.token,
    required this.assignedNode,
  });
}

/// Kapselt alle Session-Operationen gegen den StageSync-Server.
class SessionService {
  final StageSyncClient _client;

  SessionService({StageSyncClient? client})
      : _client = client ?? StageSyncClient.instance;

  /// Erstellt eine neue Session (dieses Gerät wird Master).
  Future<SessionResult> createSession({
    required String sessionName,
    required String showName,
    required NodeInfo myNode,
    String password = '',
    bool persistent = false,
  }) async {
    final req = CreateSessionRequest()
      ..sessionName = sessionName
      ..showName = showName
      ..myNode = myNode
      ..password = password
      ..persistent = persistent;

    try {
      final resp = await _client.session.createSession(req);
      return SessionResult(
        session: resp.session,
        token: resp.token,
        assignedNode: resp.assignedNode,
      );
    } on GrpcError catch (e) {
      throw _mapGrpcError(e);
    }
  }

  /// Tritt einer bestehenden Session bei.
  Future<SessionResult> joinSession({
    required String sessionId,
    required NodeInfo myNode,
    String password = '',
  }) async {
    final req = JoinSessionRequest()
      ..sessionId = sessionId
      ..myNode = myNode
      ..password = password;

    try {
      final resp = await _client.session.joinSession(req);
      return SessionResult(
        session: resp.session,
        token: resp.token,
        assignedNode: resp.assignedNode,
      );
    } on GrpcError catch (e) {
      throw _mapGrpcError(e);
    }
  }

  /// Verlässt eine Session.
  Future<void> leaveSession({
    required String sessionId,
    required String nodeId,
    required String token,
  }) async {
    final req = LeaveSessionRequest()
      ..sessionId = sessionId
      ..nodeId = nodeId
      ..token = token;

    await _client.session.leaveSession(req);
  }

  /// Sendet einen Heartbeat (sollte alle 5 Sekunden aufgerufen werden).
  /// Gibt die Antwort zurück (u.a. server_unix_millis für Clock-Sync).
  Future<HeartbeatResponse> heartbeat({
    required String sessionId,
    required String nodeId,
    required String token,
  }) async {
    final req = HeartbeatRequest()
      ..sessionId = sessionId
      ..nodeId = nodeId
      ..token = token
      ..unixMillis = Int64(DateTime.now().millisecondsSinceEpoch);

    return _client.session.heartbeat(req);
  }

  /// Stream von Session-Events (Node-Join/Leave, Master-Wechsel, etc.).
  Stream<SessionEvent> watchSession({
    required String sessionId,
    required String nodeId,
    required String token,
  }) {
    final req = WatchSessionRequest()
      ..sessionId = sessionId
      ..nodeId = nodeId
      ..token = token;

    return _client.session.watchSession(req);
  }

  /// Listet alle aktiven Sessions im Netz auf.
  Future<List<Session>> listSessions() async {
    final resp = await _client.session.listSessions(ListSessionsRequest());
    return resp.sessions;
  }

  Exception _mapGrpcError(GrpcError e) {
    return switch (e.code) {
      StatusCode.unauthenticated => SessionAuthException(e.message ?? 'Auth failed'),
      StatusCode.notFound        => SessionNotFoundException(e.message ?? 'Not found'),
      _                          => SessionException(e.message ?? 'Unknown error'),
    };
  }
}

class SessionException implements Exception {
  final String message;
  const SessionException(this.message);
  @override String toString() => 'SessionException: $message';
}

class SessionAuthException extends SessionException {
  const SessionAuthException(super.message);
}

class SessionNotFoundException extends SessionException {
  const SessionNotFoundException(super.message);
}
