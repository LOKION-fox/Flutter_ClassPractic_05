String jsonString(
  Map<String, dynamic> json,
  String key, {
  String fallback = '',
}) {
  final value = json[key];

  if (value == null) {
    return fallback;
  }

  return value.toString();
}

int jsonInt(
  Map<String, dynamic> json,
  String key, {
  int fallback = 0,
}) {
  final value = json[key];

  if (value is int) {
    return value;
  }

  if (value is num) {
    return value.toInt();
  }

  return int.tryParse(value?.toString() ?? '') ??
      fallback;
}

double jsonDouble(
  Map<String, dynamic> json,
  String key, {
  double fallback = 0,
}) {
  final value = json[key];

  if (value is double) {
    return value;
  }

  if (value is num) {
    return value.toDouble();
  }

  return double.tryParse(
        value?.toString() ?? '',
      ) ??
      fallback;
}

List<int> jsonIntList(
  Map<String, dynamic> json,
  String key,
) {
  final value = json[key];

  if (value is! List) {
    return [];
  }

  final result = <int>[];

  for (final item in value) {
    if (item is int) {
      result.add(item);
    } else if (item is num) {
      result.add(item.toInt());
    } else {
      final parsed = int.tryParse(
        item?.toString() ?? '',
      );

      if (parsed != null) {
        result.add(parsed);
      }
    }
  }

  return result;
}

DateTime? jsonDate(
  Map<String, dynamic> json,
  String key,
) {
  final value = json[key];

  if (value == null) {
    return null;
  }

  return DateTime.tryParse(
    value.toString(),
  );
}