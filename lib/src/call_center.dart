import 'dart:async';

import 'ami_io.dart';
import 'structure.dart';

abstract class LifeCycle {
  void init() {}

  void dispose() {}
}

abstract class AMIReader {
  void onReadResponse(Response response);

  void onReadEvent(Event event);

  void onReadGreeting(String words);
}

typedef EventPredicate = bool Function(Event event);

mixin CallCenter on LifeCycle implements AMIReader {
  String get prefix;

  AMIConnector _connector;

  AMIConnector get connector => _connector;

  set connector(AMIConnector connector) {
    _connector = connector;
    _connector.reader = this;
  }

  StreamController<Response> _responseStream;
  StreamController<Event> _eventStream;
  StreamSubscription<Event> _eventDispatcher;
  StreamSubscription<Response> _respDispatcher;

  Map<String, StreamController<Event>> _eventListeners = {};
  Map<String, StreamController<Response>> _respListeners = {};

  @override
  void onReadEvent(Event event) {
    _eventStream.add(event);
  }

  @override
  void onReadResponse(Response response) {
    _responseStream.add(response);
  }

  @override
  void init() {
    _responseStream = StreamController<Response>();
    _eventStream = StreamController<Event>();
    _eventDispatcher = _eventStream.stream.listen((event) {
      print('dispatch event ${event.name}');
      _eventListeners[event.name]?.add(event);
    });
    _respDispatcher = _responseStream.stream.listen((event) {
      print('dispatch response ${event.actionID}');
      _respListeners[event.actionID]?.add(event);
    });
  }

  Stream<Event> registerEvent(String name) {
    if (!_eventListeners.containsKey(name)) {
      _eventListeners[name] = StreamController<Event>.broadcast();
    }
    return _eventListeners[name].stream;
  }

  Future<Event> readEvent(String name) async {
    return registerEvent(name).first;
  }

  Future<List<Event>> readAllEventsUntil(String name, String eventPredicate) {
    final completer = Completer<List<Event>>();
    final res = <Event>[];

    final listener =
        registerEvent(name).listen((e) => res.add(e), cancelOnError: true);
    readEvent(eventPredicate).then((value) {
      listener.cancel();
      completer.complete(res);
    });
    return completer.future;
  }

  Stream<Response> _registerResponse(String actionID) {
    if (!_respListeners.containsKey(actionID)) {
      _respListeners[actionID] = StreamController<Response>.broadcast();
    }
    return _respListeners[actionID].stream;
  }

  Future<void> connect(String host, int port, {dynamic args}) {
    return connector.connect(host, port, args: args);
  }

  @override
  void dispose() {
    connector.dispose();

    _eventDispatcher?.cancel();
    _respDispatcher?.cancel();
    _eventListeners.forEach((_, value) => value?.close());
    _eventListeners.clear();
    _respListeners.forEach((_, value) => value?.close());
    _respListeners.clear();
    super.dispose();
  }

  Future<Response> sendAction(
    String name, {
    String id,
    Map<String, String> args,
  }) async {
    if (!connector.available()) {
      return null;
    }

    id ??= '${prefix}_${DateTime.now().millisecondsSinceEpoch}';

    print('send action $name id $id');

    final data = <String, String>{'Action': name, 'ActionID': id}
      ..addAll(args ?? {});
    // print('send action payload $data');

    connector.send(data);

    return _registerResponse(id).first;
  }
}
