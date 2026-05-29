import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_soloud/flutter_soloud.dart';

import '../../../showcontrol/grpc/generated/stagesync/v1/common.pb.dart';
import '../../../showcontrol/grpc/generated/stagesync/v1/node.pb.dart';
import '../../../showcontrol/grpc/stage_sync_client.dart';
import '../../../showcontrol/nodes/audio_node/audio_node_service.dart';
import '../../../showcontrol/nodes/audio_node/sweep_generator.dart';
import '../../../showcontrol/providers/audio_node_provider.dart';
import '../../../showcontrol/providers/session_provider.dart';

// ── Farben ────────────────────────────────────────────────────────────────────
const _bg = Color(0xFF0A0A0A);
const _surface = Color(0xFF141414);
const _accent = Color(0xFF00E5FF);

class AudioEngineerScreen extends ConsumerStatefulWidget {
  const AudioEngineerScreen({super.key});

  @override
  ConsumerState<AudioEngineerScreen> createState() => _AudioEngineerScreenState();
}

class _AudioEngineerScreenState extends ConsumerState<AudioEngineerScreen> {

  @override
  void initState() {
    super.initState();
    // SoLoud sofort warm-starten damit der erste Testton ohne Verzögerung kommt
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(audioNodeProvider.notifier).ensureEngineInitialized().ignore();
    });
  }

  // Sweep-Parameter
  double _startHz = 20.0;
  double _endHz = 20000.0;
  double _durationSec = 10.0;
  double _amplitude = 0.8;

  // Ton-Parameter
  double _toneHz = 1000.0;
  double _toneDuration = 3.0;

  // State
  bool _isSweeping = false;
  bool _isPlaying = false;
  bool _isDiagRunning = false;
  bool _isReiniting = false;
  String _status = '';
  bool _statusIsError = false;
  final Set<String> _selectedNodeIds = {};

  static const _sweepCueId = '__sweep__';
  static const _toneCueId = '__tone__';

  @override
  Widget build(BuildContext context) {
    final session = ref.watch(sessionProvider);
    final audioStatus = ref.watch(audioNodeProvider);
    final isAudioNode = audioStatus.state == AudioNodeState.connected;

    final allNodes = session.session?.nodes.toList() ?? <NodeInfo>[];
    final audioNodes = allNodes.where((n) =>
        n.tasks.contains(NodeTask.NODE_TASK_AUDIO_OUTPUT)).toList();

    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        backgroundColor: _surface,
        title: const Text('Audio-Ingenieur', style: TextStyle(color: Colors.white)),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Diagnose ───────────────────────────────────────────────────
            _SectionHeader('Diagnose'),
            const SizedBox(height: 8),
            Row(
              children: [
                _ActionButton(
                  label: _isDiagRunning ? 'Test läuft…' : '1-kHz-Ton testen',
                  icon: Icons.hearing,
                  color: Colors.green,
                  enabled: !_isDiagRunning && !_isSweeping && !_isPlaying && !_isReiniting,
                  onPressed: _runDiagnostic,
                ),
                const SizedBox(width: 12),
                _ActionButton(
                  label: _isReiniting ? 'Re-Init…' : 'Audio Re-Init',
                  icon: Icons.restart_alt,
                  color: Colors.orange,
                  enabled: !_isDiagRunning && !_isReiniting,
                  onPressed: _reInitAudio,
                ),
              ],
            ),
            const SizedBox(height: 8),
            // Gerätepicker – zeigt welches Gerät tatsächlich den Ton ausgibt.
            // Auch ohne aktive Node-Verbindung nutzbar (nach ensureEngineInitialized).
            if (audioStatus.availableDevices.isNotEmpty) ...[
              _DevicePicker(
                devices: audioStatus.availableDevices,
                selectedDevice: audioStatus.selectedDevice,
                isReiniting: _isReiniting,
                onSelect: (device) async {
                  setState(() { _isReiniting = true; _statusIsError = false; });
                  _setStatus('Wechsle auf "${device.name}"…');
                  try {
                    await ref.read(audioNodeProvider.notifier).selectDevice(device);
                    final actual = ref.read(audioNodeProvider).selectedDevice;
                    if (actual?.name == device.name) {
                      _setStatus('Gerät: "${device.name}" aktiv.');
                    } else {
                      _setStatus(
                        'Fallback auf System-Default — "${device.name}" nicht initialisierbar.',
                        error: true,
                      );
                    }
                  } catch (e) {
                    _setStatus('Fehler beim Gerätewechsel: $e', error: true);
                  } finally {
                    if (mounted) setState(() => _isReiniting = false);
                  }
                },
              ),
            ] else ...[
              Text(
                isAudioNode
                    ? 'Gerät: ${audioStatus.selectedDevice?.name ?? "System-Default"}'
                    : 'Direkttest auf diesem Gerät (kein Audio-Node nötig).',
                style: const TextStyle(color: Colors.white38, fontSize: 11),
              ),
            ],

            const SizedBox(height: 24),

            // ── Node-Auswahl ───────────────────────────────────────────────
            _SectionHeader('Ziel-Audio-Nodes'),
            const SizedBox(height: 8),
            if (audioNodes.isEmpty)
              _InfoTile('Keine Audio-Nodes verbunden. Starte zuerst eine Session mit Audio-Task.')
            else
              _NodeSelector(
                nodes: audioNodes,
                selectedIds: _selectedNodeIds,
                isAudioNode: isAudioNode,
                onToggle: (id) => setState(() {
                  if (_selectedNodeIds.contains(id)) {
                    _selectedNodeIds.remove(id);
                  } else {
                    _selectedNodeIds.add(id);
                  }
                }),
              ),

            const SizedBox(height: 24),

            // ── Sweep ──────────────────────────────────────────────────────
            _SectionHeader('Frequenz-Sweep'),
            const SizedBox(height: 12),
            _SweepControls(
              startHz: _startHz,
              endHz: _endHz,
              durationSec: _durationSec,
              amplitude: _amplitude,
              onStartHzChanged: (v) => setState(() => _startHz = v),
              onEndHzChanged: (v) => setState(() => _endHz = v),
              onDurationChanged: (v) => setState(() => _durationSec = v),
              onAmplitudeChanged: (v) => setState(() => _amplitude = v),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                _ActionButton(
                  label: _isSweeping ? 'Sweep läuft…' : 'Sweep starten',
                  icon: _isSweeping ? Icons.graphic_eq : Icons.play_arrow,
                  color: _isSweeping ? Colors.orange : _accent,
                  enabled: !_isSweeping && !_isPlaying && _selectedNodeIds.isNotEmpty,
                  onPressed: _startSweep,
                ),
                const SizedBox(width: 12),
                _ActionButton(
                  label: 'Stop',
                  icon: Icons.stop,
                  color: Colors.red,
                  enabled: _isSweeping || _isPlaying,
                  onPressed: _stopAll,
                ),
              ],
            ),

            const SizedBox(height: 24),

            // ── Einzelton ─────────────────────────────────────────────────
            _SectionHeader('Einzelton (Sinus)'),
            const SizedBox(height: 12),
            _ToneControls(
              freqHz: _toneHz,
              duration: _toneDuration,
              onFreqChanged: (v) => setState(() => _toneHz = v),
              onDurationChanged: (v) => setState(() => _toneDuration = v),
            ),
            const SizedBox(height: 12),
            _ActionButton(
              label: _isPlaying ? 'Ton läuft…' : 'Ton abspielen',
              icon: Icons.volume_up,
              color: _isPlaying ? Colors.orange : _accent,
              enabled: !_isSweeping && !_isPlaying && _selectedNodeIds.isNotEmpty,
              onPressed: _playTone,
            ),

            const SizedBox(height: 24),

            // ── Status ────────────────────────────────────────────────────
            if (_status.isNotEmpty)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: _statusIsError
                      ? Colors.red.withValues(alpha: 0.1)
                      : _surface,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: _statusIsError ? Colors.red.withValues(alpha: 0.5) : Colors.white12,
                  ),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      _statusIsError ? Icons.error_outline : Icons.info_outline,
                      color: _statusIsError ? Colors.red : _accent,
                      size: 16,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _status,
                        style: TextStyle(
                          color: _statusIsError ? Colors.red[200] : Colors.white70,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

            const SizedBox(height: 24),

            // ── Hinweis: Frequenzanalyse ───────────────────────────────────
            _SectionHeader('Spektrumanalyse'),
            const SizedBox(height: 8),
            _InfoTile(
              'Echtzeit-Spektrumanalyse wird in einer späteren Version ergänzt.\n'
              'Nutze einen externen Analysator (z. B. SMAART, Room EQ Wizard) für professionelle Messungen.',
            ),
          ],
        ),
      ),
    );
  }

  void _setStatus(String msg, {bool error = false}) {
    if (mounted) setState(() { _status = msg; _statusIsError = error; });
  }

  Future<void> _reInitAudio() async {
    setState(() { _isReiniting = true; _statusIsError = false; });
    _setStatus('SoLoud wird mit Default-Gerät neu initialisiert…');
    try {
      final notifier = ref.read(audioNodeProvider.notifier);
      // Gerätauswahl temporär auf Default zurücksetzen, dann re-init
      // Hintergrund: auf Windows schlägt init(device) oft still fehl.
      await notifier.resetToDefaultDevice();
      _setStatus('Re-Init OK — jetzt Testton prüfen.');
    } catch (e) {
      _setStatus('Re-Init FEHLER: $e', error: true);
    } finally {
      if (mounted) setState(() => _isReiniting = false);
    }
  }

  /// Direkttest: 1-kHz-Ton via SoLoud — zeigt welches Gerät tatsächlich genutzt wird.
  Future<void> _runDiagnostic() async {
    setState(() { _isDiagRunning = true; _statusIsError = false; });
    try {
      final audioNotifier = ref.read(audioNodeProvider.notifier);
      final audioStatus = ref.read(audioNodeProvider);
      final deviceName = audioStatus.selectedDevice?.name ?? 'Default';
      _setStatus('Init Audio (Gerät: $deviceName)…');

      final wav = SweepGenerator.generateTone(
        frequencyHz: 1000.0,
        durationSeconds: 1.5,
        amplitude: 0.7,
      );
      await audioNotifier.playWavBytesLocally('__diag__', wav);
      _setStatus('▶ 1-kHz-Ton auf "$deviceName" — hörst du etwas?');
      await Future.delayed(const Duration(milliseconds: 1700));
      await audioNotifier.stopLocalPlayback('__diag__');
      _setStatus('Test OK auf "$deviceName".');
    } catch (e) {
      _setStatus('FEHLER: $e', error: true);
    } finally {
      if (mounted) setState(() => _isDiagRunning = false);
    }
  }

  Future<void> _startSweep() async {
    setState(() { _isSweeping = true; _statusIsError = false; });
    try {
      await _sendTestSignal(
        kind: AudioTestSignalCommand_Kind.KIND_SWEEP,
        cueId: _sweepCueId,
        startHz: _startHz,
        endHz: _endHz,
        durationMs: _durationSec * 1000,
      );
      Future.delayed(Duration(milliseconds: (_durationSec * 1000).round() + 200), () {
        if (mounted) setState(() { _isSweeping = false; _status = ''; });
      });
    } catch (e) {
      setState(() => _isSweeping = false);
      _setStatus('Fehler: $e', error: true);
    }
  }

  Future<void> _playTone() async {
    setState(() { _isPlaying = true; _statusIsError = false; });
    try {
      await _sendTestSignal(
        kind: AudioTestSignalCommand_Kind.KIND_TONE,
        cueId: _toneCueId,
        frequencyHz: _toneHz,
        durationMs: _toneDuration * 1000,
      );
      Future.delayed(Duration(milliseconds: (_toneDuration * 1000).round() + 200), () {
        if (mounted) setState(() { _isPlaying = false; _status = ''; });
      });
    } catch (e) {
      setState(() => _isPlaying = false);
      _setStatus('Fehler: $e', error: true);
    }
  }

  /// Sendet die ANWEISUNG, ein Testsignal zu erzeugen — es wird kein Audio
  /// übertragen. Remote-Nodes generieren selbst; der lokale Node erzeugt das
  /// Signal direkt in seiner Engine.
  Future<void> _sendTestSignal({
    required AudioTestSignalCommand_Kind kind,
    required String cueId,
    double startHz = 0,
    double endHz = 0,
    double frequencyHz = 0,
    required double durationMs,
  }) async {
    final session = ref.read(sessionProvider);
    final audioNotifier = ref.read(audioNodeProvider.notifier);
    final audioStatus = ref.read(audioNodeProvider);
    final myId = session.myNode?.nodeId ?? '';

    final allNodes = session.session?.nodes.toList() ?? <NodeInfo>[];
    final selected = allNodes.where((n) =>
        _selectedNodeIds.contains(n.nodeId) &&
        n.tasks.contains(NodeTask.NODE_TASK_AUDIO_OUTPUT)).toList();

    final isSweep = kind == AudioTestSignalCommand_Kind.KIND_SWEEP;
    final client = StageSyncClient.instance;
    int sent = 0;

    for (final node in selected) {
      if (node.nodeId == myId) {
        // Lokaler Node: Signal direkt erzeugen und abspielen.
        if (audioStatus.state == AudioNodeState.connected) {
          final wav = isSweep
              ? SweepGenerator.generateSweep(
                  startHz: startHz, endHz: endHz,
                  durationSeconds: durationMs / 1000, amplitude: _amplitude)
              : SweepGenerator.generateTone(
                  frequencyHz: frequencyHz,
                  durationSeconds: durationMs / 1000, amplitude: _amplitude);
          await audioNotifier.playWavBytesLocally(cueId, wav);
          sent++;
        }
      } else {
        // Remote-Node: nur die Anweisung schicken.
        await client.node.sendNodeCommand(SendNodeCommandRequest(
          sessionId: session.session!.sessionId,
          token: session.token!,
          targetNodeId: node.nodeId,
          command: NodeCommandRequest(
            sessionId: session.session!.sessionId,
            targetNodeId: node.nodeId,
            audioTest: AudioTestSignalCommand(
              cueId: cueId,
              kind: kind,
              startHz: startHz,
              endHz: endHz,
              frequencyHz: frequencyHz,
              durationMs: durationMs,
              amplitude: _amplitude,
            ),
          ),
        ));
        sent++;
      }
    }

    if (sent > 0) {
      _setStatus('${isSweep ? "Sweep" : "Ton"} läuft auf $sent Node(s).');
    } else {
      _setStatus('Keine Audio-Nodes ausgewählt.', error: true);
    }
  }

  Future<void> _stopAll() async {
    final audioNotifier = ref.read(audioNodeProvider.notifier);
    // Lokal: alle Sounds sofort stoppen (robust – keine cueId-Kenntnis nötig)
    await audioNotifier.stopAllLocalPlayback();
    // Remote: zuerst gezielt nach cueId, dann "Stop All" (leer = alle) als Fallback
    await _sendStopToRemotes(_sweepCueId);
    await _sendStopToRemotes(_toneCueId);
    await _sendStopToRemotes(''); // leere cueId = "alle stoppen" auf Remote-Nodes
    setState(() { _isSweeping = false; _isPlaying = false; _status = ''; _statusIsError = false; });
  }

  Future<void> _sendStopToRemotes(String cueId) async {
    final session = ref.read(sessionProvider);
    if (!session.isInSession) return;
    final myId = session.myNode?.nodeId ?? '';
    final client = StageSyncClient.instance;
    final allNodes = session.session?.nodes.toList() ?? <NodeInfo>[];
    for (final node in allNodes) {
      if (node.nodeId == myId) continue;
      if (!_selectedNodeIds.contains(node.nodeId)) continue;
      if (!node.tasks.contains(NodeTask.NODE_TASK_AUDIO_OUTPUT)) continue;
      try {
        await client.node.sendNodeCommand(SendNodeCommandRequest(
          sessionId: session.session!.sessionId,
          token: session.token!,
          targetNodeId: node.nodeId,
          command: NodeCommandRequest(
            sessionId: session.session!.sessionId,
            targetNodeId: node.nodeId,
            audioStop: AudioStopCommand(cueId: cueId, fadeOutMs: 100),
          ),
        ));
      } catch (_) {}
    }
  }

}

