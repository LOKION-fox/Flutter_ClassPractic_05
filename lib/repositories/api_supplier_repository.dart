import 'package:dio/dio.dart';

import '../core/api_client.dart';
import '../core/api_exceptions.dart';
import '../core/auth_service.dart';
import '../models/page_result.dart';
import '../models/simple_query.dart';
import '../models/supplier.dart';
import 'supplier_repository.dart';

class ApiSupplierRepository
    implements SupplierRepository {
  final ApiClient _api;
  final AuthService _auth;

  CancelToken? _findCancelToken;

  List<Supplier>? _cache;
  DateTime? _cacheTime;

  ApiSupplierRepository(
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
  Future<PageResult<Supplier>> find(
    SimpleQuery query,
  ) async {
    _findCancelToken?.cancel();

    final token = CancelToken();

    _findCancelToken = token;

    try {
      final response =
          await _api.get(
        '/suppliers',
        queryParameters:
            query.toApiQueryParameters(
          filterParam: 'country',
        ),
        cancelToken: token,
      );

      return PageResult<Supplier>
          .fromJson(
        Map<String, dynamic>.from(
          response.data as Map,
        ),
        Supplier.fromJson,
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
  Future<List<Supplier>> all() async {
    if (_cacheIsValid) {
      return [..._cache!];
    }

    final response =
        await _api.get(
      '/suppliers',
      queryParameters: {
        'page': 1,
        'size': 100,
        'includeDeleted': 'true',
        'sort': 'name,asc',
      },
    );

    final result =
        PageResult<Supplier>.fromJson(
      Map<String, dynamic>.from(
        response.data as Map,
      ),
      Supplier.fromJson,
    );

    _cache = result.items;
    _cacheTime = DateTime.now();

    return [...result.items];
  }

  @override
  Future<Supplier?> findById(
    int id,
  ) async {
    try {
      final response =
          await _api.get(
        '/suppliers/$id',
        queryParameters: {
          'includeDeleted': 'true',
        },
      );

      return Supplier.fromJson(
        Map<String, dynamic>.from(
          response.data as Map,
        ),
      );
    } on NotFoundException {
      return null;
    }
  }

  @override
  Future<Supplier> create(
    Supplier supplier,
  ) {
    return _auth.authorized(
      () async {
        final response =
            await _api.post(
          '/suppliers',
          data: supplier.toJson(),
        );

        _clearCache();

        return Supplier.fromJson(
          Map<String, dynamic>.from(
            response.data as Map,
          ),
        );
      },
    );
  }

  @override
  Future<void> update(
    Supplier supplier,
  ) {
    return _auth.authorized(
      () async {
        await _api.put(
          '/suppliers/${supplier.id}',
          data: supplier.toJson(),
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
          '/suppliers/$id',
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
          '/suppliers/$id',
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
          '/suppliers/$id/restore',
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
          '/suppliers/bulk-delete',
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