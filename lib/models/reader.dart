import '../utils/json_utils.dart';
import 'library_card.dart';

class Reader {
  final int id;
  final String firstName;
  final String lastName;
  final String email;
  final String phone;
  final LibraryCard card;
  final DateTime? deletedAt;

  const Reader({
    required this.id,
    required this.firstName,
    required this.lastName,
    required this.email,
    required this.phone,
    required this.card,
    this.deletedAt,
  });

  bool get isDeleted => deletedAt != null;

  String get fullName {
    final joined = '$lastName $firstName'.trim();
    return joined.isEmpty ? lastName : joined;
  }

  Reader copyWith({
    String? firstName,
    String? lastName,
    String? email,
    String? phone,
    LibraryCard? card,
    DateTime? deletedAt,
    bool clearDeletedAt = false,
  }) {
    return Reader(
      id: id,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      card: card ?? this.card,
      deletedAt: clearDeletedAt ? null : (deletedAt ?? this.deletedAt),
    );
  }

  Map<String, dynamic> toApiBody() => {
    'fullName': fullName,
    'email': email,
    'phone': phone,
  };

  Map<String, dynamic> toJson() => {
    'id': id,
    'firstName': firstName,
    'lastName': lastName,
    'fullName': fullName,
    'email': email,
    'phone': phone,
    'card': card.toJson(),
    'deletedAt': deletedAt?.toIso8601String(),
  };

  factory Reader.fromJson(Map<String, dynamic> json) {
    var firstName = asString(json['firstName']);
    var lastName = asString(json['lastName']);
    final apiName = asString(json['fullName']);
    if (apiName.isNotEmpty && firstName.isEmpty && lastName.isEmpty) {
      lastName = apiName;
    }
    final cardRaw = json['card'];
    final card = cardRaw is Map
        ? LibraryCard.fromJson(Map<String, dynamic>.from(cardRaw))
        : LibraryCard(
            number: '',
            issuedAt: DateTime.now(),
            expiresAt: DateTime.now().add(const Duration(days: 365)),
          );
    return Reader(
      id: asInt(json['id']),
      firstName: firstName,
      lastName: lastName,
      email: asString(json['email']),
      phone: asString(json['phone']),
      card: card,
      deletedAt: asDateTime(json['deletedAt']),
    );
  }
}
