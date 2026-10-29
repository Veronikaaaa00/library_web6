import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../models/publisher.dart';
import '../repositories/book_repository.dart';
import '../repositories/publisher_repository.dart';
import '../widgets/app_scaffold.dart';

class PublisherDetailScreen extends StatefulWidget {
  const PublisherDetailScreen({super.key, required this.publisherId});
  final int publisherId;

  @override
  State<PublisherDetailScreen> createState() => _PublisherDetailScreenState();
}

class _PublisherDetailScreenState extends State<PublisherDetailScreen> {
  late Future<Publisher?> _future;
  late Future<int> _booksCount;

  @override
  void initState() {
    super.initState();
    _future = context.read<PublisherRepository>().findById(widget.publisherId);
    _booksCount = context.read<BookRepository>().countByPublisher(
      widget.publisherId,
    );
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: 'Издательство',
      body: FutureBuilder<Publisher?>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          final p = snapshot.data;
          if (p == null) {
            return const Center(child: Text('Издательство не найдено'));
          }
          return ListView(
            padding: const EdgeInsets.all(24),
            children: [
              Text(p.name, style: Theme.of(context).textTheme.headlineMedium),
              const SizedBox(height: 8),
              Text('Страна: ${p.country}'),
              if (p.isDeleted) const Chip(label: Text('Удалено')),
              const SizedBox(height: 8),
              FutureBuilder<int>(
                future: _booksCount,
                builder: (context, snap) =>
                    Text('Связанных книг: ${snap.data ?? '…'}'),
              ),
              const SizedBox(height: 16),
              FilledButton.tonalIcon(
                onPressed: () => context.go('/publishers/${p.id}/edit'),
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
