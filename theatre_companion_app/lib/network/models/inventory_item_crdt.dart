// inventory_item_crdt.dart
// ─────────────────────────
// Implements a **Last-Write-Wins Element Set (LWW-Element-Set)** CRDT for
// inventory item state. Each mutable field is wrapped in a [LwwField] that
// carries its own [VectorClock]. Merging two [InventoryItemCrdt] instances
// is fully commutative, associative, and idempotent – split-brain safe.
//
// ## Conflict Resolution
// When two field values have concurrent vector clocks (neither happened before
// the other), the device with the numerically higher [short ID] wins as a
// deterministic, arbitrary tiebreaker. This prevents oscillation.
//
// ## Delta Computation
// [delta(baseline)] produces a minimal [InventoryItemCrdt] that contains ONLY
// the fields that changed since [baseline]. Used to keep BLE payloads lean
// during periodic full-sync sessions.
import 'dart:convert';

import 'package:meta/meta.dart';

import 'vector_clock.dart';

// ─────────────────────────────────────────────────────────────────────────────
// LwwField – a single Last-Write-Wins field
// ─────────────────────────────────────────────────────────────────────────────

/// Wraps a single value [T] together with the [VectorClock] and a wall-clock
/// timestamp that determined when it was last written.
@immutable
class LwwField<T> {
  /// The current logical value.
  final T value;

  /// The vector clock at the time this value was written.
  final VectorClock clock;

  /// Wall-clock milliseconds since epoch – used as a last-resort tiebreaker
  /// when the vector clocks are concurrent.
  final int wallClockMs;

  /// Short device ID of the device that wrote this value (tiebreaker #2).
  final int ownerShortId;

  const LwwField({
    required this.value,
    required this.clock,
    required this.wallClockMs,
    required this.ownerShortId,
  });

  /// Returns whichever field wins according to LWW rules:
  /// 1. Causal order (vector clock) – winner is clear.
  /// 2. Concurrent clocks → pick the higher wall-clock timestamp.
  /// 3. Identical timestamps → pick the higher ownerShortId (deterministic).
  LwwField<T> merge(LwwField<T> remote) {
    // Case 1a: local happened AFTER remote → local wins.
    if (remote.clock.happensBefore(clock)) return this;

    // Case 1b: remote happened AFTER local → remote wins.
    if (clock.happensBefore(remote.clock)) return remote;

    // Case 2: Concurrent – use wall-clock timestamp as tiebreaker.
    if (wallClockMs != remote.wallClockMs) {
      return wallClockMs > remote.wallClockMs ? this : remote;
    }

    // Case 3: Identical timestamps – use ownerShortId (deterministic).
    return ownerShortId >= remote.ownerShortId ? this : remote;
  }

  /// Serialise to a JSON-compatible map for SQLite storage.
  Map<String, dynamic> toJson() => {
        'value': value,
        'clock': clock.toJson(),
        'wallClockMs': wallClockMs,
        'ownerShortId': ownerShortId,
      };

  /// Deserialise from a JSON-compatible map.
  static LwwField<T> fromJson<T>(
      Map<String, dynamic> json, T Function(dynamic) decode) {
    return LwwField<T>(
      value: decode(json['value']),
      clock: VectorClock.fromJson(json['clock'] as Map<String, dynamic>),
      wallClockMs: json['wallClockMs'] as int,
      ownerShortId: json['ownerShortId'] as int,
    );
  }

  @override
  String toString() => 'LwwField(value=$value, clock=$clock, ts=$wallClockMs)';
}

// ─────────────────────────────────────────────────────────────────────────────
// InventoryItemCrdt
// ─────────────────────────────────────────────────────────────────────────────

/// The full CRDT representation of a single inventory item.
///
/// Mutable fields (those that need conflict resolution) are [LwwField]s.
/// Immutable fields (e.g. [itemId]) are plain values agreed upon at creation.
class InventoryItemCrdt {
  /// Globally unique item identifier (QR-code value, barcode, or UUID string).
  final String itemId;

  /// The device-short-ID of the device that first created this item record.
  final int creatorShortId;

  /// LWW field: numeric status code.
  ///   0 = InPlace, 1 = CheckedOut, 2 = Missing, 3 = Damaged
  LwwField<int> status;

  /// LWW field: optional physical location tag (can be null).
  LwwField<String?> location;

  InventoryItemCrdt({
    required this.itemId,
    required this.creatorShortId,
    required this.status,
    required this.location,
  });

  // ─── Factory: create a new item with an initial value ───────────────────

  factory InventoryItemCrdt.create({
    required String itemId,
    required String deviceId,
    required int deviceShortId,
    required int statusId,
    String? locationTag,
    required int wallClockMs,
  }) {
    final clock = VectorClock.zero.increment(deviceId);
    return InventoryItemCrdt(
      itemId: itemId,
      creatorShortId: deviceShortId,
      status: LwwField(
        value: statusId,
        clock: clock,
        wallClockMs: wallClockMs,
        ownerShortId: deviceShortId,
      ),
      location: LwwField(
        value: locationTag,
        clock: clock,
        wallClockMs: wallClockMs,
        ownerShortId: deviceShortId,
      ),
    );
  }

