import 'package:flutter_soloud/flutter_soloud.dart';

/// Abstrakte Schnittstelle für die Audio-Engine.
///
/// Ermöglicht das Austauschen der echten [AudioEngine]-Implementierung
/// durch einen Fake oder Mock in Unit-Tests (Dependency Inversion).
///
/// Implementierungen:
/// - [AudioEngine] – echte SoLoud-Implementierung
/// - In Tests: Mock via `FakeAudioEngine extends Fake implements AbstractAudioEngine`
abstract class AbstractAudioEngine {
  // ── Zustand ───────────────────────────────────────────────────────────────

  /// Gibt an ob die Engine erfolgreich initialisiert ist.
  bool get isInitialized;

  /// Das aktuell aktive Ausgabegerät, oder `null` wenn System-Default aktiv ist.
  PlaybackDevice? get selectedDevice;

  /// Alle Cue-IDs die gerade eine aktive (gültige) Voice haben.
  List<String> get activeCueIds;

  // ── Lebenszyklus ──────────────────────────────────────────────────────────

  /// Initialisiert SoLoud mit dem optionalen [device].
  /// Fällt automatisch auf den System-Default zurück wenn [device] nicht
  /// initialisierbar ist.
  Future<void> init({PlaybackDevice? device});

  /// Gibt alle Ressourcen frei und deinitialisiert SoLoud.
  Future<void> deinit();

  /// Wechselt das Ausgabegerät.
  ///
  /// Sucht das Gerät per Name in der aktuellen Geräteliste (stabiler als
  /// Index-Lookup) und führt dann ein deinit+reinit durch.
  /// Gibt das tatsächlich aktivierte Gerät zurück, oder `null` für Default.
  Future<PlaybackDevice?> switchDevice(PlaybackDevice device);

  /// Listet alle verfügbaren Wiedergabegeräte auf.
  List<PlaybackDevice> listDevices();

  // ── Wiedergabe ────────────────────────────────────────────────────────────

  /// Lädt [filePath] für [cueId] in den Speicher vor (kein Abspielen).
  Future<void> preload(String cueId, String filePath);

  /// Spielt [cueId] ab. Wenn noch nicht vorgeladen, wird [filePath] sofort geladen.
  /// [startUnixMillis] ist die Serverzeit des gewünschten Starts (Clock-Sync).
  /// [startTimeMs] = Seek-Position in der Datei (0 = Anfang).
  /// [endTimeMs] = Stopp-Position (0 = Dateiende); bei Loop wird hier neu gestartet.
  Future<void> playAt({
    required String cueId,
    required String filePath,
    required int startUnixMillis,
    double volumeDb = 0.0,
    double fadeInMs = 0.0,
    double fadeOutMs = 0.0,
    bool loop = false,
    double startTimeMs = 0.0,
    double endTimeMs = 0.0,
  });

  /// Lädt WAV-Bytes direkt (ohne Datei) und spielt sie ab.
  Future<void> playWavBytes(String cueId, List<int> wavBytes, {double volumeDb = 0.0});

  /// Stoppt [cueId]. Mit [fadeOutMs] > 0 wird ein Fade-Out ausgeführt.
  Future<void> stop(String cueId, {double fadeOutMs = 0.0});

  /// Stoppt ALLE aktiven Cues. Für Notfall-Stop ohne cueId-Kenntnis.
  Future<void> stopAll({double fadeOutMs = 0.0});

  /// Pausiert [cueId] (Playhead bleibt stehen).
  Future<void> pause(String cueId, {double fadeOutMs = 0.0});

  /// Setzt eine angehaltene Voice fort.
  Future<void> resume(String cueId, {double fadeInMs = 0.0});

  /// Gibt alle geladenen Sources und Handles frei, lässt SoLoud aber laufen.
  Future<void> disposeAll();
}

