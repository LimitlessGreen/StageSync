// Stub for web and unsupported platforms — no FFI available.
class EmbeddedServer {
  EmbeddedServer._();
  static final EmbeddedServer instance = EmbeddedServer._();

  bool get isRunning => false;
  int get port => 0;

  static bool get isSupported => false;

  Future<bool> start({required int port, required String dataDir}) async => false;
  void stop() {}
}