  // ─── Local mutation (returns updated copy) ───────────────────────────────

  /// Applies a local status update, advancing own vector clock.
  /// Returns a NEW [InventoryItemCrdt] with the updated field.
  InventoryItemCrdt withStatusUpdate({
    required int newStatusId,
    required String deviceId,
    required int deviceShortId,
    required int wallClockMs,
  }) {
    final newClock = status.clock.merge(location.clock).increment(deviceId);
    return InventoryItemCrdt(
      itemId: itemId,
      creatorShortId: creatorShortId,
      status: LwwField(
        value: newStatusId,
        clock: newClock,
        wallClockMs: wallClockMs,
        ownerShortId: deviceShortId,
      ),
      location: location,
    );
  }

  /// Applies a local location update, advancing own vector clock.
  InventoryItemCrdt withLocationUpdate({
    required String? newLocation,
    required String deviceId,
    required int deviceShortId,
    required int wallClockMs,
  }) {
    final newClock = status.clock.merge(location.clock).increment(deviceId);
    return InventoryItemCrdt(
      itemId: itemId,
      creatorShortId: creatorShortId,
      status: status,
      location: LwwField(
        value: newLocation,
        clock: newClock,
        wallClockMs: wallClockMs,
        ownerShortId: deviceShortId,
      ),
    );
  }

  // ─── CRDT merge ──────────────────────────────────────────────────────────

  /// Merges a [remote] CRDT into this one using LWW rules per field.
  /// This operation is:
  ///   * **Commutative**: merge(A, B) == merge(B, A)
  ///   * **Associative**: merge(A, merge(B, C)) == merge(merge(A, B), C)
  ///   * **Idempotent**: merge(A, A) == A
  ///
  /// Returns a NEW [InventoryItemCrdt] with the merged state.
  InventoryItemCrdt merge(InventoryItemCrdt remote) {
    assert(itemId == remote.itemId,
        'Cannot merge CRDTs for different items: $itemId vs ${remote.itemId}');

    return InventoryItemCrdt(
      itemId: itemId,
      creatorShortId: creatorShortId,
      status: status.merge(remote.status),
      location: location.merge(remote.location),
    );
  }

  // ─── Delta computation ───────────────────────────────────────────────────

  /// Returns a delta CRDT containing only the fields that have changed compared
  /// to [baseline]. If nothing changed, the returned delta will be identical
  /// to [baseline] and can be detected by comparing vector clocks.
  InventoryItemCrdt delta(InventoryItemCrdt baseline) {
    // A field is in the delta if its clock does NOT happen-before baseline's
    // clock for the same field (i.e. it carries new information).
    final includeStatus = !status.clock.happensBefore(baseline.status.clock) ||
        !baseline.status.clock.happensBefore(status.clock);
    final includeLocation =
        !location.clock.happensBefore(baseline.location.clock) ||
            !baseline.location.clock.happensBefore(location.clock);

    return InventoryItemCrdt(
      itemId: itemId,
      creatorShortId: creatorShortId,
      status: includeStatus ? status : baseline.status,
      location: includeLocation ? location : baseline.location,
    );
  }

  // ─── Serialisation ───────────────────────────────────────────────────────

  Map<String, dynamic> toJson() => {
        'itemId': itemId,
        'creatorShortId': creatorShortId,
        'status': status.toJson(),
        'location': location.toJson(),
      };

  String toJsonString() => jsonEncode(toJson());

  factory InventoryItemCrdt.fromJson(Map<String, dynamic> json) {
    return InventoryItemCrdt(
      itemId: json['itemId'] as String,
      creatorShortId: json['creatorShortId'] as int,
      status: LwwField.fromJson<int>(
        json['status'] as Map<String, dynamic>,
        (v) => v as int,
      ),
      location: LwwField.fromJson<String?>(
        json['location'] as Map<String, dynamic>,
        (v) => v as String?,
      ),
    );
  }

  factory InventoryItemCrdt.fromJsonString(String jsonString) =>
      InventoryItemCrdt.fromJson(
          jsonDecode(jsonString) as Map<String, dynamic>);

  // ─── Equality ─────────────────────────────────────────────────────────────

  /// Two CRDTs are considered to have the same state if both their LWW field
  /// clocks AND their values match (clock equality alone is insufficient when
  /// the same timestamp was produced by different devices with the same wall
  /// clock but different values).
  bool hasSameStateAs(InventoryItemCrdt other) =>
      itemId == other.itemId &&
      status.value == other.status.value &&
      status.clock == other.status.clock &&
      location.value == other.location.value &&
      location.clock == other.location.clock;

  @override
  String toString() =>
      'InventoryItemCrdt(id=$itemId, status=${status.value}, location=${location.value})';
}
