import 'base.dart';
import 'dispatcher.dart';
import 'structure.dart';

mixin BaseActions on Sender, Dispatcher {
  Future<Response> login(String name, String pass) {
    return sendAction('Login', args: {'Username': name, 'Secret': pass});
  }

  Future<Response> logoff() {
    return sendAction('Logoff');
  }
}
