/// network_isolate_manager.dart
/// ──────────────────────────────
/// **Der Einstiegspunkt für den gesamten Netzwerk-Stack.**
///
/// ## Architektur-Entscheidung: Kein Background-Isolate mehr
///
/// Der ursprüngliche Ansatz mit einem Background-Isolate hatte einen kritischen
/// Fehler: Beide BLE-Bibliotheken (flutter_reactive_ble und ble_peripheral)
/// benötigen den Android-Activity-Kontext, der in Background-Isolates NICHT
/// verfügbar ist – auch nicht mit BackgroundIsolateBinaryMessenger.
/// Das führte dazu, dass BlePeripheral.initialize() / startAdvertising() im
/// Hintergrund-Isolate still fehlschlug und Geräte sich nie gegenseitig fanden.
///
/// **Lösung:** Alles läuft jetzt auf dem Main-Isolate (wie die Web-Route
/// schon immer). Dart's async Event-Loop handhabt die Nebenläufigkeit korrekt.
/// Blocking-Operationen gibt es nicht – alle BLE-, Crypto- und DB-Operationen
/// sind asynchron. Drift verwaltet seinen eigenen Thread-Pool intern.
///
/// ## Platform-Matrix
///
/// | Platform        | BLE                     | Storage       |
/// |-----------------|-------------------------|---------------|
/// | Android / iOS   | BleMeshService          | Drift/SQLite  |
/// | Windows / macOS | BleMeshService          | Drift/SQLite  |
/// | Linux           | BleMeshService          | Drift/SQLite  |
/// | Web             | StubBleService          | In-Memory     |
library network_isolate_manager;

import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/foundation.dart'
    show kIsWeb;

import '../coordinator/network_repository_weaver.dart';
import '../crypto/aes_gcm_service.dart';
import '../db/app_database.dart';
import '../db/dao/chat_dao.dart';
import '../db/dao/inventory_dao.dart';
import '../db/dao/packet_queue_dao.dart';
import '../isolate/isolate_messages.dart';
import '../models/ble_packet.dart';
import '../models/inventory_item_crdt.dart';
import '../platform/abstract_ble_service.dart';
import '../platform/stub_ble_service.dart';
import '../routing/leader_election_engine.dart';
import '../routing/peer_registry.dart';
import '../ble/ble_mesh_service.dart';
import '../ble/gossip_engine.dart';
import '../server/websocket_service.dart';

// ─────────────────────────────────────────────────────────────────────────────
// NetworkIsolateManager  (lebt auf dem MAIN-Isolate)
// ─────────────────────────────────────────────────────────────────────────────

class NetworkIsolateManager {
  NetworkRepositoryWeaver? _weaver;

  /// Geöffnete Drift-Datenbank (nur auf native Plattformen, null auf Web).
  AppDatabase? _db;

  final StreamController<NetworkEvent> _eventController =
      StreamController<NetworkEvent>.broadcast();

  bool _isInitialised = false;

  Stream<NetworkEvent> get events => _eventController.stream;
  bool get isInitialised => _isInitialised;

  /// Initialisiert den Netzwerk-Stack.
  ///
  /// Muss **einmalig** vor dem ersten [send]-Aufruf aufgerufen werden.
  /// Auf Web: In-Memory-Stubs + StubBleService.
  /// Auf native: echte Drift/SQLite-Datenbank + BleMeshService (Android/iOS)
  ///             oder StubBleService (Windows/macOS/Linux).
  Future<void> init({required String deviceId}) async {
    if (_isInitialised) return;
    if (kIsWeb) {
      await _initWeb(deviceId);
    } else {
      await _initNative(deviceId);
    }
    _isInitialised = true;
  }

  /// Sendet einen Befehl an den Netzwerk-Stack.
  ///
  /// Der [NetworkRepositoryWeaver] verarbeitet den Befehl asynchron.
  /// Da alles auf dem Main-Isolate läuft, ist kein SendPort mehr nötig.
  void send(NetworkCommand command) {
    assert(_isInitialised, 'Zuerst init() aufrufen');
    _weaver?.handleCommand(command).ignore();
  }

