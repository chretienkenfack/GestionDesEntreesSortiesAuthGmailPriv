import 'dart:convert';
import 'package:crypto/crypto.dart';
import '../models/user.dart';
import 'db_service.dart';

class AuthException implements Exception {
  final String message;
  AuthException(this.message);
  @override
  String toString() => message;
}

class AuthService {
  static const String _colonnes =
      'id, nom, email, role, auth_provider, photo_url, actif';

  String _hash(String motDePasse) {
    return sha256.convert(utf8.encode(motDePasse)).toString();
  }

  /// Authentifie un utilisateur par e-mail et mot de passe (compte local).
  Future<AppUser> login(String email, String motDePasse) async {
    final conn = await DbService.instance.getConnection();
    final resultats = await conn.query(
      'SELECT $_colonnes, password_hash FROM users WHERE email = ? LIMIT 1',
      [email.trim()],
    );

    if (resultats.isEmpty) {
      throw AuthException('Adresse e-mail ou mot de passe incorrect.');
    }

    final ligne = resultats.first.fields;

    if (ligne['auth_provider'] == 'google' && ligne['password_hash'] == null) {
      throw AuthException(
        'Ce compte utilise Google. Cliquez sur « Continuer avec Google ».',
      );
    }

    final hashSaisi = _hash(motDePasse);
    if (hashSaisi != ligne['password_hash']) {
      throw AuthException('Adresse e-mail ou mot de passe incorrect.');
    }

    return AppUser.fromRow(ligne);
  }

  /// Inscription libre : un nouvel utilisateur crée lui-même son compte.
  /// Le rôle est toujours 'agent' par défaut ; seul un administrateur
  /// peut ensuite promouvoir un compte en 'admin'.
  Future<AppUser> inscrire({
    required String nom,
    required String email,
    required String motDePasse,
  }) async {
    final conn = await DbService.instance.getConnection();

    final existant = await conn.query(
      'SELECT id FROM users WHERE email = ? LIMIT 1',
      [email.trim()],
    );
    if (existant.isNotEmpty) {
      throw AuthException('Un compte existe déjà avec cette adresse e-mail.');
    }

    final result = await conn.query(
      '''
      INSERT INTO users (nom, email, password_hash, role, auth_provider)
      VALUES (?, ?, ?, 'agent', 'local')
      ''',
      [nom.trim(), email.trim(), _hash(motDePasse)],
    );

    final id = result.insertId!;
    final resultats = await conn.query(
      'SELECT $_colonnes FROM users WHERE id = ?',
      [id],
    );
    return AppUser.fromRow(resultats.first.fields);
  }

  Future<void> changerMotDePasse(int userId, String nouveauMotDePasse) async {
    final conn = await DbService.instance.getConnection();
    await conn.query(
      "UPDATE users SET password_hash = ?, auth_provider = 'local' WHERE id = ?",
      [_hash(nouveauMotDePasse), userId],
    );
  }

  /// Réservé aux administrateurs : création directe d'un compte.
  Future<void> creerUtilisateur({
    required String nom,
    required String email,
    required String motDePasse,
    required String role,
  }) async {
    final conn = await DbService.instance.getConnection();
    await conn.query(
      "INSERT INTO users (nom, email, password_hash, role, auth_provider) VALUES (?, ?, ?, ?, 'local')",
      [nom, email.trim(), _hash(motDePasse), role],
    );
  }

  /// 1. Callback OAuth pour vérifier si l'utilisateur existe
  /// Retourne un AppUser s'il existe (Connexion),
  /// ou `null` s'il n'existe pas (le front devra rediriger vers le choix du rôle).
  Future<AppUser?> checkGoogleUser(String email) async {
    final conn = await DbService.instance.getConnection();
    final resultats = await conn.query(
      'SELECT $_colonnes FROM users WHERE email = ? LIMIT 1',
      [email.trim()],
    );

    if (resultats.isEmpty) {
      // L'utilisateur n'existe pas, on retourne null.
      return null;
    }

    // L'utilisateur existe déjà, on le connecte
    return AppUser.fromRow(resultats.first.fields);
  }

  /// 2. Finaliser l'inscription post-Google avec le rôle choisi
  Future<AppUser> registerGoogleUserWithRole({
    required String nom,
    required String email,
    required String role,
    String? googleId,
    String? photoUrl,
  }) async {
    final conn = await DbService.instance.getConnection();

    // Au cas où une double tentative est faite (sécurité)
    final existant = await conn.query(
      'SELECT id FROM users WHERE email = ? LIMIT 1',
      [email.trim()],
    );

    if (existant.isNotEmpty) {
      throw AuthException('Cet utilisateur existe déjà.');
    }

    final result = await conn.query(
      '''
      INSERT INTO users (nom, email, role, auth_provider, google_id, photo_url)
      VALUES (?, ?, ?, 'google', ?, ?)
      ''',
      [nom.trim(), email.trim(), role, googleId, photoUrl],
    );

    final id = result.insertId!;
    final resultats = await conn.query(
      'SELECT $_colonnes FROM users WHERE id = ?',
      [id],
    );

    return AppUser.fromRow(resultats.first.fields);
  }
}