// vector_clock.dart
// ──────────────────
// A pure-Dart, immutable Vector Clock (also known as Version Vector) that
// tracks the causal history of mutations across all devices in the mesh.
//
// ## Key Properties
// * **increment(deviceId)**  – Returns a new clock with deviceId's counter + 1.
//                              Call this when THIS device makes a local change.
// * **merge(other)**         – Returns a new clock where each counter is the
//                              pairwise maximum. Call this on RECEIVE before
//                              incrementing own counter.
// * **happensBefore(other)** – Partial order: A < B iff every counter in A is
//                              ≤ the corresponding counter in B, and at least
//                              one counter is strictly <.
// * **isConcurrent(other)**  – Neither A < B nor B < A → conflict / tie.
//
// ## Serialisation
// The clock is serialised as a JSON object `{ "device-id": counter, … }`.
// This JSON string is stored in the Drift database and sent in full CRDT sync
// sessions. For compact BLE micro-packets, only the wall-clock timestamp is
// transmitted; the full vector clock lives in the DB record.
import 'dart:convert';
import 'dart:math' show max;

import 'package:meta/meta.dart';

@immutable
class VectorClock {
  // Internal map: DeviceID → logical counter.
  final Map<String, int> _entries;

  // Private constructor – always create via factory.
  const VectorClock._(this._entries);

  // ─── Factories ────────────────────────────────────────────────────────────

  /// An empty clock representing the "beginning of time" for a device.
  static const VectorClock zero = VectorClock._({});

  /// Deserialise from a JSON map (e.g. loaded from SQLite column).
  factory VectorClock.fromJson(Map<String, dynamic> json) =>
      VectorClock._(Map<String, int>.from(json));

  /// Convenience: deserialise directly from a JSON string column.
  factory VectorClock.fromJsonString(String jsonString) =>
      VectorClock.fromJson(jsonDecode(jsonString) as Map<String, dynamic>);

  // ─── Mutation operations (return NEW instances – immutable!) ──────────────

  /// Returns a new clock with [deviceId]'s counter incremented.
  /// Must be called on EVERY local write before persisting.
  VectorClock increment(String deviceId) {
    final next = Map<String, int>.from(_entries);
    next[deviceId] = (_entries[deviceId] ?? 0) + 1;
    return VectorClock._(next);
  }

  /// Returns a new clock that is the component-wise maximum of [this] and
  /// [other]. Call this when merging an incoming remote event.
  VectorClock merge(VectorClock other) {
    final result = Map<String, int>.from(_entries);
    other._entries.forEach((deviceId, counter) {
      result[deviceId] = max(result[deviceId] ?? 0, counter);
    });
    return VectorClock._(result);
  }

  // ─── Causal ordering ─────────────────────────────────────────────────────

  /// Returns `true` if [this] causally happened BEFORE [other].
  /// Formally: ∀k: clock[k] ≤ other[k]  AND  ∃k: clock[k] < other[k].
  bool happensBefore(VectorClock other) {
    bool hasStrictlySmaller = false;

    // Check all keys present in THIS clock.
    for (final MapEntry(:key, :value) in _entries.entries) {
      final otherValue = other._entries[key] ?? 0;
      if (value > otherValue) {
        // Found a counter where THIS is larger → cannot happen-before.
        return false;
      }
      if (value < otherValue) {
        hasStrictlySmaller = true;
      }
    }

    // Check keys that exist ONLY in OTHER (= THIS clock has implicit 0).
    for (final MapEntry(:key, :value) in other._entries.entries) {
      if (!_entries.containsKey(key) && value > 0) {
        hasStrictlySmaller = true;
      }
    }

    return hasStrictlySmaller;
  }

  /// Returns `true` if events are CONCURRENT (neither happened before the other).
  /// This signals a conflict that the CRDT merge rule must resolve.
  bool isConcurrentWith(VectorClock other) =>
      !happensBefore(other) && !other.happensBefore(this) && this != other;

  // ─── Serialisation ────────────────────────────────────────────────────────

  Map<String, dynamic> toJson() => Map<String, dynamic>.from(_entries);

  /// Compact JSON string suitable for storing in a SQLite TEXT column.
  String toJsonString() => jsonEncode(toJson());

  // ─── Equality / hash ──────────────────────────────────────────────────────

  @override
  bool operator ==(Object other) {
    if (other is! VectorClock) return false;
    if (_entries.length != other._entries.length) return false;
    for (final k in _entries.keys) {
      if (_entries[k] != other._entries[k]) return false;
    }
    return true;
  }

  @override
  int get hashCode =>
      _entries.entries.fold(0, (h, e) => h ^ e.key.hashCode ^ e.value.hashCode);

  @override
  String toString() => 'VectorClock($_entries)';

  /// Number of devices that have contributed at least one event.
  int get size => _entries.length;

  /// Read-only view of all entries (useful for debugging / diagnostics).
  Map<String, int> get entries => Map.unmodifiable(_entries);
}
