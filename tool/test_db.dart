import 'package:mysql_dart/mysql_dart.dart';

Future<void> main(List<String> args) async {
  final host = args.isNotEmpty ? args[0] : '127.0.0.1';
  final user = args.length > 1 ? args[1] : 'pentahon_admin';
  final password = args.length > 2 ? args[2] : 'pentaho_password';

  print('Test connexion: $user@$host:3306/gestion_finances');
  MySQLConnection? conn;
  try {
    conn = await MySQLConnection.createConnection(
      host: host,
      port: 3306,
      userName: user,
      password: password,
      databaseName: 'gestion_finances',
      secure: false,
      allowPublicKeyRetrieval: true,
    );
    await conn.connect();
    final result = await conn.execute('SELECT 1 AS ok');
    print('OK: ${result.rows.first.assoc()}');
  } catch (e, st) {
    print('ERREUR: $e');
    print(st);
  } finally {
    await conn?.close();
  }
}
