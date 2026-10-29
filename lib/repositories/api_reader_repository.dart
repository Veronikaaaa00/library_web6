import 'package:dio/dio.dart';

import '../core/api_exceptions.dart';
import '../core/page_parser.dart';
import '../models/page_result.dart';
import '../models/reader.dart';
import '../models/reader_query.dart';
import 'reader_repository.dart';

class ApiReaderRepository implements ReaderRepository {
  ApiReaderRepository(this._dio);

  final Dio _dio;

  @override
  Future<PageResult<Reader>> find(ReaderQuery q) => guard(() async {
    final response = await _dio.get(
      '/readers',
      queryParameters: {
        if (q.search.trim().isNotEmpty) 'search': q.search.trim(),
        'sort': '${q.sortField},${q.sortAscending ? 'asc' : 'desc'}',
        'page': q.page,
        'size': q.size,
        if (q.includeDeleted) 'includeDeleted': true,
      },
    );
    return parsePage(response.data, Reader.fromJson, fallbackSize: q.size);
  });

  @override
  Future<List<Reader>> findAll({bool includeDeleted = false}) => guard(
    () async {
      final response = await _dio.get(
        '/readers',
        queryParameters: {
          'page': 1,
          'size': 100,
          if (includeDeleted) 'includeDeleted': true,
        },
      );
      return parsePage(response.data, Reader.fromJson, fallbackSize: 100).items;
    },
  );

  @override
  Future<Reader?> findById(int id) => guard(() async {
    try {
      final response = await _dio.get('/readers/$id');
      return Reader.fromJson(Map<String, dynamic>.from(response.data as Map));
    } on NotFoundException {
      return null;
    }
  });

  @override
  Future<Reader> create(Reader reader) => guard(() async {
    final response = await _dio.post('/readers', data: reader.toApiBody());
    return Reader.fromJson(Map<String, dynamic>.from(response.data as Map));
  });

  @override
  Future<Reader> update(Reader reader) => guard(() async {
    final response = await _dio.put(
      '/readers/${reader.id}',
      data: reader.toApiBody(),
    );
    return Reader.fromJson(Map<String, dynamic>.from(response.data as Map));
  });

  @override
  Future<void> softDelete(int id) => guard(() => _dio.delete('/readers/$id'));

  @override
  Future<void> hardDelete(int id) =>
      guard(() => _dio.delete('/readers/$id', queryParameters: {'hard': true}));

  @override
  Future<void> restore(int id) =>
      guard(() => _dio.post('/readers/$id/restore'));

  @override
  Future<int> deleteMany(List<int> ids) => guard(() async {
    final response = await _dio.post(
      '/readers/bulk-delete',
      data: {'ids': ids},
    );
    return ((response.data as Map)['deleted'] as num?)?.toInt() ?? 0;
  });

  @override
  Future<bool> isEmailTaken(String email, {int? excludeId}) => guard(() async {
    final page = await find(ReaderQuery(search: email.trim(), size: 20));
    final needle = email.trim().toLowerCase();
    return page.items.any(
      (r) => r.id != excludeId && r.email.trim().toLowerCase() == needle,
    );
  });
}