// ── Widgets ───────────────────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader(this.title);

  @override
  Widget build(BuildContext context) => Text(
        title,
        style: const TextStyle(
          color: _accent,
          fontSize: 13,
          fontWeight: FontWeight.bold,
          letterSpacing: 1.2,
        ),
      );
}

class _InfoTile extends StatelessWidget {
  final String text;
  const _InfoTile(this.text);

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: _surface,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.white12),
        ),
        child: Text(text, style: const TextStyle(color: Colors.white54, fontSize: 13)),
      );
}

class _NodeSelector extends StatelessWidget {
  final List<NodeInfo> nodes;
  final Set<String> selectedIds;
  final bool isAudioNode;
  final ValueChanged<String> onToggle;

  const _NodeSelector({
    required this.nodes,
    required this.selectedIds,
    required this.isAudioNode,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: nodes.map((n) {
        final selected = selectedIds.contains(n.nodeId);
        return FilterChip(
          selected: selected,
          label: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.speaker, size: 14, color: selected ? _bg : Colors.white54),
              const SizedBox(width: 4),
              Text(n.name, style: TextStyle(color: selected ? _bg : Colors.white70)),
            ],
          ),
          selectedColor: _accent,
          backgroundColor: _surface,
          checkmarkColor: _bg,
          side: BorderSide(color: selected ? _accent : Colors.white24),
          onSelected: (_) => onToggle(n.nodeId),
        );
      }).toList(),
    );
  }
}

