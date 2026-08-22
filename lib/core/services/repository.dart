import 'package:personal_financial_assistant/core/models/entity.dart';

abstract class Repository<T extends Entity> {
  Future<T?> getById(String id);
  Future<List<T>> getAll({int? limit, int? offset});
  Future<T> create(T entity);
  Future<T> update(T entity);
  Future<void> delete(String id);
  Stream<List<T>> watchAll({int? limit});
  Stream<T?> watchById(String id);
}

abstract class UserScopedRepository<T extends Entity> extends Repository<T> {
  Future<List<T>> getByUserId(String userId, {int? limit, int? offset});
  Stream<List<T>> watchByUserId(String userId, {int? limit});
  Future<T> createForUser(String userId, T entity);
  Future<T> updateForUser(String userId, T entity);
  Future<void> deleteForUser(String userId, String id);
}

abstract class QueryableRepository<T extends Entity> {
  Future<List<T>> query({
    String? orderBy,
    bool descending = true,
    int? limit,
    int? offset,
    Map<String, dynamic>? filters,
  });

  Stream<List<T>> watchQuery({
    String? orderBy,
    bool descending = true,
    int? limit,
    Map<String, dynamic>? filters,
  });
}

class PaginationParams {
  final int limit;
  final int offset;

  const PaginationParams({this.limit = 20, this.offset = 0});

  PaginationParams nextPage() =>
      PaginationParams(limit: limit, offset: offset + limit);
  PaginationParams previousPage() => PaginationParams(
    limit: limit,
    offset: (offset - limit).clamp(0, double.infinity).toInt(),
  );
}

class QueryParams {
  final String? orderBy;
  final bool descending;
  final int? limit;
  final Map<String, dynamic>? filters;

  const QueryParams({
    this.orderBy,
    this.descending = true,
    this.limit,
    this.filters,
  });

  QueryParams copyWith({
    String? orderBy,
    bool? descending,
    int? limit,
    Map<String, dynamic>? filters,
  }) {
    return QueryParams(
      orderBy: orderBy ?? this.orderBy,
      descending: descending ?? this.descending,
      limit: limit ?? this.limit,
      filters: filters ?? this.filters,
    );
  }
}
