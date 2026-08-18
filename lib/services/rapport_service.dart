import 'entree_service.dart';
import 'sortie_service.dart';

/// Résultat du calcul de balance pour une période (mois ou année).
class Balance {
  final double totalEntrees;
  final double totalSorties;
  double get solde => totalEntrees - totalSorties;

  Balance({required this.totalEntrees, required this.totalSorties});
}

class RapportService {
  final EntreeService _entreeService = EntreeService();
  final SortieService _sortieService = SortieService();

  Future<Balance> balanceMensuelle(int annee, int mois) async {
    final totalEntrees = await _entreeService.totalParMois(annee, mois);
    final totalSorties = await _sortieService.totalParMois(annee, mois);
    return Balance(totalEntrees: totalEntrees, totalSorties: totalSorties);
  }

  Future<Balance> balanceAnnuelle(int annee) async {
    final totalEntrees = await _entreeService.totalParAnnee(annee);
    final totalSorties = await _sortieService.totalParAnnee(annee);
    return Balance(totalEntrees: totalEntrees, totalSorties: totalSorties);
  }
}
