import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// Écran de démarrage niveau production.
///
/// Séquence d'animation :
///   0ms  → logo apparaît (scale élastique + fade)
///  400ms → titre glisse du bas
///  650ms → sous-titres en cascade
///  900ms → barre de progression + texte statut
///  [fin] → fade-out global → onTermine()
class SplashScreen extends StatefulWidget {
  /// Appelée après le fade-out complet.
  final VoidCallback onTermine;

  /// Durée minimale d'affichage avant le fade-out.
  /// La barre de progression est synchronisée sur cette durée.
  final Duration duree;

  const SplashScreen({
    super.key,
    required this.onTermine,
    this.duree = const Duration(milliseconds: 3200),
  });

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  // ── Controllers ──────────────────────────────────────────────────────────
  late final AnimationController _ctrlLogo;
  late final AnimationController _ctrlTexte;
  late final AnimationController _ctrlProgress;
  late final AnimationController _ctrlFadeOut;
  late final AnimationController _ctrlParticules;

  // ── Animations logo ──────────────────────────────────────────────────────
  late final Animation<double> _logoScale;
  late final Animation<double> _logoFade;
  late final Animation<double> _logoRotation;

  // ── Animations texte ─────────────────────────────────────────────────────
  late final Animation<double> _titreFade;
  late final Animation<Offset> _titreSlide;
  late final Animation<double> _sousTitreFade;
  late final Animation<double> _taglineFade;

  // ── Animations progression ───────────────────────────────────────────────
  late final Animation<double> _progressFade;
  late final Animation<double> _progressValeur;

  // ── Fade-out global ──────────────────────────────────────────────────────
  late final Animation<double> _fadeOut;

  // ── État ─────────────────────────────────────────────────────────────────
  String _messageStatut = 'Initialisation…';
  final List<String> _messages = [
    'Initialisation…',
    'Connexion sécurisée…',
    'Chargement des données…',
    'Prêt !',
  ];

  @override
  void initState() {
    super.initState();
    _initialiserAnimations();
    WidgetsBinding.instance.addPostFrameCallback((_) => _lancerSequence());
  }

  void _initialiserAnimations() {
    // ── Logo (700ms) ─────────────────────────────────────────────────────
    _ctrlLogo = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );

