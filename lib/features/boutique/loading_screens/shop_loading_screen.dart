import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Écran de chargement professionnel pour la boutique
class ShopLoadingScreen extends StatefulWidget {
  const ShopLoadingScreen({super.key});

  @override
  State<ShopLoadingScreen> createState() => _ShopLoadingScreenState();
}

class _ShopLoadingScreenState extends State<ShopLoadingScreen>
    with TickerProviderStateMixin {
  late AnimationController _cartController;
  late AnimationController _bounceController;
  late AnimationController _wheelController;
  late AnimationController _pulseController;
  late AnimationController _textFadeController;
  late Animation<double> _cartAnimation;
  late Animation<double> _bounceAnimation;
  late Animation<double> _pulseAnimation;
  late Animation<double> _textFadeAnimation;

  // Couleur principale
  static const Color primaryColor = Color(0xFFB932D6);
  static const Color primaryLight = Color(0xFFB932D6);
  static const Color primaryDark = Color(0xFFB932D6);

  @override
  void initState() {
    super.initState();

    // Animation du chariot qui se déplace
    _cartController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2500),
    )..repeat();

    _cartAnimation = Tween<double>(begin: -0.3, end: 1.3).animate(
      CurvedAnimation(parent: _cartController, curve: Curves.easeInOut),
    );

    // Animation de rebond vertical
    _bounceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    )..repeat(reverse: true);

    _bounceAnimation = Tween<double>(begin: 0, end: -5).animate(
      CurvedAnimation(parent: _bounceController, curve: Curves.easeInOut),
    );

    // Animation des roues
    _wheelController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    )..repeat();

    // Animation pulse pour le cercle de chargement
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.15).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    // Animation fade pour le texte
    _textFadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);

    _textFadeAnimation = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(parent: _textFadeController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _cartController.dispose();
    _bounceController.dispose();
    _wheelController.dispose();
    _pulseController.dispose();
    _textFadeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const SizedBox(height: 20),

                // Charrette animée en haut
                _buildAnimatedCart(),

                const SizedBox(height: 50),

                // Logo TIKA au centre
                _buildLogo(),

                const SizedBox(height: 50),

                // Cercle de chargement stylé
                _buildLoadingCircle(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLogo() {
    return Column(
      children: [
        // Nom TIKA avec effet
        ShaderMask(
          shaderCallback: (bounds) => LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              primaryLight,
              primaryColor,
              primaryDark,
            ],
          ).createShader(bounds),
          child: Text(
            'TIKA',
            style: GoogleFonts.poppins(
              fontSize: 56,
              fontWeight: FontWeight.w900,
              color: Colors.white,
              letterSpacing: 12,
              shadows: [
                Shadow(
                  color: primaryColor.withOpacity(0.3),
                  offset: const Offset(0, 4),
                  blurRadius: 8,
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        // Ligne décorative
        Container(
          width: 60,
          height: 3,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                primaryColor.withOpacity(0.3),
                primaryColor,
                primaryColor.withOpacity(0.3),
              ],
            ),
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(height: 16),
        // Sous-titre
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                primaryColor.withOpacity(0.08),
                primaryColor.withOpacity(0.15),
                primaryColor.withOpacity(0.08),
              ],
            ),
            borderRadius: BorderRadius.circular(25),
            border: Border.all(
              color: primaryColor.withOpacity(0.2),
              width: 1,
            ),
          ),
          child: Text(
            'Votre boutique',
            style: GoogleFonts.inter(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: primaryColor,
              letterSpacing: 1,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAnimatedCart() {
    return SizedBox(
      height: 120,
      width: double.infinity,
      child: AnimatedBuilder(
        animation: Listenable.merge([_cartAnimation, _bounceAnimation]),
        builder: (context, child) {
          return LayoutBuilder(
            builder: (context, constraints) {
              final cartX = _cartAnimation.value * constraints.maxWidth - 60;

              return Stack(
                clipBehavior: Clip.none,
                children: [
                  // Ligne de sol avec gradient
                  Positioned(
                    bottom: 8,
                    left: 20,
                    right: 20,
                    child: Container(
                      height: 2,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Colors.transparent,
                            primaryColor.withOpacity(0.3),
                            primaryColor.withOpacity(0.3),
                            Colors.transparent,
                          ],
                          stops: const [0.0, 0.2, 0.8, 1.0],
                        ),
                      ),
                    ),
                  ),

                  // Charrette
                  Positioned(
                    left: cartX,
                    bottom: 10 + _bounceAnimation.value,
                    child: _buildCart(),
                  ),
                ],
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildCart() {
    return SizedBox(
      width: 110,
      height: 90,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // Ombre du chariot
          Positioned(
            bottom: 2,
            left: 15,
            child: Container(
              width: 70,
              height: 8,
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),

          // Corps du chariot
          Positioned(
            bottom: 18,
            left: 10,
            child: Container(
              width: 75,
              height: 50,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    primaryLight,
                    primaryColor,
                  ],
                ),
                borderRadius: BorderRadius.circular(8),
                boxShadow: [
                  BoxShadow(
                    color: primaryColor.withOpacity(0.4),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: CustomPaint(
                  painter: CartGridPainter(),
                ),
              ),
            ),
          ),

          // Articles dans le chariot
          Positioned(
            bottom: 48,
            left: 16,
            child: Icon(
              Icons.checkroom,
              color: Colors.white.withOpacity(0.95),
              size: 16,
            ),
          ),
          Positioned(
            bottom: 52,
            left: 36,
            child: Icon(
              Icons.shopping_bag,
              color: Colors.white.withOpacity(0.95),
              size: 18,
            ),
          ),
          Positioned(
            bottom: 46,
            left: 56,
            child: Icon(
              Icons.card_giftcard,
              color: Colors.white.withOpacity(0.95),
              size: 14,
            ),
          ),

          // Poignée du chariot
          Positioned(
            bottom: 50,
            right: 8,
            child: Container(
              width: 22,
              height: 4,
              decoration: BoxDecoration(
                color: primaryDark,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          Positioned(
            bottom: 32,
            right: 8,
            child: Container(
              width: 4,
              height: 22,
              decoration: BoxDecoration(
                color: primaryDark,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),

          // Roues
          Positioned(
            bottom: 4,
            left: 18,
            child: _buildWheel(),
          ),
          Positioned(
            bottom: 4,
            left: 62,
            child: _buildWheel(),
          ),
        ],
      ),
    );
  }

  Widget _buildWheel() {
    return AnimatedBuilder(
      animation: _wheelController,
      builder: (context, child) {
        return Transform.rotate(
          angle: _wheelController.value * 2 * math.pi,
          child: Container(
            width: 16,
            height: 16,
            decoration: BoxDecoration(
              gradient: RadialGradient(
                colors: [
                  primaryLight,
                  primaryDark,
                ],
              ),
              shape: BoxShape.circle,
              border: Border.all(
                color: primaryColor,
                width: 2,
              ),
              boxShadow: [
                BoxShadow(
                  color: primaryColor.withOpacity(0.3),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Center(
              child: Container(
                width: 4,
                height: 4,
                decoration: const BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildLoadingCircle() {
    return Column(
      children: [
        // Cercle de chargement avec pulse
        AnimatedBuilder(
          animation: _pulseAnimation,
          builder: (context, child) {
            return Transform.scale(
              scale: _pulseAnimation.value,
              child: Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: primaryColor.withOpacity(0.25),
                      blurRadius: 25,
                      spreadRadius: 5,
                    ),
                  ],
                ),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    // Cercle de fond
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white,
                        border: Border.all(
                          color: primaryColor.withOpacity(0.15),
                          width: 3,
                        ),
                      ),
                    ),
                    // Indicateur de chargement
                    SizedBox(
                      width: 70,
                      height: 70,
                      child: CircularProgressIndicator(
                        strokeWidth: 4,
                        valueColor: AlwaysStoppedAnimation<Color>(primaryColor),
                        backgroundColor: primaryColor.withOpacity(0.12),
                      ),
                    ),
                    // Icône boutique
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: primaryColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        Icons.store,
                        color: primaryColor,
                        size: 24,
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),

        const SizedBox(height: 25),

        // Texte de chargement animé
        AnimatedBuilder(
          animation: _textFadeAnimation,
          builder: (context, child) {
            return Opacity(
              opacity: _textFadeAnimation.value,
              child: Text(
                'Chargement en cours...',
                style: GoogleFonts.inter(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: primaryColor,
                  letterSpacing: 0.5,
                ),
              ),
            );
          },
        ),

        const SizedBox(height: 8),

        Text(
          'Nous preparons votre experience',
          style: GoogleFonts.inter(
            fontSize: 12,
            fontWeight: FontWeight.w400,
            color: primaryColor.withOpacity(0.6),
          ),
        ),
      ],
    );
  }
}

/// Painter pour dessiner la grille du chariot
class CartGridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.25)
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke;

    // Lignes verticales
    for (var i = 1; i < 4; i++) {
      final x = size.width * i / 4;
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }

    // Lignes horizontales
    for (var i = 1; i < 3; i++) {
      final y = size.height * i / 3;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
