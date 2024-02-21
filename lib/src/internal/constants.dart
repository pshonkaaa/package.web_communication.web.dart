import 'package:web_communication/library.dart';

abstract class Constants {
  static List<Packet> get DEFAULT_PACKETS => [
    NullPacket.builder(),
    PingPacket.builder(),
    PongPacket.builder(),
    SingleValuePacket.builder(),
  ];

  static const Duration PING_INTERVAL = Duration(seconds: 7);
  static const Duration PING_TIMEOUT = Duration(seconds: 5);
  static const Duration WAIT_FOR_RESPONSE_TIMEOUT = Duration(seconds: 30);
}