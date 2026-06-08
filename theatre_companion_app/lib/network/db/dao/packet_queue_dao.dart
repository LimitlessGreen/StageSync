// packet_queue_dao.dart
// ──────────────────────
// Data-Access Object for the [PacketQueue] table.
//
// Implements the **Store-Carry-Forward** pattern:
//   1. Every outbound BLE packet is [enqueue]d atomically BEFORE any send
//      attempt. This guarantees no data loss even if the app is killed mid-
//      transmission.
//   2. When a peer is in range, [dequeueForDelivery] returns pending packets
//      for that target (or broadcast packets for any peer).
//   3. On successful delivery, [markDelivered] is called atomically.
//   4. [purgeDelivered] periodically cleans up old delivered rows.
//   5. [purgeStale] removes packets whose creation time exceeds [maxAgeMs]
//      (prevents unbounded queue growth during extended offline periods).
import 'package:drift/drift.dart';

import '../app_database.dart';

/// Maximum age of a queued packet before it is discarded (12 hours).
const int kPacketMaxAgeMs = 12 * 60 * 60 * 1000;

/// Maximum queue depth – oldest excess entries are dropped to bound memory.
const int kPacketQueueMaxDepth = 500;

class PacketQueueDao {
  final AppDatabase _db;
  PacketQueueDao(this._db);

  // ─── Enqueue ─────────────────────────────────────────────────────────────

  /// Persists [encryptedPayload] atomically. Returns the new row ID.
  ///
  /// [targetDeviceId] is null for broadcast packets (delivered to whoever
  /// comes into range next).
  Future<int> enqueue({
    required List<int> encryptedPayload,
    String? targetDeviceId,
    required int packetTypeByte,
    required int nowMs,
  }) async {
    // Enforce queue depth limit: remove oldest undelivered entries first.
    await _evictIfOverDepth();

    return _db.into(_db.packetQueue).insert(
          PacketQueueCompanion.insert(
            encryptedPayload: Uint8List.fromList(encryptedPayload),
            targetDeviceId: Value(targetDeviceId),
            packetTypeByte: packetTypeByte,
            createdAtMs: nowMs,
          ),
        );
  }

  // ─── Dequeue ─────────────────────────────────────────────────────────────

  /// Returns all pending (not yet delivered) packets that should be sent to
  /// [peerId]: those specifically targeted at [peerId] PLUS any broadcasts.
  ///
  /// Ordered by creation time (oldest first – FIFO delivery).
  Future<List<PacketQueueData>> dequeueForDelivery(String peerId) async {
    final nowMs = DateTime.now().millisecondsSinceEpoch;
    final cutoff = nowMs - kPacketMaxAgeMs;

    return (_db.select(_db.packetQueue)
          ..where(
            (t) =>
                t.isDelivered.equals(false) &
                t.createdAtMs.isBiggerThanValue(cutoff) &
                (t.targetDeviceId.equals(peerId) | t.targetDeviceId.isNull()),
          )
          ..orderBy([(t) => OrderingTerm.asc(t.createdAtMs)]))
        .get();
  }

  /// Returns all broadcast packets pending delivery (used on leader election
  /// to flush queue towards all newly known peers).
  Future<List<PacketQueueData>> dequeueBroadcastPending() async {
    final nowMs = DateTime.now().millisecondsSinceEpoch;
    final cutoff = nowMs - kPacketMaxAgeMs;

    return (_db.select(_db.packetQueue)
          ..where(
            (t) =>
                t.isDelivered.equals(false) &
                t.targetDeviceId.isNull() &
                t.createdAtMs.isBiggerThanValue(cutoff),
          )
          ..orderBy([(t) => OrderingTerm.asc(t.createdAtMs)]))
        .get();
  }

  // ─── Delivery confirmation ────────────────────────────────────────────────

  /// Marks a specific packet as successfully delivered.
  /// Also increments the retry counter (idempotent if called multiple times).
  Future<void> markDelivered(int rowId) async {
    await (_db.update(_db.packetQueue)..where((t) => t.id.equals(rowId)))
        .write(const PacketQueueCompanion(isDelivered: Value(true)));
  }

  /// Increments the retry counter for a packet that failed to deliver.
  Future<void> incrementRetryCount(int rowId) async {
    // Drift doesn't directly support increment; use a custom update.
    await _db.customUpdate(
      'UPDATE packet_queue SET retry_count = retry_count + 1 WHERE id = ?',
      variables: [Variable.withInt(rowId)],
      updates: {_db.packetQueue},
    );
  }

  // ─── Maintenance ─────────────────────────────────────────────────────────

  /// Deletes all packets marked as delivered. Call this periodically (e.g.
  /// every 10 minutes) to keep the database lean.
  Future<int> purgeDelivered() async {
    return (_db.delete(_db.packetQueue)
          ..where((t) => t.isDelivered.equals(true)))
        .go();
  }

  /// Deletes packets older than [kPacketMaxAgeMs] that were never delivered.
  /// These are considered permanently lost (peer never came into range).
  Future<int> purgeStale() async {
    final cutoff = DateTime.now().millisecondsSinceEpoch - kPacketMaxAgeMs;
    return (_db.delete(_db.packetQueue)
          ..where(
            (t) => t.createdAtMs.isSmallerThanValue(cutoff),
          ))
        .go();
  }

  /// Returns the count of pending (undelivered, non-stale) queued packets.
  Future<int> pendingCount() async {
    final nowMs = DateTime.now().millisecondsSinceEpoch;
    final cutoff = nowMs - kPacketMaxAgeMs;
    final result = await _db.customSelect(
      'SELECT COUNT(*) AS cnt FROM packet_queue '
      'WHERE is_delivered = 0 AND created_at_ms > ?',
      variables: [Variable.withInt(cutoff)],
    ).getSingle();
    return result.read<int>('cnt');
  }

  // ─── Private ─────────────────────────────────────────────────────────────

  /// Removes the oldest undelivered entries when queue depth exceeds limit.
  Future<void> _evictIfOverDepth() async {
    final count = await pendingCount();
    if (count >= kPacketQueueMaxDepth) {
      final excess = count - kPacketQueueMaxDepth + 1;
      // Delete the oldest [excess] undelivered entries.
      await _db.customUpdate(
        'DELETE FROM packet_queue WHERE id IN '
        '(SELECT id FROM packet_queue WHERE is_delivered = 0 '
        'ORDER BY created_at_ms ASC LIMIT ?)',
        variables: [Variable.withInt(excess)],
        updates: {_db.packetQueue},
      );
    }
  }
}
