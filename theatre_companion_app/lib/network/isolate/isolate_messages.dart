// ignore_for_file: public_member_api_docs

// isolate_messages.dart
// ─────────────────────
// Defines the entire typed message protocol between the UI Isolate (main) and
// the Network Isolate (background). Every cross-isolate call must use one of
// these sealed classes so that pattern matching on both sides is exhaustive
// and compile-time safe.
//
// Direction conventions:
//   [NetworkCommand]  →  Main Isolate  ─►  Network Isolate
//   [NetworkEvent]    ←  Network Isolate  ◄─  Main Isolate
// ═══════════════════════════════════════════════════════════════════════════════
// TRANSPORT HINT  (app-level routing preference)
// ═══════════════════════════════════════════════════════════════════════════════

// Gibt dem Netzwerk-Stack einen Hinweis, wie eine Nachricht am besten
// transportiert werden soll.  Die App muss **keine** Kenntnis von BLE-Mesh,
// WebSocket oder Cloud besitzen – der Stack trifft die endgültige Routing-
// Entscheidung anhand dieses Hinweises und der aktuellen Topologie.
enum TransportHint {
  /// Netzwerk-Stack entscheidet automatisch (empfohlen, Standard).
  /// Leader → WebSocket; Follower → BLE-Mesh; bei Problemen → Store-Carry-Forward.
  auto,

  /// BLE-Mesh bevorzugen, auch wenn Cloud verfügbar ist.
  /// Sinnvoll für kleine, latenzempfindliche Deltas im lokalen Bereich.
  preferBle,

  /// Nur via Server/Cloud senden – BLE-Mesh komplett umgehen.
  /// Nutze dies für Payloads > 50 KB oder wenn Vertraulichkeit wichtig ist.
  cloudOnly,

  /// Alle verfügbaren Transporte gleichzeitig nutzen (höchste Zuverlässigkeit).
  /// Geeignet für sicherheitskritische oder zeitkritische Befehle.
  urgent,
}

// ═══════════════════════════════════════════════════════════════════════════════
// DATA CLASSES  (shared between both isolates)
// ═══════════════════════════════════════════════════════════════════════════════

// Einzelner Cloud-Peer (verbunden über Socket.IO Realtime-Server).
class CloudPeerInfo {
  final String userId;
  final String userName;

  const CloudPeerInfo({required this.userId, required this.userName});

  /// Kurzanzeige für die UI (letzten 8 Zeichen der userId).
  String get shortId =>
      userId.length > 8 ? '…${userId.substring(userId.length - 8)}' : userId;
}

/// Snapshot of a single peer as seen by the local device.
class PeerStatusInfo {
  final String deviceId;
  final int deviceShortId;

  /// Signal strength in dBm (negative; closer to 0 = stronger signal).
  final int rssi;

  /// Most recently broadcast election score.
  final int electionScore;
  final bool isLeader;
  final bool hasInternet;

  /// Epoch ms of last contact.
  final int lastSeenMs;

  const PeerStatusInfo({
    required this.deviceId,
    required this.deviceShortId,
    required this.rssi,
    required this.electionScore,
    required this.isLeader,
    required this.hasInternet,
    required this.lastSeenMs,
  });

  /// Signal quality 0–4 (for icon selection).
  int get signalBars {
    if (rssi >= -55) return 4;
    if (rssi >= -67) return 3;
    if (rssi >= -80) return 2;
    if (rssi >= -90) return 1;
    return 0;
  }

  String get shortId => deviceId.length > 8
      ? '…${deviceId.substring(deviceId.length - 8)}'
      : deviceId;
}

/// Breakdown of the local score for the detailed status screen.
class NetworkScoreBreakdown {
  final bool hasNetwork;
  final bool isCharging;
  final int batteryPercent;
  final bool isMoving;
  final int total;

  const NetworkScoreBreakdown({
    required this.hasNetwork,
    required this.isCharging,
    required this.batteryPercent,
    required this.isMoving,
    required this.total,
  });

  static const NetworkScoreBreakdown zero = NetworkScoreBreakdown(
    hasNetwork: false,
    isCharging: false,
    batteryPercent: 0,
    isMoving: false,
    total: 0,
  );
}

// ═══════════════════════════════════════════════════════════════════════════════
// COMMANDS  (Main Isolate → Network Isolate)
// ═══════════════════════════════════════════════════════════════════════════════

/// Base sealed class for all commands sent to the network isolate.
sealed class NetworkCommand {}

/// Record an inventory scan performed by the user.
/// The network layer handles CRDT merge, DB persistence, and propagation.
///
/// Setze [hint] auf [TransportHint.cloudOnly] für Payloads > 50 KB oder
/// wenn die Daten nicht über BLE-Mesh laufen sollen (z.B. sensible Inhalte).
final class ScanItemCommand extends NetworkCommand {
  /// Application-level unique identifier (e.g. QR-code value or UUID string).
  final String itemId;

  /// Numeric status code (0 = InPlace, 1 = CheckedOut, 2 = Missing, …).
  final int statusId;

  /// Optional physical location tag (e.g. "Stage Right", "Dressing Room 3").
  final String? locationTag;

