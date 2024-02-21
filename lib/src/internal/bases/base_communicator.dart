import 'package:logger/logger.dart';
import 'package:meta/meta.dart';
import 'package:web_communication/library.dart';
import 'package:web_communication/src/internal/_internal.dart';
import 'package:web_communication/src/internal/constants.dart';

abstract class BaseCommunicator implements Communicator {
  static const TAG = 'BaseCommunicator';

  BaseCommunicator({
    required this.address,
    required this.handshake,
    required List<Packet> packets,
    required this.pingInterval,
  }) {
    controller = CommunicatorController(
      this,
      packets: [...Constants.DEFAULT_PACKETS, ...packets],
    );
  }

  late final CommunicatorController controller;

  Future<void> sendRequestDelegate(
    BaseSocket socket,
    dynamic data, {
      required bool waitForResponse,
      required bool testWater,
  });
  
  Future<void> closeSocketDelegate(
    BaseSocket socket,
  );
  
  Future<void> closeDelegate();

  @override
  Logger? logger;

  @override
  final Uri address;

  @override
  final String handshake;

  // @override
  /// TODO pingInterval setter
  final Duration pingInterval;

  @override
  bool get closed => controller.closed;

  @override
  Communicator onConnect(OnSocketCallback callback) {
    logger?.d('$TAG > new callback onConnect');
    controller.onConnectCallback = callback;
    return this;
  }

  @override
  Communicator onReceive(OnMessageCallback callback) {
    logger?.d('$TAG > new callback onReceive');
    controller.onMessageCallback = callback;
    return this;
  }

  @override
  Communicator onDisconnect(OnSocketCallback callback) {
    logger?.d('$TAG > new callback onDisconnect');
    controller.onDisconnectCallback = callback;
    return this;
  }

  @override
  @mustCallSuper
  Future<void> close() async {
    if(closed)
      return;
      
    logger?.d('$TAG > close();');
      
    await controller.onClose();
  }
}