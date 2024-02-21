import 'dart:async';

import 'package:logger/logger.dart';
import 'package:foundation/library.dart';
import 'package:web_communication/library.dart';
import 'package:web_communication/src/internal/packet_mixin.dart';

import 'bases/base_communicator.dart';
import 'bases/server.dart';
import 'constants.dart';
import 'transport_packet.dart';

enum ESocketSide {
  server,
  client,
}

abstract class BaseSocket extends BaseAsyncStateable implements Socket {
  static const TAG = 'BaseSocket';

  BaseSocket({
    required this.communicator,
  }) : id = communicator.controller.getNewSocketId(),
    side = communicator is BaseServerCommunicator ? ESocketSide.server : ESocketSide.client;

  final int id;

  final ESocketSide side;

  final BaseCommunicator communicator;

  BaseService? _pingService;

  bool _connected = false;
  
  bool _closed = true;

  int _lastPacketId = 0;
  
  int _nextPacketId()
    => _lastPacketId++;

  final Map<int, TransportPacket> _waitForResponseList = {};

  @override
  Future<void> initState() async {
    await super.initState();
  }

  @override
  Future<void> dispose() async {
    _stopPingingService();
    
    await super.dispose();
  }
  
  
  @override
  bool get connected => _connected;
  
  @override
  bool get closed => _closed;

  @override
  Future<T?> send<T extends Packet>(
    Packet packet, {
      Packet? responseTo,
      bool waitForResponse = false,
      Duration timeout = Constants.WAIT_FOR_RESPONSE_TIMEOUT,
  }) async {
    communicator.logger?.d('$TAG > send(packet=${packet.runtimeType}, responseTo=${responseTo?.runtimeType}, waitForResponse=$waitForResponse);');

    throwIfClosed();

    throwIfUnknownCommunicator();

    if(communicator is ServerCommunicator) {
      return await (communicator as ServerCommunicator).send(
        this,
        packet,
        responseTo: responseTo,
        waitForResponse: waitForResponse,
        timeout: timeout,
      );
    } else {
      return await (communicator as ClientCommunicator).send(
        packet,
        responseTo: responseTo,
        waitForResponse: waitForResponse,
        timeout: timeout,
      );
    }
  }

  @override
  Future<void> sendPing({
    Duration timeout = Constants.PING_TIMEOUT,
  }) async {

    throwIfUnknownCommunicator();

    if(communicator is ServerCommunicator) {
      return await (communicator as ServerCommunicator).sendPing(
        this,
        timeout: timeout,
      );
    } else {
      return await (communicator as ClientCommunicator).sendPing(
        timeout: timeout,
      );
    }
  }

  @override
  Future<T?> sendWithResponse<T extends Packet>(
    Packet packet, {
      Packet? responseTo,
      Duration timeout = Constants.WAIT_FOR_RESPONSE_TIMEOUT,
  }) async {
    communicator.logger?.d('$TAG > sendWithResponse();');
    
    throwIfClosed();

    throwIfUnknownCommunicator();

    if(communicator is ServerCommunicator) {
      return await (communicator as ServerCommunicator).sendWithResponse(
        this,
        packet,
        responseTo: responseTo,
        timeout: timeout,
      );
    } else {
      return await (communicator as ClientCommunicator).sendWithResponse(
        packet,
        responseTo: responseTo,
        timeout: timeout,
      );
    }
  }
  
  @override
  Future<void> close() async {
    if(closed)
      return;
      
    communicator.logger?.d('$TAG > close();');

    throwIfUnknownCommunicator();

    if(communicator is ServerCommunicator) {
      return await (communicator as ServerCommunicator).closeSocket(this);
    }
    
    if(communicator is ClientCommunicator) {
      return await (communicator as ClientCommunicator).close();
    }
  }

  void throwIfClosed() {
    if(closed)
      throw SocketClosedException();
  }

  void throwIfUnknownCommunicator() {
    if(communicator is ServerCommunicator || communicator is ClientCommunicator)
      return;

    throw "Unknown communicator type ${communicator.runtimeType}";
  }

