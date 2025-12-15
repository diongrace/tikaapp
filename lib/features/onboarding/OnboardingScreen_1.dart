import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Page d'onboarding 1 : Trouver des boutiques adaptées à vos besoins
class OnboardingScreen1 extends StatelessWidget {
  const OnboardingScreen1({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Stack(
          children: [
            // Skip button en haut à droite
            Positioned(
              top: 16,
              right: 16,
              child: TextButton(
                onPressed: () {
                  // Skip to main screen
                  Navigator.pushReplacementNamed(context, '/home');
                },
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: const [
                  ],
                ),
              ),
            ),

            // Contenu principal
            Column(
              children: [
                // Image centrale avec logo et icônes
                Expanded(
                  flex: 6,
                  child: Container(
                    width: double.infinity,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 1.0),
                      child: Image.asset(
                        'lib/core/assets/boutqTika.jpeg',
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                ),

                // Section inférieure avec contenu centré
                Expanded(
                  flex: 4,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Icône document
                      Container(
                        width: 60,
                        height: 60,
                        decoration: BoxDecoration(
                          color: Colors.transparent,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          Icons.description_outlined,
                          color: Color(0xFFB932D6),
                          size: 50,
                        ),
                      ),

                      const SizedBox(height: 24),

                      // Texte descriptif
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 40.0),
                        child: Text(
                          'Trouver\nDes Boutiques\nAdaptées À Vos Besoins',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.openSans(
                            color: Color(0xFF670C88),
                            fontSize: 24,
                            fontWeight: FontWeight.w600,
                            height: 1.0,
                          ),
                        ),
                      ),

                      const SizedBox(height: 24),

                      // Indicateur de page
                      Container(
                        width: 40,
                        height: 3,
                        decoration: BoxDecoration(
                          color: Color(0xFFB932D6),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),

                      const SizedBox(height: 32),

                      // Bouton suivant
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 80.0),
                        child: InkWell(
                          onTap: () {
                            // Navigation vers la page 2
                            Navigator.pushReplacementNamed(context, '/onboarding-2');
                          },
                          borderRadius: BorderRadius.circular(100),
                          child: Container(
                            height: 50,
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [Color(0xFFD48EFC), Color(0xFF8936A8)],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius: BorderRadius.circular(100),
                              boxShadow: [
                                BoxShadow(
                                  color: Color(0xFF8936A8).withOpacity(0.4),
                                  blurRadius: 12,
                                  offset: Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Center(
                              child: const Text(
                                'suivant',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
