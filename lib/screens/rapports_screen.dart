import 'package:flutter/material.dart';
import 'package:printing/printing.dart';
import '../services/entree_service.dart';
import '../services/sortie_service.dart';
import '../services/rapport_service.dart';
import '../services/pdf_service.dart';
import '../services/settings_service.dart';
import '../utils/constants.dart';
import '../widgets/app_drawer.dart';
import 'dart:typed_data';

class RapportsScreen extends StatefulWidget {
  const RapportsScreen({super.key});

  @override
  State<RapportsScreen> createState() => _RapportsScreenState();
}

class _RapportsScreenState extends State<RapportsScreen> {
  final EntreeService _entreeService = EntreeService();
  final SortieService _sortieService = SortieService();
  final RapportService _rapportService = RapportService();
  final PdfService _pdfService = PdfService();
  final SettingsService _settingsService = SettingsService();

  int _annee = DateTime.now().year;
  int _mois = DateTime.now().month;
  bool _generation = false;

  final List<int> _anneesDisponibles =
      List.generate(6, (i) => DateTime.now().year - i);

  Future<void> _genererListeEntrees() async {
    await _lancer(() async {
      final entrees = await _entreeService.listerParMois(_annee, _mois);
      final nomEntreprise = await _settingsService.getNomEntreprise();
      final devise = await _settingsService.getDevise();
      final bytes = await _pdfService.genererListeMouvements(
        mouvements: entrees,
        titre: 'Liste des entrées',
        annee: _annee,
        mois: _mois,
        nomEntreprise: nomEntreprise,
        devise: devise,
      );
      return bytes;
    }, 'entrees_${_annee}_$_mois.pdf');
  }

  Future<void> _genererListeSorties() async {
    await _lancer(() async {
      final sorties = await _sortieService.listerParMois(_annee, _mois);
      final nomEntreprise = await _settingsService.getNomEntreprise();
      final devise = await _settingsService.getDevise();
      final bytes = await _pdfService.genererListeMouvements(
        mouvements: sorties,
        titre: 'Liste des sorties',
        annee: _annee,
        mois: _mois,
        nomEntreprise: nomEntreprise,
        devise: devise,
      );
      return bytes;
    }, 'sorties_${_annee}_$_mois.pdf');
  }

  Future<void> _genererBalanceMensuelle() async {
    await _lancer(() async {
      final balance = await _rapportService.balanceMensuelle(_annee, _mois);
      final nomEntreprise = await _settingsService.getNomEntreprise();
      final devise = await _settingsService.getDevise();
      return _pdfService.genererBalance(
        balance: balance,
        nomEntreprise: nomEntreprise,
        devise: devise,
        annee: _annee,
        mois: _mois,
      );
    }, 'balance_mois_${_annee}_$_mois.pdf');
  }

  Future<void> _genererBalanceAnnuelle() async {
    await _lancer(() async {
      final balance = await _rapportService.balanceAnnuelle(_annee);
      final nomEntreprise = await _settingsService.getNomEntreprise();
      final devise = await _settingsService.getDevise();
      return _pdfService.genererBalance(
        balance: balance,
        nomEntreprise: nomEntreprise,
        devise: devise,
        annee: _annee,
      );
    }, 'balance_annee_$_annee.pdf');
  }

  Future<void> _lancer(Future<List<int>> Function() generer, String nomFichier) async {
    setState(() => _generation = true);
    try {
      final bytes = await generer();
     await Printing.layoutPdf(
  onLayout: (format) async => Uint8List.fromList(bytes),
  name: nomFichier,
);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur lors de la génération du PDF : $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _generation = false);
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
          title: const Text('Rapports PDF'),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            tooltip: 'Retour au tableau de bord',
            onPressed: () => Navigator.of(context).pushReplacementNamed('/dashboard'),
          ),
        ),
        drawer: const AppDrawer(routeActive: '/rapports'),
      body: AbsorbPointer(
        absorbing: _generation,
        child: Stack(
          children: [
            ListView(
              padding: const EdgeInsets.all(16),
              children: [
                const Text('Période concernée', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<int>(
                        value: _mois,
                        decoration: const InputDecoration(labelText: 'Mois'),
                        items: List.generate(
                          12,
                          (i) => DropdownMenuItem(value: i + 1, child: Text(moisFrancais[i])),
                        ),
                        onChanged: (v) => setState(() => _mois = v ?? _mois),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: DropdownButtonFormField<int>(
                        value: _annee,
                        decoration: const InputDecoration(labelText: 'Année'),
                        items: _anneesDisponibles
                            .map((a) => DropdownMenuItem(value: a, child: Text('$a')))
                            .toList(),
                        onChanged: (v) => setState(() => _annee = v ?? _annee),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                _carteRapport(
                  icone: Icons.south_west,
                  titre: 'Liste des entrées du mois',
                  description: 'Toutes les entrées enregistrées pour le mois sélectionné.',
                  onTap: _genererListeEntrees,
                ),
                _carteRapport(
                  icone: Icons.north_east,
                  titre: 'Liste des sorties du mois',
                  description: 'Toutes les sorties enregistrées pour le mois sélectionné.',
                  onTap: _genererListeSorties,
                ),
                _carteRapport(
                  icone: Icons.calendar_month_outlined,
                  titre: 'Balance du mois',
                  description: 'Total des entrées, des sorties, et solde pour le mois sélectionné.',
                  onTap: _genererBalanceMensuelle,
                ),
                _carteRapport(
                  icone: Icons.event_note_outlined,
                  titre: "Balance de l'année",
                  description: "Total des entrées, des sorties, et solde pour toute l'année sélectionnée.",
                  onTap: _genererBalanceAnnuelle,
                ),
              ],
            ),
            if (_generation)
              Container(
                color: Colors.black26,
                child: const Center(child: CircularProgressIndicator()),
              ),
          ],
        ),
      ),
    ),
    );
  }

  Widget _carteRapport({
    required IconData icone,
    required String titre,
    required String description,
    required VoidCallback onTap,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: Icon(icone, color: Theme.of(context).colorScheme.primary),
        title: Text(titre, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(description),
        trailing: const Icon(Icons.picture_as_pdf_outlined),
        onTap: onTap,
      ),
    );
  }
}
