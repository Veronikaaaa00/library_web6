import '../utils/json_utils.dart';

class Genre {
  final int id;
  final String name;
  final String? description;
  final DateTime? deletedAt;

  const Genre({
    required this.id,
    required this.name,
    this.description,
    this.deletedAt,
  });

  bool get isDeleted => deletedAt != null;

  Genre copyWith({
    String? name,
    String? description,
    DateTime? deletedAt,
    bool clearDeletedAt = false,
  }) {
    return Genre(
      id: id,
      name: name ?? this.name,
      description: description ?? this.description,
      deletedAt: clearDeletedAt ? null : (deletedAt ?? this.deletedAt),
    );
  }

  Map<String, dynamic> toApiBody() => {
    'name': name,
    if (description != null) 'description': description,
  };

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'description': description,
    'deletedAt': deletedAt?.toIso8601String(),
  };

  factory Genre.fromJson(Map<String, dynamic> json) => Genre(
    id: asInt(json['id']),
    name: asString(json['name']),
    description: json['description'] == null
        ? null
        : asString(json['description']),
    deletedAt: asDateTime(json['deletedAt']),
  );
}
