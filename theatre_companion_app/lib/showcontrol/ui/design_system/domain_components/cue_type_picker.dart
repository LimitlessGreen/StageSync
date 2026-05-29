import 'package:flutter/material.dart';

import '../../../domain/cue_params.dart';

/// Zeigt ein Popup-Menü zur Auswahl des Cue-Typs.
/// Gibt null zurück wenn der User abbricht.
Future<CueParams?> showCueTypePicker(
  BuildContext context,
  Offset nearPosition,
) async {
  final screenSize = MediaQuery.sizeOf(context);
  final result = await showMenu<String>(
    context: context,
    color: const Color(0xFF1E1E1E),
    elevation: 8,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
    position: RelativeRect.fromLTRB(
      nearPosition.dx - 160,
      nearPosition.dy,
      screenSize.width - nearPosition.dx,
      screenSize.height - nearPosition.dy,
    ),
    items: [
      cueTypeMenuItem('audio', Icons.volume_up,            'Audio', 'Audiodatei abspielen'),
      cueTypeMenuItem('wait',  Icons.timer_outlined,        'Wait',  'Pause / Timer'),
      cueTypeMenuItem('maOsc', Icons.settings_remote,       'MA OSC','GrandMA über OSC'),
      cueTypeMenuItem('goto',  Icons.redo,                  'GOTO',  'Zu einer anderen Cue springen'),
      cueTypeMenuItem('group', Icons.account_tree_outlined, 'Group', 'Cues parallel/sequentiell'),
    ],
  );

  return switch (result) {
    'audio' => const AudioParams(assetId: ''),
    'wait'  => const WaitParams(durationMs: 5000),
    'maOsc' => const MaOscParams(oscAddress: '/gma2/cmd'),
    'goto'  => const GotoParams(targetCueId: ''),
    'group' => const GroupParams(childCueIds: [], sequential: false),
    _       => null,
  };
}

PopupMenuItem<String> cueTypeMenuItem(
  String value,
  IconData icon,
  String label,
  String subtitle,
) {
  return PopupMenuItem<String>(
    value: value,
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
    child: Row(
      children: [
        Icon(icon, size: 16, color: const Color(0xFF00E676)),
        const SizedBox(width: 10),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(label,
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w600)),
            Text(subtitle,
                style: const TextStyle(
                    color: Color(0xFF555555), fontSize: 10)),
          ],
        ),
      ],
    ),
  );
}
