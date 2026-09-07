import '../models/categorie.dart';
import 'db_service.dart';

class CategorieService {
  Future<List<Categorie>> lister({String? type}) async {
    final conn = await DbService.instance.getConnection();

    final builder = conn.queryBuilder
        .select(['id', 'nom', 'type'])
        .from('categories')
        .orderBy('nom');

    if (type != null) {
      builder.whereRaw('type = ?', [type]);
    }

    final query = builder.build();
    final resultats = await conn.query(query.sql, query.params);
    return resultats.map((r) => Categorie.fromRow(r.fields)).toList();
  }

  Future<int> creer(String nom, String type) async {
    final conn = await DbService.instance.getConnection();
    final query = conn.queryBuilder.insertInto('categories', {
      'nom': nom,
      'type': type,
    });

    final result = await conn.query(query.sql, query.params);
    return result.insertId ?? -1;
  }
}
