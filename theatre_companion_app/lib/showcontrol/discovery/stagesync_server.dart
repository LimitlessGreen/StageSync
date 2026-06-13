class StageSyncServer {
  final String host;
  final int port;
  final String name;

  const StageSyncServer(
      {required this.host, required this.port, required this.name});

  @override
  String toString() => '$name ($host:$port)';
}
