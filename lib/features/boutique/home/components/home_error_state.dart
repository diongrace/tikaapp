import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Widget d'état d'erreur pour l'écran d'accueil
class HomeErrorState extends StatelessWidget {
  final String? errorMessage;
  final VoidCallback onRetry;

  const HomeErrorState({
    super.key,
    this.errorMessage,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'Erreur de chargement',
              style: GoogleFonts.openSans(
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 40),
              child: Text(
                errorMessage ?? 'Une erreur est survenue',
                style: GoogleFonts.openSans(
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: onRetry,
              child: const Text('Réessayer'),
            ),
          ],
        ),
      ),
    );
  }
}