class _SweepControls extends StatelessWidget {
  final double startHz, endHz, durationSec, amplitude;
  final ValueChanged<double> onStartHzChanged, onEndHzChanged, onDurationChanged, onAmplitudeChanged;

  const _SweepControls({
    required this.startHz,
    required this.endHz,
    required this.durationSec,
    required this.amplitude,
    required this.onStartHzChanged,
    required this.onEndHzChanged,
    required this.onDurationChanged,
    required this.onAmplitudeChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.white12),
      ),
      child: Column(
        children: [
          _SliderRow(
            label: 'Start',
            value: startHz,
            unit: 'Hz',
            min: 20,
            max: 1000,
            divisions: 98,
            format: (v) => '${v.round()} Hz',
            onChanged: onStartHzChanged,
          ),
          _SliderRow(
            label: 'Ende',
            value: endHz,
            unit: 'Hz',
            min: 1000,
            max: 20000,
            divisions: 190,
            format: (v) => '${(v / 1000).toStringAsFixed(1)} kHz',
            onChanged: onEndHzChanged,
          ),
          _SliderRow(
            label: 'Dauer',
            value: durationSec,
            unit: 's',
            min: 2,
            max: 60,
            divisions: 58,
            format: (v) => '${v.round()} s',
            onChanged: onDurationChanged,
          ),
          _SliderRow(
            label: 'Pegel',
            value: amplitude,
            unit: '',
            min: 0.1,
            max: 1.0,
            divisions: 9,
            format: (v) => '${(v * 100).round()}%',
            onChanged: onAmplitudeChanged,
          ),
        ],
      ),
    );
  }
}