    _logoScale = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween(begin: 0.0, end: 1.15)
            .chain(CurveTween(curve: Curves.easeOutBack)),
        weight: 60,
      ),
      TweenSequenceItem(
        tween: Tween(begin: 1.15, end: 1.0)
            .chain(CurveTween(curve: Curves.easeInOut)),
        weight: 40,
      ),
    ]).animate(_ctrlLogo);

    _logoFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _ctrlLogo,
        curve: const Interval(0.0, 0.4, curve: Curves.easeIn),
      ),
    );

    _logoRotation = Tween<double>(begin: -0.05, end: 0.0).animate(
      CurvedAnimation(parent: _ctrlLogo, curve: Curves.easeOutBack),
    );

    // ── Texte (800ms) ────────────────────────────────────────────────────
    _ctrlTexte = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    _titreFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _ctrlTexte,
        curve: const Interval(0.0, 0.6, curve: Curves.easeOut),
      ),
    );

    _titreSlide = Tween<Offset>(
      begin: const Offset(0, 0.4),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _ctrlTexte, curve: Curves.easeOutCubic),
    );

    _sousTitreFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _ctrlTexte,
        curve: const Interval(0.25, 0.8, curve: Curves.easeOut),
      ),
    );

    _taglineFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _ctrlTexte,
        curve: const Interval(0.5, 1.0, curve: Curves.easeOut),
      ),
    );

    // ── Progression ──────────────────────────────────────────────────────
    _ctrlProgress = AnimationController(
      vsync: this,
      duration: widget.duree - const Duration(milliseconds: 900),
    );

    _progressFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _ctrlProgress,
        curve: const Interval(0.0, 0.2, curve: Curves.easeIn),
      ),
    );

    _progressValeur = CurvedAnimation(
      parent: _ctrlProgress,
      curve: Curves.easeInOut,
    );

    // ── Fade-out sortie (400ms) ───────────────────────────────────────────
    _ctrlFadeOut = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _fadeOut = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(parent: _ctrlFadeOut, curve: Curves.easeIn),
    );

    // ── Particules de fond ────────────────────────────────────────────────
    _ctrlParticules = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat();
  }

  Future<void> _lancerSequence() async {
    if (!mounted) return;

    // Phase 1 : Logo
    await _ctrlLogo.forward();
    if (!mounted) return;

    // Phase 2 : Texte (légèrement avant la fin du logo)
    await Future.delayed(const Duration(milliseconds: 50));
    _ctrlTexte.forward();
    if (!mounted) return;

    // Phase 3 : Barre de progression avec messages dynamiques
    await Future.delayed(const Duration(milliseconds: 250));
    _ctrlProgress.forward();
    _cyclerMessages();
    if (!mounted) return;

    // Attente de fin de la barre
    await _ctrlProgress.forward();
    if (!mounted) return;

    // Phase finale : fade-out et transition
    await Future.delayed(const Duration(milliseconds: 150));
    if (!mounted) return;
    await _ctrlFadeOut.forward();
    if (!mounted) return;

    widget.onTermine();
  }

  void _cyclerMessages() {
    int index = 0;
    Future.doWhile(() async {
      if (!mounted || index >= _messages.length) return false;
      if (mounted) {
        setState(() => _messageStatut = _messages[index]);
      }
      index++;
      await Future.delayed(
        Duration(
          milliseconds:
              (widget.duree.inMilliseconds - 900) ~/ _messages.length,
        ),
      );
      return mounted && index < _messages.length;
    });
  }

  @override
  void dispose() {
    _ctrlLogo.dispose();
    _ctrlTexte.dispose();
    _ctrlProgress.dispose();
    _ctrlFadeOut.dispose();
    _ctrlParticules.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AnimatedBuilder(
        animation: _ctrlFadeOut,
        builder: (context, child) {
          return Opacity(
            opacity: _fadeOut.value,
            child: child,
          );
        },
        child: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Color(0xFF0D1547), // navy très foncé
                Color(0xFF1A237E), // navy logo
                Color(0xFF1565C0), // royal blue
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              stops: [0.0, 0.5, 1.0],
            ),
          ),
          child: Stack(
            children: [
              // ── Fond : particules géométriques ─────────────────────────
              AnimatedBuilder(
                animation: _ctrlParticules,
                builder: (context, _) {
                  return CustomPaint(
                    painter: _ParticulePainter(_ctrlParticules.value),
                    size: MediaQuery.of(context).size,
                  );
                },
              ),

              // ── Contenu principal ───────────────────────────────────────
              SafeArea(
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // ── Logo animé ──────────────────────────────────────
                      AnimatedBuilder(
                        animation: _ctrlLogo,
                        builder: (context, child) {
                          return Opacity(
                            opacity: _logoFade.value.clamp(0.0, 1.0),
                            child: Transform.scale(
                              scale: _logoScale.value,
                              child: Transform.rotate(
                                angle: _logoRotation.value,
                                child: child,
                              ),
                            ),
                          );
                        },
                        child: const _LogoAnime(),
                      ),

                      const SizedBox(height: 36),

                      // ── Titre ───────────────────────────────────────────
                      AnimatedBuilder(
                        animation: _ctrlTexte,
                        builder: (context, child) {
                          return FadeTransition(
                            opacity: _titreFade,
                            child: SlideTransition(
                              position: _titreSlide,
                              child: child,
                            ),
                          );
                        },
                        child: const _BlocTitre(),
                      ),

                      const SizedBox(height: 10),

                      // ── Sous-titre ──────────────────────────────────────
                      AnimatedBuilder(
                        animation: _sousTitreFade,
                        builder: (context, child) {
                          return Opacity(
                            opacity: _sousTitreFade.value.clamp(0.0, 1.0),
                            child: child,
                          );
                        },
                        child: _SousTitreDecore(),
                      ),

                      const SizedBox(height: 8),

                      // ── Tagline ─────────────────────────────────────────
                      AnimatedBuilder(
                        animation: _taglineFade,
                        builder: (context, child) {
                          return Opacity(
                            opacity: _taglineFade.value.clamp(0.0, 1.0),
                            child: child,
                          );
                        },
                        child: Text(
                          'Gestion des Finances',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.55),
                            fontSize: 13,
                            letterSpacing: 1.5,
                            fontWeight: FontWeight.w300,
                          ),
                        ),
                      ),

                      const SizedBox(height: 64),

                      // ── Barre de progression ────────────────────────────
                      AnimatedBuilder(
                        animation: _ctrlProgress,
                        builder: (context, _) {
                          return Opacity(
                            opacity: _progressFade.value.clamp(0.0, 1.0),
                            child: _BlocProgression(
                              valeur: _progressValeur.value,
                              message: _messageStatut,
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Widgets internes ─────────────────────────────────────────────────────────

class _LogoAnime extends StatelessWidget {
  const _LogoAnime();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 116,
      height: 116,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(30),
        gradient: const LinearGradient(
          colors: [Color(0xFF3949AB), Color(0xFF1565C0)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: Border.all(color: Colors.white.withOpacity(0.25), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1565C0).withOpacity(0.6),
            blurRadius: 32,
            spreadRadius: 4,
            offset: const Offset(0, 8),
          ),
          BoxShadow(
            color: Colors.white.withOpacity(0.08),
            blurRadius: 8,
            spreadRadius: -2,
          ),
        ],
      ),
      child: const Center(child: _LogoET()),
    );
  }
}

class _LogoET extends StatelessWidget {
  const _LogoET();

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      clipBehavior: Clip.none,
      children: [
        // Lettre E principale
        const Text(
          'E',
          style: TextStyle(
            color: Colors.white,
            fontSize: 58,
            fontWeight: FontWeight.w900,
            letterSpacing: -6,
            height: 1,
          ),
        ),
        // Lettre T en accent bleu clair
        const Positioned(
          right: 8,
          top: 12,
          child: Text(
            'T',
            style: TextStyle(
              color: Color(0xFF90CAF9),
              fontSize: 30,
              fontWeight: FontWeight.w900,
              height: 1,
            ),
          ),
        ),
        // Halo lumineux sous le logo
        Positioned(
          bottom: -6,
          child: Container(
            width: 60,
            height: 4,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(2),
              gradient: LinearGradient(
                colors: [
                  Colors.transparent,
                  Colors.white.withOpacity(0.4),
                  Colors.transparent,
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _BlocTitre extends StatelessWidget {
  const _BlocTitre();

  @override
  Widget build(BuildContext context) {
    return const Text(
      'ENGINEERYS',
      style: TextStyle(
        color: Colors.white,
        fontSize: 32,
        fontWeight: FontWeight.w900,
        letterSpacing: 7,
        height: 1,
      ),
    );
  }
}

class _SousTitreDecore extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(width: 24, height: 1, color: Colors.white38),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 10),
          child: Text(
            'IT TRAINING CENTER',
            style: TextStyle(
              color: Colors.white60,
              fontSize: 11,
              letterSpacing: 4,
              fontWeight: FontWeight.w400,
            ),
          ),
        ),
        Container(width: 24, height: 1, color: Colors.white38),
      ],
    );
  }
}

class _BlocProgression extends StatelessWidget {
  final double valeur;
  final String message;

  const _BlocProgression({required this.valeur, required this.message});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Barre personnalisée avec dégradé
        SizedBox(
          width: 140,
          child: Stack(
            children: [
              // Fond
              Container(
                height: 3,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              // Remplissage
              FractionallySizedBox(
                widthFactor: valeur.clamp(0.0, 1.0),
                child: Container(
                  height: 3,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(2),
                    gradient: const LinearGradient(
                      colors: [Color(0xFF90CAF9), Colors.white],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.white.withOpacity(0.6),
                        blurRadius: 6,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          child: Text(
            message,
            key: ValueKey(message),
            style: TextStyle(
              color: Colors.white.withOpacity(0.45),
              fontSize: 11,
              letterSpacing: 1.2,
              fontWeight: FontWeight.w400,
            ),
          ),
        ),
      ],
    );
  }
}

// ── Peintre particules ───────────────────────────────────────────────────────

class _ParticulePainter extends CustomPainter {
  final double t;
  static const int _count = 18;

  _ParticulePainter(this.t);

  // Positions pseudo-aléatoires fixes (identiques entre frames)
  static final List<_Particule> _particules = List.generate(_count, (i) {
    final rng = math.Random(i * 73 + 11);
    return _Particule(
      x: rng.nextDouble(),
      y: rng.nextDouble(),
      taille: rng.nextDouble() * 3 + 1,
      vitesse: rng.nextDouble() * 0.3 + 0.05,
      phase: rng.nextDouble() * math.pi * 2,
    );
  });

  @override
  void paint(Canvas canvas, Size size) {
    for (final p in _particules) {
      final y = (p.y - t * p.vitesse) % 1.0;
      final x = p.x + math.sin(t * math.pi * 2 + p.phase) * 0.02;
      final opacity = (math.sin(t * math.pi * 2 + p.phase) * 0.3 + 0.5)
          .clamp(0.05, 0.35);

      canvas.drawCircle(
        Offset(x * size.width, y * size.height),
        p.taille,
        Paint()
          ..color = Colors.white.withOpacity(opacity)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2),
      );
    }
  }

  @override
  bool shouldRepaint(_ParticulePainter old) => old.t != t;
}

class _Particule {
  final double x, y, taille, vitesse, phase;
  const _Particule({
    required this.x,
    required this.y,
    required this.taille,
    required this.vitesse,
    required this.phase,
  });
}
