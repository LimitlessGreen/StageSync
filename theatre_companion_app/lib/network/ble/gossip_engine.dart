/// gossip_engine.dart
/// ────────────────────
/// Implements the **Gossip Protocol** for multi-hop packet propagation in the
/// BLE Mesh. Instead of flooding the entire network (which wastes bandwidth and
/// battery), each node forwards a packet to a random subset of **3** neighbours.
///
/// ## Loop Prevention
/// Every received packet is hashed and stored in a fixed-size LRU "seen" cache
/// with a 60-second TTL. If the same packet arrives again (via a different relay
/// path), it is silently discarded before forwarding.
///
/// ## TTL Enforcement
/// Each packet carries a TTL byte. The engine decrements TTL before relaying;
/// if TTL reaches 0 the packet is dropped and is NOT forwarded further.
///
/// ## Store-Carry-Forward Integration
/// If fewer than [kGossipFanout] peers are in range, the packet is still
/// forwarded to however many are available. If 0 peers are available, the
/// [PacketQueueDao] is called to persist the packet for later delivery.
library gossip_engine;

import 'dart:async';
import 'dart:collection';
import 'dart:typed_data';

import '../crypto/aes_gcm_service.dart';
import '../db/dao/packet_queue_dao.dart';
import '../models/ble_packet.dart';
import '../platform/abstract_ble_service.dart';
import '../routing/peer_registry.dart';

/// Number of random peers to forward each packet to.
const int kGossipFanout = 3;

/// Maximum number of packet hashes in the seen-cache.
const int kSeenCacheMaxSize = 2000;

/// Milliseconds before a seen-cache entry expires.
const int kSeenCacheTtlMs = 60 * 1000;

// ─────────────────────────────────────────────────────────────────────────────

/// Entry in the seen-packet cache.
class _SeenEntry {
  final int insertedAtMs;
  _SeenEntry(this.insertedAtMs);
  bool get isExpired =>
      DateTime.now().millisecondsSinceEpoch - insertedAtMs > kSeenCacheTtlMs;
}

// ─────────────────────────────────────────────────────────────────────────────

class GossipEngine {
  final AbstractBleService _ble;
  final PeerRegistry _peers;
  final AesGcmService _crypto;
  final PacketQueueDao _queue;

  /// Seen-packet cache: dedupKey → _SeenEntry.
  /// Using LinkedHashMap to maintain insertion order for bounded eviction.
  final LinkedHashMap<String, _SeenEntry> _seenCache = LinkedHashMap();

  GossipEngine({
    required AbstractBleService ble,
    required PeerRegistry peers,
    required AesGcmService crypto,
    required PacketQueueDao queue,
    required int localShortId, // Reserviert für zukünftige Source-Tagging-Logik
  })  : _ble = ble,
        _peers = peers,
        _crypto = crypto,
        _queue = queue;

  // ─── Public API ───────────────────────────────────────────────────────────

  /// Entry point for the local node to **originate** a data packet (not relay).
  Future<void> originateDataPacket(BleDataPacket packet) async {
    _markSeen(packet.dedupKey);
    await _forwardDataPacket(packet);
  }

  /// Entry point for originating a chat text packet.
  Future<void> originateChatPacket(BleChatTextPacket packet) async {
    _markSeen(packet.dedupKey);
    await _forwardChatPacket(packet);
  }

  /// Called when a [BleChatTextPacket] arrives from the BLE layer.
  Future<void> onChatPacketReceived(
    BleChatTextPacket packet,
    String senderDeviceId,
  ) async {
    if (_hasSeenBefore(packet.dedupKey)) return;
    _markSeen(packet.dedupKey);
    if (!packet.canRelay) return;
    await _forwardChatPacket(packet.relay(), excludeId: senderDeviceId);
  }

  /// Called when a [BleDataPacket] arrives from the BLE layer (via a peer).
  ///
  /// Deduplicates, decrements TTL, and gossip-forwards to [kGossipFanout] random
  /// peers (excluding the sender). Safe to call concurrently.
  Future<void> onDataPacketReceived(
    BleDataPacket packet,
    String senderDeviceId,
  ) async {
    // 1. Deduplication check.
    if (_hasSeenBefore(packet.dedupKey)) return;
    _markSeen(packet.dedupKey);

    // 2. TTL check – only relay if TTL > 1 (we decrement on relay = new TTL ≥ 1).
    if (!packet.canRelay) return;

    // 3. Forward to random subset of peers (excluding original sender).
    await _forwardDataPacket(packet.relay(), excludeId: senderDeviceId);
  }

  /// Broadcasts a heartbeat or election-bid packet to ALL alive peers.
  /// These control packets do NOT go through the Store-Carry-Forward queue.
  Future<void> broadcastControlPacket(Uint8List plainBytes) async {
    final alivePeers = _peers.alivePeers;
    if (alivePeers.isEmpty) return;

    await Future.wait([
      for (final peer in alivePeers)
        _sendToPeer(peer, plainBytes)
            .catchError((_) {/* Ignore individual send failures */}),
    ]);
  }

  // ─── Private ─────────────────────────────────────────────────────────────

