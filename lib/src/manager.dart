import 'dart:async';
import 'dart:io';

import 'actions.dart';
import 'ami_io.dart';
import 'call_center.dart';

class Manager with LifeCycle, CallCenter, BaseActions {
  Completer<String> _title;
  Completer<String> _version;

  Future<String> get title => _title.future;

  Future<String> get version => _version.future;

  String _prefix;

  @override
  String get prefix => _prefix;

  Manager({AMIConnector connector, String prefix}) {
    _title = Completer<String>();
    _version = Completer<String>();
    this.connector = connector ?? TCPSocketConnector();
    _prefix = prefix ?? Platform.localHostname;
    init();
  }

  @override
  void dispose() {
    if (!_title.isCompleted) _title.complete();
    _title = Completer<String>();
    if (!_version.isCompleted) _version.complete();
    _version = Completer<String>();
    super.dispose();
  }

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
  }
}
