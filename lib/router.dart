import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'models/animal_query.dart';
import 'models/app_role.dart';
import 'models/product_query.dart';
import 'models/simple_query.dart';

import 'screens/account_screen.dart';
import 'screens/admin_stats_screen.dart'
    deferred as admin_stats_screen;
import 'screens/admin_users_screen.dart'
    deferred as admin_users_screen;
import 'screens/animal_details_screen.dart';
import 'screens/animal_form_screen.dart';
import 'screens/animal_list_screen.dart';
import 'screens/category_details_screen.dart';
import 'screens/category_form_screen.dart';
import 'screens/category_list_screen.dart';
import 'screens/customer_details_screen.dart';
import 'screens/customer_form_screen.dart';
import 'screens/customer_list_screen.dart';
import 'screens/forbidden_screen.dart';
import 'screens/home_screen.dart';
import 'screens/login_screen.dart';
import 'screens/management_screen.dart';
import 'screens/product_details_screen.dart';
import 'screens/product_form_screen.dart';
import 'screens/product_list_screen.dart';
import 'screens/register_screen.dart';
import 'screens/supplier_details_screen.dart';
import 'screens/supplier_form_screen.dart';
import 'screens/supplier_list_screen.dart';

import 'state/auth_notifier.dart';

import 'widgets/adaptive_app_shell.dart';
import 'widgets/deferred_screen.dart';