  Future<void> _forwardDataPacket(
    BleDataPacket packet, {
    String? excludeId,
  }) async {
    final plainBytes = packet.toBytes();
    final targets =
        _peers.randomSubset(count: kGossipFanout, excludeId: excludeId);

    if (targets.isEmpty) {
      final encrypted = await _crypto.encrypt(plainBytes);
      await _queue.enqueue(
        encryptedPayload: encrypted,
        targetDeviceId: null,
        packetTypeByte: BlePacketType.data.wireValue,
        nowMs: DateTime.now().millisecondsSinceEpoch,
      );
      // Auch Subskribenten (z.B. Windows-Centrals) informieren.
      await _ble.broadcastToSubscribers(encrypted).catchError((_) {});
      return;
    }

    final encrypted = await _crypto.encrypt(plainBytes);

    // Subscribed Centrals (Windows) als ersten Schritt benachrichtigen.
    await _ble.broadcastToSubscribers(encrypted).catchError((_) {});

    await Future.wait([
      for (final peer in targets)
        _sendRawToPeer(peer, encrypted).catchError((_) async {
          await _queue.enqueue(
            encryptedPayload: encrypted,
            targetDeviceId: peer.deviceId,
            packetTypeByte: BlePacketType.data.wireValue,
            nowMs: DateTime.now().millisecondsSinceEpoch,
          );
        }),
    ]);
  }

  Future<void> _forwardChatPacket(
    BleChatTextPacket packet, {
    String? excludeId,
  }) async {
    final plainBytes = packet.toBytes();
    final targets =
        _peers.randomSubset(count: kGossipFanout, excludeId: excludeId);

    if (targets.isEmpty) {
      final encrypted = await _crypto.encrypt(plainBytes);
      await _queue.enqueue(
        encryptedPayload: encrypted,
        targetDeviceId: null,
        packetTypeByte: BlePacketType.text.wireValue,
        nowMs: DateTime.now().millisecondsSinceEpoch,
      );
      await _ble.broadcastToSubscribers(encrypted).catchError((_) {});
      return;
    }

    final encrypted = await _crypto.encrypt(plainBytes);
    await _ble.broadcastToSubscribers(encrypted).catchError((_) {});

    await Future.wait([
      for (final peer in targets)
        _sendRawToPeer(peer, encrypted).catchError((_) async {
          await _queue.enqueue(
            encryptedPayload: encrypted,
            targetDeviceId: peer.deviceId,
            packetTypeByte: BlePacketType.text.wireValue,
            nowMs: DateTime.now().millisecondsSinceEpoch,
          );
        }),
    ]);
  }

  /// Sendet bereits verschlüsselte Bytes direkt an einen Peer.
  /// Vermeidet doppelte Verschlüsselung bei Gossip-Weiterleitung.
  Future<void> _sendRawToPeer(PeerInfo peer, Uint8List encryptedBytes) =>
      _ble.sendRawEncryptedPacket(peer.deviceId, encryptedBytes);

  Future<void> _sendToPeer(PeerInfo peer, Uint8List plainBytes) =>
      _ble.sendPacket(peer.deviceId, plainBytes);

  // ─── Seen-packet cache ────────────────────────────────────────────────────

  bool _hasSeenBefore(String dedupKey) {
    final entry = _seenCache[dedupKey];
    if (entry == null) return false;
    if (entry.isExpired) {
      _seenCache.remove(dedupKey);
      return false;
    }
    return true;
  }

  void _markSeen(String dedupKey) {
    // Bounded eviction: drop the oldest 10 % when at capacity.
    if (_seenCache.length >= kSeenCacheMaxSize) {
      final evictCount = (kSeenCacheMaxSize * 0.1).ceil();
      final keysToEvict = _seenCache.keys.take(evictCount).toList();
      for (final k in keysToEvict) {
        _seenCache.remove(k);
      }
    }
    _seenCache[dedupKey] = _SeenEntry(DateTime.now().millisecondsSinceEpoch);
  }

  /// Drains the Store-Carry-Forward queue for a newly discovered peer.
  ///
  /// Called by [NetworkRepositoryWeaver] whenever a new peer comes into range.
  ///
  /// **Wichtig:** Die Queue persistiert AES-GCM-verschlüsselte Bytes. Deshalb
  /// MUSS hier [AbstractBleService.sendRawEncryptedPacket] verwendet werden,
  /// damit die Pakete NICHT ein zweites Mal verschlüsselt werden (Bug-Fix:
  /// Doppel-Verschlüsselung würde zu nicht dekodierbare Ciphertext führen).
  Future<void> drainQueueForPeer(String peerId) async {
    final pending = await _queue.dequeueForDelivery(peerId);
    for (final row in pending) {
      try {
        // Die encryptedPayload-Bytes sind bereits AES-GCM-verschlüsselt;
        // sendRawEncryptedPacket schreibt sie direkt per GATT ohne Re-Encryption.
        await _ble.sendRawEncryptedPacket(
          peerId,
          Uint8List.fromList(row.encryptedPayload),
        );
        await _queue.markDelivered(row.id);
      } catch (_) {
        await _queue.incrementRetryCount(row.id);
      }
    }
  }
}