class _ToneControls extends StatelessWidget {
  final double freqHz, duration;
  final ValueChanged<double> onFreqChanged, onDurationChanged;

  const _ToneControls({
    required this.freqHz,
    required this.duration,
    required this.onFreqChanged,
    required this.onDurationChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.white12),
      ),
      child: Column(
        children: [
          _SliderRow(
            label: 'Frequenz',
            value: freqHz,
            unit: 'Hz',
            min: 20,
            max: 20000,
            divisions: 200,
            format: (v) => v >= 1000
                ? '${(v / 1000).toStringAsFixed(2)} kHz'
                : '${v.round()} Hz',
            onChanged: onFreqChanged,
          ),
          _SliderRow(
            label: 'Dauer',
            value: duration,
            unit: 's',
            min: 0.5,
            max: 30,
            divisions: 59,
            format: (v) => '${v.toStringAsFixed(1)} s',
            onChanged: onDurationChanged,
          ),
        ],
      ),
    );
  }
}

class _SliderRow extends StatelessWidget {
  final String label, unit;
  final double value, min, max;
  final int divisions;
  final String Function(double) format;
  final ValueChanged<double> onChanged;

  const _SliderRow({
    required this.label,
    required this.value,
    required this.unit,
    required this.min,
    required this.max,
    required this.divisions,
    required this.format,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SizedBox(
          width: 64,
          child: Text(label, style: const TextStyle(color: Colors.white70, fontSize: 12)),
        ),
        Expanded(
          child: SliderTheme(
            data: SliderTheme.of(context).copyWith(
              activeTrackColor: _accent,
              thumbColor: _accent,
              inactiveTrackColor: Colors.white12,
              overlayColor: _accent.withValues(alpha: 0.1),
            ),
            child: Slider(
              value: value.clamp(min, max),
              min: min,
              max: max,
              divisions: divisions,
              onChanged: onChanged,
            ),
          ),
        ),
        SizedBox(
          width: 72,
          child: Text(
            format(value),
            style: const TextStyle(color: _accent, fontSize: 12, fontFamily: 'monospace'),
            textAlign: TextAlign.right,
          ),
        ),
      ],
    );
  }
}

