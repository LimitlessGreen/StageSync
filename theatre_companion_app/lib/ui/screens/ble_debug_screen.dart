/// ble_debug_screen.dart
/// ─────────────────────
/// Dedizierter BLE-Diagnose-Bildschirm für StageSync.
///
/// Zeigt in Echtzeit:
///   • Adapter-Status (Advertising, Scanning, Fallback-Modus)
///   • Entdeckte Peers mit RSSI, Score und Leader-Badge
///   • Live-Log der letzten 200 BLE-Ereignisse (Errors + Status-Meldungen)
///   • Cloud-Verbindungsstatus
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/network_state_provider.dart';
import '../../network/isolate/isolate_messages.dart';

// ─── BLE Log Provider ────────────────────────────────────────────────────────

/// Hält die letzten 200 BLE-Log-Einträge (aus [BleStatusEvent] + Timestamps).
class _BleLogEntry {
  final DateTime time;
  final String message;
  final bool isError;
  _BleLogEntry(this.message, {this.isError = false}) : time = DateTime.now();
}

class _BleLogNotifier extends StateNotifier<List<_BleLogEntry>> {
  static const int _maxEntries = 200;

  _BleLogNotifier(Ref ref) : super(const []) {
    // BleStatusEvent → Log
    ref.listen<AsyncValue<NetworkEvent>>(
      networkEventStreamProvider,
      (_, next) {
        next.whenData((event) {
          if (event is BleStatusEvent) {
            final msg = event.errorMessage;
            if (msg != null && msg.isNotEmpty) {
              _add(msg, isError: true);
            }
          }
          if (event is NetworkStatusEvent) {
            // Peer-Topologie-Änderungen loggen
            final count = event.connectedPeerCount;
            if (count != _lastPeerCount) {
              _lastPeerCount = count;
              _add('Peer-Anzahl: $count (${event.peers.map((p) => p.shortId).join(', ')})');
            }
          }
        });
      },
    );
    // bleRawLogStreamProvider → alle BLE-Nachrichten (auch reine Status-Meldungen)
    ref.listen<AsyncValue<BleStatusEvent>>(
      bleRawLogStreamProvider,
      (_, next) {
        next.whenData((e) {
          // Vollständige Status-Info als Log-Zeile
          final adv  = e.isAdvertising ? '📡adv' : '○adv';
          final scan = e.isScanning    ? (e.isFallbackScanMode ? '🔍fb' : '🔍scan') : '○scan';
          final conn = '🔗${e.activeConnectionCount}';
          final msg  = e.errorMessage ?? '';
          _add('[$adv $scan $conn] $msg', isError: msg.contains('fehlgeschlagen') || msg.contains('Error') || msg.contains('timeout'));
        });
      },
    );
  }

  int _lastPeerCount = -1;

  void addEntry(String message, {bool isError = false}) {
    _add(message, isError: isError);
  }

  void _add(String message, {bool isError = false}) {
    final entries = List<_BleLogEntry>.from(state);
    entries.insert(0, _BleLogEntry(message, isError: isError));
    if (entries.length > _maxEntries) {
      entries.removeLast();
    }
    state = entries;
  }

  void clear() => state = const [];
}

final _bleLogProvider =
    StateNotifierProvider<_BleLogNotifier, List<_BleLogEntry>>(
  (ref) => _BleLogNotifier(ref),
);

/// Schreibt einen manuellen Log-Eintrag (z.B. bei manuell ausgelöstem Scan).
final bleDebugLogProvider =
    Provider<_BleLogNotifier>((ref) => ref.watch(_bleLogProvider.notifier));

// ─────────────────────────────────────────────────────────────────────────────

class BleDebugScreen extends ConsumerStatefulWidget {
  const BleDebugScreen({super.key});

  @override
  ConsumerState<BleDebugScreen> createState() => _BleDebugScreenState();
}

class _BleDebugScreenState extends ConsumerState<BleDebugScreen> {
  // Für Auto-Scroll im Log
  final ScrollController _logScrollCtrl = ScrollController();

