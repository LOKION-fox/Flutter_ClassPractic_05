import 'json_helpers.dart';

class Category {
  final int id;
  final String name;

  // product, animal или both
  final String kind;

  final String description;
  final DateTime? deletedAt;

  const Category({
    required this.id,
    required this.name,
    required this.kind,
    required this.description,
    this.deletedAt,
  });

  bool get isDeleted => deletedAt != null;

  Category copyWith({
    int? id,
    String? name,
    String? kind,
    String? description,
    DateTime? deletedAt,
    bool clearDeletedAt = false,
  }) {
    return Category(
      id: id ?? this.id,
      name: name ?? this.name,
      kind: kind ?? this.kind,
      description: description ?? this.description,
      deletedAt: clearDeletedAt ? null : (deletedAt ?? this.deletedAt),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'kind': kind,
      'description': description,
      'deletedAt': deletedAt?.toIso8601String(),
    };
  }

  factory Category.fromJson(
    Map<String, dynamic> json,
  ) {
    return Category(
      id: jsonInt(json, 'id'),
      name: jsonString(json, 'name'),
      kind: jsonString(
        json,
        'kind',
        fallback: 'product',
      ),
      description: jsonString(json, 'description'),
      deletedAt: jsonDate(json, 'deletedAt'),
    );
  }
}
