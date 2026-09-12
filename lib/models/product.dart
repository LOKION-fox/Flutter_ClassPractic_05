import 'json_helpers.dart';

class Product {
  final int id;

  final String name;
  final String article;
  final String brand;

  final double price;
  final int stock;

  final int supplierId;

  final List<int>
      categoryIds;

  final String description;

  final DateTime? deletedAt;

  const Product({
    required this.id,
    required this.name,
    required this.article,
    required this.brand,
    required this.price,
    required this.stock,
    required this.supplierId,
    required this.categoryIds,
    required this.description,
    this.deletedAt,
  });

  bool get isDeleted =>
      deletedAt != null;

  Product copyWith({
    int? id,
    String? name,
    String? article,
    String? brand,
    double? price,
    int? stock,
    int? supplierId,
    List<int>? categoryIds,
    String? description,
    DateTime? deletedAt,
    bool clearDeletedAt = false,
  }) {
    return Product(
      id: id ?? this.id,

      name:
          name ?? this.name,

      article:
          article ??
              this.article,

      brand:
          brand ?? this.brand,

      price:
          price ?? this.price,

      stock:
          stock ?? this.stock,

      supplierId:
          supplierId ??
              this.supplierId,

      categoryIds:
          categoryIds ??
              this.categoryIds,

      description:
          description ??
              this.description,

      deletedAt:
          clearDeletedAt
              ? null
              : deletedAt ??
                  this.deletedAt,
    );
  }

  Map<String, dynamic>
      toJson() {
    return {
      'name': name,
      'article': article,
      'brand': brand,
      'price': price,
      'stock': stock,
      'supplierId':
          supplierId,
      'categoryIds':
          categoryIds,
      'description':
          description,
    };
  }

  factory Product.fromJson(
    Map<String, dynamic> json,
  ) {
    var supplierId =
        jsonInt(
      json,
      'supplierId',
    );

    final supplier =
        json['supplier'];

    if (
      supplierId == 0 &&
      supplier is Map
    ) {
      supplierId =
          (supplier['id'] as num?)
                  ?.toInt() ??
              0;
    }

    var categoryIds =
        jsonIntList(
      json,
      'categoryIds',
    );

    if (
      categoryIds.isEmpty &&
      json['categories']
          is List
    ) {
      categoryIds =
          (json['categories']
                  as List)
              .whereType<Map>()
              .map(
                (item) =>
                    (item['id']
                            as num?)
                        ?.toInt(),
              )
              .whereType<int>()
              .toList();
    }

    return Product(
      id:
          jsonInt(
        json,
        'id',
      ),

      name:
          jsonString(
        json,
        'name',
      ),

      article:
          jsonString(
        json,
        'article',
      ),

      brand:
          jsonString(
        json,
        'brand',
      ),

      price:
          jsonDouble(
        json,
        'price',
      ),

      stock:
          jsonInt(
        json,
        'stock',
      ),

      supplierId:
          supplierId,

      categoryIds:
          categoryIds,

      description:
          jsonString(
        json,
        'description',
      ),

      deletedAt:
          jsonDate(
        json,
        'deletedAt',
      ),
    );
  }
}