  void _startPingingService() {
    if(_pingService != null) {
      _stopPingingService();
    }
    
    if(communicator.pingInterval.inMilliseconds == 0)
      return;
    
    _pingService = DelegatedService(
      runner: () async {
        try {
          await sendPing();
        } on TimeoutException {
          _stopPingingService();
          
          close();
        }
      },
    );

    ServiceManager.start(_pingService!, repeatInterval: communicator.pingInterval);
  }

  void _stopPingingService() {
    if(_pingService == null)
      return;

    ServiceManager.stop(_pingService!);
    _pingService = null;
  }
}














class CommunicatorController {
  static const TAG = 'CommunicatorController';

  CommunicatorController(
    this._communicator, {
      required List<Packet> packets,
  }) {
    for(int i = 0; i < packets.length; i++) {
      final packet = packets[i];
      // if(packet == null)
      //   continue;
      PacketHelper.setTypeId(packet, i.toString());
    }

    final list = packets.removeNull().cast<Packet>().toList();

    _packetsByType = Map.fromEntries(list.map((e) => MapEntry(e.runtimeType, e)));
    _packetsById = Map.fromEntries(list.map((e) => MapEntry(PacketHelper.getTypeId(e), e)));
  }


  final BaseCommunicator _communicator;

  bool _closed = true;
  
  bool _closing = false;

  late final Map<Type, Packet> _packetsByType;
  late final Map<String, Packet> _packetsById;

  // final Map<int, TransportPacket> _toResponseList = {};

  final List<BaseSocket> _sockets = [];

  int _lastSocketId = 0;



  Iterable<BaseSocket> get sockets => _sockets;

  Logger? get logger => _communicator.logger;

  String get handshake => _communicator.handshake;

  bool get closed => _closed;

  OnSocketCallback? onConnectCallback;

  OnSocketCallback? onDisconnectCallback;
  
  OnMessageCallback? onMessageCallback;

  void onOpen() {
    logger?.d('$TAG > onOpen(); handshake=${_communicator.handshake}');
    
    if(!_closed)
      throw Exception('Socket already opened');

    _closed = false;
  }
  
  void onConnect(BaseSocket socket) {
    logger?.d('$TAG > onConnect(socket=${socket.id}); handshake=${_communicator.handshake}');

    throwIfClosed();

    socket._connected = true;
    socket._closed = false;

    _sockets.add(socket);

    socket.initState();

    if(socket.side == ESocketSide.client) {
      socket._startPingingService();
    } else {
      Future.delayed(Duration(seconds: 5), () {
        socket._startPingingService();
      });
    }

    onConnectCallback?.call(socket);
  }

  void onDisconnect(BaseSocket socket) {
    logger?.d('$TAG > onDisconnect(socket=${socket.id}); handshake=${_communicator.handshake}');
    
    throwIfClosed();

    socket._connected = false;
    socket._closed = true;

    socket.dispose();

    _sockets.remove(socket);
    
    onDisconnectCallback?.call(socket);
  }
  
  Future<void> onClose() async {
    logger?.d('$TAG > onClose(); handshake=${_communicator.handshake}');

    throwIfClosed();

    // anti-recursive; [ClientSocket]socket.close()=>[ClientCommunicator]communicator.close()=>controller.onClose()=>repeat
    if(_closing)
      return;

    _closing = true;

    final List<Future> toAwait = [];
    while(_sockets.isNotEmpty) {
      final list = sockets.toList();
      for(final socket in list) {
        toAwait.add(socket.close());
      }
      await Future.wait(toAwait);
    }

    _closed = true;
    _closing = false;
  }

