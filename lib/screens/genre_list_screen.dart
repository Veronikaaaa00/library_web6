import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../core/breakpoints.dart';
import '../core/permissions.dart';
import '../models/genre.dart';
import '../models/genre_query.dart';
import '../state/auth_notifier.dart';
import '../state/genre_list_notifier.dart';
import '../widgets/app_scaffold.dart';
import '../widgets/debounced_search_field.dart';
import '../widgets/entity_table.dart';
import '../widgets/load_state_body.dart';
import '../widgets/pagination_bar.dart';

class GenreListScreen extends StatefulWidget {
  const GenreListScreen({super.key});

  @override
  State<GenreListScreen> createState() => _GenreListScreenState();
}

class _GenreListScreenState extends State<GenreListScreen> {
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final uriQuery = GenreQuery.fromUri(GoRouterState.of(context).uri);
    final notifier = context.read<GenreListNotifier>();
    if (uriQuery != notifier.query) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        context.read<GenreListNotifier>().applyQuery(uriQuery);
      });
    }
  }

  void _go(GenreQuery query) => context.go(query.toLocation());

  Future<void> _softDelete(Genre genre) async {
    final msg = await context.read<GenreListNotifier>().softDelete(genre.id);
    if (msg != null && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final notifier = context.watch<GenreListNotifier>();
    final canManage = Permissions.canManageCatalog(
      context.watch<AuthNotifier>().role,
    );
    final query = notifier.query;
    final wide = Breakpoints.isWide(context);

    return AppScaffold(
      title: 'Жанры',
      floatingActionButton: canManage
          ? FloatingActionButton(
              onPressed: () => context.go('/genres/new'),
              child: const Icon(Icons.add),
            )
          : null,
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            DebouncedSearchField(
              initialValue: query.search,
              hintText: 'Поиск по названию',
              onChanged: (v) => _go(query.copyWith(search: v)),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: [
                FilterChip(
                  label: const Text('Показать удалённые'),
                  selected: query.includeDeleted,
                  onSelected: (v) => _go(query.copyWith(includeDeleted: v)),
                ),
              ],
            ),
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
                onRetry: () => context.read<GenreListNotifier>().load(),
                child: wide
                    ? EntityTable<Genre>(
                        items: notifier.result.items,
                        idOf: (g) => g.id,
                        selected: notifier.selected,
                        onToggleSelect: notifier.toggleSelection,
                        sortField: query.sortField,
                        sortAscending: query.sortAscending,
                        isDeleted: (g) => g.isDeleted,
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
                            sortField: 'name',
                            build: (g) => InkWell(
                              onTap: () => context.go('/genres/${g.id}'),
                              child: Text(
                                g.name,
                                style: TextStyle(
                                  color: Theme.of(context).colorScheme.primary,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                        ],
                        actions: _actions,
                      )
                    : ListView.separated(
                        itemCount: notifier.result.items.length,
                        separatorBuilder: (_, _) => const SizedBox(height: 8),
                        itemBuilder: (context, i) {
                          final g = notifier.result.items[i];
                          return Card(
                            child: ListTile(
                              title: Text(g.name),
                              subtitle: g.isDeleted
                                  ? const Text('удалён')
                                  : null,
                              trailing: Wrap(children: _actions(g)),
                              onTap: () => context.go('/genres/${g.id}'),
                            ),
                          );
                        },
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _actions(Genre g) {
    if (g.isDeleted) {
      return [
        IconButton(
          tooltip: 'Восстановить',
          onPressed: () => context.read<GenreListNotifier>().restore(g.id),
          icon: const Icon(Icons.restore),
        ),
        IconButton(
          tooltip: 'Удалить навсегда',
          onPressed: () async {
            final err = await context.read<GenreListNotifier>().hardDelete(
              g.id,
            );
            if (err != null && mounted) {
              ScaffoldMessenger.of(context)
                  .showSnackBar(SnackBar(content: Text(err)));
            }
          },
          icon: const Icon(Icons.delete_forever),
        ),
      ];
    }
    return [
      IconButton(
        tooltip: 'Изменить',
        onPressed: () => context.go('/genres/${g.id}/edit'),
        icon: const Icon(Icons.edit_outlined),
      ),
      IconButton(
        tooltip: 'Удалить',
        onPressed: () => _softDelete(g),
        icon: const Icon(Icons.delete_outline),
      ),
    ];
  }
}
