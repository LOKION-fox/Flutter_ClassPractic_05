import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../models/customer.dart';
import '../state/customer_list_notifier.dart';

class CustomerDetailsScreen extends StatelessWidget {
  final int id;

  const CustomerDetailsScreen({
    super.key,
    required this.id,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Покупатель'),
      ),
      body: FutureBuilder<Customer?>(
        future: context.read<CustomerListNotifier>().findById(id),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          if (snapshot.hasError) {
            return Center(
              child: Text(
                'Ошибка загрузки: ${snapshot.error}',
              ),
            );
          }

          final value = snapshot.data;

          if (value == null) {
            return const Center(
              child: Text(
                'Запись не найдена',
              ),
            );
          }

          return ListView(
            padding: const EdgeInsets.all(
              24,
            ),
            children: [
              Text(
                value.fullName,
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              const SizedBox(
                height: 16,
              ),
              Text(
                'Email: ${value.email}',
              ),
              Text(
                'Телефон: ${value.phone}',
              ),
              const SizedBox(
                height: 20,
              ),
              const Text(
                'Карта лояльности',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                'Номер: ${value.loyaltyCard.number}',
              ),
              Text(
                'Уровень: ${value.loyaltyCard.level}',
              ),
              Text(
                'Баллы: ${value.loyaltyCard.points}',
              ),
              const SizedBox(
                height: 20,
              ),
              if (!value.isDeleted)
                FilledButton(
                  onPressed: () {
                    context.push(
                      '/customers/$id/edit',
                    );
                  },
                  child: const Text(
                    'Редактировать',
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}
