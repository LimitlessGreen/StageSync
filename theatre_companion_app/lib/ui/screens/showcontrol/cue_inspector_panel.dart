import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:path/path.dart' as p;

import '../../../showcontrol/grpc/generated/stagesync/v1/showcontrol.pb.dart';
import '../../../showcontrol/grpc/generated/stagesync/v1/common.pb.dart';
import '../../../showcontrol/media/media_grpc_client.dart';
import '../../../showcontrol/media/server_media_client.dart' show MediaFile;
import '../../../showcontrol/ui/design_system/sc_colors.dart';
import '../../../showcontrol/ui/design_system/sc_typography.dart';

// ── Inspector panel ───────────────────────────────────────────────────────────

/// Inspector for a single cue — shows type-specific parameters.
/// Changes are auto-saved after a 350 ms debounce; no save button needed.
class CueInspectorPanel extends StatefulWidget {
  final Cue cue;
  final ValueChanged<Cue> onSave;
  final List<NodeInfo> connectedNodes;

  const CueInspectorPanel({
    super.key,
    required this.cue,
    required this.onSave,
    this.connectedNodes = const [],
  });

  @override
  State<CueInspectorPanel> createState() => _CueInspectorPanelState();
}

class _CueInspectorPanelState extends State<CueInspectorPanel> {
  late Cue _working;
  bool _dirty = false;
  bool _saving = false;
  Timer? _debounce;

  late TextEditingController _numberCtrl;
  late TextEditingController _labelCtrl;
  late TextEditingController _preWaitCtrl;
  late TextEditingController _postWaitCtrl;

  @override
  void initState() {
    super.initState();
    _initFrom(widget.cue);
  }

  @override
  void didUpdateWidget(CueInspectorPanel old) {
    super.didUpdateWidget(old);
    if (old.cue.cueId != widget.cue.cueId) {
      _debounce?.cancel();
      _disposeControllers();
      _initFrom(widget.cue);
    }
  }

  void _initFrom(Cue cue) {
    _working = cue.deepCopy();
    _dirty = false;
    _saving = false;
    _numberCtrl = TextEditingController(text: cue.number);
    _labelCtrl = TextEditingController(text: cue.label);
    _preWaitCtrl = TextEditingController(text: cue.preWaitMs.toString());
    _postWaitCtrl = TextEditingController(text: cue.postWaitMs.toString());
  }

  void _disposeControllers() {
    _numberCtrl.dispose();
    _labelCtrl.dispose();
    _preWaitCtrl.dispose();
    _postWaitCtrl.dispose();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _disposeControllers();
    super.dispose();
  }

  void _change(void Function() mutate) {
    setState(() {
      mutate();
      _dirty = true;
    });
    _scheduleSave();
  }

