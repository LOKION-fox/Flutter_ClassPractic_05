import 'package:dio/dio.dart';

import '../core/api_client.dart';
import '../core/api_exceptions.dart';
import '../core/auth_service.dart';
import '../models/animal.dart';
import '../models/animal_query.dart';
import '../models/page_result.dart';
import 'animal_repository.dart';

class ApiAnimalRepository implements AnimalRepository {
  final ApiClient _api;
  final AuthService _auth;

  CancelToken? _findCancelToken;

  ApiAnimalRepository(
    this._api,
    this._auth,
  );

  @override
  Future<PageResult<Animal>> find(
    AnimalQuery query,
  ) async {
    _findCancelToken?.cancel(
      'Запущен новый запрос',
    );

    final token = CancelToken();

    _findCancelToken = token;

    try {
      final response = await _api.get(
        '/animals',
        queryParameters: query.toApiQueryParameters(),
        cancelToken: token,
      );

      return PageResult<Animal>.fromJson(
        Map<String, dynamic>.from(
          response.data as Map,
        ),
        Animal.fromJson,
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
  Future<List<Animal>> all() async {
    final response = await _api.get(
      '/animals',
      queryParameters: {
        'page': 1,
        'size': 100,
        'includeDeleted': 'true',
      },
    );

    return PageResult<Animal>.fromJson(
      Map<String, dynamic>.from(
        response.data as Map,
      ),
      Animal.fromJson,
    ).items;
  }

  @override
  Future<Animal?> findById(
    int id,
  ) async {
    try {
      final response = await _api.get(
        '/animals/$id',
        queryParameters: {
          'includeDeleted': 'true',
        },
      );

      return Animal.fromJson(
        Map<String, dynamic>.from(
          response.data as Map,
        ),
      );
    } on NotFoundException {
      return null;
    }
  }

  @override
  Future<Animal> create(
    Animal animal,
  ) {
    return _auth.authorized(
      () async {
        final response = await _api.post(
          '/animals',
          data: animal.toJson(),
        );

        return Animal.fromJson(
          Map<String, dynamic>.from(
            response.data as Map,
          ),
        );
      },
    );
  }

  @override
  Future<void> update(
    Animal animal,
  ) {
    return _auth.authorized(
      () async {
        await _api.put(
          '/animals/${animal.id}',
          data: animal.toJson(),
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
          '/animals/$id',
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
          '/animals/$id',
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
          '/animals/$id/restore',
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
          '/animals/bulk-delete',
          data: {
            'ids': ids,
          },
        );

        return (response.data['deleted'] as num?)?.toInt() ?? 0;
      },
    );
  }
}
