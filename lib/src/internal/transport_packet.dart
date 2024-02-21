import 'dart:async';
import 'dart:collection';
import 'dart:js_interop';
import 'dart:js_util';

import 'package:web_communication/library.dart';
import 'package:web_communication/src/internal/packet_mixin.dart';

class TransportPacket {
  final Socket? socket;


  final String handshake;
  final int id;
  final bool waitForResponse;
  final int? responseTo;
  final String packetTypeId;
  final Packet packet;
  TransportPacket.create({
    required this.socket,
    required this.handshake,
    required this.id,
    required this.waitForResponse,
    required this.responseTo,
    required this.packetTypeId,
    required this.packet,
  }) {
    PacketHelper.setTransport(packet, this);
  }

  late Completer<TransportPacket> mWaitForResponse;

  static TransportPacket parse(
    Socket socket,
    dynamic data,
    Map<String, Packet> packetsById,
  ) {
    if(data is! JSObject)
      throw UnknownDataException();

    final json = (dartify(data) as LinkedHashMap).cast<String, Object?>();
  
    if(!json.containsKey('handshake')
      || !json.containsKey('id')
      || !json.containsKey('packetTypeId')
      || !json.containsKey('payload'))
      throw UnknownDataException();
    
    final handshake = json['handshake'] as String;
    final id = json['id'] as int;
    final waitForResponse = json.containsKey('waitForResponse') ? json['waitForResponse'] as bool : false;
    final responseTo = json.containsKey('responseTo') ? json['responseTo'] as int : null;
    final packetTypeId = json['packetTypeId'] as String;
    final payload = json['payload'];

    if(!packetsById.containsKey(packetTypeId)) {
      throw 'unknown packet id $packetTypeId';
    } final parser = packetsById[packetTypeId]!;

    final packet = parser.parse(payload);

    return TransportPacket.create(
      socket: socket,
      handshake: handshake,
      id: id,
      waitForResponse: waitForResponse,
      responseTo: responseTo,
      packetTypeId: packetTypeId,
      packet: packet,
    );
  }

  dynamic build() {
    final json = {
      'handshake': handshake,
      'id': id,
      if(waitForResponse == true)
        'waitForResponse': waitForResponse,
      if(responseTo != null)
        'responseTo': responseTo,
      'packetTypeId': packetTypeId,
      'payload': packet.build(),
    };
    return jsify(json);
  }
}