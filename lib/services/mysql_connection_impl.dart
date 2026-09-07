import 'package:mysql_dart/mysql_dart.dart';
import 'database_connection.dart';
import 'orm/mysql_dialect.dart';
import 'orm/sql_dialect.dart';

/// Implémentation MySQL de DatabaseConnection.
class MySQLConnectionImpl extends DatabaseConnection {
  final MySQLConnection _inner;

  MySQLConnectionImpl(this._inner);

  @override
  SqlDialect get dialect => MySqlDialect();

  static Future<MySQLConnectionImpl> connect({
    required String host,
    required int port,
    required String database,
    required String username,
    required String password,
  }) async {
    final connection = await MySQLConnection.createConnection(
      host: host,
      port: port,
      userName: username,
      password: password,
      databaseName: database,
      secure: false,
      allowPublicKeyRetrieval: true,
    );
    await connection.connect();
    return MySQLConnectionImpl(connection);
  }

  @override
  Future<DbQueryResult> query(String sql, [List<Object?>? params]) async {
    final result = await _inner.execute(sql, params ?? []);
    final rows = result.rows.map((r) => DbResultRow(r.assoc())).toList();
    final insertId = result.lastInsertID > BigInt.zero ? result.lastInsertID.toInt() : null;
    return DbQueryResult(rows: rows, insertId: insertId);
  }

  @override
  Future<void> close() => _inner.close();
}
