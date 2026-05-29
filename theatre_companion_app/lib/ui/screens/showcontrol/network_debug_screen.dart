import 'dart:async';
import 'dart:io';

import 'package:fixnum/fixnum.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../showcontrol/grpc/generated/stagesync/v1/common.pb.dart';
import '../../../showcontrol/grpc/generated/stagesync/v1/node.pb.dart';
import '../../../showcontrol/grpc/stage_sync_client.dart';
import '../../../showcontrol/nodes/audio_node/audio_node_service.dart';
import '../../../showcontrol/nodes/audio_node/sweep_generator.dart';
import '../../../showcontrol/providers/audio_node_provider.dart';
import '../../../showcontrol/providers/session_provider.dart';

const _bg = Color(0xFF0A0A0A);
const _surface = Color(0xFF141414);
const _accent = Color(0xFF00E5FF);

class NetworkDebugScreen extends ConsumerStatefulWidget {
  const NetworkDebugScreen({super.key});

  @override
  ConsumerState<NetworkDebugScreen> createState() => _NetworkDebugScreenState();
}

class _NetworkDebugScreenState extends ConsumerState<NetworkDebugScreen> {
  final Map<String, _PingResult> _pingResults = {};
  final Map<String, bool> _audioRunning = {};
  bool _pingAllRunning = false;
  List<NodeInfo>? _serverNodes;
  String? _serverFetchError;
  bool _fetchingServer = false;
  String? _reregisterResult;
  bool _reregistering = false;

