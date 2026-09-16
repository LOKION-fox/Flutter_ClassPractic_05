import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../models/app_role.dart';
import '../models/customer.dart';
import '../models/simple_query.dart';

import '../state/auth_notifier.dart';
import '../state/customer_list_notifier.dart';

import '../widgets/dialogs.dart';
import '../widgets/entity_list_scaffold.dart';
import '../widgets/entity_table.dart';
import '../widgets/simple_filters.dart';

class CustomerListScreen extends StatefulWidget {
  final SimpleQuery initialQuery;

  const CustomerListScreen({
    super.key,
    required this.initialQuery,
  });

  @override
  State<CustomerListScreen> createState() => _CustomerListScreenState();
}

class _CustomerListScreenState extends State<CustomerListScreen> {
  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback(
      (_) {
        context.read<CustomerListNotifier>().applyQuery(
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
        '/customers',
        filterParam: 'level',
      ),
    );
  }

  Future<void> _delete(
    Customer customer,
    bool hard,
  ) async {
    final ok = await confirmDialog(
      context,
      title: 'Удаление',
      message: hard
          ? 'Удалить покупателя навсегда?'
          : 'Логически удалить покупателя?',
    );

    if (!ok || !mounted) {
      return;
    }

    try {
      final notifier = context.read<CustomerListNotifier>();

      if (hard) {
        await notifier.hardDelete(
          customer.id,
        );
      } else {
        await notifier.softDelete(
          customer.id,
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
    Customer customer,
  ) async {
    try {
      await context.read<CustomerListNotifier>().restore(
            customer.id,
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
    final notifier = context.watch<CustomerListNotifier>();

    final auth = context.watch<AuthNotifier>();

    final query = widget.initialQuery;

    final canHardDelete = auth.can(
      AppPermission.hardDelete,
    );

    final canRestore = auth.can(
      AppPermission.restore,
    );

    return EntityListScaffold<Customer>(
      title: 'Покупатели',
      filters: SimpleFilters(
        query: query,
        searchLabel: 'Имя, email, телефон или карта',
        filterLabel: 'Уровень карты',
        filterOptions: const {
          'Silver': 'Silver',
          'Gold': 'Gold',
          'Platinum': 'Platinum',
        },
        onChanged: _change,
      ),
      status: notifier.status,
      error: notifier.error,
      items: notifier.result.items,
      selected: notifier.selected,
      table: EntityTable<Customer>(
        items: notifier.result.items,
        idOf: (customer) => customer.id,
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
            label: 'Фамилия',
            sortField: 'lastName',
            build: (customer) {
              return Text(
                customer.fullName,
              );
            },
          ),
          TableColumnSpec(
            label: 'Email',
            sortField: 'email',
            build: (customer) {
              return Text(
                customer.email,
              );
            },
          ),
          TableColumnSpec(
            label: 'Телефон',
            build: (customer) {
              return Text(
                customer.phone,
              );
            },
          ),
          TableColumnSpec(
            label: 'Баллы',
            sortField: 'points',
            numeric: true,
            build: (customer) {
              return Text(
                '${customer.loyaltyCard.points}',
              );
            },
          ),
        ],
        actions: (customer) {
          return [
            IconButton(
              tooltip: 'Просмотр',
              icon: const Icon(
                Icons.visibility,
              ),
              onPressed: () {
                context.push(
                  '/customers/'
                  '${customer.id}',
                );
              },
            ),
            if (!customer.isDeleted)
              IconButton(
                tooltip: 'Редактировать',
                icon: const Icon(
                  Icons.edit,
                ),
                onPressed: () {
                  context.push(
                    '/customers/'
                    '${customer.id}/edit',
                  );
                },
              ),
            if (!customer.isDeleted)
              IconButton(
                tooltip: 'Логически удалить',
                icon: const Icon(
                  Icons.delete_outline,
                ),
                onPressed: () {
                  _delete(
                    customer,
                    false,
                  );
                },
              ),
            if (canRestore && customer.isDeleted)
              IconButton(
                tooltip: 'Восстановить',
                icon: const Icon(
                  Icons.restore,
                ),
                onPressed: () {
                  _restore(
                    customer,
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
                    customer,
                    true,
                  );
                },
              ),
          ];
        },
      ),
      cardBuilder: (customer) {
        return Card(
          child: ListTile(
            title: Text(
              customer.fullName,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            subtitle: Text(
              '${customer.email}\n'
              '${customer.loyaltyCard.level}',
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
            onTap: () {
              context.push(
                '/customers/'
                '${customer.id}',
              );
            },
          ),
        );
      },
      onDeleteSelected: notifier.deleteSelected,
      onRetry: notifier.load,
      onCreate: () {
        context.push(
          '/customers/new',
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
