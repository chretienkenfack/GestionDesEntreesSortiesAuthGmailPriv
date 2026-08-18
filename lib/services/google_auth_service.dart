import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../models/user.dart';
import 'auth_service.dart';

/// Résultat d'une tentative de connexion Google.
enum ResultatGoogle {
  succes,
  annulation,
  erreurReseau,
  erreurSha1,  // ApiException: 10 — SHA-1 non configuré dans Firebase
  erreurInconnue,
}

/// Encapsule la bibliothèque `google_sign_in` et relie le compte Google
/// obtenu à un compte applicatif (table `users`) via [AuthService].
///
/// ─── Prérequis Android (à faire une fois) ────────────────────────────────
///  1. Firebase Console → projet → Auth → activer Google
///  2. `cd android && gradlew signingReport` → copier le SHA-1
///  3. Firebase Console → Paramètres du projet → Empreintes SHA → Ajouter
///  4. Télécharger le nouveau google-services.json → android/app/
/// ─────────────────────────────────────────────────────────────────────────
class GoogleAuthService {
  final AuthService _authService = AuthService();

  /// `google_sign_in` lit automatiquement le client_id dans
  /// google-services.json — pas besoin de le hardcoder ici.
  final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: ['email', 'profile'],
  );

  /// Ouvre la fenêtre Google, puis crée ou relie le compte applicatif.
  ///
  /// Retourne `(utilisateur: null, resultat: ResultatGoogle.annulation)`
  /// si l'utilisateur ferme la fenêtre sans choisir de compte.
  Future<({AppUser? utilisateur, ResultatGoogle resultat, String? messageErreur})>
      connecter() async {
    try {
      // 1. Tentative silencieuse (session déjà active → instantané)
      GoogleSignInAccount? compteGoogle;
      try {
        compteGoogle = await _googleSignIn.signInSilently();
      } catch (_) {
        // Pas de session silencieuse → on passe à l'UI normale
      }

      // 2. Ouverture de la fenêtre de sélection de compte
      compteGoogle ??= await _googleSignIn.signIn();

      // 3. L'utilisateur a annulé (croix, bouton retour…)
      if (compteGoogle == null) {
        return (
          utilisateur: null,
          resultat: ResultatGoogle.annulation,
          messageErreur: null,
        );
      }

      // 4. Liaison au compte applicatif (création si nouveau)
      final utilisateur = await _authService.connecterOuInscrireAvecGoogle(
        email: compteGoogle.email,
        nom: compteGoogle.displayName ?? compteGoogle.email.split('@').first,
        googleId: compteGoogle.id,
        photoUrl: compteGoogle.photoUrl,
      );

      return (
        utilisateur: utilisateur,
        resultat: ResultatGoogle.succes,
        messageErreur: null,
      );
    } on Exception catch (e) {
      return _analyserErreur(e);
    }
  }

  /// Déconnecte le compte Google localement.
  Future<void> deconnecter() async {
    try {
      await _googleSignIn.signOut();
    } catch (_) {}
  }

  // ── Analyse d'erreur ─────────────────────────────────────────────────────

  ({AppUser? utilisateur, ResultatGoogle resultat, String? messageErreur})
      _analyserErreur(Exception e) {
    final msg = e.toString();

    if (kDebugMode) {
      debugPrint('[GoogleAuthService] Exception : $msg');
    }

    // Annulation via le code d'exception
    if (msg.contains('sign_in_canceled') ||
        msg.contains('ApiException: 12501') ||
        msg.contains('canceled')) {
      return (
        utilisateur: null,
        resultat: ResultatGoogle.annulation,
        messageErreur: null,
      );
    }

    // SHA-1 non configuré (ApiException: 10)
    if (msg.contains('ApiException: 10') ||
        msg.contains('sign_in_failed') ||
        msg.contains('DEVELOPER_ERROR')) {
      return (
        utilisateur: null,
        resultat: ResultatGoogle.erreurSha1,
        messageErreur:
            'La connexion Google n\'est pas encore configurée.\n'
            'L\'empreinte SHA-1 de l\'application doit être ajoutée '
            'dans la console Firebase.',
      );
    }

    // Erreur réseau
    if (msg.contains('network_error') ||
        msg.contains('NetworkException') ||
        msg.contains('SocketException') ||
        msg.contains('Failed host lookup')) {
      return (
        utilisateur: null,
        resultat: ResultatGoogle.erreurReseau,
        messageErreur:
            'Connexion Google impossible : vérifiez votre connexion internet.',
      );
    }

    // Autres erreurs
    return (
      utilisateur: null,
      resultat: ResultatGoogle.erreurInconnue,
      messageErreur: msg
          .replaceFirst('Exception: ', '')
          .replaceFirst('PlatformException(', '')
          .split(',')
          .first,
    );
  }
}
