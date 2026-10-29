import 'package:dio/dio.dart';

import '../core/api_exceptions.dart';
import '../core/page_parser.dart';
import '../models/page_result.dart';
import '../models/publisher.dart';
import '../models/publisher_query.dart';
import 'publisher_repository.dart';

class ApiPublisherRepository implements PublisherRepository {
  ApiPublisherRepository(this._dio);

  final Dio _dio;

  @override
  Future<PageResult<Publisher>> find(PublisherQuery q) => guard(() async {
    final searchParts = <String>[
      if (q.search.trim().isNotEmpty) q.search.trim(),
      if (q.country != null && q.country!.trim().isNotEmpty) q.country!.trim(),
    ];
    final sortField = q.sortField == 'country' ? 'city' : q.sortField;
    final response = await _dio.get(
      '/publishers',
      queryParameters: {
        if (searchParts.isNotEmpty) 'search': searchParts.join(' '),
        'sort': '$sortField,${q.sortAscending ? 'asc' : 'desc'}',
        'page': q.page,
        'size': q.size,
        if (q.includeDeleted) 'includeDeleted': true,
      },
    );
    return parsePage(response.data, Publisher.fromJson, fallbackSize: q.size);
  });

  @override
  Future<List<Publisher>> findAll({bool includeDeleted = false}) =>
      guard(() async {
        final response = await _dio.get(
          '/publishers',
          queryParameters: {
            'page': 1,
            'size': 100,
            if (includeDeleted) 'includeDeleted': true,
          },
        );
        return parsePage(
          response.data,
          Publisher.fromJson,
          fallbackSize: 100,
        ).items;
      });

  @override
  Future<Publisher?> findById(int id) => guard(() async {
    try {
      final response = await _dio.get('/publishers/$id');
      return Publisher.fromJson(
        Map<String, dynamic>.from(response.data as Map),
      );
    } on NotFoundException {
      return null;
    }
  });

  @override
  Future<Publisher> create(Publisher publisher) => guard(() async {
    final response = await _dio.post(
      '/publishers',
      data: publisher.toApiBody(),
    );
    return Publisher.fromJson(Map<String, dynamic>.from(response.data as Map));
  });

  @override
  Future<Publisher> update(Publisher publisher) => guard(() async {
    final response = await _dio.put(
      '/publishers/${publisher.id}',
      data: publisher.toApiBody(),
    );
    return Publisher.fromJson(Map<String, dynamic>.from(response.data as Map));
  });

  @override
  Future<void> softDelete(int id) =>
      guard(() => _dio.delete('/publishers/$id'));

  @override
  Future<void> hardDelete(int id) => guard(
    () => _dio.delete('/publishers/$id', queryParameters: {'hard': true}),
  );

  @override
  Future<void> restore(int id) =>
      guard(() => _dio.post('/publishers/$id/restore'));

  @override
  Future<int> deleteMany(List<int> ids) => guard(() async {
    final response = await _dio.post(
      '/publishers/bulk-delete',
      data: {'ids': ids},
    );
    return ((response.data as Map)['deleted'] as num?)?.toInt() ?? 0;
  });
}
