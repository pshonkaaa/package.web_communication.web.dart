import 'dart:async';
import 'dart:js';

import 'package:web_chrome_api/library.dart';
import 'package:web_communication/library.dart';
import 'package:web_communication/src/internal/_internal.dart';
import 'package:web_communication/src/internal/bases/client.dart';
import 'package:web_communication/src/internal/bases/server.dart';

class _HttpToServerSocket extends BaseSocket {
  _HttpToServerSocket({
    required super.communicator,
  });
}

class HttpClientCommunicator extends BaseClientCommunicator implements ClientCommunicator {
  static const TAG = 'HttpClientCommunicator';

  final String extensionId;
  HttpClientCommunicator({
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
  

  @override
  Future<BaseSocket> connectDelegate() async {
    if(chrome.runtime == null)
      throw Exception('chrome.runtime not supported');

    final socket = _HttpToServerSocket(
      communicator: this,
    );

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
    covariant _HttpToServerSocket socket,
    dynamic data, {
      required bool waitForResponse,
      required bool testWater,
  }) async {
    if(waitForResponse) {
      chrome.runtime!.sendMessageAsync(
        extensionId,
        data,
      ).then((response) {
        controller.onReceive(socket, response);

        // if(!testWater) {
        //   close();
        // }
      });
    } else {
      chrome.runtime!.sendMessage(
        extensionId,
        data,
        null,
        null,
      );
      
      // close();
    }
  }
  
  @override
  Future<void> closeSocketDelegate(covariant _HttpToServerSocket socket) async {
    
  }
  
  @override
  Future<void> closeDelegate() async {
    
  }

  @override
  Communicator onReceive(OnMessageCallback callback) {
    throw Exception('Method not supported. Client cant receive messages');
  }
}

































class _HttpToClientSocket extends BaseSocket {
  final SendResponseFunction jsSendResponse;
  _HttpToClientSocket({
    required super.communicator,
    required this.jsSendResponse,
  });

  bool _responseSent = false;
}

class HttpServerCommunicator extends BaseServerCommunicator implements ServerCommunicator {
  static const TAG = 'HttpServerCommunicator';
  
  HttpServerCommunicator({
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

  late OnMessageListener _jsOnMessage;
  late OnMessageListener _jsOnMessageExternal;

  @override
  Future<void> openDelegate() async {
    _jsOnMessage = _jsOnMessageExternal = allowInterop((data, sender, sendResponse) async {
      final socket = _HttpToClientSocket(  
        communicator: this,
        jsSendResponse: sendResponse,
      );
      
      try {
        controller.onConnect(socket);
        controller.onReceive(socket, data);
      } on UnknownDataException {
      } on UnknownHandshakeException {
      }
    });
    
    chrome.runtime!.onMessage.addListener(_jsOnMessage);
    chrome.runtime!.onMessageExternal.addListener(_jsOnMessageExternal);
  }

  @override
  Future<void> sendRequestDelegate(
    covariant _HttpToClientSocket socket,
    dynamic data, {
      required bool waitForResponse,
      required bool testWater,
  }) async {
    if(waitForResponse)
      throw Exception('Method not supported. waitForResponse on server-side not supported.');

    if(socket._responseSent)
      throw Exception('Method not supported. Client cant receive more than one message');
    
    socket._responseSent = true;

    socket.jsSendResponse(data);

    socket.close();
  }
  
  @override
  Future<void> closeSocketDelegate(
    covariant _HttpToClientSocket socket,
  ) async {
    if(socket._responseSent)
      return;

    final data = controller.preparePacket(
      socket,
      NullPacket(),
      waitForResponse: false,
      responseTo: null,
    );

    socket.jsSendResponse(data);
  }

  @override
  Future<void> closeDelegate() async {
    chrome.runtime!.onMessage.removeListener(_jsOnMessage);
    chrome.runtime!.onMessageExternal.removeListener(_jsOnMessageExternal);
  }
}