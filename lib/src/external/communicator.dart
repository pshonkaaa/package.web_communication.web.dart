import 'dart:async';

import 'package:logger/logger.dart';
import 'package:web_communication/library.dart';
import 'package:web_communication/src/internal/constants.dart';

abstract class Communicator {

  static ClientCommunicator client({
    required String handshake,
    required String extensionId,
    required List<Packet> packets,
    EConnectionType connectionType = EConnectionType.http,
    Duration pingInterval = Constants.PING_INTERVAL,
  }) {
    switch(connectionType) {
      case EConnectionType.http:
    /// TODO pingInterval
        return HttpClientCommunicator(
          handshake: handshake,
          extensionId: extensionId,
          packets: packets,
          pingInterval: pingInterval,
        );

      case EConnectionType.socket:
        return SocketClientCommunicator(
          handshake: handshake,
          extensionId: extensionId,
          packets: packets,
          pingInterval: pingInterval,
        );
    }
  }

  static ServerCommunicator server({
    required String handshake,
    required List<Packet> packets,
    EConnectionType connectionType = EConnectionType.http,
    Duration pingInterval = Constants.PING_INTERVAL,
  }) {
    switch(connectionType) {
      case EConnectionType.http:
    /// TODO pingInterval
        return HttpServerCommunicator(
          handshake: handshake,
          packets: packets,
          pingInterval: Duration.zero,
        );

      case EConnectionType.socket:
        return SocketServerCommunicator(
          handshake: handshake,
          packets: packets,
          pingInterval: pingInterval,
        );
    }
  }

  Logger? logger;

  Uri get address;

  String get handshake;

  bool get closed;

  Communicator onConnect(OnSocketCallback callback);

  Communicator onReceive(OnMessageCallback callback);

  Communicator onDisconnect(OnSocketCallback callback);
  
  Future<void> close();
}