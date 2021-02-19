import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:web_socket_channel/status.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

import 'base.dart';
import 'constants.dart';

mixin WebSocketConnector on LifeCycle, Parser implements Connector {
  WebSocketChannel _socket;
  StreamSubscription _listener;

  StreamController _controller;

  Stream get statusStream => _controller?.stream;

  @override
  void init() {
    _controller = StreamController.broadcast();
    super.init();
  }

  @override
  Future<void> connect(String host, int port, {dynamic args}) async {
    final useSSL = args == true;
    _socket = WebSocketChannel.connect(
      Uri(host: host, port: port, scheme: useSSL ? 'wss' : 'ws'),
    );
    _listener = _socket.stream.listen(
      handleMessage,
      onError: (e) {
        _controller.addError(e);
        disconnect();
      },
      cancelOnError: true,
    );
    _controller.add(true);
  }

  @override
  void disconnect() {
    _listener?.cancel();
    _socket?.sink?.close(goingAway);
    _socket = null;
    _controller.add(false);
  }

  @override
  void dispose() {
    disconnect();
    _controller.close();
    super.dispose();
  }

  @override
  bool available() {
    return _socket != null;
  }

  @override
  void send(Map<String, String> data) {
    _socket.sink.add(json.encode(data));
  }
}

mixin TCPSocketConnector on LifeCycle, Parser implements Connector {
  Socket _socket;
  StreamSubscription _listener;

  StreamController _controller;

  Stream get statusStream => _controller?.stream;

  @override
  void init() {
    _controller = StreamController.broadcast();
    super.init();
  }

  @override
  Future<void> connect(String host, int port, {dynamic args}) async {
    try {
      _socket = await Socket.connect(host, port);
      _listener = _socket.listen(handleMessage, onError: (e) {
        _controller.addError(e);
        disconnect();
      });
      _controller.add(true);
    } catch (e) {
      _controller.addError(e);
      _controller.add(false);
    }
  }

  @override
  void disconnect() {
    _listener?.cancel();
    _socket?.close();
    _socket = null;
    _controller.add(false);
  }

  @override
  void dispose() {
    disconnect();
    _controller.close();
    super.dispose();
  }

  @override
  bool available() {
    return _socket != null;
  }

  @override
  void send(Map<String, String> data) {
    final payload = <String>[];
    data.forEach((key, value) {
      payload.add('$key: $value');
    });
    payload.add(eol);
    _socket.write(payload.join(eol));
    _socket.flush();
  }
}
