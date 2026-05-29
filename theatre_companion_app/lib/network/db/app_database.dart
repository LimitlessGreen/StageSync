// app_database.dart
// ──────────────────
// Drift (SQLite) schema for StageSync.
//
// Tables:
//   [InventoryItems]  – LWW-CRDT state of every inventory item.
//   [PacketQueue]     – Store-Carry-Forward outbound packet queue.
//   [PeerTable]       – Known BLE peer devices and their election scores.
//
// Run code generation after editing this file:
//   flutter pub run build_runner build --delete-conflicting-outputs
import 'package:drift/drift.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

// Konditionaler Import: Auf native → NativeDatabase, auf Web → WebDatabase
import 'db_connector.dart';

part 'app_database.g.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Table: ShowCueLists
// ─────────────────────────────────────────────────────────────────────────────

class ShowCueLists extends Table {
  TextColumn get id => text()();
  TextColumn get sessionId => text()();
  TextColumn get name => text()();
  IntColumn get version => integer().withDefault(const Constant(1))();
  IntColumn get updatedAtMs => integer()();

  @override
  Set<Column> get primaryKey => {id};
}

// ─────────────────────────────────────────────────────────────────────────────
// Table: ShowCues
// ─────────────────────────────────────────────────────────────────────────────

class ShowCues extends Table {
  TextColumn get id => text()();
  TextColumn get cueListId => text()();
  TextColumn get number => text()();
  TextColumn get label => text()();
  IntColumn get cueType => integer()(); // CueType protobuf value
  TextColumn get paramsJson => text()(); // JSON-kodierte Cue-Parameter
  IntColumn get orderIndex => integer()();
  TextColumn get targetNodeId => text().nullable()();
  BoolColumn get autoContinue => boolean().withDefault(const Constant(false))();
  RealColumn get preWaitMs => real().withDefault(const Constant(0))();
  RealColumn get postWaitMs => real().withDefault(const Constant(0))();
  IntColumn get version => integer().withDefault(const Constant(1))();

  @override
  Set<Column> get primaryKey => {id};
}

// ─────────────────────────────────────────────────────────────────────────────
// Table: InventoryItems
// ─────────────────────────────────────────────────────────────────────────────

/// Stores the full CRDT state of a single inventory item.
/// The [crdtJson] column contains the serialised [InventoryItemCrdt] including
/// both LWW fields and their vector clocks.
class InventoryItems extends Table {
  /// Auto-increment primary key (local DB-only; not distributed).
  IntColumn get id => integer().autoIncrement()();

  /// Application-level globally unique item ID (QR value / UUID string).
  TextColumn get itemId => text().unique()();

  /// Serialised [InventoryItemCrdt] JSON – single source of truth.
  TextColumn get crdtJson => text()();

  /// StatusId cached at the DB row level for fast SQL filtering.
  IntColumn get statusId => integer()();

  /// Location tag cached for fast SQL querying.
  TextColumn get locationTag => text().nullable()();

  /// Wall-clock ms of the most recent local write (for quick ordering).
  IntColumn get lastUpdatedMs => integer()();

  /// DeviceID that made the most recent write to this row.
  TextColumn get sourceDeviceId => text()();

  /// True once the central server acknowledged this item's current CRDT state.
  BoolColumn get isSyncedToServer =>
      boolean().withDefault(const Constant(false))();
}

// ─────────────────────────────────────────────────────────────────────────────
// Table: PacketQueue  (Store-Carry-Forward)
// ─────────────────────────────────────────────────────────────────────────────

/// Persists outbound BLE packets that could not yet be delivered because no
/// peers were in range. On peer discovery the queue is drained automatically.
class PacketQueue extends Table {
  IntColumn get id => integer().autoIncrement()();

  /// Raw ENCRYPTED bytes of the BLE packet.
  BlobColumn get encryptedPayload => blob()();

  /// Target peer device ID; null means broadcast to all reachable peers.
  TextColumn get targetDeviceId => text().nullable()();

