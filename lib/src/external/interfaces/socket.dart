import 'package:web_communication/library.dart';
import 'package:web_communication/src/internal/constants.dart';

abstract class Socket {
  bool get connected;

  bool get closed;
  
  Future<T?> send<T extends Packet>(
    Packet packet, {
      Packet? responseTo,
      bool waitForResponse = false,
      Duration timeout = Constants.WAIT_FOR_RESPONSE_TIMEOUT,
  });

  Future<void> sendPing({
    Duration timeout = Constants.PING_TIMEOUT,
  });

  Future<T?> sendWithResponse<T extends Packet>(
    Packet packet, {
      Packet? responseTo,
      Duration timeout = Constants.WAIT_FOR_RESPONSE_TIMEOUT,
  });

  Future<void> close();
}