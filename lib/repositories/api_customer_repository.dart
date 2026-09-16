import 'package:dio/dio.dart';

import '../core/api_client.dart';
import '../core/api_exceptions.dart';
import '../core/auth_service.dart';
import '../models/customer.dart';
import '../models/page_result.dart';
import '../models/simple_query.dart';
import 'customer_repository.dart';

class ApiCustomerRepository implements CustomerRepository {
  final ApiClient _api;
  final AuthService _auth;

  CancelToken? _findCancelToken;

  ApiCustomerRepository(
    this._api,
    this._auth,
  );

  @override
  Future<PageResult<Customer>> find(
    SimpleQuery query,
  ) async {
    _findCancelToken?.cancel();

    final token = CancelToken();

    _findCancelToken = token;

    try {
      final response = await _api.get(
        '/customers',
        queryParameters: query.toApiQueryParameters(
          filterParam: 'level',
        ),
        cancelToken: token,
      );

      return PageResult<Customer>.fromJson(
        Map<String, dynamic>.from(
          response.data as Map,
        ),
        Customer.fromJson,
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
  Future<List<Customer>> all() async {
    final response = await _api.get(
      '/customers',
      queryParameters: {
        'page': 1,
        'size': 100,
        'includeDeleted': 'true',
      },
    );

    return PageResult<Customer>.fromJson(
      Map<String, dynamic>.from(
        response.data as Map,
      ),
      Customer.fromJson,
    ).items;
  }

  @override
  Future<Customer?> findById(
    int id,
  ) async {
    try {
      final response = await _api.get(
        '/customers/$id',
        queryParameters: {
          'includeDeleted': 'true',
        },
      );

      return Customer.fromJson(
        Map<String, dynamic>.from(
          response.data as Map,
        ),
      );
    } on NotFoundException {
      return null;
    }
  }

  @override
  Future<Customer> create(
    Customer customer,
  ) {
    return _auth.authorized(
      () async {
        final response = await _api.post(
          '/customers',
          data: customer.toJson(),
        );

        return Customer.fromJson(
          Map<String, dynamic>.from(
            response.data as Map,
          ),
        );
      },
    );
  }

  @override
  Future<void> update(
    Customer customer,
  ) {
    return _auth.authorized(
      () async {
        await _api.put(
          '/customers/${customer.id}',
          data: customer.toJson(),
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
          '/customers/$id',
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
          '/customers/$id',
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
          '/customers/$id/restore',
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
          '/customers/bulk-delete',
          data: {
            'ids': ids,
          },
        );

        return (response.data['deleted'] as num?)?.toInt() ?? 0;
      },
    );
  }
}
