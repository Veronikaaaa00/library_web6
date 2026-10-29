import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../core/api_exceptions.dart';
import '../core/permissions.dart';
import '../models/book.dart';
import '../repositories/author_repository.dart';
import '../repositories/book_repository.dart';
import '../repositories/genre_repository.dart';
import '../repositories/loan_repository.dart';
import '../repositories/publisher_repository.dart';
import '../state/auth_notifier.dart';
import '../widgets/app_scaffold.dart';

class BookDetailScreen extends StatefulWidget {
  const BookDetailScreen({super.key, required this.bookId});

  final int bookId;

  @override
  State<BookDetailScreen> createState() => _BookDetailScreenState();
}

class _BookDetailScreenState extends State<BookDetailScreen> {
  late Future<_BookView?> _future;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<_BookView?> _load() async {
    final books = context.read<BookRepository>();
    final publishers = context.read<PublisherRepository>();
    final authorsRepo = context.read<AuthorRepository>();
    final genresRepo = context.read<GenreRepository>();
    final book = await books.findById(widget.bookId);
    if (book == null) return null;
    final publisher = await publishers.findById(book.publisherId);
    final authors = await authorsRepo.findAll();
    final genres = await genresRepo.findAll();

    String nameOfAuthor(int id) {
      for (final a in authors) {
        if (a.id == id) return a.fullName;
      }
      return '';
    }

    String nameOfGenre(int id) {
      for (final g in genres) {
        if (g.id == id) return g.name;
      }
      return '';
    }

    final authorLabel = book.authorIds
        .map(nameOfAuthor)
        .where((s) => s.isNotEmpty)
        .join(', ');
    final genreLabel = book.genreIds
        .map(nameOfGenre)
        .where((s) => s.isNotEmpty)
        .join(', ');
    return _BookView(
      book: book,
      publisherName: publisher?.name ?? '—',
      authors: authorLabel.isEmpty ? '—' : authorLabel,
      genres: genreLabel.isEmpty ? '—' : genreLabel,
    );
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: 'Карточка книги',
      body: FutureBuilder<_BookView?>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          final view = snapshot.data;
          if (view == null) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('Книга не найдена'),
                  const SizedBox(height: 12),
                  FilledButton(
                    onPressed: () => context.go('/books'),
                    child: const Text('К списку'),
                  ),
                ],
              ),
            );
          }

          final book = view.book;
          return ListView(
            padding: const EdgeInsets.all(24),
            children: [
              Text(
                book.title,
                style: Theme.of(context).textTheme.headlineMedium
                    ?.copyWith(fontWeight: FontWeight.w700),
              ),
              if (book.isDeleted) ...[
                const SizedBox(height: 8),
                Chip(
                  label: const Text('Удалена логически'),
                  backgroundColor: Theme.of(context).colorScheme.errorContainer,
                ),
              ],
              const SizedBox(height: 16),
              _row('ISBN', book.isbn),
              _row('Год', '${book.year}'),
              _row('Страниц', '${book.pages}'),
              _row('Издательство', view.publisherName),
              _row('Жанры', view.genres),
              _row('Авторы', view.authors),
              _row(
                'Экземпляры',
                '${book.copiesAvailable} из ${book.copiesTotal}',
              ),
              const SizedBox(height: 24),
              Builder(
                builder: (context) {
                  final role = context.watch<AuthNotifier>().role;
                  final canManage = Permissions.canManageCatalog(role);
                  final canLoan = Permissions.canManageLoans(role);
                  return Wrap(
                    spacing: 12,
                    children: [
                      if (canManage)
                        FilledButton.tonalIcon(
                          onPressed: () => context.go('/books/${book.id}/edit'),
                          icon: const Icon(Icons.edit),
                          label: const Text('Изменить'),
                        ),
                      if (canLoan)
                        FilledButton.icon(
                          onPressed: () => _tryLoan(book),
                          icon: const Icon(Icons.menu_book),
                          label: const Text('Выдать'),
                        ),
                      OutlinedButton(
                        onPressed: () => context.go('/books'),
                        child: const Text('К списку'),
                      ),
                    ],
                  );
                },
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _tryLoan(Book book) async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      await context.read<LoanRepository>().createLoan(
        readerId: 1,
        bookId: book.id,
      );
      if (!mounted) return;
      messenger.showSnackBar(const SnackBar(content: Text('Выдача оформлена')));
      setState(() => _future = _load());
    } on ConflictException catch (e) {
      messenger.showSnackBar(SnackBar(content: Text(e.message)));
    } on ApiException catch (e) {
      messenger.showSnackBar(SnackBar(content: Text(e.message)));
    }
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

class _BookView {
  _BookView({
    required this.book,
    required this.publisherName,
    required this.authors,
    required this.genres,
  });

  final Book book;
  final String publisherName;
  final String authors;
  final String genres;
}
