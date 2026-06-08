// chat_screen.dart
// ──────────────────
// BLE-Mesh Chat Demo Screen.
// Nachrichten werden über das Gossip-Protokoll im Mesh verteilt und
// AES-256-GCM verschlüsselt übertragen.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../network/isolate/isolate_messages.dart';
import '../providers/chat_provider.dart';
import '../providers/network_state_provider.dart';

class ChatScreen extends ConsumerStatefulWidget {
  const ChatScreen({super.key});

  @override
  ConsumerState<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends ConsumerState<ChatScreen> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final messages = ref.watch(chatProvider);
    final status = ref.watch(networkStatusProvider);
    final isReady = ref.watch(isNetworkReadyProvider);
    final colors = Theme.of(context).colorScheme;

    // Auto-scroll to bottom when new messages arrive.
    ref.listen(chatProvider, (prev, next) {
      if (next.length > (prev?.length ?? 0)) {
        _scrollToBottom();
      }
    });

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mesh Chat'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(28),
          child: _ChatSubtitle(
            peerCount: status?.connectedPeerCount ?? 0,
            syncStatus: status?.syncStatus,
          ),
        ),
      ),
      body: Column(
        children: [
          // ── Message List ──────────────────────────────────────────────
          Expanded(
            child: messages.isEmpty
                ? const _EmptyChatState()
                : ListView.builder(
                    controller: _scrollController,
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    itemCount: messages.length,
                    itemBuilder: (context, i) => _ChatBubble(
                      message: messages[i],
                    ),
                  ),
          ),

          // ── Divider + Info-Chip ───────────────────────────────────────
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            child: Row(
              children: [
                const Icon(Icons.security, size: 12, color: Colors.grey),
                const SizedBox(width: 4),
                Text(
                  'AES-256-GCM via BLE Mesh',
                  style: Theme.of(context)
                      .textTheme
                      .labelSmall
                      ?.copyWith(color: Colors.grey),
                ),
                const Spacer(),
                if (status?.pendingQueuedPackets != null &&
                    status!.pendingQueuedPackets > 0)
                  Text(
                    '${status.pendingQueuedPackets} in Queue',
                    style: const TextStyle(fontSize: 10, color: Colors.orange),
                  ),
              ],
            ),
          ),

          // ── Input Row ─────────────────────────────────────────────────
          Container(
            decoration: BoxDecoration(
              color: colors.surface,
              border: Border(
                top: BorderSide(color: colors.outlineVariant),
              ),
            ),
            padding: EdgeInsets.only(
              left: 12,
              right: 8,
              top: 8,
              bottom: MediaQuery.of(context).viewInsets.bottom + 8,
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    enabled: isReady,
                    maxLength: 180,
                    maxLines: null,
                    keyboardType: TextInputType.multiline,
                    textCapitalization: TextCapitalization.sentences,
                    decoration: InputDecoration(
                      hintText: isReady
                          ? 'Nachricht ins Mesh senden…'
                          : 'Netzwerk wird initialisiert…',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                        borderSide: BorderSide.none,
                      ),
                      filled: true,
                      fillColor: colors.surfaceContainerHighest,
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 10),
                      counterText: '', // hide character counter
                    ),
                    onSubmitted: (_) => _send(),
                  ),
                ),
                const SizedBox(width: 8),
                FilledButton(
                  onPressed: isReady ? _send : null,
                  style: FilledButton.styleFrom(
                    shape: const CircleBorder(),
                    padding: const EdgeInsets.all(14),
                  ),
                  child: const Icon(Icons.send),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _send() {
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    ref.read(chatProvider.notifier).sendMessage(text);
    _controller.clear();
    _scrollToBottom();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Chat Subtitle (AppBar.bottom)
// ─────────────────────────────────────────────────────────────────────────────

class _ChatSubtitle extends StatelessWidget {
  final int peerCount;
  final NetworkSyncStatus? syncStatus;

  const _ChatSubtitle({required this.peerCount, required this.syncStatus});

  @override
  Widget build(BuildContext context) {
    final (label, color) = switch (syncStatus) {
      NetworkSyncStatus.syncing || NetworkSyncStatus.upToDate => (
          'Server + $peerCount Peers',
          Colors.green
        ),
      NetworkSyncStatus.meshOnly => (
          '$peerCount Peers via BLE Mesh',
          Colors.blueAccent
        ),
      _ => ('Offline – Store & Forward aktiv', Colors.orange),
    };

    return Container(
      padding: const EdgeInsets.only(left: 16, right: 16, bottom: 6),
      alignment: Alignment.centerLeft,
      child: Row(
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 6),
          Text(label, style: TextStyle(fontSize: 11, color: color)),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Chat Bubble
// ─────────────────────────────────────────────────────────────────────────────

class _ChatBubble extends StatelessWidget {
  final ChatMessageDisplay message;
  const _ChatBubble({required this.message});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final isMine = message.isMine;

    final timeLabel = '${message.timestamp.hour.toString().padLeft(2, '0')}'
        ':${message.timestamp.minute.toString().padLeft(2, '0')}';

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Column(
        crossAxisAlignment:
            isMine ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          if (!isMine)
            Padding(
              padding: const EdgeInsets.only(left: 12, bottom: 2),
              child: Text(
                message.senderLabel,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: _colorForLabel(message.senderLabel),
                    ),
              ),
            ),
          Row(
            mainAxisAlignment:
                isMine ? MainAxisAlignment.end : MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              if (!isMine) ...[
                CircleAvatar(
                  radius: 14,
                  backgroundColor: _colorForLabel(message.senderLabel)
                      .withValues(alpha: 0.2),
                  child: Text(
                    message.senderLabel.substring(message.senderLabel.length > 1
                        ? message.senderLabel.length - 1
                        : 0),
                    style: TextStyle(
                        fontSize: 10,
                        color: _colorForLabel(message.senderLabel)),
                  ),
                ),
                const SizedBox(width: 6),
              ],
              Flexible(
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: isMine
                        ? colors.primaryContainer
                        : colors.surfaceContainerHigh,
                    borderRadius: BorderRadius.only(
                      topLeft: const Radius.circular(18),
                      topRight: const Radius.circular(18),
                      bottomLeft: Radius.circular(isMine ? 18 : 4),
                      bottomRight: Radius.circular(isMine ? 4 : 18),
                    ),
                  ),
                  child: Text(
                    message.content,
                    style: TextStyle(
                      color:
                          isMine ? colors.onPrimaryContainer : colors.onSurface,
                    ),
                  ),
                ),
              ),
              if (isMine) const SizedBox(width: 6),
            ],
          ),
          Padding(
            padding: EdgeInsets.only(
                left: isMine ? 0 : 40, right: isMine ? 0 : 0, top: 2),
            child: Text(
              timeLabel,
              style: const TextStyle(fontSize: 10, color: Colors.grey),
            ),
          ),
        ],
      ),
    );
  }

  static const List<Color> _colors = [
    Colors.blueAccent,
    Colors.purpleAccent,
    Colors.teal,
    Colors.deepOrangeAccent,
    Colors.indigo,
    Colors.pinkAccent,
  ];

  Color _colorForLabel(String label) =>
      _colors[label.codeUnits.fold(0, (a, b) => a + b) % _colors.length];
}

// ─────────────────────────────────────────────────────────────────────────────
// Empty State
// ─────────────────────────────────────────────────────────────────────────────

class _EmptyChatState extends StatelessWidget {
  const _EmptyChatState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.chat_bubble_outline,
            size: 60,
            color: Colors.grey.withValues(alpha: 0.4),
          ),
          const SizedBox(height: 16),
          const Text(
            'Noch keine Nachrichten',
            style: TextStyle(color: Colors.grey, fontSize: 16),
          ),
          const SizedBox(height: 8),
          const Text(
            'Schreibe die erste Nachricht –\nsie wird verschlüsselt ins BLE-Mesh gesendet.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey, fontSize: 12),
          ),
        ],
      ),
    );
  }
}
