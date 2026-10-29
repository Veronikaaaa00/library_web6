import 'package:dio/dio.dart';

import '../core/api_exceptions.dart';
import '../core/page_parser.dart';
import '../models/genre.dart';
import '../models/genre_query.dart';
import '../models/page_result.dart';
import 'genre_repository.dart';

class ApiGenreRepository implements GenreRepository {
  ApiGenreRepository(this._dio);

  final Dio _dio;

  @override
  Future<PageResult<Genre>> find(GenreQuery q) => guard(() async {
    final response = await _dio.get(
      '/genres',
      queryParameters: {
        if (q.search.trim().isNotEmpty) 'search': q.search.trim(),
        'sort': '${q.sortField},${q.sortAscending ? 'asc' : 'desc'}',
        'page': q.page,
        'size': q.size,
        if (q.includeDeleted) 'includeDeleted': true,
      },
    );
    return parsePage(response.data, Genre.fromJson, fallbackSize: q.size);
  });

  @override
  Future<List<Genre>> findAll({bool includeDeleted = false}) => guard(() async {
    final response = await _dio.get(
      '/genres',
      queryParameters: {
        'page': 1,
        'size': 100,
        if (includeDeleted) 'includeDeleted': true,
      },
    );
    return parsePage(response.data, Genre.fromJson, fallbackSize: 100).items;
  });

  @override
  Future<Genre?> findById(int id) => guard(() async {
    try {
      final response = await _dio.get('/genres/$id');
      return Genre.fromJson(Map<String, dynamic>.from(response.data as Map));
    } on NotFoundException {
      return null;
    }
  });

  @override
  Future<Genre> create(Genre genre) => guard(() async {
    final response = await _dio.post('/genres', data: genre.toApiBody());
    return Genre.fromJson(Map<String, dynamic>.from(response.data as Map));
  });

  @override
  Future<Genre> update(Genre genre) => guard(() async {
    final response = await _dio.put(
      '/genres/${genre.id}',
      data: genre.toApiBody(),
    );
    return Genre.fromJson(Map<String, dynamic>.from(response.data as Map));
  });

  @override
  Future<void> softDelete(int id) => guard(() => _dio.delete('/genres/$id'));

  @override
  Future<void> hardDelete(int id) =>
      guard(() => _dio.delete('/genres/$id', queryParameters: {'hard': true}));

  @override
  Future<void> restore(int id) => guard(() => _dio.post('/genres/$id/restore'));

  @override
  Future<int> deleteMany(List<int> ids) => guard(() async {
    final response = await _dio.post('/genres/bulk-delete', data: {'ids': ids});
    return ((response.data as Map)['deleted'] as num?)?.toInt() ?? 0;
  });
}
