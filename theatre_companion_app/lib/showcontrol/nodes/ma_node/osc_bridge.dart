import 'dart:async';
import 'dart:io';

import 'package:osc/osc.dart';

/// Sendet OSC-Nachrichten an eine GrandMA2/3 Konsole im LAN.
class OscBridge {
  final String host;
  final int port;

  RawDatagramSocket? _socket;

  OscBridge({required this.host, this.port = 8000});

  Future<void> connect() async {
    _socket = await RawDatagramSocket.bind(InternetAddress.anyIPv4, 0);
  }

  Future<void> disconnect() async {
    _socket?.close();
    _socket = null;
  }

  Future<void> send(OSCMessage message) async {
    if (_socket == null) await connect();
    final bytes = message.toBytes();
    _socket!.send(bytes, InternetAddress(host), port);
  }

  /// Executor an Seite [page] / Nummer [exec] mit Befehl [command] ansteuern.
  /// command: 'Go', 'Off', 'Top', 'Pause'
  Future<void> sendExecutorCommand({
    required int page,
    required int exec,
    required String command,
  }) async {
    final arg = '$command Executor $page.$exec';
    await send(OSCMessage('/gma2/cmd', arguments: [arg]));
  }

  /// Freie OSC-Nachricht an beliebige Adresse mit optionalem String-Argument.
  Future<void> sendRaw({
    required String address,
    String argument = '',
  }) async {
    await send(OSCMessage(address, arguments: [
      if (argument.isNotEmpty) argument,
    ]));
  }
}
