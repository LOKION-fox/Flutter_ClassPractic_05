import 'package:dio/dio.dart';

import '../core/api_client.dart';
import '../core/api_exceptions.dart';
import '../core/auth_service.dart';
import '../models/category.dart';
import '../models/page_result.dart';
import '../models/simple_query.dart';
import 'category_repository.dart';

class ApiCategoryRepository
    implements CategoryRepository {
  final ApiClient _api;
  final AuthService _auth;

  CancelToken? _findCancelToken;

  List<Category>? _cache;
  DateTime? _cacheTime;

  ApiCategoryRepository(
    this._api,
    this._auth,
  );

  bool get _cacheIsValid {
    if (_cache == null ||
        _cacheTime == null) {
      return false;
    }

    return DateTime.now()
            .difference(_cacheTime!)
            .inMinutes <
        5;
  }

  void _clearCache() {
    _cache = null;
    _cacheTime = null;
  }

  @override
  Future<PageResult<Category>> find(
    SimpleQuery query,
  ) async {
    _findCancelToken?.cancel();

    final token = CancelToken();

    _findCancelToken = token;

    try {
      final response =
          await _api.get(
        '/categories',
        queryParameters:
            query.toApiQueryParameters(
          filterParam: 'kind',
        ),
        cancelToken: token,
      );

      return PageResult<Category>
          .fromJson(
        Map<String, dynamic>.from(
          response.data as Map,
        ),
        Category.fromJson,
      );
    } finally {
      if (identical(
        _findCancelToken,
        token,
      )) {
        _findCancelToken = null;
      }
    }
  }

  @override
  Future<List<Category>> all() async {
    if (_cacheIsValid) {
      return [..._cache!];
    }

    final response =
        await _api.get(
      '/categories',
      queryParameters: {
        'page': 1,
        'size': 100,
        'includeDeleted': 'true',
        'sort': 'name,asc',
      },
    );

    final result =
        PageResult<Category>.fromJson(
      Map<String, dynamic>.from(
        response.data as Map,
      ),
      Category.fromJson,
    );

    _cache = result.items;
    _cacheTime = DateTime.now();

    return [...result.items];
  }

  @override
  Future<Category?> findById(
    int id,
  ) async {
    try {
      final response =
          await _api.get(
        '/categories/$id',
        queryParameters: {
          'includeDeleted': 'true',
        },
      );

      return Category.fromJson(
        Map<String, dynamic>.from(
          response.data as Map,
        ),
      );
    } on NotFoundException {
      return null;
    }
  }

  @override
  Future<Category> create(
    Category category,
  ) {
    return _auth.authorized(
      () async {
        final response =
            await _api.post(
          '/categories',
          data: category.toJson(),
        );

        _clearCache();

        return Category.fromJson(
          Map<String, dynamic>.from(
            response.data as Map,
          ),
        );
      },
    );
  }

  @override
  Future<void> update(
    Category category,
  ) {
    return _auth.authorized(
      () async {
        await _api.put(
          '/categories/${category.id}',
          data: category.toJson(),
        );

        _clearCache();
      },
    );
  }

  @override
  Future<void> softDelete(
    int id,
  ) {
    return _auth.authorized(
      () async {
        await _api.delete(
          '/categories/$id',
        );

        _clearCache();
      },
    );
  }

  @override
  Future<void> hardDelete(
    int id,
  ) {
    return _auth.authorized(
      () async {
        await _api.delete(
          '/categories/$id',
          queryParameters: {
            'hard': 'true',
          },
        );

        _clearCache();
      },
    );
  }

  @override
  Future<void> restore(
    int id,
  ) {
    return _auth.authorized(
      () async {
        await _api.post(
          '/categories/$id/restore',
        );

        _clearCache();
      },
    );
  }

  @override
  Future<int> deleteMany(
    List<int> ids,
  ) {
    return _auth.authorized(
      () async {
        final response =
            await _api.post(
          '/categories/bulk-delete',
          data: {
            'ids': ids,
          },
        );

        _clearCache();

        return (response
                    .data['deleted']
                as num?)
            ?.toInt() ??
            0;
      },
    );
  }
}