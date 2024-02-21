import 'package:web_communication/library.dart';

class NullPacket extends Packet<Object?> {
  NullPacket.builder();
  NullPacket();

  @override
  Object? build() {
    return null;
  }

  @override
  Packet parse(Object? data) {
    return NullPacket();
  }
}

class PingPacket extends NullPacket {
  PingPacket.builder();
  PingPacket();

  @override
  Object? build() {
    return null;
  }

  @override
  Packet parse(Object? data) {
    return PingPacket();
  }
}

class PongPacket extends NullPacket {
  PongPacket.builder();
  PongPacket();

  @override
  Object? build() {
    return null;
  }

  @override
  Packet parse(Object? data) {
    return PongPacket();
  }
}

class SingleValuePacket<T> extends Packet {
  SingleValuePacket.builder();
  SingleValuePacket(this.value);

  late final T value;

  @override
  Object? build() {
    return value;
  }

  @override
  Packet parse(Object? data) {
    return SingleValuePacket(data);
  }
}