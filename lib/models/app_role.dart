enum AppRole {
  customer,
  manager,
  admin,
}

enum AppPermission {
  viewCatalog,
  customerArea,

  manageCatalog,
  manageReferences,
  manageCustomers,
  managerArea,

  manageUsers,
  viewStatistics,
  hardDelete,
  restore,
  adminArea,
}

AppRole? tryParseRole(String? value) {
  switch (value) {
    case 'customer':
      return AppRole.customer;

    case 'manager':
      return AppRole.manager;

    case 'admin':
      return AppRole.admin;

    default:
      return null;
  }
}

extension AppRoleExtension on AppRole {
  String get value {
    switch (this) {
      case AppRole.customer:
        return 'customer';

      case AppRole.manager:
        return 'manager';

      case AppRole.admin:
        return 'admin';
    }
  }

  String get title {
    switch (this) {
      case AppRole.customer:
        return 'Покупатель';

      case AppRole.manager:
        return 'Менеджер';

      case AppRole.admin:
        return 'Администратор';
    }
  }
}

bool roleHasPermission(
  AppRole role,
  AppPermission permission,
) {
  switch (role) {
    case AppRole.customer:
      return {
        AppPermission.viewCatalog,
        AppPermission.customerArea,
      }.contains(permission);

    case AppRole.manager:
      return {
        AppPermission.viewCatalog,
        AppPermission.manageCatalog,
        AppPermission.manageReferences,
        AppPermission.manageCustomers,
        AppPermission.managerArea,
      }.contains(permission);

    case AppRole.admin:
      return {
        AppPermission.viewCatalog,
        AppPermission.manageCatalog,
        AppPermission.manageReferences,
        AppPermission.manageCustomers,
        AppPermission.manageUsers,
        AppPermission.viewStatistics,
        AppPermission.hardDelete,
        AppPermission.restore,
        AppPermission.adminArea,
      }.contains(permission);
  }
}
