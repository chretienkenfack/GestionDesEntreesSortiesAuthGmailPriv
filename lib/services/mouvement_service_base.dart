import '../models/mouvement.dart';
import 'db_service.dart';

/// Logique CRUD commune, paramétrée par le nom de la table
/// ('entrees' ou 'sorties'), basée sur l'ORM QueryBuilder multi-SGBD.
abstract class MouvementServiceBase {
  String get table;

  List<String> get _selectFields => [
        'm.id',
        'm.date_operation',
        'm.montant',
        'm.categorie_id',
        'm.description',
        'm.mode_paiement',
        'm.user_id',
        'c.nom AS categorie_nom',
        'u.nom AS user_nom',
      ];

  Future<List<Mouvement>> listerParMois(int annee, int mois) async {
    final conn = await DbService.instance.getConnection();
    final query = conn.queryBuilder
        .select(_selectFields)
        .from(table, 'm')
        .leftJoin('categories', 'c', 'c.id = m.categorie_id')
        .leftJoin('users', 'u', 'u.id = m.user_id')
        .whereYear('m.date_operation', annee)
        .whereMonth('m.date_operation', mois)
        .orderBy('m.date_operation ASC, m.id ASC')
        .build();

    final resultats = await conn.query(query.sql, query.params);
    return resultats.map((r) => Mouvement.fromRow(r.fields)).toList();
  }

  Future<List<Mouvement>> listerParAnnee(int annee) async {
    final conn = await DbService.instance.getConnection();
    final query = conn.queryBuilder
        .select(_selectFields)
        .from(table, 'm')
        .leftJoin('categories', 'c', 'c.id = m.categorie_id')
        .leftJoin('users', 'u', 'u.id = m.user_id')
        .whereYear('m.date_operation', annee)
        .orderBy('m.date_operation ASC, m.id ASC')
        .build();

    final resultats = await conn.query(query.sql, query.params);
    return resultats.map((r) => Mouvement.fromRow(r.fields)).toList();
  }

  Future<List<Mouvement>> listerTout({int limite = 200}) async {
    final conn = await DbService.instance.getConnection();
    final query = conn.queryBuilder
        .select(_selectFields)
        .from(table, 'm')
        .leftJoin('categories', 'c', 'c.id = m.categorie_id')
        .leftJoin('users', 'u', 'u.id = m.user_id')
        .orderBy('m.date_operation DESC, m.id DESC')
        .limit(limite)
        .build();

    final resultats = await conn.query(query.sql, query.params);
    return resultats.map((r) => Mouvement.fromRow(r.fields)).toList();
  }

  Future<int> creer(Mouvement m) async {
    final conn = await DbService.instance.getConnection();
    final query = conn.queryBuilder.insertInto(table, {
      'date_operation': _formatDateSql(m.date),
      'montant': m.montant,
      'categorie_id': m.categorieId,
      'description': m.description,
      'mode_paiement': m.modePaiement,
      'user_id': m.userId,
    });

    final result = await conn.query(query.sql, query.params);
    return result.insertId ?? -1;
  }

  Future<void> modifier(Mouvement m) async {
    if (m.id == null) {
      throw ArgumentError('Impossible de modifier un mouvement sans identifiant.');
    }
    final conn = await DbService.instance.getConnection();
    final query = conn.queryBuilder.update(
      table,
      {
        'date_operation': _formatDateSql(m.date),
        'montant': m.montant,
        'categorie_id': m.categorieId,
        'description': m.description,
        'mode_paiement': m.modePaiement,
      },
      where: 'id = ?',
      whereParams: [m.id],
    );

    await conn.query(query.sql, query.params);
  }

  Future<void> supprimer(int id) async {
    final conn = await DbService.instance.getConnection();
    final query = conn.queryBuilder.deleteFrom(
      table,
      where: 'id = ?',
      whereParams: [id],
    );

    await conn.query(query.sql, query.params);
  }

  Future<double> totalParMois(int annee, int mois) async {
    final conn = await DbService.instance.getConnection();
    final query = conn.queryBuilder
        .select(['COALESCE(SUM(montant), 0) AS total'])
        .from(table)
        .whereYear('date_operation', annee)
        .whereMonth('date_operation', mois)
        .build();

    final resultats = await conn.query(query.sql, query.params);
    final valeur = resultats.first.fields['total'];
    if (valeur == null) return 0.0;
    return (valeur is num) ? valeur.toDouble() : (double.tryParse(valeur.toString()) ?? 0.0);
  }

  Future<double> totalParAnnee(int annee) async {
    final conn = await DbService.instance.getConnection();
    final query = conn.queryBuilder
        .select(['COALESCE(SUM(montant), 0) AS total'])
        .from(table)
        .whereYear('date_operation', annee)
        .build();

    final resultats = await conn.query(query.sql, query.params);
    final valeur = resultats.first.fields['total'];
    if (valeur == null) return 0.0;
    return (valeur is num) ? valeur.toDouble() : (double.tryParse(valeur.toString()) ?? 0.0);
  }

  String _formatDateSql(DateTime d) {
    return '${d.year.toString().padLeft(4, '0')}-'
        '${d.month.toString().padLeft(2, '0')}-'
        '${d.day.toString().padLeft(2, '0')}';
  }
}
