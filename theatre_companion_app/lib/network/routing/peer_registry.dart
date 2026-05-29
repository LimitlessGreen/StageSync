/// peer_registry.dart
/// ────────────────────
/// In-memory registry of all currently known BLE peers.
/// It is owned and mutated exclusively inside the Network Isolate.
///
/// Responsibilities:
///   * Track each peer's last-seen timestamp, RSSI, and election score.
///   * Declare peers dead after [kPeerTimeoutMs] without contact.
///   * Expose the current leader device ID based on the highest known score.
///   * Emit [PeerChangeCallback] whenever the peer list changes (used by the
///     GossipEngine and LeaderElectionEngine to react to topology changes).
/// How long (ms) without any contact before a peer is considered offline.
const int kPeerTimeoutMs = 6000;

/// Callback type for peer change notifications.
typedef PeerChangeCallback = void Function(PeerInfo peer, bool isNowOnline);

// ─────────────────────────────────────────────────────────────────────────────
// PeerInfo – value object for a single peer
// ─────────────────────────────────────────────────────────────────────────────

class PeerInfo {
  final String deviceId;
  final int deviceShortId; // uint16

  int electionScore;
  int rssi; // dBm
  int lastSeenMs; // Epoch milliseconds
  bool isLeader;
  bool hasInternet;

  PeerInfo({
    required this.deviceId,
    required this.deviceShortId,
    this.electionScore = 0,
    this.rssi = -100,
    required this.lastSeenMs,
    this.isLeader = false,
    this.hasInternet = false,
  });

  bool get isAlive =>
      DateTime.now().millisecondsSinceEpoch - lastSeenMs < kPeerTimeoutMs;

  @override
  String toString() =>
      'PeerInfo(id=$deviceId, score=$electionScore, rssi=$rssi, leader=$isLeader)';
}

// ─────────────────────────────────────────────────────────────────────────────
// PeerRegistry
// ─────────────────────────────────────────────────────────────────────────────

class PeerRegistry {
  /// All known peers keyed by their full device ID string.
  final Map<String, PeerInfo> _peers = {};

  /// Registered change callbacks.
  final List<PeerChangeCallback> _listeners = [];

  // ─── Mutation ─────────────────────────────────────────────────────────────

  /// Registers or updates a peer. Returns whether this is a NEW peer (true)
  /// or an update to an existing one (false).
  bool upsert(PeerInfo updated) {
    final isNew = !_peers.containsKey(updated.deviceId);
    _peers[updated.deviceId] = updated;
    if (isNew) {
      _notify(updated, true);
    }
    return isNew;
  }

  /// Called when a BLE scan returns a device; updates RSSI and last-seen time.
  void touchPeer({
    required String deviceId,
    required int deviceShortId,
    required int rssi,
  }) {
    final now = DateTime.now().millisecondsSinceEpoch;
    final existing = _peers[deviceId];
    if (existing != null) {
      existing.rssi = rssi;
      existing.lastSeenMs = now;
    } else {
      upsert(PeerInfo(
        deviceId: deviceId,
        deviceShortId: deviceShortId,
        rssi: rssi,
        lastSeenMs: now,
      ));
    }
  }

  /// Updates a peer's election score (received via [BleElectionBidPacket]).
  void updateScore(String deviceId, int score) {
    final peer = _peers[deviceId];
    if (peer != null) {
      peer.electionScore = score;
    }
  }

  /// Sets the leader flag: clears all existing leader flags first.
  void setLeader(String deviceId) {
    for (final p in _peers.values) {
      p.isLeader = p.deviceId == deviceId;
    }
  }

  // ─── Eviction ─────────────────────────────────────────────────────────────

  /// Removes peers that have not been seen for [kPeerTimeoutMs].
  /// Returns the list of removed peers (used to trigger UI events).
  List<PeerInfo> evictStale() {
    final stale = _peers.values.where((p) => !p.isAlive).toList();
    for (final p in stale) {
      _peers.remove(p.deviceId);
      _notify(p, false);
    }
    return stale;
  }

  // ─── Queries ──────────────────────────────────────────────────────────────

  /// All currently alive peers (not timed out).
  List<PeerInfo> get alivePeers =>
      _peers.values.where((p) => p.isAlive).toList();

  /// Number of alive peers.
  int get aliveCount => alivePeers.length;

  /// The peer with the highest election score among alive peers, or null.
  PeerInfo? get highestScoredPeer {
    final alive = alivePeers;
    if (alive.isEmpty) return null;
    alive.sort((a, b) => b.electionScore.compareTo(a.electionScore));
    return alive.first;
  }

  /// Returns a peer by device ID, or null.
  PeerInfo? getPeer(String deviceId) => _peers[deviceId];

  /// Returns up to [count] random alive peers, excluding [excludeId].
  /// Used by the Gossip engine to select relay targets.
  List<PeerInfo> randomSubset({required int count, String? excludeId}) {
    final candidates = alivePeers
        .where((p) => p.deviceId != excludeId)
        .toList()
      ..shuffle();
    return candidates.take(count).toList();
  }

  // ─── Listeners ────────────────────────────────────────────────────────────

  void addListener(PeerChangeCallback cb) => _listeners.add(cb);
  void removeListener(PeerChangeCallback cb) => _listeners.remove(cb);

  void _notify(PeerInfo peer, bool isOnline) {
    for (final cb in _listeners) {
      cb(peer, isOnline);
    }
  }
}

