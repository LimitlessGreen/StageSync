import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../nodes/audio_node/audio_node_service.dart'
    show AudioNodeState, AudioNodeStatus;
import '../../../providers/audio_node_provider.dart';
import '../../../providers/session_provider.dart';
import '../../design_system/sc_colors.dart';
import '../../design_system/sc_spacing.dart';
import '../../design_system/sc_typography.dart';
import '../../design_system/primitives/sc_button.dart';

/// Desktop panel for local audio node management.
/// Compact DAW-style layout: device list as selectable rows, inline controls.
class LocalAudioPanel extends ConsumerStatefulWidget {
  const LocalAudioPanel({super.key});

  @override
  ConsumerState<LocalAudioPanel> createState() => _LocalAudioPanelState();
}

class _LocalAudioPanelState extends ConsumerState<LocalAudioPanel> {
  bool _refreshing = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        ref.read(audioNodeProvider.notifier).ensureEngineInitialized();
      }
    });
  }

  Future<void> _refresh() async {
    setState(() => _refreshing = true);
    await ref.read(audioNodeProvider.notifier).ensureEngineInitialized();
    if (mounted) setState(() => _refreshing = false);
  }

  @override
  Widget build(BuildContext context) {
    final audioStatus = ref.watch(audioNodeProvider);
    final session     = ref.watch(sessionProvider);
    final isRunning   = audioStatus.state == AudioNodeState.connected;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // ── Toolbar: title + status + engine toggle ───────────────────────
        _AudioToolbar(
          state: audioStatus.state,
          isInSession: session.isInSession,
          isRunning: isRunning,
          refreshing: _refreshing,
          onRefresh: _refresh,
          onStart:  () => ref.read(audioNodeProvider.notifier).startAudioNode(),
          onStop:   () => ref.read(audioNodeProvider.notifier).stopAudioNode(),
        ),
        const Divider(height: 1, color: ScColors.divider),
        Expanded(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Left: device list ───────────────────────────────────────
              Expanded(
                flex: 3,
                child: _DeviceListColumn(
                  devices: audioStatus.availableDevices,
                  selected: audioStatus.selectedDevice,
                  onSelect: (d) =>
                      ref.read(audioNodeProvider.notifier).selectDevice(d),
                  onRefresh: _refresh,
                ),
              ),
              const VerticalDivider(width: 1, color: ScColors.divider),
              // ── Right: status + active cues + backend info ──────────────
              Expanded(
                flex: 2,
                child: _StatusColumn(audioStatus: audioStatus),
              ),
            ],
          ),
        ),
        // ── Error banner ─────────────────────────────────────────────────
        if (audioStatus.errorMessage != null)
          _ErrorBanner(message: audioStatus.errorMessage!),
      ],
    );
  }
}

// ── Toolbar ────────────────────────────────────────────────────────────────────

class _AudioToolbar extends StatelessWidget {
  final AudioNodeState state;
  final bool isInSession;
  final bool isRunning;
  final bool refreshing;
  final VoidCallback onRefresh;
  final VoidCallback onStart;
  final VoidCallback onStop;

