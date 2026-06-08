/// leader_election_engine_test.dart
/// ────────────────────────────────────
/// Unit-Tests fuer den LeaderElectionEngine.
///
/// Da Battery, Connectivity und Sensors Platform-Plugins sind, die in
/// Unit-Tests nicht verfuegbar sind, wird eine TestableLeaderEngine
/// verwendet, die computeLocalScore() ueberschreibt.
///
/// Getestete Verhalten:
///   1. onBidReceived aktualisiert PeerRegistry-Score.
///   2. Hoehere Score gewinnt die Wahl.
///   3. Tiebreaker: lexikografisch groessere Device-ID gewinnt.
///   4. onHeartbeatReceived setzt Watchdog nur fuer bekannten Leader zurueck.
///   5. startElectionRound broadcastet ein Bid-Paket.
library leader_election_engine_test;

import 'dart:async';
import 'package:fake_async/fake_async.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:theatre_companion_app/network/isolate/isolate_messages.dart';
import 'package:theatre_companion_app/network/models/ble_packet.dart';
import 'package:theatre_companion_app/network/routing/leader_election_engine.dart';
import 'package:theatre_companion_app/network/routing/peer_registry.dart';

// ─── Testfaehige Unterklasse ──────────────────────────────────────────────────
/// Ueberschreibt computeLocalScore(), damit keine Platform-Plugins benoetigt
/// werden. Statt Battery/Connectivity gibt diese Klasse einen fixen Score
/// zurueck, den der Test kontrollieren kann.
class TestableLeaderEngine extends LeaderElectionEngine {
  final int fixedScore;
  TestableLeaderEngine({
    required super.peers,
    required super.localDeviceId,
    required super.localDeviceShortId,
    required super.broadcast,
    required super.onLeadershipChanged,
    this.fixedScore = 100,
  });
  @override
  Future<int> computeLocalScore() async => fixedScore;
  @override
  Future<NetworkScoreBreakdown> computeScoreBreakdown() async =>
      NetworkScoreBreakdown(
        hasNetwork: fixedScore >= 100,
        isCharging: fixedScore >= 50,
        batteryPercent: fixedScore.clamp(0, 100),
        isMoving: false,
        total: fixedScore,
      );
}

