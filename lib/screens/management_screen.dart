import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class ManagementScreen extends StatelessWidget {
  const ManagementScreen({
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
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Панель управления',
        ),
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(
            24,
          ),
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              maxWidth: 1000,
            ),
            child: LayoutBuilder(
              builder: (
                context,
                constraints,
              ) {
                const spacing = 16.0;

                final columns = constraints.maxWidth < 600 ? 1 : 2;

                final width =
                    (constraints.maxWidth - spacing * (columns - 1)) / columns;

                return Wrap(
                  spacing: spacing,
                  runSpacing: spacing,
                  children: [
                    _button(
                      context,
                      'Управление товарами',
                      '/products',
                      Icons.shopping_bag,
                      width,
                    ),
                    _button(
                      context,
                      'Управление животными',
                      '/animals',
                      Icons.pets,
                      width,
                    ),
                    _button(
                      context,
                      'Категории',
                      '/categories',
                      Icons.category,
                      width,
                    ),
                    _button(
                      context,
                      'Поставщики',
                      '/suppliers',
                      Icons.local_shipping,
                      width,
                    ),
                    _button(
                      context,
                      'Покупатели',
                      '/customers',
                      Icons.people,
                      width,
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
