import 'dart:async';

import 'base.dart';
import 'structure.dart';

typedef EventPredicate = bool Function(Event event);

mixin Dispatcher on LifeCycle, Reader {
  StreamController<Response> _responseStream;
  StreamController<Event> _eventStream;
  StreamSubscription<Event> _eventDispatcher;
  StreamSubscription<Response> _respDispatcher;

  Map<String, StreamController<Event>> _eventListeners = {};
  Map<String, StreamController<Response>> _respListeners = {};

  @override
  void onReadEvent(Event event) {
    _eventStream.add(event);
    super.onReadEvent(event);
  }

  @override
  void onReadResponse(Response response) {
    _responseStream.add(response);
    super.onReadResponse(response);
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
      print('create stream for event $name');
      final controller = StreamController<Event>.broadcast();
      controller.onCancel = () {
        print('event $name stream cancel, close and remove');
        controller.close();
        _eventListeners.remove(name);
      };
      _eventListeners[name] = controller;
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

  Stream<Response> registerResponse(String actionID) {
    if (!_respListeners.containsKey(actionID)) {
      _respListeners[actionID] = StreamController<Response>.broadcast();
    }
    return _respListeners[actionID].stream;
  }

  @override
  void dispose() {
    _eventDispatcher?.cancel();
    _respDispatcher?.cancel();
    _eventListeners.forEach((_, value) => value?.close());
    _eventListeners.clear();
    _respListeners.forEach((_, value) => value?.close());
    _respListeners.clear();
    super.dispose();
  }
}
