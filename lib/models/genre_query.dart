class GenreQuery {
  final String search;
  final String sortField;
  final bool sortAscending;
  final int page;
  final int size;
  final bool includeDeleted;

  const GenreQuery({
    this.search = '',
    this.sortField = 'name',
    this.sortAscending = true,
    this.page = 1,
    this.size = 10,
    this.includeDeleted = false,
  });

  GenreQuery copyWith({
    String? search,
    String? sortField,
    bool? sortAscending,
    int? page,
    int? size,
    bool? includeDeleted,
  }) {
    return GenreQuery(
      search: search ?? this.search,
      sortField: sortField ?? this.sortField,
      sortAscending: sortAscending ?? this.sortAscending,
      page: page ?? 1,
      size: size ?? this.size,
      includeDeleted: includeDeleted ?? this.includeDeleted,
    );
  }

  factory GenreQuery.fromUri(Uri uri) {
    final q = uri.queryParameters;
    final sortRaw = q['sort'] ?? 'name,asc';
    final parts = sortRaw.split(',');
    return GenreQuery(
      search: q['search'] ?? '',
      sortField: parts.isNotEmpty && parts.first.isNotEmpty
          ? parts.first
          : 'name',
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
    if (includeDeleted) map['includeDeleted'] = 'true';
    return map;
  }

  String toLocation() =>
      Uri(path: '/genres', queryParameters: toQueryParameters()).toString();

  @override
  bool operator ==(Object other) =>
      other is GenreQuery &&
      other.search == search &&
      other.sortField == sortField &&
      other.sortAscending == sortAscending &&
      other.page == page &&
      other.size == size &&
      other.includeDeleted == includeDeleted;

  @override
  int get hashCode =>
      Object.hash(search, sortField, sortAscending, page, size, includeDeleted);
}
