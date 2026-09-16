import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../core/api_exceptions.dart';
import '../state/auth_notifier.dart';

class LoginScreen extends StatefulWidget {
  final String? from;

  const LoginScreen({
    super.key,
    this.from,
  });

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();

  final _username = TextEditingController();

  final _password = TextEditingController();

  bool _loading = false;

  String? _error;

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      await context.read<AuthNotifier>().login(
            _username.text.trim(),
            _password.text,
          );

      if (!mounted) {
        return;
      }

      final target = widget.from != null && widget.from!.startsWith('/')
          ? widget.from!
          : '/';

      context.go(target);
    } on UnauthorizedException {
      setState(() {
        _error = 'Неверный логин или пароль';
      });
    } on ApiException catch (e) {
      setState(() {
        _error = e.message;
      });
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
    _password.dispose();

    super.dispose();
  }

  @override
  Widget build(
    BuildContext context,
  ) {
    final auth = context.watch<AuthNotifier>();

    final notice = auth.notice;

    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(
            24,
          ),
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              maxWidth: 430,
            ),
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(
                  24,
                ),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        'Вход',
                        style: Theme.of(
                          context,
                        ).textTheme.headlineMedium,
                      ),
                      if (notice != null) ...[
                        const SizedBox(
                          height: 16,
                        ),
                        Container(
                          padding: const EdgeInsets.all(
                            12,
                          ),
                          decoration: BoxDecoration(
                            color: Theme.of(
                              context,
                            ).colorScheme.secondaryContainer,
                            borderRadius: BorderRadius.circular(
                              8,
                            ),
                          ),
                          child: Text(notice),
                        ),
                      ],
                      if (_error != null) ...[
                        const SizedBox(
                          height: 16,
                        ),
                        Text(
                          _error!,
                          style: TextStyle(
                            color: Theme.of(
                              context,
                            ).colorScheme.error,
                          ),
                        ),
                      ],
                      const SizedBox(
                        height: 20,
                      ),
                      TextFormField(
                        controller: _username,
                        decoration: const InputDecoration(
                          labelText: 'Логин',
                          border: OutlineInputBorder(),
                        ),
                        validator: (value) {
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
                        controller: _password,
                        obscureText: true,
                        decoration: const InputDecoration(
                          labelText: 'Пароль',
                          border: OutlineInputBorder(),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Введите пароль';
                          }

                          return null;
                        },
                        onFieldSubmitted: (_) => _login(),
                      ),
                      const SizedBox(
                        height: 20,
                      ),
                      FilledButton(
                        onPressed: _loading ? null : _login,
                        child: Text(
                          _loading ? 'Вход...' : 'Войти',
                        ),
                      ),
                      const SizedBox(
                        height: 10,
                      ),
                      TextButton(
                        onPressed: _loading
                            ? null
                            : () {
                                context.go(
                                  '/register',
                                );
                              },
                        child: const Text(
                          'Регистрация',
                        ),
                      ),
                      const Divider(),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
