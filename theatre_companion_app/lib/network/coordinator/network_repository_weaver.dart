/// network_repository_weaver.dart
/// ────────────────────────────────
/// The **central coordinator** of the StageSync network stack.
///
/// All decisions about WHERE and HOW to route a data packet flow through here:
///
///   ┌────────────────────────────────────────────────────────────────────────┐
///   │                   NetworkRepositoryWeaver                              │
///   │                                                                        │
///   │  [ScanItemCommand]  hint=auto|preferBle|cloudOnly|urgent               │
///   │       │                                                                │
///   │       ▼ 1. Persist CRDT delta to SQLite (ACID guarantee)              │
///   │       │                                                                │
///   │  TransportHint.auto:                                                   │
///   │    isLeader? → WebSocketService.send()                                 │
///   │    isFollower? → GossipEngine.originateDataPacket (BLE Mesh)           │
///   │                                                                        │
///   │  TransportHint.cloudOnly:                                              │
///   │    → WebSocketService.send() (wenn Leader+Connected)                   │
///   │    → Kein BLE-Fallback (Payload zu groß oder vertraulich)              │
///   │                                                                        │
///   │  TransportHint.urgent:                                                 │
///   │    → WebSocket + BLE gleichzeitig                                      │
///   │                                                                        │
///   │  TransportHint.preferBle:                                              │
///   │    → BLE zuerst, dann Cloud als Backup                                 │
///   │                                                                        │
///   │  [TransferAnnouncementCommand]                                         │
///   │    → Setzt _preferCloudUntilMs (große Payloads → Cloud bevorzugen)     │
///   └────────────────────────────────────────────────────────────────────────┘
///
/// BLE-Fehler aus [AbstractBleService.onBleError] werden als [BleStatusEvent]
/// an die UI weitergeleitet – kein stilles Ignorieren mehr.
library network_repository_weaver;

import 'dart:async';
import 'dart:typed_data';

import '../ble/gossip_engine.dart';
import '../crypto/aes_gcm_service.dart';
import '../db/dao/chat_dao.dart';
import '../db/dao/inventory_dao.dart';
import '../db/dao/packet_queue_dao.dart';
import '../isolate/isolate_messages.dart';
import '../models/ble_packet.dart';
import '../models/inventory_item_crdt.dart';
import '../platform/abstract_ble_service.dart';
import '../routing/leader_election_engine.dart';
import '../routing/peer_registry.dart';
import '../server/cloud_connect_service.dart';
import '../server/websocket_service.dart';

// ─────────────────────────────────────────────────────────────────────────────

class NetworkRepositoryWeaver {
  // ── Dependencies ──────────────────────────────────────────────────────────
  final AbstractBleService _ble;
  final GossipEngine _gossip;
  final WebSocketService _ws;
  final InventoryDao _inventoryDao;
  final PacketQueueDao _queueDao;
  final ChatDao _chatDao;
  final LeaderElectionEngine _election;
  final AesGcmService _crypto;
  final PeerRegistry _peers;

  // ── Cloud Connect (Socket.IO Realtime-Server) ─────────────────────────────
  CloudConnectService? _cloudService;
  String? _cloudServerUrl;

  /// In-Memory-Dedup-Set für Chat-Nachrichten.
  static const int _kMaxSeenChats = 500;
  final Set<String> _seenChatIds = {};

  /// Callback zum Emittieren von Events an die UI-Seite.
  final void Function(NetworkEvent) _emitEvent;

  /// This device's full unique identifier (UUID string).
  final String _localDeviceId;
  final int _localShortId;

  /// Wenn != 0 und in der Zukunft: Cloud-Transport für Pakete bevorzugen.
  /// Wird gesetzt durch [TransferAnnouncementCommand] bei großen Payloads.
  int _preferCloudUntilMs = 0;
  bool get _isPreferringCloud =>
      DateTime.now().millisecondsSinceEpoch < _preferCloudUntilMs;

