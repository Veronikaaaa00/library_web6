import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../core/breakpoints.dart';
import '../core/permissions.dart';
import '../models/publisher.dart';
import '../models/publisher_query.dart';
import '../state/auth_notifier.dart';
import '../state/publisher_list_notifier.dart';
import '../widgets/app_scaffold.dart';
import '../widgets/debounced_search_field.dart';
import '../widgets/entity_table.dart';
import '../widgets/load_state_body.dart';
import '../widgets/pagination_bar.dart';

class PublisherListScreen extends StatefulWidget {
  const PublisherListScreen({super.key});

  @override
  State<PublisherListScreen> createState() => _PublisherListScreenState();
}

class _PublisherListScreenState extends State<PublisherListScreen> {
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final uriQuery = PublisherQuery.fromUri(GoRouterState.of(context).uri);
    final notifier = context.read<PublisherListNotifier>();
    if (uriQuery != notifier.query) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        context.read<PublisherListNotifier>().applyQuery(uriQuery);
      });
    }
  }

  void _go(PublisherQuery query) => context.go(query.toLocation());

  Future<void> _softDelete(Publisher p) async {
    final msg = await context.read<PublisherListNotifier>().softDelete(p.id);
    if (msg != null && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final notifier = context.watch<PublisherListNotifier>();
    final canManage = Permissions.canManageCatalog(
      context.watch<AuthNotifier>().role,
    );
    final query = notifier.query;
    final wide = Breakpoints.isWide(context);

    return AppScaffold(
      title: 'Издательства',
      floatingActionButton: canManage
          ? FloatingActionButton(
              onPressed: () => context.go('/publishers/new'),
              child: const Icon(Icons.add),
            )
          : null,
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            DebouncedSearchField(
              initialValue: query.search,
              hintText: 'Поиск по названию или стране',
              onChanged: (v) => _go(query.copyWith(search: v)),
            ),
            const SizedBox(height: 8),
            FilterChip(
              label: const Text('Показать удалённые'),
              selected: query.includeDeleted,
              onSelected: (v) => _go(query.copyWith(includeDeleted: v)),
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
                onRetry: () => context.read<PublisherListNotifier>().load(),
                child: wide
                    ? EntityTable<Publisher>(
                        items: notifier.result.items,
                        idOf: (p) => p.id,
                        selected: notifier.selected,
                        onToggleSelect: notifier.toggleSelection,
                        sortField: query.sortField,
                        sortAscending: query.sortAscending,
                        isDeleted: (p) => p.isDeleted,
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
                            build: (p) => InkWell(
                              onTap: () => context.go('/publishers/${p.id}'),
                              child: Text(
                                p.name,
                                style: TextStyle(
                                  color: Theme.of(context).colorScheme.primary,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                          TableColumnSpec(
                            label: 'Страна',
                            sortField: 'country',
                            build: (p) => Text(p.country),
                          ),
                        ],
                        actions: _actions,
                      )
                    : ListView.separated(
                        itemCount: notifier.result.items.length,
                        separatorBuilder: (_, _) => const SizedBox(height: 8),
                        itemBuilder: (context, i) {
                          final p = notifier.result.items[i];
                          return Card(
                            child: ListTile(
                              title: Text(p.name),
                              subtitle: Text(
                                '${p.country}${p.isDeleted ? ' · удалён' : ''}',
                              ),
                              trailing: Wrap(children: _actions(p)),
                              onTap: () => context.go('/publishers/${p.id}'),
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

  List<Widget> _actions(Publisher p) {
    if (p.isDeleted) {
      return [
        IconButton(
          tooltip: 'Восстановить',
          onPressed: () => context.read<PublisherListNotifier>().restore(p.id),
          icon: const Icon(Icons.restore),
        ),
      ];
    }
    return [
      IconButton(
        tooltip: 'Изменить',
        onPressed: () => context.go('/publishers/${p.id}/edit'),
        icon: const Icon(Icons.edit_outlined),
      ),
      IconButton(
        tooltip: 'Удалить',
        onPressed: () => _softDelete(p),
        icon: const Icon(Icons.delete_outline),
      ),
    ];
  }
}
