import 'package:web_communication/library.dart';
import 'package:web_communication/src/internal/_internal.dart';
import 'package:web_communication/src/internal/constants.dart';

import 'base_communicator.dart';

abstract class BaseServerCommunicator extends BaseCommunicator implements ServerCommunicator {
  static const TAG = 'BaseServerCommunicator';
  
  BaseServerCommunicator({
    required super.address,
    required super.handshake,
    required super.packets,
    required super.pingInterval,
  });
  
  Future<void> openDelegate();
  
  @override
  Future<void> open() async {
    if(!closed)
      return;

    logger?.d('$TAG > open();');

    try {
      await openDelegate();
      controller.onOpen();
    } catch(_) {
      controller.onClose();
      rethrow;
    }
  }

  @override
  Future<T?> send<T extends Packet>(
    covariant BaseSocket socket,
    Packet packet, {
      Packet? responseTo,
      bool waitForResponse = false,
      Duration timeout = Constants.WAIT_FOR_RESPONSE_TIMEOUT,
  }) async {
    return await controller.send(
      socket,
      packet,
      responseTo: responseTo,
      waitForResponse: waitForResponse,
      timeout: timeout,
    );
  }

  @override
  Future<void> sendPing(
    covariant BaseSocket socket, {
      Duration timeout = Constants.PING_TIMEOUT,
  }) async {
    return await controller.sendPing(
      socket,
      timeout: timeout,
    );
  }

  @override
  Future<T?> sendWithResponse<T extends Packet>(
    covariant BaseSocket socket,
    Packet packet, {
      Packet? responseTo,
      Duration timeout = Constants.WAIT_FOR_RESPONSE_TIMEOUT,
  }) async {
    return await controller.sendWithResponse(
      socket,
      packet,
      responseTo: responseTo,
      timeout: timeout,
    );
  }
  
  @override
  Future<void> closeSocket(covariant BaseSocket socket) async {
    if(socket.closed)
      return;

    logger?.d('$TAG > closeSocket();');

    await closeSocketDelegate(socket);

    controller.onDisconnect(socket);
  }
}