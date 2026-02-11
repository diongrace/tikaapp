import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Ecran de chargement pour la boutique
class ShopLoadingScreen extends StatefulWidget {
  const ShopLoadingScreen({super.key});

  @override
  State<ShopLoadingScreen> createState() => _ShopLoadingScreenState();
}

class _ShopLoadingScreenState extends State<ShopLoadingScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  static const Color primaryColor = Color(0xFFB932D6);

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);

    _fadeAnimation = Tween<double>(begin: 0.4, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Logo TIKA
            Text(
              'TIKA',
              style: GoogleFonts.poppins(
                fontSize: 42,
                fontWeight: FontWeight.w800,
                color: primaryColor,
                letterSpacing: 8,
              ),
            ),
            const SizedBox(height: 6),
            Container(
              width: 50,
              height: 3,
              decoration: BoxDecoration(
                color: primaryColor.withOpacity(0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 40),

            // Indicateur de chargement
            const SizedBox(
              width: 36,
              height: 36,
              child: CircularProgressIndicator(
                strokeWidth: 3,
                valueColor: AlwaysStoppedAnimation<Color>(primaryColor),
              ),
            ),
            const SizedBox(height: 20),

            // Texte anime
            FadeTransition(
              opacity: _fadeAnimation,
              child: Text(
                'Chargement de la boutique...',
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Colors.grey.shade500,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
