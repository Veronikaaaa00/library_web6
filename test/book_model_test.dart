import 'package:flutter_test/flutter_test.dart';
import 'package:library_web/models/book.dart';

void main() {
  test('отсутствующие поля не приводят к исключению', () {
    final book = Book.fromJson({'id': 1});
    expect(book.title, '');
    expect(book.authorIds, isEmpty);
    expect(book.genreIds, isEmpty);
    expect(book.year, 0);
  });

  test('toApiBody отдаёт поля контракта', () {
    const book = Book(
      id: 7,
      title: 'Тень',
      isbn: '9785170000000',
      year: 2001,
      pages: 100,
      publisherId: 2,
      authorIds: [1],
      genreIds: [3],
      copiesTotal: 5,
      copiesAvailable: 4,
    );
    final body = book.toApiBody();
    expect(body['title'], 'Тень');
    expect(body['publisherId'], 2);
    expect(body.containsKey('id'), isFalse);
    expect(body.containsKey('copiesAvailable'), isFalse);
  });
}
