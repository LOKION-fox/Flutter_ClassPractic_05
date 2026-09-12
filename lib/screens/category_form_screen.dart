import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/api_exceptions.dart';
import '../models/category.dart';
import '../state/category_list_notifier.dart';
import '../validation/validators.dart';
import '../widgets/dialogs.dart';
import '../widgets/entity_form_scaffold.dart';

class CategoryFormScreen
    extends StatefulWidget {
  final int? id;

  const CategoryFormScreen({
    super.key,
    this.id,
  });

  bool get isEditing =>
      id != null;

  @override
  State<CategoryFormScreen>
      createState() =>
          _CategoryFormScreenState();
}

class _CategoryFormScreenState
    extends State<CategoryFormScreen> {
  final _formKey =
      GlobalKey<FormState>();

  final _name =
      TextEditingController();

  final _description =
      TextEditingController();

  String? _kind;

  Category? _original;

  bool _started = false;
  bool _loading = true;
  bool _dirty = false;

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
    if (widget.id == null) {
      setState(() {
        _loading = false;
      });

      return;
    }

    try {
      final value = await context
          .read<
              CategoryListNotifier>()
          .findById(widget.id!);

      if (!mounted) {
        return;
      }

      setState(() {
        _original = value;

        if (value != null) {
          _name.text =
              value.name;

          _kind = value.kind;

          _description.text =
              value.description;
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

    if (!_formKey.currentState!
        .validate()) {
      return false;
    }

    final category = Category(
      id: _original?.id ?? 0,

      name:
          _name.text.trim(),

      kind: _kind!,

      description:
          _description.text.trim(),

      deletedAt:
          _original?.deletedAt,
    );

    try {
      final notifier =
          context.read<
              CategoryListNotifier>();

      if (widget.isEditing) {
        await notifier.update(
          category,
        );
      } else {
        await notifier.create(
          category,
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

    return EntityFormScaffold(
      title: widget.isEditing
          ? 'Редактирование категории'
          : 'Новая категория',

      formKey: _formKey,

      isDirty: _dirty,

      successLocation:
          '/categories',

      onSubmit: _save,

      children: [
        TextFormField(
          controller: _name,

          decoration:
              const InputDecoration(
            labelText: 'Название',
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
                field: 'Название',
              ),
        ),

        const SizedBox(height: 14),

        DropdownButtonFormField<String>(
          initialValue: _kind,

          decoration:
              const InputDecoration(
            labelText:
                'Тип категории',
            border:
                OutlineInputBorder(),
          ),

          items: const [
            DropdownMenuItem(
              value: 'product',
              child: Text(
                'Для товаров',
              ),
            ),
            DropdownMenuItem(
              value: 'animal',
              child: Text(
                'Для животных',
              ),
            ),
            DropdownMenuItem(
              value: 'both',
              child: Text('Общая'),
            ),
          ],

          validator: (value) =>
              _serverErrors[
                  'kind'] ??
              (value == null
                  ? 'Выберите тип'
                  : null),

          onChanged: (value) {
            setState(() {
              _kind = value;
              _dirty = true;

              _serverErrors.remove(
                'kind',
              );
            });
          },
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
                300,
                field: 'Описание',
              ),
        ),
      ],
    );
  }
}