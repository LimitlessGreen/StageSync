/// inventory_item_crdt_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:theatre_companion_app/network/models/inventory_item_crdt.dart';
import 'package:theatre_companion_app/network/models/vector_clock.dart';
InventoryItemCrdt _make({
  String id = 'item-001', String dev = 'dev-A', int shortId = 1,
  int status = 0, String? loc, int ms = 1000,
}) => InventoryItemCrdt.create(itemId: id, deviceId: dev, deviceShortId: shortId,
    statusId: status, locationTag: loc, wallClockMs: ms);
void main() {
  group('LwwField.merge kausal', () {
    test('local > remote => local gewinnt', () {
      final cA = VectorClock.zero.increment('A');
      final cB = cA.increment('A');
      final local = LwwField<int>(value: 99, clock: cB, wallClockMs: 2000, ownerShortId: 1);
      final remote = LwwField<int>(value: 0, clock: cA, wallClockMs: 1000, ownerShortId: 2);
      expect(local.merge(remote).value, 99);
    });
    test('remote > local => remote gewinnt', () {
      final cA = VectorClock.zero.increment('A');
      final cB = cA.increment('A');
      final local = LwwField<int>(value: 0, clock: cA, wallClockMs: 1000, ownerShortId: 1);
      final remote = LwwField<int>(value: 99, clock: cB, wallClockMs: 999, ownerShortId: 2);
      expect(local.merge(remote).value, 99);
    });
  });
  group('LwwField.merge concurrent Tiebreaker', () {
    test('höherer wallClock gewinnt', () {
      final f1 = LwwField<int>(value: 3, clock: VectorClock.zero.increment('A'), wallClockMs: 500, ownerShortId: 1);
      final f2 = LwwField<int>(value: 7, clock: VectorClock.zero.increment('B'), wallClockMs: 800, ownerShortId: 2);
      expect(f1.merge(f2).value, 7);
      expect(f2.merge(f1).value, 7);
    });
    test('gleicher wallClock: höherer ownerShortId gewinnt', () {
      final f1 = LwwField<int>(value: 10, clock: VectorClock.zero.increment('A'), wallClockMs: 1000, ownerShortId: 5);
      final f2 = LwwField<int>(value: 20, clock: VectorClock.zero.increment('B'), wallClockMs: 1000, ownerShortId: 3);
      expect(f1.merge(f2).value, 10);
      expect(f2.merge(f1).value, 10);
    });
    test('idempotent: merge(f,f) == f', () {
      final f = LwwField<int>(value: 42, clock: VectorClock.zero.increment('X'), wallClockMs: 1000, ownerShortId: 1);
      expect(f.merge(f).value, 42);
    });
  });
  group('LwwField Serialisierung', () {
    test('toJson / fromJson Roundtrip', () {
      final f = LwwField<int>(value: 7, clock: VectorClock.zero.increment('d'), wallClockMs: 5000, ownerShortId: 42);
      final r = LwwField.fromJson<int>(f.toJson(), (v) => v as int);
      expect(r.value, f.value);
      expect(r.clock, f.clock);
      expect(r.wallClockMs, f.wallClockMs);
      expect(r.ownerShortId, f.ownerShortId);
    });
  });
  group('InventoryItemCrdt.create', () {
    test('korrekte Initialwerte', () {
      final item = _make(status: 1, loc: 'Buehne Links');
      expect(item.itemId, 'item-001');
      expect(item.status.value, 1);
      expect(item.location.value, 'Buehne Links');
      expect(item.creatorShortId, 1);
    });
    test('null location erlaubt', () => expect(_make(loc: null).location.value, isNull));
  });
  group('InventoryItemCrdt.withStatusUpdate', () {
    test('aktualisiert status, behaelt location', () {
      final orig = _make(status: 0, loc: 'Raum A', ms: 1000);
      final upd = orig.withStatusUpdate(newStatusId: 2, deviceId: 'dev-A', deviceShortId: 1, wallClockMs: 2000);
      expect(upd.status.value, 2);
      expect(upd.location.value, 'Raum A');
    });
    test('neuer Clock kommt kausaal nach altem', () {
      final o = _make(ms: 1000);
      final u = o.withStatusUpdate(newStatusId: 1, deviceId: 'dev-A', deviceShortId: 1, wallClockMs: 2000);
      expect(o.status.clock.happensBefore(u.status.clock), isTrue);
    });
  });
  group('InventoryItemCrdt.merge', () {
    test('kommutativ', () {
      final a = _make(dev: 'dev-A', shortId: 1, status: 0, ms: 1000);
      final b = _make(dev: 'dev-B', shortId: 2, status: 1, ms: 2000);
      expect(a.merge(b).status.value, b.merge(a).status.value);
    });
    test('idempotent', () => expect(_make(status: 3).merge(_make(status: 3)).status.value, 3));
    test('neueres gewinnt', () {
      final old = _make(status: 0, ms: 1000);
      final fresh = old.withStatusUpdate(newStatusId: 3, deviceId: 'dev-A', deviceShortId: 1, wallClockMs: 5000);
      expect(old.merge(fresh).status.value, 3);
      expect(fresh.merge(old).status.value, 3);
    });
  });
  group('InventoryItemCrdt.delta', () {
    test('delta unveraendert == original', () {
      final a = _make(status: 1, loc: 'X');
      expect(a.delta(a).status.value, a.status.value);
    });
    test('delta enthaelt aktualisierte Status', () {
      final base = _make(status: 0, ms: 1000);
      final upd = base.withStatusUpdate(newStatusId: 2, deviceId: 'dev-A', deviceShortId: 1, wallClockMs: 2000);
      expect(upd.delta(base).status.value, 2);
    });
  });
  group('InventoryItemCrdt Serialisierung', () {
    test('JSON Roundtrip', () {
      final orig = _make(status: 2, loc: 'Hinter der Buehne');
      final r = InventoryItemCrdt.fromJsonString(orig.toJsonString());
      expect(r.itemId, orig.itemId);
      expect(r.status.value, orig.status.value);
      expect(r.location.value, orig.location.value);
      expect(r.status.clock, orig.status.clock);
    });
    test('null location Roundtrip', () {
      expect(InventoryItemCrdt.fromJsonString(_make(loc: null).toJsonString()).location.value, isNull);
    });
  });
  group('InventoryItemCrdt.hasSameStateAs', () {
    test('gleiche Items true', () => expect(_make().hasSameStateAs(_make()), isTrue));
    test('verschiedene Status false', () => expect(_make(status: 0).hasSameStateAs(_make(status: 1)), isFalse));
  });
}
