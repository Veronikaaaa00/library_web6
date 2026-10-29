import 'package:dio/dio.dart';

import '../core/api_exceptions.dart';
import '../core/page_parser.dart';
import '../models/author.dart';
import '../models/author_query.dart';
import '../models/page_result.dart';
import 'author_repository.dart';

class ApiAuthorRepository implements AuthorRepository {
  ApiAuthorRepository(this._dio);

  final Dio _dio;
  CancelToken? _listToken;

  String _apiSortField(String field) {
    // В UI — lastName/firstName; в API — fullName.
    if (field == 'lastName' || field == 'firstName') return 'fullName';
    return field;
  }

  @override
  Future<PageResult<Author>> find(AuthorQuery q) => guard(() async {
    _listToken?.cancel('stale');
    _listToken = CancelToken();
    final searchParts = <String>[
      if (q.search.trim().isNotEmpty) q.search.trim(),
      if (q.country != null && q.country!.trim().isNotEmpty) q.country!.trim(),
    ];
    final response = await _dio.get(
      '/authors',
      queryParameters: {
        if (searchParts.isNotEmpty) 'search': searchParts.join(' '),
        'sort':
            '${_apiSortField(q.sortField)},${q.sortAscending ? 'asc' : 'desc'}',
        'page': q.page,
        'size': q.size,
        if (q.includeDeleted) 'includeDeleted': true,
      },
      cancelToken: _listToken,
    );
    return parsePage(response.data, Author.fromJson, fallbackSize: q.size);
  });

  @override
  Future<List<Author>> findAll({bool includeDeleted = false}) => guard(
    () async {
      final response = await _dio.get(
        '/authors',
        queryParameters: {
          'page': 1,
          'size': 100,
          if (includeDeleted) 'includeDeleted': true,
        },
      );
      return parsePage(response.data, Author.fromJson, fallbackSize: 100).items;
    },
  );

  @override
  Future<Author?> findById(int id) => guard(() async {
    try {
      final response = await _dio.get('/authors/$id');
      return Author.fromJson(Map<String, dynamic>.from(response.data as Map));
    } on NotFoundException {
      return null;
    }
  });

  @override
  Future<Author> create(Author author) => guard(() async {
    final response = await _dio.post('/authors', data: author.toApiBody());
    return Author.fromJson(Map<String, dynamic>.from(response.data as Map));
  });

  @override
  Future<Author> update(Author author) => guard(() async {
    final response = await _dio.put(
      '/authors/${author.id}',
      data: author.toApiBody(),
    );
    return Author.fromJson(Map<String, dynamic>.from(response.data as Map));
  });

  @override
  Future<void> softDelete(int id) => guard(() => _dio.delete('/authors/$id'));

  @override
  Future<void> hardDelete(int id) =>
      guard(() => _dio.delete('/authors/$id', queryParameters: {'hard': true}));

  @override
  Future<void> restore(int id) =>
      guard(() => _dio.post('/authors/$id/restore'));

  @override
  Future<int> deleteMany(List<int> ids) => guard(() async {
    final response = await _dio.post(
      '/authors/bulk-delete',
      data: {'ids': ids},
    );
    return ((response.data as Map)['deleted'] as num?)?.toInt() ?? 0;
  });
}
