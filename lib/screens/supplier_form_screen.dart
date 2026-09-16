import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/api_exceptions.dart';
import '../models/category.dart';
import '../models/supplier.dart';
import '../state/category_list_notifier.dart';
import '../state/supplier_list_notifier.dart';
import '../validation/validators.dart';
import '../widgets/dialogs.dart';
import '../widgets/entity_form_scaffold.dart';
import '../widgets/multi_select_field.dart';

class SupplierFormScreen extends StatefulWidget {
  final int? id;

  const SupplierFormScreen({
    super.key,
    this.id,
  });

  bool get isEditing => id != null;

  @override
  State<SupplierFormScreen> createState() => _SupplierFormScreenState();
}

class _SupplierFormScreenState extends State<SupplierFormScreen> {
  final _formKey = GlobalKey<FormState>();

  final _name = TextEditingController();

  final _country = TextEditingController();

  final _email = TextEditingController();

  List<Category> _categories = [];

  List<int> _allowedIds = [];

  Supplier? _original;

  bool _started = false;
  bool _loading = true;
  bool _dirty = false;

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

      Supplier? supplier;

      if (widget.id != null) {
        supplier = await context.read<SupplierListNotifier>().findById(
              widget.id!,
            );
      }

      if (!mounted) {
        return;
      }

      setState(() {
        _categories = categories;
        _original = supplier;

        if (supplier != null) {
          _name.text = supplier.name;

          _country.text = supplier.country;

          _email.text = supplier.email;

          _allowedIds = [
            ...supplier.allowedCategoryIds,
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
      });

      await messageDialog(
        context,
        title: 'Ошибка',
        message: e.toString(),
      );
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

  Future<bool> _save() async {
    setState(() {
      _serverErrors = {};
    });

    if (!_formKey.currentState!.validate()) {
      return false;
    }

    final supplier = Supplier(
      id: _original?.id ?? 0,
      name: _name.text.trim(),
      country: _country.text.trim(),
      email: _email.text.trim(),
      allowedCategoryIds: [
        ..._allowedIds,
      ],
      deletedAt: _original?.deletedAt,
    );

    try {
      final notifier = context.read<SupplierListNotifier>();

      if (widget.isEditing) {
        await notifier.update(
          supplier,
        );
      } else {
        await notifier.create(
          supplier,
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
    _country.dispose();
    _email.dispose();

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

    return EntityFormScaffold(
      title: widget.isEditing ? 'Редактирование поставщика' : 'Новый поставщик',
      formKey: _formKey,
      isDirty: _dirty,
      successLocation: '/suppliers',
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
          validator: (value) =>
              _serverErrors['name'] ??
              Validators.requiredAndMax(
                value,
                100,
                field: 'Название',
              ),
        ),
        const SizedBox(height: 14),
        TextFormField(
          controller: _country,
          decoration: const InputDecoration(
            labelText: 'Страна',
            border: OutlineInputBorder(),
          ),
          onChanged: (_) {
            _changed('country');
          },
          validator: (value) =>
              _serverErrors['country'] ??
              Validators.requiredAndMax(
                value,
                60,
                field: 'Страна',
              ),
        ),
        const SizedBox(height: 14),
        TextFormField(
          controller: _email,
          decoration: const InputDecoration(
            labelText: 'Email',
            border: OutlineInputBorder(),
          ),
          onChanged: (_) {
            _changed('email');
          },
          validator: (value) =>
              _serverErrors['email'] ??
              Validators.email(
                value,
              ),
        ),
        const SizedBox(height: 14),
        MultiSelectField<Category>(
          label: 'Доступные категории',
          items: _categories,
          selectedIds: _allowedIds,
          idOf: (item) => item.id,
          labelOf: (item) => item.name,
          validator: (value) =>
              _serverErrors['allowedCategoryIds'] ??
              Validators.requiredIds(
                value,
                field: 'категории',
              ),
          onChanged: (value) {
            setState(() {
              _allowedIds = value;

              _serverErrors.remove(
                'allowedCategoryIds',
              );

              _dirty = true;
            });
          },
        ),
      ],
    );
  }
}
