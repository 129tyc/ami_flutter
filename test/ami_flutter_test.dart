import 'package:ami_flutter/ami_flutter.dart';
import 'package:test/test.dart';

void main() async {
  TestManager manager;
  setUp(() async {
    print('set up');
    manager = TestManager()..init();
    await manager.connect('127.0.0.1', 8000);
  });
  tearDown(() {
    print('tear down');
    manager.dispose();
  });

  test('test mock available', () {
    expect(manager.available(), true);
  });

  test('test mock greeting', () {
    manager.title.then(expectAsync1((value) {
      expect(value, 'TestTitle');
    }));
    manager.version.then(expectAsync1((value) {
      expect(value, 'TestVersion');
    }));
    manager.mockMessages.add('TestTitle/TestVersion');
    manager.handleMessage(null);
  });

  test('test mock send resp', () async {
    manager.mockMessages
        .add(BaseMessage.fromJson(MessageType.response, {'Response': 'Success', 'ActionID': 'testActionID'}));
    final res = await manager.sendAction('DongleShowDevices', id: 'testActionID');
    expect(res.succeed, true);
  });

  test('test mock listen event', () async {
    manager.mockMessages.add(BaseMessage.fromJson(MessageType.event, {'Event': 'testEvent'}));

    final listener = manager.registerEvent('testEvent').listen(null);
    final callback = (Event event) {
      expect(event.name, 'testEvent');
      listener.cancel();
    };
    listener.onData(expectAsync1(callback));
    manager.handleMessage(null);
  });

  test('test mock read event', () async {
    manager.mockMessages.add(BaseMessage.fromJson(MessageType.event, {'Event': 'testEvent'}));

    manager.handleMessage(null);
    final event = await manager.readEvent('testEvent');
    expect(event.name, 'testEvent');
  });

  test('test mock read all events', () async {
    manager.mockMessages.add(BaseMessage.fromJson(MessageType.event, {'Event': 'testEvent'}));
    manager.mockMessages.add(BaseMessage.fromJson(MessageType.event, {'Event': 'testEvent'}));
    manager.mockMessages.add(BaseMessage.fromJson(MessageType.event, {'Event': 'testEvent1'}));

    manager.handleMessage(null);
    final events = await manager.readAllEventsUntil('testEvent', 'testEvent1');
    expect(events.length, 2);
  });
/*
  test('test web socket', () async {
    final manager = WebSocketManager()..prefix = 'web_socket';
    manager.init();
    await manager.connect('127.0.0.1', 8000);

    var res = await manager.sendAction('DongleShowDevices');

    print('devices res ${res.baseMsg.headers}');

    var events = await manager.readAllEventsUntil(
      'DongleDeviceEntry',
      'DongleShowDevicesComplete',
    );
    print('device info ${events.length} ${events[0].baseMsg.headers}');
    manager.dispose();
  });

  test('test normal socket', () async {
    final manager = DefaultManager()..init();
    await manager.connect('127.0.0.1', 5038);

    var res = await manager.login('xxx', 'xxx');

    print('login res ${res.succeed}');

    res = await manager.sendAction('DongleShowDevices');

    print('devices res ${res.baseMsg.headers}');

    var events = await manager.readAllEventsUntil(
      'DongleDeviceEntry',
      'DongleShowDevicesComplete',
    );
    print('device info ${events.length} ${events[0].baseMsg.headers}');

    await manager.logoff();
    manager.dispose();
  });*/
}

class TestManager extends BaseManager with MockConnector, MockParser {}

mixin MockParser on Reader implements Parser {
  List mockMessages = [];

  @override
  void handleMessage(message) {
    mockMessages.forEach((element) {
      _mockDispatch(element);
    });
  }

  void _mockDispatch(message) {
    if (message is String) {
      onReadGreeting(message);
      return;
    }
    switch ((message as BaseMessage).type) {
      case MessageType.response:
        onReadResponse(Response(message));
        break;
      case MessageType.event:
        onReadEvent(Event(message));
        break;
      default:
        break;
    }
  }
}

mixin MockConnector on Parser implements Connector {
  @override
  bool available() {
    return true;
  }

  @override
  Future<void> connect(String host, int port, {args}) {
    print('mock connect $host $port $args');
    return Future.value(null);
  }

  @override
  void send(Map<String, String> data) {
    print('send mock data $data');
    handleMessage(null);
  }
}