  // ── Streams & subscriptions ───────────────────────────────────────────────
  StreamSubscription<IncomingBlePacket>? _bleSub;
  StreamSubscription<String>? _bleErrorSub;
  Timer? _statusBroadcastTimer;
  Timer? _maintenanceTimer;

  NetworkRepositoryWeaver({
    required AbstractBleService ble,
    required GossipEngine gossip,
    required WebSocketService ws,
    required InventoryDao inventoryDao,
    required PacketQueueDao queueDao,
    required ChatDao chatDao,
    required LeaderElectionEngine election,
    required AesGcmService crypto,
    required PeerRegistry peers,
    required void Function(NetworkEvent) emitEvent,
    required String localDeviceId,
    required int localShortId,
  })  : _ble = ble,
        _gossip = gossip,
        _ws = ws,
        _inventoryDao = inventoryDao,
        _queueDao = queueDao,
        _chatDao = chatDao,
        _election = election,
        _crypto = crypto,
        _peers = peers,
        _emitEvent = emitEvent,
        _localDeviceId = localDeviceId,
        _localShortId = localShortId;

  // ─── Lifecycle ────────────────────────────────────────────────────────────

  Future<void> start() async {
    // 1. Peer-Änderungen abonnieren → Store-Carry-Forward ausliefern.
    _peers.addListener(_onPeerChanged);

    // 2. Alle eingehenden BLE-Pakete abonnieren.
    _bleSub = _ble.onPacketReceived.listen(_onIncomingBlePacket);

    // 3. BLE-Fehler als BleStatusEvent an UI weiterleiten.
    // Mocktail-Mocks können unstubbed Getter als null zurückgeben.
    // Deshalb defensiv auf Stream.empty() zurückfallen.
    Stream<String> bleErrorStream;
    try {
      bleErrorStream = _ble.onBleError;
    } catch (_) {
      bleErrorStream = const Stream<String>.empty();
    }
    _bleErrorSub = bleErrorStream.listen(_onBleError);

    // 4. BLE-Scan und Advertising starten.
    await _ble.start();

    // 5. Election Engine starten (erste Wahl nach 500 ms).
    await _election.start();

    // 6. Periodischer Status-Broadcast an die UI (alle 5 s).
    _statusBroadcastTimer = Timer.periodic(
      const Duration(seconds: 5),
      (_) => _emitStatus(),
    );

    // 7. Periodische DB-Wartung (alle 10 min).
    _maintenanceTimer = Timer.periodic(
      const Duration(minutes: 10),
      (_) => _runMaintenance(),
    );
  }

  Future<void> stop() async {
    _statusBroadcastTimer?.cancel();
    _maintenanceTimer?.cancel();
    await _bleSub?.cancel();
    await _bleErrorSub?.cancel();
    await _election.stop();
    await _ble.stop();
    await _ws.disconnect();
    _cloudService?.disconnect();
    _cloudService = null;
    _peers.removeListener(_onPeerChanged);
  }

  // ─── BLE Error Handler ────────────────────────────────────────────────────

  void _onBleError(String message) {
    // Gib BLE-Statusmeldungen als BleStatusEvent weiter (nicht als fatalen Fehler).
    _emitEvent(BleStatusEvent(
      isAdvertising: _readBleBool(() => _ble.isAdvertising, fallback: false),
      isScanning: _readBleBool(() => _ble.isScanning, fallback: false),
      errorMessage: message,
      activeConnectionCount:
          _readBleInt(() => _ble.activeConnectionCount, fallback: 0),
      isFallbackScanMode:
          _readBleBool(() => _ble.isFallbackScanMode, fallback: false),
    ));
  }

  bool _readBleBool(bool Function() read, {required bool fallback}) {
    try {
      return read();
    } catch (_) {
      return fallback;
    }
  }

  int _readBleInt(int Function() read, {required int fallback}) {
    try {
      return read();
    } catch (_) {
      return fallback;
    }
  }

  // ─── Command handler ──────────────────────────────────────────────────────

