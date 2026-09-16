import 'package:dio/dio.dart';

import '../core/api_client.dart';
import '../core/api_config.dart';
import '../core/api_exceptions.dart';
import '../core/auth_service.dart';
import '../models/page_result.dart';
import '../models/product.dart';
import '../models/product_query.dart';
import 'product_repository.dart';

class ApiProductRepository implements ProductRepository {
  final ApiClient _api;
  final AuthService _auth;

  CancelToken? _findCancelToken;

  ApiProductRepository(
    this._api,
    this._auth,
  );

  Map<String, dynamic> _listParameters(
    ProductQuery query,
  ) {
    final params = query.toApiQueryParameters();

    if (ApiConfig.apiDelayMs > 0) {
      params['__delay'] = ApiConfig.apiDelayMs;
    }

    if (ApiConfig.apiFailCode > 0) {
      params['__fail'] = ApiConfig.apiFailCode;
    }

    return params;
  }

  @override
  Future<PageResult<Product>> find(
    ProductQuery query,
  ) async {
    _findCancelToken?.cancel(
      'Запущен новый запрос',
    );

    final token = CancelToken();

    _findCancelToken = token;

    try {
      final response = await _api.get(
        '/products',
        queryParameters: _listParameters(query),
        cancelToken: token,
      );

      return PageResult<Product>.fromJson(
        Map<String, dynamic>.from(
          response.data as Map,
        ),
        Product.fromJson,
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
  Future<List<Product>> all() async {
    final response = await _api.get(
      '/products',
      queryParameters: {
        'page': 1,
        'size': 100,
        'includeDeleted': 'true',
      },
    );

    final page = PageResult<Product>.fromJson(
      Map<String, dynamic>.from(
        response.data as Map,
      ),
      Product.fromJson,
    );

    return page.items;
  }

  @override
  Future<Product?> findById(
    int id,
  ) async {
    try {
      final response = await _api.get(
        '/products/$id',
        queryParameters: {
          'includeDeleted': 'true',
        },
      );

      return Product.fromJson(
        Map<String, dynamic>.from(
          response.data as Map,
        ),
      );
    } on NotFoundException {
      return null;
    }
  }

  @override
  Future<Product> create(
    Product product,
  ) {
    return _auth.authorized(
      () async {
        final response = await _api.post(
          '/products',
          data: product.toJson(),
        );

        return Product.fromJson(
          Map<String, dynamic>.from(
            response.data as Map,
          ),
        );
      },
    );
  }

  @override
  Future<void> update(
    Product product,
  ) {
    return _auth.authorized(
      () async {
        await _api.put(
          '/products/${product.id}',
          data: product.toJson(),
        );
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
          '/products/$id',
        );
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
          '/products/$id',
          queryParameters: {
            'hard': 'true',
          },
        );
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
          '/products/$id/restore',
        );
      },
    );
  }

  @override
  Future<int> deleteMany(
    List<int> ids,
  ) {
    return _auth.authorized(
      () async {
        final response = await _api.post(
          '/products/bulk-delete',
          data: {
            'ids': ids,
          },
        );

        final data = Map<String, dynamic>.from(
          response.data as Map,
        );

        return (data['deleted'] as num?)?.toInt() ?? 0;
      },
    );
  }
}
