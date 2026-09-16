import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../core/api_exceptions.dart';
import '../state/auth_notifier.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({
    super.key,
  });

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();

  final _username = TextEditingController();

  final _fullName = TextEditingController();

  final _password = TextEditingController();

  final _confirm = TextEditingController();

  Map<String, String> _serverErrors = {};

  bool _loading = false;

  bool get _lengthOk => _password.text.length >= 8;

  bool get _digitOk => RegExp(
        r'[0-9]',
      ).hasMatch(
        _password.text,
      );

  bool get _specialOk => RegExp(
        r'[^A-Za-zА-Яа-яЁё0-9]',
      ).hasMatch(
        _password.text,
      );

  bool get _passwordOk => _lengthOk && _digitOk && _specialOk;

  Widget _requirement(
    String text,
    bool ok,
  ) {
    return Row(
      children: [
        Icon(
          ok ? Icons.check_circle : Icons.cancel,
          size: 18,
          color: ok ? Colors.green : Colors.red,
        ),
        const SizedBox(
          width: 6,
        ),
        Text(text),
      ],
    );
  }

  Future<void> _register() async {
    setState(() {
      _serverErrors = {};
    });

    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (!_passwordOk) {
      return;
    }

    setState(() {
      _loading = true;
    });

    try {
      await context.read<AuthNotifier>().register(
            username: _username.text.trim(),
            fullName: _fullName.text.trim(),
            password: _password.text,
          );

      if (!mounted) {
        return;
      }

      context.go('/');
    } on ValidationException catch (e) {
      setState(() {
        _serverErrors = e.errors;
      });

      _formKey.currentState?.validate();
    } on ApiException catch (e) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(
        SnackBar(
          content: Text(e.message),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _loading = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _username.dispose();
    _fullName.dispose();
    _password.dispose();
    _confirm.dispose();

    super.dispose();
  }

  @override
  Widget build(
    BuildContext context,
  ) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Регистрация'),
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(
            24,
          ),
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              maxWidth: 480,
            ),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  TextFormField(
                    controller: _username,
                    decoration: const InputDecoration(
                      labelText: 'Логин',
                      border: OutlineInputBorder(),
                    ),
                    onChanged: (_) {
                      setState(() {
                        _serverErrors.remove(
                          'username',
                        );
                      });
                    },
                    validator: (value) {
                      if (_serverErrors['username'] != null) {
                        return _serverErrors['username'];
                      }

                      if (value == null || value.trim().isEmpty) {
                        return 'Введите логин';
                      }

                      return null;
                    },
                  ),
                  const SizedBox(
                    height: 14,
                  ),
                  TextFormField(
                    controller: _fullName,
                    decoration: const InputDecoration(
                      labelText: 'Имя пользователя',
                      border: OutlineInputBorder(),
                    ),
                    onChanged: (_) {
                      setState(() {
                        _serverErrors.remove(
                          'fullName',
                        );
                      });
                    },
                    validator: (value) {
                      if (_serverErrors['fullName'] != null) {
                        return _serverErrors['fullName'];
                      }

                      if (value == null || value.trim().isEmpty) {
                        return 'Введите имя';
                      }

                      if (value.trim().length > 100) {
                        return 'Имя не должно быть длиннее 100 символов';
                      }

                      return null;
                    },
                  ),
                  const SizedBox(
                    height: 14,
                  ),
                  TextFormField(
                    controller: _password,
                    obscureText: true,
                    decoration: const InputDecoration(
                      labelText: 'Пароль',
                      border: OutlineInputBorder(),
                    ),
                    onChanged: (_) {
                      setState(() {
                        _serverErrors.remove(
                          'password',
                        );
                      });
                    },
                    validator: (value) {
                      if (_serverErrors['password'] != null) {
                        return _serverErrors['password'];
                      }

                      if (value == null || value.isEmpty) {
                        return 'Введите пароль';
                      }

                      if (!_passwordOk) {
                        return 'Пароль не соответствует требованиям';
                      }

                      return null;
                    },
                  ),
                  const SizedBox(
                    height: 10,
                  ),
                  _requirement(
                    'Не менее 8 символов',
                    _lengthOk,
                  ),
                  _requirement(
                    'Есть цифра',
                    _digitOk,
                  ),
                  _requirement(
                    'Есть специальный символ',
                    _specialOk,
                  ),
                  const SizedBox(
                    height: 14,
                  ),
                  TextFormField(
                    controller: _confirm,
                    obscureText: true,
                    decoration: const InputDecoration(
                      labelText: 'Повторите пароль',
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) {
                      if (value != _password.text) {
                        return 'Пароли не совпадают';
                      }

                      return null;
                    },
                  ),
                  const SizedBox(
                    height: 20,
                  ),
                  FilledButton(
                    onPressed: _loading ? null : _register,
                    child: Text(
                      _loading ? 'Регистрация...' : 'Зарегистрироваться',
                    ),
                  ),
                  TextButton(
                    onPressed: () {
                      context.go(
                        '/login',
                      );
                    },
                    child: const Text(
                      'Уже есть аккаунт',
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
