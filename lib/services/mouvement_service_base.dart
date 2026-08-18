import '../models/mouvement.dart';
import 'db_service.dart';

/// Logique CRUD commune, paramétrée par le nom de la table
/// ('entrees' ou 'sorties'), pour éviter la duplication entre
/// EntreeService et SortieService tout en gardant deux tables distinctes.
abstract class MouvementServiceBase {
  String get table;

  Future<List<Mouvement>> listerParMois(int annee, int mois) async {
    final conn = await DbService.instance.getConnection();
    final resultats = await conn.query(
      '''
      SELECT m.id, m.date_operation, m.montant, m.categorie_id, m.description,
             m.mode_paiement, m.user_id, c.nom AS categorie_nom, u.nom AS user_nom
      FROM $table m
      LEFT JOIN categories c ON c.id = m.categorie_id
      LEFT JOIN users u ON u.id = m.user_id
      WHERE YEAR(m.date_operation) = ? AND MONTH(m.date_operation) = ?
      ORDER BY m.date_operation ASC, m.id ASC
      ''',
      [annee, mois],
    );
    return resultats.map((r) => Mouvement.fromRow(r.fields)).toList();
  }

  Future<List<Mouvement>> listerParAnnee(int annee) async {
    final conn = await DbService.instance.getConnection();
    final resultats = await conn.query(
      '''
      SELECT m.id, m.date_operation, m.montant, m.categorie_id, m.description,
             m.mode_paiement, m.user_id, c.nom AS categorie_nom, u.nom AS user_nom
      FROM $table m
      LEFT JOIN categories c ON c.id = m.categorie_id
      LEFT JOIN users u ON u.id = m.user_id
      WHERE YEAR(m.date_operation) = ?
      ORDER BY m.date_operation ASC, m.id ASC
      ''',
      [annee],
    );
    return resultats.map((r) => Mouvement.fromRow(r.fields)).toList();
  }

  Future<List<Mouvement>> listerTout({int limite = 200}) async {
    final conn = await DbService.instance.getConnection();
    final resultats = await conn.query(
      '''
      SELECT m.id, m.date_operation, m.montant, m.categorie_id, m.description,
             m.mode_paiement, m.user_id, c.nom AS categorie_nom, u.nom AS user_nom
      FROM $table m
      LEFT JOIN categories c ON c.id = m.categorie_id
      LEFT JOIN users u ON u.id = m.user_id
      ORDER BY m.date_operation DESC, m.id DESC
      LIMIT ?
      ''',
      [limite],
    );
    return resultats.map((r) => Mouvement.fromRow(r.fields)).toList();
  }

  Future<int> creer(Mouvement m) async {
    final conn = await DbService.instance.getConnection();
    final result = await conn.query(
      '''
      INSERT INTO $table (date_operation, montant, categorie_id, description, mode_paiement, user_id)
      VALUES (?, ?, ?, ?, ?, ?)
      ''',
      [
        _formatDateSql(m.date),
        m.montant,
        m.categorieId,
        m.description,
        m.modePaiement,
        m.userId,
      ],
    );
    return result.insertId ?? -1;
  }

  Future<void> modifier(Mouvement m) async {
    if (m.id == null) {
      throw ArgumentError('Impossible de modifier un mouvement sans identifiant.');
    }
    final conn = await DbService.instance.getConnection();
    await conn.query(
      '''
      UPDATE $table
      SET date_operation = ?, montant = ?, categorie_id = ?, description = ?, mode_paiement = ?
      WHERE id = ?
      ''',
      [
        _formatDateSql(m.date),
        m.montant,
        m.categorieId,
        m.description,
        m.modePaiement,
        m.id,
      ],
    );
  }

  Future<void> supprimer(int id) async {
    final conn = await DbService.instance.getConnection();
    await conn.query('DELETE FROM $table WHERE id = ?', [id]);
  }

  Future<double> totalParMois(int annee, int mois) async {
    final conn = await DbService.instance.getConnection();
    final resultats = await conn.query(
      '''
      SELECT COALESCE(SUM(montant), 0) AS total
      FROM $table
      WHERE YEAR(date_operation) = ? AND MONTH(date_operation) = ?
      ''',
      [annee, mois],
    );
    final valeur = resultats.first.fields['total'];
    if (valeur == null) return 0.0;
    return (valeur is num) ? valeur.toDouble() : (double.tryParse(valeur.toString()) ?? 0.0);
  }

  Future<double> totalParAnnee(int annee) async {
    final conn = await DbService.instance.getConnection();
    final resultats = await conn.query(
      '''
      SELECT COALESCE(SUM(montant), 0) AS total
      FROM $table
      WHERE YEAR(date_operation) = ?
      ''',
      [annee],
    );
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
