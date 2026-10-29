import 'package:shared_preferences/shared_preferences.dart';

import '../data/seed_data.dart';
import '../models/book.dart';
import '../models/book_query.dart';
import '../models/page_result.dart';
import '../storage/json_list_store.dart';
import 'book_repository.dart';

class PersistentBookRepository implements BookRepository {
  PersistentBookRepository(SharedPreferences prefs)
    : _store = JsonListStore<Book>(
        prefs: prefs,
        key: 'books_v2',
        fromJson: Book.fromJson,
        toJson: (b) => b.toJson(),
        seed: seedBooks,
      ) {
    _books = _store.load();
    _nextId = _books.fold<int>(0, (m, b) => b.id > m ? b.id : m) + 1;
  }

  final JsonListStore<Book> _store;
  late List<Book> _books;
  late int _nextId;

  Future<void> _persist() => _store.save(_books);

  String _normIsbn(String isbn) =>
      isbn.replaceAll(RegExp(r'[\s-]'), '').toLowerCase();

  @override
  Future<PageResult<Book>> find(BookQuery q) async {
    await Future.delayed(const Duration(milliseconds: 120));
    if (q.search.trim() == '__error__') {
      throw StateError('Сбой источника данных');
    }

    var rows = _books.where((b) => q.includeDeleted || !b.isDeleted).toList();

    if (q.search.trim().isNotEmpty) {
      final needle = q.search.trim().toLowerCase();
      rows = rows
          .where(
            (b) =>
                b.title.toLowerCase().contains(needle) ||
                b.isbn.toLowerCase().contains(needle),
          )
          .toList();
    }
    if (q.genreId != null) {
      rows = rows.where((b) => b.genreIds.contains(q.genreId)).toList();
    }
    if (q.publisherId != null) {
      rows = rows.where((b) => b.publisherId == q.publisherId).toList();
    }
    if (q.yearFrom != null) {
      rows = rows.where((b) => b.year >= q.yearFrom!).toList();
    }
    if (q.yearTo != null) {
      rows = rows.where((b) => b.year <= q.yearTo!).toList();
    }

    rows.sort((a, b) {
      final result = switch (q.sortField) {
        'year' => a.year.compareTo(b.year),
        'pages' => a.pages.compareTo(b.pages),
        'isbn' => a.isbn.compareTo(b.isbn),
        _ => a.title.toLowerCase().compareTo(b.title.toLowerCase()),
      };
      return q.sortAscending ? result : -result;
    });

    final total = rows.length;
    final from = (q.page - 1) * q.size;
    final to = (from + q.size) > total ? total : (from + q.size);
    final items = from >= total ? <Book>[] : rows.sublist(from, to);
    return PageResult(items: items, page: q.page, size: q.size, total: total);
  }

  @override
  Future<List<Book>> findAll({bool includeDeleted = false}) async {
    return _books.where((b) => includeDeleted || !b.isDeleted).toList();
  }

  @override
  Future<Book?> findById(int id) async {
    for (final book in _books) {
      if (book.id == id) return book;
    }
    return null;
  }

  @override
  Future<Book> create(Book book) async {
    final created = Book(
      id: _nextId++,
      title: book.title,
      isbn: book.isbn,
      year: book.year,
      pages: book.pages,
      publisherId: book.publisherId,
      authorIds: List<int>.from(book.authorIds),
      genreIds: List<int>.from(book.genreIds),
      copiesTotal: book.copiesTotal,
      copiesAvailable: book.copiesAvailable,
    );
    _books.add(created);
    await _persist();
    return created;
  }

  @override
  Future<Book> update(Book book) async {
    final i = _books.indexWhere((b) => b.id == book.id);
    if (i == -1) throw StateError('Книга ${book.id} не найдена');
    _books[i] = book;
    await _persist();
    return book;
  }

  @override
  Future<void> softDelete(int id) async {
    final i = _books.indexWhere((b) => b.id == id);
    if (i == -1) throw StateError('Книга $id не найдена');
    _books[i] = _books[i].copyWith(deletedAt: DateTime.now());
    await _persist();
  }

  @override
  Future<void> hardDelete(int id) async {
    _books.removeWhere((b) => b.id == id);
    await _persist();
  }

  @override
  Future<void> restore(int id) async {
    final i = _books.indexWhere((b) => b.id == id);
    if (i == -1) throw StateError('Книга $id не найдена');
    _books[i] = _books[i].copyWith(clearDeletedAt: true);
    await _persist();
  }

  @override
  Future<int> deleteMany(List<int> ids) async {
    var count = 0;
    for (final id in ids) {
      final i = _books.indexWhere((b) => b.id == id && !b.isDeleted);
      if (i != -1) {
        _books[i] = _books[i].copyWith(deletedAt: DateTime.now());
        count++;
      }
    }
    await _persist();
    return count;
  }

  @override
  Future<bool> isIsbnTaken(String isbn, {int? excludeId}) async {
    final needle = _normIsbn(isbn);
    return _books.any(
      (b) => !b.isDeleted && b.id != excludeId && _normIsbn(b.isbn) == needle,
    );
  }

  @override
  Future<int> countByPublisher(int publisherId) async {
    return _books
        .where((b) => !b.isDeleted && b.publisherId == publisherId)
        .length;
  }

  @override
  Future<int> countByAuthor(int authorId) async {
    return _books
        .where((b) => !b.isDeleted && b.authorIds.contains(authorId))
        .length;
  }

  @override
  Future<int> countByGenre(int genreId) async {
    return _books
        .where((b) => !b.isDeleted && b.genreIds.contains(genreId))
        .length;
  }
}
