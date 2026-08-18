import 'package:flutter/material.dart';
import '../models/mouvement.dart';
import '../utils/currency_formatter.dart';
import '../theme/app_theme.dart';

class MouvementListItem extends StatelessWidget {
  final Mouvement mouvement;
  final bool estEntree;
  final String devise;
  final VoidCallback onModifier;
  final VoidCallback onSupprimer;

  const MouvementListItem({
    super.key,
    required this.mouvement,
    required this.estEntree,
    required this.devise,
    required this.onModifier,
    required this.onSupprimer,
  });

  @override
  Widget build(BuildContext context) {
    final couleur = estEntree ? AppTheme.couleurEntree : AppTheme.couleurSortie;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: couleur.withOpacity(0.12),
          child: Icon(
            estEntree ? Icons.south_west : Icons.north_east,
            color: couleur,
          ),
        ),
        title: Text(
          mouvement.categorieNom ?? 'Sans catégorie',
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Text(
          '${CurrencyFormatter.formatDate(mouvement.date)} • ${mouvement.description}',
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              CurrencyFormatter.formatMontant(mouvement.montant, devise: devise),
              style: TextStyle(fontWeight: FontWeight.bold, color: couleur),
            ),
            IconButton(
              icon: const Icon(Icons.edit_outlined, size: 20),
              onPressed: onModifier,
            ),
            IconButton(
              icon: const Icon(Icons.delete_outline, size: 20, color: AppTheme.couleurSortie),
              onPressed: onSupprimer,
            ),
          ],
        ),
      ),
    );
  }
}
