import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Écran de chargement pour les favoris
class FavoritesLoadingScreen extends StatelessWidget {
  const FavoritesLoadingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Animation de chargement avec cercle
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              color: const Color(0xFF8936A8).withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: const Center(
              child: SizedBox(
                width: 50,
                height: 50,
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF8936A8)),
                  strokeWidth: 3,
                ),
              ),
            ),
          ),
          const SizedBox(height: 24),
          // Icône coeur
          Icon(
            Icons.favorite_border_rounded,
            size: 48,
            color: const Color(0xFF8936A8).withOpacity(0.6),
          ),
          const SizedBox(height: 16),
          // Texte de chargement
          Text(
            'Chargement des favoris...',
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF2D2D2D),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Veuillez patienter',
            style: GoogleFonts.openSans(
              fontSize: 14,
              color: Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
  }
}
