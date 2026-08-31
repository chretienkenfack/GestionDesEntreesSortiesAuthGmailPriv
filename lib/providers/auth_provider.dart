import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user.dart';
import '../services/auth_service.dart';
import '../services/db_service.dart';
import '../services/google_auth_service.dart';
import '../utils/constants.dart';

/// Gestionnaire d'état de l'authentification.
/// Utilisé via [ChangeNotifierProvider] dans toute l'application.
class AuthProvider extends ChangeNotifier {
  final AuthService _authService = AuthService();

  AppUser? _utilisateurConnecte;
  bool _chargement = false;
  String? _erreur;

  AuthProvider() {
    _restaurerSession();
  }

  Future<void> _restaurerSession() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(AppConstants.cleUtilisateurSession);
      if (raw != null && raw.isNotEmpty) {
        _utilisateurConnecte = AppUser.fromMap(jsonDecode(raw) as Map<String, dynamic>);
        notifyListeners();
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[AuthProvider] Erreur restauration session : $e');
      }
    }
  }

  Future<void> _sauvegarderSession(AppUser user) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(AppConstants.cleUtilisateurSession, jsonEncode(user.toMap()));
    } catch (_) {}
  }

  Future<void> _effacerSession() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(AppConstants.cleUtilisateurSession);
    } catch (_) {}
  }

  // ── Getters publics ──────────────────────────────────────────────────────
  AppUser? get utilisateur => _utilisateurConnecte;
  bool get estConnecte => _utilisateurConnecte != null;
  bool get estAdmin => _utilisateurConnecte?.isAdmin ?? false;

  /// `true` pendant la connexion/inscription classique (email + mot de passe)
  bool get chargement => _chargement;

  String? get erreur => _erreur;

  // ── Connexion email + mot de passe ───────────────────────────────────────
  Future<bool> connecter(String email, String motDePasse) async {
    _demarrerChargement();
    try {
      _utilisateurConnecte = await _authService.login(email, motDePasse);
      if (_utilisateurConnecte != null) {
        await _sauvegarderSession(_utilisateurConnecte!);
      }
      _erreur = null;
      return true;
    } catch (e) {
      _erreur = _messagePropre(e);
      return false;
    } finally {
      _terminerChargement();
    }
  }

  // ── Inscription classique ────────────────────────────────────────────────
  Future<bool> inscrire(String nom, String email, String motDePasse) async {
    _demarrerChargement();
    try {
      _utilisateurConnecte = await _authService.inscrire(
        nom: nom,
        email: email,
        motDePasse: motDePasse,
      );
      if (_utilisateurConnecte != null) {
        await _sauvegarderSession(_utilisateurConnecte!);
      }
      _erreur = null;
      return true;
    } catch (e) {
      _erreur = _messagePropre(e);
      return false;
    } finally {
      _terminerChargement();
    }
  }

  // ── Connexion Google (OAuth Google + comptes en MySQL local) ───────────
  Future<AppUser?> verifierUtilisateurGoogle(String email) async {
    _demarrerChargement();
    try {
      final user = await _authService.checkGoogleUser(email);
      if (user != null) {
        _utilisateurConnecte = user;
        await _sauvegarderSession(user);
        _erreur = null;
      }
      return user;
    } catch (e) {
      _erreur = _messagePropre(e);
      return null;
    } finally {
      _terminerChargement();
    }
  }

  Future<bool> finaliserInscriptionGoogle({
    required String nom,
    required String email,
    required String role,
    String? googleId,
    String? photoUrl,
  }) async {
    _demarrerChargement();
    try {
      _utilisateurConnecte = await _authService.registerGoogleUserWithRole(
        nom: nom,
        email: email,
        role: role,
        googleId: googleId,
        photoUrl: photoUrl,
      );
      await _sauvegarderSession(_utilisateurConnecte!);
      _erreur = null;
      return true;
    } catch (e) {
      _erreur = _messagePropre(e);
      return false;
    } finally {
      _terminerChargement();
    }
  }

  // ── Déconnexion ──────────────────────────────────────────────────────────
  Future<void> deconnecter() async {
    await GoogleAuthService().deconnecter();
    await DbService.instance.reinitialiser();
    await _effacerSession();
    _utilisateurConnecte = null;
    _erreur = null;
    notifyListeners();
  }

  // ── Helpers privés ───────────────────────────────────────────────────────
  void _demarrerChargement() {
    _chargement = true;
    _erreur = null;
    notifyListeners();
  }

  void _terminerChargement() {
    _chargement = false;
    notifyListeners();
  }

  /// Transforme les exceptions techniques en messages compréhensibles.
  String _messagePropre(Object e) {
    final message = e
        .toString()
        .replaceFirst('AuthException: ', '')
        .replaceFirst('Exception: ', '');

    // Erreurs réseau / connexion base de données
    if (message.contains('Connection refused') ||
        message.contains('SocketException') ||
        message.contains('Failed host lookup') ||
        message.contains('timed out')) {
      return 'Impossible de joindre la base de données.\n'
          'Ouvrez « Configurer la base de données » et vérifiez '
          'l\'adresse IP (10.0.2.2 sur émulateur, IP du PC sur téléphone).';
    }

    if (kDebugMode) {
      debugPrint('[AuthProvider] Erreur : $message');
    }

    return message;
  }
}
