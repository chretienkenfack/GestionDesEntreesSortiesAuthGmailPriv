import 'dart:collection';

import 'package:mysql_dart/mysql_dart.dart';

/// Ligne de résultat compatible avec l'ancienne API mysql1 (.fields).
class DbResultRow {
  final Map<String, dynamic> fields;
  const DbResultRow(this.fields);
}

/// Résultat de requête compatible avec l'ancienne API mysql1.
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

/// Connexion MySQL exposée aux services métier.
class DbConnection {
  final MySQLConnection _inner;

  DbConnection(this._inner);

  Future<DbQueryResult> query(String sql, [List<Object?>? params]) async {
    final result = await _inner.execute(sql, params ?? []);
    final rows = result.rows.map((r) => DbResultRow(r.assoc())).toList();
    final insertId = result.lastInsertID > BigInt.zero ? result.lastInsertID.toInt() : null;
    return DbQueryResult(rows: rows, insertId: insertId);
  }

  Future<void> close() => _inner.close();
}
