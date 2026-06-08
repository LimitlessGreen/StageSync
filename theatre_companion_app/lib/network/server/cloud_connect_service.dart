/// cloud_connect_service.dart
/// ────────────────────────────
/// Socket.IO-Client für die Verbindung zum StageSync Realtime-Server (Website).
///
/// ## Authentifizierung
/// Der Server erwartet ein HMAC-SHA256-Token im Format:
///   `issuedAt.expiresAt.signature`
/// wobei signature = HMAC-SHA256(secret, "userId:issuedAt:expiresAt").toHex()
///
/// ## Auto-Reconnect
/// Bei Verbindungsabbruch wird der Client automatisch mit einem *neuen* Token
/// neu verbunden (wegen 5-Minuten-Ablauf des alten Tokens).
///
/// ## Inventory-Events
/// Der Server sendet `inventory_event` mit InventoryRealtimePayload.
/// Die App empfängt diese und merged sie in die lokale CRDT-DB.
///
/// ## Chat-Events
/// Bidirektionale Weiterleitung von Chatnachrichten über den `rehearsal_companions`-Raum:
///   App → Server: emit `chat_message` (wenn im Companion-Raum)
///   Server → App: empfange `chat_message` → [onChatMessage]-Callback
library cloud_connect_service;

import 'dart:async';
import 'dart:convert';
import 'dart:math' show min;

import 'package:cryptography/cryptography.dart';
import 'package:socket_io_client/socket_io_client.dart' as io;

import '../isolate/isolate_messages.dart' show CloudPeerInfo;

// ─────────────────────────────────────────────────────────────────────────────
// Data model: was die App vom Server-Inventory-Event extrahiert
// ─────────────────────────────────────────────────────────────────────────────

/// Eingehende Chat-Nachricht vom Cloud-Server.
class CloudChatMessage {
  final String messageId;
  final String senderDeviceId;
  final String senderLabel;
  final String content;
  final int timestampMs;

  const CloudChatMessage({
    required this.messageId,
    required this.senderDeviceId,
    required this.senderLabel,
    required this.content,
    required this.timestampMs,
  });
}

/// Gemergtes Inventory-Update vom Cloud-Server.
class CloudInventoryUpdate {
  final String itemId;
  final int statusId;
  final String? locationTag;
  final int wallClockMs;

  const CloudInventoryUpdate({
    required this.itemId,
    required this.statusId,
    this.locationTag,
    required this.wallClockMs,
  });
}

/// Status-Mapping Server-Strings → numerische App-StatusIds.
const _kStatusMap = {
  'available': 0,
  'in_place': 0,
  'checked_out': 1,
  'missing': 2,
  'damaged': 3,
  'lost': 2,
};

// ─────────────────────────────────────────────────────────────────────────────
// CloudConnectService
// ─────────────────────────────────────────────────────────────────────────────

class CloudConnectService {
  // ── Gespeicherte Verbindungsparameter (für Auto-Reconnect) ────────────────
  String? _serverUrl;
  String? _userId;
  String? _userName;
  String? _secret;
  String? _showId;

  // ── Socket-IO Handles ─────────────────────────────────────────────────────
  io.Socket? _socket;
  bool _isConnected = false;

  // ── Reconnect-Kontrolle ───────────────────────────────────────────────────
  bool _shouldReconnect = false;
  int _reconnectDelayMs = 1000;
  static const int _kMaxReconnectDelayMs = 30000;
  Timer? _reconnectTimer;

  // ── Proaktiver Token-Refresh ──────────────────────────────────────────────
  // Der HMAC-Token läuft nach 5 Minuten ab. Die Verbindung wird proaktiv
  // 60 Sekunden VOR Ablauf erneuert, damit kein "token expired" vom Server kommt.
  static const Duration _kTokenValidity = Duration(minutes: 10);
  static const Duration _kTokenRefreshMargin = Duration(minutes: 1);
  Timer? _tokenRefreshTimer;

  // ── Callbacks ─────────────────────────────────────────────────────────────
  final void Function(bool isConnected) _onConnectionChanged;
  final void Function(CloudInventoryUpdate update) _onInventoryUpdate;
  final void Function(List<CloudPeerInfo> peers, int totalOnline)
      _onCloudPeersUpdated;
  final void Function(CloudChatMessage message)? _onChatMessage;

  // ── Peer-Tracking ─────────────────────────────────────────────────────────
  final Map<String, CloudPeerInfo> _cloudPeers = {};
  int _totalOnline = 0;

