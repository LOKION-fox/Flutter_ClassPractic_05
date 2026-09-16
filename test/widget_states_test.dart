import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:pet_shop_web/models/app_role.dart';
import 'package:pet_shop_web/state/load_status.dart';
import 'package:pet_shop_web/validation/validators.dart';
import 'package:pet_shop_web/widgets/entity_form_scaffold.dart';
import 'package:pet_shop_web/widgets/entity_list_scaffold.dart';
import 'package:pet_shop_web/widgets/permission_gate.dart';

Widget buildList({
  required LoadStatus status,
  List<String> items = const [],
  String? error,
  VoidCallback? onRetry,
}) {
  return MaterialApp(
    home: EntityListScaffold<String>(
      title: 'Тестовый список',
      filters: const SizedBox.shrink(),
      status: status,
      error: error,
      items: items,
      selected: const <int>{},
      table: const Text('TABLE'),
      cardBuilder: (item) {
        return Card(
          child: Text(item),
        );
      },
      onDeleteSelected: () async {},
      onRetry: onRetry ?? () {},
      page: 1,
      totalPages: 1,
      total: items.length,
      size: 10,
      onPageChanged: (_) {},
      onSizeChanged: (_) {},
    ),
  );
}

void main() {
  testWidgets(
    'показывается состояние загрузки',
    (tester) async {
      await tester.pumpWidget(
        buildList(
          status: LoadStatus.loading,
        ),
      );

      expect(
        find.byKey(
          const ValueKey(
            'entity-loading',
          ),
        ),
        findsOneWidget,
      );

      expect(
        find.byType(
          CircularProgressIndicator,
        ),
        findsOneWidget,
      );
    },
  );

  testWidgets(
    'показывается пустой результат',
    (tester) async {
      await tester.pumpWidget(
        buildList(
          status: LoadStatus.success,
        ),
      );

      expect(
        find.byKey(
          const ValueKey(
            'entity-empty',
          ),
        ),
        findsOneWidget,
      );

      expect(
        find.text(
          'По заданным условиям ничего не найдено',
        ),
        findsOneWidget,
      );
    },
  );

  testWidgets(
    'ошибка показывает кнопку повтора',
    (tester) async {
      var retries = 0;

      await tester.pumpWidget(
        buildList(
          status: LoadStatus.error,
          error: 'Сервер недоступен',
          onRetry: () {
            retries++;
          },
        ),
      );

      expect(
        find.byKey(
          const ValueKey(
            'entity-error',
          ),
        ),
        findsOneWidget,
      );

      expect(
        find.text(
          'Сервер недоступен',
        ),
        findsOneWidget,
      );

      await tester.tap(
        find.byKey(
          const ValueKey(
            'entity-retry',
          ),
        ),
      );

      await tester.pump();

      expect(
        retries,
        1,
      );
    },
  );

  testWidgets(
    'форма не отправляется с пустым обязательным полем',
    (tester) async {
      final formKey = GlobalKey<FormState>();

      await tester.pumpWidget(
        MaterialApp(
          home: EntityFormScaffold(
            title: 'Форма',
            formKey: formKey,
            isDirty: false,
            successLocation: '/',
            onSubmit: () async {
              formKey.currentState!.validate();

              return false;
            },
            children: [
              TextFormField(
                decoration: const InputDecoration(
                  labelText: 'Название',
                ),
                validator: (value) {
                  return Validators.requiredText(
                    value,
                    field: 'Название',
                  );
                },
              ),
            ],
          ),
        ),
      );

      await tester.tap(
        find.text(
          'Сохранить',
        ),
      );

      await tester.pump();

      expect(
        find.text(
          'Название обязательно для заполнения',
        ),
        findsOneWidget,
      );
    },
  );

  testWidgets(
    'недоступный элемент скрывается при недостаточной роли',
    (tester) async {
      final allowed = roleHasPermission(
        AppRole.customer,
        AppPermission.manageUsers,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PermissionGate(
              allowed: allowed,
              child: const Text(
                'Управление пользователями',
              ),
            ),
          ),
        ),
      );

      expect(
        find.text(
          'Управление пользователями',
        ),
        findsNothing,
      );
    },
  );

  testWidgets(
    'доступный элемент показывается администратору',
    (tester) async {
      final allowed = roleHasPermission(
        AppRole.admin,
        AppPermission.manageUsers,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PermissionGate(
              allowed: allowed,
              child: const Text(
                'Управление пользователями',
              ),
            ),
          ),
        ),
      );

      expect(
        find.text(
          'Управление пользователями',
        ),
        findsOneWidget,
      );
    },
  );
}
