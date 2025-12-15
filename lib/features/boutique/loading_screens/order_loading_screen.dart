import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Écran de chargement pour les commandes
class OrderLoadingScreen extends StatelessWidget {
  final String? message;

  const OrderLoadingScreen({
    super.key,
    this.message,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF8936A8),
              Color(0xFFB24FD4),
            ],
          ),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Icône de commande animée
              TweenAnimationBuilder(
                tween: Tween<double>(begin: 0, end: 1),
                duration: const Duration(milliseconds: 800),
                curve: Curves.elasticOut,
                builder: (context, double value, child) {
                  return Transform.scale(
                    scale: value,
                    child: child,
                  );
                },
                child: Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.2),
                        blurRadius: 20,
                        spreadRadius: 3,
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.shopping_bag_outlined,
                    size: 60,
                    color: Color(0xFF8936A8),
                  ),
                ),
              ),

              const SizedBox(height: 50),

              // Spinner
              const SizedBox(
                width: 50,
                height: 50,
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  strokeWidth: 4,
                ),
              ),

              const SizedBox(height: 30),

              // Message
              Text(
                message ?? 'Traitement en cours...',
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 12),

              Text(
                'Veuillez patienter',
                style: GoogleFonts.openSans(
                  fontSize: 14,
                  color: Colors.white.withOpacity(0.9),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
