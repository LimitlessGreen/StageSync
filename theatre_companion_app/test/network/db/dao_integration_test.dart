/// dao_integration_test.dart
/// ────────────────────────────
/// Integrations-Tests fuer InventoryDao und PacketQueueDao mit einer
/// In-Memory-Drift-Datenbank (NativeDatabase.memory()).
///
/// Diese Tests beweisen:
///   1. InventoryDao.upsertCrdt() – erstmalige Persistenz
///   2. InventoryDao.mergeRemote() – idempotenter CRDT-Merge
///   3. InventoryDao.getByShortId() – 16-Bit-Hash-Lookup
///   4. PacketQueueDao.enqueue/dequeueForDelivery – FIFO-Reihenfolge
///   5. PacketQueueDao.markDelivered() – Zustellbestaetigung
///   6. PacketQueueDao.purgeStale() – Ablauf alter Eintraege
library dao_integration_test;

import 'dart:typed_data';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:theatre_companion_app/network/db/app_database.dart';
import 'package:theatre_companion_app/network/db/dao/inventory_dao.dart';
import 'package:theatre_companion_app/network/db/dao/packet_queue_dao.dart';
import 'package:theatre_companion_app/network/models/ble_packet.dart';
import 'package:theatre_companion_app/network/models/inventory_item_crdt.dart';

// ─── Hilfsfunktionen ─────────────────────────────────────────────────────────
/// Berechnet den djb2-16-Bit-Hash einer String-ID (muss identisch mit
/// InventoryDao.getByShortId() sein).
int djb2ShortId(String id) {
  int hash = 5381;
  for (final unit in id.codeUnits) {
    hash = ((hash << 5) + hash) ^ unit;
  }
  return hash & 0xFFFF;
}

/// Erstellt ein Test-CRDT fuer einen Artikel.
InventoryItemCrdt makeTestCrdt({
  required String itemId,
  int statusId = 1,
  String? location,
  int wallClockMs = 1000000,
}) {
  return InventoryItemCrdt.create(
    itemId: itemId,
    deviceId: 'device-test-aaa',
    deviceShortId: 0xAAAA,
    statusId: statusId,
    locationTag: location,
    wallClockMs: wallClockMs,
  );
}

