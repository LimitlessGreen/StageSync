import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:theatre_companion_app/showcontrol/domain/node_status.dart';
import 'package:theatre_companion_app/showcontrol/nodes/audio_node/audio_device.dart';
import 'package:theatre_companion_app/showcontrol/providers/audio_node_provider.dart';
import 'package:theatre_companion_app/showcontrol/providers/session_provider.dart';
import 'package:theatre_companion_app/showcontrol/providers/show_control_domain_provider.dart';
import 'package:theatre_companion_app/showcontrol/session/session_service.dart';
import 'package:theatre_companion_app/showcontrol/ui/screens/nodes/node_management_panel.dart';
import 'package:theatre_companion_app/showcontrol/grpc/generated/stagesync/v1/common.pb.dart';

class _TestSessionNotifier extends SessionNotifier {
  _TestSessionNotifier() : super(SessionService()) {
    state = SessionState(
      myNode: (NodeInfo()
        ..nodeId = 'controller'
        ..name = 'Controller'
        ..tasks.add(NodeTask.NODE_TASK_MASTER)),
    );
  }
}

void main() {
  testWidgets(
      'NodeManagementPanel zeigt Backend- und Formatsektionen fuer Audio-Nodes',
      (tester) async {
    SharedPreferences.setMockInitialValues({});

    final node = NodeStatus(
      nodeId: 'audio-1',
      name: 'Server Audio',
      tasks: const ['audio'],
      health: NodeHealthPhase.online,
      availableDevices: const [
        AudioDevice(
          id: 'jack-main',
          name: 'JACK Main Out',
          backend: AudioBackend.jack,
          index: 2,
        ),
        AudioDevice(
          id: 'wasapi-main',
          name: 'WASAPI Main Out',
          backend: AudioBackend.wasapi,
          index: 0,
        ),
      ],
      selectedDeviceIndex: 2,
      activeBackend: AudioBackend.jack,
      backendPriority: const [AudioBackend.jack, AudioBackend.wasapi],
      sampleRate: 48000,
      channels: 2,
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sessionProvider.overrideWith((ref) => _TestSessionNotifier()),
          audioNodeProvider.overrideWith((ref) => AudioNodeNotifier.forTest()),
          nodeStatusListProvider.overrideWith((ref) => [node]),
        ],
        child: const MaterialApp(home: Scaffold(body: NodeManagementPanel())),
      ),
    );

    await tester.pumpAndSettle();
    await tester.tap(find.text('Server Audio'));
    await tester.pumpAndSettle();

    expect(find.text('BACKEND'), findsOneWidget);
    expect(find.text('AUDIO-FORMAT'), findsOneWidget);
    expect(find.textContaining('48000 Hz / 2 ch'), findsOneWidget);
    expect(find.textContaining('JACK'), findsWidgets);
    expect(find.textContaining('WASAPI'), findsWidgets);
    expect(find.text('Backend anwenden'), findsOneWidget);
    expect(find.text('Format anwenden'), findsOneWidget);
  });
}
