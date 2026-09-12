import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../state/load_status.dart';
import 'dialogs.dart';
import 'pagination.dart';

class EntityListScaffold<T>
    extends StatelessWidget {
  final String title;

  final Widget filters;

  final LoadStatus status;
  final String? error;

  final List<T> items;

  final Set<int> selected;

  final Widget table;

  final Widget Function(T item)
      cardBuilder;

  final Future<void> Function()
      onDeleteSelected;

  final VoidCallback onRetry;

  final VoidCallback? onCreate;

  final int page;
  final int totalPages;
  final int total;
  final int size;

  final ValueChanged<int>
      onPageChanged;

  final ValueChanged<int>
      onSizeChanged;

  const EntityListScaffold({
    super.key,
    required this.title,
    required this.filters,
    required this.status,
    required this.error,
    required this.items,
    required this.selected,
    required this.table,
    required this.cardBuilder,
    required this.onDeleteSelected,
    required this.onRetry,
    required this.page,
    required this.totalPages,
    required this.total,
    required this.size,
    required this.onPageChanged,
    required this.onSizeChanged,
    this.onCreate,
  });

  Future<void> _delete(
    BuildContext context,
  ) async {
    final confirmed =
        await confirmDialog(
      context,

      title: 'Удаление',

      message:
          'Удалить выбранные записи: '
          '${selected.length}?',
    );

    if (!confirmed ||
        !context.mounted) {
      return;
    }

    try {
      await onDeleteSelected();
    } catch (e) {
      if (!context.mounted) {
        return;
      }

      await messageDialog(
        context,

        title:
            'Удаление невозможно',

        message:
            e.toString(),
      );
    }
  }

  @override
  Widget build(
    BuildContext context,
  ) {
    return Scaffold(
      appBar: AppBar(
        title: Text(title),

        leading: IconButton(
          icon:
              const Icon(Icons.home),

          onPressed: () {
            context.go('/');
          },
        ),

        actions: [
          if (onCreate != null)
            IconButton(
              tooltip:
                  'Создать запись',

              onPressed: onCreate,

              icon:
                  const Icon(Icons.add),
            ),
        ],
      ),

      body:
          SingleChildScrollView(
        padding:
            const EdgeInsets.all(16),

        child: Column(
          children: [
            filters,

            const SizedBox(
              height: 16,
            ),

            if (selected.isNotEmpty)
              Card(
                child: Padding(
                  padding:
                      const EdgeInsets.all(
                    12,
                  ),

                  child: Wrap(
                    spacing: 12,
                    runSpacing: 12,

                    crossAxisAlignment:
                        WrapCrossAlignment
                            .center,

                    children: [
                      Text(
                        'Выбрано: '
                        '${selected.length}',
                      ),

                      FilledButton.icon(
                        onPressed: () {
                          _delete(
                            context,
                          );
                        },

                        icon:
                            const Icon(
                          Icons.delete,
                        ),

                        label:
                            const Text(
                          'Удалить выбранные',
                        ),
                      ),
                    ],
                  ),
                ),
              ),

            const SizedBox(
              height: 8,
            ),

            if (status ==
                    LoadStatus.idle ||
                status ==
                    LoadStatus.loading)
              const Padding(
                padding:
                    EdgeInsets.all(
                  50,
                ),

                child:
                    CircularProgressIndicator(),
              )
            else if (status ==
                LoadStatus.error)
              Card(
                child: Padding(
                  padding:
                      const EdgeInsets.all(
                    30,
                  ),

                  child: Column(
                    children: [
                      const Icon(
                        Icons
                            .error_outline,
                        size: 60,
                      ),

                      const SizedBox(
                        height: 16,
                      ),

                      Text(
                        error ??
                            'Неизвестная ошибка',

                        textAlign:
                            TextAlign.center,
                      ),

                      const SizedBox(
                        height: 16,
                      ),

                      FilledButton(
                        onPressed:
                            onRetry,

                        child:
                            const Text(
                          'Повторить',
                        ),
                      ),
                    ],
                  ),
                ),
              )
            else if (items.isEmpty)
              const Card(
                child: Padding(
                  padding:
                      EdgeInsets.all(
                    40,
                  ),

                  child: Column(
                    children: [
                      Icon(
                        Icons.search_off,
                        size: 60,
                      ),

                      SizedBox(
                        height: 16,
                      ),

                      Text(
                        'По заданным условиям '
                        'ничего не найдено',

                        textAlign:
                            TextAlign.center,
                      ),
                    ],
                  ),
                ),
              )
            else ...[
              LayoutBuilder(
                builder:
                    (
                  context,
                  constraints,
                ) {
                  if (constraints
                          .maxWidth <
                      600) {
                    return Column(
                      children: items
                          .map(
                            cardBuilder,
                          )
                          .toList(),
                    );
                  }

                  return table;
                },
              ),

              const SizedBox(
                height: 20,
              ),

              Pagination(
                page: page,

                totalPages:
                    totalPages,

                total: total,

                size: size,

                onPageChanged:
                    onPageChanged,

                onSizeChanged:
                    onSizeChanged,
              ),
            ],
          ],
        ),
      ),
    );
  }
}