  @override
  Widget build(BuildContext context) {
    final session = ref.watch(sessionProvider);
    final audioStatus = ref.watch(audioNodeProvider);
    final nodes = session.session?.nodes.toList() ?? <NodeInfo>[];
    final myId = session.myNode?.nodeId ?? '';

    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        backgroundColor: _surface,
        title: const Text('Netzwerk-Debug', style: TextStyle(color: Colors.white)),
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          TextButton.icon(
            icon: _reregistering
                ? const SizedBox(width: 14, height: 14,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.purple))
                : const Icon(Icons.refresh, color: Colors.purple),
            label: Text(_reregistering ? '…' : 'Re-Reg',
                style: const TextStyle(color: Colors.purple)),
            onPressed: _reregistering ? null : () => _reRegister(session, audioStatus),
          ),
          TextButton.icon(
            icon: _fetchingServer
                ? const SizedBox(width: 14, height: 14,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.orange))
                : const Icon(Icons.cloud_download, color: Colors.orange),
            label: Text(_fetchingServer ? '…' : 'Server',
                style: const TextStyle(color: Colors.orange)),
            onPressed: _fetchingServer ? null : () => _fetchFromServer(session),
          ),
          TextButton.icon(
            icon: _pingAllRunning
                ? const SizedBox(
                    width: 14,
                    height: 14,
                    child: CircularProgressIndicator(strokeWidth: 2, color: _accent))
                : const Icon(Icons.radar, color: _accent),
            label: Text(
              _pingAllRunning ? 'Läuft…' : 'Alle pingen',
              style: const TextStyle(color: _accent),
            ),
            onPressed: _pingAllRunning ? null : () => _pingAll(nodes),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Column(
        children: [
          // ── Lokaler Audio-Node Status ──────────────────────────────────────
          _LocalAudioDiag(
            audioStatus: audioStatus,
            directUrl: ref.read(audioNodeProvider.notifier).mediaServerUrl,
            myNodeId: myId,
            sessionNodeUrl: session.session?.nodes
                .where((n) => n.nodeId == myId)
                .map((n) => n.mediaServerUrl)
                .firstOrNull,
          ),
          // ── Server-Antwort (ListNodes) ─────────────────────────────────────
          if (_reregisterResult != null)
            Container(
              color: const Color(0xFF0F0A0F),
              padding: const EdgeInsets.fromLTRB(12, 6, 12, 6),
              child: Row(children: [
                const Icon(Icons.info_outline, size: 12, color: Colors.purple),
                const SizedBox(width: 6),
                Expanded(child: Text(_reregisterResult!,
                    style: const TextStyle(color: Colors.purple, fontSize: 10, fontFamily: 'monospace'))),
              ]),
            ),
          if (_serverNodes != null || _serverFetchError != null)
            _ServerNodesDiag(nodes: _serverNodes, error: _serverFetchError),

          // ── Node-Liste ─────────────────────────────────────────────────────
          Expanded(
            child: nodes.isEmpty
                ? const Center(
                    child: Text('Keine Nodes verbunden.',
                        style: TextStyle(color: Colors.white38)))
                : ListView.builder(
                    padding: const EdgeInsets.all(12),
                    itemCount: nodes.length,
                    itemBuilder: (ctx, i) {
                      final node = nodes[i];
                      final isMe = node.nodeId == myId;
                      final isAudioNode =
                          node.tasks.contains(NodeTask.NODE_TASK_AUDIO_OUTPUT);
                      return _NodeDebugCard(
                        node: node,
                        isMe: isMe,
                        pingResult: _pingResults[node.nodeId],
                        audioRunning: _audioRunning[node.nodeId] ?? false,
                        canAudioTest: isAudioNode &&
                            (node.mediaServerUrl.isNotEmpty || isMe),
                        onPing: () => _pingNode(node),
                        onAudioTest: () => _runAudioTest(node, audioStatus, session),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Future<void> _reRegister(SessionState session, AudioNodeStatus audioStatus) async {
    if (!session.isInSession) return;
    final url = ref.read(audioNodeProvider.notifier).mediaServerUrl ?? '';
    final myNode = session.myNode;
    if (myNode == null) return;

    setState(() { _reregistering = true; _reregisterResult = null; });
    try {
      final caps = NodeCapabilities(
        audio: AudioCapabilities(
          maxSimultaneous: 8,
          mediaServerUrl: url,
        ),
      );
      final req = RegisterNodeRequest(
        sessionId: session.session!.sessionId,
        token: session.token!,
        node: NodeInfo(
          nodeId: myNode.nodeId,
          name: myNode.name,
          nodeType: myNode.nodeType,
          tasks: myNode.tasks,
          online: true,
          mediaServerUrl: url,  // URL direkt in NodeInfo
        ),
        capabilities: caps,
      );
      final resp = await StageSyncClient.instance.node.registerNode(req);
      final respUrl = resp.node.mediaServerUrl;
      setState(() {
        _reregisterResult =
            'SENT url="$url"\nRESP nodeId=${resp.node.nodeId} url="${respUrl.isEmpty ? "(leer!)" : respUrl}"';
        _reregistering = false;
      });
      // Sofort ListNodes um Server-Stand zu sehen
      await _fetchFromServer(session);
    } catch (e) {
      setState(() { _reregisterResult = 'FEHLER: $e'; _reregistering = false; });
    }
  }

  Future<void> _fetchFromServer(SessionState session) async {
    if (!session.isInSession) return;
    setState(() { _fetchingServer = true; _serverFetchError = null; });
    try {
      final resp = await StageSyncClient.instance.node.listNodes(
        ListNodesRequest(
          sessionId: session.session!.sessionId,
          token: session.token!,
        ),
      );
      if (mounted) setState(() { _serverNodes = resp.nodes.toList(); _fetchingServer = false; });
    } catch (e) {
      if (mounted) setState(() { _serverFetchError = '$e'; _fetchingServer = false; });
    }
  }

  Future<void> _pingAll(List<NodeInfo> nodes) async {
    setState(() => _pingAllRunning = true);
    await Future.wait(nodes.map(_pingNode));
    if (mounted) setState(() => _pingAllRunning = false);
  }

  Future<void> _pingNode(NodeInfo node) async {
    final url = node.mediaServerUrl;
    if (url.isEmpty) {
      setState(() => _pingResults[node.nodeId] = _PingResult.noUrl());
      return;
    }
    setState(() => _pingResults[node.nodeId] = _PingResult.running());
    final sw = Stopwatch()..start();
    try {
      final client = HttpClient()
        ..connectionTimeout = const Duration(seconds: 3);
      final req = await client.getUrl(Uri.parse('$url/health'));
      final resp = await req.close().timeout(const Duration(seconds: 3));
      final body = await resp.transform(const SystemEncoding().decoder).join();
      sw.stop();
      client.close();
      if (mounted) {
        setState(() => _pingResults[node.nodeId] =
            _PingResult.ok(rttMs: sw.elapsedMilliseconds, body: body));
      }
    } on TimeoutException {
      if (mounted) {
        setState(() => _pingResults[node.nodeId] = _PingResult.error('Timeout (3 s)'));
      }
    } catch (e) {
      if (mounted) {
        setState(() => _pingResults[node.nodeId] = _PingResult.error('$e'));
      }
    }
  }

  Future<void> _runAudioTest(
      NodeInfo node, AudioNodeStatus audioStatus, SessionState session) async {
    setState(() => _audioRunning[node.nodeId] = true);
    try {
      final wav = SweepGenerator.generateTone(
          frequencyHz: 1000, durationSeconds: 1.5, amplitude: 0.7);
      final myId = session.myNode?.nodeId ?? '';

      if (node.nodeId == myId) {
        final notifier = ref.read(audioNodeProvider.notifier);
        await notifier.playWavBytesLocally('__debug__', wav);
        await Future.delayed(const Duration(milliseconds: 1700));
        await notifier.stopLocalPlayback('__debug__');
      } else {
        if (node.mediaServerUrl.isEmpty) {
          _snack('${node.name}: kein MediaServer-URL');
          return;
        }
        final ok = await _uploadWav(node.mediaServerUrl, '__debug__.wav', wav);
        if (!ok) {
          _snack('Upload zu ${node.name} fehlgeschlagen');
          return;
        }
        await _sendPreloadAndPlay(
          sessionId: session.session!.sessionId,
          token: session.token!,
          nodeId: node.nodeId,
        );
      }
    } catch (e) {
      _snack('Fehler: $e');
    } finally {
      if (mounted) setState(() => _audioRunning[node.nodeId] = false);
    }
  }

  Future<bool> _uploadWav(String baseUrl, String filename, List<int> data) async {
    try {
      const boundary = '----DebugBoundary';
      final header =
          '--$boundary\r\nContent-Disposition: form-data; name="file"; '
          'filename="$filename"\r\nContent-Type: audio/wav\r\n\r\n';
      const footer = '\r\n--$boundary--\r\n';
      final body = [...header.codeUnits, ...data, ...footer.codeUnits];

      final client = HttpClient();
      final req = await client.postUrl(Uri.parse('$baseUrl/media/upload'));
      req.headers.set('Content-Type', 'multipart/form-data; boundary=$boundary');
      req.contentLength = body.length;
      req.add(body);
      final resp = await req.close().timeout(const Duration(seconds: 10));
      await resp.drain<void>();
      client.close();
      return resp.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  Future<void> _sendPreloadAndPlay({
    required String sessionId,
    required String token,
    required String nodeId,
  }) async {
    const cueId = '__debug__';
    const filename = '__debug__.wav';
    final startAt = DateTime.now().millisecondsSinceEpoch + 600;
    final grpc = StageSyncClient.instance;

    await grpc.node.sendNodeCommand(SendNodeCommandRequest(
      sessionId: sessionId,
      token: token,
      targetNodeId: nodeId,
      command: NodeCommandRequest(
        sessionId: sessionId,
        targetNodeId: nodeId,
        audioPreload: AudioPreloadCommand(cueId: cueId, filePath: filename),
      ),
    ));

    await grpc.node.sendNodeCommand(SendNodeCommandRequest(
      sessionId: sessionId,
      token: token,
      targetNodeId: nodeId,
      command: NodeCommandRequest(
        sessionId: sessionId,
        targetNodeId: nodeId,
        audioPlay: AudioPlayCommand(
          cueId: cueId,
          startUnixMillis: Int64(startAt),
          volumeDb: 0.0,
        ),
      ),
    ));
  }

  void _snack(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: Colors.red[800]),
    );
  }
}

// ── Ping-Ergebnis ─────────────────────────────────────────────────────────────

enum _PingState { idle, running, ok, error, noUrl }

class _PingResult {
  final _PingState state;
  final int? rttMs;
  final String? errorMsg;
  final String? body;

  const _PingResult._(this.state, {this.rttMs, this.errorMsg, this.body});
  factory _PingResult.running() => const _PingResult._(_PingState.running);
  factory _PingResult.ok({required int rttMs, required String body}) =>
      _PingResult._(_PingState.ok, rttMs: rttMs, body: body);
  factory _PingResult.error(String msg) =>
      _PingResult._(_PingState.error, errorMsg: msg);
  factory _PingResult.noUrl() => const _PingResult._(_PingState.noUrl);
}

// ── Node-Karte ────────────────────────────────────────────────────────────────

class _NodeDebugCard extends StatelessWidget {
  final NodeInfo node;
  final bool isMe;
  final _PingResult? pingResult;
  final bool audioRunning;
  final bool canAudioTest;
  final VoidCallback onPing;
  final VoidCallback onAudioTest;

  const _NodeDebugCard({
    required this.node,
    required this.isMe,
    required this.pingResult,
    required this.audioRunning,
    required this.canAudioTest,
    required this.onPing,
    required this.onAudioTest,
  });

  @override
  Widget build(BuildContext context) {
    final hasPingError = pingResult?.state == _PingState.error;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: isMe ? _accent.withValues(alpha: 0.35) : Colors.white12,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Kopfzeile
            Row(
              children: [
                Icon(
                  node.online ? Icons.circle : Icons.circle_outlined,
                  size: 10,
                  color: node.online ? Colors.green : Colors.red,
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(node.name,
                      style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                          fontSize: 14)),
                ),
                if (isMe)
                  _Chip('dieses Gerät', _accent),
                const SizedBox(width: 8),
                _PingBadge(result: pingResult),
              ],
            ),

            const SizedBox(height: 6),

            // MediaServer-URL
            Row(
              children: [
                Icon(Icons.http, size: 12,
                    color: node.mediaServerUrl.isEmpty ? Colors.red[400] : Colors.white24),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    node.mediaServerUrl.isEmpty ? 'Kein MediaServer-URL' : node.mediaServerUrl,
                    style: TextStyle(
                      color: node.mediaServerUrl.isEmpty ? Colors.red[300] : Colors.white38,
                      fontSize: 11,
                      fontFamily: 'monospace',
                    ),
                  ),
                ),
              ],
            ),

            // Ping-Fehlermeldung
            if (hasPingError) ...[
              const SizedBox(height: 4),
              Text(pingResult!.errorMsg ?? '',
                  style: const TextStyle(color: Colors.red, fontSize: 11)),
            ],

            // Ping-Antwort-Body
            if (pingResult?.state == _PingState.ok &&
                pingResult!.body != null) ...[
              const SizedBox(height: 4),
              Text(pingResult!.body!,
                  style: const TextStyle(
                      color: Colors.white24, fontSize: 10, fontFamily: 'monospace')),
            ],

            const SizedBox(height: 10),

            // Buttons
            Row(
              children: [
                _DebugButton(
                  label: pingResult?.state == _PingState.running ? 'Läuft…' : 'Ping',
                  icon: Icons.network_ping,
                  color: Colors.blue,
                  enabled: pingResult?.state != _PingState.running,
                  onPressed: onPing,
                ),
                const SizedBox(width: 8),
                _DebugButton(
                  label: audioRunning ? 'Spielt…' : '1-kHz-Test',
                  icon: Icons.volume_up,
                  color: Colors.green,
                  enabled: canAudioTest && !audioRunning,
                  onPressed: onAudioTest,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  final String label;
  final Color color;
  const _Chip(this.label, this.color);

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Text(label, style: TextStyle(color: color, fontSize: 10)),
      );
}

class _PingBadge extends StatelessWidget {
  final _PingResult? result;
  const _PingBadge({required this.result});

  @override
  Widget build(BuildContext context) {
    if (result == null) return const SizedBox.shrink();
    switch (result!.state) {
      case _PingState.running:
        return const SizedBox(
            width: 14,
            height: 14,
            child: CircularProgressIndicator(strokeWidth: 2, color: _accent));
      case _PingState.ok:
        return _badge('Pong  ${result!.rttMs} ms', Colors.green);
      case _PingState.error:
        return _badge('Fehler', Colors.red);
      case _PingState.noUrl:
        return _badge('Kein URL', Colors.orange);
      case _PingState.idle:
        return const SizedBox.shrink();
    }
  }

  Widget _badge(String text, Color color) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.35)),
        ),
        child: Text(text,
            style: TextStyle(
                color: color, fontSize: 11, fontFamily: 'monospace')),
      );
}

// ── Server-Nodes Diagnose ─────────────────────────────────────────────────────

class _ServerNodesDiag extends StatelessWidget {
  final List<NodeInfo>? nodes;
  final String? error;
  const _ServerNodesDiag({required this.nodes, required this.error});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFF0A0F0A),
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('SERVER (ListNodes)',
              style: TextStyle(color: Colors.orange, fontSize: 10, fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          if (error != null)
            Text(error!, style: const TextStyle(color: Colors.red, fontSize: 10))
          else if (nodes == null)
            const Text('—', style: TextStyle(color: Colors.white24, fontSize: 10))
          else
            ...nodes!.map((n) => Padding(
              padding: const EdgeInsets.only(bottom: 2),
              child: Row(children: [
                Expanded(child: Text(n.name,
                    style: const TextStyle(color: Colors.white54, fontSize: 10))),
                Expanded(flex: 2, child: Text(
                  n.mediaServerUrl.isEmpty ? '(leer)' : n.mediaServerUrl,
                  style: TextStyle(
                    color: n.mediaServerUrl.isEmpty ? Colors.red : Colors.orange,
                    fontSize: 10, fontFamily: 'monospace'),
                )),
              ]),
            )),
        ],
      ),
    );
  }
}

