import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../services/google_auth_service.dart';
import '../theme/app_theme.dart';
import '../utils/constants.dart';
import '../utils/validators.dart';
import 'db_setup_screen.dart';
import 'register_screen.dart';
import 'role_selection_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _motDePasseCtrl = TextEditingController();
  bool _motDePasseVisible = false;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _motDePasseCtrl.dispose();
    super.dispose();
  }

  Future<void> _seConnecter() async {
    if (!_formKey.currentState!.validate()) return;
    final auth = context.read<AuthProvider>();
    final succes = await auth.connecter(_emailCtrl.text, _motDePasseCtrl.text);
    if (!succes && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(auth.erreur ?? 'Échec de la connexion.'),
          backgroundColor: AppTheme.couleurSortie,
        ),
      );
    }
  }

  void _allerVersInscription() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const RegisterScreen()),
    );
  }

  Future<void> _seConnecterGoogle() async {
    final auth = context.read<AuthProvider>();
    final googleAuth = GoogleAuthService();

    final resultat = await googleAuth.obtenirCompte();
    if (!mounted) return;

    if (resultat.resultat != ResultatGoogle.succes || resultat.compte == null) {
      if (resultat.messageErreur != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(resultat.messageErreur!),
            backgroundColor: AppTheme.couleurSortie,
          ),
        );
      }
      return;
    }

    final compte = resultat.compte!;
    final userTrouve = await auth.verifierUtilisateurGoogle(compte.email);
    if (!mounted) return;

    if (userTrouve != null) {
      return;
    }

    if (auth.erreur != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(auth.erreur!),
          backgroundColor: AppTheme.couleurSortie,
        ),
      );
      return;
    }

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => RoleSelectionScreen(
          email: compte.email,
          nom: compte.nom,
          googleId: compte.googleId,
          photoUrl: compte.photoUrl,
        ),
      ),
    );
  }

  void _ouvrirConfigurationDb() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const DbSetupScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: AppTheme.degradePrimaire),
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Column(
                children: [
                  // ── Logo / en-tête ────────────────────────────────────
                  const _EnteteLogo(),
                  const SizedBox(height: 28),

                  // ── Carte formulaire ──────────────────────────────────
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(28),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Text(
                              'Connexion',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.couleurPrimaire,
                              ),
                            ),
                            const SizedBox(height: 4),
                            const Text(
                              'Accédez à votre espace de gestion',
                              textAlign: TextAlign.center,
                              style: TextStyle(color: Colors.black54, fontSize: 13),
                            ),
                            const SizedBox(height: 24),
                            TextFormField(
                              controller: _emailCtrl,
                              decoration: const InputDecoration(
                                labelText: 'Adresse e-mail',
                                prefixIcon: Icon(Icons.email_outlined),
                              ),
                              keyboardType: TextInputType.emailAddress,
                              validator: Validators.email,
                            ),
                            const SizedBox(height: 16),
                            TextFormField(
                              controller: _motDePasseCtrl,
                              decoration: InputDecoration(
                                labelText: 'Mot de passe',
                                prefixIcon: const Icon(Icons.lock_outline),
                                suffixIcon: IconButton(
                                  icon: Icon(_motDePasseVisible
                                      ? Icons.visibility_off_outlined
                                      : Icons.visibility_outlined),
                                  onPressed: () => setState(
                                      () => _motDePasseVisible = !_motDePasseVisible),
                                ),
                              ),
                              obscureText: !_motDePasseVisible,
                              validator: (v) =>
                                  Validators.champObligatoire(v, champ: 'Le mot de passe'),
                              onFieldSubmitted: (_) => _seConnecter(),
                            ),
                            const SizedBox(height: 20),
                            SizedBox(
                              height: 48,
                              child: ElevatedButton(
                                onPressed: auth.chargement ? null : _seConnecter,
                                child: auth.chargement
                                    ? const SizedBox(
                                        height: 20,
                                        width: 20,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          valueColor:
                                              AlwaysStoppedAnimation(Colors.white),
                                        ),
                                      )
                                    : const Text(
                                        'Se connecter',
                                        style: TextStyle(
                                            fontSize: 15,
                                            fontWeight: FontWeight.w600),
                                      ),
                              ),
                            ),
                            const SizedBox(height: 16),
                            
                            // ── SÉPARATEUR "OU" ──
                            const Row(
                              children: [
                                Expanded(child: Divider(thickness: 1)),
                                Padding(
                                  padding: EdgeInsets.symmetric(horizontal: 10),
                                  child: Text('OU', style: TextStyle(color: Colors.black45)),
                                ),
                                Expanded(child: Divider(thickness: 1)),
                              ],
                            ),
                            const SizedBox(height: 16),
                            
                            // ── BOUTON GOOGLE ──
                            SizedBox(
                              height: 48,
                              child: OutlinedButton.icon(
                                onPressed: auth.chargement ? null : _seConnecterGoogle,
                                icon: Padding(
                                  padding: const EdgeInsets.only(right: 8.0),
                                  // Remplacement de l'icône G par un widget Icon basique 
                                  // jusqu'à ce que des assets Google soient ajoutés.
                                  child: Icon(Icons.g_mobiledata, size: 30, color: AppTheme.couleurPrimaire),
                                ),
                                label: const Text(
                                  'Continuer avec Google',
                                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: Colors.blueGrey),
                                ),
                                style: OutlinedButton.styleFrom(
                                  side: const BorderSide(color: Colors.blueGrey),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),
                            TextButton(
                              onPressed: auth.chargement ? null : _allerVersInscription,
                              child: const Text("Pas encore de compte ? S'inscrire"),
                            ),
                            const SizedBox(height: 4),
                            TextButton.icon(
                              onPressed: _ouvrirConfigurationDb,
                              icon: const Icon(Icons.storage_outlined, size: 16),
                              label: const Text('Configurer la base de données'),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// En-tête avec icône et nom de l'application
class _EnteteLogo extends StatelessWidget {
  const _EnteteLogo();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 72,
          height: 72,
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.15),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: Colors.white38, width: 1.5),
          ),
          child: const Icon(Icons.account_balance_wallet_outlined,
              size: 40, color: Colors.white),
        ),
        const SizedBox(height: 12),
        const Text(
          AppConstants.nomApplication,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Engineerys IT Training Center',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: Colors.white.withOpacity(0.75),
            fontSize: 12,
            letterSpacing: 1.2,
          ),
        ),
      ],
    );
  }
}
