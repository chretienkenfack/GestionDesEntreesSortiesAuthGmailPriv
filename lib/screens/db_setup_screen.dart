import 'package:flutter/material.dart';
import '../widgets/db_connection_form.dart';

/// Configuration de la base de données accessible avant la connexion.
/// Chaque appareil (émulateur, téléphone) peut enregistrer sa propre adresse IP.
class DbSetupScreen extends StatelessWidget {
  const DbSetupScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Connexion à la base de données')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text(
            'Configuration par appareil',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          const Text(
            "Ces paramètres sont enregistrés sur cet appareil uniquement. "
            "Configurez l'adresse IP adaptée à chaque téléphone ou émulateur.",
            style: TextStyle(color: Colors.black54, fontSize: 12),
          ),
          const SizedBox(height: 16),
          const Card(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: DbConnectionForm(),
            ),
          ),
        ],
      ),
    );
  }
}
