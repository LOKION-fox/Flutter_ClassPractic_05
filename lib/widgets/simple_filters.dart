import 'dart:async';

import 'package:flutter/material.dart';

import '../models/simple_query.dart';

class SimpleFilters extends StatefulWidget {
  final SimpleQuery query;

  final String searchLabel;
  final String filterLabel;

  final Map<String, String> filterOptions;

  final ValueChanged<SimpleQuery> onChanged;

  const SimpleFilters({
    super.key,
    required this.query,
    required this.searchLabel,
    required this.filterLabel,
    required this.filterOptions,
    required this.onChanged,
  });

  @override
  State<SimpleFilters> createState() => _SimpleFiltersState();
}

class _SimpleFiltersState extends State<SimpleFilters> {
  late final TextEditingController _searchController;

  Timer? _timer;

  @override
  void initState() {
    super.initState();

    _searchController = TextEditingController(
      text: widget.query.search,
    );
  }

  @override
  void didUpdateWidget(
    SimpleFilters oldWidget,
  ) {
    super.didUpdateWidget(oldWidget);

    if (_searchController.text != widget.query.search) {
      _searchController.text = widget.query.search;
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _searchController.dispose();

    super.dispose();
  }

  void _search(String value) {
    _timer?.cancel();

    _timer = Timer(
      const Duration(
        milliseconds: 350,
      ),
      () {
        widget.onChanged(
          widget.query.copyWith(
            search: value,
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: _searchController,
              decoration: InputDecoration(
                labelText: widget.searchLabel,
                prefixIcon: const Icon(
                  Icons.search,
                ),
                border: const OutlineInputBorder(),
              ),
              onChanged: _search,
            ),
            const SizedBox(height: 14),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                SizedBox(
                  width: 230,
                  child: DropdownButtonFormField<String>(
                    initialValue: widget.query.filter,
                    isExpanded: true,
                    decoration: InputDecoration(
                      labelText: widget.filterLabel,
                      border: const OutlineInputBorder(),
                    ),
                    items: [
                      const DropdownMenuItem<String>(
                        value: null,
                        child: Text('Все'),
                      ),
                      ...widget.filterOptions.entries.map(
                        (entry) {
                          return DropdownMenuItem<String>(
                            value: entry.key,
                            child: Text(
                              entry.value,
                            ),
                          );
                        },
                      ),
                    ],
                    onChanged: (value) {
                      widget.onChanged(
                        widget.query.copyWith(
                          filter: value,
                        ),
                      );
                    },
                  ),
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Switch(
                      value: widget.query.includeDeleted,
                      onChanged: (value) {
                        widget.onChanged(
                          widget.query.copyWith(
                            includeDeleted: value,
                          ),
                        );
                      },
                    ),
                    const Text(
                      'Показывать удалённые',
                    ),
                  ],
                ),
                TextButton.icon(
                  onPressed: () {
                    widget.onChanged(
                      SimpleQuery(
                        size: widget.query.size,
                      ),
                    );
                  },
                  icon: const Icon(
                    Icons.clear,
                  ),
                  label: const Text(
                    'Сбросить',
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