  /// Wall-clock timestamp in milliseconds since epoch at the moment of scan.
  final int timestampMs;

  /// Routing-Präferenz – die App signalisiert dem Stack, wie das Update
  /// am besten transportiert werden soll.  Standardmäßig [TransportHint.auto].
  final TransportHint hint;

  ScanItemCommand({
    required this.itemId,
    required this.statusId,
    this.locationTag,
    required this.timestampMs,
    this.hint = TransportHint.auto,
  });

  @override
  String toString() =>
      'ScanItemCommand(itemId=$itemId, status=$statusId, ts=$timestampMs, hint=$hint)';
}

/// Announces that a large payload transfer is upcoming.
///
/// Die App ruft dies auf, bevor sie einen großen Datensatz senden will
/// (z.B. Bühnenpläne, Bilder, Logs).  Der Stack kann daraufhin:
///   • eine Cloud-Verbindung sicherstellen
///   • BLE-Mesh-Nutzung für die nächsten Minuten reduzieren
///   • Den Sync-Status anpassen
///
/// Beispiel:
/// ```dart
/// facade.announceTransfer(estimatedBytes: 512 * 1024, description: 'Stage plan PDF');
/// ```
final class TransferAnnouncementCommand extends NetworkCommand {
  /// Geschätzte Payload-Größe in Bytes.
  final int estimatedBytes;

  /// Optionale menschenlesbare Beschreibung (für Logs / UI).
  final String? description;

  TransferAnnouncementCommand({
    required this.estimatedBytes,
    this.description,
  });

  /// Gibt an, ob der Transfer als "groß" gilt (> 50 KB).
  bool get isLargeTransfer => estimatedBytes > 50 * 1024;
}

/// Instructs the election engine to immediately start a new leader election.
/// Useful after a known topology change (e.g. stage manager's tablet just
/// plugged in to power = instant high score candidate).
final class ForceElectionCommand extends NetworkCommand {}

/// Connect the leader's WebSocket gateway to [serverUrl].
/// Ignored silently if this device is currently a follower.
final class ConnectToServerCommand extends NetworkCommand {
  final String serverUrl;
  ConnectToServerCommand(this.serverUrl);
}

/// Verbindet die App mit dem Socket.IO Realtime-Server der Website.
/// Funktioniert unabhängig vom Leader-Status – jedes Gerät kann cloud-connected sein.
final class CloudConnectCommand extends NetworkCommand {
  /// Socket.IO-Server URL, z. B. 'https://theater.example.com' oder 'http://192.168.1.10:4001'
  final String serverUrl;

  /// Theater-Konto-ID (userId für HMAC-Auth)
  final String userId;

  /// Anzeigename im Präsenz-System
  final String userName;

  /// HMAC-SHA256-Geheimnis (vom Server-Administrator erhalten)
  final String secret;

  /// Optional: Vorstellungs-ID zum Beitreten des `show_xxx` Raums
  final String? showId;

  CloudConnectCommand({
    required this.serverUrl,
    required this.userId,
    required this.userName,
    required this.secret,
    this.showId,
  });
}

/// Trennt die Cloud-Verbindung (Socket.IO).
final class CloudDisconnectCommand extends NetworkCommand {}

/// Request a one-shot status snapshot (triggers [NetworkStatusEvent] reply).
final class QueryStatusCommand extends NetworkCommand {}

/// Gracefully shut down all network services inside the background isolate.
final class ShutdownCommand extends NetworkCommand {}

/// Send a chat message over the BLE mesh + server (if connected).
final class SendChatMessageCommand extends NetworkCommand {
  /// The text content to broadcast. Capped at 180 UTF-8 bytes by the engine.
  final String content;
  SendChatMessageCommand({required this.content});
}

// ═══════════════════════════════════════════════════════════════════════════════
// EVENTS  (Network Isolate → Main Isolate)
// ═══════════════════════════════════════════════════════════════════════════════

/// Base sealed class for all events emitted by the network isolate.
sealed class NetworkEvent {}

/// Leadership has changed – either this device became leader / follower,
/// or the previous leader was declared dead and a new one was elected.
final class LeaderChangedEvent extends NetworkEvent {
  /// DeviceID of the newly elected leader.
  final String newLeaderDeviceId;

  /// True if THIS device is now the leader (internet gateway).
  final bool isThisDeviceLeader;

  /// The winning score that determined the election outcome.
  final int leaderScore;

  LeaderChangedEvent({
    required this.newLeaderDeviceId,
    required this.isThisDeviceLeader,
    required this.leaderScore,
  });
}

/// An inventory item's CRDT state changed, either from a local scan command
/// or from an incoming BLE mesh packet that was successfully merged.
final class ItemUpdatedEvent extends NetworkEvent {
  final String itemId;
  final int statusId;
  final String? locationTag;

  /// The device that originated this change.
  final String sourceDeviceId;

  final int timestampMs;

  /// True once the central server has acknowledged this update.
  final bool isSyncedToServer;

