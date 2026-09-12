import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../models/app_role.dart';
import '../state/auth_notifier.dart';

class HomeScreen
    extends StatelessWidget {
  const HomeScreen({
    super.key,
  });

  Widget _button(
    BuildContext context,
    String text,
    String route,
    IconData icon,
  ) {
    return SizedBox(
      width: 250,
      height: 60,

      child: FilledButton.icon(
        onPressed: () {
          context.go(route);
        },

        icon: Icon(icon),

        label: Text(text),
      ),
    );
  }

  @override
  Widget build(
    BuildContext context,
  ) {
    final auth =
        context.watch<
            AuthNotifier>();

    final role =
        auth.uiRole;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Зоомагазин — '
          '${auth.user?.fullName ?? ''}',
        ),

        actions: [
          Padding(
            padding:
                const EdgeInsets
                    .symmetric(
              horizontal: 12,
            ),

            child: Center(
              child: Text(
                role?.title ?? '',
              ),
            ),
          ),

          IconButton(
            tooltip: 'Выйти',

            onPressed: () async {
              await auth.logout();
            },

            icon: const Icon(
              Icons.logout,
            ),
          ),
        ],
      ),

      body: Center(
        child:
            SingleChildScrollView(
          padding:
              const EdgeInsets.all(
            24,
          ),

          child: Wrap(
            spacing: 16,
            runSpacing: 16,

            alignment:
                WrapAlignment.center,

            children: [
              _button(
                context,
                'Товары',
                '/products',
                Icons.shopping_bag,
              ),

              _button(
                context,
                'Животные',
                '/animals',
                Icons.pets,
              ),

              if (role ==
                  AppRole.customer)
                _button(
                  context,
                  'Мой кабинет',
                  '/account',
                  Icons.person,
                ),

              if (role ==
                      AppRole.manager ||
                  role ==
                      AppRole.admin)
                _button(
                  context,
                  'Панель управления',
                  '/management',
                  Icons.store,
                ),

              if (role ==
                  AppRole.admin) ...[
                _button(
                  context,
                  'Пользователи',
                  '/admin/users',
                  Icons.manage_accounts,
                ),

                _button(
                  context,
                  'Статистика',
                  '/admin/stats',
                  Icons.bar_chart,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}