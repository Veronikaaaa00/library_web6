import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/api_exceptions.dart';
import '../models/app_user.dart';
import '../models/role.dart';
import '../repositories/user_repository.dart';
import '../widgets/app_scaffold.dart';

class UsersScreen extends StatefulWidget {
  const UsersScreen({super.key});

  @override
  State<UsersScreen> createState() => _UsersScreenState();
}

class _UsersScreenState extends State<UsersScreen> {
  late Future<List<AppUser>> _future;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<List<AppUser>> _load() async {
    final page = await context.read<UserRepository>().find();
    return page.items;
  }

  Future<void> _changeRole(AppUser user) async {
    final next = await showDialog<Role>(
      context: context,
      builder: (context) => SimpleDialog(
        title: Text('Роль: ${user.fullName}'),
        children: [
          for (final role in Role.values)
            SimpleDialogOption(
              onPressed: () => Navigator.pop(context, role),
              child: Text(
                role.label,
                style: TextStyle(
                  fontWeight: role == user.role
                      ? FontWeight.bold
                      : FontWeight.normal,
                ),
              ),
            ),
        ],
      ),
    );
    if (next == null || next == user.role || !mounted) return;
    try {
      await context.read<UserRepository>().updateRole(user.id, next);
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Роль изменена на ${next.label}')));
      setState(() => _future = _load());
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(e.message)));
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: 'Пользователи',
      body: FutureBuilder<List<AppUser>>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('${snapshot.error}'));
          }
          final users = snapshot.data ?? const [];
          return ListView.builder(
            itemCount: users.length,
            itemBuilder: (context, index) {
              final u = users[index];
              return ListTile(
                title: Text(u.fullName),
                subtitle: Text('${u.username} · ${u.email}'),
                trailing: TextButton(
                  onPressed: () => _changeRole(u),
                  child: Text(u.role.label),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