// ─────────────────────────────────────────────────────────────────────────────
void main() {
  late AppDatabase db;
  late InventoryDao inventoryDao;
  late PacketQueueDao queueDao;
  setUp(() {
    // In-Memory-SQLite-Datenbank fuer jeden Test neu erstellen
    db = AppDatabase(NativeDatabase.memory());
    inventoryDao = InventoryDao(db);
    queueDao = PacketQueueDao(db);
  });
  tearDown(() async {
    await db.close();
  });
  // ─── InventoryDao ─────────────────────────────────────────────────────────
  group('InventoryDao', () {
    test('upsertCrdt() persistiert neuen Artikel', () async {
      final crdt = makeTestCrdt(itemId: 'item-uuid-001', statusId: 1);
      await inventoryDao.upsertCrdt(crdt);
      final result = await inventoryDao.getByItemId('item-uuid-001');
      expect(result, isNotNull);
      expect(result!.itemId, equals('item-uuid-001'));
      expect(result.statusId, equals(1));
    });
    test('upsertCrdt() aktualisiert vorhandenen Artikel (idempotent)',
        () async {
      final crdt1 = makeTestCrdt(itemId: 'item-001', statusId: 1);
      await inventoryDao.upsertCrdt(crdt1);
      final crdt2 = makeTestCrdt(itemId: 'item-001', statusId: 3);
      await inventoryDao.upsertCrdt(crdt2);
      final items = await inventoryDao.getAllItems();
      expect(items, hasLength(1)); // Kein Duplikat
      expect(items.first.statusId, equals(3));
    });
    test('mergeRemote() fuegt neues Item ein wenn noch nicht vorhanden',
        () async {
      final remote = makeTestCrdt(itemId: 'item-new', statusId: 2);
      final merged = await inventoryDao.mergeRemote(remote);
      expect(merged.itemId, equals('item-new'));
      expect(merged.status.value, equals(2));
      final persisted = await inventoryDao.getByItemId('item-new');
      expect(persisted, isNotNull);
    });
    test('mergeRemote() behaelt neueren lokalen Status (LWW)', () async {
      // Lokales Item mit neuerem Timestamp
      final local = makeTestCrdt(
        itemId: 'item-merge',
        statusId: 5,
        wallClockMs: 2000000, // neuerer Timestamp
      );
      await inventoryDao.upsertCrdt(local);
      // Remote mit aelterem Timestamp
      final remote = makeTestCrdt(
        itemId: 'item-merge',
        statusId: 1,
        wallClockMs: 1000000, // aelterer Timestamp
      );
      final merged = await inventoryDao.mergeRemote(remote);
      // Lokaler Status (5) muss gewinnen (newer = wins in LWW)
      expect(merged.status.value, equals(5));
    });
    test('mergeRemote() uebernimmt neueren Remote-Status (LWW)', () async {
      // Lokales Item mit aelterem Timestamp
      final local = makeTestCrdt(
        itemId: 'item-merge-remote',
        statusId: 1,
        wallClockMs: 1000000,
      );
      await inventoryDao.upsertCrdt(local);
      // Remote mit neuerem Timestamp
      final remote = makeTestCrdt(
        itemId: 'item-merge-remote',
        statusId: 7,
        wallClockMs: 3000000, // aktuellster Timestamp
      );
      final merged = await inventoryDao.mergeRemote(remote);
      expect(merged.status.value, equals(7));
    });
    test('getByShortId() findet Item ueber 16-Bit-Hash', () async {
      const itemId = 'item-stagesync-prop-42';
      final crdt = makeTestCrdt(itemId: itemId);
      await inventoryDao.upsertCrdt(crdt);
      final shortId = djb2ShortId(itemId);
      final result = await inventoryDao.getByShortId(shortId);
      expect(result, isNotNull);
      expect(result!.itemId, equals(itemId));
    });
    test('getByShortId() gibt null zurueck wenn kein Item gefunden', () async {
      final result = await inventoryDao.getByShortId(0xDEAD);
      expect(result, isNull);
    });
    test('getPendingSyncItems() liefert nicht-synchronisierte Items', () async {
      await inventoryDao.upsertCrdt(makeTestCrdt(itemId: 'item-a'));
      await inventoryDao.upsertCrdt(makeTestCrdt(itemId: 'item-b'));
      final pending = await inventoryDao.getPendingSyncItems();
      expect(pending, hasLength(2));
    });
    test('markSynced() markiert Item als synchronisiert', () async {
      await inventoryDao.upsertCrdt(makeTestCrdt(itemId: 'item-sync'));
      await inventoryDao.markSynced('item-sync');
      final pending = await inventoryDao.getPendingSyncItems();
      expect(pending.where((r) => r.itemId == 'item-sync'), isEmpty);
    });
    test('getAllItems() liefert Items nach lastUpdatedMs absteigend sortiert',
        () async {
      await inventoryDao.upsertCrdt(makeTestCrdt(
        itemId: 'item-older',
        wallClockMs: 1000,
      ));
      await inventoryDao.upsertCrdt(makeTestCrdt(
        itemId: 'item-newer',
        wallClockMs: 9000,
      ));
      final all = await inventoryDao.getAllItems();
      expect(all.first.itemId, equals('item-newer'));
      expect(all.last.itemId, equals('item-older'));
    });
  });
  // ─── PacketQueueDao ───────────────────────────────────────────────────────
  group('PacketQueueDao', () {
    final nowMs = DateTime.now().millisecondsSinceEpoch;
    test('enqueue() persistiert Paket und gibt Row-ID zurueck', () async {
      final id = await queueDao.enqueue(
        encryptedPayload: [0x01, 0x02, 0x03],
        targetDeviceId: 'peer-1',
        packetTypeByte: BlePacketType.data.wireValue,
        nowMs: nowMs,
      );
      expect(id, greaterThan(0));
    });
    test('dequeueForDelivery() gibt Pakete fuer den Ziel-Peer zurueck',
        () async {
      await queueDao.enqueue(
        encryptedPayload: [0xAA],
        targetDeviceId: 'peer-target',
        packetTypeByte: BlePacketType.data.wireValue,
        nowMs: nowMs,
      );
      await queueDao.enqueue(
        encryptedPayload: [0xBB],
        targetDeviceId: 'peer-other',
        packetTypeByte: BlePacketType.data.wireValue,
        nowMs: nowMs,
      );
      final forTarget = await queueDao.dequeueForDelivery('peer-target');
      expect(forTarget, hasLength(1));
      expect(
          forTarget.first.encryptedPayload, equals(Uint8List.fromList([0xAA])));
    });
    test(
        'dequeueForDelivery() gibt auch Broadcast-Pakete (targetDeviceId=null) zurueck',
        () async {
      await queueDao.enqueue(
        encryptedPayload: [0xCC],
        targetDeviceId: null, // Broadcast
        packetTypeByte: BlePacketType.data.wireValue,
        nowMs: nowMs,
      );
      final packets = await queueDao.dequeueForDelivery('any-peer');
      expect(packets, hasLength(1));
    });
    test(
        'dequeueForDelivery() gibt Pakete in FIFO-Reihenfolge (aelteste zuerst)',
        () async {
      final t1 = nowMs - 2000;
      final t2 = nowMs - 1000;
      final t3 = nowMs;
      await queueDao.enqueue(
          encryptedPayload: [0x03],
          targetDeviceId: null,
          packetTypeByte: 0,
          nowMs: t3);
      await queueDao.enqueue(
          encryptedPayload: [0x01],
          targetDeviceId: null,
          packetTypeByte: 0,
          nowMs: t1);
      await queueDao.enqueue(
          encryptedPayload: [0x02],
          targetDeviceId: null,
          packetTypeByte: 0,
          nowMs: t2);
      final packets = await queueDao.dequeueForDelivery('peer-x');
      expect(packets[0].encryptedPayload[0], equals(0x01)); // aeltestes zuerst
      expect(packets[1].encryptedPayload[0], equals(0x02));
      expect(packets[2].encryptedPayload[0], equals(0x03));
    });
    test('markDelivered() schliesst Paket von zukuenftiger Dequeue aus',
        () async {
      final rowId = await queueDao.enqueue(
        encryptedPayload: [0xFF],
        targetDeviceId: 'peer-x',
        packetTypeByte: BlePacketType.data.wireValue,
        nowMs: nowMs,
      );
      await queueDao.markDelivered(rowId);
      final packets = await queueDao.dequeueForDelivery('peer-x');
      expect(packets, isEmpty);
    });
    test('purgeDelivered() loescht zugestellte Pakete', () async {
      final id = await queueDao.enqueue(
        encryptedPayload: [0x01],
        targetDeviceId: null,
        packetTypeByte: 0,
        nowMs: nowMs,
      );
      await queueDao.markDelivered(id);
      final deleted = await queueDao.purgeDelivered();
      expect(deleted, equals(1));
    });
    test('purgeStale() entfernt Pakete aelter als kPacketMaxAgeMs', () async {
      // Paket mit sehr altem Timestamp (weit vor kPacketMaxAgeMs)
      final veryOldMs = nowMs - kPacketMaxAgeMs - 1;
      await queueDao.enqueue(
        encryptedPayload: [0x99],
        targetDeviceId: null,
        packetTypeByte: 0,
        nowMs: veryOldMs,
      );
      final deleted = await queueDao.purgeStale();
      expect(deleted, equals(1));
      // Danach sollte die Queue leer sein
      final remaining = await queueDao.dequeueForDelivery('any');
      expect(remaining, isEmpty);
    });
    test('purgeStale() behaelt frische Pakete', () async {
      await queueDao.enqueue(
        encryptedPayload: [0x11],
        targetDeviceId: null,
        packetTypeByte: 0,
        nowMs: nowMs, // frisches Paket
      );
      final deleted = await queueDao.purgeStale();
      expect(deleted, equals(0));
      final remaining = await queueDao.dequeueForDelivery('any');
      expect(remaining, hasLength(1));
    });
    test('incrementRetryCount() erhoehe Retry-Zaehler', () async {
      final id = await queueDao.enqueue(
        encryptedPayload: [0x55],
        targetDeviceId: 'peer-y',
        packetTypeByte: 0,
        nowMs: nowMs,
      );
      await queueDao.incrementRetryCount(id);
      await queueDao.incrementRetryCount(id);
      final packets = await queueDao.dequeueForDelivery('peer-y');
      expect(packets, hasLength(1));
      expect(packets.first.retryCount, equals(2));
    });
  });
}