  Future<T?> send<T extends Packet>(
    BaseSocket socket,
    Packet packet, {
      Packet? responseTo,
      bool waitForResponse = false,
      Duration timeout = Constants.WAIT_FOR_RESPONSE_TIMEOUT,
      bool testWater = false,
  }) async {
    logger?.d('$TAG > send(packet=${packet.runtimeType}, responseTo=${responseTo?.runtimeType}, waitForResponse=$waitForResponse, testWater=$testWater); handshake=${_communicator.handshake}');
    
    if(!testWater) {
      _throwIfSocketNotConnected(socket);
    }

    final data = preparePacket(
      socket,
      packet,
      waitForResponse: waitForResponse,
      responseTo: responseTo,
    );

    await _communicator.sendRequestDelegate(
      socket,
      data,
      waitForResponse: waitForResponse,
      testWater: testWater,
    );
    
    if(waitForResponse) {
      final responsePacket = await waitForRequestResponse(
        socket,
        packet,
        timeout: timeout,
      );
      return responsePacket as T?;
    } return null;
  }

  Future<void> sendPing(
    BaseSocket socket, {
      Duration timeout = Constants.PING_TIMEOUT,
      bool testWater = false,
  }) async {
    logger?.d('$TAG > sendPing(timeout=${timeout}, testWater=$testWater); handshake=${_communicator.handshake}');
    
    if(!testWater) {
      _throwIfSocketNotConnected(socket);
    }

    await send<PongPacket>(
      socket,
      PingPacket(),
      waitForResponse: true,
      timeout: timeout,
      testWater: true,
    );
  }

  Future<T?> sendWithResponse<T extends Packet>(
    BaseSocket socket,
    Packet packet, {
      Packet? responseTo,
      Duration timeout = Constants.WAIT_FOR_RESPONSE_TIMEOUT,
  }) async {
    logger?.d('$TAG > sendWithResponse(packet=${packet.runtimeType}, responseTo=${responseTo?.runtimeType}, timeout=$timeout); handshake=${_communicator.handshake}');
    
    _throwIfSocketNotConnected(socket);
    
    return await send(
      socket,
      packet,
      responseTo: responseTo,
      waitForResponse: true,
      timeout: timeout,
    );
  }

  int getNewSocketId()
    => _lastSocketId += 4;

  dynamic preparePacket(
    BaseSocket socket,
    Packet packet, {
      required bool waitForResponse,
      required Packet? responseTo,
  }) {
    logger?.d('$TAG > preparePacket(packet=${packet.runtimeType}); handshake=${_communicator.handshake}');

    final responseToTransport = responseTo == null ? null : PacketHelper.getTransport(responseTo);

    if(responseTo != null) {
      if(!responseToTransport!.waitForResponse)
        throw PacketNotWaitingForResponse(responseTo);
    }


    final transport = _packet2transport(
      socket,
      packet,
      responseTo: responseToTransport?.id,
      waitForResponse: waitForResponse,
    );

    if(transport.waitForResponse) {
      transport.mWaitForResponse = Completer();
      socket._waitForResponseList[transport.id] = transport;
    } return transport.build();
  }

  void onReceive(
    BaseSocket socket,
    dynamic data,
  ) {
    if(_closed)
      return;

    final transport = _data2packet(socket, data);
    final packet = transport.packet;
    final responseTo = transport.responseTo;
      
    logger?.d('$TAG > onReceive(socket=${socket.id}, packetId=${transport.id}, packet=${packet.runtimeType}); handshake=${_communicator.handshake}');

    if(responseTo != null) {
      if(!socket._waitForResponseList.containsKey(responseTo)) {
        throw Exception("Unknown responseTo $responseTo");
      }

      final transportSent = socket._waitForResponseList.remove(responseTo)!;

      logger?.d('$TAG > got response for packet ${transportSent.packet.runtimeType}; id = ${transportSent.id}');

      transportSent.mWaitForResponse.complete(transport);
      
    } else {
      if(packet is PingPacket) {
        _sendPong(
          socket,
          packet,
        );

        if(socket.side == ESocketSide.server) {
          // Restarting
          socket._stopPingingService();
          socket._startPingingService();
        }
        return;
      }

      onMessageCallback?.call(socket, packet);
    }
  }

