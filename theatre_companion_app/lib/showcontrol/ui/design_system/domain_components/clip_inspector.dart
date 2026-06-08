import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../sc_colors.dart';
import '../primitives/sc_waveform.dart';
import '../../../providers/grid_provider.dart';
import '../../../providers/waveform_provider.dart';
import '../../../providers/media_provider.dart';
import '../../../providers/show_control_provider.dart';
import '../../../grpc/generated/stagesync/v1/grid.pb.dart';

const _uuid = Uuid();

/// Payload-Typ einer Zelle, gewählt im Inspector.
enum _ClipKind { audio, osc, midi, cueRef }

/// Editor-Sheet für eine Grid-Zelle. Öffnen via [showClipInspector].
class ClipInspector extends ConsumerStatefulWidget {
  final int trackIndex;
  final int sceneIndex;
  final GridClip? existing;

  const ClipInspector({
    super.key,
    required this.trackIndex,
    required this.sceneIndex,
    this.existing,
  });

  @override
  ConsumerState<ClipInspector> createState() => _ClipInspectorState();
}

class _ClipInspectorState extends ConsumerState<ClipInspector> {
  late _ClipKind _kind;
  late TextEditingController _label;
  late String _clipId;
  LaunchMode _launchMode = LaunchMode.LAUNCH_TRIGGER;
  FollowAction _follow = FollowAction.FOLLOW_NONE;

  // Audio
  String _assetId = '';
  double _volumeDb = 0;
  double _fadeInMs = 0;
  double _fadeOutMs = 0;
  bool _loop = false;
  double _startMs = 0;
  double _endMs = 0;
  double _durationMs = 0;

  // OSC
  late TextEditingController _oscAddress;
  late TextEditingController _oscArgs;

  // MIDI
  int _midiChannel = 0;
  int _midiCommand = 0x90;
  int _midiData1 = 60;
  int _midiData2 = 127;

  // CueRef
  String _cueId = '';

  @override
  void initState() {
    super.initState();
    final c = widget.existing;
    _clipId = c?.clipId ?? _uuid.v4();
    _label = TextEditingController(text: c?.label ?? '');
    _oscAddress = TextEditingController();
    _oscArgs = TextEditingController();
    _kind = _ClipKind.audio;

    if (c != null) {
      _launchMode = c.launchMode;
      _follow = c.follow;
      if (c.hasAudio()) {
        _kind = _ClipKind.audio;
        final a = c.audio;
        _assetId = a.assetId;
        _volumeDb = a.volumeDb;
        _fadeInMs = a.fadeInMs;
        _fadeOutMs = a.fadeOutMs;
        _loop = a.loop;
        _startMs = a.startTimeMs;
        _endMs = a.endTimeMs;
        _durationMs = a.declaredDurationMs;
      } else if (c.hasOsc()) {
        _kind = _ClipKind.osc;
        _oscAddress.text = c.osc.address;
        _oscArgs.text = c.osc.args.join(' ');
      } else if (c.hasMidi()) {
        _kind = _ClipKind.midi;
        _midiChannel = c.midi.channel;
        _midiCommand = c.midi.command;
        _midiData1 = c.midi.data1;
        _midiData2 = c.midi.data2;
      } else if (c.hasCueRef()) {
        _kind = _ClipKind.cueRef;
        _cueId = c.cueRef.cueId;
      }
    }
  }

