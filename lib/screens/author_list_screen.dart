import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../core/breakpoints.dart';
import '../core/permissions.dart';
import '../data/seed_data.dart';
import '../models/author.dart';
import '../models/author_query.dart';
import '../state/auth_notifier.dart';
import '../state/author_list_notifier.dart';
import '../widgets/app_scaffold.dart';
import '../widgets/debounced_search_field.dart';
import '../widgets/entity_table.dart';
import '../widgets/load_state_body.dart';
import '../widgets/pagination_bar.dart';

class AuthorListScreen extends StatefulWidget {
  const AuthorListScreen({super.key});

  @override
  State<AuthorListScreen> createState() => _AuthorListScreenState();
}

class _AuthorListScreenState extends State<AuthorListScreen> {
  final _yearFromController = TextEditingController();
  final _yearToController = TextEditingController();
  var _filtersOpen = false;

  static final _countries = {
    for (final author in seedAuthors) author.country,
  }.toList()..sort();

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final uriQuery = AuthorQuery.fromUri(GoRouterState.of(context).uri);
    final notifier = context.read<AuthorListNotifier>();
    if (uriQuery != notifier.query) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        context.read<AuthorListNotifier>().applyQuery(uriQuery);
        _syncYearFields(uriQuery);
      });
    } else {
      _syncYearFields(uriQuery);
    }
  }

  void _syncYearFields(AuthorQuery query) {
    final from = query.birthYearFrom?.toString() ?? '';
    final to = query.birthYearTo?.toString() ?? '';
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

  void _go(AuthorQuery query) {
    context.go(query.toLocation());
  }

  Future<void> _confirmSoftDelete(Author author) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Удалить автора?'),
        content: Text(
          '«${author.fullName}» будет скрыт из списка (логическое удаление).',
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
      await context.read<AuthorListNotifier>().softDelete(author.id);
    }
  }

  Future<void> _confirmDeleteSelected() async {
    final notifier = context.read<AuthorListNotifier>();
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Удалить выбранных?'),
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
      await context.read<AuthorListNotifier>().deleteSelected();
    }
  }

  @override
  Widget build(BuildContext context) {
    final notifier = context.watch<AuthorListNotifier>();
    final canManage = Permissions.canManageCatalog(
      context.watch<AuthNotifier>().role,
    );
    final query = notifier.query;
    final wide = Breakpoints.isWide(context);

    return AppScaffold(
      title: 'Авторы',
      floatingActionButton: canManage
          ? FloatingActionButton(
              onPressed: () => context.go('/authors/new'),
              child: const Icon(Icons.add),
            )
          : null,
      actions: [
        if (notifier.hasSelection)
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: Center(child: Text('Выбрано: ${notifier.selected.length}')),
          ),
        if (notifier.hasSelection)
          IconButton(
            tooltip: 'Удалить выбранных',
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
              hintText: 'Поиск по фамилии или стране',
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
                onRetry: () => context.read<AuthorListNotifier>().load(),
                child: wide
                    ? EntityTable<Author>(
                        items: notifier.result.items,
                        idOf: (a) => a.id,
                        selected: notifier.selected,
                        onToggleSelect: notifier.toggleSelection,
                        sortField: query.sortField,
                        sortAscending: query.sortAscending,
                        isDeleted: (a) => a.isDeleted,
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
                            label: 'Фамилия',
                            sortField: 'lastName',
                            build: (a) => InkWell(
                              onTap: () => context.go('/authors/${a.id}'),
                              child: Text(
                                a.lastName,
                                style: TextStyle(
                                  color: Theme.of(context).colorScheme.primary,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                          TableColumnSpec(
                            label: 'Имя',
                            sortField: 'firstName',
                            build: (a) => Text(a.firstName),
                          ),
                          TableColumnSpec(
                            label: 'Страна',
                            sortField: 'country',
                            build: (a) => Text(a.country),
                          ),
                          TableColumnSpec(
                            label: 'Год рождения',
                            sortField: 'birthYear',
                            numeric: true,
                            build: (a) => Text('${a.birthYear}'),
                          ),
                        ],
                        actions: (a) => _actions(a),
                      )
                    : ListView.separated(
                        itemCount: notifier.result.items.length,
                        separatorBuilder: (context, index) =>
                            const SizedBox(height: 8),
                        itemBuilder: (context, index) {
                          final author = notifier.result.items[index];
                          return _authorCard(author, notifier);
                        },
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _filters(AuthorQuery query) {
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
              child: DropdownButtonFormField<String?>(
                key: ValueKey('country-${query.country}'),
                initialValue: query.country,
                isExpanded: true,
                decoration: const InputDecoration(
                  labelText: 'Страна',
                  border: OutlineInputBorder(),
                  isDense: true,
                ),
                items: [
                  const DropdownMenuItem(value: null, child: Text('Все')),
                  for (final country in _countries)
                    DropdownMenuItem(value: country, child: Text(country)),
                ],
                onChanged: (value) => _go(query.copyWith(country: value)),
              ),
            ),
            SizedBox(
              width: 140,
              child: TextField(
                controller: _yearFromController,
                decoration: const InputDecoration(
                  labelText: 'Год рожд. от',
                  border: OutlineInputBorder(),
                  isDense: true,
                ),
                keyboardType: TextInputType.number,
                onSubmitted: (value) =>
                    _go(query.copyWith(birthYearFrom: int.tryParse(value))),
              ),
            ),
            SizedBox(
              width: 140,
              child: TextField(
                controller: _yearToController,
                decoration: const InputDecoration(
                  labelText: 'Год рожд. до',
                  border: OutlineInputBorder(),
                  isDense: true,
                ),
                keyboardType: TextInputType.number,
                onSubmitted: (value) =>
                    _go(query.copyWith(birthYearTo: int.tryParse(value))),
              ),
            ),
            FilledButton.tonal(
              onPressed: () => _go(
                query.copyWith(
                  birthYearFrom: int.tryParse(_yearFromController.text),
                  birthYearTo: int.tryParse(_yearToController.text),
                ),
              ),
              child: const Text('Применить годы'),
            ),
            FilterChip(
              label: const Text('Показать удалённых'),
              selected: query.includeDeleted,
              onSelected: (value) => _go(query.copyWith(includeDeleted: value)),
            ),
            TextButton(
              onPressed: () {
                _yearFromController.clear();
                _yearToController.clear();
                _go(const AuthorQuery());
              },
              child: const Text('Сбросить'),
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _actions(Author author) {
    if (author.isDeleted) {
      return [
        IconButton(
          tooltip: 'Восстановить',
          onPressed: () =>
              context.read<AuthorListNotifier>().restore(author.id),
          icon: const Icon(Icons.restore),
        ),
        IconButton(
          tooltip: 'Удалить навсегда',
          onPressed: () =>
              context.read<AuthorListNotifier>().hardDelete(author.id),
          icon: const Icon(Icons.delete_forever),
        ),
      ];
    }
    return [
      IconButton(
        tooltip: 'Открыть',
        onPressed: () => context.go('/authors/${author.id}'),
        icon: const Icon(Icons.visibility_outlined),
      ),
      IconButton(
        tooltip: 'Изменить',
        onPressed: () => context.go('/authors/${author.id}/edit'),
        icon: const Icon(Icons.edit_outlined),
      ),
      IconButton(
        tooltip: 'Удалить',
        onPressed: () => _confirmSoftDelete(author),
        icon: const Icon(Icons.delete_outline),
      ),
    ];
  }

  Widget _authorCard(Author author, AuthorListNotifier notifier) {
    return Card(
      child: ListTile(
        leading: Checkbox(
          value: notifier.selected.contains(author.id),
          onChanged: (_) => notifier.toggleSelection(author.id),
        ),
        title: Text(author.fullName),
        subtitle: Text(
          '${author.country} · ${author.birthYear}'
          '${author.isDeleted ? ' · удалён' : ''}',
        ),
        trailing: Wrap(children: _actions(author)),
        onTap: () => context.go('/authors/${author.id}'),
      ),
    );
  }
}
