import '../models/app_user.dart';
import '../models/auth_result.dart';
import 'api_client.dart';
import 'api_exceptions.dart';
import 'auth_session.dart';

class AuthService {
  final ApiClient api;
  final AuthSession session;

  AuthService(
    this.api,
    this.session,
  );

  Future<AuthResult> login(
    String username,
    String password,
  ) async {
    final response = await api.post(
      '/auth/login',
      data: {
        'username': username,
        'password': password,
      },
    );

    return AuthResult.fromJson(
      Map<String, dynamic>.from(
        response.data as Map,
      ),
    );
  }

  Future<AppUser> register({
    required String username,
    required String fullName,
    required String password,
  }) async {
    final response = await api.post(
      '/auth/register',
      data: {
        'username': username,
        'fullName': fullName,
        'password': password,
      },
    );

    return AppUser.fromJson(
      Map<String, dynamic>.from(
        response.data as Map,
      ),
    );
  }

  Future<AuthResult> refresh(
    String refreshToken,
  ) async {
    final response = await api.post(
      '/auth/refresh',
      data: {
        'refreshToken': refreshToken,
      },
    );

    return AuthResult.fromJson(
      Map<String, dynamic>.from(
        response.data as Map,
      ),
    );
  }

  Future<AppUser> me() async {
    final response = await api.get('/auth/me');

    return AppUser.fromJson(
      Map<String, dynamic>.from(
        response.data as Map,
      ),
    );
  }

  Future<void> logout(
    String? refreshToken,
  ) async {
    await api.post(
      '/auth/logout',
      data: {
        'refreshToken': refreshToken,
      },
    );
  }

  Future<T> authorized<T>(
    Future<T> Function() action,
  ) {
    if (!session.isAuthorized) {
      throw const UnauthorizedException(
        'Для выполнения операции необходимо войти в систему',
      );
    }

    return action();
  }
}