  void _scheduleSave() {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 350), _flush);
  }

  Future<void> _flush() async {
    if (!_dirty || !mounted) return;
    setState(() { _saving = true; _dirty = false; });
    widget.onSave(_working.deepCopy());
    await Future.delayed(const Duration(milliseconds: 400));
    if (mounted) setState(() => _saving = false);
  }

  @override
  Widget build(BuildContext context) {
    final audioNodes = widget.connectedNodes
        .where((n) =>
            n.tasks.contains(NodeTask.NODE_TASK_AUDIO_OUTPUT) &&
            n.mediaServerUrl.isNotEmpty)
        .toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _Header(
          cue: _working,
          dirty: _dirty,
          saving: _saving,
        ),
        const Divider(height: 1, color: ScColors.divider),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _generalSection(),
                const SizedBox(height: 8),
                _buildTypeSection(audioNodes),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _generalSection() {
    return _Section(
      title: 'GENERAL',
      children: [
        _PropRow(
          label: 'Number',
          child: _InlineField(
            controller: _numberCtrl,
            onChanged: (v) => _change(() => _working.number = v),
          ),
        ),
        _PropRow(
          label: 'Label',
          child: _InlineField(
            controller: _labelCtrl,
            onChanged: (v) => _change(() => _working.label = v),
          ),
        ),
        _PropRow(
          label: 'Pre-Wait',
          child: _DurationField(
            value: _working.preWaitMs,
            controller: _preWaitCtrl,
            onChanged: (v) => _change(() => _working.preWaitMs = v),
          ),
        ),
        _PropRow(
          label: 'Post-Wait',
          child: _DurationField(
            value: _working.postWaitMs,
            controller: _postWaitCtrl,
            onChanged: (v) => _change(() => _working.postWaitMs = v),
          ),
        ),
        _PropRow(
          label: 'Auto-Cont.',
          child: _Toggle(
            value: _working.autoContinue,
            onChanged: (v) => _change(() => _working.autoContinue = v),
          ),
        ),
        if (widget.connectedNodes.isNotEmpty)
          _PropRow(
            label: 'Target',
            child: _NodeDropdown(
              currentId: _working.targetNodeId,
              nodes: widget.connectedNodes,
              onChanged: (id) => _change(() => _working.targetNodeId = id),
            ),
          ),
      ],
    );
  }

  Widget _buildTypeSection(List<NodeInfo> audioNodes) => switch (_working.cueType) {
        CueType.CUE_TYPE_AUDIO => _AudioSection(
            params: _working.hasAudio() ? _working.audio : AudioCueParams(),
            audioNodes: audioNodes,
            onChanged: (p) => _change(() => _working.audio = p),
          ),
        CueType.CUE_TYPE_MA_OSC => _MaOscSection(
            params: _working.hasMaOsc() ? _working.maOsc : MaOscCueParams(),
            onChanged: (p) => _change(() => _working.maOsc = p),
          ),
        CueType.CUE_TYPE_WAIT => _WaitSection(
            params: _working.hasWait() ? _working.wait : WaitCueParams(),
            onChanged: (p) => _change(() => _working.wait = p),
          ),
        CueType.CUE_TYPE_GOTO => _GotoSection(
            params: _working.hasGotoP() ? _working.gotoP : GotoCueParams(),
            onChanged: (p) => _change(() => _working.gotoP = p),
          ),
        _ => const SizedBox.shrink(),
      };
}

// ── Header ────────────────────────────────────────────────────────────────────

class _Header extends StatelessWidget {
  final Cue cue;
  final bool dirty;
  final bool saving;

  const _Header({
    required this.cue,
    required this.dirty,
    required this.saving,
  });

  @override
  Widget build(BuildContext context) {
    final (typeLabel, typeColor) = _typeInfo(cue.cueType);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      color: ScColors.surface,
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
            decoration: BoxDecoration(
              color: typeColor.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(4),
              border: Border.all(color: typeColor.withValues(alpha: 0.4)),
            ),
            child: Text(typeLabel,
                style: TextStyle(
                    color: typeColor,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5)),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Cue ${cue.number}${cue.label.isNotEmpty ? " — ${cue.label}" : ""}',
              style: ScText.sectionTitle,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          // Auto-save indicator
          if (saving)
            const SizedBox(
              width: 12, height: 12,
              child: CircularProgressIndicator(strokeWidth: 1.5, color: ScColors.active),
            )
          else if (dirty)
            Container(
              width: 6, height: 6,
              decoration: const BoxDecoration(
                  color: ScColors.warn, shape: BoxShape.circle),
            ),
        ],
      ),
    );
  }

  static (String, Color) _typeInfo(CueType t) => switch (t) {
        CueType.CUE_TYPE_AUDIO  => ('AUDIO', const Color(0xFF1E88E5)),
        CueType.CUE_TYPE_MA_OSC => ('MA',    const Color(0xFFF4511E)),
        CueType.CUE_TYPE_WAIT   => ('WAIT',  const Color(0xFF8E24AA)),
        CueType.CUE_TYPE_GOTO   => ('GOTO',  const Color(0xFF00ACC1)),
        CueType.CUE_TYPE_GROUP  => ('GROUP', const Color(0xFF00897B)),
        _                       => ('?',     ScColors.textDim),
      };
}

// ── Audio section ─────────────────────────────────────────────────────────────

class _AudioSection extends StatefulWidget {
  final AudioCueParams params;
  final ValueChanged<AudioCueParams> onChanged;
  final List<NodeInfo> audioNodes;

  const _AudioSection({
    required this.params,
    required this.onChanged,
    required this.audioNodes,
  });

