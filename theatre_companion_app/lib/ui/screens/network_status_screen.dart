/// network_status_screen.dart
/// ───────────────────────────
/// Detaillierter Netzwerk-Status-Screen.
/// Zeigt genau was das Gerät aktuell sieht:
///   • Diese Gerät: DeviceID, Rolle, Score-Breakdown
///   • Leader-Info
///   • Server-Verbindung
///   • Vollständige Peer-Liste mit Signalstärke und Score
library network_status_screen;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../network/isolate/isolate_messages.dart';
import '../../network/platform/platform_capabilities.dart';
import '../providers/network_state_provider.dart';
import 'ble_debug_screen.dart';
class NetworkStatusScreen extends ConsumerWidget {
  const NetworkStatusScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final status = ref.watch(networkStatusProvider);
    final isLeader = ref.watch(isLeaderProvider);
    final deviceId = ref.watch(deviceIdProvider).whenData((id) => id).value
        ?? '…';
    final peers = ref.watch(peerListProvider);
    final breakdown = ref.watch(scoreBreakdownProvider);
    final capabilities = ref.watch(platformCapabilitiesProvider);
    final cloudPeers = ref.watch(cloudPeersProvider);
    final totalOnline = ref.watch(cloudTotalOnlineProvider);
    final isCloudConnected = ref.watch(isCloudConnectedProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Netzwerk-Status'),
        actions: [
          IconButton(
            icon: const Icon(Icons.bluetooth_searching),
            tooltip: 'BLE-Diagnose',
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => const BleDebugScreen(),
                ),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Status aktualisieren',
            onPressed: () {
              ref.read(networkIsolateManagerProvider).whenData(
                    (m) => m.send(QueryStatusCommand()),
                  );
            },
          ),
        ],
      ),
      body: status == null
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: () async {
                ref.read(networkIsolateManagerProvider).whenData(
                      (m) => m.send(QueryStatusCommand()),
                    );
                await Future<void>.delayed(const Duration(milliseconds: 500));
              },
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  // ── Plattform-Fähigkeiten ─────────────────────────────────
                  _SectionHeader(
                      icon: Icons.devices, title: 'Plattform-Fähigkeiten'),
                  _PlatformCapabilitiesCard(capabilities: capabilities),
                  const SizedBox(height: 16),

                  // ── Dieses Gerät ─────────────────────────────────────────
                  _SectionHeader(icon: Icons.smartphone, title: 'Dieses Gerät'),
                  _ThisDeviceCard(
                    deviceId: deviceId,
                    isLeader: isLeader,
                    score: breakdown.total,
                    breakdown: breakdown,
                  ),
                  const SizedBox(height: 16),

                  // ── Leader ────────────────────────────────────────────────
                  _SectionHeader(icon: Icons.star, title: 'Leader'),
                  _LeaderCard(
                    leaderId: status.currentLeaderId,
                    isThisDevice: isLeader,
                    hasServerConnection: status.hasServerConnection,
                  ),
                  const SizedBox(height: 16),

                  // ── Warteschlange ─────────────────────────────────────────
                  _SectionHeader(
                      icon: Icons.inbox, title: 'Warteschlange & Sync'),
                  _QueueCard(
                    pending: status.pendingQueuedPackets,
                    syncStatus: status.syncStatus,
                    hasServer: status.hasServerConnection,
                  ),
                  const SizedBox(height: 16),

                  // ── Peer-Mesh ─────────────────────────────────────────────
                  _SectionHeader(
                    icon: Icons.hub,
                    title: 'BLE Mesh Peers (${peers.length})',
                  ),
                  if (peers.isEmpty)
                    const _EmptyPeersCard()
                  else
                    ...peers.map((p) => _PeerCard(peer: p)),

                  const SizedBox(height: 16),

                  // ── Cloud Peers ───────────────────────────────────────────
                  _SectionHeader(
                    icon: Icons.cloud,
                    title: isCloudConnected
                        ? 'Cloud-Peers ($totalOnline online)'
                        : 'Cloud-Peers (nicht verbunden)',
                  ),
                  if (!isCloudConnected)
                    Card(
                      child: ListTile(
                        leading: const Icon(Icons.cloud_off, color: Colors.grey),
                        title: const Text('Keine Cloud-Verbindung'),
                        subtitle: const Text('Unter "Cloud-Verbindung" verbinden'),
                        trailing: TextButton(
                          onPressed: () {},
                          child: const Text('Einrichten'),
                        ),
                      ),
                    )
                  else if (cloudPeers.isEmpty)
                    _EmptyCloudPeersCard(totalOnline: totalOnline)
                  else
                    ...cloudPeers.map((p) => _CloudPeerCard(peer: p)),

                  const SizedBox(height: 24),
                ],
              ),
            ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Section Header
