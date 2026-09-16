import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../state/load_status.dart';
import '../state/user_admin_notifier.dart';

class AdminStatsScreen extends StatefulWidget {
  const AdminStatsScreen({
    super.key,
  });

  @override
  State<AdminStatsScreen> createState() => _AdminStatsScreenState();
}

class _AdminStatsScreenState extends State<AdminStatsScreen> {
  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback(
      (_) {
        context.read<UserAdminNotifier>().loadStatistics();
      },
    );
  }

  @override
  Widget build(
    BuildContext context,
  ) {
    final notifier = context.watch<UserAdminNotifier>();

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Статистика',
        ),
      ),
      body: Builder(
        builder: (context) {
          if (notifier.status == LoadStatus.idle ||
              notifier.status == LoadStatus.loading) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          if (notifier.status == LoadStatus.error) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(
                  24,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.cloud_off,
                      size: 56,
                    ),
                    const SizedBox(
                      height: 16,
                    ),
                    Text(
                      notifier.error ?? 'Ошибка загрузки статистики',
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(
                      height: 16,
                    ),
                    FilledButton.icon(
                      onPressed: notifier.loadStatistics,
                      icon: const Icon(
                        Icons.refresh,
                      ),
                      label: const Text(
                        'Повторить',
                      ),
                    ),
                  ],
                ),
              ),
            );
          }

          if (notifier.statistics.isEmpty) {
            return const Center(
              child: Text(
                'Статистика пока недоступна',
              ),
            );
          }

          return LayoutBuilder(
            builder: (
              context,
              constraints,
            ) {
              final columns = constraints.maxWidth < 600
                  ? 1
                  : constraints.maxWidth < 1100
                      ? 2
                      : 3;

              return GridView.count(
                padding: const EdgeInsets.all(
                  24,
                ),
                crossAxisCount: columns,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                childAspectRatio: columns == 1 ? 4.2 : 3.2,
                children: notifier.statistics.entries.map(
                  (entry) {
                    return Card(
                      child: Center(
                        child: ListTile(
                          title: Text(
                            entry.key,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          trailing: Text(
                            '${entry.value}',
                            style: Theme.of(
                              context,
                            ).textTheme.titleLarge,
                          ),
                        ),
                      ),
                    );
                  },
                ).toList(),
              );
            },
          );
        },
      ),
    );
  }
}
