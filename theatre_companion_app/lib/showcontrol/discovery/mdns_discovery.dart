import 'dart:async';
import 'dart:io';

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
  static const _mdnsGroup = '224.0.0.251';

  /// Einmalige Suche mit Timeout. Gibt alle gefundenen Server zurück.
  /// Gibt leere Liste zurück wenn mDNS nicht unterstützt wird (z.B. Windows-VMs).
  static Future<List<StageSyncServer>> discover({
    Duration timeout = const Duration(seconds: 4),
  }) async {
    final client = MDnsClient();

    // Eigene IPs vorab ermitteln, um später den passenden Server-IP zu wählen
    final localIps = await _localIpv4Addresses();

    final results = <StageSyncServer>[];
    final seen = <String>{};

    try {
      await client.start(interfacesFactory: _multicastCapableInterfaces);

      await for (final PtrResourceRecord ptr in client
          .lookup<PtrResourceRecord>(ResourceRecordQuery.serverPointer(_serviceType))
          .timeout(timeout, onTimeout: (_) {})) {
        if (seen.contains(ptr.domainName)) continue;
        seen.add(ptr.domainName);

        // SRV-Record → Port + Target-Hostname
        int port = 50051;
        String? srvTarget;
        await for (final SrvResourceRecord srv in client
            .lookup<SrvResourceRecord>(ResourceRecordQuery.service(ptr.domainName))
            .timeout(const Duration(seconds: 2), onTimeout: (_) {})) {
          port = srv.port;
          srvTarget = srv.target;
          break;
        }

        // A-Records → alle IPs sammeln, dann beste (gleicher Subnet) wählen
        final serverIps = <String>[];
        final target = srvTarget ?? ptr.domainName;
        await for (final IPAddressResourceRecord ip in client
            .lookup<IPAddressResourceRecord>(ResourceRecordQuery.addressIPv4(target))
            .timeout(const Duration(seconds: 2), onTimeout: (_) {})) {
          serverIps.add(ip.address.address);
        }

        final host = serverIps.isEmpty ? null : _bestIp(serverIps, localIps);

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
      // Timeout, kein mDNS-Support oder Interface-Fehler — leere Liste
    } finally {
      client.stop();
    }

    return results;
  }

  /// Eigene IPv4-Adressen aller aktiven Interfaces (ohne Loopback).
  static Future<List<String>> _localIpv4Addresses() async {
    final ifaces = await NetworkInterface.list(
      type: InternetAddressType.IPv4,
      includeLoopback: false,
      includeLinkLocal: false,
    );
    return [
      for (final iface in ifaces)
        for (final addr in iface.addresses) addr.address,
    ];
  }

  /// Wählt aus [serverIps] diejenige, die im selben /24-Subnetz wie eine
  /// der [localIps] liegt. Fallback: erste IP in der Liste.
  static String _bestIp(List<String> serverIps, List<String> localIps) {
    for (final local in localIps) {
      final localOctets = local.split('.');
      if (localOctets.length != 4) continue;
      final localPrefix = '${localOctets[0]}.${localOctets[1]}.${localOctets[2]}.';

      for (final server in serverIps) {
        if (server.startsWith(localPrefix)) return server;
      }
    }
    // Kein /24-Match → /16 versuchen
    for (final local in localIps) {
      final localOctets = local.split('.');
      if (localOctets.length != 4) continue;
      final localPrefix = '${localOctets[0]}.${localOctets[1]}.';

      for (final server in serverIps) {
        if (server.startsWith(localPrefix)) return server;
      }
    }
    return serverIps.first;
  }

  /// Gibt nur Interfaces zurück, die tatsächlich Multicast unterstützen.
  /// Auf Windows schlägt joinMulticast auf VPN/Loopback-Interfaces fehl (errno 10042).
  static Future<List<NetworkInterface>> _multicastCapableInterfaces(
      InternetAddressType type) async {
    final all = await NetworkInterface.list(
      type: type,
      includeLinkLocal: false,
      includeLoopback: false,
    );

    final capable = <NetworkInterface>[];
    for (final iface in all) {
      try {
        final sock = await RawDatagramSocket.bind(InternetAddress.anyIPv4, 0);
        try {
          sock.joinMulticast(InternetAddress(_mdnsGroup), iface);
          sock.leaveMulticast(InternetAddress(_mdnsGroup), iface);
          capable.add(iface);
        } finally {
          sock.close();
        }
      } catch (_) {
        // Interface unterstützt Multicast nicht — überspringen
      }
    }
    return capable;
  }
}