  @override
  State<_AudioSection> createState() => _AudioSectionState();
}

class _AudioSectionState extends State<_AudioSection> {
  late AudioCueParams _p;
  late TextEditingController _fadeInCtrl;
  late TextEditingController _fadeOutCtrl;
  late TextEditingController _startCtrl;
  late TextEditingController _endCtrl;
  bool _uploading = false;
  String? _uploadStatus;

  @override
  void initState() {
    super.initState();
    _p = widget.params.deepCopy();
    _fadeInCtrl = TextEditingController(text: _p.fadeInMs.toStringAsFixed(0));
    _fadeOutCtrl = TextEditingController(text: _p.fadeOutMs.toStringAsFixed(0));
    _startCtrl = TextEditingController(text: _p.startTimeMs.toStringAsFixed(0));
    _endCtrl = TextEditingController(text: _p.endTimeMs.toStringAsFixed(0));
  }

  @override
  void dispose() {
    _fadeInCtrl.dispose();
    _fadeOutCtrl.dispose();
    _startCtrl.dispose();
    _endCtrl.dispose();
    super.dispose();
  }

  void _emit() => widget.onChanged(_p.deepCopy());

  String get _durationHint {
    if (_p.declaredDurationMs > 0) {
      final s = _p.declaredDurationMs / 1000;
      return s < 60
          ? '${s.toStringAsFixed(1)}s'
          : '${(s / 60).floor()}:${(s % 60).toStringAsFixed(0).padLeft(2, "0")}';
    }
    return '';
  }