  CloudConnectService({
    required void Function(bool) onConnectionChanged,
    required void Function(CloudInventoryUpdate) onInventoryUpdate,
    required void Function(List<CloudPeerInfo>, int) onCloudPeersUpdated,
    void Function(CloudChatMessage)? onChatMessage,
  })  : _onConnectionChanged = onConnectionChanged,
        _onInventoryUpdate = onInventoryUpdate,
        _onCloudPeersUpdated = onCloudPeersUpdated,
        _onChatMessage = onChatMessage;

  // ── Public API ────────────────────────────────────────────────────────────

  bool get isConnected => _isConnected;

  /// Sendet eine Chat-Nachricht an alle anderen Geräte im `rehearsal_companions`-Raum.
  ///
  /// Falls nicht verbunden oder nicht im Companion-Raum, wird die Nachricht
  /// stillschweigend verworfen. Das BLE-Mesh-Pfad bleibt davon unberührt.
  void sendChatMessage({
    required String messageId,
    required String senderDeviceId,
    required String senderLabel,
    required String content,
    required int timestampMs,
  }) {
    if (!_isConnected || _socket == null) return;
    _socket!.emit('chat_message', {
      'messageId': messageId,
      'senderDeviceId': senderDeviceId,
      'senderLabel': senderLabel,
      'content': content,
      'timestampMs': timestampMs,
    });
  }

  /// Verbindet sich mit dem Socket.IO Realtime-Server.
  /// Speichert die Parameter für spätere Auto-Reconnects.
  Future<void> connect({
    required String serverUrl,
    required String userId,
    required String userName,
    required String secret,
    String? showId,
  }) async {
    _serverUrl = serverUrl;
    _userId = userId;
    _userName = userName;
    _secret = secret;
    _showId = showId;
    _shouldReconnect = true;
    _reconnectDelayMs = 1000;

    await _openSocket();
    _scheduleTokenRefresh();
  }

  /// Trennt die Verbindung und deaktiviert Auto-Reconnect.
  void disconnect() {
    _shouldReconnect = false;
    _reconnectTimer?.cancel();
    _reconnectTimer = null;
    _tokenRefreshTimer?.cancel();
    _tokenRefreshTimer = null;
    _closeSocket();
  }

  // ── Private: Socket-Lifecycle ─────────────────────────────────────────────

  Future<void> _openSocket() async {
    _closeSocket();
    if (_serverUrl == null || _userId == null || _secret == null) return;

    String token;
    try {
      token = await _generateToken(userId: _userId!, secret: _secret!);
    } catch (_) {
      _scheduleReconnect();
      return;
    }

    _socket = io.io(_serverUrl!, <String, dynamic>{
      'transports': ['websocket'],
      'autoConnect': false,
      'reconnection': false, // Manuelle Reconnect-Logik für frische Tokens
      'auth': {
        'userId': _userId,
        'token': token,
        'userName': _userName ?? _userId,
      },
    });

    _socket!.onConnect((_) {
      _isConnected = true;
      _reconnectDelayMs = 1000; // Backoff-Reset bei Erfolg
      _onConnectionChanged(true);
      // Globalen Raum joinen (Pflicht)
      _socket?.emit('join_room', 'global');
      // Companion-Raum für Peer-Discovery unter StageSync-Apps
      _socket?.emit('join_room', 'rehearsal_companions');
      // Optional: Vorstellungs-Raum joinen
      if (_showId != null && _showId!.isNotEmpty) {
        _socket?.emit('join_room', 'show_$_showId');
      }
      // Proaktiven Token-Refresh nach erfolgreichem Connect planen
      _scheduleTokenRefresh();
    });

    _socket!.onDisconnect((_) {
      _isConnected = false;
      _onConnectionChanged(false);
      _tokenRefreshTimer?.cancel();
      _scheduleReconnect();
    });

    _socket!.onConnectError((_) {
      _isConnected = false;
      _onConnectionChanged(false);
      _tokenRefreshTimer?.cancel();
      _scheduleReconnect();
    });

    // Server-seitige Auth-Fehler: z.B. wenn der Token während einer laufenden
    // Verbindung abläuft und der Server ein `auth_error`-Event sendet anstatt
    // die Verbindung zu schließen (implementierungsabhängig).
    _socket!.on('auth_error', (_) {
      _tokenRefreshTimer?.cancel();
      _closeSocket();
      _scheduleReconnect(); // öffnet Socket mit frischem Token
    });
    _socket!.on('token_expired', (_) {
      _tokenRefreshTimer?.cancel();
      _closeSocket();
      _scheduleReconnect();
    });
    // Generischer Fehler-Event (manche Server-Implementierungen)
    _socket!.on('error', (data) {
      final msg = data?.toString().toLowerCase() ?? '';
      if (msg.contains('token') ||
          msg.contains('auth') ||
          msg.contains('expired')) {
        _tokenRefreshTimer?.cancel();
        _closeSocket();
        _scheduleReconnect();
      }
    });

    _socket!.on('inventory_event', _handleInventoryEvent);
    _socket!.on('user_joined', _handleUserJoined);
    _socket!.on('user_left', _handleUserLeft);
    _socket!.on('user_presence', _handleUserPresence);
    _socket!.on('rehearsal_users_list', _handleRehearsalUsersList);
    _socket!.on('online_stats_update', _handleOnlineStats);
    _socket!.on('chat_message', _handleChatMessage);

    _socket!.connect();
  }

