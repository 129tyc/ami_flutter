# ami_flutter
Asterisk Manager Interface (AMI) Library for Flutter

---

## Features

- support Android,iOS,Desktop and Web.
- support listen events from stream.
- support async/await for ami events.
- easy to develop new actions or connection methods.

## Installation

just add dependency into `pubspec.yaml`:

```yaml
ami_flutter: ^0.0.1
```

## Usage

1. initialize `Manager` and connect(use `WebSocketConnector` at web platform):
 ```dart
final manager = Manager(connector: TCPSocketConnector());
await manager.connect('127.0.0.1', 5038);
```

2. login ami:
 ```dart
final loginResult = await manager.login('user', 'pass');
```

3. send actions and receive responses:
 ```dart
final statusResult = await manager.sendAction('Status');
final originateResult = await manager.sendAction(
      'Originate',
      id: 'actionId',
      args: {
        'Channel': 'sip/12345',
        'Exten': '1234',
        'Context': 'default',
        'Async': 'yes',
      },
    );
```

4. listen events:
 ```dart
manager.registerEvent('DongleSMSStatus').listen(
      (event) {
        print('receive event ${event.name} ${event.baseMsg.headers}');
      },
    );
```
 or read events like response:
 ```dart
final bootedEvent = await manager.readEvent('FullyBooted');
final events = await manager.readAllEventsUntil(
      'DongleDeviceEntry',
      'DongleShowDevicesComplete',
    );
```
 
 5. logoff and dispose resource:
 ```dart
await manager.logoff();
manager.dispose();
```

## Web Platform Need Know

AMI only support TCP socket. If you need use the library at web platform:
 - Install and configure  [amiws](https://github.com/staskobzar/amiws). 
 - Use `WebSocketConnector` to connect web socket proxy by `amiws`