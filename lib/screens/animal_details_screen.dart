import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../models/animal.dart';
import '../models/app_role.dart';
import '../state/animal_list_notifier.dart';
import '../state/auth_notifier.dart';

class AnimalDetailsScreen extends StatelessWidget {
  final int id;

  const AnimalDetailsScreen({
    super.key,
    required this.id,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Животное'),
      ),
      body: FutureBuilder<Animal?>(
        future: context.read<AnimalListNotifier>().findById(id),
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

          final animal = snapshot.data;

          if (animal == null) {
            return const Center(
              child: Text(
                'Запись не найдена',
              ),
            );
          }

          final canManage = context.watch<AuthNotifier>().can(
                AppPermission.manageCatalog,
              );

          return ListView(
            padding: const EdgeInsets.all(
              24,
            ),
            children: [
              Text(
                animal.name,
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              const SizedBox(
                height: 16,
              ),
              Text(
                'Вид: ${animal.species}',
              ),
              Text(
                'Порода: ${animal.breed}',
              ),
              Text(
                'Возраст: ${animal.ageMonths} мес.',
              ),
              Text(
                'Пол: ${animal.sex}',
              ),
              Text(
                'Страна: ${animal.country}',
              ),
              Text(
                'Цена: ${animal.price.toStringAsFixed(0)} ₽',
              ),
              const SizedBox(
                height: 16,
              ),
              Text(
                animal.description,
              ),
              const SizedBox(
                height: 20,
              ),
              if (canManage && !animal.isDeleted)
                FilledButton.icon(
                  onPressed: () {
                    context.push(
                      '/animals/$id/edit',
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
