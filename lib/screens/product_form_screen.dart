import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/api_exceptions.dart';
import '../models/category.dart';
import '../models/product.dart';
import '../models/supplier.dart';
import '../state/category_list_notifier.dart';
import '../state/product_list_notifier.dart';
import '../state/supplier_list_notifier.dart';
import '../validation/validators.dart';
import '../widgets/dialogs.dart';
import '../widgets/entity_form_scaffold.dart';
import '../widgets/multi_select_field.dart';

class ProductFormScreen extends StatefulWidget {
  final int? id;

  const ProductFormScreen({
    super.key,
    this.id,
  });

  bool get isEditing => id != null;

  @override
  State<ProductFormScreen> createState() => _ProductFormScreenState();
}

class _ProductFormScreenState extends State<ProductFormScreen> {
  final _formKey = GlobalKey<FormState>();

  final _name = TextEditingController();

  final _article = TextEditingController();

  final _brand = TextEditingController();

  final _price = TextEditingController();

  final _stock = TextEditingController();

  final _description = TextEditingController();

  List<Category> _categories = [];

  List<Supplier> _suppliers = [];

  int? _supplierId;

  List<int> _categoryIds = [];

  Product? _original;

  bool _started = false;
  bool _loading = true;
  bool _dirty = false;

  String? _loadError;

  Map<String, String> _serverErrors = {};

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
          await context.read<CategoryListNotifier>().getAllActive();

      final suppliers =
          await context.read<SupplierListNotifier>().getAllActive();

      Product? product;

      if (widget.id != null) {
        product = await context.read<ProductListNotifier>().findById(
              widget.id!,
            );
      }

      if (!mounted) {
        return;
      }

      setState(() {
        _categories = categories;
        _suppliers = suppliers;

        _original = product;

        if (product != null) {
          _name.text = product.name;

          _article.text = product.article;

          _brand.text = product.brand;

          _price.text = product.price.toString();

          _stock.text = product.stock.toString();

          _description.text = product.description;

          _supplierId = product.supplierId;

          _categoryIds = [
            ...product.categoryIds,
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

        _loadError = e.toString();
      });
    }
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

  Supplier? get _supplier {
    for (final supplier in _suppliers) {
      if (supplier.id == _supplierId) {
        return supplier;
      }
    }

    return null;
  }

  List<Category> get _availableCategories {
    final supplier = _supplier;

    if (supplier == null) {
      return [];
    }

    return _categories.where(
      (category) {
        final correctKind =
            category.kind == 'product' || category.kind == 'both';

        return correctKind &&
            supplier.allowedCategoryIds.contains(
              category.id,
            );
      },
    ).toList();
  }

  Future<bool> _save() async {
    setState(() {
      _serverErrors = {};
    });

    if (!_formKey.currentState!.validate()) {
      return false;
    }

    final product = Product(
      id: _original?.id ?? 0,
      name: _name.text.trim(),
      article: _article.text.trim(),
      brand: _brand.text.trim(),
      price: double.parse(
        _price.text.replaceAll(',', '.'),
      ),
      stock: int.parse(
        _stock.text,
      ),
      supplierId: _supplierId!,
      categoryIds: [
        ..._categoryIds,
      ],
      description: _description.text.trim(),
      deletedAt: _original?.deletedAt,
    );

    try {
      final notifier = context.read<ProductListNotifier>();

      if (widget.isEditing) {
        await notifier.update(
          product,
        );
      } else {
        await notifier.create(
          product,
        );
      }

      _dirty = false;

      return true;
    } on ValidationException catch (e) {
      if (!mounted) {
        return false;
      }

      setState(() {
        _serverErrors = e.errors;
      });

      _formKey.currentState?.validate();

      return false;
    } on ApiException catch (e) {
      if (mounted) {
        await messageDialog(
          context,
          title: 'Ошибка сервера',
          message: e.message,
        );
      }

      return false;
    }
  }

  @override
  void dispose() {
    _name.dispose();
    _article.dispose();
    _brand.dispose();
    _price.dispose();
    _stock.dispose();
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
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (_loadError != null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text(
            'Ошибка',
          ),
        ),
        body: Center(
          child: Text(
            _loadError!,
          ),
        ),
      );
    }