  Future<void> handleCommand(NetworkCommand command) async {
    switch (command) {
      case ScanItemCommand():
        await _handleScanItem(command);
      case SendChatMessageCommand():
        await _handleSendChat(command);
      case ConnectToServerCommand():
        await _handleConnectToServer(command);
      case CloudConnectCommand():
        await _handleCloudConnect(command);
      case CloudDisconnectCommand():
        _handleCloudDisconnect();
      case ForceElectionCommand():
        await _election.startElectionRound();
      case QueryStatusCommand():
        await _emitStatus();
      case TransferAnnouncementCommand():
        await _handleTransferAnnouncement(command);
      case ShutdownCommand():
        await stop();
    }
  }

  // ─── Outbound: Transfer Announcement ─────────────────────────────────────

  /// Reagiert auf Großtransfer-Ankündigung der App.
  /// Setzt den Cloud-Bevorzugungs-Modus für 2 Minuten.
  Future<void> _handleTransferAnnouncement(
      TransferAnnouncementCommand cmd) async {
    if (cmd.isLargeTransfer) {
      _preferCloudUntilMs = DateTime.now().millisecondsSinceEpoch +
          const Duration(minutes: 2).inMilliseconds;
      _emitEvent(BleStatusEvent(
        isAdvertising: true,
        isScanning: true,
        errorMessage:
            'Großer Transfer angekündigt (${(cmd.estimatedBytes / 1024).toStringAsFixed(0)} KB'
            '${cmd.description != null ? ", ${cmd.description}" : ""}). '
            'Cloud-Routing bevorzugt für nächste 2 Minuten.',
      ));
    }
    await _emitStatus();
  }

  // ─── Outbound: Chat message ───────────────────────────────────────────────

  Future<void> _handleSendChat(SendChatMessageCommand cmd) async {
    final nowMs = DateTime.now().millisecondsSinceEpoch;
    final msgId = _randomUint32();
    final messageId = '$_localShortId:$msgId';
    final label = _localDeviceId.length > 8
        ? '…${_localDeviceId.substring(_localDeviceId.length - 8)}'
        : _localDeviceId;

    await _chatDao.insertMessage(
      messageId: messageId,
      senderDeviceId: _localDeviceId,
      senderShortId: _localShortId,
      senderLabel: label,
      content: cmd.content,
      timestampMs: nowMs,
      isMine: true,
    );

    _markChatSeen(messageId);

    _emitEvent(ChatMessageReceivedEvent(
      messageId: messageId,
      senderDeviceId: _localDeviceId,
      senderShortLabel: label,
      content: cmd.content,
      timestampMs: nowMs,
      isMine: true,
    ));

    _cloudService?.sendChatMessage(
      messageId: messageId,
      senderDeviceId: _localDeviceId,
      senderLabel: label,
      content: cmd.content,
      timestampMs: nowMs,
    );

    final packet = BleChatTextPacket.create(
      sourceDeviceShortId: _localShortId,
      messageId: msgId,
      text: cmd.content,
    );
    await _gossip.originateChatPacket(packet);
  }

  // ─── Outbound: Local scan → Network ──────────────────────────────────────

  Future<void> _handleScanItem(ScanItemCommand cmd) async {
    final existing = await _inventoryDao.getByItemId(cmd.itemId);
    late InventoryItemCrdt crdt;

    if (existing == null) {
      crdt = InventoryItemCrdt.create(
        itemId: cmd.itemId,
        deviceId: _localDeviceId,
        deviceShortId: _localShortId,
        statusId: cmd.statusId,
        locationTag: cmd.locationTag,
        wallClockMs: cmd.timestampMs,
      );
    } else {
      final localCrdt = InventoryItemCrdt.fromJsonString(existing.crdtJson);
      crdt = localCrdt.withStatusUpdate(
        newStatusId: cmd.statusId,
        deviceId: _localDeviceId,
        deviceShortId: _localShortId,
        wallClockMs: cmd.timestampMs,
      );
      if (cmd.locationTag != null) {
        crdt = crdt.withLocationUpdate(
          newLocation: cmd.locationTag,
          deviceId: _localDeviceId,
          deviceShortId: _localShortId,
          wallClockMs: cmd.timestampMs,
        );
      }
    }

    await _inventoryDao.upsertCrdt(crdt);

    _emitEvent(ItemUpdatedEvent(
      itemId: crdt.itemId,
      statusId: crdt.status.value,
      locationTag: crdt.location.value,
      sourceDeviceId: _localDeviceId,
      timestampMs: cmd.timestampMs,
      isSyncedToServer: false,
    ));

    await _routeOutboundCrdt(crdt, cmd.timestampMs, cmd.hint);
  }

