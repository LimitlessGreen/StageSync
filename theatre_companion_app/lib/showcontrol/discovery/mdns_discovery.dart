import 'dart:async';

import 'package:multicast_dns/multicast_dns.dart';

class StageSyncServer {
  final String host;
  final int port;
  final String name;

  const StageSyncServer({required this.host, required this.port, required this.name});

  @override
  String toString() => '$name ($host:$port)';
}

/// Sucht StageSync-Server im LAN via mDNS (_stagesync._tcp).
class MdnsDiscovery {
  static const _serviceType = '_stagesync._tcp.local';

  /// Einmalige Suche mit Timeout. Gibt alle gefundenen Server zurück.
  static Future<List<StageSyncServer>> discover({
    Duration timeout = const Duration(seconds: 4),
  }) async {
    final client = MDnsClient();
    await client.start();

    final results = <StageSyncServer>[];
    final seen = <String>{};

    try {
      await for (final PtrResourceRecord ptr in client
          .lookup<PtrResourceRecord>(ResourceRecordQuery.serverPointer(_serviceType))
          .timeout(timeout, onTimeout: (_) {})) {
        if (seen.contains(ptr.domainName)) continue;
        seen.add(ptr.domainName);

        // SRV-Record → Port
        int port = 50051;
        await for (final SrvResourceRecord srv in client
            .lookup<SrvResourceRecord>(ResourceRecordQuery.service(ptr.domainName))
            .timeout(const Duration(seconds: 2), onTimeout: (_) {})) {
          port = srv.port;
          break;
        }

        // A-Record → IP
        String? host;
        final target = ptr.domainName;
        await for (final IPAddressResourceRecord ip in client
            .lookup<IPAddressResourceRecord>(ResourceRecordQuery.addressIPv4(target))
            .timeout(const Duration(seconds: 2), onTimeout: (_) {})) {
          host = ip.address.address;
          break;
        }

        if (host != null) {
          results.add(StageSyncServer(
            host: host,
            port: port,
            name: ptr.domainName
                .replaceAll('.$_serviceType', '')
                .replaceAll('.local', ''),
          ));
        }
      }
    } catch (_) {
      // Timeout oder kein mDNS-Support — leere Liste zurückgeben
    } finally {
      client.stop();
    }

    return results;
  }
}
