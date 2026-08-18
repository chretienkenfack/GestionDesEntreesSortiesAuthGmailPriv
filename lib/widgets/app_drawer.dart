import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../theme/app_theme.dart';

class AppDrawer extends StatelessWidget {
  final String routeActive;
  const AppDrawer({super.key, required this.routeActive});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final utilisateur = auth.utilisateur;

    return Drawer(
      child: Column(
        children: [
          UserAccountsDrawerHeader(
            decoration: const BoxDecoration(gradient: AppTheme.degradePrimaire),
            accountName: Text(
              utilisateur?.nom ?? '',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
            ),
            accountEmail: Text(
              utilisateur?.isAdmin == true ? 'Administrateur' : 'Agent comptable',
              style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 12),
            ),
            currentAccountPicture: CircleAvatar(
              backgroundColor: Colors.white,
              child: Text(
                (utilisateur?.nom.isNotEmpty ?? false)
                    ? utilisateur!.nom[0].toUpperCase()
                    : '?',
                style: const TextStyle(
                  color: AppTheme.couleurPrimaire,
                  fontWeight: FontWeight.bold,
                  fontSize: 24,
                ),
              ),
            ),
          ),
          _lienMenu(context, icone: Icons.dashboard_outlined, texte: 'Tableau de bord', route: '/dashboard'),
          _lienMenu(context, icone: Icons.south_west, texte: 'Entrées', route: '/entrees'),
          _lienMenu(context, icone: Icons.north_east, texte: 'Sorties', route: '/sorties'),
          _lienMenu(context, icone: Icons.picture_as_pdf_outlined, texte: 'Rapports PDF', route: '/rapports'),
          if (auth.estAdmin)
            _lienMenu(context, icone: Icons.settings_outlined, texte: 'Paramètres', route: '/parametres'),
          const Spacer(),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.logout, color: AppTheme.couleurSortie),
            title: const Text('Déconnexion'),
            onTap: () {
              Navigator.of(context).pop();
              context.read<AuthProvider>().deconnecter();
            },
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  Widget _lienMenu(BuildContext context, {required IconData icone, required String texte, required String route}) {
    final actif = routeActive == route;
    return ListTile(
      leading: Icon(icone, color: actif ? AppTheme.couleurPrimaire : Colors.grey[700]),
      title: Text(
        texte,
        style: TextStyle(
          color: actif ? AppTheme.couleurPrimaire : Colors.black87,
          fontWeight: actif ? FontWeight.bold : FontWeight.normal,
        ),
      ),
      selected: actif,
      selectedTileColor: AppTheme.couleurPrimaire.withOpacity(0.08),
      onTap: () {
        Navigator.of(context).pop();
        if (!actif) {
          Navigator.of(context).pushReplacementNamed(route);
        }
      },
    );
  }
}
