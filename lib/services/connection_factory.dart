import '../models/db_settings.dart';
import 'database_connection.dart';
import 'mysql_connection_impl.dart';
import 'postgres_connection_impl.dart';

/// Factory pour créer la bonne connexion de base de données selon le type de SGBD.
class ConnectionFactory {
  static Future<DatabaseConnection> create(DbSettings settings) async {
    switch (settings.sgbdType.toLowerCase()) {
      case 'mysql':
        return MySQLConnectionImpl.connect(
          host: settings.host,
          port: settings.port,
          database: settings.database,
          username: settings.username,
          password: settings.password,
        );
      case 'postgres':
      case 'postgresql':
        return PostgresConnectionImpl.connect(
          host: settings.host,
          port: settings.port,
          database: settings.database,
          username: settings.username,
          password: settings.password,
        );
      case 'sqlserver':
      case 'mssql':
        throw UnsupportedError(
          'SQL Server : Le dialecte ORM est configuré, mais la connexion TCP directe nécessite un serveur API backend intermédiaire (Node.js/C#/.NET) sous Flutter.',
        );
      default:
        throw UnsupportedError('Type de SGBD non supporté: ${settings.sgbdType}');
    }
  }

  static String getDefaultPort(String sgbdType) {
    switch (sgbdType.toLowerCase()) {
      case 'mysql':
        return '3306';
      case 'postgres':
      case 'postgresql':
        return '5432';
      case 'sqlserver':
      case 'mssql':
        return '1433';
      default:
        return '3306';
    }
  }
}
