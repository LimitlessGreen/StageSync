import 'dart:async';
import 'dart:typed_data';

import 'package:flutter_midi_command/flutter_midi_command.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/grid_run_state.dart';
import 'grid_provider.dart';

/// APC-Mini-Pad-Mapping (identisch zur Server-Seite in internal/midinode):
/// note 0 = unten links, scene 0 = oberste Reihe.
const _gridSize = 8;

({int track, int scene})? _noteToCell(int note) {
  if (note < 0 || note >= _gridSize * _gridSize) return null;
  final col = note % _gridSize;
  final row = note ~/ _gridSize;
  return (track: col, scene: (_gridSize - 1) - row);
}

int? _cellToNote(int track, int scene) {
  if (track < 0 || track >= _gridSize || scene < 0 || scene >= _gridSize) {
    return null;
  }
  final row = (_gridSize - 1) - scene;
  return row * _gridSize + track;
}

/// APC-Mini-LED-Velocity-Codes.
int _ledVelocity(ClipLifecycle lifecycle) {
  switch (lifecycle) {
    case ClipLifecycle.playing:
    case ClipLifecycle.launched:
      return 1; // grün
    case ClipLifecycle.error:
      return 3; // rot
    default:
      return 0; // aus
  }
}

// ── State ─────────────────────────────────────────────────────────────────────

class GridMidiState {
  final bool enabled;
  final bool connected;
  final String? deviceName;
  final String? error;

  const GridMidiState({
    this.enabled = false,
    this.connected = false,
    this.deviceName,
    this.error,
  });

  GridMidiState copyWith({
    bool? enabled,
    bool? connected,
    String? deviceName,
    String? error,
  }) =>
      GridMidiState(
        enabled: enabled ?? this.enabled,
        connected: connected ?? this.connected,
        deviceName: deviceName ?? this.deviceName,
        error: error,
      );
}

// ── Provider ──────────────────────────────────────────────────────────────────

/// Lokaler MIDI-Pfad (Desktop): liest APC-Mini-Pads direkt im Client für
/// minimale UI-Latenz und spiegelt den Clip-Status als LED zurück.
///
/// Standardmäßig **deaktiviert** — der Server-MIDI-Node (`--midi-node`) ist der
/// Default. Beide Pfade gleichzeitig würden Pads doppelt auslösen, daher per
/// [GridMidiController.setEnabled] umschalten.
final gridMidiProvider =
    StateNotifierProvider<GridMidiController, GridMidiState>(
        (ref) => GridMidiController(ref));

class GridMidiController extends StateNotifier<GridMidiState> {
  final Ref _ref;
  final MidiCommand _midi = MidiCommand();

  StreamSubscription<MidiPacket>? _rxSub;
  ProviderSubscription? _runStatesSub;
  String _portMatch = 'APC';

  // Letzter gesendeter LED-Zustand je Pad-Note → vermeidet redundante Sends.
  final Map<int, int> _ledState = {};

  GridMidiController(this._ref) : super(const GridMidiState());

  /// Schaltet den lokalen MIDI-Pfad ein/aus.
  Future<void> setEnabled(bool enabled, {String portMatch = 'APC'}) async {
    _portMatch = portMatch;
    if (enabled == state.enabled) return;
    if (enabled) {
      await _connect();
    } else {
      await _disconnect();
    }
  }

  Future<void> _connect() async {
    try {
      final devices = await _midi.devices;
      MidiDevice? target;
      if (devices != null && devices.isNotEmpty) {
        target = devices.firstWhere(
          (d) => d.name.toLowerCase().contains(_portMatch.toLowerCase()),
          orElse: () => devices.first,
        );
      }
      if (target == null) {
        state = state.copyWith(enabled: true, connected: false, error: 'Kein MIDI-Gerät gefunden');
        return;
      }
      await _midi.connectToDevice(target);

      _rxSub = _midi.onMidiDataReceived?.listen(_onMidiData);

      // LED-Updates aus dem Grid-Run-State spiegeln.
      _runStatesSub = _ref.listen<GridState>(gridProvider, (prev, next) {
        _syncLeds(next);
      }, fireImmediately: true);

      state = state.copyWith(enabled: true, connected: true, deviceName: target.name, error: null);
    } catch (e) {
      state = state.copyWith(enabled: true, connected: false, error: e.toString());
    }
  }

  Future<void> _disconnect() async {
    await _rxSub?.cancel();
    _rxSub = null;
    _runStatesSub?.close();
    _runStatesSub = null;
    _clearAllLeds();
    state = const GridMidiState(enabled: false, connected: false);
  }

  void _onMidiData(MidiPacket packet) {
    final data = packet.data;
    if (data.length < 3) return;
    final status = data[0] & 0xF0;
    final note = data[1];
    final velocity = data[2];

    // Note-On (0x90) = Pad-Druck; velocity 0 oder Note-Off (0x80) = Release.
    if (status == 0x90 || status == 0x80) {
      final cell = _noteToCell(note);
      if (cell == null) return;
      final released = status == 0x80 || velocity == 0;
      _ref.read(gridProvider.notifier).launchClip(
            cell.track,
            cell.scene,
            released: released,
          );
    }
  }

  void _syncLeds(GridState gridState) {
    final grid = gridState.grid;
    if (grid == null) return;
    for (final clip in grid.clips) {
      final note = _cellToNote(clip.trackIndex, clip.sceneIndex);
      if (note == null) continue;
      final run = gridState.runStates[clip.clipId];
      final vel = _ledVelocity(run?.lifecycle ?? ClipLifecycle.idle);
      if (_ledState[note] != vel) {
        _ledState[note] = vel;
        _sendNoteOn(note, vel);
      }
    }
  }

  void _clearAllLeds() {
    for (var note = 0; note < _gridSize * _gridSize; note++) {
      _sendNoteOn(note, 0);
    }
    _ledState.clear();
  }

  void _sendNoteOn(int note, int velocity) {
    try {
      _midi.sendData(Uint8List.fromList([0x90, note, velocity]));
    } catch (_) {
      // Senden fehlgeschlagen (Gerät getrennt) — ignorieren.
    }
  }

  @override
  void dispose() {
    _rxSub?.cancel();
    _runStatesSub?.close();
    super.dispose();
  }
}
