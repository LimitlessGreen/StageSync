/// leader_election_engine.dart
/// ────────────────────────────
/// Implements the **Score-Based Leader Election** algorithm for StageSync.
///
/// ## Scoring Formula
///   Score = (hasWlanOrLte * 100)
///           + (isChargingOrFull * 50)
///           + batteryPercent           ← 0-100
///           - (isMoving * 20)
///
/// ## Election Lifecycle
///   1. On startup / peer topology change: [startElectionRound] is called.
///   2. This device broadcasts a [BleElectionBidPacket] with its local score.
///   3. [onBidReceived] collects scores from peers for [kBiddingWindowMs].
///   4. After the window, [_concludeElection] picks the peer with the highest
///      score (including this device's own score).
///   5. If this device wins, [_becomeLeader] starts the heartbeat timer.
///   6. If this device loses, [_becomeFollower] starts the watchdog timer.
///
/// ## Heartbeat (Leader only)
///   * Timer fires every [kHeartbeatIntervalMs] = 1000 ms.
///   * Broadcasts a [BleHeartbeatPacket] via BLE Mesh.
///
/// ## Watchdog (Follower only)
///   * Timer is reset on every received heartbeat from the known leader.
///   * If no heartbeat arrives within [kLeaderDeadTimeoutMs] = 4000 ms,
///     the leader is declared dead and a new election round starts immediately.
library leader_election_engine;

import 'dart:async';
import 'dart:math' show sqrt;

import 'package:battery_plus/battery_plus.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart' show kIsWeb, TargetPlatform, defaultTargetPlatform;
import 'package:sensors_plus/sensors_plus.dart';

import '../models/ble_packet.dart';
import '../isolate/isolate_messages.dart' show NetworkScoreBreakdown;
import 'peer_registry.dart';

/// Interval at which the leader sends heartbeat packets (ms).
const int kHeartbeatIntervalMs = 1000;

/// Duration (ms) without a heartbeat before followers declare leader dead.
const int kLeaderDeadTimeoutMs = 4000;

/// Duration (ms) of the bidding window during which election bids are collected.
const int kBiddingWindowMs = 1500;

/// Accelerometer magnitude threshold above which the device is "moving" (m/s²).
const double kMovementThreshold = 2.5;

// ─────────────────────────────────────────────────────────────────────────────

/// Callback type: called when this device should broadcast a BLE packet.
typedef BroadcastCallback = Future<void> Function(Object packet);

/// Callback type: called whenever leadership status changes.
typedef LeadershipChangedCallback = void Function({
  required String newLeaderId,
  required bool isThisDeviceLeader,
  required int winningScore,
});

// ─────────────────────────────────────────────────────────────────────────────

class LeaderElectionEngine {
  final PeerRegistry _peers;
  final String _localDeviceId;
  final int _localDeviceShortId;
  final BroadcastCallback _broadcast;
  final LeadershipChangedCallback _onLeadershipChanged;

  // Platform plugins (battery, connectivity, sensors)
  final Battery _battery = Battery();
  final Connectivity _connectivity = Connectivity();

  // Timers
  Timer? _heartbeatTimer;
  Timer? _watchdogTimer;
  Timer? _electionWindowTimer;

  // State
  bool _isLeader = false;
  String? _currentLeaderId;
  int _heartbeatSeqNum = 0;

  // Motion detection
  double _currentAccelMagnitude = 0.0;
  StreamSubscription<UserAccelerometerEvent>? _accelSub;

  // Bids collected during the current election window
  final Map<String, int> _collectedBids = {};

  LeaderElectionEngine({
    required PeerRegistry peers,
    required String localDeviceId,
    required int localDeviceShortId,
    required BroadcastCallback broadcast,
    required LeadershipChangedCallback onLeadershipChanged,
  })  : _peers = peers,
        _localDeviceId = localDeviceId,
        _localDeviceShortId = localDeviceShortId,
        _broadcast = broadcast,
        _onLeadershipChanged = onLeadershipChanged;

