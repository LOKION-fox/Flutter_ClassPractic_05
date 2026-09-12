import 'app_role.dart';

class AppUser {
  final int id;
  final String username;
  final String fullName;
  final AppRole role;

  const AppUser({
    required this.id,
    required this.username,
    required this.fullName,
    required this.role,
  });

  factory AppUser.fromJson(
    Map<String, dynamic> json,
  ) {
    return AppUser(
      id: (json['id'] as num?)?.toInt() ?? 0,

      username:
          json['username']?.toString() ?? '',

      fullName:
          json['fullName']?.toString() ?? '',

      role:
          tryParseRole(
            json['role']?.toString(),
          ) ??
          AppRole.customer,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'username': username,
      'fullName': fullName,
      'role': role.value,
    };
  }
}