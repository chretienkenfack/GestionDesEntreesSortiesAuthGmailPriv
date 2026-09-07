import 'sql_dialect.dart';

class MySqlDialect implements SqlDialect {
  @override
  String get name => 'mysql';

  @override
  String formatYear(String columnName) => 'YEAR($columnName)';

  @override
  String formatMonth(String columnName) => 'MONTH($columnName)';

  @override
  String formatParam(int index) => '?';

  @override
  String formatLimit(int limit) => 'LIMIT $limit';

  @override
  String escapeIdentifier(String identifier) => '`$identifier`';
}