class _DevicePicker extends StatelessWidget {
  final List<PlaybackDevice> devices;
  final PlaybackDevice? selectedDevice;
  final bool isReiniting;
  final ValueChanged<PlaybackDevice> onSelect;

  const _DevicePicker({
    required this.devices,
    required this.selectedDevice,
    required this.isReiniting,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.white12),
      ),
      child: Row(
        children: [
          const Icon(Icons.speaker, size: 16, color: Colors.white38),
          const SizedBox(width: 8),
          Expanded(
            child: DropdownButton<PlaybackDevice>(
              value: devices.contains(selectedDevice) ? selectedDevice : null,
              hint: Text(
                selectedDevice?.name ?? 'System-Default',
                style: const TextStyle(color: Colors.white54, fontSize: 13),
                overflow: TextOverflow.ellipsis,
              ),
              isExpanded: true,
              dropdownColor: _surface,
              underline: const SizedBox.shrink(),
              style: const TextStyle(color: Colors.white70, fontSize: 13),
              items: devices.map((d) => DropdownMenuItem(
                value: d,
                child: Text(d.name, overflow: TextOverflow.ellipsis),
              )).toList(),
              onChanged: isReiniting ? null : (d) { if (d != null) onSelect(d); },
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final bool enabled;
  final VoidCallback onPressed;

  const _ActionButton({
    required this.label,
    required this.icon,
    required this.color,
    required this.enabled,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return FilledButton.icon(
      style: FilledButton.styleFrom(
        backgroundColor: enabled ? color : Colors.white12,
        foregroundColor: enabled ? Colors.black : Colors.white38,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      ),
      icon: Icon(icon),
      label: Text(label),
      onPressed: enabled ? onPressed : null,
    );
  }
}
