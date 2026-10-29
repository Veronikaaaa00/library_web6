import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../core/breakpoints.dart';
import '../models/reader.dart';
import '../models/reader_query.dart';
import '../state/reader_list_notifier.dart';
import '../widgets/app_scaffold.dart';
import '../widgets/debounced_search_field.dart';
import '../widgets/entity_table.dart';
import '../widgets/load_state_body.dart';
import '../widgets/pagination_bar.dart';

class ReaderListScreen extends StatefulWidget {
  const ReaderListScreen({super.key});

  @override
  State<ReaderListScreen> createState() => _ReaderListScreenState();
}

class _ReaderListScreenState extends State<ReaderListScreen> {
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final uriQuery = ReaderQuery.fromUri(GoRouterState.of(context).uri);
    final notifier = context.read<ReaderListNotifier>();
    if (uriQuery != notifier.query) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        context.read<ReaderListNotifier>().applyQuery(uriQuery);
      });
    }
  }

  void _go(ReaderQuery query) => context.go(query.toLocation());

  @override
  Widget build(BuildContext context) {
    final notifier = context.watch<ReaderListNotifier>();
    final query = notifier.query;
    final wide = Breakpoints.isWide(context);

    return AppScaffold(
      title: 'Читатели',
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.go('/readers/new'),
        child: const Icon(Icons.add),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            DebouncedSearchField(
              initialValue: query.search,
              hintText: 'Поиск по ФИО, email или номеру билета',
              onChanged: (v) => _go(query.copyWith(search: v)),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: [
                FilterChip(
                  label: const Text('Активный билет'),
                  selected: query.cardActive == true,
                  onSelected: (v) =>
                      _go(query.copyWith(cardActive: v ? true : null)),
                ),
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
                onRetry: () => context.read<ReaderListNotifier>().load(),
                child: wide
                    ? EntityTable<Reader>(
                        items: notifier.result.items,
                        idOf: (r) => r.id,
                        selected: notifier.selected,
                        onToggleSelect: notifier.toggleSelection,
                        sortField: query.sortField,
                        sortAscending: query.sortAscending,
                        isDeleted: (r) => r.isDeleted,
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
                            label: 'ФИО',
                            sortField: 'lastName',
                            build: (r) => InkWell(
                              onTap: () => context.go('/readers/${r.id}'),
                              child: Text(
                                r.fullName,
                                style: TextStyle(
                                  color: Theme.of(context).colorScheme.primary,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                          TableColumnSpec(
                            label: 'Email',
                            sortField: 'email',
                            build: (r) => Text(r.email),
                          ),
                          TableColumnSpec(
                            label: 'Билет',
                            sortField: 'card',
                            build: (r) => Text(
                              '${r.card.number}${r.card.isActive ? '' : ' (неакт.)'}',
                            ),
                          ),
                        ],
                        actions: _actions,
                      )
                    : ListView.separated(
                        itemCount: notifier.result.items.length,
                        separatorBuilder: (_, _) => const SizedBox(height: 8),
                        itemBuilder: (context, i) {
                          final r = notifier.result.items[i];
                          return Card(
                            child: ListTile(
                              title: Text(r.fullName),
                              subtitle: Text(
                                '${r.email} · ${r.card.number}'
                                '${r.isDeleted ? ' · удалён' : ''}',
                              ),
                              trailing: Wrap(children: _actions(r)),
                              onTap: () => context.go('/readers/${r.id}'),
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

  List<Widget> _actions(Reader r) {
    if (r.isDeleted) {
      return [
        IconButton(
          tooltip: 'Восстановить',
          onPressed: () => context.read<ReaderListNotifier>().restore(r.id),
          icon: const Icon(Icons.restore),
        ),
        IconButton(
          tooltip: 'Удалить навсегда',
          onPressed: () => context.read<ReaderListNotifier>().hardDelete(r.id),
          icon: const Icon(Icons.delete_forever),
        ),
      ];
    }
    return [
      IconButton(
        tooltip: 'Изменить',
        onPressed: () => context.go('/readers/${r.id}/edit'),
        icon: const Icon(Icons.edit_outlined),
      ),
      IconButton(
        tooltip: 'Удалить',
        onPressed: () => context.read<ReaderListNotifier>().softDelete(r.id),
        icon: const Icon(Icons.delete_outline),
      ),
    ];
  }
}