  @override
  Widget build(BuildContext context) {
    return _Section(
      title: 'AUDIO',
      children: [
        // File row
        Row(
          children: [
            Expanded(
              child: _FilenameDisplay(
                filename: _p.filePath,
                duration: _durationHint,
              ),
            ),
            const SizedBox(width: 6),
            if (_uploading)
              const SizedBox(
                  width: 28,
                  height: 28,
                  child: CircularProgressIndicator(strokeWidth: 2))
            else ...[
              _IconBtn(
                icon: Icons.folder_open,
                tooltip: 'Lokale Datei wählen',
                enabled: widget.audioNodes.isNotEmpty,
                onPressed: _pickAndUpload,
              ),
              const SizedBox(width: 4),
              _IconBtn(
                icon: Icons.cloud_download_outlined,
                tooltip: 'Server-Bibliothek',
                enabled: widget.audioNodes.isNotEmpty,
                onPressed: () => _openMediaBrowser(context),
              ),
            ],
          ],
        ),
        if (_uploadStatus != null)
          Text(_uploadStatus!,
              style: TextStyle(
                fontSize: 10,
                color: _uploadStatus!.startsWith('✓')
                    ? ScColors.active
                    : _uploadStatus!.startsWith('✗')
                        ? ScColors.error
                        : ScColors.warn,
              )),
        if (widget.audioNodes.isEmpty)
          Text('Kein Audio-Node verbunden.',
              style: ScText.label.copyWith(color: ScColors.warn)),
        const SizedBox(height: 4),
        // Volume
        _VolumeRow(
          volumeDb: _p.volumeDb,
          onChanged: (v) {
            setState(() => _p.volumeDb = v);
            _emit();
          },
        ),
        const SizedBox(height: 2),
        // Fades in one row
        Row(
          children: [
            Expanded(
              child: _PropRow(
                label: 'Fade In',
                child: _DurationField(
                  value: _p.fadeInMs,
                  controller: _fadeInCtrl,
                  onChanged: (v) { _p.fadeInMs = v; _emit(); },
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _PropRow(
                label: 'Fade Out',
                child: _DurationField(
                  value: _p.fadeOutMs,
                  controller: _fadeOutCtrl,
                  onChanged: (v) { _p.fadeOutMs = v; _emit(); },
                ),
              ),
            ),
          ],
        ),
        // Trim
        Row(
          children: [
            Expanded(
              child: _PropRow(
                label: 'Start',
                child: _DurationField(
                  value: _p.startTimeMs,
                  controller: _startCtrl,
                  onChanged: (v) { _p.startTimeMs = v; _emit(); },
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _PropRow(
                label: 'End',
                child: _DurationField(
                  value: _p.endTimeMs,
                  controller: _endCtrl,
                  onChanged: (v) { _p.endTimeMs = v; _emit(); },
                ),
              ),
            ),
          ],
        ),
        _PropRow(
          label: 'Loop',
          child: _Toggle(
            value: _p.loop,
            onChanged: (v) {
              setState(() => _p.loop = v);
              _emit();
            },
          ),
        ),
      ],
    );
  }

  Future<void> _pickAndUpload() async {
    final result = await FilePicker.pickFiles(type: FileType.audio);
    if (result == null) return;
    final file = result.files.single;
    final filename = p.basename(file.name);
    Uint8List bytes;
    if (file.path != null) {
      bytes = await File(file.path!).readAsBytes();
    } else if (file.bytes != null) {
      bytes = file.bytes!;
    } else {
      return;
    }
    setState(() { _uploading = true; _uploadStatus = 'Lade hoch…'; });
    try {
      await MediaGrpcClient().uploadFile(filename, bytes);
      setState(() {
        _uploading = false;
        _uploadStatus = '✓ "$filename" gespeichert';
        _p.filePath = filename;
        _emit();
      });
    } catch (e) {
      setState(() { _uploading = false; _uploadStatus = '✗ $e'; });
    }
  }

  Future<void> _openMediaBrowser(BuildContext context) async {
    final previewUrl = widget.audioNodes
        .map((n) => n.mediaServerUrl)
        .firstWhere((u) => u.isNotEmpty, orElse: () => '');
    final selected = await showDialog<String>(
      context: context,
      builder: (_) => _MediaBrowserDialog(
          previewBaseUrl: previewUrl.isEmpty ? null : previewUrl),
    );
    if (selected != null) {
      setState(() { _p.filePath = selected; });
      _emit();
    }
  }
}

// ── MA-OSC section ────────────────────────────────────────────────────────────

class _MaOscSection extends StatefulWidget {
  final MaOscCueParams params;
  final ValueChanged<MaOscCueParams> onChanged;
  const _MaOscSection({required this.params, required this.onChanged});

  @override
  State<_MaOscSection> createState() => _MaOscSectionState();
}

class _MaOscSectionState extends State<_MaOscSection> {
  late MaOscCueParams _p;
  late TextEditingController _addrCtrl;
  late TextEditingController _argCtrl;
  late TextEditingController _pageCtrl;
  late TextEditingController _execCtrl;

  @override
  void initState() {
    super.initState();
    _p = widget.params.deepCopy();
    _addrCtrl = TextEditingController(text: _p.oscAddress);
    _argCtrl = TextEditingController(text: _p.oscArgument);
    _pageCtrl = TextEditingController(text: _p.executorPage.toString());
    _execCtrl = TextEditingController(text: _p.executorNo.toString());
  }

  @override
  void dispose() {
    _addrCtrl.dispose();
    _argCtrl.dispose();
    _pageCtrl.dispose();
    _execCtrl.dispose();
    super.dispose();
  }

  void _emit() => widget.onChanged(_p.deepCopy());

  @override
  Widget build(BuildContext context) {
    return _Section(title: 'MA-OSC', children: [
      _PropRow(
        label: 'Address',
        child: _InlineField(
          controller: _addrCtrl,
          hint: '/gma3/cmd',
          onChanged: (v) { _p.oscAddress = v; _emit(); },
        ),
      ),
      _PropRow(
        label: 'Argument',
        child: _InlineField(
          controller: _argCtrl,
          hint: 'Executor 1 Go',
          onChanged: (v) { _p.oscArgument = v; _emit(); },
        ),
      ),
      Row(children: [
        Expanded(child: _PropRow(
          label: 'Page',
          child: _InlineField(
            controller: _pageCtrl,
            numeric: true,
            onChanged: (v) { _p.executorPage = int.tryParse(v) ?? 0; _emit(); },
          ),
        )),
        const SizedBox(width: 8),
        Expanded(child: _PropRow(
          label: 'Executor',
          child: _InlineField(
            controller: _execCtrl,
            numeric: true,
            onChanged: (v) { _p.executorNo = int.tryParse(v) ?? 0; _emit(); },
          ),
        )),
      ]),
      _PropRow(
        label: 'Command',
        child: _CompactDropdown<MaOscCueParams_MaCommand>(
          value: _p.command,
          items: const [
            (MaOscCueParams_MaCommand.MA_CMD_GO, 'Go'),
            (MaOscCueParams_MaCommand.MA_CMD_OFF, 'Off'),
            (MaOscCueParams_MaCommand.MA_CMD_PAUSE, 'Pause'),
            (MaOscCueParams_MaCommand.MA_CMD_GOTO, 'Goto Cue'),
          ],
          onChanged: (v) { if (v != null) { setState(() => _p.command = v); _emit(); } },
        ),
      ),
    ]);
  }
}

// ── Wait section ──────────────────────────────────────────────────────────────

class _WaitSection extends StatefulWidget {
  final WaitCueParams params;
  final ValueChanged<WaitCueParams> onChanged;
  const _WaitSection({required this.params, required this.onChanged});

  @override
  State<_WaitSection> createState() => _WaitSectionState();
}

class _WaitSectionState extends State<_WaitSection> {
  late TextEditingController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = TextEditingController(
        text: widget.params.durationMs.toStringAsFixed(0));
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ms = double.tryParse(_ctrl.text) ?? 0;
    return _Section(title: 'WAIT', children: [
      _PropRow(
        label: 'Duration',
        child: _DurationField(
          value: widget.params.durationMs,
          controller: _ctrl,
          onChanged: (v) {
            widget.onChanged(WaitCueParams()..durationMs = v);
          },
        ),
      ),
      Text(
        '${(ms / 1000).toStringAsFixed(2)} s',
        style: ScText.label,
      ),
    ]);
  }
}

// ── Goto section ──────────────────────────────────────────────────────────────

class _GotoSection extends StatefulWidget {
  final GotoCueParams params;
  final ValueChanged<GotoCueParams> onChanged;
  const _GotoSection({required this.params, required this.onChanged});

  @override
  State<_GotoSection> createState() => _GotoSectionState();
}

class _GotoSectionState extends State<_GotoSection> {
  late TextEditingController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = TextEditingController(text: widget.params.targetNumber);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return _Section(title: 'GOTO', children: [
      _PropRow(
        label: 'Target',
        child: _InlineField(
          controller: _ctrl,
          hint: 'Cue-Nummer',
          onChanged: (v) =>
              widget.onChanged(GotoCueParams()..targetNumber = v),
        ),
      ),
    ]);
  }
}

// ── Volume row ────────────────────────────────────────────────────────────────

class _VolumeRow extends StatelessWidget {
  final double volumeDb;
  final ValueChanged<double> onChanged;

  const _VolumeRow({required this.volumeDb, required this.onChanged});

  Color _color(double db) {
    if (db > 3) return ScColors.error;
    if (db > 0) return ScColors.warn;
    return ScColors.active;
  }

  String _label(double db) {
    if (db <= -60) return '−∞ dB';
    return '${db > 0 ? "+" : ""}${db.toStringAsFixed(1)} dB';
  }

  @override
  Widget build(BuildContext context) {
    final clamped = volumeDb.clamp(-60.0, 6.0);
    return _PropRow(
      label: 'Volume',
      child: Row(
        children: [
          Expanded(
            child: SliderTheme(
              data: SliderThemeData(
                trackHeight: 3,
                thumbShape:
                    const RoundSliderThumbShape(enabledThumbRadius: 6),
                overlayShape:
                    const RoundSliderOverlayShape(overlayRadius: 10),
                activeTrackColor: _color(clamped),
                thumbColor: _color(clamped),
                inactiveTrackColor: ScColors.divider,
              ),
              child: Slider(
                value: clamped,
                min: -60,
                max: 6,
                divisions: 66,
                onChanged: onChanged,
              ),
            ),
          ),
          const SizedBox(width: 4),
          Container(
            width: 58,
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: _color(clamped).withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(4),
              border:
                  Border.all(color: _color(clamped).withValues(alpha: 0.4)),
            ),
            child: Text(
              _label(clamped),
              style: TextStyle(
                color: _color(clamped),
                fontWeight: FontWeight.bold,
                fontFeatures: const [FontFeature.tabularFigures()],
                fontSize: 11,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Filename display ──────────────────────────────────────────────────────────

class _FilenameDisplay extends StatelessWidget {
  final String filename;
  final String duration;
  const _FilenameDisplay({required this.filename, required this.duration});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: ScColors.surface,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: ScColors.divider),
      ),
      child: Row(
        children: [
          Icon(Icons.audio_file_outlined, size: 14, color: ScColors.textDim),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              filename.isEmpty ? 'No file' : filename,
              style: ScText.label.copyWith(
                color: filename.isEmpty
                    ? ScColors.textDim
                    : ScColors.textSecondary,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          if (duration.isNotEmpty) ...[
            const SizedBox(width: 6),
            Text(duration, style: ScText.numberSmall),
          ],
        ],
      ),
    );
  }
}

// ── Shared layout primitives ──────────────────────────────────────────────────

class _Section extends StatelessWidget {
  final String title;
  final List<Widget> children;

  const _Section({required this.title, required this.children});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 6),
          child: Text(title, style: ScText.panelTitle),
        ),
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: ScColors.surface,
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: ScColors.divider),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (int i = 0; i < children.length; i++) ...[
                children[i],
                if (i < children.length - 1) const SizedBox(height: 6),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

/// Two-column property row: [label] [control].
class _PropRow extends StatelessWidget {
  final String label;
  final Widget child;

  const _PropRow({required this.label, required this.child});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        SizedBox(
          width: 68,
          child: Text(label, style: ScText.label),
        ),
        const SizedBox(width: 6),
        Expanded(child: child),
      ],
    );
  }
}

/// Compact single-line text field (no label decoration — label is in _PropRow).
class _InlineField extends StatelessWidget {
  final TextEditingController controller;
  final String? hint;
  final bool numeric;
  final ValueChanged<String>? onChanged;

  const _InlineField({
    required this.controller,
    this.hint,
    this.numeric = false,
    this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      onChanged: onChanged,
      keyboardType: numeric ? TextInputType.number : TextInputType.text,
      style: ScText.cueLabel.copyWith(fontSize: 13),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: ScText.label,
        isDense: true,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
        filled: true,
        fillColor: ScColors.bg,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(4),
          borderSide: const BorderSide(color: ScColors.divider),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(4),
          borderSide: const BorderSide(color: ScColors.divider),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(4),
          borderSide:
              const BorderSide(color: ScColors.active, width: 1.5),
        ),
      ),
    );
  }
}

