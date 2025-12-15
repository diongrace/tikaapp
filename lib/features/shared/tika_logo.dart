import 'package:flutter/material.dart';

/// Widget réutilisable pour afficher le logo TIKA
/// Permet de centraliser l'affichage du logo dans toute l'application
class TikaLogo extends StatelessWidget {
  final double height;
  final double? width;

  const TikaLogo({
    super.key,
    this.height = 60,
    this.width,
  });

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      'lib/core/assets/logo_tika.png',
      height: height,
      width: width,
      fit: BoxFit.contain,
      errorBuilder: (context, error, stackTrace) {
        // En cas d'erreur, affiche le texte TIKA
        return Text(
          'TIKA',
          style: TextStyle(
            fontSize: height * 0.4,
            fontWeight: FontWeight.bold,
            color: const Color(0xFF9C27B0),
          ),
        );
      },
    );
  }
}
