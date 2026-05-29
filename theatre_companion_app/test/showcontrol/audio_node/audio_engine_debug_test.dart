/// Standalone-Diagnose-Skript für Windows-Audio-Ausgabe.
///
/// VERWENDUNG (auf Windows im App-Verzeichnis):
///   flutter run -d windows --dart-define=AUDIO_DEBUG=1
///
/// Alternativ als normaler Dart-Test mit echter SoLoud-Instanz:
///   (nicht automatisierbar ohne Hardware – manuell starten)
///
/// Das Skript:
/// 1. Listet alle Windows-Ausgabegeräte auf
/// 2. Initialisiert SoLoud mit JEDEM Gerät der Reihe nach
/// 3. Spielt einen 440-Hz-Sinuston 1 Sekunde lang ab
/// 4. Gibt Diagnose-Info aus: Name, ID, isDefault, SoLoud-Status
///
/// Ermöglicht das Auffinden des Geräts, das SoLoud tatsächlich nutzt,
/// und ob der deinit+reinit-Zyklus zuverlässig funktioniert.
///
/// Dieser File ist KEIN automatisierter Test — er benötigt echte Hardware.

// ignore_for_file: avoid_print

import 'dart:async';
import 'dart:typed_data';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_soloud/flutter_soloud.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:theatre_companion_app/showcontrol/nodes/audio_node/audio_engine.dart';
import 'package:theatre_companion_app/showcontrol/nodes/audio_node/sweep_generator.dart';

// ── WAV-Hilfe ─────────────────────────────────────────────────────────────────

Uint8List _make1kHzTone({double durationSeconds = 1.0, double amplitudeDb = -6.0}) {
  final amplitude = math.pow(10.0, amplitudeDb / 20.0).toDouble();
  return SweepGenerator.generateTone(
    frequencyHz: 1000,
    durationSeconds: durationSeconds,
    amplitude: amplitude,
  );
}

// ── Diagnose-Funktionen ────────────────────────────────────────────────────────

/// Gibt alle verfügbaren SoLoud-Geräte aus ohne Engine zu initialisieren.
void _printDevices(SoLoud soloud) {
  print('\n════════════════════════════════════════════════');
  print('  SoLoud Playback Devices (Windows Enumeration)');
  print('════════════════════════════════════════════════');

  List<PlaybackDevice> devices;
  try {
    devices = soloud.listPlaybackDevices();
  } catch (e) {
    print('FEHLER beim Auflisten: $e');
    return;
  }

  if (devices.isEmpty) {
    print('⚠️  Keine Geräte gefunden!');
    return;
  }

  for (final d in devices) {
    final def = d.isDefault ? ' ← DEFAULT' : '';
    print('  [${d.id}] ${d.name}$def');
  }
  print('────────────────────────────────────────────────\n');
}

/// Testet ein einzelnes Gerät: init → play → verify → deinit.
/// Gibt detaillierten Bericht aus.
Future<bool> _testDevice(SoLoud soloud, PlaybackDevice device, {
  double durationSeconds = 1.0,
}) async {
  print('\n▶  Teste: [${device.id}] ${device.name}');

  // ── Schritt 1: Init ───────────────────────────────────────────────────────
  try {
    if (soloud.isInitialized) {
      print('   deinit (vorherige Session)...');
      soloud.deinit();
      await Future.delayed(const Duration(milliseconds: 120));
    }

    print('   init(device="${device.name}")...');
    await soloud.init(device: device, bufferSize: 1024);

    if (!soloud.isInitialized) {
      print('   ✗ init() abgeschlossen, aber isInitialized=false');
      return false;
    }
    print('   ✓ init OK');
  } catch (e) {
    print('   ✗ init FEHLER: $e');
    return false;
  }

  // ── Schritt 2: Ton laden ─────────────────────────────────────────────────
  AudioSource? source;
  try {
    final wav = _make1kHzTone(durationSeconds: durationSeconds);
    source = await soloud.loadMem('debug_tone', wav);
    print('   ✓ loadMem OK (${wav.length} Bytes)');
  } catch (e) {
    print('   ✗ loadMem FEHLER: $e');
    return false;
  }

  // ── Schritt 3: Abspielen ─────────────────────────────────────────────────
  SoundHandle? handle;
  try {
    handle = soloud.play(source, volume: 0.8);
    print('   ✓ play() gestartet — handle=$handle');
    print('     → Sollte jetzt aus [${device.name}] kommen...');
    print('     → Warte ${durationSeconds}s...');
    await Future.delayed(Duration(milliseconds: (durationSeconds * 1000).round()));
    print('   ✓ Wiedergabe beendet');
  } catch (e) {
    print('   ✗ play FEHLER: $e');
    return false;
  }

  // ── Schritt 4: Aufräumen ─────────────────────────────────────────────────
  try {
    if (handle != null && soloud.getIsValidVoiceHandle(handle)) {
      await soloud.stop(handle);
    }
    if (source != null) {
      await soloud.disposeSource(source);
    }
    print('   ✓ Aufräumen OK');
  } catch (e) {
    print('   ⚠ Aufräumen FEHLER: $e (nicht kritisch)');
  }

  return true;
}