/// Duration field: shows ms value, accepts numeric input.
class _DurationField extends StatelessWidget {
  final double value;
  final TextEditingController controller;
  final ValueChanged<double> onChanged;

  const _DurationField({
    required this.value,
    required this.controller,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _InlineField(
            controller: controller,
            numeric: true,
            onChanged: (v) => onChanged(double.tryParse(v) ?? 0),
          ),
        ),
        const SizedBox(width: 4),
        Text('ms', style: ScText.statusSmall),
      ],
    );
  }
}

/// Compact on/off toggle.
class _Toggle extends StatelessWidget {
  final bool value;
  final ValueChanged<bool> onChanged;

  const _Toggle({required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        GestureDetector(
          onTap: () => onChanged(!value),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            width: 36,
            height: 18,
            decoration: BoxDecoration(
              color: value ? ScColors.active : ScColors.divider,
              borderRadius: BorderRadius.circular(9),
            ),
            child: Align(
              alignment:
                  value ? Alignment.centerRight : Alignment.centerLeft,
              child: Padding(
                padding: const EdgeInsets.all(2),
                child: Container(
                  width: 14,
                  height: 14,
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 6),
        Text(
          value ? 'On' : 'Off',
          style: ScText.label.copyWith(
              color: value ? ScColors.active : ScColors.textDim),
        ),
      ],
    );
  }
}

/// Compact dropdown.
class _CompactDropdown<T> extends StatelessWidget {
  final T value;
  final List<(T, String)> items;
  final ValueChanged<T?> onChanged;

  const _CompactDropdown({
    required this.value,
    required this.items,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        color: ScColors.bg,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: ScColors.divider),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<T>(
          value: value,
          isDense: true,
          dropdownColor: ScColors.surface2,
          style: ScText.cueLabel.copyWith(fontSize: 13),
          items: items
              .map((e) => DropdownMenuItem(
                    value: e.$1,
                    child: Text(e.$2),
                  ))
              .toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }
}

/// Node dropdown (target-node picker).
class _NodeDropdown extends StatelessWidget {
  final String currentId;
  final List<NodeInfo> nodes;
  final ValueChanged<String> onChanged;

  const _NodeDropdown({
    required this.currentId,
    required this.nodes,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final selectedId = nodes.any((n) => n.nodeId == currentId) ? currentId : '';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        color: ScColors.bg,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: ScColors.divider),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: selectedId,
          isDense: true,
          isExpanded: true,
          dropdownColor: ScColors.surface2,
          style: ScText.label.copyWith(fontSize: 12),
          items: [
            const DropdownMenuItem(
                value: '', child: Text('— Automatisch —')),
            ...nodes.map((n) => DropdownMenuItem(
                  value: n.nodeId,
                  child: Row(
                    children: [
                      Icon(
                        n.tasks.contains(NodeTask.NODE_TASK_AUDIO_OUTPUT)
                            ? Icons.volume_up
                            : Icons.devices,
                        size: 12,
                        color: n.online ? ScColors.active : ScColors.textDim,
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                          child: Text(n.name,
                              overflow: TextOverflow.ellipsis)),
                    ],
                  ),
                )),
          ],
          onChanged: (v) => onChanged(v ?? ''),
        ),
      ),
    );
  }
}

