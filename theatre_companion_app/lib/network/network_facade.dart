// network_facade.dart
// ────────────────────
// **High-Level API für den StageSync Netzwerk-Stack.**
//
// Die App interagiert mit dem Netzwerk ausschließlich über diese Klasse.
// Routing-Entscheidungen (BLE vs. Cloud, Relay, Verschlüsselung, Leader-
// Election) finden intern statt – die App muss davon nichts wissen.
//
// ## Warum NetworkFacade?
//
// Das bisherige API verlangte von der App Kenntnis über interne Typen
// ([ScanItemCommand], [CloudConnectCommand], etc.) und deren Parameter.
// [NetworkFacade] kapselt diese Details und bietet stattdessen semantische
// Methoden an, die dem Theaterkontext entsprechen.
//
// ## Routing-Transparenz (TransportHint)
//
// Die App kann dem Stack optional signalisieren, wie ein Datensatz
// transportiert werden soll – ohne zu wissen, WIE das technisch umgesetzt
// wird: `hint: TransportHint.cloudOnly` → kein BLE, Daten gehen nur via
// Server. Das ist bei großen Payloads oder sensiblen Daten sinnvoll.
//
// ## Beispiel
//
// ```dart
// // Provider-Zugriff (Riverpod):
// final facade = ref.read(networkFacadeProvider);
//
// // Kleines CRDT-Update:
// facade.scanItem(itemId: qrCodeValue, statusId: 1);
//
// // Großer Transfer ankündigen (Stack bevorzugt Cloud für 2 Min.):
// await facade.announceTransfer(estimatedBytes: 500 * 1024, description: 'Bühnenplan PDF');
//
// // Chat:
// facade.sendChat('Scheinwerfer B3 ist ausgefallen!');
//
// // Cloud verbinden:
// await facade.connectCloud(serverUrl: 'https://theater.example.com', ...);
// ```
import 'isolate/isolate_messages.dart';
import 'isolate/network_isolate_manager.dart';

export 'isolate/isolate_messages.dart'
    show
        NetworkEvent,
        NetworkCommand,
        TransportHint,
        NetworkStatusEvent,
        ItemUpdatedEvent,
        ChatMessageReceivedEvent,
        LeaderChangedEvent,
        PeerDiscoveredEvent,
        BleStatusEvent,
        CloudConnectionChangedEvent,
        CloudPeersUpdatedEvent,
        NetworkErrorEvent,
        NetworkSyncStatus,
        PeerStatusInfo,
        NetworkScoreBreakdown,
        CloudPeerInfo;

/// Facade für den StageSync Netzwerk-Stack.
///
/// Instanz via Riverpod: `ref.read(networkFacadeProvider)`.
/// Lebenszeit: an den [NetworkIsolateManager] gebunden.
class NetworkFacade {
  final NetworkIsolateManager _manager;

  const NetworkFacade(this._manager);

  // ─── Events ───────────────────────────────────────────────────────────────

  /// Roher Event-Stream aus dem Netzwerk-Stack.
  ///
  /// Für typisierte Streams nutze die abgeleiteten Riverpod-Provider
  /// (z.B. [itemUpdateStreamProvider], [chatEventStreamProvider]).
  Stream<NetworkEvent> get events => _manager.events;

  // ─── Inventory ────────────────────────────────────────────────────────────

  /// Meldet einen Inventar-Scan an den Netzwerk-Stack.
  ///
  /// Der Stack:
  ///   1. Mergt den Scan mit dem lokalen CRDT-Zustand
  ///   2. Persistiert atomar in SQLite
  ///   3. Leitet per bestem verfügbarem Transport weiter (BLE oder Cloud)
  ///
  /// Parameter:
  ///   - [itemId]     Eindeutige Item-ID (z.B. QR-Code-Inhalt, UUID)
  ///   - [statusId]   Numerischer Status (0=InPlace, 1=CheckedOut, 2=Missing, …)
  ///   - [locationTag] Optionaler Ort (z.B. "Bühne Rechts", "Umkleide 3")
  ///   - [hint]       Routing-Präferenz; Standard: [TransportHint.auto]
  ///
  /// Setze [hint] = [TransportHint.cloudOnly] wenn der Payload groß ist
  /// oder ausschließlich über den Server laufen soll.
  void scanItem({
    required String itemId,
    required int statusId,
    String? locationTag,
    TransportHint hint = TransportHint.auto,
  }) {
    _manager.send(ScanItemCommand(
      itemId: itemId,
      statusId: statusId,
      locationTag: locationTag,
      timestampMs: DateTime.now().millisecondsSinceEpoch,
      hint: hint,
    ));
  }

