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
  static const List<String> _colonnesList = [
    'id',
    'nom',
    'email',
    'role',
    'auth_provider',
    'photo_url',
    'actif',
  ];

  String _hash(String motDePasse) {
    return sha256.convert(utf8.encode(motDePasse)).toString();
  }

  /// Authentifie un utilisateur par e-mail et mot de passe (compte local).
  Future<AppUser> login(String email, String motDePasse) async {
    final conn = await DbService.instance.getConnection();
    final query = conn.queryBuilder
        .select([..._colonnesList, 'password_hash'])
        .from('users')
        .whereRaw('email = ?', [email.trim()])
        .limit(1)
        .build();

    final resultats = await conn.query(query.sql, query.params);

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
  Future<AppUser> inscrire({
    required String nom,
    required String email,
    required String motDePasse,
  }) async {
    final conn = await DbService.instance.getConnection();

    final checkQuery = conn.queryBuilder
        .select(['id'])
        .from('users')
        .whereRaw('email = ?', [email.trim()])
        .limit(1)
        .build();

    final existant = await conn.query(checkQuery.sql, checkQuery.params);
    if (existant.isNotEmpty) {
      throw AuthException('Un compte existe déjà avec cette adresse e-mail.');
    }

    final insertQuery = conn.queryBuilder.insertInto('users', {
      'nom': nom.trim(),
      'email': email.trim(),
      'password_hash': _hash(motDePasse),
      'role': 'agent',
      'auth_provider': 'local',
    });

    final result = await conn.query(insertQuery.sql, insertQuery.params);

    final id = result.insertId!;
    final selectQuery = conn.queryBuilder
        .select(_colonnesList)
        .from('users')
        .whereRaw('id = ?', [id])
        .build();

    final resultats = await conn.query(selectQuery.sql, selectQuery.params);
    return AppUser.fromRow(resultats.first.fields);
  }

  Future<void> changerMotDePasse(int userId, String nouveauMotDePasse) async {
    final conn = await DbService.instance.getConnection();
    final updateQuery = conn.queryBuilder.update(
      'users',
      {
        'password_hash': _hash(nouveauMotDePasse),
        'auth_provider': 'local',
      },
      where: 'id = ?',
      whereParams: [userId],
    );

    await conn.query(updateQuery.sql, updateQuery.params);
  }

  /// Réservé aux administrateurs : création directe d'un compte.
  Future<void> creerUtilisateur({
    required String nom,
    required String email,
    required String motDePasse,
    required String role,
  }) async {
    final conn = await DbService.instance.getConnection();
    final insertQuery = conn.queryBuilder.insertInto('users', {
      'nom': nom,
      'email': email.trim(),
      'password_hash': _hash(motDePasse),
      'role': role,
      'auth_provider': 'local',
    });

    await conn.query(insertQuery.sql, insertQuery.params);
  }

  /// 1. Callback OAuth pour vérifier si l'utilisateur existe
  Future<AppUser?> checkGoogleUser(String email) async {
    final conn = await DbService.instance.getConnection();
    final query = conn.queryBuilder
        .select(_colonnesList)
        .from('users')
        .whereRaw('email = ?', [email.trim()])
        .limit(1)
        .build();

    final resultats = await conn.query(query.sql, query.params);

    if (resultats.isEmpty) {
      return null;
    }

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

    final checkQuery = conn.queryBuilder
        .select(['id'])
        .from('users')
        .whereRaw('email = ?', [email.trim()])
        .limit(1)
        .build();

    final existant = await conn.query(checkQuery.sql, checkQuery.params);
    if (existant.isNotEmpty) {
      throw AuthException('Cet utilisateur existe déjà.');
    }

    final insertQuery = conn.queryBuilder.insertInto('users', {
      'nom': nom.trim(),
      'email': email.trim(),
      'role': role,
      'auth_provider': 'google',
      'google_id': googleId,
      'photo_url': photoUrl,
    });

    final result = await conn.query(insertQuery.sql, insertQuery.params);

    final id = result.insertId!;
    final selectQuery = conn.queryBuilder
        .select(_colonnesList)
        .from('users')
        .whereRaw('id = ?', [id])
        .build();

    final resultats = await conn.query(selectQuery.sql, selectQuery.params);
    return AppUser.fromRow(resultats.first.fields);
  }
}