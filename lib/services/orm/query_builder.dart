import 'sql_dialect.dart';

class SqlResult {
  final String sql;
  final List<Object?> params;

  const SqlResult(this.sql, this.params);
}

class QueryBuilder {
  final SqlDialect dialect;

  QueryBuilder(this.dialect);

  /// Construit une requête SELECT complète.
  SelectQuery select([List<String> fields = const ['*']]) {
    return SelectQuery(dialect, fields);
  }

  /// Construit une requête INSERT.
  SqlResult insertInto(String table, Map<String, dynamic> values) {
    final columns = values.keys.toList();
    final params = values.values.toList();

    final placeholders = <String>[];
    for (int i = 0; i < columns.length; i++) {
      placeholders.add(dialect.formatParam(i + 1));
    }

    final sql =
        'INSERT INTO $table (${columns.join(', ')}) VALUES (${placeholders.join(', ')})';
    return SqlResult(sql, params);
  }

  /// Construit une requête UPDATE.
  SqlResult update(
    String table,
    Map<String, dynamic> values, {
    required String where,
    List<Object?> whereParams = const [],
  }) {
    final setClauses = <String>[];
    final params = <Object?>[];

    int paramIndex = 1;
    values.forEach((col, val) {
      setClauses.add('$col = ${dialect.formatParam(paramIndex)}');
      params.add(val);
      paramIndex++;
    });

    // Adapter les marqueurs dans le 'where' si nécessaire
    String formattedWhere = where;
    for (int i = 0; i < whereParams.length; i++) {
      final oldParam = dialect.name == 'mysql' ? '?' : '\$${i + 1}';
      final newParam = dialect.formatParam(paramIndex);
      if (oldParam != newParam) {
        formattedWhere = formattedWhere.replaceFirst(oldParam, newParam);
      }
      params.add(whereParams[i]);
      paramIndex++;
    }

    final sql = 'UPDATE $table SET ${setClauses.join(', ')} WHERE $formattedWhere';
    return SqlResult(sql, params);
  }

  /// Construit une requête DELETE.
  SqlResult deleteFrom(
    String table, {
    required String where,
    List<Object?> whereParams = const [],
  }) {
    final params = <Object?>[];
    int paramIndex = 1;

    String formattedWhere = where;
    for (int i = 0; i < whereParams.length; i++) {
      final oldParam = dialect.name == 'mysql' ? '?' : '\$${i + 1}';
      final newParam = dialect.formatParam(paramIndex);
      if (oldParam != newParam) {
        formattedWhere = formattedWhere.replaceFirst(oldParam, newParam);
      }
      params.add(whereParams[i]);
      paramIndex++;
    }

    final sql = 'DELETE FROM $table WHERE $formattedWhere';
    return SqlResult(sql, params);
  }
}

class SelectQuery {
  final SqlDialect dialect;
  final List<String> fields;

  String? _fromTable;
  final List<String> _joins = [];
  final List<String> _whereConditions = [];
  final List<Object?> _params = [];
  String? _orderBy;
  int? _limit;
  String? _groupBy;

  SelectQuery(this.dialect, this.fields);

  SelectQuery from(String table, [String? alias]) {
    _fromTable = alias != null ? '$table $alias' : table;
    return this;
  }

  SelectQuery leftJoin(String table, String alias, String condition) {
    _joins.add('LEFT JOIN $table $alias ON $condition');
    return this;
  }

  SelectQuery whereRaw(String condition, [List<Object?>? params]) {
    _addCondition(condition, params);
    return this;
  }

  SelectQuery whereYear(String columnName, int year) {
    final condition = '${dialect.formatYear(columnName)} = ${dialect.formatParam(_params.length + 1)}';
    _addCondition(condition, [year]);
    return this;
  }

  SelectQuery whereMonth(String columnName, int month) {
    final condition = '${dialect.formatMonth(columnName)} = ${dialect.formatParam(_params.length + 1)}';
    _addCondition(condition, [month]);
    return this;
  }

  SelectQuery orderBy(String clause) {
    _orderBy = clause;
    return this;
  }

  SelectQuery groupBy(String clause) {
    _groupBy = clause;
    return this;
  }

  SelectQuery limit(int limit) {
    _limit = limit;
    return this;
  }

  void _addCondition(String condition, List<Object?>? params) {
    // Si la condition contient '?', remplacer par le paramètre du dialecte courant
    String formattedCondition = condition;
    if (params != null && params.isNotEmpty) {
      for (final param in params) {
        _params.add(param);
        final placeholder = dialect.formatParam(_params.length);
        formattedCondition = formattedCondition.replaceFirst('?', placeholder);
      }
    }
    _whereConditions.add(formattedCondition);
  }

  SqlResult build() {
    final sb = StringBuffer();
    sb.write('SELECT ${fields.join(', ')}');
    if (_fromTable != null) {
      sb.write(' FROM $_fromTable');
    }
    if (_joins.isNotEmpty) {
      sb.write(' ${joinWithSpaces(_joins)}');
    }
    if (_whereConditions.isNotEmpty) {
      sb.write(' WHERE ${_whereConditions.join(' AND ')}');
    }
    if (_groupBy != null) {
      sb.write(' GROUP BY $_groupBy');
    }
    if (_orderBy != null) {
      sb.write(' ORDER BY $_orderBy');
    }
    if (_limit != null) {
      sb.write(' ${dialect.formatLimit(_limit!)}');
    }

    return SqlResult(sb.toString(), List.unmodifiable(_params));
  }

  static String joinWithSpaces(List<String> list) => list.join(' ');
}
