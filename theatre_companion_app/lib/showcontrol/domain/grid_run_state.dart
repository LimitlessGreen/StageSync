import 'package:meta/meta.dart';

/// Lebenszyklus einer Grid-Zelle (Clip) während der Ausführung.
enum ClipLifecycle {
  idle, // keine Aktivität
  launched, // ausgelöst, lädt/scheduled
  playing, // läuft
  stopped, // manuell/exklusiv gestoppt
  done, // natürlich beendet
  error,
}

/// Laufzeit-Zustand einer einzelnen Grid-Zelle.
/// Analog zu [CueRunState] im linearen Cue-System.
@immutable
class GridClipRunState {
  final ClipLifecycle lifecycle;

  /// Startzeit in Server-Zeit (Unix-Millis); null wenn nicht laufend.
  final int? startedServerMs;

  /// Gesamtlänge des Clips in ms (für Fortschrittsanzeige); 0 = unbekannt.
  final double lengthMs;

  /// Fehlermeldung bei [ClipLifecycle.error].
  final String? error;

  const GridClipRunState({
    this.lifecycle = ClipLifecycle.idle,
    this.startedServerMs,
    this.lengthMs = 0,
    this.error,
  });

  bool get isActive =>
      lifecycle == ClipLifecycle.playing || lifecycle == ClipLifecycle.launched;

  GridClipRunState copyWith({
    ClipLifecycle? lifecycle,
    int? startedServerMs,
    double? lengthMs,
    String? error,
  }) =>
      GridClipRunState(
        lifecycle: lifecycle ?? this.lifecycle,
        startedServerMs: startedServerMs ?? this.startedServerMs,
        lengthMs: lengthMs ?? this.lengthMs,
        error: error ?? this.error,
      );

  @override
  bool operator ==(Object other) =>
      other is GridClipRunState &&
      other.lifecycle == lifecycle &&
      other.startedServerMs == startedServerMs &&
      other.lengthMs == lengthMs &&
      other.error == error;

  @override
  int get hashCode => Object.hash(lifecycle, startedServerMs, lengthMs, error);
}
