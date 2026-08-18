import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../theme/app_theme.dart';
import '../utils/constants.dart';
import '../utils/validators.dart';
import '../widgets/google_sign_in_button.dart';
import 'db_setup_screen.dart';
import 'register_screen.dart';
// TypeErreurGoogle est défini dans auth_provider.dart

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

  Future<void> _seConnecterAvecGoogle() async {
    final auth = context.read<AuthProvider>();
    final succes = await auth.connecterAvecGoogle();

    if (!mounted) return;

    // Annulation volontaire → rien à afficher
    if (!succes && auth.erreur == null) return;

    if (!succes && auth.erreur != null) {
      // Erreur SHA-1 : dialog explicatif avec les étapes
      if (auth.typeErreurGoogle == TypeErreurGoogle.sha1) {
        _afficherDialogConfigGoogle();
        return;
      }

      // Autres erreurs : SnackBar informatif
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.error_outline, color: Colors.white, size: 18),
              const SizedBox(width: 10),
              Expanded(child: Text(auth.erreur!)),
            ],
          ),
          backgroundColor: AppTheme.couleurSortie,
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.all(16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      );
    }
  }

  void _afficherDialogConfigGoogle() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: Colors.orange.shade50,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Icon(Icons.settings_outlined,
                  color: Colors.orange.shade700, size: 20),
            ),
            const SizedBox(width: 10),
            const Text('Configuration requise',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'La connexion Google nécessite une configuration Firebase '
              'pour cette application. Voici les étapes :',
              style: TextStyle(fontSize: 13, color: Colors.black87),
            ),
            const SizedBox(height: 12),
            _EtapeConfig(
              numero: '1',
              texte: 'Ouvrir un terminal dans le dossier du projet',
              code: 'cd android',
            ),
            _EtapeConfig(
              numero: '2',
              texte: 'Obtenir l\'empreinte SHA-1',
              code: 'gradlew signingReport',
            ),
            _EtapeConfig(
              numero: '3',
              texte:
                  'Ajouter le SHA-1 dans Firebase Console → Paramètres du projet → Empreintes SHA',
            ),
            _EtapeConfig(
              numero: '4',
              texte:
                  'Télécharger le nouveau google-services.json et le placer dans android/app/',
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Compris'),
          ),
        ],
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  void _allerVersInscription() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const RegisterScreen()),
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
    final googleEnCours = auth.chargementGoogle;

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
                            const SizedBox(height: 8),
                            TextButton(
                              onPressed: auth.chargement ? null : _allerVersInscription,
                              child: const Text("Pas encore de compte ? S'inscrire"),
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                Expanded(child: Divider(color: Colors.grey.shade300)),
                                const Padding(
                                  padding: EdgeInsets.symmetric(horizontal: 10),
                                  child: Text('OU',
                                      style: TextStyle(
                                          color: Colors.black45, fontSize: 12)),
                                ),
                                Expanded(child: Divider(color: Colors.grey.shade300)),
                              ],
                            ),
                            const SizedBox(height: 12),
                            GoogleSignInButton(
                              onPressed: (auth.chargement || googleEnCours)
                                  ? null
                                  : _seConnecterAvecGoogle,
                              chargement: googleEnCours,
                              texte: "Se connecter avec Google",
                            ),
                            const SizedBox(height: 12),
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

/// Ligne d'une étape de configuration dans le dialog Firebase
class _EtapeConfig extends StatelessWidget {
  final String numero;
  final String texte;
  final String? code;

  const _EtapeConfig({
    required this.numero,
    required this.texte,
    this.code,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 20,
            height: 20,
            decoration: BoxDecoration(
              color: AppTheme.couleurAccent,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                numero,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(texte,
                    style: const TextStyle(fontSize: 12, color: Colors.black87)),
                if (code != null) ...
                  [
                    const SizedBox(height: 3),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF0F2F8),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        code!,
                        style: const TextStyle(
                          fontFamily: 'monospace',
                          fontSize: 11,
                          color: Color(0xFF1A237E),
                        ),
                      ),
                    ),
                  ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
