import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../utils/constants.dart';

/// Résultat d'une tentative d'ouverture du sélecteur Google.
enum ResultatGoogle {
  succes,
  annulation,
  erreurReseau,
  erreurSha1,
  erreurInconnue,
}

/// Données renvoyées par Google après authentification OAuth.
class CompteGoogle {
  final String email;
  final String nom;
  final String googleId;
  final String? photoUrl;

  const CompteGoogle({
    required this.email,
    required this.nom,
    required this.googleId,
    this.photoUrl,
  });
}

/// Ouvre le sélecteur Google. Les comptes sont ensuite vérifiés/créés
/// dans MySQL local via [AuthService] — pas dans Firebase.
///
/// Prérequis Android (une seule fois) :
/// 1. Firebase Console → Paramètres → Empreintes SHA → ajouter le SHA-1 debug
///    (`cd android && gradlew signingReport`)
/// 2. Télécharger le nouveau google-services.json (oauth_client ne doit pas être vide)
/// 3. Placer le fichier dans android/app/
class GoogleAuthService {
  final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: ['email', 'profile'],
    serverClientId: AppConstants.googleWebClientId,
  );

  Future<({CompteGoogle? compte, ResultatGoogle resultat, String? messageErreur})>
      obtenirCompte() async {
    try {
      GoogleSignInAccount? compteGoogle;
      try {
        compteGoogle = await _googleSignIn.signInSilently();
      } catch (_) {}

      compteGoogle ??= await _googleSignIn.signIn();

      if (compteGoogle == null) {
        return (
          compte: null,
          resultat: ResultatGoogle.annulation,
          messageErreur: null,
        );
      }

      return (
        compte: CompteGoogle(
          email: compteGoogle.email,
          nom: compteGoogle.displayName ??
              compteGoogle.email.split('@').first,
          googleId: compteGoogle.id,
          photoUrl: compteGoogle.photoUrl,
        ),
        resultat: ResultatGoogle.succes,
        messageErreur: null,
      );
    } on Exception catch (e) {
      return _analyserErreur(e);
    }
  }

  Future<void> deconnecter() async {
    try {
      await _googleSignIn.signOut();
    } catch (_) {}
  }

  ({CompteGoogle? compte, ResultatGoogle resultat, String? messageErreur})
      _analyserErreur(Exception e) {
    final msg = e.toString();

    if (kDebugMode) {
      debugPrint('[GoogleAuthService] Exception : $msg');
    }

    if (msg.contains('sign_in_canceled') ||
        msg.contains('ApiException: 12501') ||
        msg.contains('canceled')) {
      return (
        compte: null,
        resultat: ResultatGoogle.annulation,
        messageErreur: null,
      );
    }

    if (msg.contains('ApiException: 10') ||
        msg.contains('sign_in_failed') ||
        msg.contains('DEVELOPER_ERROR')) {
      return (
        compte: null,
        resultat: ResultatGoogle.erreurSha1,
        messageErreur:
            'Google Sign-In non configuré.\n'
            'Ajoutez l\'empreinte SHA-1 de l\'app dans Firebase, '
            'puis retéléchargez google-services.json.',
      );
    }

    if (msg.contains('network_error') ||
        msg.contains('NetworkException') ||
        msg.contains('SocketException') ||
        msg.contains('Failed host lookup')) {
      return (
        compte: null,
        resultat: ResultatGoogle.erreurReseau,
        messageErreur:
            'Connexion Google impossible : vérifiez votre connexion internet.',
      );
    }

    return (
      compte: null,
      resultat: ResultatGoogle.erreurInconnue,
      messageErreur: msg
          .replaceFirst('Exception: ', '')
          .replaceFirst('PlatformException(', '')
          .split(',')
          .first,
    );
  }
}
