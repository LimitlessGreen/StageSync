// chat_dao.dart
// ──────────────
// Data-Access Object for the [ChatMessages] table.
import 'package:drift/drift.dart';

import '../app_database.dart';

class ChatDao {
  final AppDatabase _db;
  ChatDao(this._db);

  // ─── Write ───────────────────────────────────────────────────────────────

  /// Persists a chat message. Silently ignored if [messageId] already exists
  /// (guarantees idempotent storage for gossip-relayed duplicates).
  Future<void> insertMessage({
    required String messageId,
    required String senderDeviceId,
    required int senderShortId,
    required String senderLabel,
    required String content,
    required int timestampMs,
    required bool isMine,
  }) async {
    await _db.into(_db.chatMessages).insertOnConflictUpdate(
          ChatMessagesCompanion.insert(
            messageId: messageId,
            senderDeviceId: senderDeviceId,
            senderShortId: senderShortId,
            senderLabel: senderLabel,
            content: content,
            timestampMs: timestampMs,
            isMine: Value(isMine),
          ),
        );
  }

  // ─── Read ─────────────────────────────────────────────────────────────────

  /// Returns the last [limit] messages ordered by timestamp ascending.
  Future<List<ChatMessage>> getRecentMessages({int limit = 100}) =>
      (_db.select(_db.chatMessages)
            ..orderBy([(t) => OrderingTerm.asc(t.timestampMs)])
            ..limit(limit))
          .get();

  // ─── Streaming ────────────────────────────────────────────────────────────

  /// Emits a fresh list whenever the chat table changes.
  Stream<List<ChatMessage>> watchMessages({int limit = 200}) =>
      (_db.select(_db.chatMessages)
            ..orderBy([(t) => OrderingTerm.asc(t.timestampMs)])
            ..limit(limit))
          .watch();

  // ─── Maintenance ──────────────────────────────────────────────────────────

  /// Removes messages older than [maxAgeMs] (default 24 h).
  Future<int> purgeOld({int maxAgeMs = 24 * 60 * 60 * 1000}) async {
    final cutoff = DateTime.now().millisecondsSinceEpoch - maxAgeMs;
    return (_db.delete(_db.chatMessages)
          ..where((t) => t.timestampMs.isSmallerThanValue(cutoff)))
        .go();
  }
}