  // ─── Lifecycle ────────────────────────────────────────────────────────────

  /// Initialise the engine: begin listening to the accelerometer.
  Future<void> start() async {
    // sensors_plus unterstützt nur Android/iOS/Web.
    // Auf Windows/macOS/Linux wirft userAccelerometerEventStream eine
    // MissingPluginException – diese wird ASYNCHRON geworfen (beim Aktivieren
    // des Platform-Channels), daher reicht ein synchrones try-catch allein nicht.
    // Lösung: Plattform-Guard + runZonedGuarded als doppelte Absicherung.
    final bool sensorsSupported = kIsWeb || _isMobilePlatform();
    if (sensorsSupported) {
      runZonedGuarded(() {
        _accelSub = userAccelerometerEventStream(
          samplingPeriod: SensorInterval.normalInterval,
        ).listen(
          _onAccelEvent,
          onError: (_) {/* Sensor-Fehler → stationary */},
          cancelOnError: false,
        );
      }, (_, __) {
        // MissingPluginException oder ähnliches – Sensor nicht verfügbar.
        // _currentAccelMagnitude bleibt 0.0 → kein isMoving-Malus.
      });
    }
    // Auf Desktop (Windows/macOS/Linux) wird der Block übersprungen.

    // Trigger first election after a brief startup delay.
    Timer(const Duration(milliseconds: 500), startElectionRound);
  }

  /// Release all resources – call when the network isolate is shutting down.
  Future<void> stop() async {
    _heartbeatTimer?.cancel();
    _watchdogTimer?.cancel();
    _electionWindowTimer?.cancel();
    await _accelSub?.cancel();
  }

  // ─── Public API ───────────────────────────────────────────────────────────

  bool get isLeader => _isLeader;
  String? get currentLeaderId => _currentLeaderId;

  /// Computes and returns the local election score using the formula:
  ///   Score = (hasNet*100) + (charging*50) + battery - (moving*20)
  Future<int> computeLocalScore() async {
    final b = await computeScoreBreakdown();
    return b.total;
  }

  /// Same computation but returns the full [NetworkScoreBreakdown] for the UI.
  Future<NetworkScoreBreakdown> computeScoreBreakdown() async {
    int battery = 50;
    bool isCharging = false;
    try {
      battery = await _battery.batteryLevel;
      final state = await _battery.batteryState;
      isCharging = state == BatteryState.charging || state == BatteryState.full;
    } catch (_) {}

    bool hasNet = false;
    try {
      final results = await _connectivity.checkConnectivity();
      hasNet = results.any((r) =>
          r == ConnectivityResult.wifi || r == ConnectivityResult.mobile);
    } catch (_) {}

    final isMoving = _currentAccelMagnitude > kMovementThreshold;
    final total = (hasNet ? 100 : 0) +
        (isCharging ? 50 : 0) +
        battery -
        (isMoving ? 20 : 0);

    return NetworkScoreBreakdown(
      hasNetwork: hasNet,
      isCharging: isCharging,
      batteryPercent: battery,
      isMoving: isMoving,
      total: total,
    );
  }

  /// Kicks off a new election round:
  ///   1. Compute own score.
  ///   2. Broadcast a BleElectionBidPacket.
  ///   3. Start collecting bids from peers for [kBiddingWindowMs].
  ///   4. After window: conclude election.
  Future<void> startElectionRound() async {
    // Cancel any ongoing window timer.
    _electionWindowTimer?.cancel();
    _collectedBids.clear();

    final score = await computeLocalScore();
    _collectedBids[_localDeviceId] = score;

    // Broadcast our bid.
    final bid = BleElectionBidPacket.create(
      sourceDeviceShortId: _localDeviceShortId,
      score: score,
    );
    await _broadcast(bid);

    // Wait for peers to respond.
    _electionWindowTimer =
        Timer(Duration(milliseconds: kBiddingWindowMs), _concludeElection);
  }