  void _closeSocket() {
    _socket?.disconnect();
    _socket?.dispose();
    _socket = null;
    if (_isConnected) {
      _isConnected = false;
      _onConnectionChanged(false);
    }
    if (_cloudPeers.isNotEmpty) {
      _cloudPeers.clear();
      _totalOnline = 0;
      _notifyPeers();
    }
  }

  void _scheduleReconnect() {
    if (!_shouldReconnect) return;
    _reconnectTimer?.cancel();
    _reconnectTimer = Timer(
      Duration(milliseconds: _reconnectDelayMs),
      _openSocket,
    );
    _reconnectDelayMs = min(_reconnectDelayMs * 2, _kMaxReconnectDelayMs);
  }

  /// Plant einen proaktiven Reconnect kurz VOR Token-Ablauf.
  /// Dadurch wird der Socket mit einem frischen Token neu geöffnet bevor der
  /// Server ein "token expired" schickt oder die Verbindung verwirft.
  void _scheduleTokenRefresh() {
    _tokenRefreshTimer?.cancel();
    if (!_shouldReconnect) return;
    final refreshIn = _kTokenValidity - _kTokenRefreshMargin;
    _tokenRefreshTimer = Timer(refreshIn, () {
      if (!_shouldReconnect) return;
      // Sanft neu verbinden: alten Socket schließen → sofort mit frischem Token öffnen
      _closeSocket();
      _openSocket();
    });
  }

  // ── Private: Peer-Event-Handling ─────────────────────────────────────────

  /// Benachrichtigt die App über die aktuelle Peer-Liste.
  void _notifyPeers() {
    _onCloudPeersUpdated(
      List.unmodifiable(_cloudPeers.values),
      _totalOnline,
    );
  }

  /// `user_joined` Payload: { type, timestamp, user: { id, name } }
  /// Broadcast an alle → auch das eigene Gerät empfängt seine eigene Anmeldung.
  void _handleUserJoined(dynamic data) {
    if (data is! Map) return;
    final user = data['user'];
    if (user is! Map) return;
    final id = user['id'];
    final name = user['name'];
    if (id is! String || id.isEmpty) return;
    // Eigenes Gerät nicht als Peer anzeigen
    if (id == _userId) return;
    _cloudPeers[id] = CloudPeerInfo(
      userId: id,
      userName: (name is String && name.isNotEmpty) ? name : id,
    );
    _notifyPeers();
  }

  /// `user_left` Payload: { type, timestamp, user: { id, name } }
  void _handleUserLeft(dynamic data) {
    if (data is! Map) return;
    final user = data['user'];
    if (user is! Map) return;
    final id = user['id'];
    if (id is! String || id.isEmpty) return;
    _cloudPeers.remove(id);
    _notifyPeers();
  }

  /// `user_presence` Payload: { type, action, room, user: { id, name } }
  /// Wird nur für rehearsal_* Räume emittiert (nicht an den auslösenden Socket).
  void _handleUserPresence(dynamic data) {
    if (data is! Map) return;
    final room = data['room'];
    if (room is! String || room != 'rehearsal_companions') return;
    final action = data['action'];
    final user = data['user'];
    if (user is! Map) return;
    final id = user['id'];
    final name = user['name'];
    if (id is! String || id.isEmpty) return;
    if (id == _userId) return; // eigenes Gerät ignorieren
    if (action == 'join') {
      _cloudPeers[id] = CloudPeerInfo(
        userId: id,
        userName: (name is String && name.isNotEmpty) ? name : id,
      );
    } else if (action == 'leave') {
      _cloudPeers.remove(id);
    }
    _notifyPeers();
  }

  /// `rehearsal_users_list` Payload: { rehearsalId, users: [{ id, name }] }
  /// Wird beim Beitreten eines Rehearsal-Raums an das beitretende Gerät gesendet.
  void _handleRehearsalUsersList(dynamic data) {
    if (data is! Map) return;
    final rehearsalId = data['rehearsalId'];
    if (rehearsalId != 'companions') return; // nur unser Companion-Raum
    final users = data['users'];
    if (users is! List) return;
    // Komplette Liste neu aufbauen (dieser Snapshot ist autoritativ)
    for (final u in users) {
      if (u is! Map) continue;
      final id = u['id'];
      final name = u['name'];
      if (id is! String || id.isEmpty) continue;
      if (id == _userId) continue; // eigenes Gerät nicht in der Liste
      _cloudPeers[id] = CloudPeerInfo(
        userId: id,
        userName: (name is String && name.isNotEmpty) ? name : id,
      );
    }
    _notifyPeers();
  }

