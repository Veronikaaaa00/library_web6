import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../models/author.dart';
import '../repositories/author_repository.dart';
import '../widgets/app_scaffold.dart';

class AuthorDetailScreen extends StatefulWidget {
  const AuthorDetailScreen({super.key, required this.authorId});

  final int authorId;

  @override
  State<AuthorDetailScreen> createState() => _AuthorDetailScreenState();
}

class _AuthorDetailScreenState extends State<AuthorDetailScreen> {
  late Future<Author?> _future;

  @override
  void initState() {
    super.initState();
    _future = context.read<AuthorRepository>().findById(widget.authorId);
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: 'Карточка автора',
      body: FutureBuilder<Author?>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          final author = snapshot.data;
          if (author == null) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('Автор не найден'),
                  const SizedBox(height: 12),
                  FilledButton(
                    onPressed: () => context.go('/authors'),
                    child: const Text('К списку'),
                  ),
                ],
              ),
            );
          }

          return ListView(
            padding: const EdgeInsets.all(24),
            children: [
              Text(
                author.fullName,
                style: Theme.of(context).textTheme.headlineMedium
                    ?.copyWith(fontWeight: FontWeight.w700),
              ),
              if (author.isDeleted) ...[
                const SizedBox(height: 8),
                Chip(
                  label: const Text('Удалён логически'),
                  backgroundColor: Theme.of(context).colorScheme.errorContainer,
                ),
              ],
              const SizedBox(height: 16),
              _row('Имя', author.firstName),
              _row('Фамилия', author.lastName),
              _row('Страна', author.country),
              _row('Год рождения', '${author.birthYear}'),
              _row('О себе', author.bio ?? '—'),
              const SizedBox(height: 24),
              Wrap(
                spacing: 12,
                children: [
                  FilledButton.tonalIcon(
                    onPressed: () => context.go('/authors/${author.id}/edit'),
                    icon: const Icon(Icons.edit),
                    label: const Text('Изменить'),
                  ),
                  OutlinedButton(
                    onPressed: () => context.go('/authors'),
                    child: const Text('К списку'),
                  ),
                ],
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _row(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 140,
            child: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }
}