  /// Called by [NetworkRepositoryWeaver] when an [BleElectionBidPacket] is
  /// received from a peer on the mesh.
  void onBidReceived(String senderDeviceId, int score) {
    _collectedBids[senderDeviceId] = score;
    // Update the peer registry so the registry always reflects latest scores.
    _peers.updateScore(senderDeviceId, score);
  }

  /// Called by [NetworkRepositoryWeaver] when a [BleHeartbeatPacket] is
  /// received from the current leader. Resets the watchdog timer.
  void onHeartbeatReceived(String senderDeviceId) {
    if (_currentLeaderId != null && senderDeviceId == _currentLeaderId) {
      _resetWatchdog();
    }
  }

  // ─── Private – election conclusion ────────────────────────────────────────

  void _concludeElection() {
    if (_collectedBids.isEmpty) return;

    // Find the device with the highest score.
    // Tiebreaker: lexicographically larger device ID wins (deterministic).
    String winnerId = _localDeviceId;
    int winnerScore = _collectedBids[_localDeviceId] ?? 0;

    _collectedBids.forEach((deviceId, score) {
      if (score > winnerScore ||
          (score == winnerScore && deviceId.compareTo(winnerId) > 0)) {
        winnerId = deviceId;
        winnerScore = score;
      }
    });

    _currentLeaderId = winnerId;
    _peers.setLeader(winnerId);
    _isLeader = winnerId == _localDeviceId;

    _onLeadershipChanged(
      newLeaderId: winnerId,
      isThisDeviceLeader: _isLeader,
      winningScore: winnerScore,
    );

    if (_isLeader) {
      _becomeLeader();
    } else {
      _becomeFollower();
    }
  }

  // ─── Private – leader role ────────────────────────────────────────────────

  void _becomeLeader() {
    _watchdogTimer?.cancel();

    // Send heartbeats every 1000 ms.
    _heartbeatTimer?.cancel();
    _heartbeatTimer = Timer.periodic(
      Duration(milliseconds: kHeartbeatIntervalMs),
      (_) => _sendHeartbeat(),
    );
  }

  void _sendHeartbeat() {
    _heartbeatSeqNum = (_heartbeatSeqNum + 1) & 0xFF;
    final hb = BleHeartbeatPacket.create(
      sourceDeviceShortId: _localDeviceShortId,
      sequenceNum: _heartbeatSeqNum,
    );
    _broadcast(hb); // fire-and-forget; failures are non-critical for heartbeats
  }

  // ─── Private – follower role ──────────────────────────────────────────────

  void _becomeFollower() {
    _heartbeatTimer?.cancel();
    _resetWatchdog();
  }

  void _resetWatchdog() {
    _watchdogTimer?.cancel();
    _watchdogTimer = Timer(
      Duration(milliseconds: kLeaderDeadTimeoutMs),
      _onLeaderDeadTimeout,
    );
  }

  void _onLeaderDeadTimeout() {
    // No heartbeat for 4 seconds → leader is dead.
    final oldLeader = _currentLeaderId;
    _currentLeaderId = null;

    // Remove the dead leader from the peer registry so it no longer
    // participates in score comparisons.
    if (oldLeader != null) {
      // Notify via registry (score reset to 0 signals dead leader).
      _peers.updateScore(oldLeader, 0);
    }

    // Immediately start a fresh election round.
    startElectionRound();
  }

  // ─── Private – motion detection ──────────────────────────────────────────

  void _onAccelEvent(UserAccelerometerEvent event) {
    _currentAccelMagnitude =
        sqrt(event.x * event.x + event.y * event.y + event.z * event.z);
  }
}

/// Gibt `true` zurück, wenn sensors_plus auf dieser Plattform unterstützt wird.
/// sensors_plus unterstützt: Android, iOS, Web.
/// Nicht unterstützt: Windows, macOS, Linux.
bool _isMobilePlatform() {
  return defaultTargetPlatform == TargetPlatform.android ||
      defaultTargetPlatform == TargetPlatform.iOS;
}