class _IconBtn extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final bool enabled;
  final VoidCallback? onPressed;

  const _IconBtn({
    required this.icon,
    required this.tooltip,
    this.enabled = true,
    this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        borderRadius: BorderRadius.circular(4),
        onTap: enabled ? onPressed : null,
        child: Padding(
          padding: const EdgeInsets.all(6),
          child: Icon(icon,
              size: 18,
              color: enabled ? ScColors.textSecondary : ScColors.textDim),
        ),
      ),
    );
  }
}

// ── Media browser dialog ──────────────────────────────────────────────────────

class _MediaBrowserDialog extends StatefulWidget {
  final String? previewBaseUrl;
  const _MediaBrowserDialog({this.previewBaseUrl});

  @override
  State<_MediaBrowserDialog> createState() => _MediaBrowserDialogState();
}

class _MediaBrowserDialogState extends State<_MediaBrowserDialog> {
  final _grpc = MediaGrpcClient();
  List<MediaFile> _files = [];
  bool _loading = true;
  bool _uploading = false;
  String? _error;
  String? _previewing;

  @override
  void initState() {
    super.initState();
    _loadFiles();
  }

  Future<void> _loadFiles() async {
    setState(() { _loading = true; _error = null; });
    try {
      final snapshot = await _grpc.watchManifest().first;
      setState(() { _files = snapshot.assets; _loading = false; });
    } catch (e) {
      setState(() { _error = e.toString(); _loading = false; });
    }
  }

