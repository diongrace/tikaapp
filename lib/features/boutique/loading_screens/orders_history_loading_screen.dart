import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Écran de chargement pour l'historique des commandes
class OrdersHistoryLoadingScreen extends StatelessWidget {
  const OrdersHistoryLoadingScreen({super.key});

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
          // Icône historique
          Icon(
            Icons.history_rounded,
            size: 48,
            color: const Color(0xFF8936A8).withOpacity(0.6),
          ),
          const SizedBox(height: 16),
          // Texte de chargement
          Text(
            'Chargement de l\'historique...',
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF2D2D2D),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Récupération de vos commandes',
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
