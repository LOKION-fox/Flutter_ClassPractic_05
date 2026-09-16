import 'app_user.dart';

class AuthResult {
  final String accessToken;
  final String refreshToken;
  final AppUser user;

  const AuthResult({
    required this.accessToken,
    required this.refreshToken,
    required this.user,
  });

  factory AuthResult.fromJson(
    Map<String, dynamic> json,
  ) {
    return AuthResult(
      accessToken: json['accessToken']?.toString() ?? '',
      refreshToken: json['refreshToken']?.toString() ?? '',
      user: AppUser.fromJson(
        Map<String, dynamic>.from(
          json['user'] as Map,
        ),
      ),
    );
  }
}
