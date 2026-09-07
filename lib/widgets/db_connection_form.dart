import 'package:flutter/material.dart';
import '../models/db_settings.dart';
import '../services/connection_factory.dart';
import '../services/db_service.dart';
import '../services/settings_service.dart';
import '../utils/platform_db_host.dart';
import '../utils/validators.dart';

/// Formulaire de connexion réutilisable pour MySQL et PostgreSQL
/// (écran Paramètres ou configuration avant la première connexion).
class DbConnectionForm extends StatefulWidget {
  const DbConnectionForm({super.key});

  @override
  State<DbConnectionForm> createState() => _DbConnectionFormState();
}

class _DbConnectionFormState extends State<DbConnectionForm> {
  final _formKey = GlobalKey<FormState>();
  final SettingsService _settingsService = SettingsService();

  final _hostCtrl = TextEditingController();
  final _portCtrl = TextEditingController();
  final _dbCtrl = TextEditingController();
  final _userCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();

  String _sgbdType = 'mysql';
  bool _chargement = true;
  bool _testEnCours = false;
  bool _enregistrementEnCours = false;

  @override
  void initState() {
    super.initState();
    _chargerParametres();
  }

  @override
  void dispose() {
    _hostCtrl.dispose();
    _portCtrl.dispose();
    _dbCtrl.dispose();
    _userCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  Future<void> _chargerParametres() async {
    final db = await _settingsService.getDbSettings();
    _hostCtrl.text = db.host;
    _portCtrl.text = db.port.toString();
    _dbCtrl.text = db.database;
    _userCtrl.text = db.username;
    _passwordCtrl.text = db.password;
    _sgbdType = db.sgbdType;
    setState(() => _chargement = false);
  }

  DbSettings get _settingsSaisis => DbSettings(
        host: _hostCtrl.text.trim(),
        port: int.tryParse(_portCtrl.text.trim()) ?? 3306,
        database: _dbCtrl.text.trim(),
        username: _userCtrl.text.trim(),
        password: _passwordCtrl.text,
        sgbdType: _sgbdType,
      );

  void _onSgbdTypeChanged(String? value) {
    if (value != null) {
      setState(() {
        _sgbdType = value;
        _portCtrl.text = ConnectionFactory.getDefaultPort(value);
      });
    }
  }

  Future<void> _testerConnexion() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _testEnCours = true);
    final resultat = await DbService.instance.tester(_settingsSaisis);
    setState(() => _testEnCours = false);

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: resultat.succes ? Colors.green[700] : Colors.red[700],
        content: Text(
          resultat.succes
              ? 'Connexion réussie à la base de données.'
              : resultat.message ??
                  "Échec de la connexion. Vérifiez l'adresse IP, le port et les identifiants.",
        ),
      ),
    );
  }

  Future<void> _enregistrer() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _enregistrementEnCours = true);
    try {
      await _settingsService.saveDbSettings(_settingsSaisis);
      await DbService.instance.reinitialiser();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Paramètres de connexion enregistrés.')),
        );
      }
    } finally {
      if (mounted) setState(() => _enregistrementEnCours = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_chargement) {
      return const Center(child: CircularProgressIndicator());
    }

    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              PlatformDbHost.aideEmulateurAndroid,
              style: TextStyle(fontSize: 12, color: Colors.blue.shade900),
            ),
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<String>(
            value: _sgbdType,
            decoration: const InputDecoration(
              labelText: 'Type de SGBD',
              prefixIcon: Icon(Icons.storage_outlined),
            ),
            items: const [
              DropdownMenuItem(value: 'mysql', child: Text('MySQL')),
              DropdownMenuItem(value: 'postgres', child: Text('PostgreSQL')),
              DropdownMenuItem(value: 'sqlserver', child: Text('SQL Server (MS SQL)')),
            ],
            onChanged: _onSgbdTypeChanged,
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _hostCtrl,
            decoration: const InputDecoration(
              labelText: 'Adresse IP / hôte',
              hintText: 'ex : 10.0.2.2 (émulateur) ou 192.168.1.10',
              prefixIcon: Icon(Icons.dns_outlined),
            ),
            validator: Validators.adresseIp,
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _portCtrl,
            decoration: const InputDecoration(
              labelText: 'Port',
              hintText: 'ex : 3306',
              prefixIcon: Icon(Icons.settings_ethernet),
            ),
            keyboardType: TextInputType.number,
            validator: Validators.port,
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _dbCtrl,
            decoration: const InputDecoration(
              labelText: 'Nom de la base de données',
              prefixIcon: Icon(Icons.storage_outlined),
            ),
            validator: (v) => Validators.champObligatoire(v, champ: 'Le nom de la base'),
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _userCtrl,
            decoration: const InputDecoration(
              labelText: "Nom d'utilisateur BD",
              prefixIcon: Icon(Icons.person_outline),
            ),
            validator: (v) => Validators.champObligatoire(v, champ: "Le nom d'utilisateur"),
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _passwordCtrl,
            decoration: const InputDecoration(
              labelText: 'Mot de passe BD',
              prefixIcon: Icon(Icons.key_outlined),
            ),
            obscureText: true,
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _testEnCours ? null : _testerConnexion,
                  icon: _testEnCours
                      ? const SizedBox(
                          height: 16,
                          width: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.wifi_tethering),
                  label: const Text('Tester'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _enregistrementEnCours ? null : _enregistrer,
                  icon: const Icon(Icons.save_outlined),
                  label: const Text('Enregistrer'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
