import 'package:flutter/foundation.dart';

/// Глобальный статус сети: Dio и browser online/offline.
class NetworkStatus extends ChangeNotifier {
  var _online = true;
  var _message = '';

  bool get isOnline => _online;
  String get message => _message;

  void markOnline() {
    if (_online && _message.isEmpty) return;
    _online = true;
    _message = '';
    notifyListeners();
  }

  void markOffline([String message = 'Нет соединения с сервером']) {
    if (!_online && _message == message) return;
    _online = false;
    _message = message;
    notifyListeners();
  }
}
