import 'package:flutter/material.dart';

/// Utilitaire pour adapter les layouts (pas les tailles d'elements)
/// Principes : tailles fixes pour boutons/icones/textes, layouts adaptatifs
class Responsive {
  static double screenWidth(BuildContext context) =>
      MediaQuery.of(context).size.width;

  /// Telephone : largeur < 600
  static bool isPhone(BuildContext context) => screenWidth(context) < 600;

  /// Tablette : largeur entre 600 et 900
  static bool isTablet(BuildContext context) =>
      screenWidth(context) >= 600 && screenWidth(context) < 900;

  /// Grande tablette / paysage : largeur >= 900
  static bool isLargeTablet(BuildContext context) =>
      screenWidth(context) >= 900;

  /// Nombre de colonnes pour les grilles de produits
  static int gridColumns(BuildContext context) {
    final width = screenWidth(context);
    if (width >= 900) return 4;
    if (width >= 600) return 3;
    return 2;
  }

  /// Padding horizontal fixe par breakpoint
  static double horizontalPadding(BuildContext context) {
    final width = screenWidth(context);
    if (width >= 900) return 32;
    if (width >= 600) return 24;
    return 16;
  }

  /// Padding d'ecran adapte par breakpoint
  static EdgeInsets screenPadding(BuildContext context) {
    final h = horizontalPadding(context);
    return EdgeInsets.symmetric(horizontal: h, vertical: 12);
  }
}
