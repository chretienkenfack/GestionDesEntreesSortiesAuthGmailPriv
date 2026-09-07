import 'sql_dialect.dart';

class SqlServerDialect implements SqlDialect {
  @override
  String get name => 'sqlserver';

  @override
  String formatYear(String columnName) => 'YEAR($columnName)';

  @override
  String formatMonth(String columnName) => 'MONTH($columnName)';

  @override
  String formatParam(int index) => '@p$index';

  @override
  String formatLimit(int limit) => 'OFFSET 0 ROWS FETCH NEXT $limit ROWS ONLY';

  @override
  String escapeIdentifier(String identifier) => '[$identifier]';
}
