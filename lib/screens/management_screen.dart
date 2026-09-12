import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class ManagementScreen
    extends StatelessWidget {
  const ManagementScreen({
    super.key,
  });

  Widget _button(
    BuildContext context,
    String text,
    String route,
  ) {
    return SizedBox(
      width: 260,
      height: 55,

      child: FilledButton(
        onPressed: () {
          context.go(route);
        },

        child: Text(text),
      ),
    );
  }

  @override
  Widget build(
    BuildContext context,
  ) {
    return Scaffold(
      appBar: AppBar(
        title:
            const Text(
          'Панель управления',
        ),
      ),

      body: Center(
        child: Wrap(
          spacing: 16,
          runSpacing: 16,

          children: [
            _button(
              context,
              'Управление товарами',
              '/products',
            ),

            _button(
              context,
              'Управление животными',
              '/animals',
            ),

            _button(
              context,
              'Категории',
              '/categories',
            ),

            _button(
              context,
              'Поставщики',
              '/suppliers',
            ),

            _button(
              context,
              'Покупатели',
              '/customers',
            ),
          ],
        ),
      ),
    );
  }
}