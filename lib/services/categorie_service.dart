import '../models/categorie.dart';
import 'db_service.dart';

class CategorieService {
  Future<List<Categorie>> lister({String? type}) async {
    final conn = await DbService.instance.getConnection();
    final resultats = type == null
        ? await conn.query('SELECT id, nom, type FROM categories ORDER BY nom')
        : await conn.query(
            'SELECT id, nom, type FROM categories WHERE type = ? ORDER BY nom',
            [type],
          );
    return resultats.map((r) => Categorie.fromRow(r.fields)).toList();
  }

  Future<int> creer(String nom, String type) async {
    final conn = await DbService.instance.getConnection();
    final result = await conn.query(
      'INSERT INTO categories (nom, type) VALUES (?, ?)',
      [nom, type],
    );
    return result.insertId ?? -1;
  }
}
