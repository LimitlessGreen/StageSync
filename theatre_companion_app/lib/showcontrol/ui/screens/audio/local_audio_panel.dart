import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../nodes/audio_node/audio_node_service.dart'
    show AudioNodeState, AudioNodeStatus;
import '../../../preferences/device_preferences.dart';
import '../../../providers/audio_node_provider.dart';
import '../../../providers/session_provider.dart';
import '../../design_system/sc_colors.dart';
import '../../design_system/sc_spacing.dart';
import '../../design_system/sc_typography.dart';
import '../../design_system/primitives/sc_button.dart';
import '../../design_system/domain_components/master_volume_slider.dart';

/// Desktop-Panel für den lokalen Audio-Node.
/// DAW-orientiertes Layout: Gerätestatus oben, Geräteliste links, Details rechts.
class LocalAudioPanel extends ConsumerStatefulWidget {
  const LocalAudioPanel({super.key});

  @override
  ConsumerState<LocalAudioPanel> createState() => _LocalAudioPanelState();
}

class _LocalAudioPanelState extends ConsumerState<LocalAudioPanel> {
  bool _refreshing = false;
  bool _showFirstRunHint = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        ref.read(audioNodeProvider.notifier).ensureEngineInitialized();
        _checkFirstRun();
      }
    });
  }

  Future<void> _checkFirstRun() async {
    final done = await DevicePreferences.isAudioSetupDone();
    if (!done && mounted) setState(() => _showFirstRunHint = true);
  }

  Future<void> _refresh() async {
    setState(() => _refreshing = true);
    await ref.read(audioNodeProvider.notifier).ensureEngineInitialized();
    if (mounted) setState(() => _refreshing = false);
  }

  Future<void> _selectAndSaveDevice(AudioDevice device) async {
    ref.read(audioNodeProvider.notifier).selectDevice(device);
    await DevicePreferences.savePreferredAudioDeviceName(device.name);
    await DevicePreferences.markAudioSetupDone();
    if (mounted) setState(() => _showFirstRunHint = false);
  }

  @override
  Widget build(BuildContext context) {
    final audioStatus = ref.watch(audioNodeProvider);
    final session = ref.watch(sessionProvider);
    final isRunning = audioStatus.state == AudioNodeState.connected;
    final hasError = audioStatus.state == AudioNodeState.error;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // ── Engine-Status-Header ─────────────────────────────────────────────
        _EngineHeader(
          state: audioStatus.state,
          selectedDevice: audioStatus.selectedDevice,
          isInSession: session.isInSession,
          refreshing: _refreshing,
          onRefresh: _refresh,
          onStart: () => ref.read(audioNodeProvider.notifier).startAudioNode(),
          onStop: () => ref.read(audioNodeProvider.notifier).stopAudioNode(),
        ),
        const Divider(height: 1, color: ScColors.divider),

        // ── First-run Hinweis ─────────────────────────────────────────────────
        if (_showFirstRunHint && !isRunning)
          _FirstRunBanner(
            onDismiss: () async {
              await DevicePreferences.markAudioSetupDone();
              if (mounted) setState(() => _showFirstRunHint = false);
            },
          ),

        // ── Error-Banner ──────────────────────────────────────────────────────
        if (hasError && audioStatus.errorMessage != null)
          _ErrorBanner(message: audioStatus.errorMessage!),

        // ── Master-Volume (nur wenn aktiv) ────────────────────────────────────
        if (isRunning) ...[
          _VolumeSection(
            volumeDb: audioStatus.masterVolumeDb,
            onChanged: ref.read(audioNodeProvider.notifier).setMasterVolume,
          ),
          const Divider(height: 1, color: ScColors.divider),
        ],

        // ── Hauptbereich: Geräteliste + Details ───────────────────────────────
        Expanded(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Linke Spalte: Geräteliste
              Expanded(
                flex: 3,
                child: _DeviceListColumn(
                  devices: audioStatus.availableDevices,
                  selected: audioStatus.selectedDevice,
                  isRunning: isRunning,
                  onSelect: _selectAndSaveDevice,
                  onRefresh: _refresh,
                ),
              ),
              const VerticalDivider(width: 1, color: ScColors.divider),
              // Rechte Spalte: Aktives Gerät + Status
              Expanded(
                flex: 2,
                child: _DetailColumn(audioStatus: audioStatus),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ── Engine-Header ──────────────────────────────────────────────────────────────

class _EngineHeader extends StatelessWidget {
  final AudioNodeState state;
  final AudioDevice? selectedDevice;
  final bool isInSession;
  final bool refreshing;
  final VoidCallback onRefresh;
  final VoidCallback onStart;
  final VoidCallback onStop;

  const _EngineHeader({
    required this.state,
    required this.selectedDevice,
    required this.isInSession,
    required this.refreshing,
    required this.onRefresh,
    required this.onStart,
    required this.onStop,
  });

  @override
  Widget build(BuildContext context) {
    final isRunning = state == AudioNodeState.connected;
    final hasError = state == AudioNodeState.error;

    final statusColor = switch (state) {
      AudioNodeState.connected => ScColors.active,
      AudioNodeState.error => ScColors.error,
      _ => ScColors.textDim,
    };
    final statusLabel = switch (state) {
      AudioNodeState.connected => 'AKTIV',
      AudioNodeState.error => 'FEHLER',
      _ => 'INAKTIV',
    };

    return Container(
      color: ScColors.surface,
      padding: const EdgeInsets.symmetric(
          horizontal: ScSpacing.panelPad, vertical: 6),
      child: Row(
        children: [
          // Engine-Status-Pill
          Container(
            width: 8,
            height: 8,
            margin: const EdgeInsets.only(right: 6),
            decoration:
                BoxDecoration(color: statusColor, shape: BoxShape.circle),
          ),
          Text('AUDIO-ENGINE', style: ScText.panelTitle),
          const SizedBox(width: 6),
          Text(statusLabel,
              style:
                  ScText.status.copyWith(color: statusColor, fontSize: 10)),
          // Aktives Gerät kompakt anzeigen
          if (isRunning && selectedDevice != null) ...[
            const SizedBox(width: 12),
            const Icon(Icons.arrow_forward, size: 10, color: ScColors.textDim),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                selectedDevice!.name,
                style: ScText.label
                    .copyWith(color: ScColors.textSecondary, fontSize: 11),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
              decoration: BoxDecoration(
                color: ScColors.active.withValues(alpha: 0.1),
                border: Border.all(color: ScColors.active.withValues(alpha: 0.3)),
                borderRadius: BorderRadius.circular(2),
              ),
              child: Text(
                selectedDevice!.backend.name.toUpperCase(),
                style: ScText.statusSmall
                    .copyWith(color: ScColors.active, fontSize: 9),
              ),
            ),
          ] else
            const Spacer(),
          const SizedBox(width: 8),
          // Start/Stop
          if (isInSession && !isRunning && !hasError)
            ScButton(
              label: 'Starten',
              icon: Icons.play_arrow,
              variant: ScButtonVariant.primary,
              size: ScButtonSize.compact,
              onPressed: onStart,
            ),
          if (hasError)
            ScButton(
              label: 'Neu starten',
              icon: Icons.refresh,
              variant: ScButtonVariant.secondary,
              size: ScButtonSize.compact,
              onPressed: onStart,
            ),
          if (isRunning)
            ScButton(
              label: 'Stoppen',
              icon: Icons.stop,
              variant: ScButtonVariant.danger,
              size: ScButtonSize.compact,
              onPressed: onStop,
            ),
          const SizedBox(width: 6),
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
                  color:
                      refreshing ? ScColors.textDim : ScColors.textSecondary,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── First-Run Banner ──────────────────────────────────────────────────────────

class _FirstRunBanner extends StatelessWidget {
  final VoidCallback onDismiss;
  const _FirstRunBanner({required this.onDismiss});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: ScColors.active.withValues(alpha: 0.08),
      padding:
          const EdgeInsets.symmetric(horizontal: ScSpacing.panelPad, vertical: 8),
      child: Row(
        children: [
          const Icon(Icons.info_outline, size: 14, color: ScColors.active),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Wähle ein Ausgabegerät aus der Liste, dann "Starten". '
              'Die Auswahl wird gespeichert.',
              style: ScText.label.copyWith(color: ScColors.active),
            ),
          ),
          const SizedBox(width: 8),
          InkWell(
            onTap: onDismiss,
            child: const Icon(Icons.close, size: 14, color: ScColors.active),
          ),
        ],
      ),
    );
  }
}

// ── Volume Section ─────────────────────────────────────────────────────────────

class _VolumeSection extends StatelessWidget {
  final double volumeDb;
  final ValueChanged<double> onChanged;
  const _VolumeSection({required this.volumeDb, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: ScSpacing.panelPad,
        vertical: 8,
      ),
      child: Row(
        children: [
          const Icon(Icons.volume_up, size: 13, color: ScColors.textDim),
          const SizedBox(width: 6),
          Text('MASTER', style: ScText.panelTitle),
          const SizedBox(width: 12),
          Expanded(
            child: MasterVolumeSlider(
              value: volumeDb,
              onChanged: onChanged,
              compact: true,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Device List Column ─────────────────────────────────────────────────────────

class _DeviceListColumn extends StatelessWidget {
  final List<AudioDevice> devices;
  final AudioDevice? selected;
  final bool isRunning;
  final ValueChanged<AudioDevice> onSelect;
  final VoidCallback onRefresh;

  const _DeviceListColumn({
    required this.devices,
    required this.selected,
    required this.isRunning,
    required this.onSelect,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    // Geräte nach Backend gruppieren
    final byBackend = <String, List<AudioDevice>>{};
    for (final d in devices) {
      final key = d.backend.name.toUpperCase();
      byBackend.putIfAbsent(key, () => []).add(d);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
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
              isRunning
                  ? 'Keine Geräte gefunden — Aktualisieren versuchen.'
                  : 'Engine starten um Geräte anzuzeigen.',
              style: ScText.label.copyWith(color: ScColors.textDim),
            ),
          )
        else
          Expanded(
            child: ListView(
              children: [
                for (final entry in byBackend.entries) ...[
                  // Backend-Gruppe Header
                  _BackendGroupHeader(name: entry.key),
                  for (final device in entry.value)
                    _DeviceRow(
                      device: device,
                      isSelected: device.name == selected?.name,
                      onTap: () => onSelect(device),
                    ),
                ],
              ],
            ),
          ),
      ],
    );
  }
}

class _BackendGroupHeader extends StatelessWidget {
  final String name;
  const _BackendGroupHeader({required this.name});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 22,
      color: ScColors.surface2,
      padding: const EdgeInsets.symmetric(horizontal: ScSpacing.panelPad),
      alignment: Alignment.centerLeft,
      child: Text(
        name,
        style: ScText.statusSmall.copyWith(
          color: ScColors.textDim,
          letterSpacing: 0.6,
          fontSize: 9,
        ),
      ),
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
        ? ScColors.active.withValues(alpha: 0.1)
        : _hovered
            ? ScColors.hover
            : Colors.transparent;

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: Container(
          height: 30,
          color: bg,
          padding: const EdgeInsets.symmetric(horizontal: ScSpacing.panelPad),
          child: Row(
            children: [
              // Aktiv-Indikator
              SizedBox(
                width: 14,
                child: widget.isSelected
                    ? Container(
                        width: 4,
                        height: 4,
                        decoration: const BoxDecoration(
                          color: ScColors.active,
                          shape: BoxShape.circle,
                        ),
                      )
                    : null,
              ),
              // Gerätename
              Expanded(
                child: Text(
                  d.name,
                  style: ScText.label.copyWith(
                    color: widget.isSelected
                        ? ScColors.textPrimary
                        : ScColors.textSecondary,
                    fontWeight:
                        widget.isSelected ? FontWeight.w600 : null,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Detail Column ──────────────────────────────────────────────────────────────

class _DetailColumn extends StatelessWidget {
  final AudioNodeStatus audioStatus;
  const _DetailColumn({required this.audioStatus});

  @override
  Widget build(BuildContext context) {
    final selected = audioStatus.selectedDevice;
    final isRunning = audioStatus.state == AudioNodeState.connected;

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Aktives Gerät
          _SectionHeader('AKTIVES GERÄT'),
          if (selected != null) ...[
            _PropRow('Name', selected.name),
            _PropRow('Backend', selected.backend.name.toUpperCase()),
          ] else
            Padding(
              padding: const EdgeInsets.symmetric(
                  horizontal: ScSpacing.panelPad, vertical: 6),
              child: Text(
                isRunning
                    ? 'System-Default'
                    : 'Engine inaktiv',
                style: ScText.label.copyWith(color: ScColors.textDim),
              ),
            ),
          // Engine-Details
          if (isRunning) ...[
            const Divider(height: 1, color: ScColors.divider),
            _SectionHeader('ENGINE'),
            _PropRow('Status', 'Läuft'),
            if (audioStatus.playingCueIds.isNotEmpty)
              _PropRow('Cues aktiv', '${audioStatus.playingCueIds.length}'),
          ],
          // Spielende Cues
          if (audioStatus.playingCueIds.isNotEmpty) ...[
            const Divider(height: 1, color: ScColors.divider),
            _SectionHeader('WIEDERGABE'),
            ...audioStatus.playingCueIds.map(
              (id) => _PlayingCueRow(cueId: id),
            ),
          ],
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader(this.title);

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 28,
      color: ScColors.surface,
      padding: const EdgeInsets.symmetric(horizontal: ScSpacing.panelPad),
      alignment: Alignment.centerLeft,
      child: Text(title, style: ScText.panelTitle),
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
            width: 56,
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

class _PlayingCueRow extends StatelessWidget {
  final String cueId;
  const _PlayingCueRow({required this.cueId});

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

// ── Error Banner ──────────────────────────────────────────────────────────────

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
                style: ScText.label.copyWith(color: ScColors.error)),
          ),
        ],
      ),
    );
  }
}
