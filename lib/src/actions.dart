import 'call_center.dart';
import 'structure.dart';

mixin BaseActions on CallCenter {
  Future<Response> login(String name, String pass) {
    return sendAction('Login', args: {'Username': name, 'Secret': pass});
  }

  Future<Response> logoff() {
    return sendAction('Logoff');
  }
}
