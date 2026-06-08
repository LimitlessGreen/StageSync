import 'dart:async';
import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:theatre_companion_app/network/ble/gossip_engine.dart';
import 'package:theatre_companion_app/network/coordinator/network_repository_weaver.dart';
import 'package:theatre_companion_app/network/crypto/aes_gcm_service.dart';
import 'package:theatre_companion_app/network/db/app_database.dart';
import 'package:theatre_companion_app/network/db/dao/chat_dao.dart';
import 'package:theatre_companion_app/network/db/dao/inventory_dao.dart';
import 'package:theatre_companion_app/network/db/dao/packet_queue_dao.dart';
import 'package:theatre_companion_app/network/isolate/isolate_messages.dart';
import 'package:theatre_companion_app/network/models/ble_packet.dart';
import 'package:theatre_companion_app/network/models/inventory_item_crdt.dart';
import 'package:theatre_companion_app/network/platform/abstract_ble_service.dart';
import 'package:theatre_companion_app/network/routing/leader_election_engine.dart';
import 'package:theatre_companion_app/network/routing/peer_registry.dart';
import 'package:theatre_companion_app/network/server/websocket_service.dart';

class MockGossipEngine extends Mock implements GossipEngine {}

class MockWebSocketService extends Mock implements WebSocketService {}

class MockInventoryDao extends Mock implements InventoryDao {}

class MockPacketQueueDao extends Mock implements PacketQueueDao {}

class MockChatDao extends Mock implements ChatDao {}

class MockLeaderElectionEngine extends Mock implements LeaderElectionEngine {}

class MockAesGcmService extends Mock implements AesGcmService {}

class FakeBleService extends Mock implements AbstractBleService {
  final _controller = StreamController<IncomingBlePacket>.broadcast();
  @override
  Stream<IncomingBlePacket> get onPacketReceived => _controller.stream;
  void injectPacket(IncomingBlePacket p) => _controller.add(p);
  Future<void> dispose() => _controller.close();
}

InventoryItemCrdt makeTestCrdt(
    {String itemId = 'item-test-001', int statusId = 1}) {
  return InventoryItemCrdt.create(
    itemId: itemId,
    deviceId: 'local-device',
    deviceShortId: 0xAAAA,
    statusId: statusId,
    locationTag: null,
    wallClockMs: 1000000,
  );
}

/// Erstellt ein echtes Drift-InventoryItem aus einem CRDT fuer Tests.
InventoryItem inventoryItemFromCrdt(InventoryItemCrdt crdt) {
  return InventoryItem(
    id: 1,
    itemId: crdt.itemId,
    crdtJson: crdt.toJsonString(),
    statusId: crdt.status.value,
    locationTag: crdt.location.value,
    lastUpdatedMs: crdt.status.wallClockMs,
    sourceDeviceId: 'test-device',
    isSyncedToServer: false,
  );
}