// ─────────────────────────────────────────────────────────────────────────────
void main() {
  late PeerRegistry peers;
  late List<Object> broadcastedPackets;
  late List<({String leader, bool isThisDevice, int score})> leadershipEvents;
  // Erstellt eine Engine mit konfigurierbarem lokalen Score
  TestableLeaderEngine makeEngine({
    String localId = 'local-device-aaa',
    int localShortId = 0xAAAA,
    int fixedScore = 100,
  }) {
    return TestableLeaderEngine(
      peers: peers,
      localDeviceId: localId,
      localDeviceShortId: localShortId,
      fixedScore: fixedScore,
      broadcast: (packet) async {
        broadcastedPackets.add(packet);
      },
      onLeadershipChanged: ({
        required newLeaderId,
        required isThisDeviceLeader,
        required winningScore,
      }) {
        leadershipEvents.add((
          leader: newLeaderId,
          isThisDevice: isThisDeviceLeader,
          score: winningScore,
        ));
      },
    );
  }

  setUp(() {
    peers = PeerRegistry();
    broadcastedPackets = [];
    leadershipEvents = [];
  });
  // ─── onBidReceived ────────────────────────────────────────────────────────
  group('onBidReceived', () {
    test('aktualisiert Score des Peers in der PeerRegistry', () {
      final engine = makeEngine();
      peers.touchPeer(deviceId: 'peer-1', deviceShortId: 1, rssi: -60);
      engine.onBidReceived('peer-1', 150);
      expect(peers.getPeer('peer-1')?.electionScore, equals(150));
    });
    test('ignoriert unbekannte Peers gracefully (kein Crash)', () {
      final engine = makeEngine();
      // Peer nicht registriert - darf keinen Fehler werfen
      expect(() => engine.onBidReceived('unknown-peer', 99), returnsNormally);
    });
  });
  // ─── onHeartbeatReceived ──────────────────────────────────────────────────
  group('onHeartbeatReceived', () {
    test('akzeptiert Heartbeat vom bekannten Leader', () async {
      fakeAsync((async) {
        final engine = makeEngine(fixedScore: 100);
        // Starte eine Wahl: lokales Geraet gewinnt (Score 100, kein Konkurrent)
        unawaited(engine.startElectionRound());
        async.flushMicrotasks();
        async.elapse(Duration(milliseconds: kBiddingWindowMs + 50));
        async.flushMicrotasks();
        // Geraet ist jetzt Leader
        expect(engine.isLeader, isTrue);
        expect(engine.currentLeaderId, equals('local-device-aaa'));
        // Heartbeat vom Leader selbst – darf keinen Fehler werfen
        expect(
          () => engine.onHeartbeatReceived('local-device-aaa'),
          returnsNormally,
        );
      });
    });
    test('ignoriert Heartbeat von unbekannten Peers (kein Crash)', () {
      final engine = makeEngine();
      expect(
        () => engine.onHeartbeatReceived('unknown-peer'),
        returnsNormally,
      );
    });
  });
  // ─── startElectionRound – Broadcast ───────────────────────────────────────
  group('startElectionRound', () {
    test('broadcastet ein BleElectionBidPacket', () async {
      final engine = makeEngine(fixedScore: 80);
      await engine.startElectionRound();
      // Muss mindestens 1 Paket gesendet haben
      expect(broadcastedPackets, isNotEmpty);
      expect(broadcastedPackets.first, isA<BleElectionBidPacket>());
      final bid = broadcastedPackets.first as BleElectionBidPacket;
      expect(bid.score, equals(80));
    });
  });
  // ─── Wahlergebnis ─────────────────────────────────────────────────────────
  group('Wahlergebnis', () {
    test('lokales Geraet gewinnt wenn kein Konkurrent bietet', () {
      fakeAsync((async) {
        final engine = makeEngine(localId: 'local-aaa', fixedScore: 100);
        unawaited(engine.startElectionRound());
        async.flushMicrotasks();
        async.elapse(Duration(milliseconds: kBiddingWindowMs + 100));
        async.flushMicrotasks();
        expect(leadershipEvents, isNotEmpty);
        final event = leadershipEvents.first;
        expect(event.leader, equals('local-aaa'));
        expect(event.isThisDevice, isTrue);
        expect(event.score, equals(100));
        expect(engine.isLeader, isTrue);
      });
    });
    test('Peer mit hoeherem Score gewinnt die Wahl', () {
      fakeAsync((async) {
        final engine = makeEngine(localId: 'local-aaa', fixedScore: 80);
        peers.touchPeer(deviceId: 'peer-bbb', deviceShortId: 2, rssi: -60);
        unawaited(engine.startElectionRound());
        async.flushMicrotasks();
        // Peer reicht ein Gebot mit Score 200 ein
        engine.onBidReceived('peer-bbb', 200);
        async.elapse(Duration(milliseconds: kBiddingWindowMs + 100));
        async.flushMicrotasks();
        expect(leadershipEvents, isNotEmpty);
        final event = leadershipEvents.first;
        expect(event.leader, equals('peer-bbb'));
        expect(event.isThisDevice, isFalse);
        expect(event.score, equals(200));
        expect(engine.isLeader, isFalse);
      });
    });
    test('Tiebreaker: lexikografisch groessere Device-ID gewinnt', () {
      fakeAsync((async) {
        // 'zzz' > 'aaa' lexikografisch
        final engine = makeEngine(localId: 'device-aaa', fixedScore: 100);
        peers.touchPeer(deviceId: 'device-zzz', deviceShortId: 9, rssi: -50);
        unawaited(engine.startElectionRound());
        async.flushMicrotasks();
        // Gleicher Score wie lokal
        engine.onBidReceived('device-zzz', 100);
        async.elapse(Duration(milliseconds: kBiddingWindowMs + 100));
        async.flushMicrotasks();
        expect(leadershipEvents, isNotEmpty);
        // 'device-zzz' gewinnt Tiebreaker
        expect(leadershipEvents.first.leader, equals('device-zzz'));
        expect(leadershipEvents.first.isThisDevice, isFalse);
      });
    });
    test('lokales Geraet gewinnt Tiebreaker wenn ID lexikografisch groesser',
        () {
      fakeAsync((async) {
        // 'zzz' > 'aaa' lexikografisch → lokal gewinnt
        final engine = makeEngine(localId: 'device-zzz', fixedScore: 100);
        peers.touchPeer(deviceId: 'device-aaa', deviceShortId: 1, rssi: -50);
        unawaited(engine.startElectionRound());
        async.flushMicrotasks();
        engine.onBidReceived('device-aaa', 100);
        async.elapse(Duration(milliseconds: kBiddingWindowMs + 100));
        async.flushMicrotasks();
        expect(leadershipEvents.first.leader, equals('device-zzz'));
        expect(leadershipEvents.first.isThisDevice, isTrue);
      });
    });
  });
  // ─── Watchdog ─────────────────────────────────────────────────────────────
  group('Watchdog', () {
    test('Watchdog-Timeout loest neue Wahl aus', () {
      fakeAsync((async) {
        // Zwei Engines simulieren: Engine A wird Follower
        final engineA = makeEngine(localId: 'device-aaa', fixedScore: 50);
        peers.touchPeer(deviceId: 'device-zzz', deviceShortId: 9, rssi: -50);
        // Starte Wahl: peer-zzz gewinnt mit Score 200
        unawaited(engineA.startElectionRound());
        async.flushMicrotasks();
        engineA.onBidReceived('device-zzz', 200);
        async.elapse(Duration(milliseconds: kBiddingWindowMs + 100));
        async.flushMicrotasks();
        // engineA ist Follower
        expect(engineA.isLeader, isFalse);
        // Anzahl der Events vor dem Watchdog-Timeout
        // Lass den Watchdog ablaufen (kein Heartbeat empfangen)
        async.elapse(Duration(milliseconds: kLeaderDeadTimeoutMs + 200));
        async.flushMicrotasks();
        // Eine neue Wahl muss ausgeloest worden sein
        // (broadcastedPackets enthaelt einen neuen Bid)
        expect(broadcastedPackets.length, greaterThan(1));
      });
    });
    test('Heartbeat setzt Watchdog zurueck (kein fruehzeitiger Timeout)', () {
      fakeAsync((async) {
        final engine = makeEngine(localId: 'device-aaa', fixedScore: 50);
        peers.touchPeer(deviceId: 'device-zzz', deviceShortId: 9, rssi: -50);
        unawaited(engine.startElectionRound());
        async.flushMicrotasks();
        engine.onBidReceived('device-zzz', 200);
        async.elapse(Duration(milliseconds: kBiddingWindowMs + 100));
        async.flushMicrotasks();
        final eventCountAfterElection = leadershipEvents.length;
        // Sende Heartbeats alle 1000ms (vor dem 4000ms-Timeout)
        for (int i = 0; i < 5; i++) {
          async.elapse(Duration(milliseconds: 900));
          async.flushMicrotasks();
          engine.onHeartbeatReceived('device-zzz');
        }
        // Keine neue Wahl sollte ausgeloest worden sein
        // (leadershipEvents darf sich nicht veraendert haben)
        expect(leadershipEvents.length, equals(eventCountAfterElection));
      });
    });
  });
  // ─── stop() ───────────────────────────────────────────────────────────────
  group('stop()', () {
    test('stop() gibt Ressourcen frei ohne Fehler', () async {
      final engine = makeEngine();
      // start() wuerde Accelerometer-Subscription starten; in Tests ueberspringen
      await engine.stop();
      // Kein Fehler = Test bestanden
    });
  });
}
