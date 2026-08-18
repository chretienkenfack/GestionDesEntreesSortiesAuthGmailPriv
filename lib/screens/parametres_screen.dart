import 'package:flutter/material.dart';
import '../services/settings_service.dart';
import '../widgets/app_drawer.dart';
import '../widgets/db_connection_form.dart';

class ParametresScreen extends StatefulWidget {
  const ParametresScreen({super.key});

  @override
  State<ParametresScreen> createState() => _ParametresScreenState();
}

class _ParametresScreenState extends State<ParametresScreen> {
  final SettingsService _settingsService = SettingsService();

  final _nomEntrepriseCtrl = TextEditingController();
  final _deviseCtrl = TextEditingController();

  bool _chargement = true;

  @override
  void initState() {
    super.initState();
    _chargerParametres();
  }

  @override
  void dispose() {
    _nomEntrepriseCtrl.dispose();
    _deviseCtrl.dispose();
    super.dispose();
  }

  Future<void> _chargerParametres() async {
    final nomEntreprise = await _settingsService.getNomEntreprise();
    final devise = await _settingsService.getDevise();

    _nomEntrepriseCtrl.text = nomEntreprise;
    _deviseCtrl.text = devise;

    setState(() => _chargement = false);
  }

  Future<void> _enregistrerParametresGeneraux() async {
    await _settingsService.saveNomEntreprise(_nomEntrepriseCtrl.text.trim());
    await _settingsService.saveDevise(_deviseCtrl.text.trim());
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Paramètres généraux enregistrés.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        Navigator.of(context).pushReplacementNamed('/dashboard');
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Paramètres'),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            tooltip: 'Retour au tableau de bord',
            onPressed: () => Navigator.of(context).pushReplacementNamed('/dashboard'),
          ),
        ),
        drawer: const AppDrawer(routeActive: '/parametres'),
        body: _chargement
            ? const Center(child: CircularProgressIndicator())
            : ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  _sectionTitre(
                    'Connexion à la base de données',
                    "Modifiez l'adresse IP pour connecter l'application à une "
                        "autre base de données (par exemple un autre site ou "
                        "environnement de l'entreprise).",
                  ),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: DbConnectionForm(),
                    ),
                  ),
                  const SizedBox(height: 28),
                  _sectionTitre(
                    "Paramètres généraux",
                    "Informations affichées sur les rapports PDF générés.",
                  ),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          TextFormField(
                            controller: _nomEntrepriseCtrl,
                            decoration: const InputDecoration(
                              labelText: "Nom de l'entreprise",
                              prefixIcon: Icon(Icons.apartment_outlined),
                            ),
                          ),
                          const SizedBox(height: 12),
                          TextFormField(
                            controller: _deviseCtrl,
                            decoration: const InputDecoration(
                              labelText: 'Devise (ex : FCFA, EUR, USD)',
                              prefixIcon: Icon(Icons.attach_money),
                            ),
                          ),
                          const SizedBox(height: 16),
                          ElevatedButton.icon(
                            onPressed: _enregistrerParametresGeneraux,
                            icon: const Icon(Icons.save_outlined),
                            label: const Text('Enregistrer'),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _sectionTitre(String titre, String description) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(titre, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text(description, style: const TextStyle(color: Colors.black54, fontSize: 12)),
        ],
      ),
    );
  }
}