  ItemUpdatedEvent({
    required this.itemId,
    required this.statusId,
    this.locationTag,
    required this.sourceDeviceId,
    required this.timestampMs,
    required this.isSyncedToServer,
  });
}

/// A new BLE peer was discovered (isOnline=true) or an existing peer timed
/// out and should be considered gone (isOnline=false).
final class PeerDiscoveredEvent extends NetworkEvent {
  final String deviceId;

  /// Signal strength in dBm (negative; closer to 0 = stronger).
  final int rssi;

  /// true = newly seen / still alive; false = heartbeat timeout.
  final bool isOnline;

  PeerDiscoveredEvent({
    required this.deviceId,
    required this.rssi,
    required this.isOnline,
  });
}

/// Periodic health snapshot emitted roughly every 5 seconds by the network
/// isolate so the UI can show live connectivity indicators.
final class NetworkStatusEvent extends NetworkEvent {
  final int connectedPeerCount;
  final int pendingQueuedPackets;
  final bool hasServerConnection;
  final String? currentLeaderId;

  /// This device's current election score (computed live).
  final int localElectionScore;

  final NetworkSyncStatus syncStatus;

  /// Full peer list for the status screen (updated every 5 s).
  final List<PeerStatusInfo> peers;

  /// Score breakdown for the status screen.
  final NetworkScoreBreakdown scoreBreakdown;

  NetworkStatusEvent({
    required this.connectedPeerCount,
    required this.pendingQueuedPackets,
    required this.hasServerConnection,
    this.currentLeaderId,
    required this.localElectionScore,
    required this.syncStatus,
    this.peers = const [],
    this.scoreBreakdown = NetworkScoreBreakdown.zero,
  });
}

/// A chat message was received (either from BLE mesh or server).
final class ChatMessageReceivedEvent extends NetworkEvent {
  /// Stable message ID – used for deduplication in the UI.
  final String messageId;

  /// Full device ID of the sender.
  final String senderDeviceId;

  /// Display-friendly short ID (last 8 chars).
  final String senderShortLabel;

  final String content;
  final int timestampMs;

  /// True if THIS device originated the message.
  final bool isMine;

  ChatMessageReceivedEvent({
    required this.messageId,
    required this.senderDeviceId,
    required this.senderShortLabel,
    required this.content,
    required this.timestampMs,
    required this.isMine,
  });
}

/// Unrecoverable error inside the network isolate.
/// The UI should attempt [NetworkIsolateManager.restart()] on receipt.
final class NetworkErrorEvent extends NetworkEvent {
  final String message;
  final String? dartStackTrace;
  NetworkErrorEvent(this.message, {this.dartStackTrace});
}

/// BLE-Layer Statusbericht – wird emittiert wenn Advertising startet, stoppt
/// oder fehlschlägt. Nützlich für Debug-UIs und Diagnose.
final class BleStatusEvent extends NetworkEvent {
  /// True wenn das Gerät aktuell als Peripheral advertised.
  final bool isAdvertising;

  /// True wenn aktiv nach anderen StageSync-Geräten gescannt wird.
  final bool isScanning;

  /// Falls != null: Fehlermeldung (z.B. BT nicht verfügbar, Permission fehlt).
  final String? errorMessage;

  /// Anzahl aktuell offener GATT-Verbindungen zu Peers.
  final int activeConnectionCount;

  /// True wenn der Scan im Fallback-Modus (ohne UUID-Filter) läuft.
  final bool isFallbackScanMode;

  BleStatusEvent({
    required this.isAdvertising,
    required this.isScanning,
    this.errorMessage,
    this.activeConnectionCount = 0,
    this.isFallbackScanMode = false,
  });
}

/// Status der Cloud-Verbindung (Socket.IO Realtime-Server).
final class CloudConnectionChangedEvent extends NetworkEvent {
  /// true = verbunden, false = getrennt/Fehler
  final bool isConnected;

  /// Der Server-URL falls verbunden (zur UI-Anzeige)
  final String? serverUrl;

  CloudConnectionChangedEvent({
    required this.isConnected,
    this.serverUrl,
  });
}

/// Aktuell über den Realtime-Server sichtbare Peers (user_joined / user_left).
/// Wird nach jeder Änderung der Peer-Liste gesendet.
final class CloudPeersUpdatedEvent extends NetworkEvent {
  /// Alle Peers die aktuell im gemeinsamen Companion-Raum sichtbar sind
  /// (exkl. dieses Gerät selbst).
  final List<CloudPeerInfo> peers;

  /// Gesamtzahl aller verbundenen Sockets auf dem Server (inkl. Web-Clients).
  final int totalOnline;

  CloudPeersUpdatedEvent({
    required this.peers,
    required this.totalOnline,
  });
}

// ═══════════════════════════════════════════════════════════════════════════════
// SHARED ENUMS
// ═══════════════════════════════════════════════════════════════════════════════

enum NetworkSyncStatus {
  /// Actively pushing/pulling with the central server (leader only).
  syncing,

  /// All local changes have been acknowledged by the server.
  upToDate,

  /// No BLE peers and no server connection; fully isolated device.
  offline,

  /// Operating over BLE mesh only – leader holds the server connection.
  meshOnly,
}
