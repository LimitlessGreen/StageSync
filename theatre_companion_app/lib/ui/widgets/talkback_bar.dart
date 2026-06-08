import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../showcontrol/grpc/generated/stagesync/v1/talkback.pb.dart'
    as tb_proto;
import '../../talkback/talkback_provider.dart';
import 'talk_button.dart';

/// Talkback-Leiste — am unteren Rand der Show-Control-Screen.
///
/// Enthält:
///   • [TalkButton] (Push-to-Talk)
///   • Routing-Selector (Bus auswählen)
///   • Active-Talker-Chips (zeigt andere sprechende Clients)
class TalkbackBar extends ConsumerStatefulWidget {
  const TalkbackBar({
    super.key,
    required this.availableBusIds,
    required this.busNames,
  });

  /// Alle Talkback-Bus-IDs aus der PatchConfig.
  final List<String> availableBusIds;

  /// Anzeigenamen pro Bus-ID (id → name).
  final Map<String, String> busNames;

  @override
  ConsumerState<TalkbackBar> createState() => _TalkbackBarState();
}

class _TalkbackBarState extends ConsumerState<TalkbackBar> {
  // Ausgewählte Bus-IDs (leer = broadcast auf alle TALKBACK-Buses)
  final Set<String> _selectedBusIds = {};

