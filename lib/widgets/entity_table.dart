import 'package:flutter/material.dart';

class TableColumnSpec<T> {
  final String label;
  final String? sortField;
  final bool numeric;
  final Widget Function(T item) build;

  const TableColumnSpec({
    required this.label,
    required this.build,
    this.sortField,
    this.numeric = false,
  });
}

/// Обобщённая таблица сущностей: колонки задаются снаружи,
/// сама таблица одна для книг, авторов и будущих списков.
class EntityTable<T> extends StatelessWidget {
  final List<TableColumnSpec<T>> columns;
  final List<T> items;
  final int Function(T item) idOf;
  final Set<int> selected;
  final ValueChanged<int>? onToggleSelect;
  final String? sortField;
  final bool sortAscending;
  final void Function(String field)? onSort;
  final List<Widget> Function(T item)? actions;
  final bool Function(T item)? isDeleted;

  const EntityTable({
    super.key,
    required this.columns,
    required this.items,
    required this.idOf,
    this.selected = const {},
    this.onToggleSelect,
    this.sortField,
    this.sortAscending = true,
    this.onSort,
    this.actions,
    this.isDeleted,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    // Без Scrollbar: на Flutter Web PrimaryScrollController часто
    // не привязан к вложенному SingleChildScrollView.
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          minWidth: MediaQuery.sizeOf(context).width - 48,
        ),
        child: SingleChildScrollView(
          child: DataTable(
            sortColumnIndex: _sortColumnIndex(),
            sortAscending: sortAscending,
            headingRowColor: WidgetStatePropertyAll(
              scheme.surfaceContainerHighest.withValues(alpha: 0.45),
            ),
            columns: [
              if (onToggleSelect != null) const DataColumn(label: Text('')),
              for (final column in columns)
                DataColumn(
                  label: Text(column.label),
                  numeric: column.numeric,
                  onSort: column.sortField == null || onSort == null
                      ? null
                      : (columnIndex, ascending) => onSort!(column.sortField!),
                ),
              if (actions != null) const DataColumn(label: Text('Действия')),
            ],
            rows: [
              for (final item in items)
                DataRow(
                  selected: selected.contains(idOf(item)),
                  color: (isDeleted?.call(item) ?? false)
                      ? WidgetStatePropertyAll(
                          scheme.errorContainer.withValues(alpha: 0.25),
                        )
                      : null,
                  cells: [
                    if (onToggleSelect != null)
                      DataCell(
                        Checkbox(
                          value: selected.contains(idOf(item)),
                          onChanged: (_) => onToggleSelect!(idOf(item)),
                        ),
                      ),
                    for (final column in columns) DataCell(column.build(item)),
                    if (actions != null)
                      DataCell(
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: actions!(item),
                        ),
                      ),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }

  int? _sortColumnIndex() {
    if (sortField == null) return null;
    var index = 0;
    if (onToggleSelect != null) {
      index += 1;
    }
    for (var i = 0; i < columns.length; i++) {
      if (columns[i].sortField == sortField) {
        return index + i;
      }
    }
    return null;
  }
}