  Future<void> _uploadFile() async {
    final result = await FilePicker.pickFiles(type: FileType.audio);
    if (result == null || result.files.single.path == null) return;
    setState(() => _uploading = true);
    try {
      final file = File(result.files.single.path!);
      final filename = result.files.single.name;
      final bytes = await file.readAsBytes();
      await _grpc.uploadFile(filename, bytes);
      await _loadFiles();
    } catch (e) {
      setState(() => _error = 'Upload: $e');
    } finally {
      if (mounted) setState(() => _uploading = false);
    }
  }

  Future<void> _deleteFile(String filename) async {
    try {
      await _grpc.deleteFile(filename);
    } catch (e) {
      setState(() => _error = 'Löschen: $e');
    }
    if (_previewing == filename) setState(() => _previewing = null);
    await _loadFiles();
  }

  Future<void> _preview(String filename) async {
    final base = widget.previewBaseUrl;
    if (base == null) return;
    setState(() => _previewing = filename);
    try {
      await http.get(
          Uri.parse('$base/media/preview/${Uri.encodeComponent(filename)}'));
    } catch (e) {
      if (mounted) setState(() => _error = 'Vorhören: $e');
    }
  }

  Future<void> _stopPreview() async {
    final base = widget.previewBaseUrl;
    if (base != null) {
      try { await http.delete(Uri.parse('$base/media/preview')); } catch (_) {}
    }
    if (mounted) setState(() => _previewing = null);
  }

