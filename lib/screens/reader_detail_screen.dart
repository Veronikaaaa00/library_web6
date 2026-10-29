import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../models/reader.dart';
import '../repositories/reader_repository.dart';
import '../widgets/app_scaffold.dart';

class ReaderDetailScreen extends StatefulWidget {
  const ReaderDetailScreen({super.key, required this.readerId});
  final int readerId;

  @override
  State<ReaderDetailScreen> createState() => _ReaderDetailScreenState();
}

class _ReaderDetailScreenState extends State<ReaderDetailScreen> {
  late Future<Reader?> _future;

  @override
  void initState() {
    super.initState();
    _future = context.read<ReaderRepository>().findById(widget.readerId);
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: 'Читатель',
      body: FutureBuilder<Reader?>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          final r = snapshot.data;
          if (r == null) {
            return const Center(child: Text('Читатель не найден'));
          }
          return ListView(
            padding: const EdgeInsets.all(24),
            children: [
              Text(
                r.fullName,
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              const SizedBox(height: 8),
              Text('Email: ${r.email}'),
              Text('Телефон: ${r.phone}'),
              const SizedBox(height: 12),
              Text('Билет', style: Theme.of(context).textTheme.titleMedium),
              Text('Номер: ${r.card.number}'),
              Text(
                'Выдан: ${r.card.issuedAt.toIso8601String().split('T').first}',
              ),
              Text(
                'До: ${r.card.expiresAt.toIso8601String().split('T').first}',
              ),
              Text('Статус: ${r.card.isActive ? 'активен' : 'неактивен'}'),
              if (r.isDeleted) const Chip(label: Text('Удалён')),
              const SizedBox(height: 16),
              FilledButton.tonalIcon(
                onPressed: () => context.go('/readers/${r.id}/edit'),
                icon: const Icon(Icons.edit),
                label: const Text('Изменить'),
              ),
            ],
          );
        },
      ),
    );
  }
}
