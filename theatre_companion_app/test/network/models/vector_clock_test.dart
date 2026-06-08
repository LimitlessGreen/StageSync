/// vector_clock_test.dart
/// ──────────────────────
/// Vollständige Unit-Tests für [VectorClock].
/// Rein logisch – keine Plattform-Abhängigkeiten.
import 'package:flutter_test/flutter_test.dart';
import 'package:theatre_companion_app/network/models/vector_clock.dart';

void main() {
  group('VectorClock.zero', () {
    test('ist leer', () {
      expect(VectorClock.zero.size, 0);
      expect(VectorClock.zero.entries, isEmpty);
    });

    test('equals sich selbst', () {
      expect(VectorClock.zero, VectorClock.zero);
    });
  });

  group('VectorClock.increment', () {
    test('first increment setzt counter auf 1', () {
      final c = VectorClock.zero.increment('A');
      expect(c.entries['A'], 1);
    });

    test('wiederholtes increment addiert korrekt', () {
      final c = VectorClock.zero.increment('A').increment('A').increment('A');
      expect(c.entries['A'], 3);
    });

    test('verschiedene Geräte bleiben unabhängig', () {
      final c = VectorClock.zero.increment('A').increment('B').increment('A');
      expect(c.entries['A'], 2);
      expect(c.entries['B'], 1);
    });

    test('increment gibt NEUE Instanz zurück (Immutabilität)', () {
      final c0 = VectorClock.zero;
      final c1 = c0.increment('A');
      expect(c0.size, 0); // Original unverändert
      expect(c1.size, 1);
    });
  });

  group('VectorClock.merge', () {
    test('merge gibt komponentenweises Maximum zurück', () {
      final a = VectorClock.zero.increment('A').increment('A'); // A=2
      final b = VectorClock.zero.increment('A').increment('B'); // A=1 B=1
      final m = a.merge(b);
      expect(m.entries['A'], 2); // max(2,1)
      expect(m.entries['B'], 1); // max(0,1)
    });

    test('merge ist kommutativ', () {
      final a = VectorClock.zero.increment('A').increment('C');
      final b = VectorClock.zero.increment('B').increment('C').increment('C');
      expect(a.merge(b), b.merge(a));
    });

    test('merge mit zero ergibt selbst', () {
      final c = VectorClock.zero.increment('X').increment('Y');
      expect(c.merge(VectorClock.zero), c);
      expect(VectorClock.zero.merge(c), c);
    });
  });

  group('VectorClock.happensBefore', () {
    test('zero happensBefore increment(A)', () {
      final c = VectorClock.zero.increment('A');
      expect(VectorClock.zero.happensBefore(c), isTrue);
      expect(c.happensBefore(VectorClock.zero), isFalse);
    });

    test('A<B<C ist korrekte kausal-Reihenfolge', () {
      final a = VectorClock.zero.increment('dev');
      final b = a.increment('dev');
      final c = b.increment('dev');
      expect(a.happensBefore(b), isTrue);
      expect(b.happensBefore(c), isTrue);
      expect(a.happensBefore(c), isTrue);
      expect(c.happensBefore(a), isFalse);
    });

    test('gleiche Clocks: nicht happensBefore', () {
      final c = VectorClock.zero.increment('A');
      expect(c.happensBefore(c), isFalse);
    });

    test('concurrent clocks: weder happensBefore noch umgekehrt', () {
      final a = VectorClock.zero.increment('Alice');
      final b = VectorClock.zero.increment('Bob');
      expect(a.happensBefore(b), isFalse);
      expect(b.happensBefore(a), isFalse);
    });
  });

  group('VectorClock.isConcurrentWith', () {
    test('gleichzeitige unabhängige Änderungen sind concurrent', () {
      final a = VectorClock.zero.increment('Alice');
      final b = VectorClock.zero.increment('Bob');
      expect(a.isConcurrentWith(b), isTrue);
    });

    test('kausale Reihenfolge ist NICHT concurrent', () {
      final a = VectorClock.zero.increment('A');
      final b = a.increment('A');
      expect(a.isConcurrentWith(b), isFalse);
      expect(b.isConcurrentWith(a), isFalse);
    });

    test('identische Clocks sind NICHT concurrent', () {
      final c = VectorClock.zero.increment('X');
      expect(c.isConcurrentWith(c), isFalse);
    });
  });

  group('VectorClock Serialisierung', () {
    test('toJson / fromJson Roundtrip', () {
      final c = VectorClock.zero
          .increment('device-1')
          .increment('device-2')
          .increment('device-1');
      final json = c.toJson();
      final restored = VectorClock.fromJson(json);
      expect(restored, c);
    });

    test('toJsonString / fromJsonString Roundtrip', () {
      final c = VectorClock.zero.increment('x').increment('y').increment('x');
      final s = c.toJsonString();
      final r = VectorClock.fromJsonString(s);
      expect(r, c);
    });

    test('zero Roundtrip', () {
      expect(
        VectorClock.fromJson(VectorClock.zero.toJson()),
        VectorClock.zero,
      );
    });
  });

  group('VectorClock Gleichheit', () {
    test('gleiche Einträge sind equal', () {
      final a = VectorClock.zero.increment('A').increment('B');
      final b = VectorClock.zero.increment('B').increment('A');
      expect(a, b);
      expect(a.hashCode, b.hashCode);
    });

    test('unterschiedliche Counts sind unequal', () {
      final a = VectorClock.zero.increment('A');
      final b = VectorClock.zero.increment('A').increment('A');
      expect(a, isNot(b));
    });

    test('unterschiedliche Keys sind unequal', () {
      final a = VectorClock.zero.increment('A');
      final b = VectorClock.zero.increment('B');
      expect(a, isNot(b));
    });
  });
}
