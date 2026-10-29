import 'package:shared_preferences/shared_preferences.dart';

import '../data/seed_data.dart';
import '../models/page_result.dart';
import '../models/reader.dart';
import '../models/reader_query.dart';
import '../storage/json_list_store.dart';
import 'reader_repository.dart';

class PersistentReaderRepository implements ReaderRepository {
  PersistentReaderRepository(SharedPreferences prefs)
    : _store = JsonListStore<Reader>(
        prefs: prefs,
        key: 'readers_v2',
        fromJson: Reader.fromJson,
        toJson: (r) => r.toJson(),
        seed: seedReaders,
      ) {
    _readers = _store.load();
    _nextId = _readers.fold<int>(0, (m, r) => r.id > m ? r.id : m) + 1;
  }

  final JsonListStore<Reader> _store;
  late List<Reader> _readers;
  late int _nextId;

  Future<void> _persist() => _store.save(_readers);

  @override
  Future<PageResult<Reader>> find(ReaderQuery q) async {
    await Future.delayed(const Duration(milliseconds: 100));
    var rows = _readers.where((r) => q.includeDeleted || !r.isDeleted).toList();
    if (q.search.trim().isNotEmpty) {
      final needle = q.search.trim().toLowerCase();
      rows = rows
          .where(
            (r) =>
                r.lastName.toLowerCase().contains(needle) ||
                r.firstName.toLowerCase().contains(needle) ||
                r.email.toLowerCase().contains(needle) ||
                r.card.number.toLowerCase().contains(needle),
          )
          .toList();
    }
    if (q.cardActive != null) {
      rows = rows.where((r) => r.card.isActive == q.cardActive).toList();
    }
    rows.sort((a, b) {
      final result = switch (q.sortField) {
        'email' => a.email.toLowerCase().compareTo(b.email.toLowerCase()),
        'firstName' => a.firstName.toLowerCase().compareTo(
          b.firstName.toLowerCase(),
        ),
        'card' => a.card.number.compareTo(b.card.number),
        _ => a.lastName.toLowerCase().compareTo(b.lastName.toLowerCase()),
      };
      return q.sortAscending ? result : -result;
    });
    final total = rows.length;
    final from = (q.page - 1) * q.size;
    final to = (from + q.size) > total ? total : (from + q.size);
    final items = from >= total ? <Reader>[] : rows.sublist(from, to);
    return PageResult(items: items, page: q.page, size: q.size, total: total);
  }

  @override
  Future<List<Reader>> findAll({bool includeDeleted = false}) async {
    return _readers.where((r) => includeDeleted || !r.isDeleted).toList();
  }

  @override
  Future<Reader?> findById(int id) async {
    for (final r in _readers) {
      if (r.id == id) return r;
    }
    return null;
  }

  @override
  Future<Reader> create(Reader reader) async {
    final created = Reader(
      id: _nextId++,
      firstName: reader.firstName,
      lastName: reader.lastName,
      email: reader.email,
      phone: reader.phone,
      card: reader.card,
    );
    _readers.add(created);
    await _persist();
    return created;
  }

  @override
  Future<Reader> update(Reader reader) async {
    final i = _readers.indexWhere((r) => r.id == reader.id);
    if (i == -1) throw StateError('Читатель ${reader.id} не найден');
    _readers[i] = reader;
    await _persist();
    return reader;
  }

  @override
  Future<void> softDelete(int id) async {
    final i = _readers.indexWhere((r) => r.id == id);
    if (i == -1) throw StateError('Читатель $id не найден');
    _readers[i] = _readers[i].copyWith(deletedAt: DateTime.now());
    await _persist();
  }

  @override
  Future<void> hardDelete(int id) async {
    _readers.removeWhere((r) => r.id == id);
    await _persist();
  }

  @override
  Future<void> restore(int id) async {
    final i = _readers.indexWhere((r) => r.id == id);
    if (i == -1) throw StateError('Читатель $id не найден');
    _readers[i] = _readers[i].copyWith(clearDeletedAt: true);
    await _persist();
  }

  @override
  Future<int> deleteMany(List<int> ids) async {
    var count = 0;
    for (final id in ids) {
      final i = _readers.indexWhere((r) => r.id == id && !r.isDeleted);
      if (i != -1) {
        _readers[i] = _readers[i].copyWith(deletedAt: DateTime.now());
        count++;
      }
    }
    await _persist();
    return count;
  }

  @override
  Future<bool> isEmailTaken(String email, {int? excludeId}) async {
    final needle = email.trim().toLowerCase();
    return _readers.any(
      (r) =>
          !r.isDeleted &&
          r.id != excludeId &&
          r.email.trim().toLowerCase() == needle,
    );
  }
}
