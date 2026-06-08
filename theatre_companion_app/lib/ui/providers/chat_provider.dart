// chat_provider.dart
// ────────────────────
// Riverpod state management for the Chat feature.
// Listens to [chatEventStreamProvider] and maintains a deduped message list.
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../network/isolate/isolate_messages.dart';
import 'network_state_provider.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Display model (UI-only, not persisted)
// ─────────────────────────────────────────────────────────────────────────────

class ChatMessageDisplay {
  final String messageId;
  final String senderLabel;
  final String content;
  final DateTime timestamp;
  final bool isMine;

  const ChatMessageDisplay({
    required this.messageId,
    required this.senderLabel,
    required this.content,
    required this.timestamp,
    required this.isMine,
  });

  factory ChatMessageDisplay.fromEvent(ChatMessageReceivedEvent e) =>
      ChatMessageDisplay(
        messageId: e.messageId,
        senderLabel: e.senderShortLabel,
        content: e.content,
        timestamp: DateTime.fromMillisecondsSinceEpoch(e.timestampMs),
        isMine: e.isMine,
      );
}

// ─────────────────────────────────────────────────────────────────────────────
// StateNotifier
// ─────────────────────────────────────────────────────────────────────────────

class ChatNotifier extends StateNotifier<List<ChatMessageDisplay>> {
  final Ref _ref;
  ProviderSubscription? _sub;

  ChatNotifier(this._ref) : super([]) {
    _sub = _ref.listen<AsyncValue<ChatMessageReceivedEvent>>(
      chatEventStreamProvider,
      (_, next) {
        next.whenData(_onEvent);
      },
    );
  }

  void _onEvent(ChatMessageReceivedEvent event) {
    // Deduplicate by messageId.
    if (state.any((m) => m.messageId == event.messageId)) return;
    state = [...state, ChatMessageDisplay.fromEvent(event)];
    // Keep at most 200 messages in memory.
    if (state.length > 200) {
      state = state.sublist(state.length - 200);
    }
  }

  /// Send a new chat message via the network isolate.
  Future<void> sendMessage(String content) async {
    if (content.trim().isEmpty) return;
    final manager = await _ref.read(networkIsolateManagerProvider.future);
    manager.send(SendChatMessageCommand(content: content.trim()));
  }

  @override
  void dispose() {
    _sub?.close();
    super.dispose();
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Providers
// ─────────────────────────────────────────────────────────────────────────────

final chatProvider =
    StateNotifierProvider<ChatNotifier, List<ChatMessageDisplay>>((ref) {
  return ChatNotifier(ref);
});
