import '../utils/json_utils.dart';
import 'role.dart';

class AppUser {
  final int id;
  final String username;
  final String fullName;
  final String email;
  final Role role;
  final int? readerId;

  const AppUser({
    required this.id,
    required this.username,
    required this.fullName,
    required this.email,
    required this.role,
    this.readerId,
  });

  factory AppUser.fromJson(Map<String, dynamic> json) => AppUser(
    id: asInt(json['id']),
    username: asString(json['username']),
    fullName: asString(json['fullName']),
    email: asString(json['email']),
    role: Role.fromApi(asString(json['role'])),
    readerId: json['readerId'] == null ? null : asInt(json['readerId']),
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'username': username,
    'fullName': fullName,
    'email': email,
    'role': role.apiValue,
    'readerId': readerId,
  };
}
