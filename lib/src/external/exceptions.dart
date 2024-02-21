import 'package:web_communication/library.dart';

class UnknownDataException implements Exception {}
class SocketClosedException implements Exception {}

class PacketNotWaitingForResponse implements Exception {
  final Packet packet;
  PacketNotWaitingForResponse(this.packet);
}

class UnknownHandshakeException implements Exception {
  final String handshake;
  UnknownHandshakeException(this.handshake);
}