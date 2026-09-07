/// Interface d'abstraction des dialectes SQL (MySQL, PostgreSQL, SQL Server).
abstract class SqlDialect {
  String get name;

  /// Formate l'extraction de l'année d'une colonne date.
  /// Exemple:
  /// - MySQL / SQL Server : YEAR(colonne)
  /// - PostgreSQL : EXTRACT(YEAR FROM colonne)
  String formatYear(String columnName);

  /// Formate l'extraction du mois d'une colonne date.
  /// Exemple:
  /// - MySQL / SQL Server : MONTH(colonne)
  /// - PostgreSQL : EXTRACT(MONTH FROM colonne)
  String formatMonth(String columnName);

  /// Formate un marqueur de paramètre préparé (1-indexed index).
  /// Exemple:
  /// - MySQL : ?
  /// - PostgreSQL : $1, $2, ...
  /// - SQL Server : @p1, @p2, ...
  String formatParam(int index);

  /// Formate la clause de limitation du nombre de résultats.
  /// Exemple:
  /// - MySQL / PostgreSQL : LIMIT n
  /// - SQL Server : TOP n (ou OFFSET/FETCH)
  String formatLimit(int limit);

  /// Formate l'alias ou l'échappement d'un nom de table ou de colonne.
  String escapeIdentifier(String identifier);
}