  /// Routing-Engine: entscheidet anhand [hint] und aktueller Topologie,
  /// über welchen Transport das CRDT-Update verschickt wird.
  Future<void> _routeOutboundCrdt(
    InventoryItemCrdt crdt,
    int timestampMs,
    TransportHint hint,
  ) async {
    final effectiveHint = (_isPreferringCloud && hint == TransportHint.auto)
        ? TransportHint.cloudOnly
        : hint;

    switch (effectiveHint) {
      case TransportHint.cloudOnly:
        // Nur via Server – kein BLE-Mesh-Relay.
        if (_election.isLeader && _ws.isConnected) {
          final jsonBytes = Uint8List.fromList(crdt.toJsonString().codeUnits);
          final encrypted = await _crypto.encrypt(jsonBytes);
          _ws.send(encrypted);
        }
      // Wenn kein Server, bleibt das Paket in der lokalen DB (unsynchronisiert).
      // Beim nächsten Server-Reconnect wird es nachgeliefert.

      case TransportHint.preferBle:
        // BLE zuerst, danach Cloud als zusätzliche Sicherung.
        await _gossipDataPacket(crdt, timestampMs);
        if (_election.isLeader && _ws.isConnected) {
          final jsonBytes = Uint8List.fromList(crdt.toJsonString().codeUnits);
          final encrypted = await _crypto.encrypt(jsonBytes);
          _ws.send(encrypted);
        }

      case TransportHint.urgent:
        // Alle verfügbaren Kanäle gleichzeitig.
        final futures = <Future>[];
        futures.add(_gossipDataPacket(crdt, timestampMs));
        if (_election.isLeader && _ws.isConnected) {
          futures.add(() async {
            final jsonBytes = Uint8List.fromList(crdt.toJsonString().codeUnits);
            final encrypted = await _crypto.encrypt(jsonBytes);
            _ws.send(encrypted);
          }());
        }
        await Future.wait(futures, eagerError: false);

      case TransportHint.auto:
        // Standard-Routing: Leader → WebSocket, Follower → BLE-Mesh.
        if (_election.isLeader) {
          if (_ws.isConnected) {
            final jsonBytes = Uint8List.fromList(crdt.toJsonString().codeUnits);
            final encrypted = await _crypto.encrypt(jsonBytes);
            _ws.send(encrypted);
          } else {
            // Leader, aber Server nicht erreichbar: per BLE weiterleiten,
            // damit andere Geräte es bei Reconnect hochladen können.
            await _gossipDataPacket(crdt, timestampMs);
          }
        } else {
          // Follower: BLE-Mesh → Leader → Server.
          await _gossipDataPacket(crdt, timestampMs);
        }
    }
  }

  Future<void> _gossipDataPacket(
      InventoryItemCrdt crdt, int timestampMs) async {
    final packet = BleDataPacket.create(
      sourceDeviceShortId: _localShortId,
      itemShortId: shortIdFromString(crdt.itemId),
      statusId: crdt.status.value,
      timestampSec: timestampMs ~/ 1000,
    );
    await _gossip.originateDataPacket(packet);
  }

  // ─── Outbound: Server connection (leader only) ────────────────────────────

