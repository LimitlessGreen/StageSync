import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../providers/show_control_provider.dart';
import '../../../providers/show_control_domain_provider.dart';
import '../../design_system/sc_colors.dart';
import '../../design_system/sc_spacing.dart';
import '../../design_system/sc_typography.dart';
import '../../design_system/primitives/sc_button.dart';
import '../../design_system/domain_components/patch_matrix.dart';

/// Full-screen patch configuration — wraps [PatchMatrix] with a save toolbar.
/// Desktop only.
class PatchScreen extends ConsumerWidget {
  const PatchScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final domain   = ref.watch(showControlDomainProvider);
    final notifier = ref.read(showControlProvider.notifier);

    return Column(
      children: [
        // Toolbar
        Container(
          height: 36,
          color: ScColors.surface,
          padding: const EdgeInsets.symmetric(horizontal: ScSpacing.panelPad),
          child: Row(
            children: [
              Text('PATCH', style: ScText.panelTitle),
              const Spacer(),
              ScButton(
                label: 'Speichern',
                variant: ScButtonVariant.primary,
                size: ScButtonSize.compact,
                onPressed: () => notifier.updatePatchConfig(domain.patchConfig),
              ),
            ],
          ),
        ),
        const Divider(height: 1, color: ScColors.divider),
        // Content
        Expanded(
          child: domain.patchConfig.logicalOutputs.isEmpty
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.settings_input_component,
                          size: 32, color: ScColors.textDim),
                      const SizedBox(height: 12),
                      Text('Keine Patch-Konfiguration',
                          style: ScText.label.copyWith(color: ScColors.textDim)),
                    ],
                  ),
                )
              : PatchMatrix(
                  config:    domain.patchConfig,
                  nodes:     domain.nodes,
                  onChanged: (updated) => notifier.updatePatchConfig(updated),
                ),
        ),
      ],
    );
  }
}
