// inventory_dao.dart
// ───────────────────
// Data-Access Object for the [InventoryItems] table.
// All CRDT merge logic lives in [InventoryItemCrdt]; this DAO is purely
// concerned with atomic SQLite persistence and efficient querying.
import 'package:drift/drift.dart';

import '../app_database.dart';
import '../../models/inventory_item_crdt.dart';

class InventoryDao {
  final AppDatabase _db;

  InventoryDao(this._db);

  // ─── Read ────────────────────────────────────────────────────────────────

  /// Returns all inventory items ordered by most recently updated.
  Future<List<InventoryItem>> getAllItems() =>
      (_db.select(_db.inventoryItems)
            ..orderBy([(t) => OrderingTerm.desc(t.lastUpdatedMs)]))
          .get();

  /// Returns a single item by its application-level [itemId], or null.
  Future<InventoryItem?> getByItemId(String itemId) =>
      (_db.select(_db.inventoryItems)
            ..where((t) => t.itemId.equals(itemId)))
          .getSingleOrNull();

  /// Sucht alle lokalen Items, deren 16-Bit-ShortId (djb2 hash % 65536) mit
  /// [shortId] übereinstimmt. Wird benötigt, um eingehende kompakte BLE-DataPackets
  /// (die nur den 16-Bit-Hash des ItemId tragen) einem vollständigen UUID
  /// zuzuordnen.
  ///
  /// **Einschränkung:** Bei Hash-Kollisionen (selten, aber möglich) können
  /// mehrere Items zurückgegeben werden. In diesem Fall wird das zuletzt
  /// aktualisierte Item als Kandidat verwendet. Für eine kollisionsfreie
  /// Zuordnung müsste das BLE-Paketformat auf einen längeren Hash (32–64 Bit)
  /// oder die vollständige UUID erweitert werden.
  Future<InventoryItem?> getByShortId(int shortId) async {
    // Alle persisitierten Items laden und per djb2-Hash filtern.
    // Da die DB typischerweise wenige hundert Items enthält, ist ein
    // Client-seitiger Filter hier akzeptabel (keine Voll-Tabellen-Expansion).
    final all = await getAllItems();
    final matches = all.where((item) {
      int hash = 5381;
      for (final unit in item.itemId.codeUnits) {
        hash = ((hash << 5) + hash) ^ unit;
      }
      return (hash & 0xFFFF) == shortId;
    }).toList();
    if (matches.isEmpty) return null;
    // Bei Mehrfach-Treffer: das zuletzt aktualisierte Item wählen.
    matches.sort((a, b) => b.lastUpdatedMs.compareTo(a.lastUpdatedMs));
    return matches.first;
  }

  /// Returns all items not yet acknowledged by the central server.
  Future<List<InventoryItem>> getPendingSyncItems() =>
      (_db.select(_db.inventoryItems)
            ..where((t) => t.isSyncedToServer.equals(false)))
          .get();

  // ─── Write ───────────────────────────────────────────────────────────────

  /// Persists or updates a [InventoryItemCrdt] in a single atomic operation.
  ///
  /// Uses Drift's [insertOnConflictUpdate] so this call is safe to call
  /// multiple times with the same [crdt] without duplicate rows.
  ///
  /// Returns the row-level DB primary key.
  Future<int> upsertCrdt(InventoryItemCrdt crdt) async {
    final companion = InventoryItemsCompanion.insert(
      itemId: crdt.itemId,
      crdtJson: crdt.toJsonString(),
      statusId: crdt.status.value,
      locationTag: Value(crdt.location.value),
      lastUpdatedMs: crdt.status.wallClockMs > crdt.location.wallClockMs
          ? crdt.status.wallClockMs
          : crdt.location.wallClockMs,
      sourceDeviceId: crdt.status.ownerShortId.toString(),
    );
    return _db.into(_db.inventoryItems).insert(
      companion,
      onConflict: DoUpdate(
        (old) => companion,
        target: [_db.inventoryItems.itemId],
      ),
    );
  }

  /// Merges a remote [InventoryItemCrdt] with the local copy (if any).
  ///
  /// Algorithm:
  ///   1. Load current local state from DB.
  ///   2. Call [InventoryItemCrdt.merge] → produces the merged winner.
  ///   3. Persist the merged state atomically.
  ///   4. Return the merged CRDT (so the caller can emit an [ItemUpdatedEvent]).
  ///
  /// This entire sequence runs inside a Drift transaction to prevent races.
  Future<InventoryItemCrdt> mergeRemote(InventoryItemCrdt remote) async {
    return _db.transaction<InventoryItemCrdt>(() async {
      final existing = await getByItemId(remote.itemId);

      InventoryItemCrdt merged;
      if (existing == null) {
        // First time we see this item – remote state is authoritative.
        merged = remote;
      } else {
        final local = InventoryItemCrdt.fromJsonString(existing.crdtJson);
        merged = local.merge(remote);
      }

      await upsertCrdt(merged);
      return merged;
    });
  }

  /// Marks an item as successfully synced to the central server.
  Future<void> markSynced(String itemId) async {
    await (_db.update(_db.inventoryItems)
          ..where((t) => t.itemId.equals(itemId)))
        .write(const InventoryItemsCompanion(isSyncedToServer: Value(true)));
  }

  /// Marks all items as unsynced (e.g. after a server reconnection where we
  /// need to replay the full local state).
  Future<void> markAllUnsynced() async {
    await _db.update(_db.inventoryItems).write(
          const InventoryItemsCompanion(isSyncedToServer: Value(false)),
        );
  }

  // ─── Streaming ───────────────────────────────────────────────────────────

  /// Emits a fresh list every time the [InventoryItems] table changes.
  /// The UI can consume this via a Riverpod StreamProvider for live updates.
  Stream<List<InventoryItem>> watchAllItems() =>
      (_db.select(_db.inventoryItems)
            ..orderBy([(t) => OrderingTerm.desc(t.lastUpdatedMs)]))
          .watch();
}