  /// Fährt den Netzwerk-Stack sauber herunter und gibt alle Ressourcen frei.
  Future<void> dispose() async {
    if (!_isInitialised) return;
    await _weaver?.stop();
    _weaver = null;
    await _db?.close();
    _db = null;
    if (!_eventController.isClosed) {
      await _eventController.close();
    }
    _isInitialised = false;
  }

  // ─── Native Init (Android, iOS, Windows, macOS, Linux) ───────────────────

  /// Initialisiert den Stack für native Plattformen.
  ///
  /// Läuft vollständig auf dem Main-Isolate, damit BLE-Plugins (flutter_reactive_ble
  /// und ble_peripheral) Zugriff auf den Android-Activity-Kontext haben.
  Future<void> _initNative(String deviceId) async {
    final dbPath = await AppDatabase.resolveDatabasePath();
    final shortId = shortIdFromString(deviceId);

    // ── Datenbank ──────────────────────────────────────────────────────────
    final db = AppDatabase.openAtPath(dbPath);
    _db = db;
    final inventoryDao = InventoryDao(db);
    final queueDao = PacketQueueDao(db);
    final chatDao = ChatDao(db);

    // ── Kryptographie ──────────────────────────────────────────────────────
    final crypto = await AesGcmService.withProductionKey();

    // ── Peer-Registry ──────────────────────────────────────────────────────
    final peers = PeerRegistry();

    // ── BLE-Service (plattformabhängig) ────────────────────────────────────
    // bluetooth_low_energy unterstützt Central+Peripheral auf Android, iOS,
    // Windows und macOS mit identischer Dart-API.
    // Auf Web ist BLE nicht verfügbar → StubBleService (WebSocket-only).
    final AbstractBleService ble = kIsWeb
        ? StubBleService()
        : BleMeshService(peers: peers, crypto: crypto);

    // ── Gossip & Weaver (late: gegenseitige Abhängigkeiten) ────────────────
    late final GossipEngine gossip;
    late NetworkRepositoryWeaver weaver;

    // ── WebSocket-Service ──────────────────────────────────────────────────
    final ws = WebSocketService(
      onServerMessage: (msg) => weaver.onServerMessage(msg),
      onConnectionChanged: (_) => weaver.emitStatus().ignore(),
    );

    // ── Leader-Election-Engine ─────────────────────────────────────────────
    final election = LeaderElectionEngine(
      peers: peers,
      localDeviceId: deviceId,
      localDeviceShortId: shortId,
      broadcast: (packet) async {
        late Uint8List bytes;
        if (packet is BleHeartbeatPacket) {
          bytes = packet.toBytes();
        } else if (packet is BleElectionBidPacket) {
          bytes = packet.toBytes();
        } else {
          return;
        }
        await gossip.broadcastControlPacket(bytes);
      },
      onLeadershipChanged: ({
        required String newLeaderId,
        required bool isThisDeviceLeader,
        required int winningScore,
      }) =>
          weaver.handleLeadershipChange(
            newLeaderId: newLeaderId,
            isThisDeviceLeader: isThisDeviceLeader,
            winningScore: winningScore,
          ),
    );

    // ── GossipEngine ───────────────────────────────────────────────────────
    gossip = GossipEngine(
      ble: ble,
      peers: peers,
      crypto: crypto,
      queue: queueDao,
      localShortId: shortId,
    );

    // ── NetworkRepositoryWeaver ────────────────────────────────────────────
    weaver = NetworkRepositoryWeaver(
      ble: ble,
      gossip: gossip,
      ws: ws,
      inventoryDao: inventoryDao,
      queueDao: queueDao,
      chatDao: chatDao,
      election: election,
      crypto: crypto,
      peers: peers,
      emitEvent: _eventController.add,
      localDeviceId: deviceId,
      localShortId: shortId,
    );

    _weaver = weaver;
    await _weaver!.start();
  }

  // ─── Web Init (Browser) ───────────────────────────────────────────────────

