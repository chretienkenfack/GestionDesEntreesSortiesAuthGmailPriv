/// Paramètres de connexion à la base de données, modifiables depuis
/// l'onglet "Paramètres" afin de pouvoir pointer l'application vers
/// différentes bases (différents sites / environnements de l'entreprise).
class DbSettings {
  final String host; // adresse IP ou nom d'hôte
  final int port;
  final String database;
  final String username;
  final String password;
  final String sgbdType; // 'mysql' ou 'postgres'

  const DbSettings({
    required this.host,
    this.port = 3306,
    required this.database,
    required this.username,
    required this.password,
    this.sgbdType = 'mysql',
  });

  factory DbSettings.defaults() => const DbSettings(
        host: '127.0.0.1',
        port: 3306,
        database: 'gestion_finances',
        username: 'root',
        password: '',
        sgbdType: 'mysql',
      );

  Map<String, dynamic> toMap() => {
        'host': host,
        'port': port,
        'database': database,
        'username': username,
        'password': password,
        'sgbdType': sgbdType,
      };

  factory DbSettings.fromMap(Map<String, dynamic> map) {
    int parsePort(dynamic val) {
      if (val is int) return val;
      if (val is num) return val.toInt();
      if (val != null) {
        final parsed = int.tryParse(val.toString());
        if (parsed != null) return parsed;
      }
      return 3306;
    }

    return DbSettings(
      host: map['host']?.toString() ?? '127.0.0.1',
      port: parsePort(map['port']),
      database: map['database']?.toString() ?? 'gestion_finances',
      username: map['username']?.toString() ?? 'root',
      password: map['password']?.toString() ?? '',
      sgbdType: map['sgbdType']?.toString() ?? 'mysql',
    );
  }

  DbSettings copyWith({
    String? host,
    int? port,
    String? database,
    String? username,
    String? password,
    String? sgbdType,
  }) {
    return DbSettings(
      host: host ?? this.host,
      port: port ?? this.port,
      database: database ?? this.database,
      username: username ?? this.username,
      password: password ?? this.password,
      sgbdType: sgbdType ?? this.sgbdType,
    );
  }
}
