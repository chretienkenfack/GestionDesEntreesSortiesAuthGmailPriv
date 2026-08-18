class AppUser {
  final int id;
  final String nom;
  final String email;
  final String role; // 'admin' ou 'agent'
  final String authProvider;
  final String? photoUrl;

  AppUser({
    required this.id,
    required this.nom,
    required this.email,
    required this.role,
    this.authProvider = 'local',
    this.photoUrl,
  });

  bool get isAdmin => role == 'admin';

  Map<String, dynamic> toMap() => {
        'id': id,
        'nom': nom,
        'email': email,
        'role': role,
        'auth_provider': authProvider,
        'photo_url': photoUrl,
      };

  factory AppUser.fromMap(Map<String, dynamic> map) => AppUser.fromRow(map);

  factory AppUser.fromRow(Map<String, dynamic> row) {
    int parseInt(dynamic val) {
      if (val is int) return val;
      if (val is num) return val.toInt();
      return int.parse(val.toString());
    }

    return AppUser(
      id: parseInt(row['id']),
      nom: row['nom']?.toString() ?? '',
      email: row['email']?.toString() ?? '',
      role: row['role']?.toString() ?? 'agent',
      authProvider: row['auth_provider']?.toString() ?? 'local',
      photoUrl: row['photo_url']?.toString(),
    );
  }
}