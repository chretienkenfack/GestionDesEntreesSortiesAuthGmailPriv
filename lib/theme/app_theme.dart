import 'package:flutter/material.dart';

/// Palette inspirée du logo Engineerys IT Training Center.
/// Navy foncé  : #1A237E  (hexagone + lettre E)
/// Royal bleu  : #1565C0  (lettre T + accents pixels)
class AppTheme {
  // ── Couleurs principales ──────────────────────────────────────────────────
  static const Color couleurPrimaire     = Color(0xFF1A237E); // Navy – logo hexagone
  static const Color couleurAccent       = Color(0xFF1565C0); // Royal – lettre T
  static const Color couleurPrimaireClair= Color(0xFF3949AB); // indigo intermédiaire

  // ── Couleurs sémantiques ──────────────────────────────────────────────────
  static const Color couleurEntree = Color(0xFF2E7D32); // vert entrée
  static const Color couleurSortie = Color(0xFFC62828); // rouge sortie

  // ── Dégradé utilisé sur les écrans login / register ──────────────────────
  static const LinearGradient degradePrimaire = LinearGradient(
    colors: [couleurPrimaire, couleurAccent],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // ── Thème global ──────────────────────────────────────────────────────────
  static ThemeData get theme {
    final cs = ColorScheme.fromSeed(
      seedColor: couleurPrimaire,
      primary: couleurPrimaire,
      secondary: couleurAccent,
      brightness: Brightness.light,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: cs,
      scaffoldBackgroundColor: const Color(0xFFF0F2F8),

      appBarTheme: const AppBarTheme(
        backgroundColor: couleurPrimaire,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          color: Colors.white,
          fontSize: 18,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.3,
        ),
        iconTheme: IconThemeData(color: Colors.white),
      ),

      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: couleurPrimaire,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          elevation: 2,
          shadowColor: couleurPrimaire.withOpacity(0.4),
        ),
      ),

      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: couleurAccent,
        ),
      ),

      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: couleurAccent,
        foregroundColor: Colors.white,
        elevation: 4,
      ),

      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: couleurAccent, width: 2),
        ),
        filled: true,
        fillColor: Colors.white,
        labelStyle: const TextStyle(color: Color(0xFF546080)),
      ),

      cardTheme: CardThemeData(
        elevation: 2,
        shadowColor: couleurPrimaire.withOpacity(0.12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        color: Colors.white,
      ),

      drawerTheme: const DrawerThemeData(
        backgroundColor: Colors.white,
      ),

      dividerTheme: const DividerThemeData(
        color: Color(0xFFE0E4EF),
      ),

      chipTheme: ChipThemeData(
        backgroundColor: const Color(0xFFE8EAF6),
        selectedColor: couleurPrimaire.withOpacity(0.2),
        labelStyle: const TextStyle(color: couleurPrimaire, fontWeight: FontWeight.w500),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      ),
    );
  }
}
