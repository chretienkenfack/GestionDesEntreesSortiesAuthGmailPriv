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
      'id, nom, email, password_hash, role, auth_provider, google_id, photo_url, actif';

  String _hash(String motDePasse) {
    return sha256.convert(utf8.encode(motDePasse)).toString();
  }

  /// Authentifie un utilisateur par e-mail et mot de passe (compte local).
  Future<AppUser> login(String email, String motDePasse) async {
    final conn = await DbService.instance.getConnection();
    final resultats = await conn.query(
      'SELECT $_colonnes FROM users WHERE email = ? LIMIT 1',
      [email.trim()],
    );

    if (resultats.isEmpty) {
      throw AuthException('Adresse e-mail ou mot de passe incorrect.');
    }

    final ligne = resultats.first.fields;

    if (ligne['auth_provider'] == 'google' && ligne['password_hash'] == null) {
      throw AuthException(
        'Ce compte a été créé avec Google. Utilisez le bouton "Se connecter avec Google".',
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
  /// peut ensuite promouvoir un compte en 'admin' (via la base ou un
  /// futur écran de gestion des utilisateurs).
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

  /// Connecte l'utilisateur avec un compte Google. Si aucun compte
  /// n'existe encore pour cet e-mail, un nouveau compte 'agent' est
  /// créé automatiquement (inscription et connexion en une seule action).
  Future<AppUser> connecterOuInscrireAvecGoogle({
    required String email,
    required String nom,
    required String googleId,
    String? photoUrl,
  }) async {
    final conn = await DbService.instance.getConnection();

    final resultats = await conn.query(
      'SELECT $_colonnes FROM users WHERE email = ? LIMIT 1',
      [email.trim()],
    );

    if (resultats.isNotEmpty) {
      final ligne = Map<String, dynamic>.from(resultats.first.fields);

      // Compte existant dans MySQL local : enregistrement des métadonnées Google et bascule du provider en local
      await conn.query(
        'UPDATE users SET google_id = ?, photo_url = ?, auth_provider = "google" WHERE id = ?',
        [googleId, photoUrl, ligne['id']],
      );

      ligne['google_id'] = googleId;
      ligne['photo_url'] = photoUrl;
      ligne['auth_provider'] = 'google';

      return AppUser.fromRow(ligne);
    }

    // Aucun compte trouvé dans la base MySQL locale : création automatique du compte dans MySQL local
    final result = await conn.query(
      '''
      INSERT INTO users (nom, email, password_hash, role, auth_provider, google_id, photo_url)
      VALUES (?, ?, NULL, 'agent', 'google', ?, ?)
      ''',
      [nom.trim(), email.trim(), googleId, photoUrl],
    );

    final id = result.insertId!;
    final nouveau = await conn.query('SELECT $_colonnes FROM users WHERE id = ?', [id]);
    return AppUser.fromRow(nouveau.first.fields);
  }

  Future<void> changerMotDePasse(int userId, String nouveauMotDePasse) async {
    final conn = await DbService.instance.getConnection();
    await conn.query(
      "UPDATE users SET password_hash = ?, auth_provider = 'local' WHERE id = ?",
      [_hash(nouveauMotDePasse), userId],
    );
  }

  /// Réservé aux administrateurs : création directe d'un compte
  /// (par ex. pour créer un autre administrateur).
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
}