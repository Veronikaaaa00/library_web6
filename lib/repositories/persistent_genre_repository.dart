import 'package:shared_preferences/shared_preferences.dart';

import '../data/seed_data.dart';
import '../models/genre.dart';
import '../models/genre_query.dart';
import '../models/page_result.dart';
import '../storage/json_list_store.dart';
import 'book_repository.dart';
import 'genre_repository.dart';
import 'related_records_exception.dart';

class PersistentGenreRepository implements GenreRepository {
  PersistentGenreRepository(SharedPreferences prefs, this._books)
    : _store = JsonListStore<Genre>(
        prefs: prefs,
        key: 'genres_v2',
        fromJson: Genre.fromJson,
        toJson: (g) => g.toJson(),
        seed: seedGenres,
      ) {
    _genres = _store.load();
    _nextId = _genres.fold<int>(0, (m, g) => g.id > m ? g.id : m) + 1;
  }

  final JsonListStore<Genre> _store;
  final BookRepository _books;
  late List<Genre> _genres;
  late int _nextId;

  Future<void> _persist() => _store.save(_genres);

  @override
  Future<PageResult<Genre>> find(GenreQuery q) async {
    await Future.delayed(const Duration(milliseconds: 80));
    var rows = _genres.where((g) => q.includeDeleted || !g.isDeleted).toList();
    if (q.search.trim().isNotEmpty) {
      final needle = q.search.trim().toLowerCase();
      rows = rows.where((g) => g.name.toLowerCase().contains(needle)).toList();
    }
    rows.sort((a, b) {
      final r = a.name.toLowerCase().compareTo(b.name.toLowerCase());
      return q.sortAscending ? r : -r;
    });
    final total = rows.length;
    final from = (q.page - 1) * q.size;
    final to = (from + q.size) > total ? total : (from + q.size);
    final items = from >= total ? <Genre>[] : rows.sublist(from, to);
    return PageResult(items: items, page: q.page, size: q.size, total: total);
  }

  @override
  Future<List<Genre>> findAll({bool includeDeleted = false}) async {
    return _genres.where((g) => includeDeleted || !g.isDeleted).toList();
  }

  @override
  Future<Genre?> findById(int id) async {
    for (final g in _genres) {
      if (g.id == id) return g;
    }
    return null;
  }

  @override
  Future<Genre> create(Genre genre) async {
    final created = Genre(id: _nextId++, name: genre.name);
    _genres.add(created);
    await _persist();
    return created;
  }

  @override
  Future<Genre> update(Genre genre) async {
    final i = _genres.indexWhere((g) => g.id == genre.id);
    if (i == -1) throw StateError('Жанр ${genre.id} не найден');
    _genres[i] = genre;
    await _persist();
    return genre;
  }

  Future<void> _ensureNoBooks(int id) async {
    final count = await _books.countByGenre(id);
    if (count > 0) {
      throw RelatedRecordsException(
        count,
        message: 'Нельзя удалить жанр: на него ссылаются книги ($count).',
      );
    }
  }

  @override
  Future<void> softDelete(int id) async {
    await _ensureNoBooks(id);
    final i = _genres.indexWhere((g) => g.id == id);
    if (i == -1) throw StateError('Жанр $id не найден');
    _genres[i] = _genres[i].copyWith(deletedAt: DateTime.now());
    await _persist();
  }

  @override
  Future<void> hardDelete(int id) async {
    await _ensureNoBooks(id);
    _genres.removeWhere((g) => g.id == id);
    await _persist();
  }

  @override
  Future<void> restore(int id) async {
    final i = _genres.indexWhere((g) => g.id == id);
    if (i == -1) throw StateError('Жанр $id не найден');
    _genres[i] = _genres[i].copyWith(clearDeletedAt: true);
    await _persist();
  }

  @override
  Future<int> deleteMany(List<int> ids) async {
    var count = 0;
    for (final id in ids) {
      try {
        await softDelete(id);
        count++;
      } on RelatedRecordsException {
        // пропускаем связанные
      }
    }
    return count;
  }
}
