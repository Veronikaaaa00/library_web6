import 'package:dio/dio.dart';

import '../core/api_exceptions.dart';
import '../core/auth_token_store.dart';
import '../models/app_user.dart';

class AuthTokens {
  final String accessToken;
  final String refreshToken;
  final int expiresIn;
  final AppUser user;

  const AuthTokens({
    required this.accessToken,
    required this.refreshToken,
    required this.expiresIn,
    required this.user,
  });

  factory AuthTokens.fromJson(Map<String, dynamic> json) => AuthTokens(
    accessToken: json['accessToken'] as String,
    refreshToken: json['refreshToken'] as String,
    expiresIn: (json['expiresIn'] as num?)?.toInt() ?? 900,
    user: AppUser.fromJson(Map<String, dynamic>.from(json['user'] as Map)),
  );
}

class AuthRepository {
  AuthRepository(this._dio, this._tokens);

  final Dio _dio;
  final AuthTokenStore _tokens;

  Future<AuthTokens> login({
    required String username,
    required String password,
  }) => guard(() async {
    final response = await _dio.post(
      '/auth/login',
      data: {'username': username, 'password': password},
    );
    final result = AuthTokens.fromJson(
      Map<String, dynamic>.from(response.data as Map),
    );
    _tokens.setToken(result.accessToken);
    return result;
  });

  Future<AppUser> register({
    required String username,
    required String password,
    required String email,
    required String fullName,
  }) => guard(() async {
    final response = await _dio.post(
      '/auth/register',
      data: {
        'username': username,
        'password': password,
        'email': email,
        'fullName': fullName,
      },
    );
    return AppUser.fromJson(Map<String, dynamic>.from(response.data as Map));
  });

  Future<AppUser> me() => guard(() async {
    final response = await _dio.get('/auth/me');
    return AppUser.fromJson(Map<String, dynamic>.from(response.data as Map));
  });

  Future<AuthTokens> refresh(String refreshToken) => guard(() async {
    final response = await _dio.post(
      '/auth/refresh',
      data: {'refreshToken': refreshToken},
    );
    final result = AuthTokens.fromJson(
      Map<String, dynamic>.from(response.data as Map),
    );
    _tokens.setToken(result.accessToken);
    return result;
  });

  Future<void> logoutRemote(String? refreshToken) => guard(() async {
    await _dio.post(
      '/auth/logout',
      data: {if (refreshToken != null) 'refreshToken': refreshToken},
    );
  });

  void clearLocalToken() => _tokens.clear();
}
