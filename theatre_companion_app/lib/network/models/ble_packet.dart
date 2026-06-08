// ble_packet.dart
// ────────────────
// Defines the compact binary packet format used for all BLE Mesh broadcasts.
//
// ## Packet Layout (before AES-GCM encryption)
//
// Every packet starts with a 4-byte shared header:
//   Offset  Size  Field
//   ──────  ────  ─────────────────────────────────────────────────
//   0       1 B   PacketType  (see [BlePacketType] enum, values 0-3)
//   1       1 B   TTL         (Time-To-Live hop counter; decremented on relay)
//   2       2 B   SourceDeviceShortId  (uint16 LE, lower 16 bits of device ID hash)
//
// DataPacket body (appended after header) = 9 B  → total plain = 13 B
//   4       2 B   PacketShortId  (uint16, random nonce for deduplication)
//   6       2 B   ItemShortId    (uint16, hash of the full item UUID)
//   8       1 B   StatusId
//   9       4 B   TimestampSec   (uint32 LE, Unix seconds – enough until 2106)
//
// HeartbeatPacket body = 1 B  → total plain = 5 B
//   4       1 B   SequenceNum  (uint8, wraps at 255; used for ordering)
//
// ElectionBidPacket body = 2 B  → total plain = 6 B
//   4       2 B   Score  (uint16 LE, clamped to 0-65535)
//
// AckPacket body = 2 B  → total plain = 6 B
//   4       2 B   AckedPacketShortId  (the PacketShortId being acknowledged)
//
// After AES-256-GCM encryption the on-wire size adds:
//   +12 B (nonce)  +16 B (authentication tag)
// Resulting in DataPacket wire size = 13 + 28 = 41 bytes – well inside BLE MTU.
import 'dart:convert';
import 'dart:math' show Random;
import 'dart:typed_data';

// ─────────────────────────────────────────────────────────────────────────────
// Constants
// ─────────────────────────────────────────────────────────────────────────────

/// Default TTL for data packets (each relay hop decrements by 1; drop at 0).
const int kDataPacketTtl = 5;

/// Heartbeat packets travel only one logical hop into the local cluster.
const int kHeartbeatTtl = 2;

/// Election bids propagate a bit further for wider topology coverage.
const int kElectionBidTtl = 3;

const int kHeaderSize = 4;
const int kDataBodySize = 9;
const int kHeartbeatBodySize = 1;
const int kElectionBodySize = 2;
const int kAckBodySize = 2;

// ─────────────────────────────────────────────────────────────────────────────
// Packet Type Enum
// ─────────────────────────────────────────────────────────────────────────────

/// Identifies the packet variant. Stored as a single byte.
enum BlePacketType {
  data(0),
  heartbeat(1),
  electionBid(2),
  ack(3),

  /// Chat text message – variable-length payload.
  text(4);

  final int wireValue;
  const BlePacketType(this.wireValue);

