import 'package:flutter/material.dart';
import 'package:flutter_web_plugins/url_strategy.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'core/api_client.dart';
import 'core/api_config.dart';
import 'core/auth_service.dart';
import 'core/auth_session.dart';

import 'repositories/animal_repository.dart';
import 'repositories/api_animal_repository.dart';
import 'repositories/api_category_repository.dart';
import 'repositories/api_customer_repository.dart';
import 'repositories/api_product_repository.dart';
import 'repositories/api_supplier_repository.dart';
import 'repositories/api_user_admin_repository.dart';
import 'repositories/category_repository.dart';
import 'repositories/customer_repository.dart';
import 'repositories/product_repository.dart';
import 'repositories/supplier_repository.dart';
import 'repositories/user_admin_repository.dart';

import 'router.dart';

import 'state/animal_list_notifier.dart';
import 'state/auth_notifier.dart';
import 'state/category_list_notifier.dart';
import 'state/customer_list_notifier.dart';
import 'state/product_list_notifier.dart';
import 'state/supplier_list_notifier.dart';
import 'state/user_admin_notifier.dart';

import 'widgets/session_watcher.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  usePathUrlStrategy();

  final prefs = await SharedPreferences.getInstance();

  final session = AuthSession();

  final apiClient = ApiClient(
    baseUrl: ApiConfig.baseUrl,
    session: session,
  );

  final authService = AuthService(
    apiClient,
    session,
  );

  final authNotifier = AuthNotifier(
    prefs,
    authService,
    session,
  );

  // При 401 ApiClient просит
  // AuthNotifier обновить токен.
  apiClient.onRefreshRequested = authNotifier.refreshTokens;

  // Если обновить токен не удалось,
  // завершаем сессию.
  apiClient.onSessionExpired = () {
    return authNotifier.forceLogout(
      'Сессия истекла. '
      'Войдите снова.',
    );
  };

  // Восстанавливаем токены после F5.
  await authNotifier.restore();

  final productRepository = ApiProductRepository(
    apiClient,
    authService,
  );

  final animalRepository = ApiAnimalRepository(
    apiClient,
    authService,
  );

  final categoryRepository = ApiCategoryRepository(
    apiClient,
    authService,
  );

  final supplierRepository = ApiSupplierRepository(
    apiClient,
    authService,
  );

  final customerRepository = ApiCustomerRepository(
    apiClient,
    authService,
  );

  final userAdminRepository = ApiUserAdminRepository(
    apiClient,
    authService,
  );

  final router = buildRouter(
    authNotifier,
  );

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider<AuthNotifier>.value(
          value: authNotifier,
        ),
        Provider<ApiClient>.value(
          value: apiClient,
        ),
        Provider<AuthService>.value(
          value: authService,
        ),
        Provider<ProductRepository>.value(
          value: productRepository,
        ),
        Provider<AnimalRepository>.value(
          value: animalRepository,
        ),
        Provider<CategoryRepository>.value(
          value: categoryRepository,
        ),
        Provider<SupplierRepository>.value(
          value: supplierRepository,
        ),
        Provider<CustomerRepository>.value(
          value: customerRepository,
        ),
        Provider<UserAdminRepository>.value(
          value: userAdminRepository,
        ),
        ChangeNotifierProvider(
          create: (_) => ProductListNotifier(
            productRepository,
          ),
        ),
        ChangeNotifierProvider(
          create: (_) => AnimalListNotifier(
            animalRepository,
          ),
        ),
        ChangeNotifierProvider(
          create: (_) => CategoryListNotifier(
            categoryRepository,
          ),
        ),
        ChangeNotifierProvider(
          create: (_) => SupplierListNotifier(
            supplierRepository,
          ),
        ),
        ChangeNotifierProvider(
          create: (_) => CustomerListNotifier(
            customerRepository,
          ),
        ),
        ChangeNotifierProvider(
          create: (_) => UserAdminNotifier(
            userAdminRepository,
          ),
        ),
      ],
      child: PetShopApp(
        router: router,
        auth: authNotifier,
      ),
    ),
  );
}

class PetShopApp extends StatelessWidget {
  final RouterConfig<Object> router;

  final AuthNotifier auth;

  const PetShopApp({
    super.key,
    required this.router,
    required this.auth,
  });

  @override
  Widget build(
    BuildContext context,
  ) {
    return MaterialApp.router(
      title: 'Зоомагазин',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.teal,
        ),
        useMaterial3: true,
      ),
      routerConfig: router,
      builder: (context, child) {
        return SessionWatcher(
          auth: auth,
          child: child ?? const SizedBox(),
        );
      },
    );
  }
}
