import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../state/network_status.dart';
import 'api_exceptions.dart';
import 'auth_token_store.dart';
import 'config.dart';

typedef TokenRefresher = Future<void> Function();
typedef LogoutCallback = Future<void> Function();

Dio buildDio({
  AuthTokenStore? tokenStore,
  TokenRefresher? onRefresh,
  LogoutCallback? onLogout,
  NetworkStatus? network,
}) {
  final dio = Dio(
    BaseOptions(
      baseUrl: apiBaseUrl,
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 15),
      headers: {'Content-Type': 'application/json'},
      validateStatus: (status) => status != null && status < 500,
    ),
  );

  dio.interceptors.add(
    InterceptorsWrapper(
      onRequest: (options, handler) {
        final token = tokenStore?.accessToken;
        if (token != null && token.isNotEmpty) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        if (kDebugMode) {
          debugPrint('[API] → ${options.method} ${options.uri}');
        }
        return handler.next(options);
      },
      onResponse: (response, handler) {
        final status = response.statusCode ?? 0;
        network?.markOnline();
        if (kDebugMode) {
          debugPrint(
            '[API] ← ${response.requestOptions.method} '
            '${response.requestOptions.uri} → $status',
          );
        }
        if (status >= 400) {
          return handler.reject(
            DioException(
              requestOptions: response.requestOptions,
              response: response,
              type: DioExceptionType.badResponse,
              error: mapHttpError(status, response.data),
            ),
            true,
          );
        }
        return handler.next(response);
      },
      onError: (error, handler) {
        final isNetwork =
            error.type == DioExceptionType.connectionError ||
            error.type == DioExceptionType.connectionTimeout ||
            error.type == DioExceptionType.receiveTimeout ||
            error.type == DioExceptionType.sendTimeout ||
            (error.type == DioExceptionType.unknown && error.response == null);
        if (isNetwork) {
          network?.markOffline(
            'Нет соединения с сервером. Проверьте сеть и нажмите «Повторить».',
          );
        }
        if (kDebugMode) {
          debugPrint('[API] сбой ${error.requestOptions.uri}: ${error.type}');
        }
        return handler.next(error);
      },
    ),
  );

  // 401 → refresh → повтор (не для /auth/).
  dio.interceptors.add(
    InterceptorsWrapper(
      onError: (error, handler) async {
        final status = error.response?.statusCode;
        final path = error.requestOptions.path;
        final alreadyRetried =
            error.requestOptions.extra['authRetried'] == true;
        if (status != 401 ||
            onRefresh == null ||
            alreadyRetried ||
            path.contains('/auth/')) {
          return handler.next(error);
        }
        try {
          await onRefresh();
          final opts = error.requestOptions;
          opts.headers['Authorization'] =
              'Bearer ${tokenStore?.accessToken ?? ''}';
          opts.extra = {...opts.extra, 'authRetried': true};
          final response = await dio.fetch(opts);
          return handler.resolve(response);
        } catch (_) {
          if (onLogout != null) await onLogout();
          return handler.next(error);
        }
      },
    ),
  );

  // Автоповтор только для GET (чтение), до 3 попыток.
  dio.interceptors.add(
    InterceptorsWrapper(
      onError: (error, handler) async {
        final req = error.requestOptions;
        final method = req.method.toUpperCase();
        if (method != 'GET') {
          return handler.next(error);
        }
        if (error.response?.statusCode == 401) {
          return handler.next(error);
        }
        final attempt = (req.extra['retryAttempt'] as int?) ?? 0;
        final isNetwork =
            error.type == DioExceptionType.connectionError ||
            error.type == DioExceptionType.connectionTimeout ||
            error.type == DioExceptionType.receiveTimeout ||
            error.type == DioExceptionType.sendTimeout;
        if (!isNetwork || attempt >= 2) {
          return handler.next(error);
        }
        final next = attempt + 1;
        await Future.delayed(Duration(milliseconds: 300 * next));
        final opts = req.copyWith(extra: {...req.extra, 'retryAttempt': next});
        try {
          final response = await dio.fetch(opts);
          return handler.resolve(response);
        } on DioException catch (e) {
          return handler.next(e);
        }
      },
    ),
  );

  return dio;
}
