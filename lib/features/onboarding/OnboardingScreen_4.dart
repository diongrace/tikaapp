import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Page d'onboarding 4 : Bénéficier d'une carte de fidélité
class OnboardingScreen4 extends StatelessWidget {
  const OnboardingScreen4({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Stack(
          children: [
            Column(
              children: [
                // Section supérieure avec image
                Expanded(
                  flex: 6,
                  child: Container(
                    width: double.infinity,
                    height: double.infinity,
                    child: Image.asset(
                      'lib/core/assets/mage.jpeg',
                      width: double.infinity,
                      height: double.infinity,
                      fit: BoxFit.cover,
                    ),
                  ),
                ),

                // Section inférieure blanche avec coins arrondis
                Expanded(
                  flex: 4,
                  child: Container(
                    width: double.infinity,
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(24),
                        topRight: Radius.circular(24),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black12,
                          blurRadius: 10,
                          offset: Offset(0, -2),
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Icône carte cadeau
                        const Icon(
                          Icons.card_giftcard,
                          color: Color(0xFF7B2CBF),
                          size: 60,
                        ),

                        const SizedBox(height: 24),

                        // Texte descriptif
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 40.0),
                          child: Text(
                            'Bénéficier D\'une Carte\nDe Fidélité',
                            textAlign: TextAlign.center,
                            style: GoogleFonts.openSans(
                              color: const Color(0xFF670C88),
                              fontSize: 24,
                              fontWeight: FontWeight.w600,
                              height: 1.2,
                            ),
                          ),
                        ),

                        const SizedBox(height: 24),

                        // Indicateur de page
                        Container(
                          width: 40,
                          height: 3,
                          decoration: BoxDecoration(
                            color: const Color(0xFFB932D6),
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),

                        const SizedBox(height: 32),

                        // Bouton suivant (dernière page - va vers access boutique)
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 80.0),
                          child: InkWell(
                            onTap: () {
                              // Navigation vers l'écran d'accès boutique
                              Navigator.pushReplacementNamed(context, '/access-boutique');
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
                                    color: const Color(0xFF8936A8).withOpacity(0.4),
                                    blurRadius: 12,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: const Center(
                                child: Text(
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
                      ],
                    ),
                  ),
                ),
              ],
            ),

            // Bouton Skip en haut à droite
            Positioned(
              top: 16,
              right: 16,
              child: TextButton(
                onPressed: () {
                  Navigator.pushReplacementNamed(context, '/home');
                },
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [

                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