// ─────────────────────────────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  final IconData icon;
  final String title;
  const _SectionHeader({required this.icon, required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(icon, size: 18, color: Theme.of(context).colorScheme.primary),
          const SizedBox(width: 8),
          Text(title,
              style: Theme.of(context)
                  .textTheme
                  .titleSmall
                  ?.copyWith(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// This Device Card
// ─────────────────────────────────────────────────────────────────────────────

class _ThisDeviceCard extends StatelessWidget {
  final String deviceId;
  final bool isLeader;
  final int score;
  final NetworkScoreBreakdown breakdown;

  const _ThisDeviceCard({
    required this.deviceId,
    required this.isLeader,
    required this.score,
    required this.breakdown,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final shortId = deviceId.length > 12
        ? '${deviceId.substring(0, 4)}…${deviceId.substring(deviceId.length - 8)}'
        : deviceId;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Device ID',
                          style: Theme.of(context).textTheme.labelSmall),
                      Text(shortId,
                          style: Theme.of(context)
                              .textTheme
                              .bodyMedium
                              ?.copyWith(fontFamily: 'monospace')),
                    ],
                  ),
                ),
                _RoleBadge(isLeader: isLeader),
              ],
            ),
            const Divider(height: 24),
            // Score Breakdown
            Row(
              children: [
                Text('Election Score',
                    style: Theme.of(context).textTheme.labelMedium),
                const Spacer(),
                Text(
                  '$score Punkte',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: colors.primary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            _ScoreBreakdownBar(breakdown: breakdown),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _ScoreChip(
                  label: 'Netz',
                  value: '+100',
                  active: breakdown.hasNetwork,
                  color: Colors.green,
                ),
                _ScoreChip(
                  label: 'Laden',
                  value: '+50',
                  active: breakdown.isCharging,
                  color: Colors.orange,
                ),
                _ScoreChip(
                  label: 'Akku',
                  value: '${breakdown.batteryPercent}%',
                  active: true,
                  color: Colors.teal,
                ),
                _ScoreChip(
                  label: 'Bewegt',
                  value: '-20',
                  active: breakdown.isMoving,
                  color: Colors.red,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ScoreBreakdownBar extends StatelessWidget {
  final NetworkScoreBreakdown breakdown;
  const _ScoreBreakdownBar({required this.breakdown});

  @override
  Widget build(BuildContext context) {
    final maxScore = 100 + 50 + 100; // max possible = 250
    final fraction = (breakdown.total / maxScore).clamp(0.0, 1.0);
    final color = fraction > 0.6
        ? Colors.green
        : fraction > 0.3
            ? Colors.orange
            : Colors.red;

    return ClipRRect(
      borderRadius: BorderRadius.circular(4),
      child: LinearProgressIndicator(
        value: fraction,
        minHeight: 8,
        backgroundColor: Colors.white12,
        valueColor: AlwaysStoppedAnimation(color),
      ),
    );
  }
}

class _ScoreChip extends StatelessWidget {
  final String label;
  final String value;
  final bool active;
  final Color color;

  const _ScoreChip({
    required this.label,
    required this.value,
    required this.active,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: active ? color.withValues(alpha: 0.2) : Colors.white10,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: active ? color : Colors.transparent,
              width: 1,
            ),
          ),
          child: Text(
            value,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: active ? color : Colors.grey,
            ),
          ),
        ),
        const SizedBox(height: 2),
        Text(label,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: active ? null : Colors.grey,
                )),
      ],
    );
  }
}

