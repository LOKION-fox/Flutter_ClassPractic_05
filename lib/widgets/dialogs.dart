import 'package:flutter/material.dart';

Widget _dialogContent(
  String message,
) {
  return ConstrainedBox(
    constraints: const BoxConstraints(
      maxWidth: 520,
    ),
    child: Text(message),
  );
}

Future<bool> confirmDialog(
  BuildContext context, {
  required String title,
  required String message,
}) async {
  return await showDialog<bool>(
        context: context,
        builder: (context) {
          return AlertDialog(
            insetPadding: const EdgeInsets.symmetric(
              horizontal: 24,
              vertical: 24,
            ),
            title: Text(
              title,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            content: _dialogContent(
              message,
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(
                    context,
                    false,
                  );
                },
                child: const Text(
                  'Отмена',
                ),
              ),
              FilledButton(
                onPressed: () {
                  Navigator.pop(
                    context,
                    true,
                  );
                },
                child: const Text(
                  'Да',
                ),
              ),
            ],
          );
        },
      ) ??
      false;
}

Future<void> messageDialog(
  BuildContext context, {
  required String title,
  required String message,
}) {
  return showDialog<void>(
    context: context,
    builder: (context) {
      return AlertDialog(
        insetPadding: const EdgeInsets.symmetric(
          horizontal: 24,
          vertical: 24,
        ),
        title: Text(
          title,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        content: _dialogContent(
          message,
        ),
        actions: [
          FilledButton(
            onPressed: () {
              Navigator.pop(
                context,
              );
            },
            child: const Text('ОК'),
          ),
        ],
      );
    },
  );
}
