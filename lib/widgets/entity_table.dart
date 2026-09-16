import 'dart:math' as math;

import 'package:flutter/material.dart';

class TableColumnSpec<T> {
  final String label;

  final Widget Function(T item) build;

  final String? sortField;

  final bool numeric;

  const TableColumnSpec({
    required this.label,
    required this.build,
    this.sortField,
    this.numeric = false,
  });
}

class EntityTable<T> extends StatefulWidget {
  final List<T> items;

  final int Function(T item) idOf;

  final List<TableColumnSpec<T>> columns;

  final Set<int> selected;

  final ValueChanged<int> onToggleSelect;

  final List<Widget> Function(T item) actions;

  final String sortField;

  final bool sortAscending;

  final ValueChanged<String> onSort;

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
  State<EntityTable<T>> createState() => _EntityTableState<T>();
}

class _EntityTableState<T> extends State<EntityTable<T>> {
  final ScrollController _horizontalController = ScrollController();

  final ScrollController _verticalController = ScrollController();

  @override
  void dispose() {
    _horizontalController.dispose();

    _verticalController.dispose();

    super.dispose();
  }

  @override
  Widget build(
    BuildContext context,
  ) {
    final sortIndex = widget.columns.indexWhere(
      (column) => column.sortField == widget.sortField,
    );

    final tableHeight = math.min(
      560.0,
      72.0 + widget.items.length * 56.0,
    );

    final table = DataTable(
      showCheckboxColumn: widget.selectionEnabled,
      sortColumnIndex: sortIndex == -1 ? null : sortIndex,
      sortAscending: widget.sortAscending,
      columns: [
        ...widget.columns.map(
          (column) {
            return DataColumn(
              label: Text(
                column.label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              numeric: column.numeric,
              onSort: column.sortField == null
                  ? null
                  : (
                      index,
                      ascending,
                    ) {
                      widget.onSort(
                        column.sortField!,
                      );
                    },
            );
          },
        ),
        const DataColumn(
          label: Text('Действия'),
        ),
      ],
      rows: widget.items.map(
        (item) {
          final id = widget.idOf(item);

          return DataRow(
            selected: widget.selectionEnabled && widget.selected.contains(id),
            onSelectChanged: widget.selectionEnabled
                ? (_) {
                    widget.onToggleSelect(
                      id,
                    );
                  }
                : null,
            cells: [
              ...widget.columns.map(
                (column) {
                  return DataCell(
                    ConstrainedBox(
                      constraints: const BoxConstraints(
                        maxWidth: 260,
                      ),
                      child: DefaultTextStyle.merge(
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        child: column.build(
                          item,
                        ),
                      ),
                    ),
                  );
                },
              ),
              DataCell(
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: widget.actions(
                    item,
                  ),
                ),
              ),
            ],
          );
        },
      ).toList(),
    );

    return SizedBox(
      height: tableHeight,
      child: Scrollbar(
        controller: _verticalController,
        thumbVisibility: widget.items.length > 8,
        scrollbarOrientation: ScrollbarOrientation.right,
        child: SingleChildScrollView(
          controller: _verticalController,
          child: Scrollbar(
            controller: _horizontalController,
            thumbVisibility: true,
            scrollbarOrientation: ScrollbarOrientation.bottom,
            child: SingleChildScrollView(
              controller: _horizontalController,
              scrollDirection: Axis.horizontal,
              child: table,
            ),
          ),
        ),
      ),
    );
  }
}
