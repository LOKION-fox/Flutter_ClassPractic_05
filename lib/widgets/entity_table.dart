import 'package:flutter/material.dart';

class TableColumnSpec<T> {
  final String label;

  final Widget Function(T item)
      build;

  final String? sortField;

  final bool numeric;

  const TableColumnSpec({
    required this.label,
    required this.build,
    this.sortField,
    this.numeric = false,
  });
}

class EntityTable<T>
    extends StatelessWidget {
  final List<T> items;

  final int Function(T item) idOf;

  final List<TableColumnSpec<T>>
      columns;

  final Set<int> selected;

  final ValueChanged<int>
      onToggleSelect;

  final List<Widget> Function(T item)
      actions;

  final String sortField;

  final bool sortAscending;

  final ValueChanged<String>
      onSort;

  final bool selectionEnabled;

  const EntityTable({
    super.key,
    required this.items,
    required this.idOf,
    required this.columns,
    required this.selected,
    required this.onToggleSelect,
    required this.actions,
    required this.sortField,
    required this.sortAscending,
    required this.onSort,
    this.selectionEnabled = true,
  });

  @override
  Widget build(
    BuildContext context,
  ) {
    final sortIndex =
        columns.indexWhere(
      (column) =>
          column.sortField ==
          sortField,
    );

    return SingleChildScrollView(
      scrollDirection:
          Axis.horizontal,

      child: DataTable(
        showCheckboxColumn:
            selectionEnabled,

        sortColumnIndex:
            sortIndex == -1
                ? null
                : sortIndex,

        sortAscending:
            sortAscending,

        columns: [
          ...columns.map(
            (column) {
              return DataColumn(
                label:
                    Text(column.label),

                numeric:
                    column.numeric,

                onSort:
                    column.sortField ==
                            null
                        ? null
                        : (
                            index,
                            ascending,
                          ) {
                            onSort(
                              column
                                  .sortField!,
                            );
                          },
              );
            },
          ),

          const DataColumn(
            label:
                Text('Действия'),
          ),
        ],

        rows: items.map(
          (item) {
            final id =
                idOf(item);

            return DataRow(
              selected:
                  selectionEnabled &&
                  selected.contains(id),

              onSelectChanged:
                  selectionEnabled
                      ? (_) {
                          onToggleSelect(
                            id,
                          );
                        }
                      : null,

              cells: [
                ...columns.map(
                  (column) {
                    return DataCell(
                      column.build(
                        item,
                      ),
                    );
                  },
                ),

                DataCell(
                  Row(
                    mainAxisSize:
                        MainAxisSize.min,

                    children:
                        actions(item),
                  ),
                ),
              ],
            );
          },
        ).toList(),
      ),
    );
  }
}