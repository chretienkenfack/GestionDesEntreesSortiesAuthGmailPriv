import 'package:flutter/material.dart';
import '../services/entree_service.dart';
import 'mouvement_screen_base.dart';

class EntreesScreen extends StatelessWidget {
  const EntreesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return MouvementScreenBase(
      estEntree: true,
      service: EntreeService(),
      route: '/entrees',
    );
  }
}
