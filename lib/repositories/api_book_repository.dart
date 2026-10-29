import 'package:dio/dio.dart';

import '../core/api_exceptions.dart';
import '../core/page_parser.dart';
import '../models/book.dart';
import '../models/book_query.dart';
import '../models/page_result.dart';
import 'book_repository.dart';

class ApiBookRepository implements BookRepository {
  ApiBookRepository(this._dio);

  final Dio _dio;
  CancelToken? _listToken;

  @override
  Future<PageResult<Book>> find(BookQuery q) => guard(() async {
    _listToken?.cancel('stale');
    _listToken = CancelToken();
    final response = await _dio.get(
      '/books',
      queryParameters: {
        if (q.search.trim().isNotEmpty) 'search': q.search.trim(),
        if (q.genreId != null) 'genreId': q.genreId,
        if (q.publisherId != null) 'publisherId': q.publisherId,
        if (q.yearFrom != null) 'yearFrom': q.yearFrom,
        if (q.yearTo != null) 'yearTo': q.yearTo,
        'sort': '${q.sortField},${q.sortAscending ? 'asc' : 'desc'}',
        'page': q.page,
        'size': q.size,
        if (q.includeDeleted) 'includeDeleted': true,
      },
      cancelToken: _listToken,
    );
    return parsePage(response.data, Book.fromJson, fallbackSize: q.size);
  });

  @override
  Future<List<Book>> findAll({bool includeDeleted = false}) => guard(() async {
    final response = await _dio.get(
      '/books',
      queryParameters: {
        'page': 1,
        'size': 100,
        if (includeDeleted) 'includeDeleted': true,
      },
    );
    return parsePage(response.data, Book.fromJson, fallbackSize: 100).items;
  });

  @override
  Future<Book?> findById(int id) => guard(() async {
    try {
      final response = await _dio.get('/books/$id');
      return Book.fromJson(Map<String, dynamic>.from(response.data as Map));
    } on NotFoundException {
      return null;
    }
  });

  @override
  Future<Book> create(Book book) => guard(() async {
    final response = await _dio.post('/books', data: book.toApiBody());
    return Book.fromJson(Map<String, dynamic>.from(response.data as Map));
  });

  @override
  Future<Book> update(Book book) => guard(() async {
    final response = await _dio.put(
      '/books/${book.id}',
      data: book.toApiBody(),
    );
    return Book.fromJson(Map<String, dynamic>.from(response.data as Map));
  });

  @override
  Future<void> softDelete(int id) => guard(() => _dio.delete('/books/$id'));

  @override
  Future<void> hardDelete(int id) =>
      guard(() => _dio.delete('/books/$id', queryParameters: {'hard': true}));

  @override
  Future<void> restore(int id) => guard(() => _dio.post('/books/$id/restore'));

  @override
  Future<int> deleteMany(List<int> ids) => guard(() async {
    final response = await _dio.post('/books/bulk-delete', data: {'ids': ids});
    final data = response.data as Map<String, dynamic>;
    return (data['deleted'] as num?)?.toInt() ?? 0;
  });

  @override
  Future<bool> isIsbnTaken(String isbn, {int? excludeId}) => guard(() async {
    final page = await find(
      BookQuery(search: isbn.replaceAll(RegExp(r'[\s-]'), ''), size: 20),
    );
    final needle = isbn.replaceAll(RegExp(r'[\s-]'), '').toLowerCase();
    return page.items.any(
      (b) =>
          b.id != excludeId &&
          b.isbn.replaceAll(RegExp(r'[\s-]'), '').toLowerCase() == needle,
    );
  });

  @override
  Future<int> countByPublisher(int publisherId) => guard(() async {
    final response = await _dio.get(
      '/books',
      queryParameters: {'publisherId': publisherId, 'page': 1, 'size': 1},
    );
    return parsePage(response.data, Book.fromJson, fallbackSize: 1).total;
  });

  @override
  Future<int> countByAuthor(int authorId) => guard(() async {
    final response = await _dio.get(
      '/books',
      queryParameters: {'authorId': authorId, 'page': 1, 'size': 1},
    );
    return parsePage(response.data, Book.fromJson, fallbackSize: 1).total;
  });

  @override
  Future<int> countByGenre(int genreId) => guard(() async {
    final response = await _dio.get(
      '/books',
      queryParameters: {'genreId': genreId, 'page': 1, 'size': 1},
    );
    return parsePage(response.data, Book.fromJson, fallbackSize: 1).total;
  });
}
