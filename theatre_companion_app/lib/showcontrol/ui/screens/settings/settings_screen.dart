import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../providers/settings_provider.dart';
import '../../design_system/sc_colors.dart';
import '../../design_system/sc_spacing.dart';
import '../../design_system/sc_typography.dart';

/// Einstellungsscreen — erreichbar über das Menü in der Shell.
class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);
    final notifier = ref.read(settingsProvider.notifier);

    return Scaffold(
      backgroundColor: ScColors.bg,
      appBar: AppBar(
        backgroundColor: ScColors.surface,
        foregroundColor: ScColors.textPrimary,
        title: Text('Einstellungen', style: ScText.panelTitle),
        titleSpacing: ScSpacing.panelPad,
        elevation: 0,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: ScColors.divider),
        ),
      ),
      body: ListView(
        children: [
          _SectionHeader('ANZEIGE'),
          _ToggleRow(
            label: 'Display immer an',
            description: 'Verhindert, dass der Bildschirm sich während einer Show ausschaltet.',
            icon: Icons.screen_lock_portrait,
            value: settings.keepScreenOn,
            onChanged: notifier.setKeepScreenOn,
          ),
          const Divider(height: 1, color: ScColors.divider),
          _SectionHeader('POWER-MANAGEMENT'),
          _InfoRow(
            icon: Icons.battery_saver,
            label: 'Batterieoptimierung',
            description: 'Android schränkt Apps im Hintergrund ein. '
                'Damit gRPC-Streams und Audio auch bei ausgeschaltetem Bildschirm laufen, '
                'sollte StageSync von der Batterieoptimierung ausgenommen werden.',
            actionLabel: 'Systemeinstellungen öffnen',
            onAction: () => _openBatterySettings(context),
          ),
          const Divider(height: 1, color: ScColors.divider),
          _SectionHeader('INFO'),
          _InfoRow(
            icon: Icons.info_outline,
            label: 'Hintergrund-Betrieb',
            description: 'StageSync benötigt für zuverlässige Hintergrund-Synchronisation '
                'auf Android einen aktiven Foreground Service. '
                'Stelle sicher, dass die App von der Batterieoptimierung ausgenommen ist '
                'und "Display immer an" aktiviert ist, wenn du als Audio-Node arbeitest.',
          ),
        ],
      ),
    );
  }

  void _openBatterySettings(BuildContext context) {
    // Zeigt einen Dialog mit Anleitung statt direkt zu öffnen
    // (Intent-Öffnung würde natives Kotlin brauchen)
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: ScColors.surface,
        title: Text('Batterieoptimierung deaktivieren',
            style: ScText.panelTitle.copyWith(color: ScColors.textPrimary)),
        content: Text(
          '1. Öffne die Android-Einstellungen\n'
          '2. Gehe zu Apps → StageSync\n'
          '3. Tippe auf „Akku"\n'
          '4. Wähle „Nicht optimieren"\n\n'
          'Alternativ: Einstellungen → Akku → Akkuoptimierung → Alle Apps → StageSync → Nicht einschränken',
          style: ScText.label.copyWith(color: ScColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text('OK', style: TextStyle(color: ScColors.active)),
          ),
        ],
      ),
    );
  }
}

// ── Section Header ────────────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader(this.title);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(ScSpacing.panelPad, 16, ScSpacing.panelPad, 6),
      child: Text(title, style: ScText.panelTitle),
    );
  }
}

// ── Toggle Row ────────────────────────────────────────────────────────────────

class _ToggleRow extends StatelessWidget {
  final String label;
  final String description;
  final IconData icon;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _ToggleRow({
    required this.label,
    required this.description,
    required this.icon,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => onChanged(!value),
      child: Container(
        padding: const EdgeInsets.symmetric(
            horizontal: ScSpacing.panelPad, vertical: 12),
        child: Row(
          children: [
            Icon(icon, size: 18, color: value ? ScColors.active : ScColors.textDim),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label,
                      style: ScText.label.copyWith(
                        color: ScColors.textPrimary,
                        fontWeight: FontWeight.w600,
                      )),
                  const SizedBox(height: 2),
                  Text(description,
                      style: ScText.label.copyWith(
                          color: ScColors.textDim, fontSize: 11)),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Transform.scale(
              scale: 0.85,
              child: Switch(
                value: value,
                onChanged: onChanged,
                activeColor: ScColors.active,
                activeTrackColor: ScColors.active.withValues(alpha: 0.3),
                inactiveThumbColor: ScColors.textDim,
                inactiveTrackColor: ScColors.surface2,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Info Row (read-only mit optionalem Button) ────────────────────────────────

class _InfoRow extends StatelessWidget {
  final String label;
  final String description;
  final IconData icon;
  final String? actionLabel;
  final VoidCallback? onAction;

  const _InfoRow({
    required this.label,
    required this.description,
    required this.icon,
    this.actionLabel,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
          horizontal: ScSpacing.panelPad, vertical: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 1),
            child: Icon(icon, size: 18, color: ScColors.textDim),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: ScText.label.copyWith(
                      color: ScColors.textPrimary,
                      fontWeight: FontWeight.w600,
                    )),
                const SizedBox(height: 4),
                Text(description,
                    style: ScText.label
                        .copyWith(color: ScColors.textDim, fontSize: 11)),
                if (actionLabel != null && onAction != null) ...[
                  const SizedBox(height: 8),
                  GestureDetector(
                    onTap: onAction,
                    child: Text(
                      actionLabel!,
                      style: ScText.label.copyWith(
                        color: ScColors.active,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
