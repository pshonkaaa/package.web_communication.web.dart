import 'package:true_core/library.dart';
import 'package:web_communication/library.dart';
import 'package:web_communication/src/internal/_internal.dart';
import 'package:web_communication/src/internal/constants.dart';

import 'base_communicator.dart';

abstract class BaseClientCommunicator extends BaseCommunicator implements ClientCommunicator {
  static const TAG = 'BaseClientCommunicator';
  
  BaseClientCommunicator({
    required super.address,
    required super.handshake,
    required super.packets,
    required super.pingInterval,
  });

  Future<BaseSocket> connectDelegate();

  @override
  bool get connected => controller.sockets.tryFirst?.connected ?? false;

  BaseSocket? get socket => controller.sockets.tryFirst;

  @override
  Future<void> connect() async {
    if(!closed)
      return;
      
    logger?.d('$TAG > connect();');

    try {        
      controller.onOpen();
      
      final socket = await connectDelegate();
    
      controller.onConnect(socket);

    } on SocketClosedException {
      controller.onClose();

      rethrow;

    } catch(_) {
      controller.onClose();

      rethrow;
    }
  }

  @override
  Future<T?> send<T extends Packet>(
    Packet packet, {
      Packet? responseTo,
      bool waitForResponse = false,
      Duration timeout = Constants.WAIT_FOR_RESPONSE_TIMEOUT,
  }) async {
    _throwIfNotConnected();
    
    return await controller.send(
      socket!,
      packet,
      responseTo: responseTo,
      waitForResponse: waitForResponse,
      timeout: timeout,
    );
  }

  @override
  Future<void> sendPing({
    Duration timeout = Constants.PING_TIMEOUT,
  }) async {
    _throwIfNotConnected();
    
    return await controller.sendPing(
      socket!,
      timeout: timeout,
    );
  }

  @override
  Future<T?> sendWithResponse<T extends Packet>(
    Packet packet, {
      Packet? responseTo,
      Duration timeout = Constants.WAIT_FOR_RESPONSE_TIMEOUT,
  }) async {
    _throwIfNotConnected();
    
    return await controller.sendWithResponse(
      socket!,
      packet,
      responseTo: responseTo,
      timeout: timeout,
    );
  }
  
  @override
  Future<void> close() async {
    if(closed)
      return;
      
    logger?.d('$TAG > close();');

    await closeDelegate();

    controller.onDisconnect(socket!);
       
    await super.close();
  }


  void _throwIfNotConnected() {
    if(!connected)
      throw Exception('Socket not connected');
  }
}