  // ─── Large Payload ────────────────────────────────────────────────────────

  /// Kündigt einen bevorstehenden großen Datentransfer an.
  ///
  /// Der Stack reagiert darauf:
  ///   • Bei Payloads > 50 KB: Cloud-Routing für die nächsten 2 Minuten
  ///     bevorzugt, BLE-Mesh wird reduziert
  ///   • Cloud-Verbindung wird priorisiert sichert
  ///
  /// Rufe diese Methode **vor** dem eigentlichen Transfer auf.
  ///
  /// Beispiel (Bühnenplan hochladen):
  /// ```dart
  /// await facade.announceTransfer(
  ///   estimatedBytes: pdfBytes.length,
  ///   description: 'Bühnenplan Akt 2',
  /// );
  /// // ... jetzt den Transfer starten
  /// ```
  void announceTransfer({
    required int estimatedBytes,
    String? description,
  }) {
    _manager.send(TransferAnnouncementCommand(
      estimatedBytes: estimatedBytes,
      description: description,
    ));
  }

  // ─── Chat ─────────────────────────────────────────────────────────────────

  /// Sendet eine Chat-Nachricht an alle Peers (BLE-Mesh + Cloud wenn verbunden).
  ///
  /// Die Nachricht wird auf max. 180 UTF-8-Bytes begrenzt (BLE-MTU-Grenze).
  /// Längere Nachrichten werden ohne Warnung abgeschnitten.
  void sendChat(String text) {
    _manager.send(SendChatMessageCommand(content: text));
  }

  // ─── Cloud ────────────────────────────────────────────────────────────────

  /// Verbindet die App mit dem Realtime-Server (Socket.IO).
  ///
  /// Parameter:
  ///   - [serverUrl]  URL, z.B. 'https://theater.example.com'
  ///   - [userId]     Theater-Konto-ID (für HMAC-Auth)
  ///   - [userName]   Anzeigename im Präsenz-System
  ///   - [secret]     HMAC-SHA256-Geheimnis (vom Server-Admin erhalten)
  ///   - [showId]     Optional: Vorstellungs-ID (tritt `show_<showId>`-Raum bei)
  void connectCloud({
    required String serverUrl,
    required String userId,
    required String userName,
    required String secret,
    String? showId,
  }) {
    _manager.send(CloudConnectCommand(
      serverUrl: serverUrl,
      userId: userId,
      userName: userName,
      secret: secret,
      showId: showId,
    ));
  }

  /// Trennt die Cloud-Verbindung.
  void disconnectCloud() {
    _manager.send(CloudDisconnectCommand());
  }

  // ─── Election & Control ───────────────────────────────────────────────────

  /// Löst sofort eine neue Leader-Election aus.
  ///
  /// Sinnvoll wenn sich die Topologie geändert hat, z.B. wenn ein Gerät mit
  /// Strom verbunden wurde und damit einen höheren Election-Score hat.
  void forceElection() {
    _manager.send(ForceElectionCommand());
  }

  /// Fordert einen einmaligen Netzwerk-Status-Snapshot an.
  ///
  /// Löst ein [NetworkStatusEvent] im [events]-Stream aus.
  void queryStatus() {
    _manager.send(QueryStatusCommand());
  }

  // ─── Raw access (for advanced use cases) ─────────────────────────────────

  /// Ermöglicht das direkte Senden einer [NetworkCommand]-Instanz.
  ///
  /// Nur für fortgeschrittene Anwendungsfälle.  Nutze bevorzugt die
  /// semantischen Methoden oben.
  void sendRaw(NetworkCommand command) {
    _manager.send(command);
  }
}

