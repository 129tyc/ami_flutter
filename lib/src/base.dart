import 'dart:async';

import 'dispatcher.dart';
import 'structure.dart';

mixin LifeCycle {
  void init() {}

  void dispose() {}
}

mixin Reader {
  void onReadResponse(Response response) {}

  void onReadEvent(Event event) {}

  void onReadGreeting(String words) {}
}

mixin Connector {
  Future<void> connect(String host, int port, {dynamic args});

  void send(Map<String, String> data);

  bool available();
}

mixin Parser {
  void handleMessage(dynamic message);
}

mixin Sender on Connector, Dispatcher {
  String prefix;

  Future<Response> sendAction(
    String name, {
    String id,
    Map<String, String> args,
  }) async {
    if (!available()) {
      return null;
    }

    id ??= '${prefix}_${DateTime.now().millisecondsSinceEpoch}';

    print('send action $name id $id');

    final data = <String, String>{'Action': name, 'ActionID': id}..addAll(args ?? {});
    // print('send action payload $data');

    send(data);

    return registerResponse(id).first;
  }
}