  String _fmtSize(int bytes) {
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(0)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  @override
  void dispose() {
    _stopPreview().ignore();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: ScColors.surface,
      title: Row(
        children: [
          const Expanded(child: Text('Medienbibliothek')),
          if (_uploading)
            const SizedBox(
                width: 20, height: 20,
                child: CircularProgressIndicator(strokeWidth: 2))
          else
            IconButton(
                icon: const Icon(Icons.upload_file),
                tooltip: 'Hochladen',
                onPressed: _uploadFile),
          IconButton(
              icon: const Icon(Icons.refresh),
              tooltip: 'Aktualisieren',
              onPressed: _loadFiles),
        ],
      ),
      content: SizedBox(
        width: 480, height: 420,
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : Column(
                children: [
                  if (_error != null)
                    Container(
                      padding: const EdgeInsets.all(8),
                      margin: const EdgeInsets.only(bottom: 8),
                      decoration: BoxDecoration(
                        color: ScColors.error.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(_error!,
                          style: const TextStyle(
                              color: ScColors.error, fontSize: 12)),
                    ),
                  Expanded(
                    child: _files.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.audio_file_outlined,
                                    size: 48, color: ScColors.textDim),
                                const SizedBox(height: 8),
                                Text('Keine Dateien',
                                    style: ScText.label),
                                const SizedBox(height: 16),
                                FilledButton.icon(
                                  icon: const Icon(Icons.upload_file),
                                  label: const Text('Datei hochladen'),
                                  onPressed: _uploading ? null : _uploadFile,
                                ),
                              ],
                            ),
                          )
                        : ListView.builder(
                            itemCount: _files.length,
                            itemBuilder: (ctx, i) {
                              final f = _files[i];
                              final isPreviewing = _previewing == f.name;
                              return ListTile(
                                dense: true,
                                leading: Icon(
                                  isPreviewing
                                      ? Icons.volume_up
                                      : Icons.audio_file,
                                  color: isPreviewing
                                      ? ScColors.active
                                      : ScColors.textDim,
                                  size: 18,
                                ),
                                title: Text(f.name,
                                    overflow: TextOverflow.ellipsis,
                                    style: ScText.cueLabel
                                        .copyWith(fontSize: 13)),
                                subtitle: Text(_fmtSize(f.sizeBytes),
                                    style: ScText.statusSmall),
                                trailing: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    if (widget.previewBaseUrl != null)
                                      IconButton(
                                        icon: Icon(isPreviewing
                                            ? Icons.stop
                                            : Icons.play_arrow,
                                            size: 18),
                                        onPressed: isPreviewing
                                            ? _stopPreview
                                            : () => _preview(f.name),
                                      ),
                                    IconButton(
                                      icon: const Icon(Icons.check,
                                          color: ScColors.active, size: 18),
                                      onPressed: () =>
                                          Navigator.of(context).pop(f.name),
                                    ),
                                    IconButton(
                                      icon: const Icon(
                                          Icons.delete_outline,
                                          color: ScColors.error,
                                          size: 18),
                                      onPressed: () =>
                                          _confirmDelete(ctx, f.name),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                  ),
                ],
              ),
      ),
      actions: [
        if (_previewing != null)
          TextButton.icon(
            icon: const Icon(Icons.stop),
            label: const Text('Stoppen'),
            onPressed: _stopPreview,
          ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Schließen'),
        ),
      ],
    );
  }

  Future<void> _confirmDelete(BuildContext context, String filename) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Datei löschen?'),
        content: Text('"$filename" wird vom Server gelöscht.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Abbrechen')),
          FilledButton(
            style: FilledButton.styleFrom(
                backgroundColor: ScColors.error),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Löschen'),
          ),
        ],
      ),
    );
    if (ok == true) await _deleteFile(filename);
  }
}
