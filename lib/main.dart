import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';
import 'providers/auth_provider.dart';
import 'screens/login_screen.dart';
import 'screens/dashboard_screen.dart';
import 'screens/entrees_screen.dart';
import 'screens/sorties_screen.dart';
import 'screens/rapports_screen.dart';
import 'screens/parametres_screen.dart';
import 'screens/splash_screen.dart';
import 'theme/app_theme.dart';
import 'utils/constants.dart';

void main() {
  runApp(const GestionFinancesApp());
}

class GestionFinancesApp extends StatelessWidget {
  const GestionFinancesApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
      ],
      child: MaterialApp(
        title: AppConstants.nomApplication,
        debugShowCheckedModeBanner: false,
        theme: AppTheme.theme,
        locale: const Locale('fr', 'FR'),
        supportedLocales: const [Locale('fr', 'FR')],
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        home: const _DemarrageSplash(),
        routes: {
          '/dashboard':   (_) => const _EcranProtege(enfant: DashboardScreen()),
          '/entrees':     (_) => const _EcranProtege(enfant: EntreesScreen()),
          '/sorties':     (_) => const _EcranProtege(enfant: SortiesScreen()),
          '/rapports':    (_) => const _EcranProtege(enfant: RapportsScreen()),
          '/parametres':  (_) => const _EcranProtege(enfant: ParametresScreen(), reserveAdmin: true),
        },
      ),
    );
  }
}

/// Affiche le Splash, puis bascule vers RacineApplication avec un
/// fondu enchaîné fluide (AnimatedSwitcher).
class _DemarrageSplash extends StatefulWidget {
  const _DemarrageSplash();

  @override
  State<_DemarrageSplash> createState() => _DemarrageSplashState();
}

class _DemarrageSplashState extends State<_DemarrageSplash> {
  bool _splashTermine = false;

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      // Le splash fait déjà son propre fade-out ; ici on donne une
      // légère durée pour lisser la bascule côté RacineApplication.
      duration: const Duration(milliseconds: 500),
      switchInCurve: Curves.easeIn,
      switchOutCurve: Curves.easeOut,
      transitionBuilder: (child, animation) =>
          FadeTransition(opacity: animation, child: child),
      child: _splashTermine
          ? const RacineApplication(key: ValueKey('racine'))
          : SplashScreen(
              key: const ValueKey('splash'),
              onTermine: () {
                if (mounted) setState(() => _splashTermine = true);
              },
            ),
    );
  }
}

/// Redirige vers l'écran de connexion ou le tableau de bord
/// selon l'état d'authentification courant.
class RacineApplication extends StatelessWidget {
  const RacineApplication({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    return auth.estConnecte ? const DashboardScreen() : const LoginScreen();
  }
}

/// Empêche l'accès direct à un écran si l'utilisateur n'est pas connecté,
/// et restreint certains écrans (ex: Paramètres) aux administrateurs.
class _EcranProtege extends StatelessWidget {
  final Widget enfant;
  final bool reserveAdmin;

  const _EcranProtege({required this.enfant, this.reserveAdmin = false});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    if (!auth.estConnecte) return const LoginScreen();

    if (reserveAdmin && !auth.estAdmin) {
      return Scaffold(
        appBar: AppBar(title: const Text('Accès refusé')),
        body: const Center(
          child: Text('Cette section est réservée aux administrateurs.'),
        ),
      );
    }
    return enfant;
  }
}
