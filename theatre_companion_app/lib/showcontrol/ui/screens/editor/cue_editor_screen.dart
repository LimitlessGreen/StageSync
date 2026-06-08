import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../providers/show_control_provider.dart';
import '../../../providers/show_control_domain_provider.dart';
import '../../design_system/sc_colors.dart';
import '../../design_system/sc_spacing.dart';
import '../../design_system/sc_typography.dart';
import '../../design_system/primitives/sc_split_view.dart';
import '../../design_system/domain_components/cue_list_panel.dart';
import '../../design_system/domain_components/cue_inspector.dart';

/// Standalone CueList-Editor + Inspector screen.
///
/// Uses the shared [CueListPanel] and [CueInspector] widgets so features
/// stay in sync with the desktop shell automatically.
class CueEditorScreen extends ConsumerStatefulWidget {
  const CueEditorScreen({super.key});

  @override
  ConsumerState<CueEditorScreen> createState() => _CueEditorScreenState();
}

class _CueEditorScreenState extends ConsumerState<CueEditorScreen> {
  String? _selectedCueId;

  @override
  Widget build(BuildContext context) {
    final domain = ref.watch(showControlDomainProvider);
    final notifier = ref.read(showControlProvider.notifier);

    return ScSplitView(
      persistKey: 'editor.main',
      initialFraction: 0.40,
      left: CueListPanel(
        cueList: domain.cueList,
        playhead: domain.playhead,
        selectedCueId: _selectedCueId,
        onCueSelected: (id) => setState(() => _selectedCueId = id),
        notifier: notifier,
      ),
      right: _EditorInspectorPane(
        selectedCueId: _selectedCueId,
        domain: domain,
        notifier: notifier,
      ),
    );
  }
}

// ── Inspector pane wrapper ────────────────────────────────────────────────────

class _EditorInspectorPane extends StatelessWidget {
  final String? selectedCueId;
  final ShowControlDomainState domain;
  final ShowControlNotifier notifier;

  const _EditorInspectorPane({
    required this.selectedCueId,
    required this.domain,
    required this.notifier,
  });

  @override
  Widget build(BuildContext context) {
    final cue =
        selectedCueId != null ? domain.cueList?.cueById(selectedCueId!) : null;

    return Column(
      children: [
        Container(
          height: 36,
          color: ScColors.surface,
          padding: const EdgeInsets.symmetric(horizontal: ScSpacing.panelPad),
          child: Align(
            alignment: Alignment.centerLeft,
            child: Text('INSPECTOR', style: ScText.panelTitle),
          ),
        ),
        const Divider(height: 1, color: ScColors.divider),
        Expanded(
          child: cue == null
              ? Center(
                  child: Text(
                    'Cue auswählen',
                    style: ScText.label.copyWith(color: ScColors.textDim),
                  ),
                )
              : CueInspector(cue: cue, notifier: notifier),
        ),
      ],
    );
  }
}
