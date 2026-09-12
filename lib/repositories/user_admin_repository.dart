import '../models/app_role.dart';
import '../models/app_user.dart';

abstract interface class
    UserAdminRepository {
  Future<List<AppUser>> findUsers();

  Future<AppUser> changeRole(
    int userId,
    AppRole role,
  );

  Future<Map<String, int>>
      getStatistics();
}