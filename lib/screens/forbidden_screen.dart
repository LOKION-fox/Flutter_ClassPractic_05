import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class ForbiddenScreen extends StatelessWidget {
  const ForbiddenScreen({
    super.key,
  });

  @override
  Widget build(
    BuildContext context,
  ) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Доступ запрещён'),
      ),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.lock,
              size: 80,
            ),
            const SizedBox(
              height: 16,
            ),
            const Text(
              '403',
              style: TextStyle(
                fontSize: 48,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(
              height: 8,
            ),
            const Text(
              'У вашей роли нет доступа '
              'к этому разделу.',
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
    );
  }
}
