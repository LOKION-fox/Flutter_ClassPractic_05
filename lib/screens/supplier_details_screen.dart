import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../models/supplier.dart';
import '../state/supplier_list_notifier.dart';

class SupplierDetailsScreen extends StatelessWidget {
  final int id;

  const SupplierDetailsScreen({
    super.key,
    required this.id,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Поставщик'),
      ),
      body: FutureBuilder<Supplier?>(
        future: context.read<SupplierListNotifier>().findById(id),
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
                value.name,
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              const SizedBox(
                height: 16,
              ),
              Text(
                'Страна: ${value.country}',
              ),
              Text(
                'Email: ${value.email}',
              ),
              Text(
                'Категорий: ${value.allowedCategoryIds.length}',
              ),
              const SizedBox(
                height: 20,
              ),
              if (!value.isDeleted)
                FilledButton(
                  onPressed: () {
                    context.push(
                      '/suppliers/$id/edit',
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
