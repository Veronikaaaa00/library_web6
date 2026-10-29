import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../core/api_exceptions.dart';
import '../core/auth_token_store.dart';
import '../models/app_user.dart';
import '../models/role.dart';
import '../repositories/auth_repository.dart';

class AuthNotifier extends ChangeNotifier {
  AuthNotifier(this._prefs, this._api, this._tokens);

  static const _kAccess = 'auth_access_token';
  static const _kRefresh = 'auth_refresh_token';
  static const _kSessionStarted = 'auth_session_started';
  static const _kLastActivity = 'auth_last_activity';

  /// Общая длительность сессии (независимо от активности).
  static const sessionMaxDuration = Duration(hours: 8);

  /// Выход по неактивности.
  static const inactivityTimeout = Duration(minutes: 3);

  /// Предупреждение до выхода по неактивности.
  static const inactivityWarning = Duration(seconds: 30);

  final SharedPreferences _prefs;
  final AuthRepository _api;
  final AuthTokenStore _tokens;

  AppUser? _user;
  String? _accessToken;
  String? _refreshToken;
  var _refreshing = false;
  DateTime? _sessionStartedAt;

  AppUser? get user => _user;
  String? get accessToken => _accessToken;
  bool get isAuthenticated => _user != null;
  Role? get role => _user?.role;
  DateTime? get sessionStartedAt => _sessionStartedAt;

  bool has(Role minimum) => _user != null && _user!.role.atLeast(minimum);

  Future<void> restore() async {
    final access = _prefs.getString(_kAccess);
    final refresh = _prefs.getString(_kRefresh);
    final startedRaw = _prefs.getString(_kSessionStarted);
    if (startedRaw != null) {
      _sessionStartedAt = DateTime.tryParse(startedRaw);
    }
    if (access == null) return;

    if (_sessionExpiredByMaxDuration()) {
      await logout(silent: true);
      return;
    }

    _accessToken = access;
    _refreshToken = refresh;
    _tokens.setToken(access);

    try {
      _user = await _api.me();
    } on UnauthorizedException {
      if (refresh != null) {
        try {
          await refreshTokens();
        } catch (_) {
          await logout(silent: true);
        }
      } else {
        await logout(silent: true);
      }
    } catch (_) {
      // Сервер недоступен — сессию оставляем, покажем ошибку позже.
    }
    notifyListeners();
  }

  Future<void> login(String username, String password) async {
    final result = await _api.login(username: username, password: password);
    await _applySession(result);
  }

  Future<void> register({
    required String username,
    required String password,
    required String email,
    required String fullName,
  }) async {
    await _api.register(
      username: username,
      password: password,
      email: email,
      fullName: fullName,
    );
    await login(username, password);
  }

  Future<void> refreshTokens() async {
    final refresh = _refreshToken ?? _prefs.getString(_kRefresh);
    if (refresh == null || refresh.isEmpty) {
      throw const UnauthorizedException('Нет токена обновления.');
    }
    if (_refreshing) return;
    _refreshing = true;
    try {
      final result = await _api.refresh(refresh);
      await _applySession(result, keepSessionStart: true);
    } finally {
      _refreshing = false;
    }
  }

  Future<void> logout({bool silent = false}) async {
    final refresh = _refreshToken;
    _user = null;
    _accessToken = null;
    _refreshToken = null;
    _sessionStartedAt = null;
    _tokens.clear();
    await _prefs.remove(_kAccess);
    await _prefs.remove(_kRefresh);
    await _prefs.remove(_kSessionStarted);
    await _prefs.remove(_kLastActivity);
    if (refresh != null) {
      try {
        await _api.logoutRemote(refresh);
      } catch (_) {}
    }
    if (!silent) notifyListeners();
    if (silent) notifyListeners();
  }

  Future<void> markActivity() async {
    await _prefs.setString(_kLastActivity, DateTime.now().toIso8601String());
  }

  DateTime? lastActivityAt() {
    final raw = _prefs.getString(_kLastActivity);
    return raw == null ? null : DateTime.tryParse(raw);
  }

  bool _sessionExpiredByMaxDuration() {
    final started = _sessionStartedAt;
    if (started == null) return false;
    return DateTime.now().difference(started) >= sessionMaxDuration;
  }

  bool get isSessionOverMaxDuration => _sessionExpiredByMaxDuration();

  Future<void> _applySession(
    AuthTokens result, {
    bool keepSessionStart = false,
  }) async {
    _accessToken = result.accessToken;
    _refreshToken = result.refreshToken;
    _user = result.user;
    _tokens.setToken(result.accessToken);
    await _prefs.setString(_kAccess, result.accessToken);
    await _prefs.setString(_kRefresh, result.refreshToken);
    if (!keepSessionStart || _sessionStartedAt == null) {
      _sessionStartedAt = DateTime.now();
      await _prefs.setString(
        _kSessionStarted,
        _sessionStartedAt!.toIso8601String(),
      );
    }
    await markActivity();
    notifyListeners();
  }
}
