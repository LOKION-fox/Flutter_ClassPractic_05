import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../core/api_exceptions.dart';

import '../models/animal.dart';
import '../models/animal_query.dart';
import '../models/app_role.dart';
import '../models/supplier.dart';

import '../state/animal_list_notifier.dart';
import '../state/auth_notifier.dart';
import '../state/supplier_list_notifier.dart';

import '../widgets/animal_filters.dart';
import '../widgets/dialogs.dart';
import '../widgets/entity_list_scaffold.dart';
import '../widgets/entity_table.dart';

class AnimalListScreen extends StatefulWidget {
  final AnimalQuery initialQuery;

  const AnimalListScreen({
    super.key,
    required this.initialQuery,
  });

  @override
  State<AnimalListScreen> createState() => _AnimalListScreenState();
}

class _AnimalListScreenState extends State<AnimalListScreen> {
  List<Supplier> _suppliers = [];

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback(
      (_) async {
        await context.read<AnimalListNotifier>().applyQuery(
              widget.initialQuery,
            );

        try {
          final suppliers =
              await context.read<SupplierListNotifier>().getAllActive();

          if (!mounted) {
            return;
          }

          setState(() {
            _suppliers = suppliers;
          });
        } on ApiException catch (e) {
          if (!mounted) {
            return;
          }

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Не удалось загрузить '
                'поставщиков: ${e.message}',
              ),
            ),
          );
        }
      },
    );
  }

  void _change(
    AnimalQuery query,
  ) {
    context.go(
      query.toLocation(
        '/animals',
      ),
    );
  }

  Future<void> _delete(
    Animal animal,
    bool hard,
  ) async {
    final confirmed = await confirmDialog(
      context,
      title: hard ? 'Физическое удаление' : 'Удаление',
      message: hard
          ? 'Удалить животное '
              '«${animal.name}» навсегда? '
              'Восстановить запись после '
              'этого будет невозможно.'
          : 'Логически удалить животное '
              '«${animal.name}»?',
    );

    if (!confirmed || !mounted) {
      return;
    }

    final notifier = context.read<AnimalListNotifier>();

    try {
      if (hard) {
        await notifier.hardDelete(
          animal.id,
        );
      } else {
        await notifier.softDelete(
          animal.id,
        );
      }
    } on ApiException catch (e) {
      if (!mounted) {
        return;
      }

      await messageDialog(
        context,
        title: 'Операция запрещена',
        message: e.message,
      );
    } catch (e) {
      if (!mounted) {
        return;
      }

      await messageDialog(
        context,
        title: 'Ошибка',
        message: e.toString(),
      );
    }
  }

  Future<void> _restore(
    Animal animal,
  ) async {
    final notifier = context.read<AnimalListNotifier>();

    try {
      await notifier.restore(
        animal.id,
      );
    } on ApiException catch (e) {
      if (!mounted) {
        return;
      }

      await messageDialog(
        context,
        title: 'Операция запрещена',
        message: e.message,
      );
    } catch (e) {
      if (!mounted) {
        return;
      }

      await messageDialog(
        context,
        title: 'Ошибка',
        message: e.toString(),
      );
    }
  }

  Future<void> _cardAction(
    String action,
    Animal animal,
  ) async {
    switch (action) {
      case 'edit':
        context.push(
          '/animals/${animal.id}/edit',
        );
        break;

      case 'softDelete':
        await _delete(
          animal,
          false,
        );
        break;

      case 'restore':
        await _restore(
          animal,
        );
        break;

      case 'hardDelete':
        await _delete(
          animal,
          true,
        );
        break;
    }
  }

  @override
  Widget build(
    BuildContext context,
  ) {
    final notifier = context.watch<AnimalListNotifier>();

    final auth = context.watch<AuthNotifier>();

    final query = widget.initialQuery;

    final canManage = auth.can(
      AppPermission.manageCatalog,
    );

    final canHardDelete = auth.can(
      AppPermission.hardDelete,
    );

    final canRestore = auth.can(
      AppPermission.restore,
    );

    final selected = canManage ? notifier.selected : const <int>{};

    return EntityListScaffold<Animal>(
      title: 'Животные',

      filters: AnimalFilters(
        query: query,
        suppliers: _suppliers,
        onChanged: _change,
        showDeletedToggle: canManage,
      ),

      status: notifier.status,

      error: notifier.error,

      items: notifier.result.items,

      selected: selected,

      // ======================================================
      // ТАБЛИЦА
      // ======================================================

      table: EntityTable<Animal>(
        items: notifier.result.items,
        idOf: (animal) => animal.id,
        selected: selected,
        selectionEnabled: canManage,
        onToggleSelect: notifier.toggleSelection,
        sortField: query.sortField,
        sortAscending: query.sortAscending,
        onSort: (field) {
          _change(
            query.copyWith(
              sortField: field,
              sortAscending:
                  field == query.sortField ? !query.sortAscending : true,
            ),
          );
        },
        columns: [
          TableColumnSpec<Animal>(
            label: 'Имя',
            sortField: 'name',
            build: (animal) {
              return Text(
                animal.name,
              );
            },
          ),
          TableColumnSpec<Animal>(
            label: 'Вид',
            build: (animal) {
              return Text(
                animal.species,
              );
            },
          ),
          TableColumnSpec<Animal>(
            label: 'Порода',
            build: (animal) {
              return Text(
                animal.breed,
              );
            },
          ),
          TableColumnSpec<Animal>(
            label: 'Возраст',
            sortField: 'age',
            numeric: true,
            build: (animal) {
              return Text(
                '${animal.ageMonths} мес.',
              );
            },
          ),
          TableColumnSpec<Animal>(
            label: 'Пол',
            build: (animal) {
              return Text(
                animal.sex,
              );
            },
          ),
          TableColumnSpec<Animal>(
            label: 'Страна',
            build: (animal) {
              return Text(
                animal.country,
              );
            },
          ),
          TableColumnSpec<Animal>(
            label: 'Цена',
            sortField: 'price',
            numeric: true,
            build: (animal) {
              return Text(
                '${animal.price.toStringAsFixed(0)} ₽',
              );
            },
          ),
        ],
        actions: (animal) {
          return [
            // Просмотр разрешён всем.
            IconButton(
              tooltip: 'Просмотр',
              icon: const Icon(
                Icons.visibility,
              ),
              onPressed: () {
                context.push(
                  '/animals/${animal.id}',
                );
              },
            ),

            // manager/admin
            if (canManage && !animal.isDeleted)
              IconButton(
                tooltip: 'Редактировать',
                icon: const Icon(
                  Icons.edit,
                ),
                onPressed: () {
                  context.push(
                    '/animals/'
                    '${animal.id}/edit',
                  );
                },
              ),

            // manager/admin
            if (canManage && !animal.isDeleted)
              IconButton(
                tooltip: 'Логически удалить',
                icon: const Icon(
                  Icons.delete_outline,
                ),
                onPressed: () {
                  _delete(
                    animal,
                    false,
                  );
                },
              ),

            // Только admin.
            if (canRestore && animal.isDeleted)
              IconButton(
                tooltip: 'Восстановить',
                icon: const Icon(
                  Icons.restore,
                ),
                onPressed: () {
                  _restore(
                    animal,
                  );
                },
              ),

            // Только admin.
            if (canHardDelete)
              IconButton(
                tooltip: 'Удалить навсегда',
                icon: const Icon(
                  Icons.delete_forever,
                ),
                onPressed: () {
                  _delete(
                    animal,
                    true,
                  );
                },
              ),
          ];
        },
      ),

      // ======================================================
      // КАРТОЧКИ ПРИ ШИРИНЕ < 600
      // ======================================================

      cardBuilder: (animal) {
        final hasActions = (canManage && !animal.isDeleted) ||
            (canRestore && animal.isDeleted) ||
            canHardDelete;

        return Card(
          child: ListTile(
            leading: Icon(
              animal.isDeleted ? Icons.pets_outlined : Icons.pets,
            ),
            title: Text(
              animal.name,
            ),
            subtitle: Text(
              'Вид: ${animal.species}\n'
              'Порода: ${animal.breed}\n'
              'Возраст: '
              '${animal.ageMonths} мес.\n'
              'Цена: '
              '${animal.price.toStringAsFixed(0)} ₽'
              '${animal.isDeleted ? '\nУдалено' : ''}',
            ),
            isThreeLine: true,
            onTap: () {
              context.push(
                '/animals/${animal.id}',
              );
            },
            trailing: hasActions
                ? PopupMenuButton<String>(
                    onSelected: (value) {
                      _cardAction(
                        value,
                        animal,
                      );
                    },
                    itemBuilder: (context) {
                      return [
                        if (canManage && !animal.isDeleted)
                          const PopupMenuItem(
                            value: 'edit',
                            child: ListTile(
                              leading: Icon(
                                Icons.edit,
                              ),
                              title: Text(
                                'Редактировать',
                              ),
                            ),
                          ),
                        if (canManage && !animal.isDeleted)
                          const PopupMenuItem(
                            value: 'softDelete',
                            child: ListTile(
                              leading: Icon(
                                Icons.delete_outline,
                              ),
                              title: Text(
                                'Удалить',
                              ),
                            ),
                          ),
                        if (canRestore && animal.isDeleted)
                          const PopupMenuItem(
                            value: 'restore',
                            child: ListTile(
                              leading: Icon(
                                Icons.restore,
                              ),
                              title: Text(
                                'Восстановить',
                              ),
                            ),
                          ),
                        if (canHardDelete)
                          const PopupMenuItem(
                            value: 'hardDelete',
                            child: ListTile(
                              leading: Icon(
                                Icons.delete_forever,
                              ),
                              title: Text(
                                'Удалить навсегда',
                              ),
                            ),
                          ),
                      ];
                    },
                  )
                : null,
          ),
        );
      },

      onDeleteSelected: canManage ? notifier.deleteSelected : () async {},

      onRetry: notifier.load,

      onCreate: canManage
          ? () {
              context.push(
                '/animals/new',
              );
            }
          : null,

      page: notifier.result.page,

      totalPages: notifier.result.totalPages,

      total: notifier.result.total,

      size: notifier.result.size,

      onPageChanged: (page) {
        _change(
          query.copyWith(
            page: page,
          ),
        );
      },

      onSizeChanged: (size) {
        _change(
          query.copyWith(
            size: size,
            page: 1,
          ),
        );
      },
    );
  }
}
