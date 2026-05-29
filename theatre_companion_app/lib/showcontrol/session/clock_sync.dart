/// Geräteübergreifende Uhren-Synchronisation gegen die Server-Uhr.
///
/// Der StageSync-Server ist die Referenzuhr. Jeder Node schätzt über den
/// regelmäßigen Heartbeat (NTP-artig) seinen Offset zur Server-Uhr. Damit
/// können `startUnixMillis`-Zeitpunkte geräteübergreifend einheitlich in
/// Serverzeit interpretiert werden — Voraussetzung für synchrone Wiedergabe.
///
/// Ohne Sync (offset == 0) verhält sich [serverNow] wie die lokale Uhr.
class ClockSync {
  ClockSync._();
  static final ClockSync instance = ClockSync._();

  /// Offset in Millisekunden: serverTime ≈ localTime + _offsetMs.
  double? _offsetMs;

  /// Niedrigste bisher gemessene Round-Trip-Time (Diagnose/Qualität).
  int _bestRttMs = 1 << 30;

  bool get isSynced => _offsetMs != null;
  int get offsetMs => (_offsetMs ?? 0).round();
  int get bestRttMs => _bestRttMs;

  /// Verarbeitet einen Heartbeat-Austausch.
  /// [t0] = lokale Sendezeit, [serverMs] = Server-Zeitstempel der Antwort,
  /// [t3] = lokale Empfangszeit (alle Unix-Millis).
  void update({required int t0, required int serverMs, required int t3}) {
    final rtt = t3 - t0;
    if (rtt < 0) return; // unplausibel
    // Annahme symmetrischer Latenz: Server-Verarbeitung ≈ 0, also liegt der
    // Server-Zeitstempel zeitlich in der Mitte des Round-Trips.
    final sample = serverMs - (t0 + t3) / 2.0;

    if (_offsetMs == null) {
      _offsetMs = sample;
      _bestRttMs = rtt;
      return;
    }
    // EMA-Glättung gegen Jitter; niedrigere RTT bekommt mehr Gewicht.
    final alpha = rtt <= _bestRttMs ? 0.5 : 0.2;
    _offsetMs = _offsetMs! * (1 - alpha) + sample * alpha;
    if (rtt < _bestRttMs) _bestRttMs = rtt;
  }

  /// Geschätzte aktuelle Server-Zeit in Unix-Millis.
  int serverNow() => DateTime.now().millisecondsSinceEpoch + offsetMs;

  /// Rechnet einen Server-Zeitpunkt in die lokale Uhr um.
  int toLocalMillis(int serverMs) => serverMs - offsetMs;

  void reset() {
    _offsetMs = null;
    _bestRttMs = 1 << 30;
  }
}
