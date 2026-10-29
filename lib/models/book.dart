import '../utils/json_utils.dart';

class Book {
  final int id;
  final String title;
  final String isbn;
  final int year;
  final int pages;
  final int publisherId;
  final List<int> authorIds;
  final List<int> genreIds;
  final int copiesTotal;
  final int copiesAvailable;
  final DateTime? deletedAt;
  final String? publisherName;

  const Book({
    required this.id,
    required this.title,
    required this.isbn,
    required this.year,
    required this.pages,
    required this.publisherId,
    required this.authorIds,
    required this.genreIds,
    required this.copiesTotal,
    required this.copiesAvailable,
    this.deletedAt,
    this.publisherName,
  });

  bool get isDeleted => deletedAt != null;

  Book copyWith({
    String? title,
    String? isbn,
    int? year,
    int? pages,
    int? publisherId,
    List<int>? authorIds,
    List<int>? genreIds,
    int? copiesTotal,
    int? copiesAvailable,
    DateTime? deletedAt,
    bool clearDeletedAt = false,
    String? publisherName,
  }) {
    return Book(
      id: id,
      title: title ?? this.title,
      isbn: isbn ?? this.isbn,
      year: year ?? this.year,
      pages: pages ?? this.pages,
      publisherId: publisherId ?? this.publisherId,
      authorIds: authorIds ?? this.authorIds,
      genreIds: genreIds ?? this.genreIds,
      copiesTotal: copiesTotal ?? this.copiesTotal,
      copiesAvailable: copiesAvailable ?? this.copiesAvailable,
      deletedAt: clearDeletedAt ? null : (deletedAt ?? this.deletedAt),
      publisherName: publisherName ?? this.publisherName,
    );
  }

  /// Тело для POST/PUT по контракту API.
  Map<String, dynamic> toApiBody() => {
    'title': title,
    'isbn': isbn,
    'year': year,
    'pages': pages,
    'publisherId': publisherId,
    'authorIds': authorIds,
    'genreIds': genreIds,
    'copiesTotal': copiesTotal,
  };

  Map<String, dynamic> toJson() => {
    'id': id,
    ...toApiBody(),
    'copiesAvailable': copiesAvailable,
    'deletedAt': deletedAt?.toIso8601String(),
  };

  factory Book.fromJson(Map<String, dynamic> json) {
    // Ответ API: publisher / authors / genres — объекты.
    // Локальное хранилище / запись: publisherId / authorIds / genreIds.
    var publisherId = asInt(json['publisherId']);
    String? publisherName;
    final publisher = json['publisher'];
    if (publisher is Map) {
      publisherId = asInt(publisher['id'], publisherId);
      publisherName = asString(publisher['name']);
    }

    var authorIds = asIntList(json['authorIds']);
    final authors = json['authors'];
    if (authors is List && authors.isNotEmpty) {
      authorIds = authors
          .whereType<Map>()
          .map((a) => asInt(a['id']))
          .where((id) => id > 0)
          .toList();
    }

    var genreIds = asIntList(json['genreIds']);
    final genres = json['genres'];
    if (genres is List && genres.isNotEmpty) {
      genreIds = genres
          .whereType<Map>()
          .map((g) => asInt(g['id']))
          .where((id) => id > 0)
          .toList();
    }

    return Book(
      id: asInt(json['id']),
      title: asString(json['title']),
      isbn: asString(json['isbn']),
      year: asInt(json['year']),
      pages: asInt(json['pages']),
      publisherId: publisherId,
      authorIds: authorIds,
      genreIds: genreIds,
      copiesTotal: asInt(json['copiesTotal']),
      copiesAvailable: asInt(json['copiesAvailable']),
      deletedAt: asDateTime(json['deletedAt']),
      publisherName: publisherName,
    );
  }
}