  Future<void> _handleConnectToServer(ConnectToServerCommand cmd) async {
    if (!_election.isLeader) return;
    await _ws.connect(cmd.serverUrl);
  }

  // ─── Cloud Connect (Socket.IO Realtime-Server) ────────────────────────────

  Future<void> _handleCloudConnect(CloudConnectCommand cmd) async {
    _cloudService?.disconnect();
    _cloudServerUrl = cmd.serverUrl;

    _cloudService = CloudConnectService(
      onConnectionChanged: (connected) {
        _emitEvent(CloudConnectionChangedEvent(
          isConnected: connected,
          serverUrl: connected ? _cloudServerUrl : null,
        ));
        _emitStatus().ignore();
      },
      onInventoryUpdate: _handleCloudInventoryUpdate,
      onCloudPeersUpdated: (peers, totalOnline) {
        _emitEvent(CloudPeersUpdatedEvent(
          peers: peers,
          totalOnline: totalOnline,
        ));
      },
      onChatMessage: _handleCloudChat,
    );

    await _cloudService!.connect(
      serverUrl: cmd.serverUrl,
      userId: cmd.userId,
      userName: cmd.userName,
      secret: cmd.secret,
      showId: cmd.showId,
    );
  }

  void _handleCloudDisconnect() {
    _cloudService?.disconnect();
    _cloudService = null;
    _cloudServerUrl = null;
    _emitEvent(CloudConnectionChangedEvent(isConnected: false));
    _emitStatus().ignore();
  }

  Future<void> _handleCloudInventoryUpdate(CloudInventoryUpdate update) async {
    try {
      final remoteCrdt = InventoryItemCrdt.create(
        itemId: update.itemId,
        deviceId: 'cloud-server',
        deviceShortId: 0,
        statusId: update.statusId,
        locationTag: update.locationTag,
        wallClockMs: update.wallClockMs,
      );

      final merged = await _inventoryDao.mergeRemote(remoteCrdt);
      await _inventoryDao.markSynced(merged.itemId);

      final updatePacket = BleDataPacket.create(
        sourceDeviceShortId: _localShortId,
        itemShortId: shortIdFromString(merged.itemId),
        statusId: merged.status.value,
        timestampSec: merged.status.wallClockMs ~/ 1000,
      );
      await _gossip.originateDataPacket(updatePacket);

      _emitEvent(ItemUpdatedEvent(
        itemId: merged.itemId,
        statusId: merged.status.value,
        locationTag: merged.location.value,
        sourceDeviceId: 'cloud-server',
        timestampMs: merged.status.wallClockMs,
        isSyncedToServer: true,
      ));
    } catch (_) {}
  }

  // ─── Inbound: BLE packet dispatcher ──────────────────────────────────────

  Future<void> _onIncomingBlePacket(IncomingBlePacket incoming) async {
    final packet = incoming.packet;
    final sender = incoming.senderDeviceId;

    switch (packet) {
      case BleDataPacket():
        await _handleIncomingDataPacket(packet, sender);

      case BleHeartbeatPacket():
        _election.onHeartbeatReceived(sender);

      case BleElectionBidPacket():
        _election.onBidReceived(sender, packet.score);
        if (packet.header.ttl > 1) {
          final relayed = Uint8List.fromList(
            BleElectionBidPacket(
              header: packet.header.withDecrementedTtl(),
              score: packet.score,
            ).toBytes(),
          );
          await _gossip.broadcastControlPacket(relayed);
        }

      case BleAckPacket():
        await _queueDao.markDelivered(packet.ackedPacketShortId);

      case BleChatTextPacket():
        await _handleIncomingChatPacket(packet, sender);

      default:
        break;
    }
  }

