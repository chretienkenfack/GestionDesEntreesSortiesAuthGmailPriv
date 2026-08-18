class Validators {
  static String? champObligatoire(String? valeur, {String champ = 'Ce champ'}) {
    if (valeur == null || valeur.trim().isEmpty) {
      return '$champ est obligatoire.';
    }
    return null;
  }

  static String? email(String? valeur) {
    if (valeur == null || valeur.trim().isEmpty) {
      return "L'adresse e-mail est obligatoire.";
    }
    final regex = RegExp(r'^[\w\.\-]+@[\w\-]+\.[a-zA-Z]{2,}$');
    if (!regex.hasMatch(valeur.trim())) {
      return "Adresse e-mail invalide.";
    }
    return null;
  }

  static String? montant(String? valeur) {
    if (valeur == null || valeur.trim().isEmpty) {
      return 'Le montant est obligatoire.';
    }
    final montant = double.tryParse(valeur.replaceAll(',', '.'));
    if (montant == null) {
      return 'Le montant doit être un nombre valide.';
    }
    if (montant <= 0) {
      return 'Le montant doit être supérieur à zéro.';
    }
    return null;
  }

  static String? port(String? valeur) {
    if (valeur == null || valeur.trim().isEmpty) {
      return 'Le port est obligatoire.';
    }
    final port = int.tryParse(valeur);
    if (port == null || port <= 0 || port > 65535) {
      return 'Le port doit être un nombre entre 1 et 65535.';
    }
    return null;
  }

  static String? adresseIp(String? valeur) {
    if (valeur == null || valeur.trim().isEmpty) {
      return "L'adresse IP / hôte est obligatoire.";
    }
    // Autorise une adresse IPv4 ou un nom d'hôte simple (ex: localhost, db.entreprise.local)
    final ipRegex = RegExp(
      r'^(\d{1,3}\.){3}\d{1,3}$|^[a-zA-Z0-9\-\.]+$',
    );
    if (!ipRegex.hasMatch(valeur.trim())) {
      return "Adresse IP ou nom d'hôte invalide.";
    }
    return null;
  }
}
