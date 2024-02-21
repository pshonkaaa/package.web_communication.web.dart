import 'dart:developer';

import 'package:web_communication/library.dart';

Future<void> testClient() async {
  final communicator = Communicator.client(
    handshake: 'handshake',
    extensionId: 'mpahlfekjgleahcckfpcdnaiehfpjegc',
    packets: [
      SingleValuePacket.builder(),
    ],
    connectionType: EConnectionType.socket,
  );

  await communicator.connect();

  communicator.onReceive((packet, sendResponse) {
    // sendResponse(CommonPacket('test'));
    
    debugger();
    print(packet);
  });

  final response = await communicator.sendWithResponse(SingleValuePacket("from inject"));
  print(response);
}

Future<void> testServer() async {
  final communicator = Communicator.server(
    handshake: 'handshake',
    packets: [
      SingleValuePacket.builder(),
    ],
    connectionType: EConnectionType.socket,
  );

  await communicator.open();

  communicator.onReceive((socket, packet) async {
    
    debugger();
    await socket.send(SingleValuePacket('test'), responseTo: packet);
    print(packet);
    await communicator.close();
  });

  await Future.delayed(Duration(seconds: 30));
  await communicator.close();
}