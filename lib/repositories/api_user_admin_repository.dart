import '../core/api_client.dart';
import '../core/auth_service.dart';
import '../models/app_role.dart';
import '../models/app_user.dart';
import 'user_admin_repository.dart';

class ApiUserAdminRepository implements UserAdminRepository {
  final ApiClient _api;
  final AuthService _auth;

  ApiUserAdminRepository(
    this._api,
    this._auth,
  );

  @override
  Future<List<AppUser>> findUsers() {
    return _auth.authorized(
      () async {
        final response = await _api.get(
          '/admin/users',
        );

        final source = response.data as List;

        return source
            .whereType<Map>()
            .map(
              (item) => AppUser.fromJson(
                Map<String, dynamic>.from(item),
              ),
            )
            .toList();
      },
    );
  }

  @override
  Future<AppUser> changeRole(
    int userId,
    AppRole role,
  ) {
    return _auth.authorized(
      () async {
        final response = await _api.put(
          '/admin/users/$userId/role',
          data: {
            'role': role.value,
          },
        );

        return AppUser.fromJson(
          Map<String, dynamic>.from(
            response.data as Map,
          ),
        );
      },
    );
  }

  @override
  Future<Map<String, int>> getStatistics() {
    return _auth.authorized(
      () async {
        final response = await _api.get(
          '/admin/stats',
        );

        final source = Map<String, dynamic>.from(
          response.data as Map,
        );

        return source.map(
          (
            key,
            value,
          ) {
            return MapEntry(
              key,
              (value as num).toInt(),
            );
          },
        );
      },
    );
  }
}
