import '../utils/json_utils.dart';

class Author {
  final int id;
  final String firstName;
  final String lastName;
  final String country;
  final int birthYear;
  final String? bio;
  final DateTime? deletedAt;

  const Author({
    required this.id,
    required this.firstName,
    required this.lastName,
    required this.country,
    required this.birthYear,
    this.bio,
    this.deletedAt,
  });

  bool get isDeleted => deletedAt != null;

  String get fullName {
    final joined = '$lastName $firstName'.trim();
    return joined.isEmpty ? lastName : joined;
  }

  Author copyWith({
    String? firstName,
    String? lastName,
    String? country,
    int? birthYear,
    String? bio,
    DateTime? deletedAt,
    bool clearDeletedAt = false,
  }) {
    return Author(
      id: id,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      country: country ?? this.country,
      birthYear: birthYear ?? this.birthYear,
      bio: bio ?? this.bio,
      deletedAt: clearDeletedAt ? null : (deletedAt ?? this.deletedAt),
    );
  }

  Map<String, dynamic> toApiBody() => {
    'fullName': fullName,
    'birthYear': birthYear,
    'country': country,
  };

  Map<String, dynamic> toJson() => {
    'id': id,
    'firstName': firstName,
    'lastName': lastName,
    'fullName': fullName,
    'country': country,
    'birthYear': birthYear,
    'bio': bio,
    'deletedAt': deletedAt?.toIso8601String(),
  };

  factory Author.fromJson(Map<String, dynamic> json) {
    var firstName = asString(json['firstName']);
    var lastName = asString(json['lastName']);
    final apiName = asString(json['fullName']);
    if (apiName.isNotEmpty && firstName.isEmpty && lastName.isEmpty) {
      // API отдаёт одну строку fullName — кладём её в lastName для отображения.
      lastName = apiName;
    }
    return Author(
      id: asInt(json['id']),
      firstName: firstName,
      lastName: lastName,
      country: asString(json['country']),
      birthYear: asInt(json['birthYear']),
      bio: json['bio'] == null && json['description'] == null
          ? null
          : asString(json['bio'] ?? json['description']),
      deletedAt: asDateTime(json['deletedAt']),
    );
  }
}
