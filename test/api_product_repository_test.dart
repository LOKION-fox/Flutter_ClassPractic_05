import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http_mock_adapter/http_mock_adapter.dart';

import 'package:pet_shop_web/core/api_client.dart';
import 'package:pet_shop_web/core/api_exceptions.dart';
import 'package:pet_shop_web/core/auth_service.dart';
import 'package:pet_shop_web/core/auth_session.dart';
import 'package:pet_shop_web/models/product.dart';
import 'package:pet_shop_web/models/product_query.dart';
import 'package:pet_shop_web/repositories/api_product_repository.dart';

void main() {
  late Dio dio;
  late DioAdapter adapter;

  late AuthSession session;
  late ApiClient apiClient;
  late AuthService authService;

  late ApiProductRepository repository;

  setUp(() {
    dio = Dio(
      BaseOptions(
        baseUrl:
            'http://localhost:8080/api',
      ),
    );

    adapter = DioAdapter(
      dio: dio,
    );

    session = AuthSession();

    // Для тестов считаем,
    // что пользователь уже вошёл.
    session.accessToken =
        'test-token';

    apiClient = ApiClient(
      baseUrl:
          'http://localhost:8080/api',
      session: session,
      dio: dio,
    );

    authService = AuthService(
      apiClient,
      session,
    );

    repository =
        ApiProductRepository(
      apiClient,
      authService,
    );
  });

  test(
    'GET возвращает страницу товаров',
    () async {
      adapter.onGet(
        '/products',
        (server) => server.reply(
          200,
          {
            'items': [
              {
                'id': 1,
                'name': 'Корм',
                'article': 'TEST-1',
                'brand': 'Test',
                'price': 1000,
                'stock': 5,
                'supplier': {
                  'id': 1,
                  'name': 'Поставщик',
                },
                'categories': [
                  {
                    'id': 1,
                    'name': 'Корм',
                  },
                ],
                'description':
                    'Описание',
                'deletedAt': null,
              },
            ],
            'page': 1,
            'size': 10,
            'total': 1,
            'totalPages': 1,
          },
        ),
      );

      final result =
          await repository.find(
        const ProductQuery(),
      );

      expect(
        result.total,
        1,
      );

      expect(
        result.items.length,
        1,
      );

      expect(
        result.items.first.name,
        'Корм',
      );
    },
  );

  test(
    'Product правильно получает связи из JSON',
    () async {
      adapter.onGet(
        '/products/1',
        (server) => server.reply(
          200,
          {
            'id': 1,
            'name': 'Игрушка',
            'article': 'T-1',
            'brand': 'Trixie',
            'price': 500,
            'stock': 3,
            'supplier': {
              'id': 7,
              'name': 'ЗооОпт',
            },
            'categories': [
              {
                'id': 2,
                'name': 'Игрушки',
              },
            ],
            'description':
                'Описание',
            'deletedAt': null,
          },
        ),
      );

      final product =
          await repository.findById(
        1,
      );

      expect(
        product,
        isNotNull,
      );

      expect(
        product!.supplierId,
        7,
      );

      expect(
        product.categoryIds,
        [2],
      );
    },
  );

  test(
    'POST создаёт товар',
    () async {
      const product = Product(
        id: 0,
        name: 'Новый товар',
        article: 'NEW-001',
        brand: 'Brand',
        price: 900,
        stock: 10,
        supplierId: 1,
        categoryIds: [1],
        description: 'Описание',
      );

      adapter.onPost(
        '/products',
        (server) => server.reply(
          201,
          {
            'id': 25,
            'name': 'Новый товар',
            'article': 'NEW-001',
            'brand': 'Brand',
            'price': 900,
            'stock': 10,
            'supplier': {
              'id': 1,
              'name': 'ЗооОпт',
            },
            'categories': [
              {
                'id': 1,
                'name': 'Корм',
              },
            ],
            'description':
                'Описание',
            'deletedAt': null,
          },
        ),

        // ВАЖНО:
        // мок должен знать тело POST.
        data: product.toJson(),
      );

      final created =
          await repository.create(
        product,
      );

      expect(
        created.id,
        25,
      );

      expect(
        created.article,
        'NEW-001',
      );
    },
  );

  test(
    '422 превращается в ValidationException',
    () async {
      const product = Product(
        id: 0,
        name: 'Товар',
        article: 'RC-001',
        brand: 'Brand',
        price: 1000,
        stock: 1,
        supplierId: 1,
        categoryIds: [1],
        description: 'Описание',
      );

      adapter.onPost(
        '/products',
        (server) => server.reply(
          422,
          {
            'message':
                'Ошибка валидации',
            'errors': {
              'article':
                  'Товар с таким артикулом уже существует',
            },
          },
        ),

        // Реальный repository отправляет
        // именно product.toJson().
        data: product.toJson(),
      );

      try {
        await repository.create(
          product,
        );

        fail(
          'Ожидалась ValidationException',
        );
      } on ValidationException catch (e) {
        expect(
          e.errors['article'],
          'Товар с таким артикулом уже существует',
        );
      }
    },
  );

  test(
    '409 превращается в ConflictException',
    () async {
      adapter.onDelete(
        '/products/1',
        (server) => server.reply(
          409,
          {
            'message':
                'Запись связана с другими данными',
          },
        ),

        queryParameters: {
          'hard': 'true',
        },
      );

      expect(
        repository.hardDelete(1),
        throwsA(
          isA<ConflictException>(),
        ),
      );
    },
  );

  test(
    'bulk delete возвращает число удалённых',
    () async {
      const ids = [
        1,
        2,
        3,
      ];

      adapter.onPost(
        '/products/bulk-delete',
        (server) => server.reply(
          200,
          {
            'deleted': 3,
          },
        ),

        // bulk-delete тоже отправляет
        // тело POST.
        data: {
          'ids': ids,
        },
      );

      final count =
          await repository.deleteMany(
        ids,
      );

      expect(
        count,
        3,
      );
    },
  );
}