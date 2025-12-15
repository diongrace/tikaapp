import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Écran de chargement simple et réutilisable
class SimpleLoadingScreen extends StatelessWidget {
  final String? title;
  final String? subtitle;
  final Color? primaryColor;
  final IconData? icon;

  const SimpleLoadingScreen({
    super.key,
    this.title,
    this.subtitle,
    this.primaryColor,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final color = primaryColor ?? const Color(0xFF8936A8);

    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Icône avec animation
            if (icon != null)
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  icon,
                  size: 48,
                  color: color,
                ),
              ),

            const SizedBox(height: 30),

            // Spinner
            SizedBox(
              width: 50,
              height: 50,
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(color),
                strokeWidth: 3,
              ),
            ),

            const SizedBox(height: 30),

            // Titre
            if (title != null)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 40),
                child: Text(
                  title!,
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF2D2D2D),
                  ),
                  textAlign: TextAlign.center,
                ),
              ),

            // Sous-titre
            if (subtitle != null) ...[
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 40),
                child: Text(
                  subtitle!,
                  style: GoogleFonts.openSans(
                    fontSize: 14,
                    color: Colors.grey.shade600,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
