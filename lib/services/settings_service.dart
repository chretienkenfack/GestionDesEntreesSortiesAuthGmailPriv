import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/db_settings.dart';
import '../utils/constants.dart';
import '../utils/platform_db_host.dart';

/// Service responsable de la persistance des paramètres de l'application,
/// notamment l'adresse IP / port de la base de données, afin que
/// l'application puisse être reconfigurée pour cibler une autre base
/// sans recompilation.
class SettingsService {
  Future<DbSettings> getDbSettings() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(AppConstants.cleParametresDb);
    if (raw == null) return _defaultsPlateforme();
    try {
      return _normaliserHote(DbSettings.fromMap(jsonDecode(raw) as Map<String, dynamic>));
    } catch (_) {
      return _defaultsPlateforme();
    }
  }

  Future<void> saveDbSettings(DbSettings settings) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      AppConstants.cleParametresDb,
      jsonEncode(settings.toMap()),
    );
  }

  Future<String> getDevise() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(AppConstants.cleDevise) ?? AppConstants.deviseParDefaut;
  }

  Future<void> saveDevise(String devise) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(AppConstants.cleDevise, devise);
  }

  Future<String> getNomEntreprise() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(AppConstants.cleNomEntreprise) ?? AppConstants.nomEntrepriseParDefaut;
  }

  Future<void> saveNomEntreprise(String nom) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(AppConstants.cleNomEntreprise, nom);
  }

  DbSettings _defaultsPlateforme() => DbSettings.defaults().copyWith(
        host: PlatformDbHost.defaultHost,
      );

  /// Corrige automatiquement localhost sur Android (127.0.0.1 → 10.0.2.2).
  DbSettings _normaliserHote(DbSettings settings) {
    final hostCorrige = PlatformDbHost.hostEffectif(settings.host);
    if (hostCorrige == settings.host) return settings;
    return settings.copyWith(host: hostCorrige);
  }
}
