import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/api_exceptions.dart';
import '../models/customer.dart';
import '../state/customer_list_notifier.dart';
import '../validation/validators.dart';
import '../widgets/dialogs.dart';
import '../widgets/entity_form_scaffold.dart';

class CustomerFormScreen extends StatefulWidget {
  final int? id;

  const CustomerFormScreen({
    super.key,
    this.id,
  });

  bool get isEditing => id != null;

  @override
  State<CustomerFormScreen> createState() => _CustomerFormScreenState();
}

class _CustomerFormScreenState extends State<CustomerFormScreen> {
  final _formKey = GlobalKey<FormState>();

  final _firstName = TextEditingController();

  final _lastName = TextEditingController();

  final _email = TextEditingController();

  final _phone = TextEditingController();

  final _cardNumber = TextEditingController();

  final _points = TextEditingController();

  String? _level;

  Customer? _original;

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
    if (widget.id == null) {
      _points.text = '0';
      _level = 'Silver';

      setState(() {
        _loading = false;
      });

      return;
    }

    try {
      final customer = await context.read<CustomerListNotifier>().findById(
            widget.id!,
          );

      if (!mounted) {
        return;
      }

      setState(() {
        _original = customer;

        if (customer != null) {
          _firstName.text = customer.firstName;

          _lastName.text = customer.lastName;

          _email.text = customer.email;

          _phone.text = customer.phone;

          _cardNumber.text = customer.loyaltyCard.number;

          _points.text = customer.loyaltyCard.points.toString();

          _level = customer.loyaltyCard.level;
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

    final card = LoyaltyCard(
      number: _cardNumber.text.trim(),
      level: _level!,
      points: int.parse(
        _points.text,
      ),
      issuedAt: _original?.loyaltyCard.issuedAt ?? DateTime.now(),
    );

    final customer = Customer(
      id: _original?.id ?? 0,
      firstName: _firstName.text.trim(),
      lastName: _lastName.text.trim(),
      email: _email.text.trim(),
      phone: _phone.text.trim(),
      loyaltyCard: card,
      deletedAt: _original?.deletedAt,
    );

    try {
      final notifier = context.read<CustomerListNotifier>();

      if (widget.isEditing) {
        await notifier.update(
          customer,
        );
      } else {
        await notifier.create(
          customer,
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
    _firstName.dispose();
    _lastName.dispose();
    _email.dispose();
    _phone.dispose();
    _cardNumber.dispose();
    _points.dispose();

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
      title:
          widget.isEditing ? 'Редактирование покупателя' : 'Новый покупатель',
      formKey: _formKey,
      isDirty: _dirty,
      successLocation: '/customers',
      onSubmit: _save,
      children: [
        TextFormField(
          controller: _lastName,
          decoration: const InputDecoration(
            labelText: 'Фамилия',
            border: OutlineInputBorder(),
          ),
          onChanged: (_) {
            _changed('lastName');
          },
          validator: (value) =>
              _serverErrors['lastName'] ??
              Validators.requiredAndMax(
                value,
                80,
                field: 'Фамилия',
              ),
        ),
        const SizedBox(height: 14),
        TextFormField(
          controller: _firstName,
          decoration: const InputDecoration(
            labelText: 'Имя',
            border: OutlineInputBorder(),
          ),
          onChanged: (_) {
            _changed(
              'firstName',
            );
          },
          validator: (value) =>
              _serverErrors['firstName'] ??
              Validators.requiredAndMax(
                value,
                80,
                field: 'Имя',
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
        TextFormField(
          controller: _phone,
          decoration: const InputDecoration(
            labelText: 'Телефон',
            border: OutlineInputBorder(),
          ),
          onChanged: (_) {
            _changed('phone');
          },
          validator: (value) =>
              _serverErrors['phone'] ??
              Validators.phone(
                value,
              ),
        ),
        const SizedBox(height: 24),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(
              16,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Карта лояльности',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(
                  height: 14,
                ),
                TextFormField(
                  controller: _cardNumber,
                  decoration: const InputDecoration(
                    labelText: 'Номер карты',
                    border: OutlineInputBorder(),
                  ),
                  onChanged: (_) {
                    _changed(
                      'loyaltyCardNumber',
                    );
                  },
                  validator: (value) =>
                      _serverErrors['loyaltyCardNumber'] ??
                      Validators.requiredAndMax(
                        value,
                        30,
                        field: 'Номер карты',
                      ),
                ),
                const SizedBox(
                  height: 14,
                ),
                DropdownButtonFormField<String>(
                  initialValue: _level,
                  decoration: const InputDecoration(
                    labelText: 'Уровень карты',
                    border: OutlineInputBorder(),
                  ),
                  items: const [
                    DropdownMenuItem(
                      value: 'Silver',
                      child: Text('Silver'),
                    ),
                    DropdownMenuItem(
                      value: 'Gold',
                      child: Text('Gold'),
                    ),
                    DropdownMenuItem(
                      value: 'Platinum',
                      child: Text(
                        'Platinum',
                      ),
                    ),
                  ],
                  validator: (value) =>
                      _serverErrors['loyaltyCardLevel'] ??
                      (value == null ? 'Выберите уровень' : null),
                  onChanged: (value) {
                    setState(() {
                      _level = value;
                      _dirty = true;

                      _serverErrors.remove(
                        'loyaltyCardLevel',
                      );
                    });
                  },
                ),
                const SizedBox(
                  height: 14,
                ),
                TextFormField(
                  controller: _points,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Бонусные баллы',
                    border: OutlineInputBorder(),
                  ),
                  onChanged: (_) {
                    _changed(
                      'loyaltyCardPoints',
                    );
                  },
                  validator: (value) =>
                      _serverErrors['loyaltyCardPoints'] ??
                      Validators.integerRange(
                        value,
                        min: 0,
                        max: 1000000,
                        field: 'Количество баллов',
                      ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
