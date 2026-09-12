import 'dart:async';

import 'package:flutter/material.dart';

import '../models/animal_query.dart';
import '../models/supplier.dart';

class AnimalFilters
    extends StatefulWidget {
  final AnimalQuery query;

  final List<Supplier> suppliers;

  final ValueChanged<AnimalQuery>
      onChanged;

  final bool showDeletedToggle;

  const AnimalFilters({
    super.key,
    required this.query,
    required this.suppliers,
    required this.onChanged,
    this.showDeletedToggle = true,
  });

  @override
  State<AnimalFilters>
      createState() =>
          _AnimalFiltersState();
}

class _AnimalFiltersState
    extends State<AnimalFilters> {
  late final TextEditingController
      _search;

  Timer? _timer;

  @override
  void initState() {
    super.initState();

    _search =
        TextEditingController(
      text: widget.query.search,
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    _search.dispose();

    super.dispose();
  }

  void _searchChanged(
    String value,
  ) {
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
        padding:
            const EdgeInsets.all(16),

        child: Column(
          children: [
            TextField(
              controller: _search,

              onChanged:
                  _searchChanged,

              decoration:
                  const InputDecoration(
                labelText:
                    'Поиск по имени, породе или стране',
                prefixIcon:
                    Icon(Icons.search),
                border:
                    OutlineInputBorder(),
              ),
            ),

            const SizedBox(height: 14),

            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                SizedBox(
                  width: 190,
                  child:
                      DropdownButtonFormField<
                          String>(
                    initialValue:
                        widget
                            .query
                            .species,
                    isExpanded: true,
                    decoration:
                        const InputDecoration(
                      labelText: 'Вид',
                      border:
                          OutlineInputBorder(),
                    ),
                    items: const [
                      DropdownMenuItem(
                        value: null,
                        child:
                            Text('Все'),
                      ),
                      DropdownMenuItem(
                        value: 'Кошка',
                        child:
                            Text('Кошка'),
                      ),
                      DropdownMenuItem(
                        value: 'Собака',
                        child:
                            Text('Собака'),
                      ),
                      DropdownMenuItem(
                        value: 'Хомяк',
                        child:
                            Text('Хомяк'),
                      ),
                      DropdownMenuItem(
                        value: 'Попугай',
                        child:
                            Text('Попугай'),
                      ),
                      DropdownMenuItem(
                        value: 'Кролик',
                        child:
                            Text('Кролик'),
                      ),
                      DropdownMenuItem(
                        value:
                            'Морская свинка',
                        child: Text(
                          'Морская свинка',
                        ),
                      ),
                    ],
                    onChanged: (value) {
                      widget.onChanged(
                        widget.query
                            .copyWith(
                          species: value,
                        ),
                      );
                    },
                  ),
                ),

                SizedBox(
                  width: 170,
                  child:
                      DropdownButtonFormField<
                          String>(
                    initialValue:
                        widget.query.sex,
                    decoration:
                        const InputDecoration(
                      labelText: 'Пол',
                      border:
                          OutlineInputBorder(),
                    ),
                    items: const [
                      DropdownMenuItem(
                        value: null,
                        child:
                            Text('Любой'),
                      ),
                      DropdownMenuItem(
                        value: 'Самец',
                        child:
                            Text('Самец'),
                      ),
                      DropdownMenuItem(
                        value: 'Самка',
                        child:
                            Text('Самка'),
                      ),
                    ],
                    onChanged: (value) {
                      widget.onChanged(
                        widget.query
                            .copyWith(
                          sex: value,
                        ),
                      );
                    },
                  ),
                ),

                SizedBox(
                  width: 240,
                  child:
                      DropdownButtonFormField<
                          int>(
                    initialValue:
                        widget
                            .query
                            .supplierId,
                    isExpanded: true,
                    decoration:
                        const InputDecoration(
                      labelText:
                          'Поставщик',
                      border:
                          OutlineInputBorder(),
                    ),
                    items: [
                      const DropdownMenuItem<
                          int>(
                        value: null,
                        child:
                            Text('Все'),
                      ),
                      ...widget.suppliers
                          .map(
                        (s) =>
                            DropdownMenuItem(
                          value: s.id,
                          child:
                              Text(s.name),
                        ),
                      ),
                    ],
                    onChanged: (value) {
                      widget.onChanged(
                        widget.query
                            .copyWith(
                          supplierId:
                              value,
                        ),
                      );
                    },
                  ),
                ),

                if (widget
                    .showDeletedToggle)
                  Row(
                    mainAxisSize:
                        MainAxisSize.min,
                    children: [
                      Switch(
                        value: widget
                            .query
                            .includeDeleted,
                        onChanged: (value) {
                          widget.onChanged(
                            widget.query
                                .copyWith(
                              includeDeleted:
                                  value,
                            ),
                          );
                        },
                      ),
                      const Text(
                        'Показывать удалённых',
                      ),
                    ],
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}