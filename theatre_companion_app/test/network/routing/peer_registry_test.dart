import 'package:flutter_test/flutter_test.dart';
import 'package:theatre_companion_app/network/routing/peer_registry.dart';

PeerInfo makePeer(String id, {int shortId = 1, int rssi = -70}) => PeerInfo(
    deviceId: id,
    deviceShortId: shortId,
    rssi: rssi,
    lastSeenMs: DateTime.now().millisecondsSinceEpoch);
void main() {
  late PeerRegistry reg;
  setUp(() => reg = PeerRegistry());
  group('PeerRegistry.touchPeer', () {
    test('neuer Peer wird hinzugefuegt', () {
      reg.touchPeer(deviceId: 'dev-A', deviceShortId: 1, rssi: -60);
      expect(reg.aliveCount, 1);
    });
    test('bestehender Peer wird aktualisiert (nicht dupliziert)', () {
      reg.touchPeer(deviceId: 'dev-A', deviceShortId: 1, rssi: -60);
      reg.touchPeer(deviceId: 'dev-A', deviceShortId: 1, rssi: -50);
      expect(reg.aliveCount, 1);
      expect(reg.getPeer('dev-A')!.rssi, -50);
    });
    test('neuer Peer loest PeerChangeCallback aus', () {
      bool called = false;
      reg.addListener((peer, isOnline) {
        called = true;
        expect(isOnline, isTrue);
      });
      reg.touchPeer(deviceId: 'dev-B', deviceShortId: 2, rssi: -70);
      expect(called, isTrue);
    });
  });
  group('PeerRegistry.updateScore', () {
    test('score wird aktualisiert', () {
      reg.touchPeer(deviceId: 'dev-A', deviceShortId: 1, rssi: -70);
      reg.updateScore('dev-A', 250);
      expect(reg.getPeer('dev-A')!.electionScore, 250);
    });
    test('unbekannter Peer wird ignoriert', () {
      expect(() => reg.updateScore('unbekannt', 100), returnsNormally);
    });
  });
  group('PeerRegistry.setLeader', () {
    test('Leader-Flag wird korrekt gesetzt', () {
      reg.touchPeer(deviceId: 'dev-A', deviceShortId: 1, rssi: -70);
      reg.touchPeer(deviceId: 'dev-B', deviceShortId: 2, rssi: -70);
      reg.setLeader('dev-A');
      expect(reg.getPeer('dev-A')!.isLeader, isTrue);
      expect(reg.getPeer('dev-B')!.isLeader, isFalse);
    });
    test('Leader wechselt: alter Leader-Flag wird geloescht', () {
      reg.touchPeer(deviceId: 'dev-A', deviceShortId: 1, rssi: -70);
      reg.touchPeer(deviceId: 'dev-B', deviceShortId: 2, rssi: -70);
      reg.setLeader('dev-A');
      reg.setLeader('dev-B');
      expect(reg.getPeer('dev-A')!.isLeader, isFalse);
      expect(reg.getPeer('dev-B')!.isLeader, isTrue);
    });
  });
  group('PeerRegistry.evictStale', () {
    test('abgelaufene Peers werden entfernt', () {
      // Peer mit lastSeenMs in der Vergangenheit (> kPeerTimeoutMs)
      final stale = PeerInfo(
        deviceId: 'old-dev',
        deviceShortId: 99,
        lastSeenMs:
            DateTime.now().millisecondsSinceEpoch - kPeerTimeoutMs - 1000,
      );
      reg.upsert(stale);
      reg.touchPeer(deviceId: 'fresh-dev', deviceShortId: 1, rssi: -60);
      final evicted = reg.evictStale();
      expect(evicted.length, 1);
      expect(evicted.first.deviceId, 'old-dev');
      expect(reg.aliveCount, 1);
    });
    test('Eviction loest PeerChangeCallback mit isOnline=false aus', () {
      final calls = <bool>[];
      reg.addListener((_, isOnline) => calls.add(isOnline));
      final stale = PeerInfo(
        deviceId: 'stale',
        deviceShortId: 5,
        lastSeenMs: DateTime.now().millisecondsSinceEpoch - kPeerTimeoutMs - 1,
      );
      reg.upsert(stale);
      calls.clear(); // upsert callback ignorieren
      reg.evictStale();
      expect(calls, contains(false));
    });
  });
  group('PeerRegistry.randomSubset', () {
    test('liefert maximal count Elemente', () {
      for (var i = 0; i < 10; i++) {
        reg.touchPeer(deviceId: 'dev-$i', deviceShortId: i, rssi: -70);
      }
      final subset = reg.randomSubset(count: 3);
      expect(subset.length, 3);
    });
    test('schliesst excludeId korrekt aus', () {
      reg.touchPeer(deviceId: 'dev-A', deviceShortId: 1, rssi: -70);
      reg.touchPeer(deviceId: 'dev-B', deviceShortId: 2, rssi: -70);
      reg.touchPeer(deviceId: 'dev-C', deviceShortId: 3, rssi: -70);
      final subset = reg.randomSubset(count: 10, excludeId: 'dev-A');
      expect(subset.map((p) => p.deviceId), isNot(contains('dev-A')));
    });
    test('leer wenn keine alive peers', () {
      expect(reg.randomSubset(count: 3), isEmpty);
    });
  });
  group('PeerRegistry.highestScoredPeer', () {
    test('liefert Peer mit hoechstem Score', () {
      reg.touchPeer(deviceId: 'low', deviceShortId: 1, rssi: -70);
      reg.touchPeer(deviceId: 'high', deviceShortId: 2, rssi: -70);
      reg.updateScore('low', 50);
      reg.updateScore('high', 200);
      expect(reg.highestScoredPeer!.deviceId, 'high');
    });
    test('null wenn keine Peers', () => expect(reg.highestScoredPeer, isNull));
  });
}
