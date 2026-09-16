import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../models/app_role.dart';
import '../models/simple_query.dart';
import '../models/supplier.dart';

import '../state/auth_notifier.dart';
import '../state/supplier_list_notifier.dart';

import '../widgets/dialogs.dart';
import '../widgets/entity_list_scaffold.dart';
import '../widgets/entity_table.dart';
import '../widgets/simple_filters.dart';

class SupplierListScreen extends StatefulWidget {
  final SimpleQuery initialQuery;

  const SupplierListScreen({
    super.key,
    required this.initialQuery,
  });

  @override
  State<SupplierListScreen> createState() => _SupplierListScreenState();
}

class _SupplierListScreenState extends State<SupplierListScreen> {
  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback(
      (_) {
        context.read<SupplierListNotifier>().applyQuery(
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
        '/suppliers',
        filterParam: 'country',
      ),
    );
  }

  Future<void> _delete(
    Supplier supplier,
    bool hard,
  ) async {
    final ok = await confirmDialog(
      context,
      title: 'Удаление поставщика',
      message: hard
          ? 'Удалить поставщика навсегда?'
          : 'Логически удалить поставщика?',
    );

    if (!ok || !mounted) {
      return;
    }

    try {
      final notifier = context.read<SupplierListNotifier>();

      if (hard) {
        await notifier.hardDelete(
          supplier.id,
        );
      } else {
        await notifier.softDelete(
          supplier.id,
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
    Supplier supplier,
  ) async {
    try {
      await context.read<SupplierListNotifier>().restore(
            supplier.id,
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
    final notifier = context.watch<SupplierListNotifier>();

    final auth = context.watch<AuthNotifier>();

    final query = widget.initialQuery;

    final canHardDelete = auth.can(
      AppPermission.hardDelete,
    );

    final canRestore = auth.can(
      AppPermission.restore,
    );

    return EntityListScaffold<Supplier>(
      title: 'Поставщики',
      filters: SimpleFilters(
        query: query,
        searchLabel: 'Название, страна или email',
        filterLabel: 'Страна',
        filterOptions: const {
          'Россия': 'Россия',
          'Германия': 'Германия',
          'Польша': 'Польша',
          'Беларусь': 'Беларусь',
          'Франция': 'Франция',
        },
        onChanged: _change,
      ),
      status: notifier.status,
      error: notifier.error,
      items: notifier.result.items,
      selected: notifier.selected,
      table: EntityTable<Supplier>(
        items: notifier.result.items,
        idOf: (supplier) => supplier.id,
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
            build: (supplier) {
              return Text(
                supplier.name,
              );
            },
          ),
          TableColumnSpec(
            label: 'Страна',
            sortField: 'country',
            build: (supplier) {
              return Text(
                supplier.country,
              );
            },
          ),
          TableColumnSpec(
            label: 'Email',
            build: (supplier) {
              return Text(
                supplier.email,
              );
            },
          ),
          TableColumnSpec(
            label: 'ID',
            sortField: 'id',
            numeric: true,
            build: (supplier) {
              return Text(
                '${supplier.id}',
              );
            },
          ),
        ],
        actions: (supplier) {
          return [
            IconButton(
              tooltip: 'Просмотр',
              icon: const Icon(
                Icons.visibility,
              ),
              onPressed: () {
                context.push(
                  '/suppliers/'
                  '${supplier.id}',
                );
              },
            ),
            if (!supplier.isDeleted)
              IconButton(
                tooltip: 'Редактировать',
                icon: const Icon(
                  Icons.edit,
                ),
                onPressed: () {
                  context.push(
                    '/suppliers/'
                    '${supplier.id}/edit',
                  );
                },
              ),
            if (!supplier.isDeleted)
              IconButton(
                tooltip: 'Логически удалить',
                icon: const Icon(
                  Icons.delete_outline,
                ),
                onPressed: () {
                  _delete(
                    supplier,
                    false,
                  );
                },
              ),
            if (canRestore && supplier.isDeleted)
              IconButton(
                tooltip: 'Восстановить',
                icon: const Icon(
                  Icons.restore,
                ),
                onPressed: () {
                  _restore(
                    supplier,
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
                    supplier,
                    true,
                  );
                },
              ),
          ];
        },
      ),
      cardBuilder: (supplier) {
        return Card(
          child: ListTile(
            title: Text(
              supplier.name,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            subtitle: Text(
              '${supplier.country}\n'
              '${supplier.email}',
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
            onTap: () {
              context.push(
                '/suppliers/'
                '${supplier.id}',
              );
            },
          ),
        );
      },
      onDeleteSelected: notifier.deleteSelected,
      onRetry: notifier.load,
      onCreate: () {
        context.push(
          '/suppliers/new',
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
