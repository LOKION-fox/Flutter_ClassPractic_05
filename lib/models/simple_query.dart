class SimpleQuery {
  final String search;

  final String? filter;

  final String sortField;

  final bool sortAscending;

  final int page;
  final int size;

  final bool includeDeleted;

  const SimpleQuery({
    this.search = '',
    this.filter,
    this.sortField = 'name',
    this.sortAscending = true,
    this.page = 1,
    this.size = 10,
    this.includeDeleted = false,
  });

  static const _unset = Object();

  SimpleQuery copyWith({
    String? search,
    Object? filter = _unset,
    String? sortField,
    bool? sortAscending,
    int? page,
    int? size,
    bool? includeDeleted,
  }) {
    return SimpleQuery(
      search: search ?? this.search,
      filter: filter == _unset ? this.filter : filter as String?,
      sortField: sortField ?? this.sortField,
      sortAscending: sortAscending ?? this.sortAscending,
      page: page ?? 1,
      size: size ?? this.size,
      includeDeleted: includeDeleted ?? this.includeDeleted,
    );
  }

  factory SimpleQuery.fromUri(
    Uri uri, {
    required String filterParam,
    required Set<String> allowedSortFields,
    String defaultSort = 'name',
  }) {
    final query = uri.queryParameters;

    final sort = (query['sort'] ?? '$defaultSort,asc').split(',');

    var sortField = sort.first;

    if (!allowedSortFields.contains(
      sortField,
    )) {
      sortField = defaultSort;
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

    return SimpleQuery(
      search: query['search'] ?? '',
      filter: query[filterParam],
      sortField: sortField,
      sortAscending: sort.length < 2 || sort[1] != 'desc',
      page: page,
      size: size,
      includeDeleted: query['deleted'] == '1',
    );
  }

  Map<String, dynamic> toApiQueryParameters({
    required String filterParam,
  }) {
    final result = <String, dynamic>{
      'sort': '$sortField,${sortAscending ? 'asc' : 'desc'}',
      'page': page,
      'size': size,
    };

    if (search.trim().isNotEmpty) {
      result['search'] = search.trim();
    }

    if (filter != null) {
      result[filterParam] = filter;
    }

    if (includeDeleted) {
      result['includeDeleted'] = 'true';
    }

    return result;
  }

  String toLocation(
    String path, {
    required String filterParam,
  }) {
    final params = <String, String>{};

    if (search.trim().isNotEmpty) {
      params['search'] = search.trim();
    }

    if (filter != null) {
      params[filterParam] = filter!;
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
    return other is SimpleQuery &&
        other.search == search &&
        other.filter == filter &&
        other.sortField == sortField &&
        other.sortAscending == sortAscending &&
        other.page == page &&
        other.size == size &&
        other.includeDeleted == includeDeleted;
  }

  @override
  int get hashCode => Object.hash(
        search,
        filter,
        sortField,
        sortAscending,
        page,
        size,
        includeDeleted,
      );
}
