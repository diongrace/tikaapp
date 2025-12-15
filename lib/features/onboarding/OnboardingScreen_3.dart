import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class OnboardingScreen3 extends StatelessWidget {
  const OnboardingScreen3({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Stack(
          children: [
            Column(
              children: [
                // Image du livreur
                Expanded(
                  flex: 6,
                  child: Image.asset(
                    'lib/core/assets/livreur.jpg',
                    width: double.infinity,
                    fit: BoxFit.cover,
                  ),
                ),

                // Section inférieure qui couvre toute la partie basse
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
                        const Icon(
                          Icons.two_wheeler,
                          color: Color(0xFF7B2CBF),
                          size: 60,
                        ),
                        const SizedBox(height: 24),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 40.0),
                          child: Text(
                            'Suivez Vos\nLivraisons En\nTemps Réel',
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
                        Container(
                          width: 40,
                          height: 3,
                          decoration: BoxDecoration(
                            color: Color(0xFFB932D6),
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                        const SizedBox(height: 32),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 80.0),
                          child: InkWell(
                            onTap: () {
                              Navigator.pushReplacementNamed(context, '/onboarding-4');
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
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: const [
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