  static BlePacketType fromWire(int byte) {
    for (final t in values) {
      if (t.wireValue == byte) return t;
    }
    throw FormatException('Unknown BlePacketType byte: $byte');
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Shared Packet Header
// ─────────────────────────────────────────────────────────────────────────────

/// Common fields carried by every packet variant.
class BlePacketHeader {
  final BlePacketType type;

  /// Hop counter. Set to the appropriate k*Ttl constant on creation.
  /// Each relay node MUST decrement by 1 before forwarding; discard if == 0.
  final int ttl;

  /// Lower 16 bits of the source device's numeric ID (for routing decisions).
  final int sourceDeviceShortId;

  const BlePacketHeader({
    required this.type,
    required this.ttl,
    required this.sourceDeviceShortId,
  });

  /// Serialise header into the provided [ByteData] starting at [offset].
  void writeInto(ByteData bd, int offset) {
    bd.setUint8(offset, type.wireValue);
    bd.setUint8(offset + 1, ttl.clamp(0, 255));
    bd.setUint16(offset + 2, sourceDeviceShortId & 0xFFFF, Endian.little);
  }

  /// Parse a header from [bytes] starting at [offset].
  static BlePacketHeader readFrom(Uint8List bytes, int offset) {
    final bd = ByteData.sublistView(bytes, offset, offset + kHeaderSize);
    return BlePacketHeader(
      type: BlePacketType.fromWire(bd.getUint8(0)),
      ttl: bd.getUint8(1),
      sourceDeviceShortId: bd.getUint16(2, Endian.little),
    );
  }

  /// Returns a new header with TTL decremented by 1.
  BlePacketHeader withDecrementedTtl() => BlePacketHeader(
      type: type, ttl: ttl - 1, sourceDeviceShortId: sourceDeviceShortId);
}

// ─────────────────────────────────────────────────────────────────────────────
// DataPacket (inventory scan / CRDT delta)
// ─────────────────────────────────────────────────────────────────────────────

class BleDataPacket {
  final BlePacketHeader header;

  /// Random uint16 assigned at creation time; used by gossip engine for
  /// deduplication (seen-packet cache keyed on sourceDeviceShortId:packetShortId).
  final int packetShortId;

  /// Lower 16 bits of the full item UUID hash.
  final int itemShortId;

  /// Numeric status code (matches InventoryItemCrdt.status).
  final int statusId;

  /// Wall-clock timestamp in UNIX seconds (uint32 → valid until 2106).
  final int timestampSec;

  BleDataPacket({
    required this.header,
    required this.packetShortId,
    required this.itemShortId,
    required this.statusId,
    required this.timestampSec,
  });

  /// Convenience factory that sets up the header automatically.
  factory BleDataPacket.create({
    required int sourceDeviceShortId,
    required int itemShortId,
    required int statusId,
    required int timestampSec,
  }) {
    return BleDataPacket(
      header: BlePacketHeader(
        type: BlePacketType.data,
        ttl: kDataPacketTtl,
        sourceDeviceShortId: sourceDeviceShortId,
      ),
      packetShortId: _randomShortId(),
      itemShortId: itemShortId,
      statusId: statusId,
      timestampSec: timestampSec,
    );
  }

  /// Serialise to a 13-byte [Uint8List] (before encryption).
  Uint8List toBytes() {
    final bd = ByteData(kHeaderSize + kDataBodySize);
    header.writeInto(bd, 0);
    bd.setUint16(kHeaderSize, packetShortId, Endian.little);
    bd.setUint16(kHeaderSize + 2, itemShortId & 0xFFFF, Endian.little);
    bd.setUint8(kHeaderSize + 4, statusId & 0xFF);
    bd.setUint32(kHeaderSize + 5, timestampSec, Endian.little);
    return bd.buffer.asUint8List();
  }

  /// Parse from raw bytes (after decryption); [bytes.length] must be ≥ 13.
  static BleDataPacket fromBytes(Uint8List bytes) {
    assert(bytes.length >= kHeaderSize + kDataBodySize);
    final header = BlePacketHeader.readFrom(bytes, 0);
    final bd =
        ByteData.sublistView(bytes, kHeaderSize, kHeaderSize + kDataBodySize);
    return BleDataPacket(
      header: header,
      packetShortId: bd.getUint16(0, Endian.little),
      itemShortId: bd.getUint16(2, Endian.little),
      statusId: bd.getUint8(4),
      timestampSec: bd.getUint32(5, Endian.little),
    );
  }

  /// Returns a copy with TTL decremented (for relay forwarding).
  BleDataPacket relay() => BleDataPacket(
        header: header.withDecrementedTtl(),
        packetShortId: packetShortId,
        itemShortId: itemShortId,
        statusId: statusId,
        timestampSec: timestampSec,
      );

  bool get canRelay => header.ttl > 1;

  /// Unique deduplication key: source + packet nonce.
  String get dedupKey => '${header.sourceDeviceShortId}:$packetShortId';
}

// ─────────────────────────────────────────────────────────────────────────────
// HeartbeatPacket
// ─────────────────────────────────────────────────────────────────────────────

class BleHeartbeatPacket {
  final BlePacketHeader header;

  /// Monotonically increasing, wraps at 255. Used to detect missed heartbeats.
  final int sequenceNum;

  BleHeartbeatPacket({required this.header, required this.sequenceNum});

  factory BleHeartbeatPacket.create({
    required int sourceDeviceShortId,
    required int sequenceNum,
  }) {
    return BleHeartbeatPacket(
      header: BlePacketHeader(
        type: BlePacketType.heartbeat,
        ttl: kHeartbeatTtl,
        sourceDeviceShortId: sourceDeviceShortId,
      ),
      sequenceNum: sequenceNum & 0xFF,
    );
  }

  Uint8List toBytes() {
    final bd = ByteData(kHeaderSize + kHeartbeatBodySize);
    header.writeInto(bd, 0);
    bd.setUint8(kHeaderSize, sequenceNum);
    return bd.buffer.asUint8List();
  }

  static BleHeartbeatPacket fromBytes(Uint8List bytes) {
    assert(bytes.length >= kHeaderSize + kHeartbeatBodySize);
    final header = BlePacketHeader.readFrom(bytes, 0);
    return BleHeartbeatPacket(
      header: header,
      sequenceNum: bytes[kHeaderSize],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// ElectionBidPacket
// ─────────────────────────────────────────────────────────────────────────────

class BleElectionBidPacket {
  final BlePacketHeader header;

  /// The computed election score of the sending device.
  final int score;

  BleElectionBidPacket({required this.header, required this.score});

  factory BleElectionBidPacket.create({
    required int sourceDeviceShortId,
    required int score,
  }) {
    return BleElectionBidPacket(
      header: BlePacketHeader(
        type: BlePacketType.electionBid,
        ttl: kElectionBidTtl,
        sourceDeviceShortId: sourceDeviceShortId,
      ),
      score: score.clamp(0, 65535),
    );
  }

  Uint8List toBytes() {
    final bd = ByteData(kHeaderSize + kElectionBodySize);
    header.writeInto(bd, 0);
    bd.setUint16(kHeaderSize, score & 0xFFFF, Endian.little);
    return bd.buffer.asUint8List();
  }

  static BleElectionBidPacket fromBytes(Uint8List bytes) {
    assert(bytes.length >= kHeaderSize + kElectionBodySize);
    final header = BlePacketHeader.readFrom(bytes, 0);
    final score = ByteData.sublistView(bytes, kHeaderSize, kHeaderSize + 2)
        .getUint16(0, Endian.little);
    return BleElectionBidPacket(header: header, score: score);
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// AckPacket
// ─────────────────────────────────────────────────────────────────────────────

class BleAckPacket {
  final BlePacketHeader header;

  /// The packetShortId of the DataPacket being acknowledged.
  final int ackedPacketShortId;

  BleAckPacket({required this.header, required this.ackedPacketShortId});

  factory BleAckPacket.create({
    required int sourceDeviceShortId,
    required int ackedPacketShortId,
  }) {
    return BleAckPacket(
      header: BlePacketHeader(
        type: BlePacketType.ack,
        ttl: 1, // ACKs don't need to propagate further
        sourceDeviceShortId: sourceDeviceShortId,
      ),
      ackedPacketShortId: ackedPacketShortId,
    );
  }

  Uint8List toBytes() {
    final bd = ByteData(kHeaderSize + kAckBodySize);
    header.writeInto(bd, 0);
    bd.setUint16(kHeaderSize, ackedPacketShortId, Endian.little);
    return bd.buffer.asUint8List();
  }

  static BleAckPacket fromBytes(Uint8List bytes) {
    assert(bytes.length >= kHeaderSize + kAckBodySize);
    final header = BlePacketHeader.readFrom(bytes, 0);
    final acked = ByteData.sublistView(bytes, kHeaderSize, kHeaderSize + 2)
        .getUint16(0, Endian.little);
    return BleAckPacket(header: header, ackedPacketShortId: acked);
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Helpers
// ─────────────────────────────────────────────────────────────────────────────

final _rng = Random.secure();

/// Generates a random 16-bit unsigned ID for packet deduplication.
int _randomShortId() => _rng.nextInt(65536);

/// Compute a reproducible uint16 from any String (e.g. device UUID, item UUID).
/// This is a simple djb2-like hash truncated to 16 bits.
int shortIdFromString(String s) {
  int hash = 5381;
  for (final unit in s.codeUnits) {
    hash = ((hash << 5) + hash) ^ unit;
  }
  return hash & 0xFFFF;
}

/// Deserialise any encrypted-then-decrypted raw bytes into the correct packet
/// variant based on the first byte (PacketType).
Object parseBlePacket(Uint8List bytes) {
  if (bytes.isEmpty) throw FormatException('Empty BLE packet');
  final type = BlePacketType.fromWire(bytes[0]);
  switch (type) {
    case BlePacketType.data:
      return BleDataPacket.fromBytes(bytes);
    case BlePacketType.heartbeat:
      return BleHeartbeatPacket.fromBytes(bytes);
    case BlePacketType.electionBid:
      return BleElectionBidPacket.fromBytes(bytes);
    case BlePacketType.ack:
      return BleAckPacket.fromBytes(bytes);
    case BlePacketType.text:
      return BleChatTextPacket.fromBytes(bytes);
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// BleChatTextPacket  (variable length text message)
// ─────────────────────────────────────────────────────────────────────────────
//
// Layout (before AES-GCM encryption):
//   Offset  Size  Field
//   0       4 B   Header (type=4, TTL, sourceDeviceShortId)
//   4       4 B   MessageId (uint32 LE, random – for deduplication)
//   8       2 B   TextByteLength (uint16 LE)
//   10      N B   TextBytes (UTF-8)  ← max 180 bytes enforced on creation
//   Total:  10 + N bytes
//   After AES-GCM: 10 + N + 28 bytes  (max 218 B – fits in 247 B MTU)

const int kChatTextMaxBytes = 180;

class BleChatTextPacket {
  final BlePacketHeader header;

  /// Random uint32 for deduplication (source:messageId key).
  final int messageId;

  /// UTF-8 encoded text content.
  final String text;

  BleChatTextPacket({
    required this.header,
    required this.messageId,
    required this.text,
  });

  factory BleChatTextPacket.create({
    required int sourceDeviceShortId,
    required int messageId,
    required String text,
  }) {
    // Enforce byte limit at creation time.
    var encoded = const Utf8Encoder().convert(text);
    if (encoded.length > kChatTextMaxBytes) {
      encoded = encoded.sublist(0, kChatTextMaxBytes);
    }
    return BleChatTextPacket(
      header: BlePacketHeader(
        type: BlePacketType.text,
        ttl: kDataPacketTtl, // same hop count as data packets
        sourceDeviceShortId: sourceDeviceShortId,
      ),
      messageId: messageId,
      text: const Utf8Decoder().convert(encoded),
    );
  }

  Uint8List toBytes() {
    final textBytes = const Utf8Encoder().convert(text);
    final bd = ByteData(kHeaderSize + 6 + textBytes.length);
    header.writeInto(bd, 0);
    bd.setUint32(kHeaderSize, messageId, Endian.little);
    bd.setUint16(kHeaderSize + 4, textBytes.length, Endian.little);
    for (int i = 0; i < textBytes.length; i++) {
      bd.setUint8(kHeaderSize + 6 + i, textBytes[i]);
    }
    return bd.buffer.asUint8List();
  }

  static BleChatTextPacket fromBytes(Uint8List bytes) {
    assert(bytes.length >= kHeaderSize + 6);
    final header = BlePacketHeader.readFrom(bytes, 0);
    final bd = ByteData.sublistView(bytes, kHeaderSize);
    final msgId = bd.getUint32(0, Endian.little);
    final len = bd.getUint16(4, Endian.little);
    final textBytes = bytes.sublist(kHeaderSize + 6, kHeaderSize + 6 + len);
    return BleChatTextPacket(
      header: header,
      messageId: msgId,
      text: const Utf8Decoder().convert(textBytes),
    );
  }

  BleChatTextPacket relay() => BleChatTextPacket(
        header: header.withDecrementedTtl(),
        messageId: messageId,
        text: text,
      );

  bool get canRelay => header.ttl > 1;

  String get dedupKey => '${header.sourceDeviceShortId}:$messageId';
}