  const _AudioToolbar({
    required this.state,
    required this.isInSession,
    required this.isRunning,
    required this.refreshing,
    required this.onRefresh,
    required this.onStart,
    required this.onStop,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 36,
      color: ScColors.surface,
      padding: const EdgeInsets.symmetric(horizontal: ScSpacing.panelPad),
      child: Row(
        children: [
          Text('AUDIO-AUSGABE', style: ScText.panelTitle),
          const SizedBox(width: 10),
          _StatusDot(state: state),
          const Spacer(),
          // Engine start/stop
          if (isInSession && !isRunning)
            ScButton(
              label: 'Starten',
              variant: ScButtonVariant.primary,
              size: ScButtonSize.compact,
              onPressed: onStart,
            ),
          if (isRunning)
            ScButton(
              label: 'Stoppen',
              variant: ScButtonVariant.danger,
              size: ScButtonSize.compact,
              onPressed: onStop,
            ),
          const SizedBox(width: 8),
          Tooltip(
            message: 'Geräte aktualisieren',
            child: InkWell(
              onTap: refreshing ? null : onRefresh,
              borderRadius: BorderRadius.circular(4),
              child: Padding(
                padding: const EdgeInsets.all(4),
                child: Icon(
                  Icons.refresh,
                  size: 14,
                  color: refreshing ? ScColors.textDim : ScColors.textSecondary,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusDot extends StatelessWidget {
  final AudioNodeState state;
  const _StatusDot({required this.state});

  @override
  Widget build(BuildContext context) {
    final (color, label) = switch (state) {
      AudioNodeState.connected => (ScColors.active, 'AKTIV'),
      AudioNodeState.error     => (ScColors.error,  'FEHLER'),
      AudioNodeState.idle      => (ScColors.past,   'INAKTIV'),
    };
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 6, height: 6,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 5),
        Text(label, style: ScText.status.copyWith(color: color, fontSize: 10)),
      ],
    );
  }
}

// ── Device list column ─────────────────────────────────────────────────────────

class _DeviceListColumn extends StatelessWidget {
  final List<AudioDevice> devices;
  final AudioDevice? selected;
  final ValueChanged<AudioDevice> onSelect;
  final VoidCallback onRefresh;

  const _DeviceListColumn({
    required this.devices,
    required this.selected,
    required this.onSelect,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Section header
        Container(
          height: 28,
          color: ScColors.surface,
          padding: const EdgeInsets.symmetric(horizontal: ScSpacing.panelPad),
          alignment: Alignment.centerLeft,
          child: Text('AUSGABEGERÄTE', style: ScText.panelTitle),
        ),
        const Divider(height: 1, color: ScColors.divider),
        if (devices.isEmpty)
          Padding(
            padding: const EdgeInsets.all(ScSpacing.panelPad),
            child: Text(
              'Keine Geräte — Engine starten oder aktualisieren.',
              style: ScText.label.copyWith(color: ScColors.textDim),
            ),
          )
        else
          Expanded(
            child: ListView.builder(
              itemCount: devices.length,
              itemBuilder: (context, i) => _DeviceRow(
                device: devices[i],
                isSelected: devices[i].name == selected?.name,
                onTap: () => onSelect(devices[i]),
              ),
            ),
          ),
      ],
    );
  }
}

class _DeviceRow extends StatefulWidget {
  final AudioDevice device;
  final bool isSelected;
  final VoidCallback onTap;

  const _DeviceRow({
    required this.device,
    required this.isSelected,
    required this.onTap,
  });

  @override
  State<_DeviceRow> createState() => _DeviceRowState();
}

class _DeviceRowState extends State<_DeviceRow> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final d = widget.device;
    final bg = widget.isSelected
        ? ScColors.active.withValues(alpha: 0.08)
        : _hovered
            ? ScColors.hover
            : Colors.transparent;

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit:  (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: Container(
          height: 30,
          color: bg,
          padding: const EdgeInsets.symmetric(horizontal: ScSpacing.panelPad),
          child: Row(
            children: [
              // Selection indicator
              SizedBox(
                width: 12,
                child: widget.isSelected
                    ? Container(
                        width: 4, height: 4,
                        decoration: const BoxDecoration(
                          color: ScColors.active,
                          shape: BoxShape.circle,
                        ),
                      )
                    : null,
              ),
              // Backend icon
              Icon(_backendIcon(d.backend), size: 12, color: ScColors.textDim),
              const SizedBox(width: 8),
              // Name
              Expanded(
                child: Text(
                  d.name,
                  style: ScText.label.copyWith(
                    color: widget.isSelected
                        ? ScColors.textPrimary
                        : ScColors.textSecondary,
                    fontWeight: widget.isSelected ? FontWeight.w600 : null,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              // Backend badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                decoration: BoxDecoration(
                  color: ScColors.surface2,
                  borderRadius: BorderRadius.circular(2),
                ),
                child: Text(
                  d.backend.name.toUpperCase(),
                  style: ScText.statusSmall.copyWith(fontSize: 9, letterSpacing: 0.3),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  IconData _backendIcon(AudioBackend b) => switch (b) {
    AudioBackend.asio      => Icons.speed,
    AudioBackend.wasapi    => Icons.speaker,
    AudioBackend.coreAudio => Icons.apple,
    AudioBackend.alsa      => Icons.speaker,
    AudioBackend.aaudio    => Icons.phone_android,
    AudioBackend.openSLES  => Icons.phone_android,
    _                      => Icons.volume_up,
  };
}

// ── Status column ──────────────────────────────────────────────────────────────

class _StatusColumn extends StatelessWidget {
  final AudioNodeStatus audioStatus;

  const _StatusColumn({required this.audioStatus});

  @override
  Widget build(BuildContext context) {
    final selected = audioStatus.selectedDevice;

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Selected device info
          Container(
            height: 28,
            color: ScColors.surface,
            padding: const EdgeInsets.symmetric(horizontal: ScSpacing.panelPad),
            alignment: Alignment.centerLeft,
            child: Text('AKTIVES GERÄT', style: ScText.panelTitle),
          ),
          const Divider(height: 1, color: ScColors.divider),
          if (selected != null) ...[
            _PropRow('Name',    selected.name),
            _PropRow('Backend', selected.backend.name.toUpperCase()),
            if (selected.index >= 0)
              _PropRow('Index', '${selected.index}'),
          ] else
            Padding(
              padding: const EdgeInsets.symmetric(
                  horizontal: ScSpacing.panelPad, vertical: 6),
              child: Text(
                'Kein Gerät ausgewählt',
                style: ScText.label.copyWith(color: ScColors.textDim),
              ),
            ),
          // Active cues
          if (audioStatus.playingCueIds.isNotEmpty) ...[
            const Divider(height: 1, color: ScColors.divider),
            Container(
              height: 28,
              color: ScColors.surface,
              padding: const EdgeInsets.symmetric(
                  horizontal: ScSpacing.panelPad),
              alignment: Alignment.centerLeft,
              child: Text('LÄUFT', style: ScText.panelTitle),
            ),
            const Divider(height: 1, color: ScColors.divider),
            ...audioStatus.playingCueIds.map(
              (id) => _PlayingRow(cueId: id),
            ),
          ],
        ],
      ),
    );
  }
}

class _PropRow extends StatelessWidget {
  final String label;
  final String value;
  const _PropRow(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 28,
      padding: const EdgeInsets.symmetric(horizontal: ScSpacing.panelPad),
      child: Row(
        children: [
          SizedBox(
            width: 52,
            child: Text(label, style: ScText.label),
          ),
          Expanded(
            child: Text(
              value,
              style: ScText.label.copyWith(
                  color: ScColors.textPrimary, fontWeight: FontWeight.w500),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

class _PlayingRow extends StatelessWidget {
  final String cueId;
  const _PlayingRow({required this.cueId});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 28,
      padding: const EdgeInsets.symmetric(horizontal: ScSpacing.panelPad),
      child: Row(
        children: [
          const Icon(Icons.play_arrow, size: 10, color: ScColors.active),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              cueId.length > 8 ? cueId.substring(0, 8) : cueId,
              style: ScText.label.copyWith(color: ScColors.textSecondary),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Error banner ──────────────────────────────────────────────────────────────

class _ErrorBanner extends StatelessWidget {
  final String message;
  const _ErrorBanner({required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
          horizontal: ScSpacing.panelPad, vertical: 6),
      color: ScColors.error.withValues(alpha: 0.12),
      child: Row(
        children: [
          const Icon(Icons.error_outline, size: 13, color: ScColors.error),
          const SizedBox(width: 8),
          Expanded(
              child: Text(message,
                  style: ScText.label.copyWith(color: ScColors.error))),
        ],
      ),
    );
  }
}
