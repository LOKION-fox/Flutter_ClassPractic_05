import 'package:flutter_test/flutter_test.dart';

import 'package:pet_shop_web/models/app_role.dart';

void main() {
  test(
    'Покупатель может смотреть каталог',
    () {
      expect(
        roleHasPermission(
          AppRole.customer,
          AppPermission.viewCatalog,
        ),
        true,
      );
    },
  );

  test(
    'Покупатель не может редактировать каталог',
    () {
      expect(
        roleHasPermission(
          AppRole.customer,
          AppPermission.manageCatalog,
        ),
        false,
      );
    },
  );

  test(
    'Покупатель имеет личный раздел',
    () {
      expect(
        roleHasPermission(
          AppRole.customer,
          AppPermission.customerArea,
        ),
        true,
      );
    },
  );

  test(
    'Менеджер может редактировать каталог',
    () {
      expect(
        roleHasPermission(
          AppRole.manager,
          AppPermission.manageCatalog,
        ),
        true,
      );
    },
  );

  test(
    'Менеджер может работать с покупателями',
    () {
      expect(
        roleHasPermission(
          AppRole.manager,
          AppPermission.manageCustomers,
        ),
        true,
      );
    },
  );

  test(
    'Менеджер не может управлять пользователями',
    () {
      expect(
        roleHasPermission(
          AppRole.manager,
          AppPermission.manageUsers,
        ),
        false,
      );
    },
  );

  test(
    'Менеджер не может физически удалять',
    () {
      expect(
        roleHasPermission(
          AppRole.manager,
          AppPermission.hardDelete,
        ),
        false,
      );
    },
  );

  test(
    'Администратор может управлять ролями',
    () {
      expect(
        roleHasPermission(
          AppRole.admin,
          AppPermission.manageUsers,
        ),
        true,
      );
    },
  );

  test(
    'Администратор может физически удалять',
    () {
      expect(
        roleHasPermission(
          AppRole.admin,
          AppPermission.hardDelete,
        ),
        true,
      );
    },
  );
}
