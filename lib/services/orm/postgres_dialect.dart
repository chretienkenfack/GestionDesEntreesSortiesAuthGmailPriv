import 'sql_dialect.dart';

class PostgresDialect implements SqlDialect {
  @override
  String get name => 'postgres';

  @override
  String formatYear(String columnName) => 'EXTRACT(YEAR FROM $columnName)';

  @override
  String formatMonth(String columnName) => 'EXTRACT(MONTH FROM $columnName)';

  @override
  String formatParam(int index) => '\$$index';

  @override
  String formatLimit(int limit) => 'LIMIT $limit';

  @override
  String escapeIdentifier(String identifier) => '"$identifier"';
}
