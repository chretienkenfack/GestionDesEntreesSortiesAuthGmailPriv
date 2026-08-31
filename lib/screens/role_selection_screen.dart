import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../theme/app_theme.dart';

class RoleSelectionScreen extends StatefulWidget {
  final String email;
  final String nom;
  final String? googleId;
  final String? photoUrl;

  const RoleSelectionScreen({
    super.key,
    required this.email,
    required this.nom,
    this.googleId,
    this.photoUrl,
  });

  @override
  State<RoleSelectionScreen> createState() => _RoleSelectionScreenState();
}

class _RoleSelectionScreenState extends State<RoleSelectionScreen> {
  String _selectedRole = 'agent'; // Par défaut
  bool _isLoading = false;

  Future<void> _submitRole() async {
    setState(() => _isLoading = true);
    final auth = context.read<AuthProvider>();
    final succes = await auth.finaliserInscriptionGoogle(
      email: widget.email,
      nom: widget.nom,
      role: _selectedRole,
      googleId: widget.googleId,
      photoUrl: widget.photoUrl,
    );

    if (!mounted) return;

    if (!succes) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(auth.erreur ?? 'Inscription impossible.'),
          backgroundColor: AppTheme.couleurSortie,
        ),
      );
    } else {
      Navigator.of(context).popUntil((route) => route.isFirst);
    }

    setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Complétez votre profil')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'Bienvenue ${widget.nom} !',
                style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              const Text('Avant de continuer, veuillez choisir votre rôle.'),
              const SizedBox(height: 32),
              
              DropdownButtonFormField<String>(
                value: _selectedRole,
                decoration: const InputDecoration(
                  labelText: 'Rôle',
                  border: OutlineInputBorder(),
                ),
                items: const [
                  DropdownMenuItem(value: 'agent', child: Text('Agent')),
                  DropdownMenuItem(value: 'admin', child: Text('Administrateur')),
                ],
                onChanged: (val) {
                  setState(() {
                    if (val != null) _selectedRole = val;
                  });
                },
              ),
              
              const SizedBox(height: 32),
              
              _isLoading 
                ? const CircularProgressIndicator()
                : ElevatedButton(
                    onPressed: _submitRole,
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size.fromHeight(50),
                    ),
                    child: const Text('Finaliser l\'inscription'),
                  ),
            ],
          ),
        ),
      ),
    );
  }
}
