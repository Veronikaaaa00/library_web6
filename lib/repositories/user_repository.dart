import 'package:dio/dio.dart';

import '../core/api_exceptions.dart';
import '../core/page_parser.dart';
import '../models/app_user.dart';
import '../models/page_result.dart';
import '../models/role.dart';

class UserRepository {
  UserRepository(this._dio);

  final Dio _dio;

  Future<PageResult<AppUser>> find({int page = 1, int size = 50}) =>
      guard(() async {
        final response = await _dio.get(
          '/users',
          queryParameters: {'page': page, 'size': size, 'sort': 'username,asc'},
        );
        return parsePage(response.data, AppUser.fromJson, fallbackSize: size);
      });

  Future<AppUser> updateRole(int id, Role role) => guard(() async {
    final response = await _dio.patch(
      '/users/$id',
      data: {'role': role.apiValue},
    );
    return AppUser.fromJson(Map<String, dynamic>.from(response.data as Map));
  });

  Future<Map<String, int>> stats() => guard(() async {
    final response = await _dio.get('/stats');
    final data = Map<String, dynamic>.from(response.data as Map);
    return data.map((k, v) => MapEntry(k, (v as num).toInt()));
  });
}