  Future<void> _handleIncomingDataPacket(
    BleDataPacket packet,
    String senderDeviceId,
  ) async {
    await _gossip.onDataPacketReceived(packet, senderDeviceId);

    final knownRow = await _inventoryDao.getByShortId(packet.itemShortId);

    if (knownRow != null) {
      final remoteCrdt = InventoryItemCrdt.create(
        itemId: knownRow.itemId,
        deviceId: senderDeviceId,
        deviceShortId: packet.header.sourceDeviceShortId,
        statusId: packet.statusId,
        locationTag: null,
        wallClockMs: packet.timestampSec * 1000,
      );

      final merged = await _inventoryDao.mergeRemote(remoteCrdt);

      if (_election.isLeader && _ws.isConnected) {
        final jsonBytes = Uint8List.fromList(merged.toJsonString().codeUnits);
        final encrypted = await _crypto.encrypt(jsonBytes);
        _ws.send(encrypted);
        await _inventoryDao.markSynced(merged.itemId);
      }

      _emitEvent(ItemUpdatedEvent(
        itemId: merged.itemId,
        statusId: merged.status.value,
        locationTag: merged.location.value,
        sourceDeviceId: senderDeviceId,
        timestampMs: packet.timestampSec * 1000,
        isSyncedToServer: _election.isLeader && _ws.isConnected,
      ));
    } else {
      if (_election.isLeader && _ws.isConnected) {
        final encrypted =
            await _crypto.encrypt(Uint8List.fromList(packet.toBytes()));
        _ws.send(encrypted);
      }

      _emitEvent(ItemUpdatedEvent(
        itemId: '~${packet.itemShortId.toRadixString(16).padLeft(4, '0')}',
        statusId: packet.statusId,
        locationTag: null,
        sourceDeviceId: senderDeviceId,
        timestampMs: packet.timestampSec * 1000,
        isSyncedToServer: false,
      ));
    }
  }

  Future<void> _handleIncomingChatPacket(
    BleChatTextPacket packet,
    String senderDeviceId,
  ) async {
    final dedupKey = '${packet.header.sourceDeviceShortId}:${packet.messageId}';

    await _gossip.onChatPacketReceived(packet, senderDeviceId);

    if (_hasChatSeen(dedupKey)) return;
    _markChatSeen(dedupKey);

    final nowMs = DateTime.now().millisecondsSinceEpoch;
    final label = senderDeviceId.length > 8
        ? '…${senderDeviceId.substring(senderDeviceId.length - 8)}'
        : senderDeviceId;

    await _chatDao.insertMessage(
      messageId: dedupKey,
      senderDeviceId: senderDeviceId,
      senderShortId: packet.header.sourceDeviceShortId,
      senderLabel: label,
      content: packet.text,
      timestampMs: nowMs,
      isMine: false,
    );

    _emitEvent(ChatMessageReceivedEvent(
      messageId: dedupKey,
      senderDeviceId: senderDeviceId,
      senderShortLabel: label,
      content: packet.text,
      timestampMs: nowMs,
      isMine: false,
    ));
  }

  Future<void> _handleCloudChat(CloudChatMessage msg) async {
    if (_hasChatSeen(msg.messageId)) return;
    _markChatSeen(msg.messageId);

    await _chatDao.insertMessage(
      messageId: msg.messageId,
      senderDeviceId: msg.senderDeviceId,
      senderShortId: 0,
      senderLabel: msg.senderLabel,
      content: msg.content,
      timestampMs: msg.timestampMs,
      isMine: false,
    );

    _emitEvent(ChatMessageReceivedEvent(
      messageId: msg.messageId,
      senderDeviceId: msg.senderDeviceId,
      senderShortLabel: msg.senderLabel,
      content: msg.content,
      timestampMs: msg.timestampMs,
      isMine: false,
    ));
  }

  // ─── Chat-Dedup ───────────────────────────────────────────────────────────

  bool _hasChatSeen(String messageId) => _seenChatIds.contains(messageId);

  void _markChatSeen(String messageId) {
    if (_seenChatIds.length >= _kMaxSeenChats) {
      _seenChatIds.remove(_seenChatIds.first);
    }
    _seenChatIds.add(messageId);
  }

