import 'package:mysql_dart/mysql_dart.dart';
import '../models/db_settings.dart';
import '../utils/platform_db_host.dart';
import 'db_connection.dart';
import 'settings_service.dart';

/// Service singleton qui gère la connexion MySQL courante.
class DbService {
  DbService._internal();
  static final DbService instance = DbService._internal();

  DbConnection? _connection;
  MySQLConnection? _inner;
  DbSettings? _settingsUtilises;
  final SettingsService _settingsService = SettingsService();

  Future<DbConnection> getConnection() async {
    final settingsActuels = await _settingsService.getDbSettings();

    final settingsOntChange = _settingsUtilises == null ||
        _settingsUtilises!.host != settingsActuels.host ||
        _settingsUtilises!.port != settingsActuels.port ||
        _settingsUtilises!.database != settingsActuels.database ||
        _settingsUtilises!.username != settingsActuels.username ||
        _settingsUtilises!.password != settingsActuels.password;

    if (_connection == null || settingsOntChange) {
      await _fermerConnexionExistante();
      _inner = await MySQLConnection.createConnection(
        host: PlatformDbHost.hostEffectif(settingsActuels.host),
        port: settingsActuels.port,
        userName: settingsActuels.username,
        password: settingsActuels.password,
        databaseName: settingsActuels.database,
        secure: false,
        allowPublicKeyRetrieval: true,
      );
      await _inner!.connect();
      _connection = DbConnection(_inner!);
      _settingsUtilises = settingsActuels;
    }
    return _connection!;
  }

  Future<void> _fermerConnexionExistante() async {
    try {
      await _connection?.close();
    } catch (_) {}
    _connection = null;
    _inner = null;
  }

  /// Retourne `true` si la connexion réussit, sinon le message d'erreur.
  Future<DbTestResult> tester(DbSettings settings) async {
    MySQLConnection? conn;
    try {
      conn = await MySQLConnection.createConnection(
        host: PlatformDbHost.hostEffectif(settings.host),
        port: settings.port,
        userName: settings.username,
        password: settings.password,
        databaseName: settings.database,
        secure: false,
        allowPublicKeyRetrieval: true,
      );
      await conn.connect();
      await conn.execute('SELECT 1');
      return const DbTestResult(succes: true);
    } catch (e) {
      return DbTestResult(succes: false, message: e.toString());
    } finally {
      await conn?.close();
    }
  }

  Future<void> reinitialiser() async {
    await _fermerConnexionExistante();
    _settingsUtilises = null;
  }
}

class DbTestResult {
  final bool succes;
  final String? message;

  const DbTestResult({required this.succes, this.message});
}
