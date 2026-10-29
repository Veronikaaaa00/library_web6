import '../utils/json_utils.dart';

class LibraryCard {
  final String number;
  final DateTime issuedAt;
  final DateTime expiresAt;
  final bool isActive;

  const LibraryCard({
    required this.number,
    required this.issuedAt,
    required this.expiresAt,
    this.isActive = true,
  });

  LibraryCard copyWith({
    String? number,
    DateTime? issuedAt,
    DateTime? expiresAt,
    bool? isActive,
  }) {
    return LibraryCard(
      number: number ?? this.number,
      issuedAt: issuedAt ?? this.issuedAt,
      expiresAt: expiresAt ?? this.expiresAt,
      isActive: isActive ?? this.isActive,
    );
  }

  Map<String, dynamic> toJson() => {
    'number': number,
    'issuedAt': issuedAt.toIso8601String(),
    'expiresAt': expiresAt.toIso8601String(),
    'isActive': isActive,
  };

  factory LibraryCard.fromJson(Map<String, dynamic> json) {
    final now = DateTime.now();
    return LibraryCard(
      number: asString(json['number']),
      issuedAt: asDateTime(json['issuedAt']) ?? now,
      expiresAt:
          asDateTime(json['expiresAt']) ?? now.add(const Duration(days: 365)),
      isActive: asBool(json['isActive'], true),
    );
  }
}
