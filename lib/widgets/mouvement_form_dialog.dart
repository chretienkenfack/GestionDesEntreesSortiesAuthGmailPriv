import 'package:flutter/material.dart';
import '../models/categorie.dart';
import '../models/mouvement.dart';
import '../services/categorie_service.dart';
import '../theme/app_theme.dart';
import '../utils/validators.dart';

/// Boîte de dialogue de formulaire, utilisée à la fois pour les entrées
/// et les sorties (le type détermine simplement la liste de catégories
/// proposée et le libellé affiché).
class MouvementFormDialog extends StatefulWidget {
  final String titre;
  final Mouvement? mouvementExistant;
  final List<Categorie> categories;
  final int userId;
  final String typeMouvement; // 'entree' ou 'sortie'
  final Function(Categorie nouvelle)? onCategorieCreee;

  const MouvementFormDialog({
    super.key,
    required this.titre,
    required this.categories,
    required this.userId,
    this.typeMouvement = 'entree',
    this.onCategorieCreee,
    this.mouvementExistant,
  });

  @override
  State<MouvementFormDialog> createState() => _MouvementFormDialogState();
}

class _MouvementFormDialogState extends State<MouvementFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late DateTime _date;
  late TextEditingController _montantCtrl;
  late TextEditingController _descriptionCtrl;
  late List<Categorie> _categoriesLocal;
  int? _categorieId;
  String _modePaiement = 'espece';

  @override
  void initState() {
    super.initState();
    final m = widget.mouvementExistant;
    _date = m?.date ?? DateTime.now();
    _montantCtrl = TextEditingController(text: m != null ? m.montant.toStringAsFixed(0) : '');
    _descriptionCtrl = TextEditingController(text: m?.description ?? '');
    _categoriesLocal = List.from(widget.categories);
    _categorieId = m?.categorieId;
    _modePaiement = m?.modePaiement ?? 'espece';
  }

  @override
  void dispose() {
    _montantCtrl.dispose();
    _descriptionCtrl.dispose();
    super.dispose();
  }

  Future<void> _choisirDate() async {
    final selection = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2015),
      lastDate: DateTime(2100),
    );
    if (selection != null) {
      setState(() => _date = selection);
    }
  }

  Future<void> _ajouterCategorie() async {
    final nomCtrl = TextEditingController();
    final String? nom = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Nouvelle catégorie'),
        content: TextField(
          controller: nomCtrl,
          autofocus: true,
          decoration: const InputDecoration(
            labelText: 'Nom de la catégorie',
            hintText: 'Ex: Projet, Facture, Vente...',
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('Annuler')),
          ElevatedButton(
            onPressed: () {
              final val = nomCtrl.text.trim();
              if (val.isNotEmpty) Navigator.of(ctx).pop(val);
            },
            child: const Text('Ajouter'),
          ),
        ],
      ),
    );

    if (nom == null || nom.isEmpty) return;

    try {
      final nouveauId = await CategorieService().creer(nom, widget.typeMouvement);
      final nouvelleCat = Categorie(id: nouveauId, nom: nom, type: widget.typeMouvement);
      setState(() {
        _categoriesLocal.add(nouvelleCat);
        _categorieId = nouveauId;
      });
      widget.onCategorieCreee?.call(nouvelleCat);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur lors de la création de la catégorie : $e')),
        );
      }
    }
  }

  void _valider() {
    if (!_formKey.currentState!.validate()) return;

    final resultat = Mouvement(
      id: widget.mouvementExistant?.id,
      date: _date,
      montant: double.parse(_montantCtrl.text.replaceAll(',', '.')),
      categorieId: _categorieId,
      description: _descriptionCtrl.text.trim(),
      modePaiement: _modePaiement,
      userId: widget.userId,
    );
    Navigator.of(context).pop(resultat);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.titre),
      content: SizedBox(
        width: 420,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text('Date : ${_date.day.toString().padLeft(2, '0')}/'
                      '${_date.month.toString().padLeft(2, '0')}/${_date.year}'),
                  trailing: const Icon(Icons.calendar_today, size: 18),
                  onTap: _choisirDate,
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _montantCtrl,
                  decoration: const InputDecoration(labelText: 'Montant'),
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  validator: Validators.montant,
                ),
                const SizedBox(height: 12),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<int>(
                        value: _categoriesLocal.any((c) => c.id == _categorieId) ? _categorieId : null,
                        decoration: const InputDecoration(labelText: 'Catégorie (optionnelle)'),
                        hint: const Text('Sélectionner une catégorie'),
                        items: _categoriesLocal
                            .map((c) => DropdownMenuItem(value: c.id, child: Text(c.nom)))
                            .toList(),
                        onChanged: (v) => setState(() => _categorieId = v),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.add_circle_outline, color: AppTheme.couleurPrimaire),
                      tooltip: 'Créer une nouvelle catégorie',
                      onPressed: _ajouterCategorie,
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: _modePaiement,
                  decoration: const InputDecoration(labelText: 'Mode de paiement'),
                  items: modesPaiementLabels.entries
                      .map((e) => DropdownMenuItem(value: e.key, child: Text(e.value)))
                      .toList(),
                  onChanged: (v) => setState(() => _modePaiement = v ?? 'espece'),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _descriptionCtrl,
                  decoration: const InputDecoration(labelText: 'Description'),
                  maxLines: 2,
                  validator: (v) => Validators.champObligatoire(v, champ: 'La description'),
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Annuler'),
        ),
        ElevatedButton(
          onPressed: _valider,
          child: const Text('Enregistrer'),
        ),
      ],
    );
  }
}
