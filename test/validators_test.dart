import 'package:flutter_test/flutter_test.dart';

import 'package:pet_shop_web/validation/validators.dart';

void main() {
  group(
    'requiredText',
    () {
      test(
        'пустая строка отклоняется',
        () {
          expect(
            Validators.requiredText(
              '',
              field: 'Название',
            ),
            isNotNull,
          );

          expect(
            Validators.requiredText(
              '   ',
              field: 'Название',
            ),
            isNotNull,
          );
        },
      );

      test(
        'непустая строка принимается',
        () {
          expect(
            Validators.requiredText(
              'Корм',
              field: 'Название',
            ),
            isNull,
          );
        },
      );
    },
  );

  group(
    'maxLength',
    () {
      test(
        'слишком длинная строка отклоняется',
        () {
          expect(
            Validators.maxLength(
              '123456',
              5,
              field: 'Код',
            ),
            isNotNull,
          );
        },
      );

      test(
        'строка допустимой длины принимается',
        () {
          expect(
            Validators.maxLength(
              '12345',
              5,
              field: 'Код',
            ),
            isNull,
          );
        },
      );
    },
  );

  group(
    'numberRange',
    () {
      test(
        'нечисловое значение отклоняется',
        () {
          expect(
            Validators.numberRange(
              'abc',
              min: 1,
              max: 100,
              field: 'Цена',
            ),
            isNotNull,
          );
        },
      );

      test(
        'число с запятой принимается',
        () {
          expect(
            Validators.numberRange(
              '10,5',
              min: 1,
              max: 100,
              field: 'Цена',
            ),
            isNull,
          );
        },
      );
    },
  );

  group(
    'email и phone',
    () {
      test(
        'некорректный email отклоняется',
        () {
          expect(
            Validators.email(
              'mail@',
            ),
            isNotNull,
          );
        },
      );

      test(
        'корректные email и телефон принимаются',
        () {
          expect(
            Validators.email(
              'user@example.ru',
            ),
            isNull,
          );

          expect(
            Validators.phone(
              '+79990000000',
            ),
            isNull,
          );
        },
      );
    },
  );
}
