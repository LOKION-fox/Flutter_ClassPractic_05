import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../state/load_status.dart';
import '../state/user_admin_notifier.dart';

class AdminStatsScreen
    extends StatefulWidget {
  const AdminStatsScreen({
    super.key,
  });

  @override
  State<AdminStatsScreen>
      createState() =>
          _AdminStatsScreenState();
}

class _AdminStatsScreenState
    extends State<AdminStatsScreen> {
  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance
        .addPostFrameCallback(
      (_) {
        context
            .read<
                UserAdminNotifier>()
            .loadStatistics();
      },
    );
  }

  @override
  Widget build(
    BuildContext context,
  ) {
    final notifier =
        context.watch<
            UserAdminNotifier>();

    return Scaffold(
      appBar: AppBar(
        title:
            const Text(
          'Статистика',
        ),
      ),

      body: Builder(
        builder: (context) {
          if (notifier.status ==
              LoadStatus.loading) {
            return const Center(
              child:
                  CircularProgressIndicator(),
            );
          }

          if (notifier.status ==
              LoadStatus.error) {
            return Center(
              child: Text(
                notifier.error ??
                    'Ошибка',
              ),
            );
          }

          return ListView(
            padding:
                const EdgeInsets.all(
              24,
            ),

            children: notifier
                .statistics
                .entries
                .map(
              (entry) {
                return Card(
                  child: ListTile(
                    title:
                        Text(entry.key),
                    trailing: Text(
                      '${entry.value}',
                      style:
                          Theme.of(
                        context,
                      )
                              .textTheme
                              .titleLarge,
                    ),
                  ),
                );
              },
            ).toList(),
          );
        },
      ),
    );
  }
}