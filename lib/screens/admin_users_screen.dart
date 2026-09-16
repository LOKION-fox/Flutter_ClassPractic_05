import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/app_role.dart';
import '../state/load_status.dart';
import '../state/user_admin_notifier.dart';

class AdminUsersScreen extends StatefulWidget {
  const AdminUsersScreen({
    super.key,
  });

  @override
  State<AdminUsersScreen> createState() => _AdminUsersScreenState();
}

class _AdminUsersScreenState extends State<AdminUsersScreen> {
  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback(
      (_) {
        context.read<UserAdminNotifier>().loadUsers();
      },
    );
  }

  Future<void> _changeRole(
    BuildContext context,
    UserAdminNotifier notifier,
    int userId,
    AppRole role,
  ) async {
    try {
      await notifier.changeRole(
        userId,
        role,
      );
    } catch (e) {
      if (!context.mounted) {
        return;
      }

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(
        SnackBar(
          content: Text(e.toString()),
        ),
      );
    }
  }

  @override
  Widget build(
    BuildContext context,
  ) {
    final notifier = context.watch<UserAdminNotifier>();

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Пользователи и роли',
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
                      notifier.error ?? 'Ошибка загрузки пользователей',
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(
                      height: 16,
                    ),
                    FilledButton.icon(
                      onPressed: notifier.loadUsers,
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

          if (notifier.users.isEmpty) {
            return const Center(
              child: Text(
                'Пользователи не найдены',
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(
              16,
            ),
            itemCount: notifier.users.length,
            itemBuilder: (
              context,
              index,
            ) {
              final user = notifier.users[index];

              return Card(
                child: Padding(
                  padding: const EdgeInsets.all(
                    12,
                  ),
                  child: LayoutBuilder(
                    builder: (
                      context,
                      constraints,
                    ) {
                      final userInfo = Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            user.fullName,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(
                              context,
                            ).textTheme.titleMedium,
                          ),
                          const SizedBox(
                            height: 4,
                          ),
                          Text(
                            user.username,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      );

                      final roleField = DropdownButtonFormField<AppRole>(
                        initialValue: user.role,
                        isExpanded: true,
                        decoration: const InputDecoration(
                          labelText: 'Роль',
                          border: OutlineInputBorder(),
                        ),
                        items: AppRole.values.map(
                          (role) {
                            return DropdownMenuItem(
                              value: role,
                              child: Text(
                                role.title,
                              ),
                            );
                          },
                        ).toList(),
                        onChanged: (role) {
                          if (role == null || role == user.role) {
                            return;
                          }

                          _changeRole(
                            context,
                            notifier,
                            user.id,
                            role,
                          );
                        },
                      );

                      if (constraints.maxWidth < 520) {
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            userInfo,
                            const SizedBox(
                              height: 12,
                            ),
                            roleField,
                          ],
                        );
                      }

                      return Row(
                        children: [
                          Expanded(
                            child: userInfo,
                          ),
                          const SizedBox(
                            width: 16,
                          ),
                          SizedBox(
                            width: 210,
                            child: roleField,
                          ),
                        ],
                      );
                    },
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
