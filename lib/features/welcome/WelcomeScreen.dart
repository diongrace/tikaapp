import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key});

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen> {
  double opacity = 0;
  Offset offset = const Offset(0, 0.3); // Texte légèrement vers le bas

  @override
  void initState() {
    super.initState();

    // Lancement de l'animation après 200ms
    Future.delayed(const Duration(milliseconds: 200), () {
      setState(() {
        opacity = 1;
        offset = Offset.zero; // Remonte vers sa position normale
      });
    });

    // Navigation après 4 secondes
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) {
        Navigator.pushReplacementNamed(context, '/onboarding-1');
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF670C88),
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                AnimatedSlide(
                  duration: const Duration(milliseconds: 800),
                  curve: Curves.easeOut,
                  offset: offset,
                  child: AnimatedOpacity(
                    duration: const Duration(milliseconds: 800),
                    opacity: opacity,
                    child: Text(
                      'Bienvenue Sur TIKA',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.openSans(
                        color: Colors.white,
                        fontSize: 25,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 10),

                AnimatedSlide(
                  duration: const Duration(milliseconds: 1000),
                  curve: Curves.easeOut,
                  offset: offset,
                  child: AnimatedOpacity(
                    duration: const Duration(milliseconds: 1000),
                    opacity: opacity,
                    child: Text(
                      'L\'App Qui Vous Simplifie La Vie.',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.openSans(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w400,
                        fontStyle: FontStyle.italic,
                        letterSpacing: 0.3,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
