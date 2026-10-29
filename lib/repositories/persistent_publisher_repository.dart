import 'package:shared_preferences/shared_preferences.dart';

import '../data/seed_data.dart';
import '../models/page_result.dart';
import '../models/publisher.dart';
import '../models/publisher_query.dart';
import '../storage/json_list_store.dart';
import 'book_repository.dart';
import 'publisher_repository.dart';
import 'related_records_exception.dart';

class PersistentPublisherRepository implements PublisherRepository {
  PersistentPublisherRepository(SharedPreferences prefs, this._books)
    : _store = JsonListStore<Publisher>(
        prefs: prefs,
        key: 'publishers_v2',
        fromJson: Publisher.fromJson,
        toJson: (p) => p.toJson(),
        seed: seedPublishers,
      ) {
    _publishers = _store.load();
    _nextId = _publishers.fold<int>(0, (m, p) => p.id > m ? p.id : m) + 1;
  }

  final JsonListStore<Publisher> _store;
  final BookRepository _books;
  late List<Publisher> _publishers;
  late int _nextId;

  Future<void> _persist() => _store.save(_publishers);

  @override
  Future<PageResult<Publisher>> find(PublisherQuery q) async {
    await Future.delayed(const Duration(milliseconds: 80));
    var rows = _publishers
        .where((p) => q.includeDeleted || !p.isDeleted)
        .toList();
    if (q.search.trim().isNotEmpty) {
      final needle = q.search.trim().toLowerCase();
      rows = rows
          .where(
            (p) =>
                p.name.toLowerCase().contains(needle) ||
                p.country.toLowerCase().contains(needle),
          )
          .toList();
    }
    if (q.country != null && q.country!.trim().isNotEmpty) {
      final c = q.country!.trim().toLowerCase();
      rows = rows.where((p) => p.country.toLowerCase() == c).toList();
    }
    rows.sort((a, b) {
      final result = switch (q.sortField) {
        'country' => a.country.toLowerCase().compareTo(b.country.toLowerCase()),
        _ => a.name.toLowerCase().compareTo(b.name.toLowerCase()),
      };
      return q.sortAscending ? result : -result;
    });
    final total = rows.length;
    final from = (q.page - 1) * q.size;
    final to = (from + q.size) > total ? total : (from + q.size);
    final items = from >= total ? <Publisher>[] : rows.sublist(from, to);
    return PageResult(items: items, page: q.page, size: q.size, total: total);
  }

  @override
  Future<List<Publisher>> findAll({bool includeDeleted = false}) async {
    return _publishers.where((p) => includeDeleted || !p.isDeleted).toList();
  }

  @override
  Future<Publisher?> findById(int id) async {
    for (final p in _publishers) {
      if (p.id == id) return p;
    }
    return null;
  }

  @override
  Future<Publisher> create(Publisher publisher) async {
    final created = Publisher(
      id: _nextId++,
      name: publisher.name,
      country: publisher.country,
    );
    _publishers.add(created);
    await _persist();
    return created;
  }

  @override
  Future<Publisher> update(Publisher publisher) async {
    final i = _publishers.indexWhere((p) => p.id == publisher.id);
    if (i == -1) throw StateError('Издательство ${publisher.id} не найдено');
    _publishers[i] = publisher;
    await _persist();
    return publisher;
  }

  Future<void> _ensureNoBooks(int id) async {
    final count = await _books.countByPublisher(id);
    if (count > 0) {
      throw RelatedRecordsException(
        count,
        message:
            'Нельзя удалить издательство: на него ссылаются книги ($count).',
      );
    }
  }

  @override
  Future<void> softDelete(int id) async {
    await _ensureNoBooks(id);
    final i = _publishers.indexWhere((p) => p.id == id);
    if (i == -1) throw StateError('Издательство $id не найдено');
    _publishers[i] = _publishers[i].copyWith(deletedAt: DateTime.now());
    await _persist();
  }

  @override
  Future<void> hardDelete(int id) async {
    await _ensureNoBooks(id);
    _publishers.removeWhere((p) => p.id == id);
    await _persist();
  }

  @override
  Future<void> restore(int id) async {
    final i = _publishers.indexWhere((p) => p.id == id);
    if (i == -1) throw StateError('Издательство $id не найдено');
    _publishers[i] = _publishers[i].copyWith(clearDeletedAt: true);
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
