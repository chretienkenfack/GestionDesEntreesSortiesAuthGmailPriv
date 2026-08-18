import 'dart:io' show Platform;

import 'package:flutter/foundation.dart' show kIsWeb;

/// Adresse hôte MySQL adaptée à la plateforme d'exécution.
///
/// Sur l'émulateur Android, `127.0.0.1` désigne l'émulateur lui-même,
/// pas le PC hôte. `10.0.2.2` est l'alias spécial qui pointe vers
/// localhost de la machine de développement.
class PlatformDbHost {
  static String get defaultHost {
    if (kIsWeb) return '127.0.0.1';
    if (Platform.isAndroid) return '10.0.2.2';
    return '127.0.0.1';
  }

  /// Corrige les adresses localhost saisies sur Android (émulateur ou appareil).
  static String hostEffectif(String host) {
    final normalise = host.trim().toLowerCase();
    if (!kIsWeb &&
        Platform.isAndroid &&
        (normalise == '127.0.0.1' || normalise == 'localhost')) {
      return '10.0.2.2';
    }
    return host.trim();
  }

  static String get aideEmulateurAndroid =>
      'Émulateur Android : utilisez 10.0.2.2 pour joindre MySQL sur votre PC.\n'
      'Téléphone physique : utilisez l\'adresse IP locale du PC (ex : 192.168.1.10).';
}
