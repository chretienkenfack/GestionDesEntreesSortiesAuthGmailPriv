import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show SystemNavigator;
import '../services/entree_service.dart';
import '../services/sortie_service.dart';
import '../services/settings_service.dart';
import '../utils/currency_formatter.dart';
import '../utils/constants.dart';
import '../theme/app_theme.dart';
import '../widgets/app_drawer.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final EntreeService _entreeService = EntreeService();
  final SortieService _sortieService = SortieService();
  final SettingsService _settingsService = SettingsService();

  late Future<_ResumeMois> _futureResume;

  @override
  void initState() {
    super.initState();
    _futureResume = _chargerResume();
  }

  Future<_ResumeMois> _chargerResume() async {
    final maintenant = DateTime.now();
    final devise = await _settingsService.getDevise();
    final totalEntrees = await _entreeService.totalParMois(maintenant.year, maintenant.month);
    final totalSorties = await _sortieService.totalParMois(maintenant.year, maintenant.month);
    return _ResumeMois(
      annee: maintenant.year,
      mois: maintenant.month,
      totalEntrees: totalEntrees,
      totalSorties: totalSorties,
      devise: devise,
    );
  }

  Future<void> _rafraichir() async {
    setState(() => _futureResume = _chargerResume());
  }

  Future<bool> _confirmerQuitter() async {
    final confirme = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Quitter l\'application'),
        content: const Text('Voulez-vous vraiment quitter l\'application ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Non'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Oui'),
          ),
        ],
      ),
    );
    return confirme ?? false;
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        final quitter = await _confirmerQuitter();
        if (quitter && context.mounted) {
          SystemNavigator.pop();
        }
      },
      child: Scaffold(
        appBar: AppBar(title: const Text('Tableau de bord')),
        drawer: const AppDrawer(routeActive: '/dashboard'),
        body: RefreshIndicator(
          onRefresh: _rafraichir,
          child: FutureBuilder<_ResumeMois>(
            future: _futureResume,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (snapshot.hasError) {
                return _erreurConnexion(snapshot.error.toString());
              }
              final resume = snapshot.data!;
              final solde = resume.totalEntrees - resume.totalSorties;

              return ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  Text(
                    'Résumé de ${moisFrancais[resume.mois - 1]} ${resume.annee}',
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: _carteResume(
                          titre: 'Entrées du mois',
                          montant: resume.totalEntrees,
                          devise: resume.devise,
                          couleur: AppTheme.couleurEntree,
                          icone: Icons.south_west,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _carteResume(
                          titre: 'Sorties du mois',
                          montant: resume.totalSorties,
                          devise: resume.devise,
                          couleur: AppTheme.couleurSortie,
                          icone: Icons.north_east,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _carteResume(
                    titre: 'Solde du mois',
                    montant: solde,
                    devise: resume.devise,
                    couleur: solde >= 0 ? AppTheme.couleurEntree : AppTheme.couleurSortie,
                    icone: Icons.account_balance_wallet_outlined,
                    pleineLargeur: true,
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'Accès rapide',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: [
                      _boutonRapide(context, 'Nouvelle entrée', Icons.add_circle_outline, '/entrees'),
                      _boutonRapide(context, 'Nouvelle sortie', Icons.remove_circle_outline, '/sorties'),
                      _boutonRapide(context, 'Générer un rapport PDF', Icons.picture_as_pdf_outlined, '/rapports'),
                    ],
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _erreurConnexion(String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.cloud_off, size: 48, color: Colors.grey),
            const SizedBox(height: 12),
            const Text(
              "Impossible de se connecter à la base de données.",
              textAlign: TextAlign.center,
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              "Vérifiez l'adresse IP configurée dans Paramètres.\n$message",
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.black54, fontSize: 12),
            ),
            const SizedBox(height: 16),
            ElevatedButton(onPressed: _rafraichir, child: const Text('Réessayer')),
          ],
        ),
      ),
    );
  }

  Widget _carteResume({
    required String titre,
    required double montant,
    required String devise,
    required Color couleur,
    required IconData icone,
    bool pleineLargeur = false,
  }) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            CircleAvatar(backgroundColor: couleur.withOpacity(0.12), child: Icon(icone, color: couleur)),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(titre, style: const TextStyle(color: Colors.black54, fontSize: 12)),
                  const SizedBox(height: 4),
                  Text(
                    CurrencyFormatter.formatMontant(montant, devise: devise),
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: couleur),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _boutonRapide(BuildContext context, String texte, IconData icone, String route) {
    return ActionChip(
      avatar: Icon(icone, size: 18, color: AppTheme.couleurPrimaire),
      label: Text(texte),
      onPressed: () => Navigator.of(context).pushReplacementNamed(route),
    );
  }
}

class _ResumeMois {
  final int annee;
  final int mois;
  final double totalEntrees;
  final double totalSorties;
  final String devise;

  _ResumeMois({
    required this.annee,
    required this.mois,
    required this.totalEntrees,
    required this.totalSorties,
    required this.devise,
  });
}