  @override
  Widget build(BuildContext context) {
    final tbState =
        ref.watch(talkbackProvider).valueOrNull ?? const TalkbackState();

    final List<String> targetBusIds = _selectedBusIds.isEmpty
        ? const [] // leer = alle TALKBACK-Buses
        : _selectedBusIds.toList();

    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFF1A1A1A),
        border: Border(top: BorderSide(color: Color(0xFF333333), width: 1)),
      ),
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ── Fehleranzeige ────────────────────────────────────────────────
          if (tbState.status == TalkbackStatus.error &&
              tbState.errorMessage != null) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFFE65100).withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(4),
                border: Border.all(
                    color: const Color(0xFFE65100).withValues(alpha: 0.4)),
              ),
              child: Text(
                tbState.errorMessage!,
                style: const TextStyle(color: Color(0xFFFFAB40), fontSize: 11),
              ),
            ),
            const SizedBox(height: 6),
          ],

          // ── Aktive Talker Chips ──────────────────────────────────────────
          if (tbState.activeTalkers.isNotEmpty) ...[
            _buildActiveTalkers(tbState.activeTalkers),
            const SizedBox(height: 8),
          ],

          // ── Kein-Bus-Hinweis ─────────────────────────────────────────────
          if (widget.availableBusIds.isEmpty) ...[
            const Row(
              children: [
                Icon(Icons.info_outline, size: 14, color: Color(0xFF888888)),
                SizedBox(width: 6),
                Expanded(
                  child: Text(
                    'Kein Talkback-Bus konfiguriert — Bus-Icon (oben rechts) antippen.',
                    style: TextStyle(color: Color(0xFF666666), fontSize: 11),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
          ],

          // ── Talk-Button + Modus + Bus-Selector ──────────────────────────
          Row(
            children: [
              // Talk-Button
              Expanded(
                child: TalkButton(targetBusIds: targetBusIds),
              ),
              const SizedBox(width: 6),
              // Modus-Toggle (Live / Delayed)
              _ModeToggle(tbState: tbState),
              const SizedBox(width: 6),
              // Bus-Selector
              if (widget.availableBusIds.isNotEmpty) _buildBusSelector(context),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActiveTalkers(List<tb_proto.ActiveTalker> talkers) {
    return Wrap(
      spacing: 6,
      runSpacing: 4,
      children: talkers.map((t) => _TalkerChip(talker: t)).toList(),
    );
  }

  Widget _buildBusSelector(BuildContext context) {
    final label = _selectedBusIds.isEmpty
        ? 'Alle Buses'
        : _selectedBusIds.length == 1
            ? (widget.busNames[_selectedBusIds.first] ?? _selectedBusIds.first)
            : '${_selectedBusIds.length} Buses';

    return GestureDetector(
      onTap: () => _showBusPicker(context),
      child: Container(
        height: 56,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: const Color(0xFF2C2C2C),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: const Color(0xFF444444)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.speaker, color: Color(0xFFAAAAAA), size: 18),
            const SizedBox(width: 6),
            Text(
              label,
              style: const TextStyle(color: Color(0xFFCCCCCC), fontSize: 12),
            ),
            const SizedBox(width: 4),
            const Icon(Icons.arrow_drop_down,
                color: Color(0xFF888888), size: 18),
          ],
        ),
      ),
    );
  }

  void _showBusPicker(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: const Color(0xFF1E1E1E),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) => Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Padding(
              padding: EdgeInsets.all(16),
              child: Text(
                'Talkback-Ziel',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            // "Alle" Option
            CheckboxListTile(
              value: _selectedBusIds.isEmpty,
              title: const Text('Alle Talkback-Buses',
                  style: TextStyle(color: Colors.white)),
              onChanged: (_) {
                setModalState(() => _selectedBusIds.clear());
                setState(() {});
              },
            ),
            const Divider(color: Color(0xFF333333), height: 1),
            ...widget.availableBusIds.map((id) {
              final name = widget.busNames[id] ?? id;
              return CheckboxListTile(
                value: _selectedBusIds.contains(id),
                title: Text(name, style: const TextStyle(color: Colors.white)),
                subtitle: Text(id,
                    style: const TextStyle(
                        color: Color(0xFF888888), fontSize: 11)),
                onChanged: (checked) {
                  setModalState(() {
                    if (checked == true) {
                      _selectedBusIds.add(id);
                    } else {
                      _selectedBusIds.remove(id);
                    }
                  });
                  setState(() {});
                },
              );
            }),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}

// ── Modus-Toggle ──────────────────────────────────────────────────────────────

class _ModeToggle extends ConsumerWidget {
  const _ModeToggle({required this.tbState});
  final TalkbackState tbState;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDelayed = tbState.mode == TalkbackMode.delayed;
    final canToggle = tbState.status == TalkbackStatus.idle;

    return GestureDetector(
      onTap: canToggle
          ? () => ref.read(talkbackProvider.notifier).toggleMode()
          : null,
      child: Tooltip(
        message: isDelayed
            ? 'Delayed: aufnehmen & beim Loslassen abspielen'
            : 'Live: sofort übertragen',
        child: Container(
          height: 56,
          padding: const EdgeInsets.symmetric(horizontal: 8),
          decoration: BoxDecoration(
            color: isDelayed
                ? const Color(0xFF7B1FA2).withValues(alpha: 0.25)
                : const Color(0xFF2C2C2C),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color:
                  isDelayed ? const Color(0xFFCE93D8) : const Color(0xFF444444),
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                isDelayed ? Icons.timer : Icons.bolt,
                size: 16,
                color: isDelayed
                    ? const Color(0xFFCE93D8)
                    : const Color(0xFF888888),
              ),
              const SizedBox(height: 2),
              Text(
                isDelayed ? 'DELAY' : 'LIVE',
                style: TextStyle(
                  fontSize: 9,
                  fontWeight: FontWeight.bold,
                  color: isDelayed
                      ? const Color(0xFFCE93D8)
                      : const Color(0xFF666666),
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TalkerChip extends StatelessWidget {
  const _TalkerChip({required this.talker});
  final tb_proto.ActiveTalker talker;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFFD32F2F).withOpacity(0.2),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFD32F2F), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.mic, color: Color(0xFFFF5252), size: 12),
          const SizedBox(width: 4),
          Text(
            talker.displayName.isNotEmpty
                ? talker.displayName
                : talker.clientId,
            style: const TextStyle(color: Color(0xFFFF8A80), fontSize: 11),
          ),
        ],
      ),
    );
  }
}
