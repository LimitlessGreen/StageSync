import '../crypto/aes_gcm_service.dart';
import '../platform/abstract_ble_service.dart';
import '../platform/stub_ble_service.dart';
import '../routing/peer_registry.dart';

AbstractBleService createBleService(PeerRegistry peers, AesGcmService crypto) {
  return StubBleService();
}
