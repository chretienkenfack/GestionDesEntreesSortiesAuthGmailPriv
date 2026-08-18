import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../theme/app_theme.dart';
import '../utils/validators.dart';
import 'db_setup_screen.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nomCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _motDePasseCtrl = TextEditingController();
  final _confirmationCtrl = TextEditingController();
  bool _motDePasseVisible = false;

  @override
  void dispose() {
    _nomCtrl.dispose();
    _emailCtrl.dispose();
    _motDePasseCtrl.dispose();
    _confirmationCtrl.dispose();
    super.dispose();
  }

  Future<void> _sInscrire() async {
    if (!_formKey.currentState!.validate()) return;
    final auth = context.read<AuthProvider>();
    final succes = await auth.inscrire(
      _nomCtrl.text.trim(),
      _emailCtrl.text.trim(),
      _motDePasseCtrl.text,
    );
    if (!succes && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(auth.erreur ?? "Échec de l'inscription."),
          backgroundColor: AppTheme.couleurSortie,
        ),
      );
    }
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
                  // ── En-tête ───────────────────────────────────────────────
                  Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.white38, width: 1.5),
                    ),
                    child: const Icon(Icons.person_add_alt_1_outlined,
                        size: 36, color: Colors.white),
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    'Créer un compte',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Rejoignez Engineerys IT Training Center',
                    style: TextStyle(
                        color: Colors.white.withOpacity(0.75), fontSize: 12),
                  ),
                  const SizedBox(height: 24),

                  // ── Carte formulaire ──────────────────────────────────────
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
                              'Inscription',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.couleurPrimaire,
                              ),
                            ),
                            const SizedBox(height: 20),
                            TextFormField(
                              controller: _nomCtrl,
                              decoration: const InputDecoration(
                                labelText: 'Nom complet',
                                prefixIcon: Icon(Icons.person_outline),
                              ),
                              validator: (v) =>
                                  Validators.champObligatoire(v, champ: 'Le nom'),
                            ),
                            const SizedBox(height: 16),
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
                              validator: (v) {
                                if (v == null || v.isEmpty)
                                  return 'Le mot de passe est obligatoire.';
                                if (v.length < 6) return 'Au moins 6 caractères.';
                                return null;
                              },
                            ),
                            const SizedBox(height: 16),
                            TextFormField(
                              controller: _confirmationCtrl,
                              decoration: const InputDecoration(
                                labelText: 'Confirmer le mot de passe',
                                prefixIcon: Icon(Icons.lock_outline),
                              ),
                              obscureText: !_motDePasseVisible,
                              validator: (v) {
                                if (v != _motDePasseCtrl.text)
                                  return 'Les mots de passe ne correspondent pas.';
                                return null;
                              },
                            ),
                            const SizedBox(height: 24),
                            SizedBox(
                              height: 48,
                              child: ElevatedButton(
                                onPressed: auth.chargement ? null : _sInscrire,
                                child: auth.chargement
                                    ? const SizedBox(
                                        height: 20,
                                        width: 20,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          valueColor: AlwaysStoppedAnimation(
                                              Colors.white),
                                        ),
                                      )
                                    : const Text("S'inscrire",
                                        style: TextStyle(
                                            fontSize: 15,
                                            fontWeight: FontWeight.w600)),
                              ),
                            ),
                            const SizedBox(height: 12),
                            TextButton(
                              onPressed: () => Navigator.of(context).pop(),
                              child: const Text("J'ai déjà un compte — Se connecter"),
                            ),
                            TextButton.icon(
                              onPressed: () => Navigator.of(context).push(
                                MaterialPageRoute(
                                    builder: (_) => const DbSetupScreen()),
                              ),
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
