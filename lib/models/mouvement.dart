/// Modèle de base partagé par les entrées et les sorties.
/// Les entrées et sorties sont stockées dans deux tables distinctes
/// (`entrees` et `sorties`) mais partagent la même structure.
class Mouvement {
  final int? id;
  final DateTime date;
  final double montant;
  final int? categorieId;
  final String? categorieNom;
  final String description;
  final String modePaiement; // espece, virement, cheque, mobile_money, autre
  final int userId;
  final String? userNom;

  Mouvement({
    this.id,
    required this.date,
    required this.montant,
    this.categorieId,
    this.categorieNom,
    this.description = '',
    this.modePaiement = 'espece',
    required this.userId,
    this.userNom,
  });

  factory Mouvement.fromRow(Map<String, dynamic> row) {
    int? parseNullableInt(dynamic val) {
      if (val == null) return null;
      if (val is int) return val;
      if (val is num) return val.toInt();
      return int.tryParse(val.toString());
    }

    int parseInt(dynamic val) {
      if (val is int) return val;
      if (val is num) return val.toInt();
      return int.parse(val.toString());
    }

    return Mouvement(
      id: parseNullableInt(row['id']),
      date: row['date_operation'] is DateTime
          ? row['date_operation'] as DateTime
          : DateTime.parse(row['date_operation'].toString()),
      montant: (row['montant'] is num)
          ? (row['montant'] as num).toDouble()
          : double.parse(row['montant'].toString()),
      categorieId: parseNullableInt(row['categorie_id']),
      categorieNom: row['categorie_nom']?.toString(),
      description: row['description']?.toString() ?? '',
      modePaiement: row['mode_paiement']?.toString() ?? 'espece',
      userId: parseInt(row['user_id']),
      userNom: row['user_nom']?.toString(),
    );
  }

  Mouvement copyWith({
    int? id,
    DateTime? date,
    double? montant,
    int? categorieId,
    String? description,
    String? modePaiement,
    int? userId,
  }) {
    return Mouvement(
      id: id ?? this.id,
      date: date ?? this.date,
      montant: montant ?? this.montant,
      categorieId: categorieId ?? this.categorieId,
      categorieNom: categorieNom,
      description: description ?? this.description,
      modePaiement: modePaiement ?? this.modePaiement,
      userId: userId ?? this.userId,
      userNom: userNom,
    );
  }
}

/// Libellés français pour les modes de paiement, utilisés dans les
/// formulaires et les PDF.
const Map<String, String> modesPaiementLabels = {
  'espece': 'Espèces',
  'virement': 'Virement',
  'cheque': 'Chèque',
  'mobile_money': 'Mobile Money',
  'autre': 'Autre',
};
