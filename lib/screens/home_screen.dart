import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../models/app_role.dart';
import '../state/auth_notifier.dart';
import '../widgets/permission_gate.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({
    super.key,
  });

  Widget _button(
    BuildContext context,
    String text,
    String route,
    IconData icon,
    double width,
  ) {
    return SizedBox(
      width: width,
      height: 64,
      child: FilledButton.icon(
        onPressed: () {
          context.go(route);
        },
        icon: Icon(icon),
        label: Text(
          text,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          textAlign: TextAlign.center,
        ),
      ),
    );
  }

  @override
  Widget build(
    BuildContext context,
  ) {
    final auth = context.watch<AuthNotifier>();

    final role = auth.uiRole;

    final screenWidth = MediaQuery.sizeOf(
      context,
    ).width;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Зоомагазин — '
          '${auth.user?.fullName ?? ''}',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        actions: [
          if (screenWidth >= 600)
            Padding(
              padding: const EdgeInsets.symmetric(
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
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(
            24,
          ),
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              maxWidth: 1100,
            ),
            child: LayoutBuilder(
              builder: (
                context,
                constraints,
              ) {
                const spacing = 16.0;

                final columns = constraints.maxWidth < 600
                    ? 1
                    : constraints.maxWidth < 1000
                        ? 2
                        : 3;

                final buttonWidth =
                    (constraints.maxWidth - spacing * (columns - 1)) / columns;

                return Wrap(
                  spacing: spacing,
                  runSpacing: spacing,
                  alignment: WrapAlignment.center,
                  children: [
                    _button(
                      context,
                      'Товары',
                      '/products',
                      Icons.shopping_bag,
                      buttonWidth,
                    ),
                    _button(
                      context,
                      'Животные',
                      '/animals',
                      Icons.pets,
                      buttonWidth,
                    ),
                    PermissionGate(
                      allowed: role == AppRole.customer,
                      child: _button(
                        context,
                        'Мой кабинет',
                        '/account',
                        Icons.person,
                        buttonWidth,
                      ),
                    ),
                    PermissionGate(
                      allowed: role == AppRole.manager || role == AppRole.admin,
                      child: _button(
                        context,
                        'Панель управления',
                        '/management',
                        Icons.store,
                        buttonWidth,
                      ),
                    ),
                    PermissionGate(
                      allowed: role == AppRole.admin,
                      child: _button(
                        context,
                        'Пользователи',
                        '/admin/users',
                        Icons.manage_accounts,
                        buttonWidth,
                      ),
                    ),
                    PermissionGate(
                      allowed: role == AppRole.admin,
                      child: _button(
                        context,
                        'Статистика',
                        '/admin/stats',
                        Icons.bar_chart,
                        buttonWidth,
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}
