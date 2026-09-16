import 'package:flutter_test/flutter_test.dart';

import 'package:pet_shop_web/models/app_role.dart';
import 'package:pet_shop_web/models/app_user.dart';
import 'package:pet_shop_web/models/product.dart';

void main() {
  test(
    'Product разбирает вложенные связи из JSON',
    () {
      final product = Product.fromJson(
        {
          'id': 10,
          'name': 'Игрушка',
          'article': 'T-10',
          'brand': 'Test',
          'price': 500,
          'stock': 3,
          'supplier': {
            'id': 7,
            'name': 'Поставщик',
          },
          'categories': [
            {
              'id': 2,
              'name': 'Игрушки',
            },
          ],
          'description': 'Описание',
          'deletedAt': null,
        },
      );

      expect(
        product.id,
        10,
      );

      expect(
        product.supplierId,
        7,
      );

      expect(
        product.categoryIds,
        [2],
      );
    },
  );

  test(
    'Product безопасно разбирает отсутствующие поля',
    () {
      final product = Product.fromJson(
        {
          'id': 1,
        },
      );

      expect(
        product.name,
        '',
      );

      expect(
        product.article,
        '',
      );

      expect(
        product.categoryIds,
        isEmpty,
      );

      expect(
        product.supplierId,
        0,
      );
    },
  );

  test(
    'AppUser разбирает роль администратора',
    () {
      final user = AppUser.fromJson(
        {
          'id': 3,
          'username': 'admin',
          'fullName': 'Администратор',
          'role': 'admin',
        },
      );

      expect(
        user.role,
        AppRole.admin,
      );

      expect(
        user.username,
        'admin',
      );
    },
  );

  test(
    'неизвестная роль безопасно превращается в customer',
    () {
      final user = AppUser.fromJson(
        {
          'role': 'unknown',
        },
      );

      expect(
        user.role,
        AppRole.customer,
      );
    },
  );
}
