import 'package:web_communication/library.dart';

typedef void OnSocketCallback(Socket socket);
typedef void OnMessageCallback(Socket socket, Packet packet);

enum EConnectionType {
  /// runtime.sendMessage
  http,

  /// runtime.connect
  socket,
}