    if (widget.isEditing && _original == null) {
      return const Scaffold(
        body: Center(
          child: Text(
            'Товар не найден',
          ),
        ),
      );
    }

    return EntityFormScaffold(
      title: widget.isEditing ? 'Редактирование товара' : 'Новый товар',
      formKey: _formKey,
      isDirty: _dirty,
      successLocation: '/products',
      submitText: widget.isEditing ? 'Сохранить изменения' : 'Создать товар',
      onSubmit: _save,
      children: [
        TextFormField(
          controller: _name,
          decoration: const InputDecoration(
            labelText: 'Название',
            border: OutlineInputBorder(),
          ),
          onChanged: (_) {
            _changed('name');
          },
          validator: (value) {
            return _serverErrors['name'] ??
                Validators.requiredAndMax(
                  value,
                  100,
                  field: 'Название',
                );
          },
        ),
        const SizedBox(height: 14),
        TextFormField(
          controller: _article,
          decoration: const InputDecoration(
            labelText: 'Артикул',
            border: OutlineInputBorder(),
          ),
          onChanged: (_) {
            _changed('article');
          },
          validator: (value) {
            return _serverErrors['article'] ??
                Validators.requiredAndMax(
                  value,
                  30,
                  field: 'Артикул',
                );
          },
        ),
        const SizedBox(height: 14),
        TextFormField(
          controller: _brand,
          decoration: const InputDecoration(
            labelText: 'Бренд',
            border: OutlineInputBorder(),
          ),
          onChanged: (_) {
            _changed('brand');
          },
          validator: (value) {
            return _serverErrors['brand'] ??
                Validators.requiredAndMax(
                  value,
                  60,
                  field: 'Бренд',
                );
          },
        ),
        const SizedBox(height: 14),
        DropdownButtonFormField<int>(
          initialValue: _supplierId,
          isExpanded: true,
          decoration: const InputDecoration(
            labelText: 'Поставщик',
            border: OutlineInputBorder(),
          ),
          items: _suppliers.map(
            (supplier) {
              return DropdownMenuItem<int>(
                value: supplier.id,
                child: Text(
                  supplier.name,
                ),
              );
            },
          ).toList(),
          validator: (value) {
            return _serverErrors['supplierId'] ??
                Validators.requiredId(
                  value,
                  field: 'поставщика',
                );
          },
          onChanged: (value) {
            setState(() {
              _supplierId = value;

              _serverErrors.remove(
                'supplierId',
              );

              _serverErrors.remove(
                'categoryIds',
              );

              final supplier = _supplier;

              if (supplier != null) {
                _categoryIds = _categoryIds
                    .where(
                      supplier.allowedCategoryIds.contains,
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
          items: _availableCategories,
          selectedIds: _categoryIds,
          idOf: (category) => category.id,
          labelOf: (category) => category.name,
          validator: (value) {
            return _serverErrors['categoryIds'] ??
                Validators.requiredIds(
                  value,
                  field: 'категории',
                );
          },
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
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
            labelText: 'Цена, ₽',
            border: OutlineInputBorder(),
          ),
          onChanged: (_) {
            _changed('price');
          },
          validator: (value) {
            return _serverErrors['price'] ??
                Validators.numberRange(
                  value,
                  min: 1,
                  max: 10000000,
                  field: 'Цена',
                );
          },
        ),
        const SizedBox(height: 14),
        TextFormField(
          controller: _stock,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
            labelText: 'Количество на складе',
            border: OutlineInputBorder(),
          ),
          onChanged: (_) {
            _changed('stock');
          },
          validator: (value) {
            return _serverErrors['stock'] ??
                Validators.integerRange(
                  value,
                  min: 0,
                  max: 100000,
                  field: 'Количество',
                );
          },
        ),
        const SizedBox(height: 14),
        TextFormField(
          controller: _description,
          maxLines: 4,
          decoration: const InputDecoration(
            labelText: 'Описание',
            border: OutlineInputBorder(),
          ),
          onChanged: (_) {
            _changed(
              'description',
            );
          },
          validator: (value) {
            return Validators.requiredAndMax(
              value,
              500,
              field: 'Описание',
            );
          },
        ),
      ],
    );
  }
}
