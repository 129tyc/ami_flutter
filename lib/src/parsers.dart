import 'dart:convert';

import 'base.dart';
import 'constants.dart';
import 'structure.dart';
import 'utils.dart';

mixin WebSocketMessageParser on LifeCycle, Reader implements Parser {
  bool _greetingSent;

  @override
  void init() {
    _greetingSent = false;
    super.init();
  }

  @override
  void dispose() {
    _greetingSent = false;
    super.dispose();
  }

  @override
  void handleMessage(message) {
    try {
      final jsonData = json.decode(message);
      if (!_greetingSent) {
        _greetingSent = true;
        onReadGreeting('${jsonData['server_name']}/${jsonData['server_id']}');
      }
      final headers = jsonData['data'];
      switch (jsonData['type']) {
        case 4:
          final response = Response(BaseMessage.fromJson(MessageType.response, headers));
          onReadResponse(response);
          break;
        case 3:
          final event = Event(BaseMessage.fromJson(MessageType.event, headers));
          onReadEvent(event);
          break;
        default:
          print('can not handle unknown data $jsonData');
      }
    } catch (e) {
      print('not right data format $e');
    }
  }
}

mixin SocketMessageParser on LifeCycle, Reader implements Parser {
  HandleStatus _status;
  List<String> _buffer;

  @override
  void init() {
    _status = HandleStatus.idle;
    _buffer = [];
    super.init();
  }

  @override
  void dispose() {
    _status = HandleStatus.idle;
    _buffer.clear();
    super.dispose();
  }

  @override
  void handleMessage(dynamic message) {
    final data = String.fromCharCodes(message);
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
      onReadGreeting(_buffer.first);
      _buffer.clear();
      _status = HandleStatus.idle;
    } else if (_status == HandleStatus.done) {
      if (isGreeting(_buffer.first)) {
        onReadGreeting(_buffer.first);
        _buffer.removeAt(0);
      }

      final message = BaseMessage.fromLines(_buffer);
      switch (message.type) {
        case MessageType.response:
          final resp = Response(message);
          print('sink resp ${resp.actionID}');
          onReadResponse(resp);
          break;
        case MessageType.event:
          final event = Event(message);
          print('sink event ${event.name}');
          onReadEvent(event);
          break;
        default:
          print('handle type ${message.type} failed, skip');
      }
      _buffer.clear();
      _status = HandleStatus.idle;
    }
  }
}