  Future<void> _sendPong(
    BaseSocket socket,
    PingPacket responseTo,
  ) async {
    final responseToTransport = PacketHelper.getTransport(responseTo);

    logger?.d('$TAG > _sendPong(socket=${socket.id}, responseTo=${responseToTransport.id})');

    if(_communicator is ClientCommunicator) {
      final com = _communicator as ClientCommunicator;
      await com.send(
        PongPacket(),
        responseTo: responseTo,
      );

    } else {
      final com = _communicator as ServerCommunicator;
      await com.send(
        socket,
        PongPacket(),
        responseTo: responseTo,
      );
    }
  }

  Future<Packet?> waitForRequestResponse(
    BaseSocket socket,
    Packet packet, {
      required Duration timeout,
      bool closeIfTimeout = false,
  }) async {
    final transport = PacketHelper.getTransport(packet);

    logger?.d('$TAG > waitForRequestResponse(packet=${packet.runtimeType}, id=${transport.id}, closeIfTimeout=$closeIfTimeout)');
    
    try {
      final transportResponse = await transport.mWaitForResponse.future.timeout(timeout);
      return transportResponse.packet is NullPacket ? null : transportResponse.packet;
    } on TimeoutException {
      logger?.d('$TAG > waitForRequestResponse(); TimeoutException. packet=${packet.runtimeType}, id=${transport.id}');
      if(closeIfTimeout) {
        socket.close();
      } rethrow;
    }
  }

  TransportPacket _packet2transport(
    BaseSocket socket,
    Packet packet, {
      required bool waitForResponse,
      required int? responseTo,
  }) {
    PacketHelper.setTypeId(packet, _getPacketTypeIdByPacket(packet));

    final transport = TransportPacket.create(
      socket: null,
      handshake: _communicator.handshake,
      id: socket._nextPacketId(),
      waitForResponse: waitForResponse,
      responseTo: responseTo,
      packetTypeId: PacketHelper.getTypeId(packet),
      packet: packet,
    );
    return transport;
  }

  String _getPacketTypeIdByPacket(Packet packet) {
    final hasType = _packetsByType.containsKey(packet.runtimeType);
    if(hasType) {
      return PacketHelper.getTypeId(_packetsByType[packet.runtimeType]!);
    }

    final packetType = packet.runtimeType.toString().replaceFirst(RegExp('<.*>'), '');
    final baseType = _packetsByType.values.tryFirstWhere((e) => e.runtimeType.toString().replaceFirst(RegExp('<.*>'), '') == packetType);
    if(baseType != null) {
      return PacketHelper.getTypeId(_packetsByType[baseType.runtimeType]!);
    }
    
    /// NOTE: checking next cases and allowing
    /// packets is [List<dynamic>, WhateverPacket<dynamic>]
    /// packet is Packet<List<int>> or WhateverPacket<String>

    // logger?.d('_packets');
    // logger?.d(_packetsByType.keys.toList());

    // logger?.d('map');
    // logger?.d(_packetsByType.values.map((e) => _isChildType(e, packet)).toList());
    
    // logger?.d('map reverse');
    // logger?.d(_packetsByType.values.map((e) => _isChildType(packet, e)).toList());

    // final baseType = _packetsByType.values.tryFirstWhere((e) => _isChildType(e, packet));
    // if(baseType != null) {
    //   return _packetsByType[baseType.runtimeType]!._packetId;
    // }

    logger?.d('_packetsByType = ');
    logger?.d(_packetsByType.keys.toList());
    logger?.d(_packetsByType.keys.map((e) => e.hashCode).toList());
    throw Exception('Unknown packet ${packet.runtimeType}#${packet.runtimeType.hashCode}');
  }

  // bool _isChildType<TBase, TChild>(TBase base, TChild child) {
  //   return child is TBase;
  // }

  TransportPacket _data2packet(
    Socket socket,
    dynamic data,
  ) {
    final transport = TransportPacket.parse(
      socket,
      data,
      _packetsById,
    );

    if(transport.handshake != _communicator.handshake) {
      throw UnknownHandshakeException(transport.handshake);
    }

    return transport;
  }

  void throwIfClosed() {
    if(_closed)
      throw Exception('Connection closed');
  }


  void _throwIfSocketNotConnected(BaseSocket socket) {
    if(!socket.connected)
      throw Exception('Socket not connected');
  }
}