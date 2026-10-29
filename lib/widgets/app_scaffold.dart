import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../core/breakpoints.dart';
import '../core/permissions.dart';
import '../models/role.dart';
import '../state/auth_notifier.dart';

class AppScaffold extends StatelessWidget {
  const AppScaffold({
    super.key,
    required this.title,
    required this.body,
    this.actions,
    this.floatingActionButton,
  });

  final String title;
  final Widget body;
  final List<Widget>? actions;
  final Widget? floatingActionButton;

  @override
  Widget build(BuildContext context) {
    final location = GoRouter.of(context)
        .routeInformationProvider
        .value
        .uri
        .path;
    final auth = context.watch<AuthNotifier>();
    final destinations = _destinations(auth.role);
    final narrow = Breakpoints.isNarrow(context);
    final selected = _selectedIndex(location, destinations);

    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        actions: [
          if (auth.user != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 220),
                  child: Text(
                    '${auth.user!.fullName} (${auth.user!.role.label})',
                    style: Theme.of(context).textTheme.bodyMedium,
                    overflow: TextOverflow.ellipsis,
                    softWrap: false,
                  ),
                ),
              ),
            ),
          IconButton(
            tooltip: 'Выйти',
            onPressed: () async {
              await context.read<AuthNotifier>().logout();
              if (context.mounted) context.go('/login');
            },
            icon: const Icon(Icons.logout),
          ),
          ...?actions,
        ],
      ),
      drawer: narrow
          ? null
          : NavigationDrawer(
              selectedIndex: selected,
              onDestinationSelected: (index) {
                Navigator.of(context).pop();
                context.go(destinations[index].path);
              },
              children: [
                const DrawerHeader(
                  child: Align(
                    alignment: Alignment.bottomLeft,
                    child: Text(
                      'Библиотека',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
                for (final d in destinations)
                  NavigationDrawerDestination(
                    icon: Icon(d.icon),
                    selectedIcon: Icon(d.selectedIcon),
                    label: Text(d.label),
                  ),
              ],
            ),
      bottomNavigationBar: narrow
          ? _BottomNav(
              destinations: destinations,
              selectedIndex: selected,
              location: location,
            )
          : null,
      floatingActionButton: floatingActionButton == null
          ? null
          : Tooltip(message: 'Создать', child: floatingActionButton!),
      body: body,
    );
  }

  List<_NavItem> _destinations(Role? role) {
    final items = <_NavItem>[
      const _NavItem('/', 'Главная', Icons.home_outlined, Icons.home),
      const _NavItem(
        '/books',
        'Книги',
        Icons.menu_book_outlined,
        Icons.menu_book,
      ),
      const _NavItem('/authors', 'Авторы', Icons.person_outline, Icons.person),
      const _NavItem(
        '/genres',
        'Жанры',
        Icons.category_outlined,
        Icons.category,
      ),
      const _NavItem(
        '/publishers',
        'Издательства',
        Icons.business_outlined,
        Icons.business,
      ),
      const _NavItem(
        '/loans',
        'Выдачи',
        Icons.assignment_outlined,
        Icons.assignment,
      ),
    ];
    if (Permissions.canManageReaders(role)) {
      items.add(
        const _NavItem(
          '/readers',
          'Читатели',
          Icons.badge_outlined,
          Icons.badge,
        ),
      );
    }
    if (Permissions.canManageUsers(role)) {
      items.add(
        const _NavItem(
          '/admin/users',
          'Пользователи',
          Icons.manage_accounts_outlined,
          Icons.manage_accounts,
        ),
      );
    }
    if (Permissions.canViewStats(role)) {
      items.add(
        const _NavItem(
          '/admin/stats',
          'Статистика',
          Icons.bar_chart_outlined,
          Icons.bar_chart,
        ),
      );
    }
    return items;
  }

  int _selectedIndex(String location, List<_NavItem> destinations) {
    for (var i = 0; i < destinations.length; i++) {
      final path = destinations[i].path;
      if (path == '/') {
        if (location == '/') return i;
      } else if (location.startsWith(path)) {
        return i;
      }
    }
    return 0;
  }
}

class _BottomNav extends StatelessWidget {
  const _BottomNav({
    required this.destinations,
    required this.selectedIndex,
    required this.location,
  });

  final List<_NavItem> destinations;
  final int selectedIndex;
  final String location;

  static const _primaryCount = 4;

  @override
  Widget build(BuildContext context) {
    final primary = destinations.take(_primaryCount).toList();
    final hasMore = destinations.length > _primaryCount;
    final inMore = selectedIndex >= _primaryCount;
    final barIndex = inMore ? primary.length : selectedIndex;

    final maxIndex = hasMore ? primary.length : primary.length - 1;
    return NavigationBar(
      selectedIndex: barIndex.clamp(0, maxIndex < 0 ? 0 : maxIndex),
      onDestinationSelected: (index) {
        if (hasMore && index == primary.length) {
          _openMore(context);
          return;
        }
        context.go(primary[index].path);
      },
      destinations: [
        for (final d in primary)
          NavigationDestination(
            icon: Icon(d.icon),
            selectedIcon: Icon(d.selectedIcon),
            label: d.label,
            tooltip: d.label,
          ),
        if (hasMore)
          const NavigationDestination(
            icon: Icon(Icons.more_horiz),
            selectedIcon: Icon(Icons.more_horiz),
            label: 'Ещё',
            tooltip: 'Другие разделы',
          ),
      ],
    );
  }

  Future<void> _openMore(BuildContext context) async {
    final rest = destinations.skip(_primaryCount).toList();
    final chosen = await showModalBottomSheet<_NavItem>(
      context: context,
      showDragHandle: true,
      constraints: const BoxConstraints(maxWidth: 480),
      builder: (context) {
        return SafeArea(
          child: ListView(
            shrinkWrap: true,
            children: [
              const ListTile(
                title: Text(
                  'Другие разделы',
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
              ),
              for (final d in rest)
                ListTile(
                  leading: Icon(d.icon),
                  title: Text(d.label),
                  selected:
                      location == d.path ||
                      (d.path != '/' && location.startsWith(d.path)),
                  onTap: () => Navigator.pop(context, d),
                ),
            ],
          ),
        );
      },
    );
    if (chosen != null && context.mounted) {
      context.go(chosen.path);
    }
  }
}

class _NavItem {
  const _NavItem(this.path, this.label, this.icon, this.selectedIcon);

  final String path;
  final String label;
  final IconData icon;
  final IconData selectedIcon;
}
