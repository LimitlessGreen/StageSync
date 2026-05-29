import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:state_notifier/state_notifier.dart';
import 'package:theatre_companion_app/showcontrol/grpc/generated/stagesync/v1/common.pb.dart';
import 'package:theatre_companion_app/showcontrol/grpc/generated/stagesync/v1/session.pb.dart';
import 'package:theatre_companion_app/showcontrol/providers/session_provider.dart';
import 'package:theatre_companion_app/showcontrol/ui/shell/sc_adaptive_shell.dart';
import 'package:theatre_companion_app/ui/screens/showcontrol/session_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('SessionScreen', () {
    testWidgets('routes in-session users through the adaptive shell on mobile', (
      tester,
    ) async {
      final session = Session()
        ..sessionId = 'session-1'
        ..name = 'Probe';
      final node = NodeInfo()
        ..nodeId = 'node-1'
        ..name = 'Remote'
        ..nodeType = NodeType.NODE_TYPE_VIEWER
        ..tasks.add(NodeTask.NODE_TASK_VIEWER);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            sessionProvider.overrideWith(
              (_) => _TestSessionNotifier(
                SessionState(session: session, token: 'token', myNode: node),
              ),
            ),
          ],
          child: const MaterialApp(
            home: MediaQuery(
              data: MediaQueryData(size: Size(480, 800)),
              child: SessionScreen(),
            ),
          ),
        ),
      );

      await tester.pump();

      expect(find.byType(ScAdaptiveShell), findsOneWidget);
    });
  });
}

class _TestSessionNotifier extends StateNotifier<SessionState>
    implements SessionNotifier {
  _TestSessionNotifier(super.state);

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}