void main() {
  late FakeBleService ble;
  late MockGossipEngine gossip;
  late MockWebSocketService ws;
  late MockInventoryDao inventoryDao;
  late MockPacketQueueDao queueDao;
  late MockChatDao chatDao;
  late MockLeaderElectionEngine election;
  late MockAesGcmService crypto;
  late PeerRegistry peers;
  late List<NetworkEvent> emittedEvents;
  late NetworkRepositoryWeaver weaver;
  setUpAll(() {
    registerFallbackValue(Uint8List(0));
    registerFallbackValue(makeTestCrdt());
    registerFallbackValue(BleDataPacket.create(
      sourceDeviceShortId: 0,
      itemShortId: 0,
      statusId: 0,
      timestampSec: 0,
    ));
    registerFallbackValue(BleChatTextPacket.create(
      sourceDeviceShortId: 0,
      messageId: 0,
      text: '',
    ));
    registerFallbackValue(BleHeartbeatPacket.create(
      sourceDeviceShortId: 0,
      sequenceNum: 0,
    ));
    registerFallbackValue(BleElectionBidPacket.create(
      sourceDeviceShortId: 0,
      score: 0,
    ));
    registerFallbackValue(BleAckPacket.create(
      sourceDeviceShortId: 0,
      ackedPacketShortId: 0,
    ));
  });
  setUp(() {
    ble = FakeBleService();
    gossip = MockGossipEngine();
    ws = MockWebSocketService();
    inventoryDao = MockInventoryDao();
    queueDao = MockPacketQueueDao();
    chatDao = MockChatDao();
    election = MockLeaderElectionEngine();
    crypto = MockAesGcmService();
    peers = PeerRegistry();
    emittedEvents = [];
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
      emitEvent: (e) => emittedEvents.add(e),
      localDeviceId: 'local-device',
      localShortId: 0xAAAA,
    );
    when(() => election.isLeader).thenReturn(false);
    when(() => election.currentLeaderId).thenReturn(null);
    when(() => election.computeScoreBreakdown()).thenAnswer((_) async =>
        const NetworkScoreBreakdown(
            hasNetwork: false,
            isCharging: false,
            batteryPercent: 50,
            isMoving: false,
            total: 50));
    when(() => election.startElectionRound()).thenAnswer((_) async {});
    when(() => election.start()).thenAnswer((_) async {});
    when(() => election.stop()).thenAnswer((_) async {});
    when(() => election.onHeartbeatReceived(any())).thenReturn(null);
    when(() => election.onBidReceived(any(), any())).thenReturn(null);
    when(() => ws.isConnected).thenReturn(false);
    when(() => ws.disconnect()).thenAnswer((_) async {});
    when(() => ws.send(any())).thenReturn(null);
    when(() => ble.start()).thenAnswer((_) async {});
    when(() => ble.stop()).thenAnswer((_) async {});
    when(() => inventoryDao.getByItemId(any())).thenAnswer((_) async => null);
    when(() => inventoryDao.upsertCrdt(any())).thenAnswer((_) async => 1);
    when(() => inventoryDao.getByShortId(any())).thenAnswer((_) async => null);
    when(() => inventoryDao.mergeRemote(any())).thenAnswer(
        (inv) async => inv.positionalArguments[0] as InventoryItemCrdt);
    when(() => inventoryDao.markSynced(any())).thenAnswer((_) async {});
    when(() => queueDao.pendingCount()).thenAnswer((_) async => 0);
    when(() => queueDao.purgeDelivered()).thenAnswer((_) async => 0);
    when(() => queueDao.purgeStale()).thenAnswer((_) async => 0);
    when(() => chatDao.insertMessage(
          messageId: any(named: 'messageId'),
          senderDeviceId: any(named: 'senderDeviceId'),
          senderShortId: any(named: 'senderShortId'),
          senderLabel: any(named: 'senderLabel'),
          content: any(named: 'content'),
          timestampMs: any(named: 'timestampMs'),
          isMine: any(named: 'isMine'),
        )).thenAnswer((_) async {});
    when(() => gossip.originateDataPacket(any())).thenAnswer((_) async {});
    when(() => gossip.originateChatPacket(any())).thenAnswer((_) async {});
    when(() => gossip.onDataPacketReceived(any(), any()))
        .thenAnswer((_) async {});
    when(() => gossip.onChatPacketReceived(any(), any()))
        .thenAnswer((_) async {});
    when(() => gossip.drainQueueForPeer(any())).thenAnswer((_) async {});
    when(() => gossip.broadcastControlPacket(any())).thenAnswer((_) async {});
    when(() => crypto.encrypt(any()))
        .thenAnswer((_) async => Uint8List.fromList([0x01, 0x02]));
    when(() => crypto.decrypt(any())).thenAnswer((_) async =>
        Uint8List.fromList(makeTestCrdt().toJsonString().codeUnits));
  });
  tearDown(() async {
    await ble.dispose();
  });
  // --- ScanItemCommand - Follower ---
  group('ScanItemCommand - Follower-Pfad', () {
    test('neues Item wird in DB persistiert und via Gossip weitergeleitet',
        () async {
      await weaver.handleCommand(ScanItemCommand(
          itemId: 'item-scan-001', statusId: 2, timestampMs: 2000000));
      verify(() => inventoryDao.upsertCrdt(any())).called(1);
      verify(() => gossip.originateDataPacket(any())).called(1);
      verifyNever(() => ws.send(any()));
    });
    test('emittiert sofortiges ItemUpdatedEvent', () async {
      await weaver.handleCommand(ScanItemCommand(
          itemId: 'item-scan-002', statusId: 3, timestampMs: 1500000));
      final updates = emittedEvents.whereType<ItemUpdatedEvent>().toList();
      expect(updates, hasLength(1));
      expect(updates.first.itemId, equals('item-scan-002'));
      expect(updates.first.statusId, equals(3));
      expect(updates.first.isSyncedToServer, isFalse);
    });
    test('vorhandenes Item wird via getByItemId geladen und aktualisiert',
        () async {
      final existingCrdt = makeTestCrdt(itemId: 'item-existing', statusId: 1);
      when(() => inventoryDao.getByItemId('item-existing'))
          .thenAnswer((_) async => inventoryItemFromCrdt(existingCrdt));
      await weaver.handleCommand(ScanItemCommand(
          itemId: 'item-existing', statusId: 5, timestampMs: 3000000));
      verify(() => inventoryDao.upsertCrdt(any())).called(1);
    });
  });
  // --- ScanItemCommand - Leader ---
  group('ScanItemCommand - Leader-Pfad', () {
    test('Leader mit WS sendet direkt zum Server', () async {
      when(() => election.isLeader).thenReturn(true);
      when(() => ws.isConnected).thenReturn(true);
      await weaver.handleCommand(ScanItemCommand(
          itemId: 'item-leader-scan', statusId: 1, timestampMs: 1000000));
      verify(() => ws.send(any())).called(1);
      verifyNever(() => gossip.originateDataPacket(any()));
    });
    test('Leader ohne WS nutzt Gossip als Fallback', () async {
      when(() => election.isLeader).thenReturn(true);
      when(() => ws.isConnected).thenReturn(false);
      await weaver.handleCommand(ScanItemCommand(
          itemId: 'item-leader-offline', statusId: 2, timestampMs: 1000000));
      verifyNever(() => ws.send(any()));
      verify(() => gossip.originateDataPacket(any())).called(1);
    });
  });
  // --- Eingehende BLE DataPackets ---
  group('Eingehende BLE DataPackets', () {
    test('bekanntes Item - CRDT-Merge + ItemUpdatedEvent', () async {
      await weaver.start();
      addTearDown(weaver.stop);
      const knownItemId = 'item-known-001';
      final crdt = makeTestCrdt(itemId: knownItemId);
      when(() => inventoryDao.getByShortId(any()))
          .thenAnswer((_) async => inventoryItemFromCrdt(crdt));
      when(() => inventoryDao.mergeRemote(any())).thenAnswer((_) async => crdt);
      ble.injectPacket(IncomingBlePacket(
        senderDeviceId: 'peer-sender',
        packet: BleDataPacket.create(
          sourceDeviceShortId: 0xBBBB,
          itemShortId: shortIdFromString(knownItemId),
          statusId: 3,
          timestampSec: 2000,
        ),
      ));
      await Future.delayed(const Duration(milliseconds: 50));
      verify(() => inventoryDao.mergeRemote(any())).called(1);
      expect(emittedEvents.whereType<ItemUpdatedEvent>(), isNotEmpty);
    });
    test('unbekanntes Item - Preview-ItemUpdatedEvent mit ~XXXX-Prefix',
        () async {
      await weaver.start();
      addTearDown(weaver.stop);
      when(() => inventoryDao.getByShortId(any()))
          .thenAnswer((_) async => null);
      ble.injectPacket(IncomingBlePacket(
        senderDeviceId: 'peer-sender',
        packet: BleDataPacket.create(
          sourceDeviceShortId: 0xBBBB,
          itemShortId: 0x1234,
          statusId: 2,
          timestampSec: 1000,
        ),
      ));
      await Future.delayed(const Duration(milliseconds: 50));
      verifyNever(() => inventoryDao.mergeRemote(any()));
      final updates = emittedEvents.whereType<ItemUpdatedEvent>().toList();
      expect(updates, isNotEmpty);
      expect(updates.first.itemId, startsWith('~'));
    });
    test('eingehender Heartbeat - election.onHeartbeatReceived()', () async {
      await weaver.start();
      addTearDown(weaver.stop);
      ble.injectPacket(IncomingBlePacket(
        senderDeviceId: 'peer-leader',
        packet: BleHeartbeatPacket.create(
            sourceDeviceShortId: 0x9999, sequenceNum: 1),
      ));
      await Future.delayed(const Duration(milliseconds: 20));
      verify(() => election.onHeartbeatReceived('peer-leader')).called(1);
    });
    test('eingehendes ElectionBid - election.onBidReceived()', () async {
      await weaver.start();
      addTearDown(weaver.stop);
      ble.injectPacket(IncomingBlePacket(
        senderDeviceId: 'peer-bidder',
        packet: BleElectionBidPacket.create(
            sourceDeviceShortId: 0x7777, score: 200),
      ));
      await Future.delayed(const Duration(milliseconds: 20));
      verify(() => election.onBidReceived('peer-bidder', 200)).called(1);
    });
  });
  // --- Peer-Topologie ---
  group('Peer-Topologie', () {
    test('neuer Peer online - gossip.drainQueueForPeer()', () async {
      await weaver.start();
      addTearDown(weaver.stop);
      peers.upsert(PeerInfo(
        deviceId: 'new-peer-002',
        deviceShortId: 2,
        rssi: -65,
        lastSeenMs: DateTime.now().millisecondsSinceEpoch,
      ));
      await Future.delayed(const Duration(milliseconds: 20));
      verify(() => gossip.drainQueueForPeer('new-peer-002')).called(1);
    });
  });
  // --- handleLeadershipChange ---
  group('handleLeadershipChange', () {
    test('emittiert LeaderChangedEvent', () {
      weaver.handleLeadershipChange(
          newLeaderId: 'device-leader',
          isThisDeviceLeader: true,
          winningScore: 180);
      final events = emittedEvents.whereType<LeaderChangedEvent>().toList();
      expect(events, hasLength(1));
      expect(events.first.newLeaderDeviceId, equals('device-leader'));
      expect(events.first.isThisDeviceLeader, isTrue);
      expect(events.first.leaderScore, equals(180));
    });
  });
  // --- ForceElectionCommand ---
  group('ForceElectionCommand', () {
    test('ruft election.startElectionRound() auf', () async {
      await weaver.handleCommand(ForceElectionCommand());
      verify(() => election.startElectionRound()).called(1);
    });
  });
  // --- ConnectToServerCommand ---
  group('ConnectToServerCommand', () {
    test('wird von Follower ignoriert', () async {
      when(() => ws.connect(any())).thenAnswer((_) async {});
      await weaver
          .handleCommand(ConnectToServerCommand('wss://server.example.com'));
      verifyNever(() => ws.connect(any()));
    });
    test('Leader verbindet zum Server', () async {
      when(() => election.isLeader).thenReturn(true);
      when(() => ws.connect(any())).thenAnswer((_) async {});
      await weaver
          .handleCommand(ConnectToServerCommand('wss://server.example.com'));
      verify(() => ws.connect('wss://server.example.com')).called(1);
    });
  });
  // --- SendChatMessageCommand ---
  group('SendChatMessageCommand', () {
    test('persistiert Nachricht und emittiert ChatMessageReceivedEvent',
        () async {
      await weaver
          .handleCommand(SendChatMessageCommand(content: 'Hallo Buehne!'));
      verify(() => chatDao.insertMessage(
            messageId: any(named: 'messageId'),
            senderDeviceId: any(named: 'senderDeviceId'),
            senderShortId: any(named: 'senderShortId'),
            senderLabel: any(named: 'senderLabel'),
            content: 'Hallo Buehne!',
            timestampMs: any(named: 'timestampMs'),
            isMine: true,
          )).called(1);
      final chatEvents = emittedEvents.whereType<ChatMessageReceivedEvent>();
      expect(chatEvents, isNotEmpty);
      expect(chatEvents.first.content, equals('Hallo Buehne!'));
      expect(chatEvents.first.isMine, isTrue);
    });
    test('gossipiert Nachricht via BLE', () async {
      await weaver.handleCommand(SendChatMessageCommand(content: 'Test'));
      verify(() => gossip.originateChatPacket(any())).called(1);
    });
  });
}
