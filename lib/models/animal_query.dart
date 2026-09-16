class AnimalQuery {
  final String search;

  final String? species;
  final String? sex;

  final int? supplierId;

  final double? priceFrom;
  final double? priceTo;

  final String sortField;
  final bool sortAscending;

  final int page;
  final int size;

  final bool includeDeleted;

  const AnimalQuery({
    this.search = '',
    this.species,
    this.sex,
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

  AnimalQuery copyWith({
    String? search,
    Object? species = _unset,
    Object? sex = _unset,
    Object? supplierId = _unset,
    Object? priceFrom = _unset,
    Object? priceTo = _unset,
    String? sortField,
    bool? sortAscending,
    int? page,
    int? size,
    bool? includeDeleted,
  }) {
    return AnimalQuery(
      search: search ?? this.search,
      species: species == _unset ? this.species : species as String?,
      sex: sex == _unset ? this.sex : sex as String?,
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

  factory AnimalQuery.fromUri(
    Uri uri,
  ) {
    final q = uri.queryParameters;

    final sort = (q['sort'] ?? 'name,asc').split(',');

    var field = sort.first;

    if (!{
      'name',
      'price',
      'age',
    }.contains(field)) {
      field = 'name';
    }

    var page = int.tryParse(
          q['page'] ?? '',
        ) ??
        1;

    if (page < 1) {
      page = 1;
    }

    var size = int.tryParse(
          q['size'] ?? '',
        ) ??
        10;

    if (![10, 25, 50].contains(size)) {
      size = 10;
    }

    return AnimalQuery(
      search: q['search'] ?? '',
      species: q['species'],
      sex: q['sex'],
      supplierId: int.tryParse(
        q['supplierId'] ?? '',
      ),
      priceFrom: double.tryParse(
        q['priceFrom'] ?? '',
      ),
      priceTo: double.tryParse(
        q['priceTo'] ?? '',
      ),
      sortField: field,
      sortAscending: sort.length < 2 || sort[1] != 'desc',
      page: page,
      size: size,
      includeDeleted: q['deleted'] == '1',
    );
  }

  Map<String, dynamic> toApiQueryParameters() {
    final apiSortField = sortField == 'age' ? 'ageMonths' : sortField;

    final result = <String, dynamic>{
      'sort': '$apiSortField,${sortAscending ? 'asc' : 'desc'}',
      'page': page,
      'size': size,
    };

    if (search.trim().isNotEmpty) {
      result['search'] = search.trim();
    }

    if (species != null) {
      result['species'] = species;
    }

    if (sex != null) {
      result['sex'] = sex;
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

    if (species != null) {
      params['species'] = species!;
    }

    if (sex != null) {
      params['sex'] = sex!;
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
    return other is AnimalQuery &&
        other.search == search &&
        other.species == species &&
        other.sex == sex &&
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
        species,
        sex,
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
