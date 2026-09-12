import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../models/category.dart';
import '../state/category_list_notifier.dart';

class CategoryDetailsScreen
    extends StatelessWidget {
  final int id;

  const CategoryDetailsScreen({
    super.key,
    required this.id,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title:
            const Text('Категория'),
      ),
      body: FutureBuilder<Category?>(
        future: context
            .read<CategoryListNotifier>()
            .findById(id),
        builder: (context, snapshot) {
          if (snapshot.connectionState ==
              ConnectionState.waiting) {
            return const Center(
              child:
                  CircularProgressIndicator(),
            );
          }

          if (snapshot.hasError) {
            return Center(
              child: Text(
                'Ошибка загрузки: ${snapshot.error}',
              ),
            );
          }

          final value =
              snapshot.data;

          if (value == null) {
            return const Center(
              child: Text(
                'Запись не найдена',
              ),
            );
          }

          return ListView(
            padding:
                const EdgeInsets.all(
              24,
            ),
            children: [
              Text(
                value.name,
                style:
                    Theme.of(context)
                        .textTheme
                        .headlineMedium,
              ),
              const SizedBox(
                height: 16,
              ),
              Text(
                'Тип: ${value.kind}',
              ),
              Text(
                value.description,
              ),
              const SizedBox(
                height: 20,
              ),
              if (!value.isDeleted)
                FilledButton(
                onPressed: () {
                  context.push(
                    '/categories/$id/edit',
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