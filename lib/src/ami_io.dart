import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:web_socket_channel/status.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

import 'call_center.dart';
import 'constants.dart';
import 'structure.dart';
import 'utils.dart';

abstract class AMIConnector extends LifeCycle {
  AMIReader _reader;

  set reader(AMIReader reader) => _reader = reader;

  Future<void> connect(String host, int port, {dynamic args});

  void send(Map<String, String> data);

  bool available();
}

class WebSocketConnector extends AMIConnector {
  WebSocketChannel _socket;
  StreamSubscription _listener;
  bool _greetingSent = false;

  @override
  Future<void> connect(String host, int port, {dynamic args}) async {
    final useSSL = args == true;
    _socket = WebSocketChannel.connect(
      Uri(host: host, port: port, scheme: useSSL ? 'wss' : 'ws'),
    );
    _listener = _socket.stream.listen(handleData);
  }

  @override
  void dispose() {
    _listener?.cancel();
    _socket?.sink?.close(goingAway);
    _socket = null;
    _greetingSent = false;
  }

  @override
  bool available() {
    return _socket != null;
  }

  void handleData(data) {
    try {
      final jsonData = json.decode(data);
      if (!_greetingSent) {
        _greetingSent = true;
        _reader?.onReadGreeting(
            '${jsonData['server_name']}/${jsonData['server_id']}');
      }
      final headers = jsonData['data'];
      switch (jsonData['type']) {
        case 4:
          final response =
              Response(BaseMessage.fromJson(MessageType.response, headers));
          _reader?.onReadResponse(response);
          break;
        case 3:
          final event = Event(BaseMessage.fromJson(MessageType.event, headers));
          _reader?.onReadEvent(event);
          break;
        default:
          print('can not handle unknown data $jsonData');
      }
    } catch (e) {
      print('not right data format $e');
    }
  }

  @override
  void send(Map<String, String> data) {
    _socket.sink.add(json.encode(data));
  }
}

class TCPSocketConnector extends AMIConnector with _SocketMessageReader {
  Socket _socket;
  StreamSubscription _listener;

  @override
  Future<void> connect(String host, int port, {dynamic args}) async {
    _socket = await Socket.connect(host, port);
    _listener = _socket.listen(handleData);
  }

  @override
  void dispose() {
    _listener?.cancel();
    _socket?.close();
    _socket = null;
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

mixin _SocketMessageReader on LifeCycle, AMIConnector {
  HandleStatus _status = HandleStatus.idle;
  List<String> _buffer = [];

  @override
  void dispose() {
    _status = HandleStatus.idle;
    _buffer.clear();
    super.dispose();
  }

  void handleData(event) {
    final data = String.fromCharCodes(event);
    // print('---dataSTART---$EOL$data---dataEND---');

    final lines = data.split(eol);
    lines.removeLast();

    for (final line in lines) {
      if (line.isNotEmpty) {
        _status = HandleStatus.reading;
        _buffer.add(line);
      } else {
        _status = HandleStatus.done;
        _handleStatus();
      }
    }
    if (_status == HandleStatus.reading) {
      _status = HandleStatus.truncated;
      _handleStatus();
    }
  }

  void _handleStatus() {
    // print('current status $_status');
    // print('current status $_status buffer $_buffer');

    if (_status == HandleStatus.truncated && isGreetingLines(_buffer)) {
      _reader?.onReadGreeting(_buffer.first);
      _buffer.clear();
      _status = HandleStatus.idle;
    } else if (_status == HandleStatus.done) {
      if (isGreeting(_buffer.first)) {
        _reader?.onReadGreeting(_buffer.first);
        _buffer.removeAt(0);
      }

      final message = BaseMessage.fromLines(_buffer);
      switch (message.type) {
        case MessageType.response:
          final resp = Response(message);
          print('sink resp ${resp.actionID}');
          _reader?.onReadResponse(resp);
          break;
        case MessageType.event:
          final event = Event(message);
          print('sink event ${event.name}');
          _reader?.onReadEvent(event);
          break;
        default:
          print('handle type ${message.type} failed, skip');
      }
      _buffer.clear();
      _status = HandleStatus.idle;
    }
  }
}
