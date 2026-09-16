import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../state/load_status.dart';

import 'dialogs.dart';
import 'pagination.dart';

class EntityListScaffold<T> extends StatelessWidget {
  final String title;

  final Widget filters;

  final LoadStatus status;
  final String? error;

  final List<T> items;

  final Set<int> selected;

  final Widget table;

  final Widget Function(T item) cardBuilder;

  final Future<void> Function() onDeleteSelected;

  final VoidCallback onRetry;

  final VoidCallback? onCreate;

  final int page;
  final int totalPages;
  final int total;
  final int size;

  final ValueChanged<int> onPageChanged;

  final ValueChanged<int> onSizeChanged;

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
    final confirmed = await confirmDialog(
      context,
      title: 'Удаление',
      message: 'Удалить выбранные записи: '
          '${selected.length}?',
    );

    if (!confirmed || !context.mounted) {
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
        title: 'Удаление невозможно',
        message: e.toString(),
      );
    }
  }

  Widget _buildCards(
    BoxConstraints constraints,
  ) {
    final oneColumn = constraints.maxWidth < 600;

    const gap = 12.0;

    final cardWidth =
        oneColumn ? constraints.maxWidth : (constraints.maxWidth - gap) / 2;

    return Wrap(
      spacing: gap,
      runSpacing: gap,
      children: items.map(
        (item) {
          return SizedBox(
            width: cardWidth,
            child: cardBuilder(item),
          );
        },
      ).toList(),
    );
  }

  @override
  Widget build(
    BuildContext context,
  ) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        leading: IconButton(
          tooltip: 'На главную',
          icon: const Icon(Icons.home),
          onPressed: () {
            context.go('/');
          },
        ),
        actions: [
          if (onCreate != null)
            IconButton(
              tooltip: 'Создать запись',
              onPressed: onCreate,
              icon: const Icon(Icons.add),
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(
          16,
        ),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              maxWidth: 1400,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                filters,
                const SizedBox(
                  height: 16,
                ),
                if (selected.isNotEmpty)
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(
                        12,
                      ),
                      child: Wrap(
                        spacing: 12,
                        runSpacing: 12,
                        crossAxisAlignment: WrapCrossAlignment.center,
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
                            icon: const Icon(
                              Icons.delete,
                            ),
                            label: const Text(
                              'Удалить выбранные',
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                if (selected.isNotEmpty)
                  const SizedBox(
                    height: 8,
                  ),
                if (status == LoadStatus.idle || status == LoadStatus.loading)
                  const Padding(
                    key: ValueKey(
                      'entity-loading',
                    ),
                    padding: EdgeInsets.all(
                      50,
                    ),
                    child: Center(
                      child: CircularProgressIndicator(),
                    ),
                  )
                else if (status == LoadStatus.error)
                  Card(
                    key: const ValueKey(
                      'entity-error',
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(
                        30,
                      ),
                      child: Column(
                        children: [
                          const Icon(
                            Icons.cloud_off,
                            size: 60,
                          ),
                          const SizedBox(
                            height: 16,
                          ),
                          Text(
                            error ?? 'Неизвестная ошибка',
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(
                            height: 8,
                          ),
                          const Text(
                            'Если сервер был отключён, '
                            'запустите его снова и нажмите '
                            '«Повторить». Перезагружать '
                            'страницу не нужно.',
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(
                            height: 16,
                          ),
                          FilledButton.icon(
                            key: const ValueKey(
                              'entity-retry',
                            ),
                            onPressed: onRetry,
                            icon: const Icon(
                              Icons.refresh,
                            ),
                            label: const Text(
                              'Повторить',
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                else if (items.isEmpty)
                  const Card(
                    key: ValueKey(
                      'entity-empty',
                    ),
                    child: Padding(
                      padding: EdgeInsets.all(
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
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  )
                else ...[
                  LayoutBuilder(
                    builder: (
                      context,
                      constraints,
                    ) {
                      // 360 px — одна колонка.
                      // 768 px — две колонки.
                      // 1280 px — таблица.
                      if (constraints.maxWidth < 900) {
                        return _buildCards(
                          constraints,
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
                    totalPages: totalPages,
                    total: total,
                    size: size,
                    onPageChanged: onPageChanged,
                    onSizeChanged: onSizeChanged,
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
