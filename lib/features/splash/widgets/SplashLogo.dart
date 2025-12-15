import 'package:flutter/material.dart';
import 'dart:math' as math;
import '../../../core/constants/colors.dart';

class SplashLogo extends StatefulWidget {
  const SplashLogo({super.key});

  @override
  State<SplashLogo> createState() => _SplashLogoState();
}

class _SplashLogoState extends State<SplashLogo>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 6),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  final String assetPath = 'lib/core/assets/logo_tika.png';

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        return SizedBox(
          width: 300,
          height: 300,
          child: Stack(
            alignment: Alignment.center,
            children: [
              // ===== ARC EXTÉRIEUR =====
              Transform.rotate(
                angle: _controller.value * 2 * math.pi,
                child: CustomPaint(
                  size: const Size(300, 300),
                  painter: FadeArcPainter(
                    radius: 75, // espace augmenté entre logo et cercle
                    strokeWidth: 2.7,
                    startAngle: -math.pi / 2.8,
                    sweepAngle: 1.55 * math.pi,
                    gradientColors: const [
                      Color.fromARGB(255, 153, 5, 176),
                      Color.fromARGB(25, 59, 1, 63),
                    ],
                    fadeOut: true,
                    glowOpacity: 0.25,
                  ),
                ),
              ),

              // ===== ARC INTÉRIEUR =====
              Transform.rotate(
                angle: -_controller.value * 2 * math.pi,
                child: CustomPaint(
                  size: const Size(210, 210),
                  painter: FadeArcPainter(
                    radius: 105, // espace augmenté entre logo et cercle
                    strokeWidth: 3.6,
                    startAngle: math.pi / 3.9,
                    sweepAngle: 1.5 * math.pi,
                    gradientColors: const [
                      Color.fromARGB(0, 202, 111, 255),
                      Color.fromARGB(203, 110, 14, 212),
                    ],
                    fadeOut: true,
                    glowOpacity: 0.20,
                  ),
                ),
              ),

              // ===== LOGO CENTRAL =====
              Image.asset(
                assetPath,
                width: 120,
                height: 120,
                fit: BoxFit.contain,
              ),
            ],
          ),
        );
      },
    );
  }
}

/// Peint un arc fin avec dégradé + estompe douce à la fin + point lumineux fondu
class FadeArcPainter extends CustomPainter {
  final double radius;
  final double strokeWidth;
  final double startAngle;
  final double sweepAngle;
  final List<Color> gradientColors;
  final bool fadeOut;
  final double glowOpacity;

  FadeArcPainter({
    required this.radius,
    required this.strokeWidth,
    required this.startAngle,
    required this.sweepAngle,
    required this.gradientColors,
    this.fadeOut = true,
    this.glowOpacity = 0.3,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final rect = Rect.fromCircle(center: center, radius: radius);

    // Crée un dégradé circulaire avec fondu doux sur les bords
    final List<Color> colors = fadeOut
        ? [
            gradientColors.first.withOpacity(0.0),
            gradientColors.first,
            gradientColors.last,
            gradientColors.last.withOpacity(0.0),
          ]
        : gradientColors;

    final List<double> stops = [0.0, 0.1, 0.9, 1.0];

    final Paint arcPaint = Paint()
      ..shader = SweepGradient(
        startAngle: 0,
        endAngle: 2 * math.pi,
        colors: colors,
        stops: stops,
      ).createShader(rect)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(rect, startAngle, sweepAngle, false, arcPaint);

    // Point lumineux à la fin
    final double endAngle = startAngle + sweepAngle;
    final Offset dotPos = Offset(
      center.dx + radius * math.cos(endAngle),
      center.dy + radius * math.sin(endAngle),
    );

    final Paint glowPaint = Paint()
      ..color = gradientColors.last.withOpacity(glowOpacity)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);
    canvas.drawCircle(dotPos, strokeWidth * 2.2, glowPaint);

    final Paint dotPaint = Paint()..color = gradientColors.last.withOpacity(0.9);
    canvas.drawCircle(dotPos, strokeWidth * 1.2, dotPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
