import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../platform/foreground_service.dart';
import '../../../providers/settings_provider.dart';
import '../../design_system/sc_colors.dart';
import '../../design_system/sc_spacing.dart';
import '../../design_system/sc_typography.dart';

/// Einstellungsscreen — erreichbar über das Menü in der Shell.
class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  bool? _ignoringBatteryOpt;

  @override
  void initState() {
    super.initState();
    _checkBatteryOpt();
  }

  Future<void> _checkBatteryOpt() async {
    final ignoring = await ForegroundService.isIgnoringBatteryOptimizations();
    if (mounted) setState(() => _ignoringBatteryOpt = ignoring);
  }

  Future<void> _requestBatteryOpt() async {
    await ForegroundService.requestIgnoreBatteryOptimizations();
    // Nach Rückkehr Status neu prüfen
    await Future.delayed(const Duration(milliseconds: 500));
    await _checkBatteryOpt();
  }

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(settingsProvider);
    final notifier = ref.read(settingsProvider.notifier);
    final batteryOk = _ignoringBatteryOpt ?? false;

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
          _BatteryRow(
            isIgnoring: _ignoringBatteryOpt,
            onRequest: _requestBatteryOpt,
          ),
          const Divider(height: 1, color: ScColors.divider),
          if (!batteryOk && _ignoringBatteryOpt != null)
            _InfoRow(
              icon: Icons.warning_amber_rounded,
              label: 'Hintergrund eingeschränkt',
              description: 'Ohne Batterieoptimierungs-Ausnahme kann Android die App '
                  'nach ~1–2 Min. im Hintergrund einschränken oder beenden. '
                  'Tippe oben auf "Ausnahme beantragen" um das zu beheben.',
            ),
          if (batteryOk)
            _InfoRow(
              icon: Icons.check_circle_outline,
              label: 'Hintergrund-Betrieb aktiv',
              description: 'StageSync läuft als Foreground Service und ist von der '
                  'Batterieoptimierung ausgenommen. gRPC-Streams und Audio bleiben '
                  'auch bei ausgeschaltetem Bildschirm aktiv.',
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

// ── Battery Row ───────────────────────────────────────────────────────────────

class _BatteryRow extends StatelessWidget {
  final bool? isIgnoring;
  final VoidCallback onRequest;

  const _BatteryRow({required this.isIgnoring, required this.onRequest});

  @override
  Widget build(BuildContext context) {
    final loading = isIgnoring == null;
    final ok      = isIgnoring == true;
    final color   = ok ? ScColors.active : ScColors.warn;

    return Container(
      padding: const EdgeInsets.symmetric(
          horizontal: ScSpacing.panelPad, vertical: 12),
      child: Row(
        children: [
          Icon(
            ok ? Icons.battery_saver : Icons.battery_alert,
            size: 18,
            color: color,
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Batterieoptimierung',
                  style: ScText.label.copyWith(
                      color: ScColors.textPrimary, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 2),
                Text(
                  loading
                      ? 'Wird geprüft…'
                      : ok
                          ? 'Ausnahme aktiv — App läuft uneingeschränkt im Hintergrund.'
                          : 'Nicht ausgenommen — Android kann die App einschränken.',
                  style: ScText.label.copyWith(color: ScColors.textDim, fontSize: 11),
                ),
              ],
            ),
          ),
          if (!ok && !loading) ...[
            const SizedBox(width: 12),
            GestureDetector(
              onTap: onRequest,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: ScColors.warn.withValues(alpha: 0.12),
                  border: Border.all(color: ScColors.warn.withValues(alpha: 0.5)),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  'Ausnahme beantragen',
                  style: ScText.label.copyWith(
                      color: ScColors.warn,
                      fontSize: 11,
                      fontWeight: FontWeight.w700),
                ),
              ),
            ),
          ],
          if (ok) ...[
            const SizedBox(width: 12),
            Icon(Icons.check_circle, size: 18, color: ScColors.active),
          ],
        ],
      ),
    );
  }
}

// ── Info Row ──────────────────────────────────────────────────────────────────

class _InfoRow extends StatelessWidget {
  final String label;
  final String description;
  final IconData icon;

  const _InfoRow({
    required this.label,
    required this.description,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final color = icon == Icons.warning_amber_rounded
        ? ScColors.warn
        : icon == Icons.check_circle_outline
            ? ScColors.active
            : ScColors.textDim;
    return Container(
      padding: const EdgeInsets.symmetric(
          horizontal: ScSpacing.panelPad, vertical: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 1),
            child: Icon(icon, size: 16, color: color),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: ScText.label.copyWith(
                        color: color, fontWeight: FontWeight.w600)),
                const SizedBox(height: 3),
                Text(description,
                    style: ScText.label
                        .copyWith(color: ScColors.textDim, fontSize: 11)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
