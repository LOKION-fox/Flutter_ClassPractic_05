class PageResult<T> {
  final List<T> items;

  final int page;
  final int size;
  final int total;

  const PageResult({
    required this.items,
    required this.page,
    required this.size,
    required this.total,
  });

  int get totalPages {
    if (total == 0) {
      return 1;
    }

    return (total / size).ceil();
  }

  bool get hasPrevious => page > 1;

  bool get hasNext => page < totalPages;

  factory PageResult.fromJson(
    Map<String, dynamic> json,
    T Function(
      Map<String, dynamic>,
    ) fromJson,
  ) {
    final rawItems = json['items'];

    final items = <T>[];

    if (rawItems is List) {
      for (final item in rawItems) {
        if (item is Map) {
          items.add(
            fromJson(
              Map<String, dynamic>.from(item),
            ),
          );
        }
      }
    }

    return PageResult<T>(
      items: items,
      page: (json['page'] as num?)?.toInt() ?? 1,
      size: (json['size'] as num?)?.toInt() ?? 10,
      total: (json['total'] as num?)?.toInt() ?? items.length,
    );
  }

  PageResult.empty({
    this.size = 10,
  })  : items = <T>[],
        page = 1,
        total = 0;
}
