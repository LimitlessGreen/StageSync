// home_screen.dart
// Dashboard-Startseite der StageSync App.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../main.dart' show selectedTabProvider;
import '../../network/isolate/isolate_messages.dart';
import '../../showcontrol/grpc/generated/stagesync/v1/common.pb.dart';
import '../../showcontrol/providers/session_provider.dart';
import '../providers/network_state_provider.dart';
import 'cloud_settings_screen.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final status = ref.watch(networkStatusProvider);
    final isLeader = ref.watch(isLeaderProvider);
    final breakdown = ref.watch(scoreBreakdownProvider);
    final isCloudConnected = ref.watch(isCloudConnectedProvider);
    final colors = Theme.of(context).colorScheme;

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // ── Hero-Header ──────────────────────────────────────────────────
          SliverAppBar(
            expandedHeight: 160,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              title: const Text('StageSync'),
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      colors.primaryContainer,
                      colors.primary.withValues(alpha: 0.7),
                    ],
                  ),
                ),
                child: Center(
                  child: Icon(
                    Icons.theater_comedy,
                    size: 64,
                    color: colors.onPrimaryContainer.withValues(alpha: 0.3),
                  ),
                ),
              ),
            ),
          ),

          SliverPadding(
            padding: const EdgeInsets.all(16),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                // ── Status-Karten-Reihe ────────────────────────────────────
                Row(
                  children: [
                    Expanded(
                      child: _StatCard(
                        icon: isLeader ? Icons.star : Icons.hub,
                        label: isLeader ? 'Leader' : 'Follower',
                        value: isLeader ? '★' : '○',
                        color: isLeader ? Colors.amber : colors.secondary,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _StatCard(
                        icon: Icons.bluetooth_connected,
                        label: 'Peers',
                        value: '${status?.connectedPeerCount ?? 0}',
                        color: colors.tertiary,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _StatCard(
                        icon: _syncIcon(status?.syncStatus),
                        label: _syncLabel(status?.syncStatus),
                        value: _syncShort(status?.syncStatus),
                        color: _syncColor(status?.syncStatus, context),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                // ── Election Score ────────────────────────────────────────
                _ScoreCard(breakdown: breakdown),

                const SizedBox(height: 16),

                // ── Warteschlange ─────────────────────────────────────────
                if ((status?.pendingQueuedPackets ?? 0) > 0)
                  _QueueWarningCard(count: status!.pendingQueuedPackets),

                const SizedBox(height: 16),

                // ── Quick-Actions ─────────────────────────────────────────
                Text('Aktionen',
                    style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 8),
                _QuickActionButton(
                  icon: Icons.how_to_vote,
                  label: 'Neue Leader-Wahl starten',
                  onTap: () {
                    ref
                        .read(networkIsolateManagerProvider)
                        .whenData((m) => m.send(ForceElectionCommand()));
                  },
                ),
                const SizedBox(height: 8),
                _QuickActionButton(
                  icon: Icons.refresh,
                  label: 'Status aktualisieren',
                  onTap: () {
                    ref
                        .read(networkIsolateManagerProvider)
                        .whenData((m) => m.send(QueryStatusCommand()));
                  },
                ),
                const SizedBox(height: 8),

                // ── Show Control Karte ────────────────────────────────────
                _ShowControlCard(
                  session: ref.watch(sessionProvider),
                  onTap: () =>
                      ref.read(selectedTabProvider.notifier).state = 4,
                ),
                const SizedBox(height: 8),

                // ── Cloud Connect Karte ────────────────────────────────────
                _CloudConnectCard(
                  isConnected: isCloudConnected,
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const CloudSettingsScreen(),
                    ),
                  ),
                ),

                const SizedBox(height: 24),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  IconData _syncIcon(NetworkSyncStatus? s) => switch (s) {
        NetworkSyncStatus.syncing => Icons.cloud_sync,
        NetworkSyncStatus.upToDate => Icons.cloud_done,
        NetworkSyncStatus.meshOnly => Icons.bluetooth_connected,
        _ => Icons.cloud_off,
      };

  String _syncLabel(NetworkSyncStatus? s) => switch (s) {
        NetworkSyncStatus.syncing => 'Sync',
        NetworkSyncStatus.upToDate => 'Aktuell',
        NetworkSyncStatus.meshOnly => 'Mesh',
        _ => 'Offline',
      };

  String _syncShort(NetworkSyncStatus? s) => switch (s) {
        NetworkSyncStatus.syncing => '↑↓',
        NetworkSyncStatus.upToDate => '✓',
        NetworkSyncStatus.meshOnly => 'BLE',
        _ => '✕',
      };

  Color _syncColor(NetworkSyncStatus? s, BuildContext ctx) {
    final c = Theme.of(ctx).colorScheme;
    return switch (s) {
      NetworkSyncStatus.syncing => Colors.greenAccent,
      NetworkSyncStatus.upToDate => Colors.green,
      NetworkSyncStatus.meshOnly => c.tertiary,
      _ => Colors.redAccent,
    };
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Widgets
// ─────────────────────────────────────────────────────────────────────────────

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _StatCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
        child: Column(
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(height: 4),
            Text(value,
                style: TextStyle(
                    fontSize: 22, fontWeight: FontWeight.bold, color: color)),
            const SizedBox(height: 2),
            Text(label,
                style: Theme.of(context).textTheme.bodySmall,
                overflow: TextOverflow.ellipsis),
          ],
        ),
      ),
    );
  }
}

class _ScoreCard extends StatelessWidget {
  final NetworkScoreBreakdown breakdown;
  const _ScoreCard({required this.breakdown});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.leaderboard, size: 20),
                const SizedBox(width: 8),
                Text('Election Score',
                    style: Theme.of(context).textTheme.titleSmall),
                const Spacer(),
                Text(
                  '${breakdown.total}',
                  style: Theme.of(context)
                      .textTheme
                      .headlineSmall
                      ?.copyWith(fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _ScoreRow(
              label: 'WLAN / LTE',
              value: '+100',
              active: breakdown.hasNetwork,
              activeColor: Colors.green,
            ),
            _ScoreRow(
              label: 'Ladekabel',
              value: '+50',
              active: breakdown.isCharging,
              activeColor: Colors.orange,
            ),
            _ScoreRow(
              label: 'Akku',
              value: '+${breakdown.batteryPercent}',
              active: true,
              activeColor: Colors.teal,
            ),
            _ScoreRow(
              label: 'In Bewegung',
              value: '-20',
              active: breakdown.isMoving,
              activeColor: Colors.red,
            ),
          ],
        ),
      ),
    );
  }
}

