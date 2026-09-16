import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../models/app_role.dart';
import '../state/auth_notifier.dart';

class AdaptiveAppShell extends StatelessWidget {
  final String currentLocation;
  final Widget child;

  const AdaptiveAppShell({
    super.key,
    required this.currentLocation,
    required this.child,
  });

  List<_NavigationItem> _items(AuthNotifier auth) {
    final items = <_NavigationItem>[
      const _NavigationItem(
        label: 'Главная',
        route: '/',
        icon: Icons.home_outlined,
        selectedIcon: Icons.home,
      ),
      const _NavigationItem(
        label: 'Товары',
        route: '/products',
        icon: Icons.shopping_bag_outlined,
        selectedIcon: Icons.shopping_bag,
      ),
      const _NavigationItem(
        label: 'Животные',
        route: '/animals',
        icon: Icons.pets_outlined,
        selectedIcon: Icons.pets,
      ),
    ];

    if (auth.isUiRole(AppRole.customer)) {
      items.add(
        const _NavigationItem(
          label: 'Кабинет',
          route: '/account',
          icon: Icons.person_outline,
          selectedIcon: Icons.person,
        ),
      );
    }

    if (auth.can(AppPermission.managerArea) || auth.isUiRole(AppRole.admin)) {
      items.add(
        const _NavigationItem(
          label: 'Управление',
          route: '/management',
          icon: Icons.store_outlined,
          selectedIcon: Icons.store,
          relatedPrefixes: [
            '/management',
            '/categories',
            '/suppliers',
            '/customers',
          ],
        ),
      );
    }

    if (auth.can(AppPermission.manageUsers)) {
      items.add(
        const _NavigationItem(
          label: 'Пользователи',
          route: '/admin/users',
          icon: Icons.manage_accounts_outlined,
          selectedIcon: Icons.manage_accounts,
          relatedPrefixes: [
            '/admin/users',
            '/admin/stats',
          ],
        ),
      );
    }

    return items;
  }

  int _selectedIndex(
    List<_NavigationItem> items,
  ) {
    for (var i = 0; i < items.length; i++) {
      if (items[i].matches(
        currentLocation,
      )) {
        return i;
      }
    }

    return 0;
  }

  Widget _content() {
    return FocusTraversalGroup(
      policy: ReadingOrderTraversalPolicy(),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(
            maxWidth: 1500,
          ),
          child: SizedBox.expand(
            child: child,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(
    BuildContext context,
  ) {
    final auth = context.watch<AuthNotifier>();

    final items = _items(auth);

    final selectedIndex = _selectedIndex(items);

    return LayoutBuilder(
      builder: (
        context,
        constraints,
      ) {
        final width = constraints.maxWidth;

        if (width < 600) {
          return Scaffold(
            body: _content(),
            bottomNavigationBar: NavigationBar(
              selectedIndex: selectedIndex,
              labelBehavior:
                  NavigationDestinationLabelBehavior.onlyShowSelected,
              onDestinationSelected: (index) {
                context.go(
                  items[index].route,
                );
              },
              destinations: items
                  .map(
                    (item) => NavigationDestination(
                      icon: Icon(item.icon),
                      selectedIcon: Icon(
                        item.selectedIcon,
                      ),
                      label: item.label,
                      tooltip: item.label,
                    ),
                  )
                  .toList(),
            ),
          );
        }

        final extended = width >= 1200;

        return Scaffold(
          body: Row(
            children: [
              Semantics(
                label: 'Основная навигация',
                container: true,
                child: NavigationRail(
                  extended: extended,
                  selectedIndex: selectedIndex,
                  labelType: extended
                      ? NavigationRailLabelType.none
                      : NavigationRailLabelType.selected,
                  onDestinationSelected: (index) {
                    context.go(
                      items[index].route,
                    );
                  },
                  leading: Padding(
                    padding: const EdgeInsets.symmetric(
                      vertical: 12,
                    ),
                    child: Tooltip(
                      message: 'Зоомагазин',
                      child: Icon(
                        Icons.pets,
                        size: extended ? 34 : 30,
                      ),
                    ),
                  ),
                  destinations: items.map(
                    (item) {
                      return NavigationRailDestination(
                        icon: Tooltip(
                          message: item.label,
                          child: Icon(
                            item.icon,
                          ),
                        ),
                        selectedIcon: Tooltip(
                          message: item.label,
                          child: Icon(
                            item.selectedIcon,
                          ),
                        ),
                        label: Text(
                          item.label,
                        ),
                      );
                    },
                  ).toList(),
                ),
              ),
              const VerticalDivider(
                width: 1,
              ),
              Expanded(
                child: ColoredBox(
                  color: Theme.of(context).colorScheme.surfaceContainerLowest,
                  child: _content(),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _NavigationItem {
  final String label;
  final String route;

  final IconData icon;
  final IconData selectedIcon;

  final List<String> relatedPrefixes;

  const _NavigationItem({
    required this.label,
    required this.route,
    required this.icon,
    required this.selectedIcon,
    this.relatedPrefixes = const [],
  });

  bool matches(
    String location,
  ) {
    if (route == '/') {
      return location == '/';
    }

    if (location == route ||
        location.startsWith(
          '$route/',
        )) {
      return true;
    }

    return relatedPrefixes.any(
      (prefix) =>
          location == prefix ||
          location.startsWith(
            '$prefix/',
          ),
    );
  }
}
