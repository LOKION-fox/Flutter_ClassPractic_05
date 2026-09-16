import 'json_helpers.dart';

class Animal {
  final int id;

  final String name;
  final String species;
  final String breed;

  final int ageMonths;

  final String sex;
  final String country;

  final double price;

  final int supplierId;

  final List<int> categoryIds;

  final String description;

  final DateTime? deletedAt;

  const Animal({
    required this.id,
    required this.name,
    required this.species,
    required this.breed,
    required this.ageMonths,
    required this.sex,
    required this.country,
    required this.price,
    required this.supplierId,
    required this.categoryIds,
    required this.description,
    this.deletedAt,
  });

  bool get isDeleted => deletedAt != null;

  Animal copyWith({
    int? id,
    String? name,
    String? species,
    String? breed,
    int? ageMonths,
    String? sex,
    String? country,
    double? price,
    int? supplierId,
    List<int>? categoryIds,
    String? description,
    DateTime? deletedAt,
    bool clearDeletedAt = false,
  }) {
    return Animal(
      id: id ?? this.id,
      name: name ?? this.name,
      species: species ?? this.species,
      breed: breed ?? this.breed,
      ageMonths: ageMonths ?? this.ageMonths,
      sex: sex ?? this.sex,
      country: country ?? this.country,
      price: price ?? this.price,
      supplierId: supplierId ?? this.supplierId,
      categoryIds: categoryIds ?? this.categoryIds,
      description: description ?? this.description,
      deletedAt: clearDeletedAt ? null : deletedAt ?? this.deletedAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'species': species,
      'breed': breed,
      'ageMonths': ageMonths,
      'sex': sex,
      'country': country,
      'price': price,
      'supplierId': supplierId,
      'categoryIds': categoryIds,
      'description': description,
    };
  }

  factory Animal.fromJson(
    Map<String, dynamic> json,
  ) {
    var supplierId = jsonInt(
      json,
      'supplierId',
    );

    final supplier = json['supplier'];

    if (supplierId == 0 && supplier is Map) {
      supplierId = (supplier['id'] as num?)?.toInt() ?? 0;
    }

    var categoryIds = jsonIntList(
      json,
      'categoryIds',
    );

    if (categoryIds.isEmpty && json['categories'] is List) {
      categoryIds = (json['categories'] as List)
          .whereType<Map>()
          .map(
            (item) => (item['id'] as num?)?.toInt(),
          )
          .whereType<int>()
          .toList();
    }

    return Animal(
      id: jsonInt(
        json,
        'id',
      ),
      name: jsonString(
        json,
        'name',
      ),
      species: jsonString(
        json,
        'species',
      ),
      breed: jsonString(
        json,
        'breed',
      ),
      ageMonths: jsonInt(
        json,
        'ageMonths',
      ),
      sex: jsonString(
        json,
        'sex',
      ),
      country: jsonString(
        json,
        'country',
      ),
      price: jsonDouble(
        json,
        'price',
      ),
      supplierId: supplierId,
      categoryIds: categoryIds,
      description: jsonString(
        json,
        'description',
      ),
      deletedAt: jsonDate(
        json,
        'deletedAt',
      ),
    );
  }
}
