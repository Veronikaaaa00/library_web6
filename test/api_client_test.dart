import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:library_web/core/api_exceptions.dart';
import 'package:library_web/core/page_parser.dart';
import 'package:library_web/models/book.dart';
import 'package:library_web/models/book_query.dart';
import 'package:library_web/repositories/api_book_repository.dart';

Dio _mockDio(Future<Response<dynamic>> Function(RequestOptions) handler) {
  final dio = Dio(
    BaseOptions(
      baseUrl: 'http://localhost/api',
      validateStatus: (s) => s != null && s < 500,
    ),
  );
  dio.interceptors.add(
    InterceptorsWrapper(
      onRequest: (options, sink) async {
        try {
          final response = await handler(options);
          if ((response.statusCode ?? 200) >= 400) {
            sink.reject(
              DioException(
                requestOptions: options,
                response: response,
                type: DioExceptionType.badResponse,
                error: mapHttpError(response.statusCode!, response.data),
              ),
            );
          } else {
            sink.resolve(response);
          }
        } catch (e) {
          sink.reject(DioException(requestOptions: options, error: e));
        }
      },
    ),
  );
  return dio;
}

void main() {
  test('mapHttpError: 422 → ValidationException с полями', () {
    final err = mapHttpError(422, {
      'message': 'Ошибка валидации',
      'errors': {'isbn': 'Книга с таким ISBN уже существует'},
    });
    expect(err, isA<ValidationException>());
    final v = err as ValidationException;
    expect(v.errors['isbn'], contains('ISBN'));
  });

  test('mapHttpError: 409 → ConflictException', () {
    final err = mapHttpError(409, {
      'message': 'Нет свободных экземпляров этой книги',
    });
    expect(err, isA<ConflictException>());
    expect(err.message, contains('свободных'));
  });

  test('mapHttpError: 401 / 404', () {
    expect(mapHttpError(401, null), isA<UnauthorizedException>());
    expect(mapHttpError(404, {'message': 'Нет'}), isA<NotFoundException>());
  });

  test('parsePage разбирает контрактный ответ', () {
    final page = parsePage(
      {
        'items': [
          {
            'id': 1,
            'title': 'Война и мир',
            'isbn': '978-5-17-090123-1',
            'year': 1869,
            'pages': 1225,
            'publisher': {'id': 1, 'name': 'АСТ'},
            'authors': [
              {'id': 1, 'fullName': 'Толстой Л. Н.'},
            ],
            'genres': [
              {'id': 1, 'name': 'Роман'},
            ],
            'copiesTotal': 5,
            'copiesAvailable': 3,
            'deletedAt': null,
          },
        ],
        'page': 1,
        'size': 10,
        'total': 1,
      },
      Book.fromJson,
      fallbackSize: 10,
    );
    expect(page.total, 1);
    expect(page.items.first.publisherId, 1);
    expect(page.items.first.authorIds, [1]);
    expect(page.items.first.genreIds, [1]);
    expect(page.items.first.publisherName, 'АСТ');
  });

  test('ApiBookRepository.find мапит GET /books', () async {
    final dio = _mockDio((options) async {
      expect(options.path, '/books');
      expect(options.queryParameters['search'], 'война');
      return Response(
        requestOptions: options,
        statusCode: 200,
        data: {
          'items': [
            {
              'id': 1,
              'title': 'Война и мир',
              'isbn': '9785170901231',
              'year': 1869,
              'pages': 100,
              'publisher': {'id': 2, 'name': 'Эксмо'},
              'authors': [],
              'genres': [],
              'copiesTotal': 1,
              'copiesAvailable': 1,
              'deletedAt': null,
            },
          ],
          'page': 1,
          'size': 10,
          'total': 1,
        },
      );
    });

    final repo = ApiBookRepository(dio);
    final page = await repo.find(const BookQuery(search: 'война'));
    expect(page.items.single.title, 'Война и мир');
    expect(page.items.single.publisherId, 2);
  });

  test('ApiBookRepository.create пробрасывает 422', () async {
    final dio = _mockDio((options) async {
      expect(options.method, 'POST');
      return Response(
        requestOptions: options,
        statusCode: 422,
        data: {
          'message': 'Ошибка валидации',
          'errors': {'title': 'Укажите название'},
        },
      );
    });

    final repo = ApiBookRepository(dio);
    expect(
      () => repo.create(
        const Book(
          id: 0,
          title: '',
          isbn: '9780000000001',
          year: 2020,
          pages: 10,
          publisherId: 1,
          authorIds: [1],
          genreIds: [1],
          copiesTotal: 1,
          copiesAvailable: 1,
        ),
      ),
      throwsA(
        isA<ValidationException>().having(
          (e) => e.errors['title'],
          'title',
          'Укажите название',
        ),
      ),
    );
  });
}
