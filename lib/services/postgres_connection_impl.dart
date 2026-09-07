import 'package:postgres/postgres.dart';
import 'database_connection.dart';
import 'orm/postgres_dialect.dart';
import 'orm/sql_dialect.dart';

/// Implémentation PostgreSQL de DatabaseConnection (compatible package postgres 2.x).
class PostgresConnectionImpl extends DatabaseConnection {
  final PostgreSQLConnection _inner;

  PostgresConnectionImpl(this._inner);

  @override
  SqlDialect get dialect => PostgresDialect();

  static Future<PostgresConnectionImpl> connect({
    required String host,
    required int port,
    required String database,
    required String username,
    required String password,
  }) async {
    final connection = PostgreSQLConnection(
      host,
      port,
      database,
      username: username,
      password: password,
      useSSL: false,
    );
    await connection.open();
    return PostgresConnectionImpl(connection);
  }

  @override
  Future<DbQueryResult> query(String sql, [List<Object?>? params]) async {
    try {
      final map = params != null ? _mapParams(params) : null;
      final results = await _inner.query(sql, substitutionValues: map);

      final rows = <DbResultRow>[];
      for (final row in results) {
        final fields = <String, dynamic>{};
        for (int i = 0; i < results.columnDescriptions.length; i++) {
          final colName = results.columnDescriptions[i].columnName;
          fields[colName] = row[i];
        }
        rows.add(DbResultRow(fields));
      }
      return DbQueryResult(rows: rows, insertId: null);
    } catch (e) {
      rethrow;
    }
  }

  Map<String, dynamic> _mapParams(List<Object?> params) {
    final map = <String, dynamic>{};
    for (int i = 0; i < params.length; i++) {
      final keyIndex = '${i + 1}';
      map[keyIndex] = params[i];
    }
    return map;
  }

  @override
  Future<void> close() => _inner.close();
}
