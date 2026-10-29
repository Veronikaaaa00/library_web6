class PublisherQuery {
  final String search;
  final String? country;
  final String sortField;
  final bool sortAscending;
  final int page;
  final int size;
  final bool includeDeleted;

  const PublisherQuery({
    this.search = '',
    this.country,
    this.sortField = 'name',
    this.sortAscending = true,
    this.page = 1,
    this.size = 10,
    this.includeDeleted = false,
  });

  PublisherQuery copyWith({
    String? search,
    Object? country = _unset,
    String? sortField,
    bool? sortAscending,
    int? page,
    int? size,
    bool? includeDeleted,
  }) {
    return PublisherQuery(
      search: search ?? this.search,
      country: identical(country, _unset) ? this.country : country as String?,
      sortField: sortField ?? this.sortField,
      sortAscending: sortAscending ?? this.sortAscending,
      page: page ?? 1,
      size: size ?? this.size,
      includeDeleted: includeDeleted ?? this.includeDeleted,
    );
  }

  static const _unset = Object();

  factory PublisherQuery.fromUri(Uri uri) {
    final q = uri.queryParameters;
    final sortRaw = q['sort'] ?? 'name,asc';
    final parts = sortRaw.split(',');
    return PublisherQuery(
      search: q['search'] ?? '',
      country: (q['country'] ?? '').isEmpty ? null : q['country'],
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
    if (country != null && country!.trim().isNotEmpty) {
      map['country'] = country!.trim();
    }
    if (includeDeleted) map['includeDeleted'] = 'true';
    return map;
  }

  String toLocation() =>
      Uri(path: '/publishers', queryParameters: toQueryParameters()).toString();

  @override
  bool operator ==(Object other) =>
      other is PublisherQuery &&
      other.search == search &&
      other.country == country &&
      other.sortField == sortField &&
      other.sortAscending == sortAscending &&
      other.page == page &&
      other.size == size &&
      other.includeDeleted == includeDeleted;

  @override
  int get hashCode => Object.hash(
    search,
    country,
    sortField,
    sortAscending,
    page,
    size,
    includeDeleted,
  );
}