  // ─── Public wrappers ──────────────────────────────────────────────────────

  void onServerMessage(Uint8List encrypted) => _onServerMessage(encrypted);
  Future<void> emitStatus() => _emitStatus();

  // ─── Inbound: Server → Local ──────────────────────────────────────────────

  void _onServerMessage(Uint8List encrypted) async {
    try {
      final plainBytes = await _crypto.decrypt(encrypted);
      final jsonString = String.fromCharCodes(plainBytes);
      final remoteCrdt = InventoryItemCrdt.fromJsonString(jsonString);

      final merged = await _inventoryDao.mergeRemote(remoteCrdt);
      await _inventoryDao.markSynced(merged.itemId);

      final updatePacket = BleDataPacket.create(
        sourceDeviceShortId: _localShortId,
        itemShortId: shortIdFromString(merged.itemId),
        statusId: merged.status.value,
        timestampSec: merged.status.wallClockMs ~/ 1000,
      );
      await _gossip.originateDataPacket(updatePacket);

      _emitEvent(ItemUpdatedEvent(
        itemId: merged.itemId,
        statusId: merged.status.value,
        locationTag: merged.location.value,
        sourceDeviceId: 'server',
        timestampMs: merged.status.wallClockMs,
        isSyncedToServer: true,
      ));
    } catch (_) {}
  }

  // ─── Peer change handler (Store-Carry-Forward drain) ─────────────────────

  void _onPeerChanged(PeerInfo peer, bool isOnline) {
    _emitEvent(PeerDiscoveredEvent(
      deviceId: peer.deviceId,
      rssi: peer.rssi,
      isOnline: isOnline,
    ));

    if (isOnline) {
      _gossip.drainQueueForPeer(peer.deviceId).ignore();
    }
  }

  // ─── Leadership change handler ────────────────────────────────────────────

  void handleLeadershipChange({
    required String newLeaderId,
    required bool isThisDeviceLeader,
    required int winningScore,
  }) {
    _emitEvent(LeaderChangedEvent(
      newLeaderDeviceId: newLeaderId,
      isThisDeviceLeader: isThisDeviceLeader,
      leaderScore: winningScore,
    ));
  }

  // ─── Periodic status event ────────────────────────────────────────────────

  Future<void> _emitStatus() async {
    final pending = await _queueDao.pendingCount();
    final breakdown = await _election.computeScoreBreakdown();

    final peerInfos = _peers.alivePeers
        .map((p) => PeerStatusInfo(
              deviceId: p.deviceId,
              deviceShortId: p.deviceShortId,
              rssi: p.rssi,
              electionScore: p.electionScore,
              isLeader: p.isLeader,
              hasInternet: p.hasInternet,
              lastSeenMs: p.lastSeenMs,
            ))
        .toList()
      ..sort((a, b) => b.rssi.compareTo(a.rssi));

    _emitEvent(NetworkStatusEvent(
      connectedPeerCount: _peers.aliveCount,
      pendingQueuedPackets: pending,
      hasServerConnection:
          _ws.isConnected || (_cloudService?.isConnected ?? false),
      currentLeaderId: _election.currentLeaderId,
      localElectionScore: breakdown.total,
      syncStatus: _determineSyncStatus(),
      peers: peerInfos,
      scoreBreakdown: breakdown,
    ));
  }

  static int _randomUint32() {
    final r = DateTime.now().microsecondsSinceEpoch & 0xFFFFFFFF;
    return r;
  }

  NetworkSyncStatus _determineSyncStatus() {
    if (_ws.isConnected || (_cloudService?.isConnected ?? false)) {
      return NetworkSyncStatus.syncing;
    }
    if (_peers.aliveCount > 0) return NetworkSyncStatus.meshOnly;
    return NetworkSyncStatus.offline;
  }

  // ─── DB maintenance ───────────────────────────────────────────────────────

  Future<void> _runMaintenance() async {
    await _queueDao.purgeDelivered();
    await _queueDao.purgeStale();
  }
}
