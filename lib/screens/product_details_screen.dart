import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../models/app_role.dart';
import '../models/category.dart';
import '../models/product.dart';
import '../models/supplier.dart';
import '../state/auth_notifier.dart';
import '../state/category_list_notifier.dart';
import '../state/product_list_notifier.dart';
import '../state/supplier_list_notifier.dart';

class ProductDetailsScreen extends StatelessWidget {
  final int id;

  const ProductDetailsScreen({
    super.key,
    required this.id,
  });

  Future<List<Object?>> _load(
    BuildContext context,
  ) async {
    final product = await context.read<ProductListNotifier>().findById(id);

    final categories = await context.read<CategoryListNotifier>().getAll();

    final suppliers = await context.read<SupplierListNotifier>().getAll();

    return [
      product,
      categories,
      suppliers,
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Товар'),
      ),
      body: FutureBuilder<List<Object?>>(
        future: _load(context),
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

          final data = snapshot.data;

          if (data == null || data[0] == null) {
            return const Center(
              child: Text(
                'Запись не найдена',
              ),
            );
          }

          final product = data[0] as Product;

          final categories = data[1] as List<Category>;

          final suppliers = data[2] as List<Supplier>;

          var supplier = 'Не найден';

          for (final value in suppliers) {
            if (value.id == product.supplierId) {
              supplier = value.name;
              break;
            }
          }

          final categoryNames = categories
              .where(
                (c) => product.categoryIds.contains(c.id),
              )
              .map((c) => c.name)
              .join(', ');

          final canManage = context.watch<AuthNotifier>().can(
                AppPermission.manageCatalog,
              );

          return ListView(
            padding: const EdgeInsets.all(
              24,
            ),
            children: [
              Text(
                product.name,
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              const SizedBox(
                height: 16,
              ),
              Text(
                'Артикул: ${product.article}',
              ),
              Text(
                'Бренд: ${product.brand}',
              ),
              Text(
                'Цена: ${product.price.toStringAsFixed(0)} ₽',
              ),
              Text(
                'Остаток: ${product.stock}',
              ),
              Text(
                'Поставщик: $supplier',
              ),
              Text(
                'Категории: $categoryNames',
              ),
              const SizedBox(
                height: 16,
              ),
              Text(
                product.description,
              ),
              const SizedBox(
                height: 20,
              ),
              if (canManage && !product.isDeleted)
                FilledButton.icon(
                  onPressed: () {
                    context.push(
                      '/products/$id/edit',
                    );
                  },
                  icon: const Icon(Icons.edit),
                  label: const Text(
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
