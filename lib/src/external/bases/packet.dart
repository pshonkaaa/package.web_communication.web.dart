import 'package:web_communication/src/internal/packet_mixin.dart';

abstract class Packet<T> with PacketMixin {
  Packet.builder();
  Packet();
  
  Packet parse(T data);

  T build();
}

// abstract class BytePacket extends Packet<Uint8List> {
//   BytePacket.builder();
//   BytePacket();
  
//   BytePacket parse(Uint8List? data);

//   Uint8List? build();
// }

// abstract class JsonPacket extends Packet<Map<String, dynamic>> {
//   JsonPacket.builder();
//   JsonPacket();
  
//   JsonPacket parse(Map<String, dynamic>? data);

//   Map<String, dynamic>? build();
// }