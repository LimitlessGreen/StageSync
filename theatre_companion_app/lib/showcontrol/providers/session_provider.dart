import 'dart:async';
import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../grpc/stage_sync_client.dart';
import '../grpc/generated/stagesync/v1/session.pb.dart';
import '../grpc/generated/stagesync/v1/common.pb.dart';
import '../session/session_service.dart';
import '../session/clock_sync.dart';

const _kCredKey = 'stagesync_session_creds';

// ── State-Modell ──────────────────────────────────────────────────────────────

enum ConnectionHealth { connected, reconnecting, disconnected }

class SessionState {
  final Session? session;
  final String? token;
  final NodeInfo? myNode;
  final bool isLoading;
  final String? error;
  final bool needsNodeStart;
  final ConnectionHealth health;

  const SessionState({
    this.session,
    this.token,
    this.myNode,
    this.isLoading = false,
    this.error,
    this.needsNodeStart = false,
    this.health = ConnectionHealth.connected,
  });

  bool get isInSession => session != null && token != null;
  bool get isDisconnected => health == ConnectionHealth.disconnected;
  bool get isReconnecting => health == ConnectionHealth.reconnecting;

  SessionState copyWith({
    Session? session,
    String? token,
    NodeInfo? myNode,
    bool? isLoading,
    String? error,
    bool? needsNodeStart,
    ConnectionHealth? health,
  }) =>
      SessionState(
        session: session ?? this.session,
        token: token ?? this.token,
        myNode: myNode ?? this.myNode,
        isLoading: isLoading ?? this.isLoading,
        error: error,
        needsNodeStart: needsNodeStart ?? this.needsNodeStart,
        health: health ?? this.health,
      );
}

// ── Provider ──────────────────────────────────────────────────────────────────

final sessionServiceProvider = Provider<SessionService>((_) => SessionService());

final sessionProvider =
    StateNotifierProvider<SessionNotifier, SessionState>((ref) {
  return SessionNotifier(ref.read(sessionServiceProvider));
});

// ── Notifier ──────────────────────────────────────────────────────────────────

class SessionNotifier extends StateNotifier<SessionState> {
  final SessionService _service;
  Timer? _heartbeatTimer;
  StreamSubscription<SessionEvent>? _eventSub;
  int _heartbeatFailCount = 0;
  static const _maxHeartbeatFails = 3;

  SessionNotifier(this._service) : super(const SessionState(isLoading: true)) {
    _tryAutoReconnect();
  }

  // ── Persistenz ───────────────────────────────────────────────────────────────

  Future<void> _saveCredentials({
    required String host,
    required int port,
    required String sessionId,
    required String token,
    required String nodeId,
    required String nodeName,
    required int nodeType,
    List<int> nodeTasks = const [],
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _kCredKey,
      jsonEncode({
        'host': host,
        'port': port,
        'session_id': sessionId,
        'token': token,
        'node_id': nodeId,
        'node_name': nodeName,
        'node_type': nodeType,
        'node_tasks': nodeTasks,
      }),
    );
  }