class _ScoreRow extends StatelessWidget {
  final String label;
  final String value;
  final bool active;
  final Color activeColor;

  const _ScoreRow({
    required this.label,
    required this.value,
    required this.active,
    required this.activeColor,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Icon(
            active ? Icons.check_circle : Icons.radio_button_unchecked,
            size: 16,
            color: active ? activeColor : Colors.grey,
          ),
          const SizedBox(width: 8),
          Text(label,
              style: TextStyle(color: active ? null : Colors.grey)),
          const Spacer(),
          Text(
            value,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: active ? activeColor : Colors.grey,
            ),
          ),
        ],
      ),
    );
  }
}

class _QueueWarningCard extends StatelessWidget {
  final int count;
  const _QueueWarningCard({required this.count});

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Colors.orange.withValues(alpha: 0.15),
      child: ListTile(
        leading: const Icon(Icons.queue, color: Colors.orange),
        title: Text('$count Pakete in Warteschlange'),
        subtitle: const Text('Werden beim nächsten Peer-Kontakt gesendet'),
      ),
    );
  }
}

class _QuickActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _QuickActionButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      icon: Icon(icon),
      label: Text(label),
      onHover: null,
      onPressed: onTap,
      style: OutlinedButton.styleFrom(
        alignment: Alignment.centerLeft,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),
    );
  }
}

class _ShowControlCard extends StatelessWidget {
  final SessionState session;
  final VoidCallback onTap;

  const _ShowControlCard({required this.session, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final isActive = session.isInSession;
    final color = isActive ? const Color(0xFF00C853) : Colors.white38;

    return Card(
      color: isActive
          ? const Color(0xFF00C853).withValues(alpha: 0.12)
          : null,
      child: ListTile(
        leading: Icon(
          isActive ? Icons.play_circle : Icons.play_circle_outline,
          color: color,
          size: 28,
        ),
        title: Text(
          'Show Control',
          style: TextStyle(fontWeight: FontWeight.w600, color: color),
        ),
        subtitle: Text(
          isActive
              ? '${session.session?.showName ?? 'Session aktiv'} · '
                  '${_nodeLabel(session.myNode?.nodeType)}'
              : 'CueListen, AudioNode, GrandMA-OSC, GO-Screen',
          style: TextStyle(
            fontSize: 12,
            color: isActive ? color.withValues(alpha: 0.8) : Colors.white54,
          ),
        ),
        trailing: Icon(Icons.chevron_right, color: color),
        onTap: onTap,
      ),
    );
  }

  String _nodeLabel(NodeType? nodeType) => switch (nodeType) {
        NodeType.NODE_TYPE_AUDIO => 'Audio-Node',
        NodeType.NODE_TYPE_MA => 'GrandMA-Node',
        NodeType.NODE_TYPE_MASTER => 'Master',
        NodeType.NODE_TYPE_VIEWER => 'Viewer',
        _ => '',
      };
}

class _CloudConnectCard extends StatelessWidget {
  final bool isConnected;
  final VoidCallback onTap;

  const _CloudConnectCard({
    required this.isConnected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Colors.blue.withValues(alpha: 0.15),
      child: ListTile(
        leading: const Icon(Icons.cloud, color: Colors.blue),
        title: Text('Cloud-Verbindung'),
        subtitle: Text(isConnected ? 'Verbindung besteht' : 'Keine Verbindung'),
        onTap: onTap,
      ),
    );
  }
}
