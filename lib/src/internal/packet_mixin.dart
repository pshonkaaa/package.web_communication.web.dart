import 'package:web_communication/library.dart';

import 'transport_packet.dart';

mixin PacketMixin {
  late final String _typeId;
  late final TransportPacket _transport;
}

abstract class PacketHelper {
  static String getTypeId(
    Packet packet,
  ) => packet._typeId;

  static String setTypeId(
    Packet packet,
    String value,
  ) => packet._typeId = value;


  static TransportPacket getTransport(
    Packet packet,
  ) => packet._transport;

  static TransportPacket setTransport(
    Packet packet,
    TransportPacket value,
  ) => packet._transport = value;
}