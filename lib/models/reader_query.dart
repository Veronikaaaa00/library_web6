class ReaderQuery {
  final String search;
  final bool? cardActive;
  final String sortField;
  final bool sortAscending;
  final int page;
  final int size;
  final bool includeDeleted;

  const ReaderQuery({
    this.search = '',
    this.cardActive,
    this.sortField = 'lastName',
    this.sortAscending = true,
    this.page = 1,
    this.size = 10,
    this.includeDeleted = false,
  });

  ReaderQuery copyWith({
    String? search,
    Object? cardActive = _unset,
    String? sortField,
    bool? sortAscending,
    int? page,
    int? size,
    bool? includeDeleted,
  }) {
    return ReaderQuery(
      search: search ?? this.search,
      cardActive: identical(cardActive, _unset)
          ? this.cardActive
          : cardActive as bool?,
      sortField: sortField ?? this.sortField,
      sortAscending: sortAscending ?? this.sortAscending,
      page: page ?? 1,
      size: size ?? this.size,
      includeDeleted: includeDeleted ?? this.includeDeleted,
    );
  }

  static const _unset = Object();

  factory ReaderQuery.fromUri(Uri uri) {
    final q = uri.queryParameters;
    final sortRaw = q['sort'] ?? 'lastName,asc';
    final parts = sortRaw.split(',');
    bool? cardActive;
    if (q['cardActive'] == 'true') cardActive = true;
    if (q['cardActive'] == 'false') cardActive = false;
    return ReaderQuery(
      search: q['search'] ?? '',
      cardActive: cardActive,
      sortField: parts.isNotEmpty && parts.first.isNotEmpty
          ? parts.first
          : 'lastName',
      sortAscending: parts.length < 2 || parts[1] != 'desc',
      page: int.tryParse(q['page'] ?? '') ?? 1,
      size: int.tryParse(q['size'] ?? '') ?? 10,
      includeDeleted: q['includeDeleted'] == 'true',
    );
  }

  Map<String, String> toQueryParameters() {
    final map = <String, String>{
      'sort': '$sortField,${sortAscending ? 'asc' : 'desc'}',
      'page': '$page',
      'size': '$size',
    };
    if (search.trim().isNotEmpty) map['search'] = search.trim();
    if (cardActive != null) map['cardActive'] = '$cardActive';
    if (includeDeleted) map['includeDeleted'] = 'true';
    return map;
  }

  String toLocation() =>
      Uri(path: '/readers', queryParameters: toQueryParameters()).toString();

  @override
  bool operator ==(Object other) =>
      other is ReaderQuery &&
      other.search == search &&
      other.cardActive == cardActive &&
      other.sortField == sortField &&
      other.sortAscending == sortAscending &&
      other.page == page &&
      other.size == size &&
      other.includeDeleted == includeDeleted;

  @override
  int get hashCode => Object.hash(
    search,
    cardActive,
    sortField,
    sortAscending,
    page,
    size,
    includeDeleted,
  );
}
