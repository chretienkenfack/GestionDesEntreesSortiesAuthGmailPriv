import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/categorie.dart';
import '../models/mouvement.dart';
import '../providers/auth_provider.dart';
import '../services/categorie_service.dart';
import '../services/mouvement_service_base.dart';
import '../services/settings_service.dart';
import '../utils/constants.dart';
import '../widgets/app_drawer.dart';
import '../widgets/mouvement_form_dialog.dart';
import '../widgets/mouvement_list_item.dart';

/// Écran générique de gestion (liste + CRUD) d'un type de mouvement.
/// Utilisé à la fois par l'écran Entrées et l'écran Sorties, afin
/// d'éviter de dupliquer toute la logique d'affichage / formulaire.
class MouvementScreenBase extends StatefulWidget {
  final bool estEntree;
  final MouvementServiceBase service;
  final String route;

  const MouvementScreenBase({
    super.key,
    required this.estEntree,
    required this.service,
    required this.route,
  });

  @override
  State<MouvementScreenBase> createState() => _MouvementScreenBaseState();
}

class _MouvementScreenBaseState extends State<MouvementScreenBase> {
  final CategorieService _categorieService = CategorieService();
  final SettingsService _settingsService = SettingsService();

  DateTime _periode = DateTime.now();
  List<Mouvement> _mouvements = [];
  List<Categorie> _categories = [];
  String _devise = AppConstants.deviseParDefaut;
  bool _chargement = true;
  String? _erreur;

  String get _type => widget.estEntree ? 'entree' : 'sortie';
  String get _titre => widget.estEntree ? 'Entrées' : 'Sorties';

  @override
  void initState() {
    super.initState();
    _charger();
  }

  Future<void> _charger() async {
    setState(() {
      _chargement = true;
      _erreur = null;
    });
    try {
      final categories = await _categorieService.lister(type: _type);
      final devise = await _settingsService.getDevise();
      final mouvements = await widget.service.listerParMois(_periode.year, _periode.month);
      setState(() {
        _categories = categories;
        _devise = devise;
        _mouvements = mouvements;
      });
    } catch (e) {
      setState(() => _erreur = e.toString());
    } finally {
      setState(() => _chargement = false);
    }
  }

  Future<void> _changerMois(int delta) async {
    setState(() {
      _periode = DateTime(_periode.year, _periode.month + delta, 1);
    });
    await _charger();
  }

  Future<void> _ouvrirFormulaire({Mouvement? existant}) async {
    final utilisateur = context.read<AuthProvider>().utilisateur;
    if (utilisateur == null) return;
    final userId = utilisateur.id;
    final resultat = await showDialog<Mouvement>(
      context: context,
      builder: (_) => MouvementFormDialog(
        titre: existant == null ? 'Nouvelle ${_titre.toLowerCase().substring(0, _titre.length - 1)}' : 'Modifier',
        categories: _categories,
        userId: userId,
        typeMouvement: _type,
        onCategorieCreee: (cat) {
          setState(() {
            if (!_categories.any((c) => c.id == cat.id)) {
              _categories.add(cat);
            }
          });
        },
        mouvementExistant: existant,
      ),
    );

    if (resultat == null) return;

    try {
      if (existant == null) {
        await widget.service.creer(resultat);
      } else {
        await widget.service.modifier(resultat);
      }
      await _charger();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Enregistrement effectué avec succès.')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Erreur lors de l'enregistrement : $e")),
        );
      }
    }
  }

  Future<void> _confirmerSuppression(Mouvement m) async {
    final confirme = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Confirmer la suppression'),
        content: const Text('Voulez-vous vraiment supprimer cet enregistrement ? Cette action est irréversible.'),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Annuler')),
          ElevatedButton(onPressed: () => Navigator.of(context).pop(true), child: const Text('Supprimer')),
        ],
      ),
    );
    if (confirme != true) return;

    try {
      await widget.service.supprimer(m.id!);
      await _charger();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur lors de la suppression : $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final totalMois = _mouvements.fold<double>(0, (s, m) => s + m.montant);

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        Navigator.of(context).pushReplacementNamed('/dashboard');
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(_titre),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            tooltip: 'Retour au tableau de bord',
            onPressed: () => Navigator.of(context).pushReplacementNamed('/dashboard'),
          ),
        ),
        drawer: AppDrawer(routeActive: widget.route),
        body: Column(
          children: [
            Container(
              color: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
              child: Row(
                children: [
                  IconButton(icon: const Icon(Icons.chevron_left), onPressed: () => _changerMois(-1)),
                  Expanded(
                    child: Text(
                      '${moisFrancais[_periode.month - 1]} ${_periode.year}',
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                  IconButton(icon: const Icon(Icons.chevron_right), onPressed: () => _changerMois(1)),
                ],
              ),
            ),
            const Divider(height: 1),
            Expanded(child: _corps(totalMois)),
          ],
        ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: () => _ouvrirFormulaire(),
          icon: const Icon(Icons.add),
          label: const Text('Ajouter'),
        ),
      ),
    );
  }

  Widget _corps(double totalMois) {
    if (_chargement) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_erreur != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            "Impossible de charger les données.\nVérifiez la connexion à la base de données dans Paramètres.\n$_erreur",
            textAlign: TextAlign.center,
          ),
        ),
      );
    }
    if (_mouvements.isEmpty) {
      return const Center(child: Text('Aucun enregistrement pour cette période.'));
    }

    return RefreshIndicator(
      onRefresh: _charger,
      child: ListView.builder(
        padding: const EdgeInsets.only(top: 8, bottom: 90),
        itemCount: _mouvements.length + 1,
        itemBuilder: (context, index) {
          if (index == _mouvements.length) {
            return Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                'Total du mois : ${totalMois.toStringAsFixed(0)} $_devise',
                textAlign: TextAlign.right,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            );
          }
          final m = _mouvements[index];
          return MouvementListItem(
            mouvement: m,
            estEntree: widget.estEntree,
            devise: _devise,
            onModifier: () => _ouvrirFormulaire(existant: m),
            onSupprimer: () => _confirmerSuppression(m),
          );
        },
      ),
    );
  }
}