  @override
  void dispose() {
    _label.dispose();
    _oscAddress.dispose();
    _oscArgs.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        color: ScColors.bg,
        borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text('Zelle  T${widget.trackIndex + 1} · S${widget.sceneIndex + 1}',
                    style: const TextStyle(color: ScColors.textPrimary, fontSize: 15, fontWeight: FontWeight.bold)),
                const Spacer(),
                if (widget.existing != null)
                  IconButton(
                    icon: const Icon(Icons.delete_outline, color: ScColors.error),
                    tooltip: 'Zelle löschen',
                    onPressed: _delete,
                  ),
              ],
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _label,
              style: const TextStyle(color: ScColors.textPrimary),
              decoration: _dec('Label'),
            ),
            const SizedBox(height: 12),
            _kindSelector(),
            const SizedBox(height: 12),
            _payloadEditor(),
            const SizedBox(height: 12),
            _launchOptions(),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Abbrechen', style: TextStyle(color: ScColors.textSecondary)),
                ),
                const SizedBox(width: 8),
                FilledButton(
                  style: FilledButton.styleFrom(backgroundColor: ScColors.active),
                  onPressed: _save,
                  child: const Text('Speichern'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ── Type selector ───────────────────────────────────────────────────────────

  Widget _kindSelector() {
    return SegmentedButton<_ClipKind>(
      segments: const [
        ButtonSegment(value: _ClipKind.audio, label: Text('Audio')),
        ButtonSegment(value: _ClipKind.osc, label: Text('OSC')),
        ButtonSegment(value: _ClipKind.midi, label: Text('MIDI')),
        ButtonSegment(value: _ClipKind.cueRef, label: Text('Cue')),
      ],
      selected: {_kind},
      onSelectionChanged: (s) => setState(() => _kind = s.first),
    );
  }

  // ── Payload editors ─────────────────────────────────────────────────────────

  Widget _payloadEditor() {
    switch (_kind) {
      case _ClipKind.audio:
        return _audioEditor();
      case _ClipKind.osc:
        return _oscEditor();
      case _ClipKind.midi:
        return _midiEditor();
      case _ClipKind.cueRef:
        return _cueRefEditor();
    }
  }

  Widget _audioEditor() {
    final assets = ref.watch(mediaProvider).assets.where((a) => a.audio != null).toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        DropdownButtonFormField<String>(
          initialValue: _assetId.isEmpty ? null : _assetId,
          isExpanded: true,
          dropdownColor: ScColors.surface2,
          decoration: _dec('Audio-Datei'),
          style: const TextStyle(color: ScColors.textPrimary),
          items: [
            for (final a in assets)
              DropdownMenuItem(value: a.id, child: Text(a.name, overflow: TextOverflow.ellipsis)),
          ],
          onChanged: (v) {
            if (v == null) return;
            final a = assets.firstWhere((x) => x.id == v);
            setState(() {
              _assetId = v;
              _durationMs = a.audio?.declaredDurationMs ?? 0;
              if (_endMs == 0) _endMs = 0; // 0 = bis Ende
            });
          },
        ),
        const SizedBox(height: 12),
        if (_assetId.isNotEmpty) _waveform(),
        const SizedBox(height: 12),
        _slider('Lautstärke', _volumeDb, -60, 6, '${_volumeDb.toStringAsFixed(1)} dB',
            (v) => setState(() => _volumeDb = v)),
        _slider('Fade In', _fadeInMs, 0, 10000, '${_fadeInMs.toStringAsFixed(0)} ms',
            (v) => setState(() => _fadeInMs = v)),
        _slider('Fade Out', _fadeOutMs, 0, 10000, '${_fadeOutMs.toStringAsFixed(0)} ms',
            (v) => setState(() => _fadeOutMs = v)),
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: const Text('Loop', style: TextStyle(color: ScColors.textPrimary)),
          value: _loop,
          activeThumbColor: ScColors.active,
          onChanged: (v) => setState(() => _loop = v),
        ),
      ],
    );
  }

  Widget _waveform() {
    final asyncWf = ref.watch(waveformProvider(_assetId));
    return SizedBox(
      height: 90,
      child: asyncWf.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
            child: Text('Waveform-Fehler', style: TextStyle(color: ScColors.textDim))),
        data: (wf) {
          final dur = _durationMs > 0 ? _durationMs : (wf.durationMs > 0 ? wf.durationMs : 1);
          final endMs = _endMs > 0 ? _endMs : dur;
          return ScWaveform(
            data: wf,
            startFraction: (_startMs / dur).clamp(0.0, 1.0),
            endFraction: (endMs / dur).clamp(0.0, 1.0),
            fadeInFraction: (_fadeInMs / dur).clamp(0.0, 1.0),
            fadeOutFraction: (_fadeOutMs / dur).clamp(0.0, 1.0),
            onSeekStart: (f) => setState(() => _startMs = f * dur),
            onSeekEnd: (f) => setState(() => _endMs = f * dur),
          );
        },
      ),
    );
  }

  Widget _oscEditor() {
    return Column(
      children: [
        TextField(
          controller: _oscAddress,
          style: const TextStyle(color: ScColors.textPrimary),
          decoration: _dec('OSC-Adresse (z.B. /cue/1/go)'),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _oscArgs,
          style: const TextStyle(color: ScColors.textPrimary),
          decoration: _dec('Argumente (leerzeichengetrennt)'),
        ),
      ],
    );
  }

  Widget _midiEditor() {
    return Column(
      children: [
        _intField('Kanal (0-15)', _midiChannel, (v) => setState(() => _midiChannel = v)),
        _intField('Command (Hex, z.B. 144=NoteOn)', _midiCommand, (v) => setState(() => _midiCommand = v)),
        _intField('Data1 (Note/CC)', _midiData1, (v) => setState(() => _midiData1 = v)),
        _intField('Data2 (Velocity/Value)', _midiData2, (v) => setState(() => _midiData2 = v)),
      ],
    );
  }

  Widget _cueRefEditor() {
    final cues = ref.watch(showControlProvider).cueList?.cues ?? [];
    return DropdownButtonFormField<String>(
      initialValue: _cueId.isEmpty ? null : _cueId,
      isExpanded: true,
      dropdownColor: ScColors.surface2,
      decoration: _dec('Cue'),
      style: const TextStyle(color: ScColors.textPrimary),
      items: [
        for (final c in cues)
          DropdownMenuItem(
              value: c.cueId,
              child: Text('${c.number}  ${c.label}', overflow: TextOverflow.ellipsis)),
      ],
      onChanged: (v) => setState(() => _cueId = v ?? ''),
    );
  }

  Widget _launchOptions() {
    return Row(
      children: [
        Expanded(
          child: DropdownButtonFormField<LaunchMode>(
            initialValue: _launchMode,
            dropdownColor: ScColors.surface2,
            decoration: _dec('Launch-Modus'),
            style: const TextStyle(color: ScColors.textPrimary),
            items: const [
              DropdownMenuItem(value: LaunchMode.LAUNCH_TRIGGER, child: Text('Trigger')),
              DropdownMenuItem(value: LaunchMode.LAUNCH_GATE, child: Text('Gate')),
              DropdownMenuItem(value: LaunchMode.LAUNCH_TOGGLE, child: Text('Toggle')),
            ],
            onChanged: (v) => setState(() => _launchMode = v ?? LaunchMode.LAUNCH_TRIGGER),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: DropdownButtonFormField<FollowAction>(
            initialValue: _follow,
            dropdownColor: ScColors.surface2,
            decoration: _dec('Follow'),
            style: const TextStyle(color: ScColors.textPrimary),
            items: const [
              DropdownMenuItem(value: FollowAction.FOLLOW_NONE, child: Text('Keine')),
              DropdownMenuItem(value: FollowAction.FOLLOW_NEXT_CLIP, child: Text('Nächster Clip')),
              DropdownMenuItem(value: FollowAction.FOLLOW_NEXT_SCENE, child: Text('Nächste Scene')),
              DropdownMenuItem(value: FollowAction.FOLLOW_STOP, child: Text('Stop')),
            ],
            onChanged: (v) => setState(() => _follow = v ?? FollowAction.FOLLOW_NONE),
          ),
        ),
      ],
    );
  }

  // ── Helpers ──────────────────────────────────────────────────────────────────

  InputDecoration _dec(String label) => InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: ScColors.textSecondary),
        isDense: true,
        enabledBorder: const OutlineInputBorder(
            borderSide: BorderSide(color: ScColors.divider)),
        focusedBorder: const OutlineInputBorder(
            borderSide: BorderSide(color: ScColors.active)),
      );

  Widget _slider(String label, double value, double min, double max, String display,
      ValueChanged<double> onChanged) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(label, style: const TextStyle(color: ScColors.textSecondary, fontSize: 12)),
            const Spacer(),
            Text(display, style: const TextStyle(color: ScColors.textPrimary, fontSize: 12)),
          ],
        ),
        Slider(
          value: value.clamp(min, max),
          min: min,
          max: max,
          activeColor: ScColors.active,
          onChanged: onChanged,
        ),
      ],
    );
  }

  Widget _intField(String label, int value, ValueChanged<int> onChanged) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: TextFormField(
        initialValue: value.toString(),
        keyboardType: TextInputType.number,
        style: const TextStyle(color: ScColors.textPrimary),
        decoration: _dec(label),
        onChanged: (s) {
          final v = int.tryParse(s);
          if (v != null) onChanged(v);
        },
      ),
    );
  }

  // ── Save / Delete ─────────────────────────────────────────────────────────────

  void _save() {
    final clip = GridClip()
      ..clipId = _clipId
      ..trackIndex = widget.trackIndex
      ..sceneIndex = widget.sceneIndex
      ..label = _label.text
      ..launchMode = _launchMode
      ..follow = _follow;

    switch (_kind) {
      case _ClipKind.audio:
        clip.audio = AudioClipPayload()
          ..assetId = _assetId
          ..volumeDb = _volumeDb
          ..fadeInMs = _fadeInMs
          ..fadeOutMs = _fadeOutMs
          ..loop = _loop
          ..startTimeMs = _startMs
          ..endTimeMs = _endMs
          ..declaredDurationMs = _durationMs;
      case _ClipKind.osc:
        clip.osc = OscClipPayload()
          ..address = _oscAddress.text
          ..args.addAll(_oscArgs.text.trim().isEmpty
              ? const []
              : _oscArgs.text.trim().split(RegExp(r'\s+')));
      case _ClipKind.midi:
        clip.midi = MidiClipPayload()
          ..channel = _midiChannel
          ..command = _midiCommand
          ..data1 = _midiData1
          ..data2 = _midiData2;
      case _ClipKind.cueRef:
        clip.cueRef = CueRefPayload()..cueId = _cueId;
    }

    ref.read(gridProvider.notifier).upsertClip(clip);
    Navigator.of(context).pop();
  }

  void _delete() {
    ref.read(gridProvider.notifier).deleteClip(_clipId);
    Navigator.of(context).pop();
  }
}

/// Öffnet den Clip-Inspector als modales Bottom-Sheet.
Future<void> showClipInspector(
  BuildContext context, {
  required int trackIndex,
  required int sceneIndex,
  GridClip? existing,
}) {
  return showModalBottomSheet(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    builder: (_) => FractionallySizedBox(
      heightFactor: 0.85,
      child: ClipInspector(
        trackIndex: trackIndex,
        sceneIndex: sceneIndex,
        existing: existing,
      ),
    ),
  );
}