  @override
  void dispose() {
    _logScrollCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bleStatus    = ref.watch(bleStatusProvider);
    final netStatus    = ref.watch(networkStatusProvider);
    final peers        = ref.watch(peerListProvider);
    final isCloud      = ref.watch(isCloudConnectedProvider);
    final isLeader     = ref.watch(isLeaderProvider);
    final logEntries   = ref.watch(_bleLogProvider);
    final score        = ref.watch(scoreBreakdownProvider);

    // BLE-Ereignisse aus BleStatusEvent in den Log übernehmen
    ref.listen<BleStatusEvent?>(bleStatusProvider, (prev, next) {
      if (next?.errorMessage != null && next!.errorMessage!.isNotEmpty) {
        // Bereits durch _BleLogNotifier erfasst
      }
    });

    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('BLE-Diagnose'),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_sweep_outlined),
            tooltip: 'Log leeren',
            onPressed: () => ref.read(_bleLogProvider.notifier).clear(),
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Status manuell abfragen',
            onPressed: () {
              final manager =
                  ref.read(networkIsolateManagerProvider).valueOrNull;
              manager?.send(QueryStatusCommand());
              ref
                  .read(_bleLogProvider.notifier)
                  .addEntry('[UI] QueryStatusCommand gesendet.');
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // ── Adapter-Status-Kacheln ──────────────────────────────────────
          _StatusRow(
            bleStatus: bleStatus,
            netStatus: netStatus,
            isCloud: isCloud,
            isLeader: isLeader,
            score: score,
          ),

          const Divider(height: 1),

          // ── Peer-Liste ─────────────────────────────────────────────────
          if (peers.isNotEmpty) ...[
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
              child: Row(
                children: [
                  Icon(Icons.bluetooth_connected,
                      size: 16, color: colorScheme.primary),
                  const SizedBox(width: 6),
                  Text(
                    'BLE-Peers (${peers.length})',
                    style: theme.textTheme.labelLarge
                        ?.copyWith(color: colorScheme.primary),
                  ),
                ],
              ),
            ),
            SizedBox(
              height: 110,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                itemCount: peers.length,
                itemBuilder: (_, i) => _PeerCard(peer: peers[i]),
              ),
            ),
            const Divider(height: 1),
          ],

          // ── BLE Event Log ───────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
            child: Row(
              children: [
                Icon(Icons.terminal,
                    size: 16, color: colorScheme.onSurfaceVariant),
                const SizedBox(width: 6),
                Text(
                  'Live-Log (${logEntries.length} Einträge)',
                  style: theme.textTheme.labelMedium
                      ?.copyWith(color: colorScheme.onSurfaceVariant),
                ),
              ],
            ),
          ),
          Expanded(
            child: logEntries.isEmpty
                ? Center(
                    child: Text(
                      'Kein BLE-Ereignis bisher.\nBLE startet nach dem App-Start automatisch.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: colorScheme.onSurfaceVariant),
                    ),
                  )
                : ListView.builder(
                    controller: _logScrollCtrl,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 4),
                    itemCount: logEntries.length,
                    itemBuilder: (_, i) => _LogEntryTile(logEntries[i]),
                  ),
          ),
        ],
      ),
    );
  }
}

// ─── Status-Zeile ────────────────────────────────────────────────────────────

class _StatusRow extends StatelessWidget {
  final BleStatusEvent? bleStatus;
  final NetworkStatusEvent? netStatus;
  final bool isCloud;
  final bool isLeader;
  final NetworkScoreBreakdown score;

  const _StatusRow({
    required this.bleStatus,
    required this.netStatus,
    required this.isCloud,
    required this.isLeader,
    required this.score,
  });

  @override
  Widget build(BuildContext context) {
    final adv  = bleStatus?.isAdvertising ?? false;
    final scan = bleStatus?.isScanning    ?? false;
    final fallb = bleStatus?.isFallbackScanMode ?? false;
    final conns = bleStatus?.activeConnectionCount ?? 0;
    final peers = netStatus?.connectedPeerCount ?? 0;
    final queue = netStatus?.pendingQueuedPackets ?? 0;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          _Chip(
            icon: Icons.cell_tower,
            label: 'Advertising',
            active: adv,
            activeColor: Colors.green,
          ),
          _Chip(
            icon: Icons.radar,
            label: scan ? (fallb ? 'Scan (Fallback)' : 'Scan') : 'Scan aus',
            active: scan,
            activeColor: fallb ? Colors.orange : Colors.blue,
          ),
          _Chip(
            icon: Icons.cable,
            label: '$conns GATT',
            active: conns > 0,
            activeColor: Colors.teal,
          ),
          _Chip(
            icon: Icons.people,
            label: '$peers Peer(s)',
            active: peers > 0,
            activeColor: Colors.indigo,
          ),
          _Chip(
            icon: Icons.cloud_done,
            label: isCloud ? 'Cloud ✓' : 'Cloud ✗',
            active: isCloud,
            activeColor: Colors.purple,
          ),
          _Chip(
            icon: Icons.star,
            label: isLeader ? 'Leader' : 'Follower',
            active: isLeader,
            activeColor: Colors.amber,
          ),
          _Chip(
            icon: Icons.hourglass_top,
            label: '$queue Queued',
            active: queue > 0,
            activeColor: Colors.deepOrange,
          ),
          _Chip(
            icon: Icons.analytics_outlined,
            label: 'Score ${score.total}',
            active: true,
            activeColor: Colors.grey,
          ),
        ],
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool active;
  final Color activeColor;

