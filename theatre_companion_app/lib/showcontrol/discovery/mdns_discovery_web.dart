import 'stagesync_server.dart';

/// Web-Stub: Browser können kein mDNS — Server-Adresse muss manuell
/// eingegeben werden. Siehe mdns_discovery_io.dart für die native Variante.
class MdnsDiscoveryImpl {
  static Future<List<StageSyncServer>> discover({
    Duration timeout = const Duration(seconds: 4),
  }) async {
    return const [];
  }
}
