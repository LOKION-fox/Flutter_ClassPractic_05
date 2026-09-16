import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../models/app_role.dart';
import '../models/category.dart';
import '../models/simple_query.dart';

import '../state/auth_notifier.dart';
import '../state/category_list_notifier.dart';

import '../widgets/dialogs.dart';
import '../widgets/entity_list_scaffold.dart';
import '../widgets/entity_table.dart';
import '../widgets/simple_filters.dart';

class CategoryListScreen extends StatefulWidget {
  final SimpleQuery initialQuery;

  const CategoryListScreen({
    super.key,
    required this.initialQuery,
  });

  @override
  State<CategoryListScreen> createState() => _CategoryListScreenState();
}

class _CategoryListScreenState extends State<CategoryListScreen> {
  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback(
      (_) {
        context.read<CategoryListNotifier>().applyQuery(
              widget.initialQuery,
            );
      },
    );
  }

  void _change(
    SimpleQuery query,
  ) {
    context.go(
      query.toLocation(
        '/categories',
        filterParam: 'kind',
      ),
    );
  }

  Future<void> _delete(
    Category category,
    bool hard,
  ) async {
    final ok = await confirmDialog(
      context,
      title: 'Удаление',
      message:
          hard ? 'Удалить категорию навсегда?' : 'Логически удалить категорию?',
    );

    if (!ok || !mounted) {
      return;
    }

    try {
      final notifier = context.read<CategoryListNotifier>();

      if (hard) {
        await notifier.hardDelete(
          category.id,
        );
      } else {
        await notifier.softDelete(
          category.id,
        );
      }
    } catch (e) {
      if (!mounted) {
        return;
      }

      await messageDialog(
        context,
        title: 'Удаление невозможно',
        message: e.toString(),
      );
    }
  }

  Future<void> _restore(
    Category category,
  ) async {
    try {
      await context.read<CategoryListNotifier>().restore(
            category.id,
          );
    } catch (e) {
      if (!mounted) {
        return;
      }

      await messageDialog(
        context,
        title: 'Восстановление невозможно',
        message: e.toString(),
      );
    }
  }

  @override
  Widget build(
    BuildContext context,
  ) {
    final notifier = context.watch<CategoryListNotifier>();

    final auth = context.watch<AuthNotifier>();

    final query = widget.initialQuery;

    final canHardDelete = auth.can(
      AppPermission.hardDelete,
    );

    final canRestore = auth.can(
      AppPermission.restore,
    );

    final table = EntityTable<Category>(
      items: notifier.result.items,
      idOf: (category) => category.id,
      selected: notifier.selected,
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
        TableColumnSpec(
          label: 'Название',
          sortField: 'name',
          build: (category) {
            return Text(
              category.name,
            );
          },
        ),
        TableColumnSpec(
          label: 'Тип',
          sortField: 'kind',
          build: (category) {
            return Text(
              category.kind,
            );
          },
        ),
        TableColumnSpec(
          label: 'ID',
          sortField: 'id',
          numeric: true,
          build: (category) {
            return Text(
              '${category.id}',
            );
          },
        ),
      ],
      actions: (category) {
        return [
          IconButton(
            tooltip: 'Просмотр',
            icon: const Icon(
              Icons.visibility,
            ),
            onPressed: () {
              context.push(
                '/categories/'
                '${category.id}',
              );
            },
          ),
          if (!category.isDeleted)
            IconButton(
              tooltip: 'Редактировать',
              icon: const Icon(
                Icons.edit,
              ),
              onPressed: () {
                context.push(
                  '/categories/'
                  '${category.id}/edit',
                );
              },
            ),
          if (!category.isDeleted)
            IconButton(
              tooltip: 'Логически удалить',
              icon: const Icon(
                Icons.delete_outline,
              ),
              onPressed: () {
                _delete(
                  category,
                  false,
                );
              },
            ),
          if (canRestore && category.isDeleted)
            IconButton(
              tooltip: 'Восстановить',
              icon: const Icon(
                Icons.restore,
              ),
              onPressed: () {
                _restore(
                  category,
                );
              },
            ),
          if (canHardDelete)
            IconButton(
              tooltip: 'Удалить навсегда',
              icon: const Icon(
                Icons.delete_forever,
              ),
              onPressed: () {
                _delete(
                  category,
                  true,
                );
              },
            ),
        ];
      },
    );

    return EntityListScaffold<Category>(
      title: 'Категории',
      filters: SimpleFilters(
        query: query,
        searchLabel: 'Поиск категории',
        filterLabel: 'Тип категории',
        filterOptions: const {
          'product': 'Для товаров',
          'animal': 'Для животных',
          'both': 'Общие',
        },
        onChanged: _change,
      ),
      status: notifier.status,
      error: notifier.error,
      items: notifier.result.items,
      selected: notifier.selected,
      table: table,
      cardBuilder: (category) {
        return Card(
          child: ListTile(
            title: Text(
              category.name,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            subtitle: Text(
              category.description,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
            onTap: () {
              context.push(
                '/categories/'
                '${category.id}',
              );
            },
          ),
        );
      },
      onDeleteSelected: notifier.deleteSelected,
      onRetry: notifier.load,
      onCreate: () {
        context.push(
          '/categories/new',
        );
      },
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
