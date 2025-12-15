import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Écran de chargement élégant pour la boutique
class ShopLoadingScreen extends StatelessWidget {
  const ShopLoadingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF8936A8),
              Color(0xFFB24FD4),
              Color(0xFFD48EFC),
            ],
          ),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Logo TIKA avec animation pulse
              TweenAnimationBuilder(
                tween: Tween<double>(begin: 0.8, end: 1.0),
                duration: const Duration(milliseconds: 1200),
                curve: Curves.easeInOut,
                builder: (context, double scale, child) {
                  return Transform.scale(
                    scale: scale,
                    child: child,
                  );
                },
                onEnd: () {},
                child: Container(
                  width: 140,
                  height: 140,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.2),
                        blurRadius: 30,
                        spreadRadius: 5,
                      ),
                    ],
                  ),
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'TIKA',
                          style: GoogleFonts.poppins(
                            fontSize: 36,
                            fontWeight: FontWeight.bold,
                            foreground: Paint()
                              ..shader = const LinearGradient(
                                colors: [
                                  Color(0xFF8936A8),
                                  Color(0xFFB24FD4),
                                ],
                              ).createShader(const Rect.fromLTWH(0, 0, 200, 70)),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Container(
                          width: 60,
                          height: 3,
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [
                                Color(0xFF8936A8),
                                Color(0xFFD48EFC),
                              ],
                            ),
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 50),

              // Indicateur de chargement personnalisé
              SizedBox(
                width: 80,
                height: 80,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    // Cercle extérieur rotatif
                    const CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      strokeWidth: 3,
                    ),
                    // Icône boutique au centre
                    Container(
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.storefront_rounded,
                        color: Colors.white,
                        size: 28,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 40),

              // Texte avec animation de points
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Chargement',
                    style: GoogleFonts.poppins(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(width: 4),
                  const LoadingDots(),
                ],
              ),

              const SizedBox(height: 12),

              Text(
                'Bientôt votre boutique',
                style: GoogleFonts.openSans(
                  fontSize: 14,
                  color: Colors.white,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Widget d'animation des points de chargement
class LoadingDots extends StatefulWidget {
  const LoadingDots({super.key});

  @override
  State<LoadingDots> createState() => _LoadingDotsState();
}

class _LoadingDotsState extends State<LoadingDots> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(3, (index) {
            final delay = index * 0.2;
            final value = (_controller.value - delay) % 1.0;
            final opacity = (math.sin(value * math.pi * 2) * 0.5 + 0.5).clamp(0.3, 1.0);

            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 2),
              child: Text(
                '.',
                style: GoogleFonts.poppins(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.white.withOpacity(opacity),
                ),
              ),
            );
          }),
        );
      },
    );
  }
}
