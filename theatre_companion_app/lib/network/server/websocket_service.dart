// websocket_service.dart
// ────────────────────────
// Maintains the WebSocket connection to the central StageSync server.
//
// ## Design Rules
//   * ONLY the elected leader ever calls [connect]. Follower devices route
//     their updates via the BLE mesh → leader → WebSocket.
//   * All outbound payloads are the same AES-GCM encrypted binary blobs used
//     on the BLE layer, ensuring end-to-end consistency. The server decrypts
//     using the same shared key stored server-side.
//   * Automatic reconnection uses exponential back-off (max 30 s).
//   * On disconnect, the leader immediately starts buffering outbound messages
//     in [_outboundBuffer]. These are flushed once reconnected.
import 'dart:async';
import 'dart:math' show min;
import 'dart:typed_data';

import 'package:web_socket_channel/web_socket_channel.dart';

/// Maximum number of bytes to buffer while disconnected.
const int kWsBufferMaxBytes = 512 * 1024; // 512 KB

/// Initial reconnect delay (ms).
const int kWsInitialReconnectMs = 500;

/// Maximum reconnect delay (ms).
const int kWsMaxReconnectMs = 30000;

// ─────────────────────────────────────────────────────────────────────────────

/// Callback for messages received from the server.
typedef ServerMessageCallback = void Function(Uint8List message);

/// Callback for connection state changes.
typedef ServerConnectionCallback = void Function(bool isConnected);

// ─────────────────────────────────────────────────────────────────────────────

class WebSocketService {
  String? _serverUrl;
  WebSocketChannel? _channel;
  StreamSubscription? _channelSub;

  bool _isConnected = false;
  bool _shouldReconnect = false;
  int _reconnectDelayMs = kWsInitialReconnectMs;
  Timer? _reconnectTimer;

  /// Buffered outbound messages accumulated while disconnected.
  final List<Uint8List> _outboundBuffer = [];
  int _outboundBufferBytes = 0;

  final ServerMessageCallback _onServerMessage;
  final ServerConnectionCallback _onConnectionChanged;

  WebSocketService({
    required ServerMessageCallback onServerMessage,
    required ServerConnectionCallback onConnectionChanged,
  })  : _onServerMessage = onServerMessage,
        _onConnectionChanged = onConnectionChanged;

  // ─── Public API ───────────────────────────────────────────────────────────

  bool get isConnected => _isConnected;

  /// Connects to [serverUrl] with automatic reconnection.
  /// Safe to call repeatedly – subsequent calls update the URL and reconnect.
  Future<void> connect(String serverUrl) async {
    _serverUrl = serverUrl;
    _shouldReconnect = true;
    await _openConnection();
  }

  /// Permanently disconnects and stops reconnection attempts.
  Future<void> disconnect() async {
    _shouldReconnect = false;
    _reconnectTimer?.cancel();
    await _closeChannel();
  }

  /// Sends an encrypted binary payload to the server.
  ///
  /// If currently disconnected, the message is buffered (up to
  /// [kWsBufferMaxBytes]). Older messages are dropped to make room when the
  /// buffer is full.
  void send(Uint8List encryptedPayload) {
    if (_isConnected && _channel != null) {
      _flushBuffer(); // flush any buffered messages first
      _channel!.sink.add(encryptedPayload);
    } else {
      _bufferMessage(encryptedPayload);
    }
  }

  // ─── Private – Connection ─────────────────────────────────────────────────

  Future<void> _openConnection() async {
    if (_serverUrl == null) return;
    await _closeChannel();

    try {
      _channel = WebSocketChannel.connect(Uri.parse(_serverUrl!));

      // Wait for the handshake to complete.
      await _channel!.ready;

      _channelSub = _channel!.stream.listen(
        _onRawMessage,
        onError: (_) => _onChannelClosed(),
        onDone: _onChannelClosed,
        cancelOnError: true,
      );

      _isConnected = true;
      _reconnectDelayMs = kWsInitialReconnectMs;
      _onConnectionChanged(true);
      _flushBuffer();
    } catch (_) {
      // Connection attempt failed – schedule retry.
      _scheduleReconnect();
    }
  }

  Future<void> _closeChannel() async {
    await _channelSub?.cancel();
    _channelSub = null;
    try {
      await _channel?.sink.close();
    } catch (_) {}
    _channel = null;
    if (_isConnected) {
      _isConnected = false;
      _onConnectionChanged(false);
    }
  }

  void _onChannelClosed() {
    _isConnected = false;
    _onConnectionChanged(false);
    _scheduleReconnect();
  }

  void _scheduleReconnect() {
    if (!_shouldReconnect) return;
    _reconnectTimer?.cancel();
    _reconnectTimer = Timer(
      Duration(milliseconds: _reconnectDelayMs),
      () => _openConnection(),
    );
    // Exponential back-off with jitter.
    _reconnectDelayMs = min(_reconnectDelayMs * 2, kWsMaxReconnectMs);
  }

  // ─── Private – Message Handling ──────────────────────────────────────────

  void _onRawMessage(dynamic data) {
    if (data is List<int>) {
      _onServerMessage(Uint8List.fromList(data));
    } else if (data is Uint8List) {
      _onServerMessage(data);
    }
    // Text frames are ignored (protocol is binary-only).
  }

  // ─── Private – Outbound Buffer ────────────────────────────────────────────

  void _bufferMessage(Uint8List payload) {
    // If adding this message would exceed the byte cap, evict the oldest entries.
    while (_outboundBufferBytes + payload.length > kWsBufferMaxBytes &&
        _outboundBuffer.isNotEmpty) {
      final evicted = _outboundBuffer.removeAt(0);
      _outboundBufferBytes -= evicted.length;
    }
    _outboundBuffer.add(payload);
    _outboundBufferBytes += payload.length;
  }

  void _flushBuffer() {
    if (_outboundBuffer.isEmpty || !_isConnected || _channel == null) return;
    final toSend = List<Uint8List>.from(_outboundBuffer);
    _outboundBuffer.clear();
    _outboundBufferBytes = 0;
    for (final msg in toSend) {
      _channel!.sink.add(msg);
    }
  }
}