  /// Initialisiert den Stack für Web-Plattformen.
  ///
  /// Verwendet In-Memory-Stubs für alle persistierenden Services da SQLite
  /// im Browser nicht verfügbar ist. BLE wird durch StubBleService ersetzt.
  /// Election läuft ohne BLE-Broadcast (kein Mesh auf Web).
  Future<void> _initWeb(String deviceId) async {
    final shortId = shortIdFromString(deviceId);
    final crypto = await AesGcmService.withProductionKey();
    final peers = PeerRegistry();

    final ble = StubBleService();
    final queueDao = _WebNoOpQueue();
    final inventoryDao = _WebNoOpInventory();
    final chatDao = _WebNoOpChat();

    // Auf Web keine aktive Leader-Election (kein BLE-Mesh).
    final election = LeaderElectionEngine(
      peers: peers,
      localDeviceId: deviceId,
      localDeviceShortId: shortId,
      broadcast: (_) async {},
      onLeadershipChanged: ({
        required String newLeaderId,
        required bool isThisDeviceLeader,
        required int winningScore,
      }) {},
    );

    final gossip = GossipEngine(
      ble: ble,
      peers: peers,
      crypto: crypto,
      queue: queueDao,
      localShortId: shortId,
    );

    late NetworkRepositoryWeaver weaver;

    weaver = NetworkRepositoryWeaver(
      ble: ble,
      gossip: gossip,
      ws: WebSocketService(
        onServerMessage: (msg) => weaver.onServerMessage(msg),
        onConnectionChanged: (_) => weaver.emitStatus().ignore(),
      ),
      inventoryDao: inventoryDao,
      queueDao: queueDao,
      chatDao: chatDao,
      election: election,
      crypto: crypto,
      peers: peers,
      emitEvent: _eventController.add,
      localDeviceId: deviceId,
      localShortId: shortId,
    );

    _weaver = weaver;
    await _weaver!.start();
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Web No-Op Storage (in-memory, kein Persist) für Browser-Modus
// ─────────────────────────────────────────────────────────────────────────────

class _WebNoOpQueue implements PacketQueueDao {
  int _nextId = 1;

  @override
  Future<int> enqueue({
    required List<int> encryptedPayload,
    String? targetDeviceId,
    required int packetTypeByte,
    required int nowMs,
  }) async =>
      _nextId++;

  @override
  Future<List<PacketQueueData>> dequeueForDelivery(String peerId) async => [];

  @override
  Future<List<PacketQueueData>> dequeueBroadcastPending() async => [];

  @override
  Future<void> markDelivered(int rowId) async {}

  @override
  Future<void> incrementRetryCount(int rowId) async {}

  @override
  Future<int> purgeDelivered() async => 0;

  @override
  Future<int> purgeStale() async => 0;

  @override
  Future<int> pendingCount() async => 0;
}

class _WebNoOpInventory implements InventoryDao {
  @override
  Future<InventoryItem?> getByItemId(String itemId) async => null;

  @override
  Future<InventoryItem?> getByShortId(int shortId) async => null;

  @override
  Future<int> upsertCrdt(InventoryItemCrdt crdt) async => 0;

  @override
  Future<InventoryItemCrdt> mergeRemote(InventoryItemCrdt remote) async =>
      remote;

  @override
  Future<void> markSynced(String itemId) async {}

  @override
  Future<void> markAllUnsynced() async {}

  @override
  Future<List<InventoryItem>> getAllItems() async => [];

  @override
  Future<List<InventoryItem>> getPendingSyncItems() async => [];

  @override
  Stream<List<InventoryItem>> watchAllItems() => const Stream.empty();
}

class _WebNoOpChat implements ChatDao {
  @override
  Future<void> insertMessage({
    required String messageId,
    required String senderDeviceId,
    required int senderShortId,
    required String senderLabel,
    required String content,
    required int timestampMs,
    required bool isMine,
  }) async {}

  @override
  Future<List<ChatMessage>> getRecentMessages({int limit = 100}) async => [];

  @override
  Stream<List<ChatMessage>> watchMessages({int limit = 200}) =>
      const Stream.empty();

  @override
  Future<int> purgeOld({int maxAgeMs = 86400000}) async => 0;
}
