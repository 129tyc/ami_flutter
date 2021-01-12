import 'dart:async';
import 'dart:io';

import 'actions.dart';
import 'base.dart';
import 'connectors.dart';
import 'dispatcher.dart';
import 'parsers.dart';

mixin Manager on LifeCycle, Reader, Sender {
  Completer<String> _title;
  Completer<String> _version;

  Future<String> get title => _title.future;

  Future<String> get version => _version.future;

  @override
  void onReadGreeting(String words) {
    final greetings = words.split('/');
    if (!_title.isCompleted) {
      _title.complete(greetings[0].trim());
    }
    if (!_version.isCompleted) {
      _version.complete(greetings[1].trim());
    }

    print('incoming greeting : $words');
    super.onReadGreeting(words);
  }

  @override
  void init() {
    _title = Completer<String>();
    _version = Completer<String>();
    prefix ??= Platform.localHostname;
    super.init();
  }

  @override
  void dispose() {
    if (!_title.isCompleted) _title.complete();
    _title = Completer<String>();
    if (!_version.isCompleted) _version.complete();
    _version = Completer<String>();
    super.dispose();
  }
}

abstract class BaseManager with LifeCycle, Reader, Parser, Connector, Dispatcher, Sender, Manager, BaseActions {}

class DefaultManager extends BaseManager with SocketMessageParser, TCPSocketConnector {}

class WebSocketManager extends BaseManager with WebSocketMessageParser, WebSocketConnector {}