  /// PacketType byte (mirrors [BlePacketType.wireValue]) for fast filtering.
  IntColumn get packetTypeByte => integer()();

  /// Creation timestamp (ms) – used for TTL expiration of stale queue entries.
  IntColumn get createdAtMs => integer()();

  /// Number of delivery attempts made so far.
  IntColumn get retryCount => integer().withDefault(const Constant(0))();

  /// Delivered successfully – retained briefly for idempotent deduplication.
  BoolColumn get isDelivered => boolean().withDefault(const Constant(false))();
}

// ─────────────────────────────────────────────────────────────────────────────
// Table: PeerTable
// ─────────────────────────────────────────────────────────────────────────────

/// Tracks all known BLE peers discovered during the current session.
/// This table is ephemeral (cleared on cold start) but persisted in SQLite
/// so the network isolate can query it efficiently via Drift.
class PeerTable extends Table {
  /// Full device ID string (UUID or platform BLE device ID).
  TextColumn get deviceId => text()();

  /// Pre-computed uint16 short ID (lower 16 bits of djb2 hash of deviceId).
  IntColumn get deviceShortId => integer()();

  /// Most recently received election score from this peer.
  IntColumn get electionScore => integer().withDefault(const Constant(0))();

  /// Last received RSSI value (dBm, negative).
  IntColumn get rssi => integer().withDefault(const Constant(-100))();

  /// Epoch ms of the most recent contact (scan, heartbeat, or data packet).
  IntColumn get lastSeenMs => integer()();

  /// True if this peer is currently considered the network leader.
  BoolColumn get isLeader => boolean().withDefault(const Constant(false))();

  /// True if this peer is believed to have an active internet connection.
  BoolColumn get hasInternet => boolean().withDefault(const Constant(false))();

  @override
  Set<Column> get primaryKey => {deviceId};
}

// ─────────────────────────────────────────────────────────────────────────────
// Table: ChatMessages
// ─────────────────────────────────────────────────────────────────────────────

/// Persists all chat messages seen or originated by this device.
class ChatMessages extends Table {
  IntColumn get id => integer().autoIncrement()();

  /// UUID string that uniquely identifies the message across the whole mesh.
  TextColumn get messageId => text().unique()();

  /// Full device ID of the author.
  TextColumn get senderDeviceId => text()();

  /// uint16 short ID of the sender (for compact display).
  IntColumn get senderShortId => integer()();

  /// Human-readable label derived from senderDeviceId.
  TextColumn get senderLabel => text()();

  /// UTF-8 text content.
  TextColumn get content => text()();

  /// Wall-clock ms when the message was created by the sender.
  IntColumn get timestampMs => integer()();

  /// True if this device originated the message.
  BoolColumn get isMine => boolean().withDefault(const Constant(false))();
}

// ─────────────────────────────────────────────────────────────────────────────
// Database Class
// ─────────────────────────────────────────────────────────────────────────────

@DriftDatabase(tables: [InventoryItems, PacketQueue, PeerTable, ChatMessages, ShowCueLists, ShowCues])
class AppDatabase extends _$AppDatabase {
  AppDatabase(super.e);

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onCreate: (m) async {
          await m.createAll();
        },
        onUpgrade: (m, from, to) async {
          if (from < 2) {
            await m.createTable(chatMessages);
          }
          if (from < 3) {
            await m.createTable(showCueLists);
            await m.createTable(showCues);
          }
        },
      );

  @override
  int get schemaVersion => 3;

  // ─── Convenience: open on the main isolate (path_provider available) ────

  /// Opens the database in the application documents directory.
  /// Must be called from the main isolate (uses path_provider).
  static Future<String> resolveDatabasePath() async {
    final dir = await getApplicationDocumentsDirectory();
    return p.join(dir.path, 'stagesync.db');
  }

  /// Opens the database given an absolute file [path] (native) or a name (web).
  /// Delegates to the platform-specific [openDatabaseForPlatform] function.
  static AppDatabase openAtPath(String path) {
    return AppDatabase(openDatabaseForPlatform(path));
  }
}



