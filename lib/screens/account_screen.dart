import 'package:flutter/material.dart';
import 'package:pet_shop_web/models/app_role.dart';
import 'package:provider/provider.dart';

import '../state/auth_notifier.dart';

class AccountScreen extends StatelessWidget {
  const AccountScreen({
    super.key,
  });

  @override
  Widget build(
    BuildContext context,
  ) {
    final auth = context.watch<AuthNotifier>();

    final user = auth.user;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Мой кабинет'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Card(
          child: Padding(
            padding: const EdgeInsets.all(
              24,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  user?.fullName ?? 'Пользователь',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(
                  height: 12,
                ),
                Text(
                  'Логин: '
                  '${user?.username ?? ''}',
                ),
                Text(
                  'Роль сервера: '
                  '${user?.role.title ?? ''}',
                ),
                const SizedBox(
                  height: 16,
                ),
                const Text(
                  'Покупатель может просматривать '
                  'каталог товаров и животных.',
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
