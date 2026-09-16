class Validators {
  static String? requiredText(
    String? value, {
    String field = 'Поле',
  }) {
    if (value == null || value.trim().isEmpty) {
      return '$field обязательно для заполнения';
    }

    return null;
  }

  static String? maxLength(
    String? value,
    int max, {
    String field = 'Поле',
  }) {
    if (value != null && value.trim().length > max) {
      return '$field: максимум $max символов';
    }

    return null;
  }

  static String? requiredAndMax(
    String? value,
    int max, {
    String field = 'Поле',
  }) {
    final required = requiredText(
      value,
      field: field,
    );

    if (required != null) {
      return required;
    }

    return maxLength(
      value,
      max,
      field: field,
    );
  }

  static String? numberRange(
    String? value, {
    required double min,
    required double max,
    required String field,
  }) {
    final required = requiredText(
      value,
      field: field,
    );

    if (required != null) {
      return required;
    }

    final number = double.tryParse(
      value!.trim().replaceAll(',', '.'),
    );

    if (number == null) {
      return '$field должно быть числом';
    }

    if (number < min || number > max) {
      return '$field должно быть от $min до $max';
    }

    return null;
  }

  static String? integerRange(
    String? value, {
    required int min,
    required int max,
    required String field,
  }) {
    final required = requiredText(
      value,
      field: field,
    );

    if (required != null) {
      return required;
    }

    final number = int.tryParse(
      value!.trim(),
    );

    if (number == null) {
      return '$field должно быть целым числом';
    }

    if (number < min || number > max) {
      return '$field должно быть от $min до $max';
    }

    return null;
  }

  static String? email(
    String? value,
  ) {
    final required = requiredText(
      value,
      field: 'Email',
    );

    if (required != null) {
      return required;
    }

    final regex = RegExp(
      r'^[^@\s]+@[^@\s]+\.[^@\s]+$',
    );

    if (!regex.hasMatch(
      value!.trim(),
    )) {
      return 'Введите корректный email';
    }

    return null;
  }

  static String? phone(
    String? value,
  ) {
    final required = requiredText(
      value,
      field: 'Телефон',
    );

    if (required != null) {
      return required;
    }

    final regex = RegExp(
      r'^\+?[0-9]{10,15}$',
    );

    if (!regex.hasMatch(
      value!.trim(),
    )) {
      return 'Введите корректный телефон';
    }

    return null;
  }

  static String? requiredId(
    int? value, {
    required String field,
  }) {
    if (value == null || value <= 0) {
      return 'Выберите $field';
    }

    return null;
  }

  static String? requiredIds(
    List<int>? value, {
    required String field,
  }) {
    if (value == null || value.isEmpty) {
      return 'Выберите хотя бы один вариант: $field';
    }

    return null;
  }
}
