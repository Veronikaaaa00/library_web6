import '../utils/json_utils.dart';

class Publisher {
  final int id;
  final String name;

  /// В UI — «страна»; в API это поле `city`.
  final String country;
  final int? foundedYear;
  final DateTime? deletedAt;

  const Publisher({
    required this.id,
    required this.name,
    required this.country,
    this.foundedYear,
    this.deletedAt,
  });

  bool get isDeleted => deletedAt != null;

  Publisher copyWith({
    String? name,
    String? country,
    int? foundedYear,
    DateTime? deletedAt,
    bool clearDeletedAt = false,
  }) {
    return Publisher(
      id: id,
      name: name ?? this.name,
      country: country ?? this.country,
      foundedYear: foundedYear ?? this.foundedYear,
      deletedAt: clearDeletedAt ? null : (deletedAt ?? this.deletedAt),
    );
  }

  Map<String, dynamic> toApiBody() => {
    'name': name,
    'city': country,
    if (foundedYear != null) 'foundedYear': foundedYear,
  };

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'country': country,
    'city': country,
    'foundedYear': foundedYear,
    'deletedAt': deletedAt?.toIso8601String(),
  };

  factory Publisher.fromJson(Map<String, dynamic> json) => Publisher(
    id: asInt(json['id']),
    name: asString(json['name']),
    country: asString(
      json['country']?.toString().isNotEmpty == true
          ? json['country']
          : json['city'],
    ),
    foundedYear: json['foundedYear'] == null
        ? null
        : asInt(json['foundedYear']),
    deletedAt: asDateTime(json['deletedAt']),
  );
}
