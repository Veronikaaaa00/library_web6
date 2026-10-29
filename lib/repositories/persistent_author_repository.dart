import 'package:shared_preferences/shared_preferences.dart';

import '../data/seed_data.dart';
import '../models/author.dart';
import '../models/author_query.dart';
import '../models/page_result.dart';
import '../storage/json_list_store.dart';
import 'author_repository.dart';

class PersistentAuthorRepository implements AuthorRepository {
  PersistentAuthorRepository(SharedPreferences prefs)
    : _store = JsonListStore<Author>(
        prefs: prefs,
        key: 'authors_v2',
        fromJson: Author.fromJson,
        toJson: (a) => a.toJson(),
        seed: seedAuthors,
      ) {
    _authors = _store.load();
    _nextId = _authors.fold<int>(0, (m, a) => a.id > m ? a.id : m) + 1;
  }

  final JsonListStore<Author> _store;
  late List<Author> _authors;
  late int _nextId;

  Future<void> _persist() => _store.save(_authors);

  @override
  Future<PageResult<Author>> find(AuthorQuery q) async {
    await Future.delayed(const Duration(milliseconds: 120));
    if (q.search.trim() == '__error__') {
      throw StateError('Сбой источника данных');
    }

    var rows = _authors.where((a) => q.includeDeleted || !a.isDeleted).toList();

    if (q.search.trim().isNotEmpty) {
      final needle = q.search.trim().toLowerCase();
      rows = rows
          .where(
            (a) =>
                a.lastName.toLowerCase().contains(needle) ||
                a.country.toLowerCase().contains(needle) ||
                a.firstName.toLowerCase().contains(needle),
          )
          .toList();
    }
    if (q.country != null && q.country!.trim().isNotEmpty) {
      final country = q.country!.trim().toLowerCase();
      rows = rows.where((a) => a.country.toLowerCase() == country).toList();
    }
    if (q.birthYearFrom != null) {
      rows = rows.where((a) => a.birthYear >= q.birthYearFrom!).toList();
    }
    if (q.birthYearTo != null) {
      rows = rows.where((a) => a.birthYear <= q.birthYearTo!).toList();
    }

    rows.sort((a, b) {
      final result = switch (q.sortField) {
        'birthYear' => a.birthYear.compareTo(b.birthYear),
        'country' => a.country.toLowerCase().compareTo(b.country.toLowerCase()),
        'firstName' => a.firstName.toLowerCase().compareTo(
          b.firstName.toLowerCase(),
        ),
        _ => a.lastName.toLowerCase().compareTo(b.lastName.toLowerCase()),
      };
      return q.sortAscending ? result : -result;
    });

    final total = rows.length;
    final from = (q.page - 1) * q.size;
    final to = (from + q.size) > total ? total : (from + q.size);
    final items = from >= total ? <Author>[] : rows.sublist(from, to);
    return PageResult(items: items, page: q.page, size: q.size, total: total);
  }

  @override
  Future<List<Author>> findAll({bool includeDeleted = false}) async {
    return _authors.where((a) => includeDeleted || !a.isDeleted).toList();
  }

  @override
  Future<Author?> findById(int id) async {
    for (final author in _authors) {
      if (author.id == id) return author;
    }
    return null;
  }

  @override
  Future<Author> create(Author author) async {
    final created = Author(
      id: _nextId++,
      firstName: author.firstName,
      lastName: author.lastName,
      country: author.country,
      birthYear: author.birthYear,
      bio: author.bio,
    );
    _authors.add(created);
    await _persist();
    return created;
  }

  @override
  Future<Author> update(Author author) async {
    final i = _authors.indexWhere((a) => a.id == author.id);
    if (i == -1) throw StateError('Автор ${author.id} не найден');
    _authors[i] = author;
    await _persist();
    return author;
  }

  @override
  Future<void> softDelete(int id) async {
    final i = _authors.indexWhere((a) => a.id == id);
    if (i == -1) throw StateError('Автор $id не найден');
    _authors[i] = _authors[i].copyWith(deletedAt: DateTime.now());
    await _persist();
  }

  @override
  Future<void> hardDelete(int id) async {
    _authors.removeWhere((a) => a.id == id);
    await _persist();
  }

  @override
  Future<void> restore(int id) async {
    final i = _authors.indexWhere((a) => a.id == id);
    if (i == -1) throw StateError('Автор $id не найден');
    _authors[i] = _authors[i].copyWith(clearDeletedAt: true);
    await _persist();
  }

  @override
  Future<int> deleteMany(List<int> ids) async {
    var count = 0;
    for (final id in ids) {
      final i = _authors.indexWhere((a) => a.id == id && !a.isDeleted);
      if (i != -1) {
        _authors[i] = _authors[i].copyWith(deletedAt: DateTime.now());
        count++;
      }
    }
    await _persist();
    return count;
  }
}
