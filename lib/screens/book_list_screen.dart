import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../core/api_exceptions.dart';
import '../core/breakpoints.dart';
import '../core/permissions.dart';
import '../models/book.dart';
import '../models/book_query.dart';
import '../models/genre.dart';
import '../models/publisher.dart';
import '../repositories/genre_repository.dart';
import '../repositories/publisher_repository.dart';
import '../state/auth_notifier.dart';
import '../state/book_list_notifier.dart';
import '../widgets/app_scaffold.dart';
import '../widgets/debounced_search_field.dart';
import '../widgets/entity_table.dart';
import '../widgets/load_state_body.dart';
import '../widgets/pagination_bar.dart';

class BookListScreen extends StatefulWidget {
  const BookListScreen({super.key});

  @override
  State<BookListScreen> createState() => _BookListScreenState();
}

class _BookListScreenState extends State<BookListScreen> {
  final _yearFromController = TextEditingController();
  final _yearToController = TextEditingController();
  var _filtersOpen = false;
  List<Genre> _genres = [];
  List<Publisher> _publishers = [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadLookups();
    });
  }

  Future<void> _loadLookups() async {
    final genresRepo = context.read<GenreRepository>();
    final publishersRepo = context.read<PublisherRepository>();
    final genres = await genresRepo.findAll();
    final publishers = await publishersRepo.findAll();
    if (!mounted) return;
    setState(() {
      _genres = genres;
      _publishers = publishers;
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final uriQuery = BookQuery.fromUri(GoRouterState.of(context).uri);
    final notifier = context.read<BookListNotifier>();
    if (uriQuery != notifier.query) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        context.read<BookListNotifier>().applyQuery(uriQuery);
        _syncYearFields(uriQuery);
      });
    } else {
      _syncYearFields(uriQuery);
    }
  }

  void _syncYearFields(BookQuery query) {
    final from = query.yearFrom?.toString() ?? '';
    final to = query.yearTo?.toString() ?? '';
    if (_yearFromController.text != from) {
      _yearFromController.text = from;
    }
    if (_yearToController.text != to) {
      _yearToController.text = to;
    }
  }

  @override
  void dispose() {
    _yearFromController.dispose();
    _yearToController.dispose();
    super.dispose();
  }

  void _go(BookQuery query) {
    context.go(query.toLocation());
  }

  Future<void> _confirmSoftDelete(Book book) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        constraints: const BoxConstraints(maxWidth: 420),
        title: const Text('Удалить книгу?'),
        content: Text(
          '«${book.title}» будет скрыта из списка (логическое удаление).',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Отмена'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Удалить'),
          ),
        ],
      ),
    );
    if (ok == true && mounted) {
      await context.read<BookListNotifier>().softDelete(book.id);
    }
  }

  Future<void> _confirmDeleteSelected() async {
    final notifier = context.read<BookListNotifier>();
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        constraints: const BoxConstraints(maxWidth: 420),
        title: const Text('Удалить выбранные?'),
        content: Text(
          'Будет логически удалено записей: ${notifier.selected.length}.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Отмена'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Удалить'),
          ),
        ],
      ),
    );
    if (ok == true && mounted) {
      await context.read<BookListNotifier>().deleteSelected();
    }
  }

  @override
  Widget build(BuildContext context) {
    final notifier = context.watch<BookListNotifier>();
    final auth = context.watch<AuthNotifier>();
    final canManage = Permissions.canManageCatalog(auth.role);
    final query = notifier.query;
    final wide = Breakpoints.isWide(context);

    return AppScaffold(
      title: 'Книги',
      floatingActionButton: canManage
          ? FloatingActionButton(
              onPressed: () => context.go('/books/new'),
              child: const Icon(Icons.add),
            )
          : null,
      actions: [
        if (canManage && notifier.hasSelection)
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: Center(child: Text('Выбрано: ${notifier.selected.length}')),
          ),
        if (canManage && notifier.hasSelection)
          IconButton(
            tooltip: 'Удалить выбранные',
            onPressed: _confirmDeleteSelected,
            icon: const Icon(Icons.delete_sweep),
          ),
      ],
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            DebouncedSearchField(
              initialValue: query.search,
              hintText: 'Поиск по названию или ISBN',
              onChanged: (value) => _go(query.copyWith(search: value)),
            ),
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                onPressed: () => setState(() => _filtersOpen = !_filtersOpen),
                icon: Icon(
                  _filtersOpen ? Icons.expand_less : Icons.expand_more,
                ),
                label: Text(_filtersOpen ? 'Скрыть фильтры' : 'Фильтры'),
              ),
            ),
            if (_filtersOpen) _filters(query),
            const SizedBox(height: 8),
            PaginationBar(
              page: notifier.result.page,
              totalPages: notifier.result.totalPages,
              total: notifier.result.total,
              size: query.size,
              onPageChanged: (page) => _go(query.copyWith(page: page)),
              onSizeChanged: (size) => _go(query.copyWith(size: size)),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: LoadStateBody(
                status: notifier.status,
                isEmpty: notifier.result.items.isEmpty,
                error: notifier.error,
                onRetry: () => context.read<BookListNotifier>().load(),
                child: wide
                    ? EntityTable<Book>(
                        items: notifier.result.items,
                        idOf: (b) => b.id,
                        selected: notifier.selected,
                        onToggleSelect: notifier.toggleSelection,
                        sortField: query.sortField,
                        sortAscending: query.sortAscending,
                        isDeleted: (b) => b.isDeleted,
                        onSort: (field) => _go(
                          query.copyWith(
                            sortField: field,
                            sortAscending: field == query.sortField
                                ? !query.sortAscending
                                : true,
                          ),
                        ),
                        columns: [
                          TableColumnSpec(
                            label: 'Название',
                            sortField: 'title',
                            build: (b) => InkWell(
                              onTap: () => context.go('/books/${b.id}'),
                              child: Text(
                                b.title,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  color: Theme.of(context).colorScheme.primary,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                          TableColumnSpec(
                            label: 'ISBN',
                            sortField: 'isbn',
                            build: (b) => Text(b.isbn),
                          ),
                          TableColumnSpec(
                            label: 'Год',
                            sortField: 'year',
                            numeric: true,
                            build: (b) => Text('${b.year}'),
                          ),
                          TableColumnSpec(
                            label: 'Страниц',
                            sortField: 'pages',
                            numeric: true,
                            build: (b) => Text('${b.pages}'),
                          ),
                          TableColumnSpec(
                            label: 'Издательство',
                            build: (b) {
                              for (final p in _publishers) {
                                if (p.id == b.publisherId) {
                                  return Text(p.name);
                                }
                              }
                              return const Text('—');
                            },
                          ),
                        ],
                        actions: (b) => _actions(b),
                      )
                    : ListView.separated(
                        itemCount: notifier.result.items.length,
                        separatorBuilder: (context, index) =>
                            const SizedBox(height: 8),
                        itemBuilder: (context, index) {
                          final book = notifier.result.items[index];
                          return _bookCard(book, notifier);
                        },
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _filters(BookQuery query) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Wrap(
          spacing: 12,
          runSpacing: 12,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            SizedBox(
              width: 220,
              child: DropdownButtonFormField<int?>(
                key: ValueKey('genre-${query.genreId}'),
                initialValue: query.genreId,
                isExpanded: true,
                decoration: const InputDecoration(
                  labelText: 'Жанр',
                  border: OutlineInputBorder(),
                  isDense: true,
                ),
                items: [
                  const DropdownMenuItem(value: null, child: Text('Все')),
                  for (final genre in _genres)
                    DropdownMenuItem(value: genre.id, child: Text(genre.name)),
                ],
                onChanged: (value) => _go(query.copyWith(genreId: value)),
              ),
            ),
            SizedBox(
              width: 220,
              child: DropdownButtonFormField<int?>(
                key: ValueKey('publisher-${query.publisherId}'),
                initialValue: query.publisherId,
                isExpanded: true,
                decoration: const InputDecoration(
                  labelText: 'Издательство',
                  border: OutlineInputBorder(),
                  isDense: true,
                ),
                items: [
                  const DropdownMenuItem(value: null, child: Text('Все')),
                  for (final publisher in _publishers)
                    DropdownMenuItem(
                      value: publisher.id,
                      child: Text(publisher.name),
                    ),
                ],
                onChanged: (value) => _go(query.copyWith(publisherId: value)),
              ),
            ),
            SizedBox(
              width: 120,
              child: TextField(
                controller: _yearFromController,
                decoration: const InputDecoration(
                  labelText: 'Год от',
                  border: OutlineInputBorder(),
                  isDense: true,
                ),
                keyboardType: TextInputType.number,
                onSubmitted: (value) =>
                    _go(query.copyWith(yearFrom: int.tryParse(value))),
              ),
            ),
            SizedBox(
              width: 120,
              child: TextField(
                controller: _yearToController,
                decoration: const InputDecoration(
                  labelText: 'Год до',
                  border: OutlineInputBorder(),
                  isDense: true,
                ),
                keyboardType: TextInputType.number,
                onSubmitted: (value) =>
                    _go(query.copyWith(yearTo: int.tryParse(value))),
              ),
            ),
            FilledButton.tonal(
              onPressed: () => _go(
                query.copyWith(
                  yearFrom: int.tryParse(_yearFromController.text),
                  yearTo: int.tryParse(_yearToController.text),
                ),
              ),
              child: const Text('Применить годы'),
            ),
            FilterChip(
              label: const Text('Показать удалённые'),
              selected: query.includeDeleted,
              onSelected: (value) => _go(query.copyWith(includeDeleted: value)),
            ),
            TextButton(
              onPressed: () {
                _yearFromController.clear();
                _yearToController.clear();
                _go(const BookQuery());
              },
              child: const Text('Сбросить'),
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _actions(Book book) {
    final role = context.read<AuthNotifier>().role;
    final canManage = Permissions.canManageCatalog(role);
    final canHard = Permissions.canHardDelete(role);
    final canRestore = Permissions.canRestore(role);

    if (book.isDeleted) {
      return [
        if (canRestore)
          IconButton(
            tooltip: 'Восстановить',
            onPressed: () => context.read<BookListNotifier>().restore(book.id),
            icon: const Icon(Icons.restore),
          ),
        if (canHard)
          IconButton(
            tooltip: 'Удалить навсегда',
            onPressed: () async {
              try {
                await context.read<BookListNotifier>().hardDelete(book.id);
              } on ApiException catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context)
                      .showSnackBar(SnackBar(content: Text(e.message)));
                }
              }
            },
            icon: const Icon(Icons.delete_forever),
          ),
      ];
    }
    return [
      IconButton(
        tooltip: 'Открыть',
        onPressed: () => context.go('/books/${book.id}'),
        icon: const Icon(Icons.visibility_outlined),
      ),
      if (canManage) ...[
        IconButton(
          tooltip: 'Изменить',
          onPressed: () => context.go('/books/${book.id}/edit'),
          icon: const Icon(Icons.edit_outlined),
        ),
        IconButton(
          tooltip: 'Удалить',
          onPressed: () => _confirmSoftDelete(book),
          icon: const Icon(Icons.delete_outline),
        ),
      ],
    ];
  }

  Widget _bookCard(Book book, BookListNotifier notifier) {
    String publisher = '—';
    for (final p in _publishers) {
      if (p.id == book.publisherId) {
        publisher = p.name;
        break;
      }
    }
    return Card(
      child: ListTile(
        leading: Checkbox(
          value: notifier.selected.contains(book.id),
          onChanged: (_) => notifier.toggleSelection(book.id),
        ),
        title: Text(book.title),
        subtitle: Text(
          '${book.year} · $publisher · ${book.isbn}'
          '${book.isDeleted ? ' · удалена' : ''}',
        ),
        trailing: Wrap(children: _actions(book)),
        onTap: () => context.go('/books/${book.id}'),
      ),
    );
  }
}
