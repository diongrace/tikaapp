import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Page d'onboarding 1 : Trouver des boutiques adaptées à vos besoins
class OnboardingScreen1 extends StatelessWidget {
  const OnboardingScreen1({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Container(
        decoration: BoxDecoration(
          image: DecorationImage(
            image: AssetImage('lib/core/assets/Shoponline.jpg'),
            fit: BoxFit.cover,
          ),
        ),
        child: Column(
          children: [
            // Espace pour l'image de fond (partie supérieure)
            const Spacer(flex: 5),

            // Container blanc arrondi en bas
            Container(
              width: double.infinity,
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(30),
                  topRight: Radius.circular(30),
                ),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 30),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Icône document
                  Icon(
                    Icons.description_outlined,
                    color: Color(0xFFB932D6),
                    size: 50,
                  ),

                  const SizedBox(height: 20),

                  // Texte descriptif
                  Text(
                    'Trouver\nDes Boutiques\nAdaptées À Vos Besoins',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.openSans(
                      color: Color(0xFF670C88),
                      fontSize: 24,
                      fontWeight: FontWeight.w600,
                      height: 1.3,
                    ),
                  ),

                  const SizedBox(height: 20),

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
                          padding: const EdgeInsets.symmetric(horizontal: 40.0),
                          child: InkWell(
                            onTap: () {
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
      ),
    );
  }
}
