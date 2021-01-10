import 'constants.dart';
import 'utils.dart';

class BaseMessage {
  Map<String, String> _headers;
  MessageType _type;

  MessageType get type => _type;

  Map<String, String> get headers => _headers;

  BaseMessage.fromLines(List<String> lines) {
    _type = decodeType(lines);
    _headers = decodeHeaders(lines);
  }

  BaseMessage.fromJson(MessageType type, Map<String, dynamic> json) {
    _type = type;
    final headers = json.map((key, value) => MapEntry(key, value.toString()));
    _headers = headers;
  }
}

class Response {
  final BaseMessage baseMsg;

  Response(this.baseMsg);

  bool get succeed => baseMsg.headers['Response'] == 'Success';

  String get actionID => baseMsg.headers['ActionID'];
}

class Event {
  final BaseMessage baseMsg;

  Event(this.baseMsg);

  String get name => baseMsg.headers['Event'];
}
