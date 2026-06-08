/// gossip_engine_test.dart
/// ──────────────────────────
/// Unit-Tests für den GossipEngine.
///
/// Getestete Verhalten:
///   1. Deduplizierung: Dasselbe Paket wird nur einmal weitergeleitet.
///   2. TTL-Durchsetzung: Pakete mit TTL=1 werden nicht weitergeleitet.
///   3. Store-Carry-Forward: Bei 0 Peers → in die Queue einreihen.
///   4. drainQueueForPeer: Verwendet sendRawEncryptedPacket (kein Re-Encrypt).
///   5. Bei Sendefehler: RetryCount inkrementieren.
library gossip_engine_test;
import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:theatre_companion_app/network/ble/gossip_engine.dart';
import 'package:theatre_companion_app/network/crypto/aes_gcm_service.dart';
import 'package:theatre_companion_app/network/db/app_database.dart';
import 'package:theatre_companion_app/network/db/dao/packet_queue_dao.dart';
import 'package:theatre_companion_app/network/models/ble_packet.dart';
import 'package:theatre_companion_app/network/platform/abstract_ble_service.dart';
import 'package:theatre_companion_app/network/routing/peer_registry.dart';
// ─── Mock-Klassen ─────────────────────────────────────────────────────────────
class MockBleService extends Mock implements AbstractBleService {}
class MockPacketQueueDao extends Mock implements PacketQueueDao {}
class MockAesGcmService extends Mock implements AesGcmService {}
// ─── Hilfsfunktionen ─────────────────────────────────────────────────────────
/// Erstellt ein BleDataPacket mit konfigurierbarem TTL.
BleDataPacket makeDataPacket({int ttl = kDataPacketTtl, int shortId = 0xBEEF}) {
  return BleDataPacket(
    header: BlePacketHeader(
      type: BlePacketType.data,
      ttl: ttl,
      sourceDeviceShortId: 0x1234,
    ),
    packetShortId: shortId,
    itemShortId: 0x5678,
    statusId: 1,
    timestampSec: 1000000,
  );
}
// ─────────────────────────────────────────────────────────────────────────────
void main() {
  late MockBleService ble;
  late MockPacketQueueDao queue;
  late MockAesGcmService crypto;
  late PeerRegistry peers;
  late GossipEngine engine;
  setUpAll(() {
    registerFallbackValue(Uint8List(0));
  });
  setUp(() {
    ble = MockBleService();
    queue = MockPacketQueueDao();
    crypto = MockAesGcmService();
    peers = PeerRegistry();
    engine = GossipEngine(
      ble: ble,
      peers: peers,
      crypto: crypto,
      queue: queue,
      localShortId: 0xABCD,
    );
    // Standard-Stubs
    when(() => ble.sendPacket(any(), any())).thenAnswer((_) async {});
    when(() => ble.sendRawEncryptedPacket(any(), any())).thenAnswer((_) async {});
    when(() => ble.broadcastToSubscribers(any())).thenAnswer((_) async {});
    when(() => crypto.encrypt(any()))
        .thenAnswer((_) async => Uint8List.fromList([0x01, 0x02, 0x03, 0x04]));
    when(() => queue.enqueue(
          encryptedPayload: any(named: 'encryptedPayload'),
          targetDeviceId: any(named: 'targetDeviceId'),
          packetTypeByte: any(named: 'packetTypeByte'),
          nowMs: any(named: 'nowMs'),
        )).thenAnswer((_) async => 1);
    when(() => queue.dequeueForDelivery(any())).thenAnswer((_) async => []);
    when(() => queue.markDelivered(any())).thenAnswer((_) async {});
    when(() => queue.incrementRetryCount(any())).thenAnswer((_) async {});
  });
  // ─── Deduplizierung ────────────────────────────────────────────────────────
  group('Deduplizierung', () {
    test('dasselbe Paket wird nur einmal weitergeleitet', () async {
      peers.touchPeer(deviceId: 'peer-1', deviceShortId: 1, rssi: -60);
      final packet = makeDataPacket();
      await engine.onDataPacketReceived(packet, 'sender-x');
      await engine.onDataPacketReceived(packet, 'sender-x'); // Duplikat
      // sendRawEncryptedPacket darf nur 1x aufgerufen werden
      verify(() => ble.sendRawEncryptedPacket(any(), any())).called(1);
    });
    test('zwei verschiedene Pakete werden beide weitergeleitet', () async {
      peers.touchPeer(deviceId: 'peer-1', deviceShortId: 1, rssi: -60);
      final p1 = makeDataPacket(shortId: 0xAAAA);
      final p2 = makeDataPacket(shortId: 0xBBBB);
      await engine.onDataPacketReceived(p1, 'sender-1');
      await engine.onDataPacketReceived(p2, 'sender-2');
      // Beide weitergeleitet → 2 Aufrufe insgesamt
      verify(() => ble.sendRawEncryptedPacket(any(), any())).called(2);
    });
    test('originateDataPacket markiert Paket als gesehen – Relay-Loop verhindert', () async {
      peers.touchPeer(deviceId: 'peer-1', deviceShortId: 1, rssi: -60);
      final packet = BleDataPacket.create(
        sourceDeviceShortId: 0xABCD,
        itemShortId: 0x1111,
        statusId: 1,
        timestampSec: 1000000,
      );
      await engine.originateDataPacket(packet);
      // Wenn dasselbe Paket zurückkommt → nicht nochmal weiterleiten
      await engine.onDataPacketReceived(packet, 'peer-1');
      verify(() => ble.sendRawEncryptedPacket(any(), any())).called(1);
    });
  });
  // ─── TTL-Durchsetzung ─────────────────────────────────────────────────────
  group('TTL-Durchsetzung', () {
    test('TTL=1 → canRelay=false → kein Relay', () async {
      peers.touchPeer(deviceId: 'peer-1', deviceShortId: 1, rssi: -60);
      final packet = makeDataPacket(ttl: 1);
      await engine.onDataPacketReceived(packet, 'sender');
      verifyNever(() => ble.sendRawEncryptedPacket(any(), any()));
    });
    test('TTL=2 → canRelay=true → wird weitergeleitet (neuer TTL=1)', () async {
      peers.touchPeer(deviceId: 'peer-1', deviceShortId: 1, rssi: -60);
      final packet = makeDataPacket(ttl: 2);
      await engine.onDataPacketReceived(packet, 'peer-other');
      verify(() => ble.sendRawEncryptedPacket('peer-1', any())).called(1);
    });
    test('TTL=5 → weiterleiten und nicht an Absender zurück', () async {
      peers.touchPeer(deviceId: 'peer-1', deviceShortId: 1, rssi: -60);
      peers.touchPeer(deviceId: 'peer-2', deviceShortId: 2, rssi: -70);
      final packet = makeDataPacket(ttl: 5);
      await engine.onDataPacketReceived(packet, 'peer-1'); // sender=peer-1
      // Soll NICHT an peer-1 zurück senden (excludeId)
      verifyNever(() => ble.sendRawEncryptedPacket('peer-1', any()));
      // Soll an peer-2 senden
      verify(() => ble.sendRawEncryptedPacket('peer-2', any())).called(1);
    });
  });
  // ─── Store-Carry-Forward ──────────────────────────────────────────────────
  group('Store-Carry-Forward', () {
    test('keine Peers verfügbar → Broadcast in Queue einreihen', () async {
      // Keine Peers hinzugefügt
      final packet = BleDataPacket.create(
        sourceDeviceShortId: 0xABCD,
        itemShortId: 0x1234,
        statusId: 2,
        timestampSec: 2000000,
      );
      await engine.originateDataPacket(packet);
      verify(() => queue.enqueue(
            encryptedPayload: any(named: 'encryptedPayload'),
            targetDeviceId: null, // Broadcast-Eintrag
            packetTypeByte: BlePacketType.data.wireValue,
            nowMs: any(named: 'nowMs'),
          )).called(1);
      verifyNever(() => ble.sendRawEncryptedPacket(any(), any()));
    });
    test('drainQueueForPeer verwendet sendRawEncryptedPacket – kein Re-Encrypt', () async {
      // BUG-FIX Verifikation: Doppel-Verschlüsselung muss verhindert werden.
      final encBytes = Uint8List.fromList([0xDE, 0xAD, 0xBE, 0xEF, 0xCA, 0xFE]);
      final fakeRow = PacketQueueData(
        id: 42,
        encryptedPayload: encBytes,
        targetDeviceId: 'peer-1',
        packetTypeByte: BlePacketType.data.wireValue,
        createdAtMs: DateTime.now().millisecondsSinceEpoch,
        retryCount: 0,
        isDelivered: false,
      );
      when(() => queue.dequeueForDelivery('peer-1'))
          .thenAnswer((_) async => [fakeRow]);
      await engine.drainQueueForPeer('peer-1');
      // MUSS sendRawEncryptedPacket verwenden
      verify(() => ble.sendRawEncryptedPacket('peer-1', any())).called(1);
      // DARF NICHT sendPacket verwenden (würde erneut verschlüsseln)
      verifyNever(() => ble.sendPacket(any(), any()));
      // Nach Erfolg: markDelivered aufrufen
      verify(() => queue.markDelivered(42)).called(1);
    });
    test('drainQueueForPeer inkrementiert RetryCount bei Sendefehler', () async {
      final fakeRow = PacketQueueData(
        id: 99,
        encryptedPayload: Uint8List.fromList([0xCA, 0xFE]),
        targetDeviceId: 'peer-1',
        packetTypeByte: BlePacketType.data.wireValue,
        createdAtMs: DateTime.now().millisecondsSinceEpoch,
        retryCount: 1,
        isDelivered: false,
      );
      when(() => queue.dequeueForDelivery('peer-1'))
          .thenAnswer((_) async => [fakeRow]);
      when(() => ble.sendRawEncryptedPacket(any(), any()))
          .thenThrow(Exception('BLE-Verbindungsfehler'));
      await engine.drainQueueForPeer('peer-1');
      verifyNever(() => queue.markDelivered(any()));
      verify(() => queue.incrementRetryCount(99)).called(1);
    });
    test('drainQueueForPeer liefert mehrere Pakete in Reihenfolge', () async {
      final rows = [
        PacketQueueData(
          id: 1,
          encryptedPayload: Uint8List.fromList([0x01]),
          targetDeviceId: 'peer-1',
          packetTypeByte: BlePacketType.data.wireValue,
          createdAtMs: 1000,
          retryCount: 0,
          isDelivered: false,
        ),
        PacketQueueData(
          id: 2,
          encryptedPayload: Uint8List.fromList([0x02]),
          targetDeviceId: 'peer-1',
          packetTypeByte: BlePacketType.data.wireValue,
          createdAtMs: 2000,
          retryCount: 0,
          isDelivered: false,
        ),
      ];
      when(() => queue.dequeueForDelivery('peer-1')).thenAnswer((_) async => rows);
      await engine.drainQueueForPeer('peer-1');
      verify(() => ble.sendRawEncryptedPacket('peer-1', any())).called(2);
      verify(() => queue.markDelivered(1)).called(1);
      verify(() => queue.markDelivered(2)).called(1);
    });
  });
  // ─── originateDataPacket ──────────────────────────────────────────────────
  group('originateDataPacket', () {
    test('sendet an verfügbare Peers', () async {
      peers.touchPeer(deviceId: 'peer-1', deviceShortId: 1, rssi: -60);
      peers.touchPeer(deviceId: 'peer-2', deviceShortId: 2, rssi: -70);
      final packet = BleDataPacket.create(
        sourceDeviceShortId: 0xABCD,
        itemShortId: 0x1234,
        statusId: 2,
        timestampSec: 2000000,
      );
      await engine.originateDataPacket(packet);
      // GossipFanout = 3, aber nur 2 Peers verfügbar → 2 Aufrufe
      final callCount = verify(() => ble.sendRawEncryptedPacket(any(), any())).callCount;
      expect(callCount, inInclusiveRange(1, 2));
    });
  });
  // ─── broadcastControlPacket ───────────────────────────────────────────────
  group('broadcastControlPacket', () {
    test('sendet an alle lebenden Peers', () async {
      peers.touchPeer(deviceId: 'peer-A', deviceShortId: 10, rssi: -55);
      peers.touchPeer(deviceId: 'peer-B', deviceShortId: 20, rssi: -65);
      await engine.broadcastControlPacket(Uint8List.fromList([0xFF, 0x00]));
      verify(() => ble.sendPacket('peer-A', any())).called(1);
      verify(() => ble.sendPacket('peer-B', any())).called(1);
    });
    test('keine Peers → keine Aufrufe', () async {
      await engine.broadcastControlPacket(Uint8List.fromList([0xFF]));
      verifyNever(() => ble.sendPacket(any(), any()));
    });
  });
}
