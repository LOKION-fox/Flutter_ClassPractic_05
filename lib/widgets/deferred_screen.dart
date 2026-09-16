import 'package:flutter/material.dart';

typedef DeferredWidgetBuilder = Widget Function();

class DeferredScreen extends StatefulWidget {
  final Future<void> Function() loadLibrary;
  final DeferredWidgetBuilder builder;

  const DeferredScreen({
    super.key,
    required this.loadLibrary,
    required this.builder,
  });

  @override
  State<DeferredScreen> createState() => _DeferredScreenState();
}

class _DeferredScreenState extends State<DeferredScreen> {
  late Future<void> _loadFuture;

  @override
  void initState() {
    super.initState();

    _loadFuture = widget.loadLibrary();
  }

  void _retry() {
    setState(() {
      _loadFuture = widget.loadLibrary();
    });
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<void>(
      future: _loadFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(),
            ),
          );
        }

        if (snapshot.hasError) {
          return Scaffold(
            body: Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.error_outline,
                      size: 56,
                    ),
                    const SizedBox(
                      height: 16,
                    ),
                    const Text(
                      'Не удалось загрузить раздел.',
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(
                      height: 16,
                    ),
                    FilledButton(
                      onPressed: _retry,
                      child: const Text(
                        'Повторить',
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }

        return widget.builder();
      },
    );
  }
}
