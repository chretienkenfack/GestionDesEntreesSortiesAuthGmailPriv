import 'package:flutter/material.dart';

/// Bouton de connexion Google respectant les proportions habituelles
/// (icône blanche/coloree sur fond blanc, bordure grise) sans dépendre
/// d'assets externes : le logo est recréé en CustomPaint/texte simplifié
/// via une icône Material stylisée pour rester léger.
class GoogleSignInButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final bool chargement;
  final String texte;

  const GoogleSignInButton({
    super.key,
    required this.onPressed,
    this.chargement = false,
    this.texte = 'Continuer avec Google',
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 48,
      child: OutlinedButton(
        onPressed: chargement ? null : onPressed,
        style: OutlinedButton.styleFrom(
          backgroundColor: Colors.white,
          foregroundColor: Colors.black87,
          side: BorderSide(color: Colors.grey.shade300),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
        child: chargement
            ? const SizedBox(
                height: 18,
                width: 18,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _LogoGoogle(),
                  const SizedBox(width: 10),
                  Text(texte, style: const TextStyle(fontWeight: FontWeight.w600)),
                ],
              ),
      ),
    );
  }
}

/// Petit rendu simplifié du logo Google en quatre quarts colorés,
/// pour ne pas dépendre d'un fichier image externe dans le projet.
class _LogoGoogle extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 18,
      width: 18,
      child: CustomPaint(painter: _GoogleLogoPainter()),
    );
  }
}

class _GoogleLogoPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final paintBleu = Paint()..color = const Color(0xFF4285F4);
    final paintVert = Paint()..color = const Color(0xFF34A853);
    final paintJaune = Paint()..color = const Color(0xFFFBBC05);
    final paintRouge = Paint()..color = const Color(0xFFEA4335);

    canvas.drawArc(rect, -0.3, 1.6, true, paintBleu);
    canvas.drawArc(rect, 1.3, 1.6, true, paintVert);
    canvas.drawArc(rect, 2.9, 1.6, true, paintJaune);
    canvas.drawArc(rect, 4.5, 1.6, true, paintRouge);

    canvas.drawCircle(
      size.center(Offset.zero),
      size.width / 3.2,
      Paint()..color = Colors.white,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