/// Testet `changeDevice()` — HOT-Wechsel ohne deinit+reinit.
/// Kritisch: Prüft ob AudioSource nach Gerätewechsel noch gültig ist.
Future<void> _testChangeDevice(SoLoud soloud) async {
  print('\n════════════════════════════════════════════════');
  print('  Test: changeDevice() — HOT-Gerätewechsel');
  print('════════════════════════════════════════════════');

  final devices = soloud.listPlaybackDevices();
  if (devices.length < 2) {
    print('  ⚠ Weniger als 2 Geräte → Test übersprungen');
    return;
  }

  // Mit Gerät 0 initialisieren
  if (soloud.isInitialized) {
    soloud.deinit();
    await Future.delayed(const Duration(milliseconds: 100));
  }

  try {
    await soloud.init(device: devices[0], bufferSize: 1024);
    print('  ✓ init mit [${devices[0].id}] ${devices[0].name}');
  } catch (e) {
    print('  ✗ init fehlgeschlagen: $e');
    return;
  }

  // Ton vorladen
  final wav = _make1kHzTone(durationSeconds: 0.5);
  AudioSource? source;
  try {
    source = await soloud.loadMem('hot_swap_tone', wav);
    print('  ✓ Source geladen');
  } catch (e) {
    print('  ✗ loadMem fehlgeschlagen: $e');
    return;
  }

  // Auf Gerät 0 abspielen
  print('  ▶ Spiele auf ${devices[0].name}...');
  final h1 = soloud.play(source, volume: 0.5);
  await Future.delayed(const Duration(milliseconds: 300));
  if (h1.id != 0 && soloud.getIsValidVoiceHandle(h1)) {
    await soloud.stop(h1);
  }

  // HOT-Wechsel zu Gerät 1
  print('  ⇄ changeDevice() → ${devices[1].name}...');
  try {
    soloud.changeDevice(newDevice: devices[1]);
    print('  ✓ changeDevice() ohne Exception');
  } catch (e) {
    print('  ✗ changeDevice() EXCEPTION: $e');
    print('    → HOT-Wechsel auf dieser Platform nicht unterstützt');
    print('    → deinit+reinit bleibt die korrekte Methode');
    return;
  }

  // Prüfen ob Source noch gültig ist
  print('  ▶ Spiele GLEICHE Source auf ${devices[1].name} (kein erneutes Laden!)...');
  try {
    final h2 = soloud.play(source, volume: 0.5);
    await Future.delayed(const Duration(milliseconds: 600));
    print('  ✓ play() nach changeDevice() erfolgreich — Source blieb gültig!');
    if (soloud.getIsValidVoiceHandle(h2)) {
      await soloud.stop(h2);
    }
  } catch (e) {
    print('  ✗ play() nach changeDevice() FEHLER: $e');
    print('    → Source wurde durch changeDevice() ungültig gemacht');
    print('    → deinit+reinit ist notwendig (und PRELOAD muss wiederholt werden)');
  }

  // Aufräumen
  try { await soloud.disposeSource(source); } catch (_) {}
}

/// Hauptdiagnose: alle Geräte sequenziell testen, dann HOT-Wechsel.
Future<void> runWindowsAudioDiagnostics() async {
  final soloud = SoLoud.instance;

  print('\n╔══════════════════════════════════════════════╗');
  print('║   StageSync Windows Audio Diagnose          ║');
  print('╚══════════════════════════════════════════════╝');

  _printDevices(soloud);

  final devices = soloud.listPlaybackDevices();
  if (devices.isEmpty) {
    print('Keine Geräte gefunden. Diagnose abgebrochen.');
    return;
  }

  print('Teste ${devices.length} Gerät(e) sequenziell mit 440-Hz-Ton...');
  print('HINWEIS: Hören Sie welche(s) Gerät(e) Ton ausgeben!\n');

  final results = <String, bool>{};
  for (final device in devices) {
    results[device.name] = await _testDevice(soloud, device, durationSeconds: 0.8);
    await Future.delayed(const Duration(milliseconds: 200));
  }

  // Abschlussbericht
  print('\n════════════════════════════════════════════════');
  print('  Ergebnis-Zusammenfassung');
  print('════════════════════════════════════════════════');
  for (final entry in results.entries) {
    final symbol = entry.value ? '✓' : '✗';
    print('  $symbol ${entry.key}');
  }

  final workingCount = results.values.where((v) => v).length;
  print('\n  $workingCount/${results.length} Geräte erfolgreich getestet\n');

  // HOT-Wechsel-Test
  await _testChangeDevice(soloud);

  // Alles aufräumen
  if (soloud.isInitialized) {
    soloud.deinit();
  }

  print('\n════════════════════════════════════════════════');
  print('  Diagnose abgeschlossen');
  print('════════════════════════════════════════════════\n');
}

// ── Test-Entry-Point (muss manuell mit echter Hardware ausgeführt werden) ────

void main() {
  // Dieser Test ist als @Skip markiert, da er echte Hardware benötigt.
  // Zum Ausführen: flutter test test/showcontrol/audio_node/audio_engine_debug_test.dart
  // und das @Skip entfernen (oder --run-skipped übergeben).
  group('Windows Audio Diagnose (MANUELL, benötigt Hardware)', () {
    test(
      'enumeriert alle Geräte und testet Wiedergabe auf jedem',
      () async {
        await runWindowsAudioDiagnostics();
      },
      skip: 'Benötigt echte Audio-Hardware und Windows. '
          'Entferne skip zum manuellen Ausführen.',
    );
  });
}

