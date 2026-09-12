import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/api_exceptions.dart';
import '../models/animal.dart';
import '../models/category.dart';
import '../models/supplier.dart';
import '../state/animal_list_notifier.dart';
import '../state/category_list_notifier.dart';
import '../state/supplier_list_notifier.dart';
import '../validation/validators.dart';
import '../widgets/dialogs.dart';
import '../widgets/entity_form_scaffold.dart';
import '../widgets/multi_select_field.dart';

class AnimalFormScreen
    extends StatefulWidget {
  final int? id;

  const AnimalFormScreen({
    super.key,
    this.id,
  });

  bool get isEditing =>
      id != null;

  @override
  State<AnimalFormScreen>
      createState() =>
          _AnimalFormScreenState();
}

class _AnimalFormScreenState
    extends State<AnimalFormScreen> {
  final _formKey =
      GlobalKey<FormState>();

  final _name =
      TextEditingController();

  final _breed =
      TextEditingController();

  final _age =
      TextEditingController();

  final _country =
      TextEditingController();

  final _price =
      TextEditingController();

  final _description =
      TextEditingController();

  String? _species;
  String? _sex;
  int? _supplierId;

  List<int> _categoryIds = [];

  List<Category> _categories = [];
  List<Supplier> _suppliers = [];

  Animal? _original;

  bool _started = false;
  bool _loading = true;
  bool _dirty = false;

  String? _loadError;

  Map<String, String>
      _serverErrors = {};

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    if (!_started) {
      _started = true;
      _load();
    }
  }

  Future<void> _load() async {
    try {
      final categories =
          await context
              .read<
                  CategoryListNotifier>()
              .getAllActive();

      final suppliers =
          await context
              .read<
                  SupplierListNotifier>()
              .getAllActive();

      Animal? animal;

      if (widget.id != null) {
        animal = await context
            .read<
                AnimalListNotifier>()
            .findById(
              widget.id!,
            );
      }

      if (!mounted) {
        return;
      }

      setState(() {
        _categories = categories;
        _suppliers = suppliers;
        _original = animal;

        if (animal != null) {
          _name.text =
              animal.name;

          _species =
              animal.species;

          _breed.text =
              animal.breed;

          _age.text =
              animal.ageMonths
                  .toString();

          _sex = animal.sex;

          _country.text =
              animal.country;

          _price.text =
              animal.price
                  .toString();

          _description.text =
              animal.description;

          _supplierId =
              animal.supplierId;

          _categoryIds = [
            ...animal.categoryIds,
          ];
        }

        _loading = false;
      });
    } catch (e) {
      if (!mounted) {
        return;
      }

      setState(() {
        _loading = false;
        _loadError =
            e.toString();
      });
    }
  }

  Supplier? get _supplier {
    for (final supplier
        in _suppliers) {
      if (supplier.id ==
          _supplierId) {
        return supplier;
      }
    }

    return null;
  }

  List<Category>
      get _availableCategories {
    final supplier = _supplier;

    if (supplier == null) {
      return [];
    }

    return _categories.where(
      (category) {
        return (category.kind ==
                    'animal' ||
                category.kind ==
                    'both') &&
            supplier
                .allowedCategoryIds
                .contains(
                  category.id,
                );
      },
    ).toList();
  }

  void _changed(
    String field,
  ) {
    setState(() {
      _dirty = true;

      _serverErrors.remove(
        field,
      );
    });
  }

  Future<bool> _save() async {
    setState(() {
      _serverErrors = {};
    });

    if (!_formKey.currentState!
        .validate()) {
      return false;
    }

    final animal = Animal(
      id: _original?.id ?? 0,

      name:
          _name.text.trim(),

      species: _species!,

      breed:
          _breed.text.trim(),

      ageMonths:
          int.parse(_age.text),

      sex: _sex!,

      country:
          _country.text.trim(),

      price: double.parse(
        _price.text
            .replaceAll(',', '.'),
      ),

      supplierId:
          _supplierId!,

      categoryIds: [
        ..._categoryIds,
      ],

      description:
          _description.text.trim(),

      deletedAt:
          _original?.deletedAt,
    );

    try {
      final notifier =
          context.read<
              AnimalListNotifier>();

      if (widget.isEditing) {
        await notifier.update(
          animal,
        );
      } else {
        await notifier.create(
          animal,
        );
      }

      _dirty = false;

      return true;
    } on ValidationException catch (e) {
      if (!mounted) {
        return false;
      }

      setState(() {
        _serverErrors =
            e.errors;
      });

      _formKey.currentState
          ?.validate();

      return false;
    } on ApiException catch (e) {
      if (mounted) {
        await messageDialog(
          context,
          title:
              'Ошибка сервера',
          message: e.message,
        );
      }

      return false;
    }
  }

  @override
  void dispose() {
    _name.dispose();
    _breed.dispose();
    _age.dispose();
    _country.dispose();
    _price.dispose();
    _description.dispose();

    super.dispose();
  }

  @override
  Widget build(
    BuildContext context,
  ) {
    if (_loading) {
      return const Scaffold(
        body: Center(
          child:
              CircularProgressIndicator(),
        ),
      );
    }

    if (_loadError != null) {
      return Scaffold(
        body: Center(
          child: Text(
            _loadError!,
          ),
        ),
      );
    }

    if (widget.isEditing &&
        _original == null) {
      return const Scaffold(
        body: Center(
          child: Text(
            'Животное не найдено',
          ),
        ),
      );
    }

    return EntityFormScaffold(
      title: widget.isEditing
          ? 'Редактирование животного'
          : 'Новое животное',

      formKey: _formKey,

      isDirty: _dirty,

      successLocation:
          '/animals',

      onSubmit: _save,

      children: [
        TextFormField(
          controller: _name,

          decoration:
              const InputDecoration(
            labelText: 'Имя',
            border:
                OutlineInputBorder(),
          ),

          onChanged: (_) {
            _changed('name');
          },

          validator: (value) =>
              _serverErrors[
                  'name'] ??
              Validators
                  .requiredAndMax(
                value,
                80,
                field: 'Имя',
              ),
        ),

        const SizedBox(height: 14),

        DropdownButtonFormField<String>(
          initialValue: _species,

          isExpanded: true,

          decoration:
              const InputDecoration(
            labelText: 'Вид',
            border:
                OutlineInputBorder(),
          ),

          items: const [
            DropdownMenuItem(
              value: 'Кошка',
              child: Text('Кошка'),
            ),
            DropdownMenuItem(
              value: 'Собака',
              child: Text('Собака'),
            ),
            DropdownMenuItem(
              value: 'Хомяк',
              child: Text('Хомяк'),
            ),
            DropdownMenuItem(
              value: 'Попугай',
              child:
                  Text('Попугай'),
            ),
            DropdownMenuItem(
              value: 'Кролик',
              child: Text('Кролик'),
            ),
            DropdownMenuItem(
              value:
                  'Морская свинка',
              child: Text(
                'Морская свинка',
              ),
            ),
          ],

          validator: (value) =>
              _serverErrors[
                  'species'] ??
              (value == null
                  ? 'Выберите вид'
                  : null),

          onChanged: (value) {
            setState(() {
              _species = value;
              _dirty = true;

              _serverErrors.remove(
                'species',
              );
            });
          },
        ),

        const SizedBox(height: 14),

        TextFormField(
          controller: _breed,

          decoration:
              const InputDecoration(
            labelText: 'Порода',
            border:
                OutlineInputBorder(),
          ),

          onChanged: (_) {
            _changed('breed');
          },

          validator: (value) =>
              _serverErrors[
                  'breed'] ??
              Validators
                  .requiredAndMax(
                value,
                100,
                field: 'Порода',
              ),
        ),

        const SizedBox(height: 14),

        TextFormField(
          controller: _age,

          keyboardType:
              TextInputType.number,

          decoration:
              const InputDecoration(
            labelText:
                'Возраст, месяцев',
            border:
                OutlineInputBorder(),
          ),

          onChanged: (_) {
            _changed(
              'ageMonths',
            );
          },

          validator: (value) =>
              _serverErrors[
                  'ageMonths'] ??
              Validators.integerRange(
                value,
                min: 1,
                max: 240,
                field: 'Возраст',
              ),
        ),

        const SizedBox(height: 14),

        DropdownButtonFormField<String>(
          initialValue: _sex,

          decoration:
              const InputDecoration(
            labelText: 'Пол',
            border:
                OutlineInputBorder(),
          ),

          items: const [
            DropdownMenuItem(
              value: 'Самец',
              child: Text('Самец'),
            ),
            DropdownMenuItem(
              value: 'Самка',
              child: Text('Самка'),
            ),
          ],

          validator: (value) =>
              _serverErrors[
                  'sex'] ??
              (value == null
                  ? 'Выберите пол'
                  : null),

          onChanged: (value) {
            setState(() {
              _sex = value;
              _dirty = true;

              _serverErrors.remove(
                'sex',
              );
            });
          },
        ),

        const SizedBox(height: 14),

        TextFormField(
          controller: _country,

          decoration:
              const InputDecoration(
            labelText: 'Страна',
            border:
                OutlineInputBorder(),
          ),

          onChanged: (_) {
            _changed('country');
          },

          validator: (value) =>
              _serverErrors[
                  'country'] ??
              Validators
                  .requiredAndMax(
                value,
                60,
                field: 'Страна',
              ),
        ),

        const SizedBox(height: 14),

        DropdownButtonFormField<int>(
          initialValue: _supplierId,

          isExpanded: true,

          decoration:
              const InputDecoration(
            labelText: 'Поставщик',
            border:
                OutlineInputBorder(),
          ),

          items: _suppliers
              .map(
                (supplier) =>
                    DropdownMenuItem(
                  value: supplier.id,
                  child: Text(
                    supplier.name,
                  ),
                ),
              )
              .toList(),

          validator: (value) =>
              _serverErrors[
                  'supplierId'] ??
              Validators.requiredId(
                value,
                field:
                    'поставщика',
              ),

          onChanged: (value) {
            setState(() {
              _supplierId = value;

              _serverErrors.remove(
                'supplierId',
              );

              _serverErrors.remove(
                'categoryIds',
              );

              final supplier =
                  _supplier;

              if (supplier != null) {
                _categoryIds =
                    _categoryIds
                        .where(
                          supplier
                              .allowedCategoryIds
                              .contains,
                        )
                        .toList();
              }

              _dirty = true;
            });
          },
        ),

        const SizedBox(height: 14),

        MultiSelectField<Category>(
          label: 'Категории',

          items:
              _availableCategories,

          selectedIds:
              _categoryIds,

          idOf:
              (item) => item.id,

          labelOf:
              (item) => item.name,

          validator: (value) =>
              _serverErrors[
                  'categoryIds'] ??
              Validators.requiredIds(
                value,
                field: 'категории',
              ),

          onChanged: (value) {
            setState(() {
              _categoryIds = value;

              _serverErrors.remove(
                'categoryIds',
              );

              _dirty = true;
            });
          },
        ),

        const SizedBox(height: 14),

        TextFormField(
          controller: _price,

          keyboardType:
              TextInputType.number,

          decoration:
              const InputDecoration(
            labelText: 'Цена, ₽',
            border:
                OutlineInputBorder(),
          ),

          onChanged: (_) {
            _changed('price');
          },

          validator: (value) =>
              _serverErrors[
                  'price'] ??
              Validators.numberRange(
                value,
                min: 1,
                max: 10000000,
                field: 'Цена',
              ),
        ),

        const SizedBox(height: 14),

        TextFormField(
          controller:
              _description,

          maxLines: 4,

          decoration:
              const InputDecoration(
            labelText: 'Описание',
            border:
                OutlineInputBorder(),
          ),

          onChanged: (_) {
            _changed(
              'description',
            );
          },

          validator: (value) =>
              Validators
                  .requiredAndMax(
                value,
                500,
                field: 'Описание',
              ),
        ),
      ],
    );
  }
}