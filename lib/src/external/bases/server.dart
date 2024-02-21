import 'package:web_communication/library.dart';
import 'package:web_communication/src/internal/constants.dart';

abstract class ServerCommunicator implements Communicator {

  Iterable<Socket> get sockets;
  
  Future<void> open();

  Future<T?> send<T extends Packet>(
    Socket socket,
    Packet packet, {
      Packet? responseTo,
      bool waitForResponse = false,
      Duration timeout = Constants.WAIT_FOR_RESPONSE_TIMEOUT,
  });

  Future<void> sendPing(
    Socket socket,{
      Duration timeout = Constants.PING_TIMEOUT,
  });

  Future<T?> sendWithResponse<T extends Packet>(
    Socket socket,
    Packet packet, {
      Packet? responseTo,
      Duration timeout = Constants.WAIT_FOR_RESPONSE_TIMEOUT,
  });

  Future<void> closeSocket(
    Socket socket,
  );
}