  Future<void> _clearCredentials() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_kCredKey);
  }

  Future<void> _tryAutoReconnect() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_kCredKey);
    if (raw == null) {
      state = const SessionState();
      return;
    }

    try {
      final m = jsonDecode(raw) as Map<String, dynamic>;
      final host = m['host'] as String;
      final port = m['port'] as int;
      final sessionId = m['session_id'] as String;
      final token = m['token'] as String;
      final nodeId = m['node_id'] as String;
      final nodeName = m['node_name'] as String;
      final nodeType =
          NodeType.valueOf(m['node_type'] as int) ?? NodeType.NODE_TYPE_VIEWER;
      final tasks = ((m['node_tasks'] as List?)?.cast<int>() ?? const <int>[])
          .map(NodeTask.valueOf)
          .whereType<NodeTask>()
          .toList();

      await StageSyncClient.instance.connect(host, port);

      // Prüfen, ob das gespeicherte Token noch gültig ist.
      var tokenValid = true;
      try {
        await _service
            .heartbeat(sessionId: sessionId, nodeId: nodeId, token: token)
            .timeout(const Duration(seconds: 5));
      } catch (_) {
        tokenValid = false;
      }

      var activeToken = token;
      var myNode = NodeInfo()
        ..nodeId = nodeId
        ..name = nodeName
        ..nodeType = nodeType
        ..tasks.addAll(tasks);
      Session session;

      if (tokenValid) {
        final sessions = await _service.listSessions();
        session = sessions.firstWhere(
          (s) => s.sessionId == sessionId,
          orElse: () => throw Exception('Session nicht mehr vorhanden'),
        );
      } else {
        // Token ungültig — typisch nach Neustart einer persistenten Session.
        // Erneut beitreten und ein frisches Token holen.
        final result = await _service.joinSession(
          sessionId: sessionId,
          myNode: myNode,
        );
        session = result.session;
        activeToken = result.token;
        myNode = result.assignedNode;
        await _saveCredentials(
          host: host,
          port: port,
          sessionId: session.sessionId,
          token: activeToken,
          nodeId: myNode.nodeId,
          nodeName: myNode.name,
          nodeType: myNode.nodeType.value,
          nodeTasks: myNode.tasks.map((t) => t.value).toList(),
        );
      }

      state = SessionState(
        session: session,
        token: activeToken,
        myNode: myNode,
        needsNodeStart: true,
        health: ConnectionHealth.connected,
      );

      _startHeartbeat();
      await _watchEvents();
    } catch (_) {
      await _clearCredentials();
      state = const SessionState();
    }
  }

  void clearNeedsNodeStart() {
    state = state.copyWith(needsNodeStart: false);
  }

  /// Aktualisiert die mediaServerUrl des eigenen Nodes in der lokalen Session.
  /// Wird direkt nach RegisterNode aufgerufen um die Race Condition zu umgehen.
  void updateMyNodeMediaUrl(String url) {
    final sess = state.session;
    final myId = state.myNode?.nodeId;
    if (sess == null || myId == null || url.isEmpty) return;

    final updatedSession = sess.deepCopy();
    for (final node in updatedSession.nodes) {
      if (node.nodeId == myId) {
        node.mediaServerUrl = url;
        break;
      }
    }
    state = state.copyWith(session: updatedSession);
  }

  // ── Session-Operationen ───────────────────────────────────────────────────────

  Future<void> createSession({
    required String host,
    required int port,
    required String sessionName,
    required String showName,
    required String deviceName,
    required NodeType nodeType,
    List<NodeTask> tasks = const [],
    String password = '',
    bool persistent = false,
  }) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      await StageSyncClient.instance.connect(host, port);

      final myNode = NodeInfo()
        ..name = deviceName
        ..nodeType = nodeType
        ..nodeRole = NodeRole.NODE_ROLE_MASTER
        ..tasks.addAll(tasks);

      final result = await _service.createSession(
        sessionName: sessionName,
        showName: showName,
        myNode: myNode,
        password: password,
        persistent: persistent,
      );

      state = state.copyWith(
        session: result.session,
        token: result.token,
        myNode: result.assignedNode,
        isLoading: false,
        health: ConnectionHealth.connected,
      );

      await _saveCredentials(
        host: host,
        port: port,
        sessionId: result.session.sessionId,
        token: result.token,
        nodeId: result.assignedNode.nodeId,
        nodeName: result.assignedNode.name,
        nodeType: result.assignedNode.nodeType.value,
        nodeTasks: result.assignedNode.tasks.map((t) => t.value).toList(),
      );

      _startHeartbeat();
      await _watchEvents();
    } on SessionException catch (e) {
      state = state.copyWith(isLoading: false, error: e.message);
    }
  }

  Future<void> joinSession({
    required String host,
    required int port,
    required String sessionId,
    required String deviceName,
    required NodeType nodeType,
    List<NodeTask> tasks = const [],
    String password = '',
  }) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      await StageSyncClient.instance.connect(host, port);

      final myNode = NodeInfo()
        ..name = deviceName
        ..nodeType = nodeType
        ..tasks.addAll(tasks);

      final result = await _service.joinSession(
        sessionId: sessionId,
        myNode: myNode,
        password: password,
      );

      state = state.copyWith(
        session: result.session,
        token: result.token,
        myNode: result.assignedNode,
        isLoading: false,
        health: ConnectionHealth.connected,
      );

      await _saveCredentials(
        host: host,
        port: port,
        sessionId: result.session.sessionId,
        token: result.token,
        nodeId: result.assignedNode.nodeId,
        nodeName: result.assignedNode.name,
        nodeType: result.assignedNode.nodeType.value,
        nodeTasks: result.assignedNode.tasks.map((t) => t.value).toList(),
      );

      _startHeartbeat();
      await _watchEvents();
    } on SessionException catch (e) {
      state = state.copyWith(isLoading: false, error: e.message);
    }
  }

  Future<void> leaveSession() async {
    final s = state;
    if (!s.isInSession) return;

    state = const SessionState();
    _heartbeatTimer?.cancel();
    _heartbeatTimer = null;
    _eventSub?.cancel();
    _eventSub = null;
    _heartbeatFailCount = 0;
    ClockSync.instance.reset();

    try {
      await _service
          .leaveSession(
            sessionId: s.session!.sessionId,
            nodeId: s.myNode!.nodeId,
            token: s.token!,
          )
          .timeout(const Duration(seconds: 3));
    } catch (_) {}

    await _clearCredentials();

    try {
      await StageSyncClient.instance.disconnect();
    } catch (_) {}
  }

  // ── Heartbeat ─────────────────────────────────────────────────────────────────

  void _startHeartbeat() {
    _heartbeatTimer?.cancel();
    _heartbeatFailCount = 0;
    // Sofort einmal senden, damit der Clock-Offset nicht erst nach 5 s steht.
    _sendHeartbeat();
    _heartbeatTimer =
        Timer.periodic(const Duration(seconds: 5), (_) => _sendHeartbeat());
  }

  Future<void> _sendHeartbeat() async {
    final s = state;
    if (!s.isInSession) return;
    try {
      final t0 = DateTime.now().millisecondsSinceEpoch;
      final resp = await _service
          .heartbeat(
            sessionId: s.session!.sessionId,
            nodeId: s.myNode!.nodeId,
            token: s.token!,
          )
          .timeout(const Duration(seconds: 4));
      final t3 = DateTime.now().millisecondsSinceEpoch;

      // Clock-Sync gegen die Server-Uhr aktualisieren.
      ClockSync.instance.update(
        t0: t0,
        serverMs: resp.serverUnixMillis.toInt(),
        t3: t3,
      );

      _heartbeatFailCount = 0;
      if (s.health != ConnectionHealth.connected) {
        state = state.copyWith(health: ConnectionHealth.connected);
        // Stream neu aufbauen nach Reconnect
        await _watchEvents();
      }
    } catch (_) {
      _heartbeatFailCount++;
      if (_heartbeatFailCount >= _maxHeartbeatFails) {
        state = state.copyWith(health: ConnectionHealth.disconnected);
      } else if (_heartbeatFailCount == 1) {
        state = state.copyWith(health: ConnectionHealth.reconnecting);
      }
    }
  }

  // ── Event-Stream ──────────────────────────────────────────────────────────────

  Future<void> _watchEvents() async {
    await _eventSub?.cancel();
    _eventSub = null;

    final s = state;
    if (!s.isInSession) return;

    try {
      final stream = _service.watchSession(
        sessionId: s.session!.sessionId,
        nodeId: s.myNode!.nodeId,
        token: s.token!,
      );
      _eventSub = stream.listen(
        _handleSessionEvent,
        onError: (_) {
          if (state.isInSession) {
            state = state.copyWith(health: ConnectionHealth.disconnected);
          }
        },
        onDone: () {
          if (state.isInSession &&
              state.health == ConnectionHealth.connected) {
            state = state.copyWith(health: ConnectionHealth.disconnected);
          }
        },
      );
    } catch (_) {
      state = state.copyWith(health: ConnectionHealth.disconnected);
    }
  }

  void _handleSessionEvent(SessionEvent event) {
    final incoming = event.session;
    final current = state.session;

    // Bestehende mediaServerUrls bewahren wenn das Event leere Werte hat.
    // Passiert wenn ein JoinSession-Broadcast ankommt bevor RegisterNode
    // auf dem Server verarbeitet wurde (Race Condition).
    if (current != null) {
      final merged = incoming.deepCopy();
      for (final node in merged.nodes) {
        if (node.mediaServerUrl.isEmpty) {
          final known = current.nodes
              .where((n) => n.nodeId == node.nodeId)
              .map((n) => n.mediaServerUrl)
              .firstOrNull;
          if (known != null && known.isNotEmpty) {
            node.mediaServerUrl = known;
          }
        }
      }
      state = state.copyWith(session: merged, health: ConnectionHealth.connected);
    } else {
      state = state.copyWith(session: incoming, health: ConnectionHealth.connected);
    }
  }

  @override
  void dispose() {
    _heartbeatTimer?.cancel();
    _eventSub?.cancel();
    super.dispose();
  }
}
