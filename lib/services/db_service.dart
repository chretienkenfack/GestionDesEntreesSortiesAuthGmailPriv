import 'dart:async';
import 'dart:io';
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
      final host = PlatformDbHost.hostEffectif(settingsActuels.host);
      _inner = await MySQLConnection.createConnection(
        host: host,
        port: settingsActuels.port,
        userName: settingsActuels.username,
        password: settingsActuels.password,
        databaseName: settingsActuels.database,
        secure: false,
        allowPublicKeyRetrieval: true,
      );
      try {
        await _inner!.connect().timeout(
          const Duration(seconds: 5),
          onTimeout: () {
            throw TimeoutException(
                "Délai d'attente dépassé (5s) vers $host:${settingsActuels.port}.");
          },
        );
      } catch (e) {
        await _fermerConnexionExistante();
        rethrow;
      }
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

  /// Retourne `DbTestResult` avec le détail précis en cas d'erreur.
  Future<DbTestResult> tester(DbSettings settings) async {
    MySQLConnection? conn;
    final host = PlatformDbHost.hostEffectif(settings.host);
    try {
      conn = await MySQLConnection.createConnection(
        host: host,
        port: settings.port,
        userName: settings.username,
        password: settings.password,
        databaseName: settings.database,
        secure: false,
        allowPublicKeyRetrieval: true,
      );

      await conn.connect().timeout(
        const Duration(seconds: 5),
        onTimeout: () {
          throw TimeoutException(
            "Impossible d'atteindre le serveur $host:${settings.port} (Timeout de 5s).\n"
            "• Si vous utilisez NoxPlayer, utilisez l'adresse IP locale de votre PC (ex: 192.168.1.XX) au lieu de 10.0.2.2 ou 127.0.0.1.\n"
            "• Vérifiez votre pare-feu Windows pour le port ${settings.port}.",
          );
        },
      );

      await conn.execute('SELECT 1').timeout(const Duration(seconds: 3));
      return const DbTestResult(succes: true);
    } on TimeoutException catch (e) {
      return DbTestResult(succes: false, message: e.message);
    } on SocketException catch (e) {
      return DbTestResult(
        succes: false,
        message: "Erreur réseau ($host:${settings.port}) : ${e.message}",
      );
    } catch (e) {
      return DbTestResult(succes: false, message: "Échec de connexion : $e");
    } finally {
      try {
        await conn?.close();
      } catch (_) {}
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
