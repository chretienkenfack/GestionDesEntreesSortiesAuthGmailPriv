import 'dart:collection';
import 'orm/query_builder.dart';
import 'orm/sql_dialect.dart';

/// Ligne de résultat compatible avec l'ancienne API.
class DbResultRow {
  final Map<String, dynamic> fields;
  const DbResultRow(this.fields);
}

/// Résultat de requête compatible.
class DbQueryResult extends IterableBase<DbResultRow> {
  final List<DbResultRow> _rows;
  final int? insertId;

  DbQueryResult({required List<DbResultRow> rows, this.insertId}) : _rows = rows;

  @override
  bool get isEmpty => _rows.isEmpty;

  @override
  bool get isNotEmpty => _rows.isNotEmpty;

  DbResultRow get first => _rows.first;

  @override
  Iterator<DbResultRow> get iterator => _rows.iterator;

  @override
  int get length => _rows.length;
}

/// Interface abstraite pour toutes les connexions de base de données.
abstract class DatabaseConnection {
  /// Le dialecte SQL associé à ce SGBD.
  SqlDialect get dialect;

  /// Retourne une instance de QueryBuilder configurée avec le dialecte de cette connexion.
  QueryBuilder get queryBuilder => QueryBuilder(dialect);

  /// Exécute une requête SQL avec paramètres optionnels.
  Future<DbQueryResult> query(String sql, [List<Object?>? params]);

  /// Ferme la connexion.
  Future<void> close();
}
