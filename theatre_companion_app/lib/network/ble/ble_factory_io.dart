import '../crypto/aes_gcm_service.dart';
import '../platform/abstract_ble_service.dart';
import '../routing/peer_registry.dart';
import 'ble_mesh_service.dart';

AbstractBleService createBleService(PeerRegistry peers, AesGcmService crypto) {
  return BleMeshService(peers: peers, crypto: crypto);
}
