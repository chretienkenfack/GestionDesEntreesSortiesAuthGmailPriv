class Categorie {
  final int id;
  final String nom;
  final String type; // 'entree' ou 'sortie'

  Categorie({required this.id, required this.nom, required this.type});

  factory Categorie.fromRow(Map<String, dynamic> row) {
    int parseInt(dynamic val) {
      if (val is int) return val;
      if (val is num) return val.toInt();
      return int.parse(val.toString());
    }

    return Categorie(
      id: parseInt(row['id']),
      nom: row['nom']?.toString() ?? '',
      type: row['type']?.toString() ?? '',
    );
  }
}

