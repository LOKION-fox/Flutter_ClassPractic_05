import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../core/api_exceptions.dart';

import '../models/app_role.dart';
import '../models/category.dart';
import '../models/product.dart';
import '../models/product_query.dart';
import '../models/supplier.dart';

import '../state/auth_notifier.dart';
import '../state/category_list_notifier.dart';
import '../state/product_list_notifier.dart';
import '../state/supplier_list_notifier.dart';

import '../widgets/dialogs.dart';
import '../widgets/entity_list_scaffold.dart';
import '../widgets/entity_table.dart';
import '../widgets/product_filters.dart';

class ProductListScreen extends StatefulWidget {
  final ProductQuery initialQuery;

  const ProductListScreen({
    super.key,
    required this.initialQuery,
  });

  @override
  State<ProductListScreen> createState() => _ProductListScreenState();
}

class _ProductListScreenState extends State<ProductListScreen> {
  List<Category> _categories = [];
  List<Supplier> _suppliers = [];

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback(
      (_) async {
        await context.read<ProductListNotifier>().applyQuery(
              widget.initialQuery,
            );

        try {
          final categories =
              await context.read<CategoryListNotifier>().getAllActive();

          final suppliers =
              await context.read<SupplierListNotifier>().getAllActive();

          if (!mounted) {
            return;
          }

          setState(() {
            _categories = categories;
            _suppliers = suppliers;
          });
        } on ApiException catch (e) {
          if (!mounted) {
            return;
          }

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Не удалось загрузить справочники: '
                '${e.message}',
              ),
            ),
          );
        }
      },
    );
  }

  void _change(
    ProductQuery query,
  ) {
    context.go(
      query.toLocation(
        '/products',
      ),
    );
  }

  Future<void> _delete(
    Product product,
    bool hard,
  ) async {
    final confirmed = await confirmDialog(
      context,
      title: hard ? 'Физическое удаление' : 'Удаление',
      message: hard
          ? 'Удалить товар «${product.name}» '
              'навсегда? Восстановить его '
              'после этого будет невозможно.'
          : 'Логически удалить товар '
              '«${product.name}»?',
    );

    if (!confirmed || !mounted) {
      return;
    }

    final notifier = context.read<ProductListNotifier>();

    try {
      if (hard) {
        await notifier.hardDelete(
          product.id,
        );
      } else {
        await notifier.softDelete(
          product.id,
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
    Product product,
  ) async {
    final notifier = context.read<ProductListNotifier>();

    try {
      await notifier.restore(
        product.id,
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
    Product product,
  ) async {
    switch (action) {
      case 'edit':
        context.push(
          '/products/${product.id}/edit',
        );
        break;

      case 'softDelete':
        await _delete(
          product,
          false,
        );
        break;

      case 'restore':
        await _restore(
          product,
        );
        break;

      case 'hardDelete':
        await _delete(
          product,
          true,
        );
        break;
    }
  }

  @override
  Widget build(
    BuildContext context,
  ) {
    final notifier = context.watch<ProductListNotifier>();

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

    // Если пользователь не имеет права
    // управлять каталогом, выбранные строки
    // ему вообще не показываем.
    final selected = canManage ? notifier.selected : const <int>{};

    return EntityListScaffold<Product>(
      title: 'Товары',

      filters: ProductFilters(
        query: query,
        categories: _categories,
        suppliers: _suppliers,
        onChanged: _change,
        showDeletedToggle: canManage,
      ),

      status: notifier.status,
      error: notifier.error,

      items: notifier.result.items,

      selected: selected,

      // ======================================================
      // ТАБЛИЦА ДЛЯ ШИРОКОГО ЭКРАНА
      // ======================================================

      table: EntityTable<Product>(
        items: notifier.result.items,
        idOf: (product) => product.id,
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
          TableColumnSpec<Product>(
            label: 'Название',
            sortField: 'name',
            build: (product) {
              return Text(
                product.name,
              );
            },
          ),
          TableColumnSpec<Product>(
            label: 'Артикул',
            build: (product) {
              return Text(
                product.article,
              );
            },
          ),
          TableColumnSpec<Product>(
            label: 'Бренд',
            build: (product) {
              return Text(
                product.brand,
              );
            },
          ),
          TableColumnSpec<Product>(
            label: 'Цена',
            sortField: 'price',
            numeric: true,
            build: (product) {
              return Text(
                '${product.price.toStringAsFixed(0)} ₽',
              );
            },
          ),
          TableColumnSpec<Product>(
            label: 'Остаток',
            sortField: 'stock',
            numeric: true,
            build: (product) {
              return Text(
                '${product.stock}',
              );
            },
          ),
        ],
        actions: (product) {
          return [
            // Просмотр доступен всем
            // авторизованным пользователям.
            IconButton(
              tooltip: 'Просмотр',
              icon: const Icon(
                Icons.visibility,
              ),
              onPressed: () {
                context.push(
                  '/products/${product.id}',
                );
              },
            ),

            // Редактировать может
            // manager или admin.
            if (canManage && !product.isDeleted)
              IconButton(
                tooltip: 'Редактировать',
                icon: const Icon(
                  Icons.edit,
                ),
                onPressed: () {
                  context.push(
                    '/products/'
                    '${product.id}/edit',
                  );
                },
              ),

            // Логическое удаление:
            // manager или admin.
            if (canManage && !product.isDeleted)
              IconButton(
                tooltip: 'Логически удалить',
                icon: const Icon(
                  Icons.delete_outline,
                ),
                onPressed: () {
                  _delete(
                    product,
                    false,
                  );
                },
              ),

            // Восстановление:
            // только admin.
            if (canRestore && product.isDeleted)
              IconButton(
                tooltip: 'Восстановить',
                icon: const Icon(
                  Icons.restore,
                ),
                onPressed: () {
                  _restore(
                    product,
                  );
                },
              ),

            // Физическое удаление:
            // только admin.
            if (canHardDelete)
              IconButton(
                tooltip: 'Удалить навсегда',
                icon: const Icon(
                  Icons.delete_forever,
                ),
                onPressed: () {
                  _delete(
                    product,
                    true,
                  );
                },
              ),
          ];
        },
      ),

      // ======================================================
      // КАРТОЧКИ ДЛЯ ЭКРАНА < 600 PX
      // ======================================================

      cardBuilder: (product) {
        final hasActions = (canManage && !product.isDeleted) ||
            (canRestore && product.isDeleted) ||
            canHardDelete;

        return Card(
          child: ListTile(
            leading: Icon(
              product.isDeleted
                  ? Icons.remove_shopping_cart
                  : Icons.shopping_bag,
            ),
            title: Text(
              product.name,
            ),
            subtitle: Text(
              'Артикул: '
              '${product.article}\n'
              'Бренд: '
              '${product.brand}\n'
              'Цена: '
              '${product.price.toStringAsFixed(0)} ₽\n'
              'Остаток: '
              '${product.stock}'
              '${product.isDeleted ? '\nУдалён' : ''}',
            ),
            isThreeLine: true,
            onTap: () {
              context.push(
                '/products/${product.id}',
              );
            },
            trailing: hasActions
                ? PopupMenuButton<String>(
                    onSelected: (value) {
                      _cardAction(
                        value,
                        product,
                      );
                    },
                    itemBuilder: (context) {
                      return [
                        if (canManage && !product.isDeleted)
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
                        if (canManage && !product.isDeleted)
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
                        if (canRestore && product.isDeleted)
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

      // Массовое удаление используется
      // только manager/admin.
      onDeleteSelected: canManage ? notifier.deleteSelected : () async {},

      onRetry: notifier.load,

      // Кнопка "+" скрыта у customer.
      onCreate: canManage
          ? () {
              context.push(
                '/products/new',
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