  /// `online_stats_update` Payload: { stats: { totalOnline, peakConcurrentUsers } }
  void _handleOnlineStats(dynamic data) {
    if (data is! Map) return;
    final stats = data['stats'];
    if (stats is! Map) return;
    final total = stats['totalOnline'];
    if (total is int) {
      _totalOnline = total;
      _notifyPeers();
    }
  }

  // ── Private: Event-Handling (Inventory) ──────────────────────────────────

  void _handleInventoryEvent(dynamic data) {
    if (data is! Map) return;

    final payload = data['payload'];
    if (payload is! Map) return;

    final delta = payload['delta'];
    if (delta is! Map) return;

    final upserts = delta['upserts'];
    if (upserts is! List) return;

    for (final item in upserts) {
      if (item is! Map) continue;

      // ItemId: Server nutzt meist 'id'; alternativ 'itemId'
      final rawId = item['id'] ?? item['itemId'];
      if (rawId is! String || rawId.isEmpty) continue;

      // Status parsen (int oder String)
      final rawStatus = item['status'] ?? item['statusId'];
      int statusId = 0;
      if (rawStatus is int) {
        statusId = rawStatus;
      } else if (rawStatus is String) {
        statusId = _kStatusMap[rawStatus.toLowerCase()] ?? 0;
      }

      // Ort
      final rawLocation = item['location'] ?? item['locationTag'];
      final locationTag = (rawLocation is String && rawLocation.isNotEmpty)
          ? rawLocation
          : null;

      // Zeitstempel
      final rawTs = item['updatedAt'] ?? item['lastUpdatedMs'];
      int wallClockMs;
      if (rawTs is int) {
        wallClockMs = rawTs;
      } else if (rawTs is String) {
        wallClockMs = DateTime.tryParse(rawTs)?.millisecondsSinceEpoch ??
            DateTime.now().millisecondsSinceEpoch;
      } else {
        wallClockMs = DateTime.now().millisecondsSinceEpoch;
      }

      _onInventoryUpdate(CloudInventoryUpdate(
        itemId: rawId,
        statusId: statusId,
        locationTag: locationTag,
        wallClockMs: wallClockMs,
      ));
    }
  }

  // ── Private: Chat-Event-Handling ─────────────────────────────────────────

  /// `chat_message` Payload:
  ///   { messageId, senderDeviceId, senderLabel, content, timestampMs }
  /// Broadcast vom Server an alle anderen im `rehearsal_companions`-Raum.
  void _handleChatMessage(dynamic data) {
    if (_onChatMessage == null) return;
    if (data is! Map) return;
    final messageId = data['messageId'];
    final senderDeviceId = data['senderDeviceId'];
    final senderLabel = data['senderLabel'];
    final content = data['content'];
    final rawTs = data['timestampMs'];
    if (messageId is! String || messageId.isEmpty) return;
    if (content is! String || content.isEmpty) return;
    final timestampMs =
        rawTs is int ? rawTs : DateTime.now().millisecondsSinceEpoch;
    _onChatMessage(CloudChatMessage(
      messageId: messageId,
      senderDeviceId: (senderDeviceId is String && senderDeviceId.isNotEmpty)
          ? senderDeviceId
          : 'cloud-peer',
      senderLabel: (senderLabel is String && senderLabel.isNotEmpty)
          ? senderLabel
          : '…${messageId.length > 8 ? messageId.substring(messageId.length - 8) : messageId}',
      content: content,
      timestampMs: timestampMs,
    ));
  }

  // ── Token-Generierung ─────────────────────────────────────────────────────

  /// Generiert HMAC-SHA256 Token im Server-Format: `issuedAt.expiresAt.sig`
  static Future<String> _generateToken({
    required String userId,
    required String secret,
  }) async {
    final nowMs = DateTime.now().millisecondsSinceEpoch;
    final issuedAt = nowMs;
    final expiresAt = nowMs + 600000; // 10 Minuten Gültigkeit (war: 5 min)

    final base = '$userId:$issuedAt:$expiresAt';

    final hmac = Hmac.sha256();
    final secretKey = SecretKey(utf8.encode(secret));
    final mac = await hmac.calculateMac(
      utf8.encode(base),
      secretKey: secretKey,
    );

    final sig =
        mac.bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();

    return '$issuedAt.$expiresAt.$sig';
  }
}
