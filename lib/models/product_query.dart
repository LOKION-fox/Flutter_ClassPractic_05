class ProductQuery {
  final String search;

  final int? categoryId;
  final int? supplierId;

  final double? priceFrom;
  final double? priceTo;

  final String sortField;
  final bool sortAscending;

  final int page;
  final int size;

  final bool includeDeleted;

  const ProductQuery({
    this.search = '',
    this.categoryId,
    this.supplierId,
    this.priceFrom,
    this.priceTo,
    this.sortField = 'name',
    this.sortAscending = true,
    this.page = 1,
    this.size = 10,
    this.includeDeleted = false,
  });

  static const _unset = Object();

  ProductQuery copyWith({
    String? search,
    Object? categoryId = _unset,
    Object? supplierId = _unset,
    Object? priceFrom = _unset,
    Object? priceTo = _unset,
    String? sortField,
    bool? sortAscending,
    int? page,
    int? size,
    bool? includeDeleted,
  }) {
    return ProductQuery(
      search: search ?? this.search,
      categoryId: categoryId == _unset ? this.categoryId : categoryId as int?,
      supplierId: supplierId == _unset ? this.supplierId : supplierId as int?,
      priceFrom: priceFrom == _unset ? this.priceFrom : priceFrom as double?,
      priceTo: priceTo == _unset ? this.priceTo : priceTo as double?,
      sortField: sortField ?? this.sortField,
      sortAscending: sortAscending ?? this.sortAscending,
      page: page ?? 1,
      size: size ?? this.size,
      includeDeleted: includeDeleted ?? this.includeDeleted,
    );
  }

  factory ProductQuery.fromUri(
    Uri uri,
  ) {
    final query = uri.queryParameters;

    final sort = (query['sort'] ?? 'name,asc').split(',');

    var sortField = sort.first;

    if (!{
      'name',
      'price',
      'stock',
    }.contains(sortField)) {
      sortField = 'name';
    }

    var page = int.tryParse(
          query['page'] ?? '',
        ) ??
        1;

    if (page < 1) {
      page = 1;
    }

    var size = int.tryParse(
          query['size'] ?? '',
        ) ??
        10;

    if (![
      10,
      25,
      50,
    ].contains(size)) {
      size = 10;
    }

    return ProductQuery(
      search: query['search'] ?? '',
      categoryId: int.tryParse(
        query['categoryId'] ?? '',
      ),
      supplierId: int.tryParse(
        query['supplierId'] ?? '',
      ),
      priceFrom: double.tryParse(
        query['priceFrom'] ?? '',
      ),
      priceTo: double.tryParse(
        query['priceTo'] ?? '',
      ),
      sortField: sortField,
      sortAscending: sort.length < 2 || sort[1] != 'desc',
      page: page,
      size: size,
      includeDeleted: query['deleted'] == '1',
    );
  }

  Map<String, dynamic> toApiQueryParameters() {
    final result = <String, dynamic>{
      'sort': '$sortField,${sortAscending ? 'asc' : 'desc'}',
      'page': page,
      'size': size,
    };

    if (search.trim().isNotEmpty) {
      result['search'] = search.trim();
    }

    if (categoryId != null) {
      result['categoryId'] = categoryId;
    }

    if (supplierId != null) {
      result['supplierId'] = supplierId;
    }

    if (priceFrom != null) {
      result['priceFrom'] = priceFrom;
    }

    if (priceTo != null) {
      result['priceTo'] = priceTo;
    }

    if (includeDeleted) {
      result['includeDeleted'] = 'true';
    }

    return result;
  }

  String toLocation(
    String path,
  ) {
    final params = <String, String>{};

    if (search.trim().isNotEmpty) {
      params['search'] = search.trim();
    }

    if (categoryId != null) {
      params['categoryId'] = categoryId.toString();
    }

    if (supplierId != null) {
      params['supplierId'] = supplierId.toString();
    }

    if (priceFrom != null) {
      params['priceFrom'] = priceFrom.toString();
    }

    if (priceTo != null) {
      params['priceTo'] = priceTo.toString();
    }

    params['sort'] = '$sortField,${sortAscending ? 'asc' : 'desc'}';

    params['page'] = page.toString();

    params['size'] = size.toString();

    if (includeDeleted) {
      params['deleted'] = '1';
    }

    return Uri(
      path: path,
      queryParameters: params,
    ).toString();
  }

  @override
  bool operator ==(
    Object other,
  ) {
    return other is ProductQuery &&
        other.search == search &&
        other.categoryId == categoryId &&
        other.supplierId == supplierId &&
        other.priceFrom == priceFrom &&
        other.priceTo == priceTo &&
        other.sortField == sortField &&
        other.sortAscending == sortAscending &&
        other.page == page &&
        other.size == size &&
        other.includeDeleted == includeDeleted;
  }

  @override
  int get hashCode => Object.hash(
        search,
        categoryId,
        supplierId,
        priceFrom,
        priceTo,
        sortField,
        sortAscending,
        page,
        size,
        includeDeleted,
      );
}
