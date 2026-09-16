import 'dart:async';

import 'package:flutter/material.dart';

import '../models/category.dart';
import '../models/product_query.dart';
import '../models/supplier.dart';

class ProductFilters extends StatefulWidget {
  final ProductQuery query;

  final List<Category> categories;
  final List<Supplier> suppliers;

  final ValueChanged<ProductQuery> onChanged;

  final bool showDeletedToggle;

  const ProductFilters({
    super.key,
    required this.query,
    required this.categories,
    required this.suppliers,
    required this.onChanged,
    this.showDeletedToggle = true,
  });

  @override
  State<ProductFilters> createState() => _ProductFiltersState();
}

class _ProductFiltersState extends State<ProductFilters> {
  late final TextEditingController _searchController;

  late final TextEditingController _priceFrom;

  late final TextEditingController _priceTo;

  Timer? _timer;

  @override
  void initState() {
    super.initState();

    _searchController = TextEditingController(
      text: widget.query.search,
    );

    _priceFrom = TextEditingController(
      text: widget.query.priceFrom?.toString() ?? '',
    );

    _priceTo = TextEditingController(
      text: widget.query.priceTo?.toString() ?? '',
    );
  }

  @override
  void dispose() {
    _timer?.cancel();

    _searchController.dispose();
    _priceFrom.dispose();
    _priceTo.dispose();

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

  double? _number(String value) {
    return double.tryParse(
      value.replaceAll(',', '.'),
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
              onChanged: _search,
              decoration: const InputDecoration(
                labelText: 'Поиск по названию, артикулу или бренду',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 14),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                SizedBox(
                  width: 220,
                  child: DropdownButtonFormField<int>(
                    initialValue: widget.query.categoryId,
                    isExpanded: true,
                    decoration: const InputDecoration(
                      labelText: 'Категория',
                      border: OutlineInputBorder(),
                    ),
                    items: [
                      const DropdownMenuItem<int>(
                        value: null,
                        child: Text('Все'),
                      ),
                      ...widget.categories.map(
                        (c) => DropdownMenuItem<int>(
                          value: c.id,
                          child: Text(c.name),
                        ),
                      ),
                    ],
                    onChanged: (value) {
                      widget.onChanged(
                        widget.query.copyWith(
                          categoryId: value,
                        ),
                      );
                    },
                  ),
                ),
                SizedBox(
                  width: 240,
                  child: DropdownButtonFormField<int>(
                    initialValue: widget.query.supplierId,
                    isExpanded: true,
                    decoration: const InputDecoration(
                      labelText: 'Поставщик',
                      border: OutlineInputBorder(),
                    ),
                    items: [
                      const DropdownMenuItem<int>(
                        value: null,
                        child: Text('Все'),
                      ),
                      ...widget.suppliers.map(
                        (s) => DropdownMenuItem<int>(
                          value: s.id,
                          child: Text(s.name),
                        ),
                      ),
                    ],
                    onChanged: (value) {
                      widget.onChanged(
                        widget.query.copyWith(
                          supplierId: value,
                        ),
                      );
                    },
                  ),
                ),
                SizedBox(
                  width: 150,
                  child: TextField(
                    controller: _priceFrom,
                    decoration: const InputDecoration(
                      labelText: 'Цена от, ₽',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                SizedBox(
                  width: 150,
                  child: TextField(
                    controller: _priceTo,
                    decoration: const InputDecoration(
                      labelText: 'Цена до, ₽',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                FilledButton(
                  onPressed: () {
                    widget.onChanged(
                      widget.query.copyWith(
                        priceFrom: _number(
                          _priceFrom.text,
                        ),
                        priceTo: _number(
                          _priceTo.text,
                        ),
                      ),
                    );
                  },
                  child: const Text(
                    'Применить',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 10,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                if (widget.showDeletedToggle) ...[
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
                TextButton.icon(
                  onPressed: () {
                    widget.onChanged(
                      ProductQuery(
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