class _RoleBadge extends StatelessWidget {
  final bool isLeader;
  const _RoleBadge({required this.isLeader});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: isLeader
            ? Colors.amber.withValues(alpha: 0.2)
            : Theme.of(context).colorScheme.secondaryContainer,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isLeader ? Colors.amber : Colors.transparent,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isLeader ? Icons.star : Icons.hub_outlined,
            size: 14,
            color: isLeader ? Colors.amber : null,
          ),
          const SizedBox(width: 4),
          Text(
            isLeader ? 'Leader' : 'Follower',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: isLeader ? Colors.amber : null,
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Leader Card
// ─────────────────────────────────────────────────────────────────────────────

class _LeaderCard extends StatelessWidget {
  final String? leaderId;
  final bool isThisDevice;
  final bool hasServerConnection;

  const _LeaderCard({
    required this.leaderId,
    required this.isThisDevice,
    required this.hasServerConnection,
  });

  @override
  Widget build(BuildContext context) {
    if (leaderId == null) {
      return const Card(
        child: ListTile(
          leading: Icon(Icons.how_to_vote, color: Colors.orange),
          title: Text('Wahl läuft…'),
          subtitle: Text('Kein Leader gewählt'),
        ),
      );
    }

    final shortId = leaderId!.length > 12
        ? '${leaderId!.substring(0, 4)}…${leaderId!.substring(leaderId!.length - 8)}'
        : leaderId!;

    return Card(
      color: Colors.amber.withValues(alpha: 0.05),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: Colors.amber, width: 1),
      ),
      child: ListTile(
        leading: const Icon(Icons.star, color: Colors.amber),
        title: Text(
          isThisDevice ? 'Dieses Gerät (★ Leader)' : shortId,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(
          hasServerConnection
              ? '● Server-Verbindung aktiv'
              : '○ Kein Server – nur BLE',
          style: TextStyle(
            color: hasServerConnection ? Colors.green : Colors.orange,
          ),
        ),
        trailing: hasServerConnection
            ? const Icon(Icons.cloud_done, color: Colors.green)
            : const Icon(Icons.cloud_off, color: Colors.orange),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Queue / Sync Card
// ─────────────────────────────────────────────────────────────────────────────

class _QueueCard extends StatelessWidget {
  final int pending;
  final NetworkSyncStatus syncStatus;
  final bool hasServer;

  const _QueueCard({
    required this.pending,
    required this.syncStatus,
    required this.hasServer,
  });

  @override
  Widget build(BuildContext context) {
    final (label, color, icon) = switch (syncStatus) {
      NetworkSyncStatus.syncing =>
        ('Synchronisiere mit Server…', Colors.green, Icons.cloud_sync),
      NetworkSyncStatus.upToDate =>
        ('Vollständig synchronisiert', Colors.green, Icons.cloud_done),
      NetworkSyncStatus.meshOnly =>
        ('BLE-Mesh Only – Leader sendet', Colors.blue, Icons.hub),
      NetworkSyncStatus.offline => ('Fully Offline', Colors.red, Icons.cloud_off),
    };

    return Card(
      child: Column(
        children: [
          ListTile(
            leading: Icon(icon, color: color),
            title: Text(label),
            trailing: pending > 0
                ? Badge(
                    label: Text('$pending'),
                    child: const Icon(Icons.outbox),
                  )
                : const Icon(Icons.check, color: Colors.green),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Peer Card
// ─────────────────────────────────────────────────────────────────────────────

class _PeerCard extends StatelessWidget {
  final PeerStatusInfo peer;
  const _PeerCard({required this.peer});

  @override
  Widget build(BuildContext context) {
    final timeSince = DateTime.now()
        .difference(DateTime.fromMillisecondsSinceEpoch(peer.lastSeenMs));
    final lastSeenLabel = timeSince.inSeconds < 5
        ? 'Gerade aktiv'
        : 'Vor ${timeSince.inSeconds}s gesehen';

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Stack(
          alignment: Alignment.bottomRight,
          children: [
            CircleAvatar(
              backgroundColor: peer.isLeader
                  ? Colors.amber.withValues(alpha: 0.2)
                  : Colors.blueGrey.withValues(alpha: 0.3),
              child: Icon(
                peer.isLeader ? Icons.star : Icons.smartphone,
                color: peer.isLeader ? Colors.amber : null,
                size: 20,
              ),
            ),
            _SignalIcon(bars: peer.signalBars),
          ],
        ),
        title: Row(
          children: [
            Text(peer.shortId,
                style: const TextStyle(fontFamily: 'monospace', fontSize: 13)),
            if (peer.isLeader) ...[
              const SizedBox(width: 6),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.amber.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(4),
                  ),
                child: const Text('Leader',
                    style:
                        TextStyle(fontSize: 10, color: Colors.amber)),
              ),
            ],
          ],
        ),
        subtitle: Text(
          '$lastSeenLabel  •  RSSI ${peer.rssi} dBm  •  Score ${peer.electionScore}',
          style: Theme.of(context).textTheme.bodySmall,
        ),
        trailing: _RssiBar(rssi: peer.rssi),
      ),
    );
  }
}

class _SignalIcon extends StatelessWidget {
  final int bars; // 0-4
  const _SignalIcon({required this.bars});

  @override
  Widget build(BuildContext context) {
    final color = bars >= 3
        ? Colors.green
        : bars == 2
            ? Colors.orange
            : Colors.red;
    return Container(
      padding: const EdgeInsets.all(2),
      decoration: const BoxDecoration(
          color: Colors.black54, shape: BoxShape.circle),
      child: Icon(
        _iconForBars(bars),
        size: 10,
        color: color,
      ),
    );
  }

  IconData _iconForBars(int bars) {
    if (bars >= 4) return Icons.signal_wifi_4_bar;
    if (bars == 3) return Icons.network_wifi_3_bar;
    if (bars == 2) return Icons.network_wifi_2_bar;
    if (bars == 1) return Icons.network_wifi_1_bar;
    return Icons.signal_wifi_0_bar;
  }
}

class _RssiBar extends StatelessWidget {
  final int rssi;
  const _RssiBar({required this.rssi});

  @override
  Widget build(BuildContext context) {
    // Normalize RSSI: -30 dBm = 100 %, -100 dBm = 0 %
    final percent = ((rssi + 100) / 70).clamp(0.0, 1.0);
    final color = percent > 0.6
        ? Colors.green
        : percent > 0.3
            ? Colors.orange
            : Colors.red;

    return SizedBox(
      width: 40,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('$rssi dBm',
              style: const TextStyle(fontSize: 9, color: Colors.grey)),
          const SizedBox(height: 2),
          ClipRRect(
            borderRadius: BorderRadius.circular(2),
            child: LinearProgressIndicator(
              value: percent,
              minHeight: 4,
              backgroundColor: Colors.white12,
              valueColor: AlwaysStoppedAnimation(color),
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyPeersCard extends StatelessWidget {
  const _EmptyPeersCard();

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            const Icon(Icons.bluetooth_searching, size: 40, color: Colors.grey),
            const SizedBox(height: 12),
            Text('Keine Peers in Reichweite',
                style: Theme.of(context)
                    .textTheme
                    .bodyMedium
                    ?.copyWith(color: Colors.grey)),
            const SizedBox(height: 4),
            const Text(
              'Das Gerät scannt kontinuierlich nach anderen StageSync-Geräten.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Cloud Peer Cards
// ─────────────────────────────────────────────────────────────────────────────

class _EmptyCloudPeersCard extends StatelessWidget {
  final int totalOnline;
  const _EmptyCloudPeersCard({required this.totalOnline});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            const Icon(Icons.cloud_queue, size: 40, color: Colors.grey),
            const SizedBox(height: 12),
            Text(
              totalOnline <= 1
                  ? 'Nur dieses Gerät ist verbunden'
                  : '$totalOnline Sockets online – noch keine App-Peers',
              style: Theme.of(context)
                  .textTheme
                  .bodyMedium
                  ?.copyWith(color: Colors.grey),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 4),
            const Text(
              'Andere Geräte müssen ebenfalls verbunden sein.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }
}

class _CloudPeerCard extends StatelessWidget {
  final CloudPeerInfo peer;
  const _CloudPeerCard({required this.peer});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor:
              Theme.of(context).colorScheme.primaryContainer,
          child: Text(
            peer.userName.isNotEmpty ? peer.userName[0].toUpperCase() : '?',
            style: TextStyle(
              color: Theme.of(context).colorScheme.onPrimaryContainer,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        title: Text(peer.userName),
        subtitle: Text(
          peer.shortId,
          style: const TextStyle(fontFamily: 'monospace', fontSize: 11),
        ),
        trailing: const Icon(Icons.cloud_done, color: Colors.green, size: 18),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Platform Capabilities Card
// ─────────────────────────────────────────────────────────────────────────────

class _PlatformCapabilitiesCard extends StatelessWidget {
  final PlatformCapabilities capabilities;
  const _PlatformCapabilitiesCard({required this.capabilities});

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
                const Icon(Icons.info_outline, size: 16),
                const SizedBox(width: 8),
                Text(
                  capabilities.platformName,
                  style: Theme.of(context)
                      .textTheme
                      .titleSmall
                      ?.copyWith(fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _CapabilityRow(
                label: 'BLE Mesh', support: capabilities.bleMesh),
            _CapabilityRow(
                label: 'WebSocket', support: capabilities.webSocket),
            _CapabilityRow(
                label: 'Hintergrund-Isolate',
                support: capabilities.backgroundIsolate),
            _CapabilityRow(
                label: 'Lokale Persistenz',
                support: capabilities.localStorage),
            if (capabilities.hint != null) ...[
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.amber.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.amber.withValues(alpha: 0.3)),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.warning_amber, size: 14, color: Colors.amber),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        capabilities.hint!,
                        style: const TextStyle(fontSize: 11, color: Colors.amber),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _CapabilityRow extends StatelessWidget {
  final String label;
  final FeatureSupport support;

  const _CapabilityRow({required this.label, required this.support});

  @override
  Widget build(BuildContext context) {
    final (icon, color, text) = switch (support) {
      FeatureSupport.full => (Icons.check_circle, Colors.green, 'Vollständig'),
      FeatureSupport.partial => (Icons.warning, Colors.amber, 'Eingeschränkt'),
      FeatureSupport.unavailable => (Icons.cancel, Colors.red, 'Nicht verfügbar'),
    };

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 8),
          Text(label),
          const Spacer(),
          Text(text, style: TextStyle(color: color, fontSize: 12)),
        ],
      ),
    );
  }
}