// ── Lokale Audio-Node Diagnose ────────────────────────────────────────────────

class _LocalAudioDiag extends StatelessWidget {
  final AudioNodeStatus audioStatus;
  final String? directUrl;     // _mediaServer.serverUrl direkt aus dem Service
  final String myNodeId;
  final String? sessionNodeUrl; // URL die in session.nodes steht

  const _LocalAudioDiag({
    required this.audioStatus,
    required this.directUrl,
    required this.myNodeId,
    required this.sessionNodeUrl,
  });

  @override
  Widget build(BuildContext context) {
    final stateColor = switch (audioStatus.state) {
      AudioNodeState.connected => Colors.green,
      AudioNodeState.error     => Colors.red,
      _                        => Colors.white38,
    };
    final stateLabel = switch (audioStatus.state) {
      AudioNodeState.connected => 'CONNECTED',
      AudioNodeState.error     => 'ERROR',
      _                        => 'IDLE',
    };

    return Container(
      color: const Color(0xFF0F0F1A),
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            const Text('Audio-Node (dieses Gerät)',
                style: TextStyle(color: Colors.white54, fontSize: 11, fontWeight: FontWeight.bold)),
            const Spacer(),
            _Chip(stateLabel, stateColor),
          ]),
          const SizedBox(height: 6),
          _DiagRow('Service-URL', directUrl?.isEmpty ?? true ? '(leer)' : directUrl!,
              directUrl?.isNotEmpty == true ? Colors.green : Colors.orange),
          _DiagRow('Session-URL', sessionNodeUrl?.isEmpty ?? true ? '(leer)' : sessionNodeUrl!,
              sessionNodeUrl?.isNotEmpty == true ? Colors.green : Colors.red),
          _DiagRow('myNodeId', myNodeId.isEmpty ? '(leer)' : myNodeId,
              myNodeId.isNotEmpty ? Colors.white38 : Colors.red),
          _DiagRow('Iface', audioStatus.selectedInterface?.toString() ?? '(keine gewählt)',
              audioStatus.selectedInterface != null ? Colors.white38 : Colors.orange),
          if (audioStatus.state == AudioNodeState.error && audioStatus.errorMessage != null)
            _DiagRow('Fehler', audioStatus.errorMessage!, Colors.red),
        ],
      ),
    );
  }
}

class _DiagRow extends StatelessWidget {
  final String label;
  final String value;
  final Color valueColor;
  const _DiagRow(this.label, this.value, this.valueColor);

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 1),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 90,
              child: Text(label,
                  style: const TextStyle(color: Colors.white24, fontSize: 10)),
            ),
            Expanded(
              child: Text(value,
                  style: TextStyle(
                      color: valueColor,
                      fontSize: 10,
                      fontFamily: 'monospace')),
            ),
          ],
        ),
      );
}

class _DebugButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final bool enabled;
  final VoidCallback onPressed;

  const _DebugButton({
    required this.label,
    required this.icon,
    required this.color,
    required this.enabled,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) => OutlinedButton.icon(
        style: OutlinedButton.styleFrom(
          foregroundColor: enabled ? color : Colors.white24,
          side: BorderSide(
              color: enabled ? color.withValues(alpha: 0.5) : Colors.white12),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        ),
        icon: Icon(icon, size: 15),
        label: Text(label, style: const TextStyle(fontSize: 12)),
        onPressed: enabled ? onPressed : null,
      );
}
