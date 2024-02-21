import 'dart:async';
import 'dart:js';

import 'package:web_chrome_api/library.dart';
import 'package:web_communication/library.dart';
import 'package:web_communication/src/internal/_internal.dart';
import 'package:web_communication/src/internal/bases/client.dart';
import 'package:web_communication/src/internal/bases/server.dart';

class _Socket extends BaseSocket {
  _Socket({
    required super.communicator,
    required this.port,
  });

  final Port port;

  late final OnPortMessageListener jsOnMessage;

  late final OnPortListener jsOnDisconnect;
}


class SocketClientCommunicator extends BaseClientCommunicator {
  static const TAG = 'SocketClientCommunicator';

  SocketClientCommunicator({
    required super.handshake,
    required this.extensionId,
    required super.packets,
    required super.pingInterval,
  }) : super(
    address: Uri(
      scheme: 'chrome-background',
      host: extensionId,
    ),
  );
  
  final String extensionId;

  @override
  Future<BaseSocket> connectDelegate() async {
    if(chrome.runtime == null)
      throw Exception('chrome.runtime not supported');

    final port = chrome.runtime!.connect(extensionId, ConnectInfo(name: handshake));
    
    final socket = _Socket(
      communicator: this,
      port: port,
    );

    socket.jsOnMessage = allowInterop((message, port) {
      try {
        controller.onReceive(socket, message);
      } on UnknownDataException {
      } on UnknownHandshakeException {
      }
    });

    socket.jsOnDisconnect = allowInterop((_) {
      socket.close();
    });
    
    port.onMessage.addListener(socket.jsOnMessage);
    port.onDisconnect.addListener(socket.jsOnDisconnect);

    try {
      await controller.sendPing(
        socket,
        timeout: Duration(milliseconds: 200),
        testWater: true,
      );
    } on TimeoutException {
      throw SocketClosedException();
    }

    return socket;
  }

  @override
  Future<void> sendRequestDelegate(
    covariant _Socket socket,
    dynamic data, {
      required bool waitForResponse,
      required bool testWater,
  }) async {
    socket.port.postMessage(data);
  }
  
  @override
  Future<void> closeSocketDelegate(
    covariant _Socket socket,
  ) async {
    socket.port.onMessage.removeListener(socket.jsOnMessage);
    socket.port.onDisconnect.removeListener(socket.jsOnDisconnect);
    socket.port.disconnect();
  }
  
  @override
  Future<void> closeDelegate() async {
    
  }
}

class SocketServerCommunicator extends BaseServerCommunicator {
  static const TAG = 'SocketServerCommunicator';

  SocketServerCommunicator({
    required super.handshake,
    required super.packets,
    required super.pingInterval,
  }) : super(
    address: Uri(
      scheme: 'chrome-background',
      host: 'localhost',
    ),
  );

  @override
  Iterable<Socket> get sockets => controller.sockets;
  
  late OnPortListener _jsOnConnect;
  
  late OnPortListener _jsOnConnectExternal;

  @override
  Future<void> openDelegate() async {
    _jsOnConnect = _jsOnConnectExternal = allowInterop((port) async {
      if(port.name != handshake)
        return;
        
      final socket = _Socket(
        communicator: this,
        port: port,
      );

      socket.jsOnMessage = allowInterop((message, port) {
        try {
          controller.onReceive(socket, message);
        } on UnknownDataException {
        } on UnknownHandshakeException {
        }
      });

      socket.jsOnDisconnect = allowInterop((_) {
        socket.close();
      });
      
      port.onMessage.addListener(socket.jsOnMessage);
      port.onDisconnect.addListener(socket.jsOnDisconnect);
      
      controller.onConnect(socket);
    });

    chrome.runtime!.onConnect.addListener(_jsOnConnect);
    chrome.runtime!.onConnectExternal.addListener(_jsOnConnectExternal);
  }

  @override
  Future<void> sendRequestDelegate(
    covariant _Socket socket,
    dynamic data, {
      required bool waitForResponse,
      required bool testWater,
  }) async {
    socket.port.postMessage(data);
  }
  
  @override
  Future<void> closeSocketDelegate(
    covariant _Socket socket,
  ) async {
    socket.port.onMessage.removeListener(socket.jsOnMessage);
    socket.port.onDisconnect.removeListener(socket.jsOnDisconnect);
    socket.port.disconnect();
  }

  @override
  Future<void> closeDelegate() async {
    chrome.runtime!.onConnect.removeListener(_jsOnConnect);
    chrome.runtime!.onConnectExternal.removeListener(_jsOnConnectExternal);
  }
}

































