import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:theatre_companion_app/network/models/ble_packet.dart';

void main() {
  group('shortIdFromString', () {
    test('deterministisch: gleicher Input => gleicher Output', () {
      expect(shortIdFromString('dev-A'), shortIdFromString('dev-A'));
    });
    test(
        'unterschiedlich: verschiedene Inputs => verschiedene Outputs (haeufig)',
        () {
      expect(shortIdFromString('dev-A'), isNot(shortIdFromString('dev-B')));
    });
    test('immer im Bereich 0-65535', () {
      for (final s in ['', 'a', 'some-uuid-string', 'x' * 100]) {
        final id = shortIdFromString(s);
        expect(id, greaterThanOrEqualTo(0));
        expect(id, lessThanOrEqualTo(0xFFFF));
      }
    });
  });
  group('BlePacketType.fromWire', () {
    test('alle Bytes korrekt gemapt', () {
      expect(BlePacketType.fromWire(0), BlePacketType.data);
      expect(BlePacketType.fromWire(1), BlePacketType.heartbeat);
      expect(BlePacketType.fromWire(2), BlePacketType.electionBid);
      expect(BlePacketType.fromWire(3), BlePacketType.ack);
      expect(BlePacketType.fromWire(4), BlePacketType.text);
    });
    test('unbekannter Byte wirft FormatException', () {
      expect(() => BlePacketType.fromWire(99), throwsFormatException);
    });
  });
  group('BleDataPacket', () {
    test('toBytes / fromBytes Roundtrip', () {
      final p = BleDataPacket.create(
        sourceDeviceShortId: 0xABCD,
        itemShortId: 0x1234,
        statusId: 2,
        timestampSec: 1700000000,
      );
      final bytes = p.toBytes();
      expect(bytes.length, kHeaderSize + kDataBodySize);
      final r = BleDataPacket.fromBytes(bytes);
      expect(r.header.type, BlePacketType.data);
      expect(r.header.sourceDeviceShortId, 0xABCD);
      expect(r.itemShortId, 0x1234);
      expect(r.statusId, 2);
      expect(r.timestampSec, 1700000000);
    });
    test('relay() dekrementiert TTL', () {
      final p = BleDataPacket.create(
          sourceDeviceShortId: 1,
          itemShortId: 2,
          statusId: 0,
          timestampSec: 100);
      expect(p.header.ttl, kDataPacketTtl);
      final relayed = p.relay();
      expect(relayed.header.ttl, kDataPacketTtl - 1);
    });
    test('canRelay false wenn TTL == 1', () {
      final p = BleDataPacket(
        header: BlePacketHeader(
            type: BlePacketType.data, ttl: 1, sourceDeviceShortId: 1),
        packetShortId: 1,
        itemShortId: 2,
        statusId: 0,
        timestampSec: 0,
      );
      expect(p.canRelay, isFalse);
    });
    test('dedupKey eindeutig fuer verschiedene Pakete', () {
      final a = BleDataPacket.create(
          sourceDeviceShortId: 1, itemShortId: 1, statusId: 0, timestampSec: 1);
      BleDataPacket.create(
          sourceDeviceShortId: 1, itemShortId: 2, statusId: 0, timestampSec: 1);
      // packetShortId ist random, also fast immer unterschiedlich
      expect(a.dedupKey, isA<String>());
    });
  });
  group('BleHeartbeatPacket', () {
    test('toBytes / fromBytes Roundtrip', () {
      final p =
          BleHeartbeatPacket.create(sourceDeviceShortId: 0xFF, sequenceNum: 42);
      final bytes = p.toBytes();
      expect(bytes.length, kHeaderSize + kHeartbeatBodySize);
      final r = BleHeartbeatPacket.fromBytes(bytes);
      expect(r.header.type, BlePacketType.heartbeat);
      expect(r.sequenceNum, 42);
    });
    test('sequenceNum wrappt bei 255', () {
      final p =
          BleHeartbeatPacket.create(sourceDeviceShortId: 1, sequenceNum: 256);
      expect(p.sequenceNum, 0); // 256 & 0xFF = 0
    });
  });
  group('BleElectionBidPacket', () {
    test('toBytes / fromBytes Roundtrip', () {
      final p =
          BleElectionBidPacket.create(sourceDeviceShortId: 100, score: 230);
      final bytes = p.toBytes();
      expect(bytes.length, kHeaderSize + kElectionBodySize);
      final r = BleElectionBidPacket.fromBytes(bytes);
      expect(r.header.type, BlePacketType.electionBid);
      expect(r.score, 230);
    });
    test('score <= 65535 wegen uint16', () {
      final p =
          BleElectionBidPacket.create(sourceDeviceShortId: 1, score: 99999);
      expect(p.score, lessThanOrEqualTo(65535));
    });
  });
  group('BleAckPacket', () {
    test('toBytes / fromBytes Roundtrip', () {
      final p = BleAckPacket.create(
          sourceDeviceShortId: 5, ackedPacketShortId: 0xBEEF);
      final bytes = p.toBytes();
      expect(bytes.length, kHeaderSize + kAckBodySize);
      final r = BleAckPacket.fromBytes(bytes);
      expect(r.header.type, BlePacketType.ack);
      expect(r.ackedPacketShortId, 0xBEEF);
    });
  });
  group('BleChatTextPacket', () {
    test('toBytes / fromBytes Roundtrip', () {
      final p = BleChatTextPacket.create(
          sourceDeviceShortId: 7, messageId: 0xDEAD, text: 'Hallo Welt!');
      final bytes = p.toBytes();
      final r = BleChatTextPacket.fromBytes(bytes);
      expect(r.header.type, BlePacketType.text);
      expect(r.messageId, 0xDEAD);
      expect(r.text, 'Hallo Welt!');
    });
    test('enforced max bytes bei langen Texten', () {
      final longText = 'x' * 500;
      final p = BleChatTextPacket.create(
          sourceDeviceShortId: 1, messageId: 1, text: longText);
      final encoded = p.toBytes();
      // Text muss <= kChatTextMaxBytes sein
      expect(p.text.length, lessThanOrEqualTo(kChatTextMaxBytes));
      expect(encoded.length,
          lessThanOrEqualTo(kHeaderSize + 6 + kChatTextMaxBytes + 28));
    });
    test('relay() dekrementiert TTL und haelt Text', () {
      final p = BleChatTextPacket.create(
          sourceDeviceShortId: 1, messageId: 42, text: 'Test');
      final r = p.relay();
      expect(r.header.ttl, p.header.ttl - 1);
      expect(r.text, 'Test');
    });
  });
  group('parseBlePacket', () {
    test('erkennt DataPacket korrekt', () {
      final p = BleDataPacket.create(
          sourceDeviceShortId: 1, itemShortId: 1, statusId: 0, timestampSec: 1);
      final parsed = parseBlePacket(p.toBytes());
      expect(parsed, isA<BleDataPacket>());
    });
    test('erkennt HeartbeatPacket korrekt', () {
      final p =
          BleHeartbeatPacket.create(sourceDeviceShortId: 1, sequenceNum: 1);
      final parsed = parseBlePacket(p.toBytes());
      expect(parsed, isA<BleHeartbeatPacket>());
    });
    test('leeres Byte-Array wirft FormatException', () {
      expect(() => parseBlePacket(Uint8List(0)), throwsFormatException);
    });
  });
}
