import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../core/permissions.dart';
import '../state/auth_notifier.dart';
import '../widgets/app_scaffold.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthNotifier>();
    final role = auth.role;

    return AppScaffold(
      title: 'Библиотека',
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 520),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Здравствуйте, ${auth.user?.fullName ?? ''}',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.headlineMedium
                      ?.copyWith(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 8),
                Text(
                  'Роль: ${auth.user?.role.label ?? '—'}',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
                const SizedBox(height: 28),
                FilledButton.icon(
                  onPressed: () => context.go('/books'),
                  icon: const Icon(Icons.menu_book),
                  label: const Text('Каталог книг'),
                ),
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  onPressed: () => context.go('/loans'),
                  icon: const Icon(Icons.assignment),
                  label: Text(
                    Permissions.canManageLoans(role) ? 'Выдачи' : 'Мои выдачи',
                  ),
                ),
                if (Permissions.canManageReaders(role)) ...[
                  const SizedBox(height: 12),
                  OutlinedButton.icon(
                    onPressed: () => context.go('/readers'),
                    icon: const Icon(Icons.badge),
                    label: const Text('Читатели'),
                  ),
                ],
                if (Permissions.canManageUsers(role)) ...[
                  const SizedBox(height: 12),
                  OutlinedButton.icon(
                    onPressed: () => context.go('/admin/users'),
                    icon: const Icon(Icons.manage_accounts),
                    label: const Text('Пользователи'),
                  ),
                ],
                if (Permissions.canViewStats(role)) ...[
                  const SizedBox(height: 12),
                  OutlinedButton.icon(
                    onPressed: () => context.go('/admin/stats'),
                    icon: const Icon(Icons.bar_chart),
                    label: const Text('Статистика'),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
