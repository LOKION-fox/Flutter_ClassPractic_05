import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/app_role.dart';
import '../state/load_status.dart';
import '../state/user_admin_notifier.dart';

class AdminUsersScreen
    extends StatefulWidget {
  const AdminUsersScreen({
    super.key,
  });

  @override
  State<AdminUsersScreen>
      createState() =>
          _AdminUsersScreenState();
}

class _AdminUsersScreenState
    extends State<AdminUsersScreen> {
  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance
        .addPostFrameCallback(
      (_) {
        context
            .read<
                UserAdminNotifier>()
            .loadUsers();
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
          'Пользователи и роли',
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
              child: Column(
                mainAxisSize:
                    MainAxisSize.min,

                children: [
                  Text(
                    notifier.error ??
                        'Ошибка',
                  ),

                  const SizedBox(
                    height: 16,
                  ),

                  FilledButton(
                    onPressed:
                        notifier
                            .loadUsers,

                    child:
                        const Text(
                      'Повторить',
                    ),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding:
                const EdgeInsets.all(
              16,
            ),

            itemCount:
                notifier.users.length,

            itemBuilder:
                (
              context,
              index,
            ) {
              final user =
                  notifier.users[
                      index];

              return Card(
                child: ListTile(
                  title: Text(
                    user.fullName,
                  ),

                  subtitle: Text(
                    user.username,
                  ),

                  trailing:
                      SizedBox(
                    width: 180,

                    child:
                        DropdownButtonFormField<
                            AppRole>(
                      initialValue:
                          user.role,

                      items:
                          AppRole.values
                              .map(
                        (role) {
                          return DropdownMenuItem(
                            value: role,
                            child: Text(
                              role.title,
                            ),
                          );
                        },
                      ).toList(),

                      onChanged:
                          (role) async {
                        if (role ==
                            null) {
                          return;
                        }

                        try {
                          await notifier
                              .changeRole(
                            user.id,
                            role,
                          );
                        } catch (e) {
                          if (!context
                              .mounted) {
                            return;
                          }

                          ScaffoldMessenger
                              .of(
                            context,
                          )
                              .showSnackBar(
                            SnackBar(
                              content:
                                  Text(
                                e.toString(),
                              ),
                            ),
                          );
                        }
                      },
                    ),
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