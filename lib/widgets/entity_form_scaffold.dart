import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'dialogs.dart';

class EntityFormScaffold
    extends StatefulWidget {
  final String title;

  final GlobalKey<FormState> formKey;

  final List<Widget> children;

  final bool isDirty;

  final Future<bool> Function()
      onSubmit;

  final String successLocation;

  final String submitText;

  const EntityFormScaffold({
    super.key,
    required this.title,
    required this.formKey,
    required this.children,
    required this.isDirty,
    required this.onSubmit,
    required this.successLocation,
    this.submitText = 'Сохранить',
  });

  @override
  State<EntityFormScaffold>
      createState() =>
          _EntityFormScaffoldState();
}

class _EntityFormScaffoldState
    extends State<EntityFormScaffold> {
  bool _saving = false;

  bool _allowPop = false;

  Future<bool> _canLeave() async {
    if (!widget.isDirty) {
      return true;
    }

    return confirmDialog(
      context,
      title:
          'Несохранённые изменения',
      message:
          'Изменения не сохранены. Выйти без сохранения?',
    );
  }

  Future<void> _cancel() async {
    final allow =
        await _canLeave();

    if (!allow || !mounted) {
      return;
    }

    setState(() {
      _allowPop = true;
    });

    if (context.canPop()) {
      context.pop();
    } else {
      context.go(
        widget.successLocation,
      );
    }
  }

  Future<void> _submit() async {
    if (_saving) {
      return;
    }

    setState(() {
      _saving = true;
    });

    try {
      final success =
          await widget.onSubmit();

      if (!mounted) {
        return;
      }

      if (success) {
        setState(() {
          _allowPop = true;
        });

        context.go(
          widget.successLocation,
        );
      }
    } catch (e) {
      if (!mounted) {
        return;
      }

      await messageDialog(
        context,
        title: 'Ошибка',
        message: e.toString(),
      );
    } finally {
      if (mounted) {
        setState(() {
          _saving = false;
        });
      }
    }
  }

  @override
  Widget build(
    BuildContext context,
  ) {
    return PopScope(
      canPop:
          _allowPop ||
          !widget.isDirty,

      onPopInvokedWithResult:
          (
        didPop,
        result,
      ) async {
        if (didPop ||
            _allowPop ||
            !widget.isDirty) {
          return;
        }

        final allow =
            await _canLeave();

        if (!allow ||
            !mounted) {
          return;
        }

        setState(() {
          _allowPop = true;
        });

        if (context.canPop()) {
          context.pop();
        } else {
          context.go(
            widget.successLocation,
          );
        }
      },

      child: Scaffold(
        appBar: AppBar(
          title: Text(
            widget.title,
          ),
        ),

        body:
            SingleChildScrollView(
          padding:
              const EdgeInsets.all(
            24,
          ),

          child: Center(
            child: ConstrainedBox(
              constraints:
                  const BoxConstraints(
                maxWidth: 750,
              ),

              child: Form(
                key: widget.formKey,

                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment
                          .stretch,

                  children: [
                    ...widget.children,

                    const SizedBox(
                      height: 24,
                    ),

                    Wrap(
                      spacing: 12,
                      runSpacing: 12,

                      children: [
                        FilledButton(
                          onPressed:
                              _saving
                                  ? null
                                  : _submit,

                          child: Text(
                            _saving
                                ? 'Сохранение...'
                                : widget
                                    .submitText,
                          ),
                        ),

                        OutlinedButton(
                          onPressed:
                              _saving
                                  ? null
                                  : _cancel,

                          child:
                              const Text(
                            'Отмена',
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}