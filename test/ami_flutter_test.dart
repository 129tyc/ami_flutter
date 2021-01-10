import 'package:flutter_test/flutter_test.dart';

import 'package:ami_flutter/ami_flutter.dart';

void main() async {
  test('test web socket', () async {
    final manager = Manager(connector: WebSocketConnector());
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
    final manager = Manager(connector: TCPSocketConnector());
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
  });
}