  const _Chip({
    required this.icon,
    required this.label,
    required this.active,
    required this.activeColor,
  });

  @override
  Widget build(BuildContext context) {
    final color = active ? activeColor : Colors.grey.shade400;
    return Chip(
      avatar: Icon(icon, size: 16, color: color),
      label: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          color: active ? color : Colors.grey.shade500,
          fontWeight: active ? FontWeight.bold : FontWeight.normal,
        ),
      ),
      backgroundColor: active
          ? activeColor.withAlpha(26)
          : Colors.grey.shade100,
      side: BorderSide(color: color.withAlpha(77), width: 1),
      padding: const EdgeInsets.symmetric(horizontal: 2),
      visualDensity: VisualDensity.compact,
    );
  }
}

// ─── Peer-Karte ──────────────────────────────────────────────────────────────

class _PeerCard extends StatelessWidget {
  final PeerStatusInfo peer;
  const _PeerCard({required this.peer});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bars  = peer.signalBars;
    final barColor = bars >= 3
        ? Colors.green
        : bars >= 2
            ? Colors.orange
            : Colors.red;

    return Card(
      margin: const EdgeInsets.only(right: 8, bottom: 4, top: 4),
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.bluetooth, size: 14, color: barColor),
                const SizedBox(width: 4),
                // Signal-Balken
                ...List.generate(
                  4,
                  (i) => Container(
                    width: 4,
                    height: 6.0 + i * 3,
                    margin: const EdgeInsets.only(right: 1),
                    decoration: BoxDecoration(
                      color: i < bars ? barColor : Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(1),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              peer.shortId,
              style: theme.textTheme.labelSmall
                  ?.copyWith(fontFamily: 'monospace', fontSize: 10),
            ),
            Text(
              '${peer.rssi} dBm',
              style: TextStyle(fontSize: 10, color: barColor),
            ),
            Text(
              'S: ${peer.electionScore}',
              style: theme.textTheme.labelSmall,
            ),
            if (peer.isLeader)
              const Text(
                '★ Leader',
                style: TextStyle(
                  fontSize: 9,
                  color: Colors.amber,
                  fontWeight: FontWeight.bold,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// ─── Log-Eintrag ─────────────────────────────────────────────────────────────

class _LogEntryTile extends StatelessWidget {
  final _BleLogEntry entry;
  const _LogEntryTile(this.entry);

  @override
  Widget build(BuildContext context) {
    final time = '${entry.time.hour.toString().padLeft(2, '0')}:'
        '${entry.time.minute.toString().padLeft(2, '0')}:'
        '${entry.time.second.toString().padLeft(2, '0')}.'
        '${(entry.time.millisecond ~/ 10).toString().padLeft(2, '0')}';

    final color =
        entry.isError ? Colors.red.shade700 : Colors.blueGrey.shade700;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 1),
      child: RichText(
        text: TextSpan(
          children: [
            TextSpan(
              text: '$time  ',
              style: const TextStyle(
                fontFamily: 'monospace',
                fontSize: 10,
                color: Colors.grey,
              ),
            ),
            if (entry.isError)
              const TextSpan(
                text: '⚠ ',
                style: TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 10,
                  color: Colors.red,
                  fontWeight: FontWeight.bold,
                ),
              ),
            TextSpan(
              text: entry.message,
              style: TextStyle(
                fontFamily: 'monospace',
                fontSize: 10,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}