GoRouter buildRouter(
  AuthNotifier auth,
) {
  String? requirePermission(
    AppPermission permission,
  ) {
    return auth.can(permission)
        ? null
        : '/forbidden';
  }

  int parseId(
    GoRouterState state,
  ) {
    return int.tryParse(
          state.pathParameters['id'] ?? '',
        ) ??
        -1;
  }

  return GoRouter(
    refreshListenable: auth,
    initialLocation: '/',

    redirect: (
      context,
      state,
    ) {
      final loggedIn =
          auth.isAuthenticated;

      final target =
          state.matchedLocation;

      final public =
          target == '/login' ||
          target == '/register';

      if (!loggedIn &&
          !public) {
        final from =
            Uri.encodeComponent(
          state.uri.toString(),
        );

        return '/login?from=$from';
      }

      if (loggedIn &&
          public) {
        return '/';
      }

      return null;
    },

    routes: [
      // ======================================================
      // PUBLIC
      // ======================================================

      GoRoute(
        path: '/login',

        builder: (
          context,
          state,
        ) {
          return LoginScreen(
            from:
                state.uri.queryParameters[
              'from'
            ],
          );
        },
      ),

      GoRoute(
        path: '/register',

        builder: (
          context,
          state,
        ) {
          return const RegisterScreen();
        },
      ),

      // ======================================================
      // AUTHORIZED APPLICATION
      // ======================================================

      ShellRoute(
        builder: (
          context,
          state,
          child,
        ) {
          return AdaptiveAppShell(
            currentLocation:
                state.uri.path,

            child: child,
          );
        },

        routes: [
          // ==================================================
          // FORBIDDEN
          // ==================================================

          GoRoute(
            path: '/forbidden',

            builder: (
              context,
              state,
            ) {
              return const ForbiddenScreen();
            },
          ),

          // ==================================================
          // HOME
          // ==================================================

          GoRoute(
            path: '/',

            builder: (
              context,
              state,
            ) {
              return const HomeScreen();
            },
          ),

          // ==================================================
          // ACCOUNT
          // ==================================================

          GoRoute(
            path: '/account',

            redirect: (
              context,
              state,
            ) {
              return auth.isUiRole(
                AppRole.customer,
              )
                  ? null
                  : '/forbidden';
            },

            builder: (
              context,
              state,
            ) {
              return const AccountScreen();
            },
          ),

          // ==================================================
          // MANAGEMENT
          // ==================================================

          GoRoute(
            path: '/management',

            redirect: (
              context,
              state,
            ) {
              final allowed =
                  auth.isUiRole(
                    AppRole.manager,
                  ) ||
                  auth.isUiRole(
                    AppRole.admin,
                  );

              return allowed
                  ? null
                  : '/forbidden';
            },

            builder: (
              context,
              state,
            ) {
              return const ManagementScreen();
            },
          ),

          // ==================================================
          // ADMIN USERS
          // ==================================================

          GoRoute(
            path: '/admin/users',

            redirect: (
              context,
              state,
            ) {
              return requirePermission(
                AppPermission.manageUsers,
              );
            },

            builder: (
              context,
              state,
            ) {
              return DeferredScreen(
                loadLibrary:
                    admin_users_screen
                        .loadLibrary,

                builder: () {
                  // Важно:
                  // deferred-библиотека
                  // не используется через const.
                  return admin_users_screen
                      .AdminUsersScreen();
                },
              );
            },
          ),

          // ==================================================
          // ADMIN STATISTICS
          // ==================================================

          GoRoute(
            path: '/admin/stats',

            redirect: (
              context,
              state,
            ) {
              return requirePermission(
                AppPermission
                    .viewStatistics,
              );
            },

            builder: (
              context,
              state,
            ) {
              return DeferredScreen(
                loadLibrary:
                    admin_stats_screen
                        .loadLibrary,

                builder: () {
                  // Важно:
                  // deferred-библиотека
                  // не используется через const.
                  return admin_stats_screen
                      .AdminStatsScreen();
                },
              );
            },
          ),

          // ==================================================
          // PRODUCTS
          // ==================================================

          GoRoute(
            path: '/products',

            builder: (
              context,
              state,
            ) {
              return ProductListScreen(
                key: ValueKey(
                  state.uri.toString(),
                ),

                initialQuery:
                    ProductQuery.fromUri(
                  state.uri,
                ),
              );
            },
          ),

          GoRoute(
            path: '/products/new',

            redirect: (
              context,
              state,
            ) {
              return requirePermission(
                AppPermission
                    .manageCatalog,
              );
            },

            builder: (
              context,
              state,
            ) {
              return const ProductFormScreen();
            },
          ),

          GoRoute(
            path:
                '/products/:id/edit',

            redirect: (
              context,
              state,
            ) {
              return requirePermission(
                AppPermission
                    .manageCatalog,
              );
            },

            builder: (
              context,
              state,
            ) {
              return ProductFormScreen(
                id: parseId(state),
              );
            },
          ),

          GoRoute(
            path: '/products/:id',

            builder: (
              context,
              state,
            ) {
              return ProductDetailsScreen(
                id: parseId(state),
              );
            },
          ),

          // ==================================================
          // ANIMALS
          // ==================================================

          GoRoute(
            path: '/animals',

            builder: (
              context,
              state,
            ) {
              return AnimalListScreen(
                key: ValueKey(
                  state.uri.toString(),
                ),

                initialQuery:
                    AnimalQuery.fromUri(
                  state.uri,
                ),
              );
            },
          ),

          GoRoute(
            path: '/animals/new',

            redirect: (
              context,
              state,
            ) {
              return requirePermission(
                AppPermission
                    .manageCatalog,
              );
            },

            builder: (
              context,
              state,
            ) {
              return const AnimalFormScreen();
            },
          ),

          GoRoute(
            path:
                '/animals/:id/edit',

            redirect: (
              context,
              state,
            ) {
              return requirePermission(
                AppPermission
                    .manageCatalog,
              );
            },

            builder: (
              context,
              state,
            ) {
              return AnimalFormScreen(
                id: parseId(state),
              );
            },
          ),

          GoRoute(
            path: '/animals/:id',

            builder: (
              context,
              state,
            ) {
              return AnimalDetailsScreen(
                id: parseId(state),
              );
            },
          ),

          // ==================================================
          // CATEGORIES
          // ==================================================

          GoRoute(
            path: '/categories',

            redirect: (
              context,
              state,
            ) {
              return requirePermission(
                AppPermission
                    .manageReferences,
              );
            },

            builder: (
              context,
              state,
            ) {
              return CategoryListScreen(
                key: ValueKey(
                  state.uri.toString(),
                ),

                initialQuery:
                    SimpleQuery.fromUri(
                  state.uri,

                  filterParam: 'kind',

                  allowedSortFields: {
                    'name',
                    'kind',
                    'id',
                  },
                ),
              );
            },
          ),

          GoRoute(
            path: '/categories/new',

            redirect: (
              context,
              state,
            ) {
              return requirePermission(
                AppPermission
                    .manageReferences,
              );
            },

            builder: (
              context,
              state,
            ) {
              return const CategoryFormScreen();
            },
          ),

          GoRoute(
            path:
                '/categories/:id/edit',

            redirect: (
              context,
              state,
            ) {
              return requirePermission(
                AppPermission
                    .manageReferences,
              );
            },

            builder: (
              context,
              state,
            ) {
              return CategoryFormScreen(
                id: parseId(state),
              );
            },
          ),

          GoRoute(
            path: '/categories/:id',

            redirect: (
              context,
              state,
            ) {
              return requirePermission(
                AppPermission
                    .manageReferences,
              );
            },

            builder: (
              context,
              state,
            ) {
              return CategoryDetailsScreen(
                id: parseId(state),
              );
            },
          ),

          // ==================================================
          // SUPPLIERS
          // ==================================================

          GoRoute(
            path: '/suppliers',

            redirect: (
              context,
              state,
            ) {
              return requirePermission(
                AppPermission
                    .manageReferences,
              );
            },

            builder: (
              context,
              state,
            ) {
              return SupplierListScreen(
                key: ValueKey(
                  state.uri.toString(),
                ),

                initialQuery:
                    SimpleQuery.fromUri(
                  state.uri,

                  filterParam:
                      'country',

                  allowedSortFields: {
                    'name',
                    'country',
                    'id',
                  },
                ),
              );
            },
          ),

          GoRoute(
            path: '/suppliers/new',

            redirect: (
              context,
              state,
            ) {
              return requirePermission(
                AppPermission
                    .manageReferences,
              );
            },

            builder: (
              context,
              state,
            ) {
              return const SupplierFormScreen();
            },
          ),

          GoRoute(
            path:
                '/suppliers/:id/edit',

            redirect: (
              context,
              state,
            ) {
              return requirePermission(
                AppPermission
                    .manageReferences,
              );
            },

            builder: (
              context,
              state,
            ) {
              return SupplierFormScreen(
                id: parseId(state),
              );
            },
          ),

          GoRoute(
            path: '/suppliers/:id',

            redirect: (
              context,
              state,
            ) {
              return requirePermission(
                AppPermission
                    .manageReferences,
              );
            },

            builder: (
              context,
              state,
            ) {
              return SupplierDetailsScreen(
                id: parseId(state),
              );
            },
          ),

          // ==================================================
          // CUSTOMERS
          // ==================================================

          GoRoute(
            path: '/customers',

            redirect: (
              context,
              state,
            ) {
              return requirePermission(
                AppPermission
                    .manageCustomers,
              );
            },

            builder: (
              context,
              state,
            ) {
              return CustomerListScreen(
                key: ValueKey(
                  state.uri.toString(),
                ),

                initialQuery:
                    SimpleQuery.fromUri(
                  state.uri,

                  filterParam: 'level',

                  allowedSortFields: {
                    'lastName',
                    'email',
                    'points',
                  },

                  defaultSort:
                      'lastName',
                ),
              );
            },
          ),

          GoRoute(
            path: '/customers/new',

            redirect: (
              context,
              state,
            ) {
              return requirePermission(
                AppPermission
                    .manageCustomers,
              );
            },

            builder: (
              context,
              state,
            ) {
              return const CustomerFormScreen();
            },
          ),

          GoRoute(
            path:
                '/customers/:id/edit',

            redirect: (
              context,
              state,
            ) {
              return requirePermission(
                AppPermission
                    .manageCustomers,
              );
            },

            builder: (
              context,
              state,
            ) {
              return CustomerFormScreen(
                id: parseId(state),
              );
            },
          ),

          GoRoute(
            path: '/customers/:id',

            redirect: (
              context,
              state,
            ) {
              return requirePermission(
                AppPermission
                    .manageCustomers,
              );
            },

            builder: (
              context,
              state,
            ) {
              return CustomerDetailsScreen(
                id: parseId(state),
              );
            },
          ),
        ],
      ),
    ],

    // ========================================================
    // 404
    // ========================================================

    errorBuilder: (
      context,
      state,
    ) {
      return Scaffold(
        appBar: AppBar(
          title: const Text(
            'Ошибка 404',
          ),
        ),

        body: Center(
          child: Padding(
            padding:
                const EdgeInsets.all(
              24,
            ),

            child: Column(
              mainAxisSize:
                  MainAxisSize.min,

              children: [
                const Text(
                  '404',

                  style: TextStyle(
                    fontSize: 60,
                  ),
                ),

                const Text(
                  'Страница не найдена',
                ),

                const SizedBox(
                  height: 20,
                ),

                FilledButton(
                  onPressed: () {
                    context.go('/');
                  },

                  child: const Text(
                    'На главную',
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    },
  );
}