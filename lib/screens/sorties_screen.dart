import 'package:flutter/material.dart';
import '../services/sortie_service.dart';
import 'mouvement_screen_base.dart';

class SortiesScreen extends StatelessWidget {
  const SortiesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return MouvementScreenBase(
      estEntree: false,
      service: SortieService(),
      route: '/sorties',
    );
  }
}
