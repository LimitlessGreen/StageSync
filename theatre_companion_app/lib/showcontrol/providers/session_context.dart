import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'session_provider.dart';

/// Kapselt den Zugriff auf Session-Credentials für Provider.
///
/// Ersetzt die wiederholten Getter `_session`, `_sessionId`, `_token`
/// die in jedem Provider identisch definiert sind.
class SessionContext {
  final SessionState _state;

  const SessionContext(this._state);

  bool get isInSession => _state.isInSession;
  String get sessionId => _state.session!.sessionId;
  String get token => _state.token!;
  String? get myNodeId => _state.myNode?.nodeId;
}

/// Extension auf Ref/WidgetRef für bequemen SessionContext-Zugriff.
extension SessionContextRef on Ref {
  SessionContext get sessionCtx => SessionContext(read(sessionProvider));
}
