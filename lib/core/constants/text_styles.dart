import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'colors.dart';

/// Classe contenant tous les styles de texte utilisés dans l'application TIKA
/// Centralise les styles pour une gestion cohérente et éviter la répétition
class AppTextStyles {
  // Styles pour les titres
  static TextStyle get appBarTitle => GoogleFonts.inriaSerif(
        fontSize: 16,
        fontWeight: FontWeight.w500,
        color: AppColors.textSecondary,
      );

  static TextStyle get heading1 => GoogleFonts.inriaSerif(
        fontSize: 28,
        fontWeight: FontWeight.bold,
        color: AppColors.text,
      );

  static TextStyle get heading2 => GoogleFonts.inriaSerif(
        fontSize: 24,
        fontWeight: FontWeight.bold,
        color: AppColors.text,
      );

  static TextStyle get heading3 => GoogleFonts.inriaSerif(
        fontSize: 20,
        fontWeight: FontWeight.bold,
        color: AppColors.text,
      );

  // Styles pour les sous-titres
  static TextStyle get subtitle1 => GoogleFonts.inriaSerif(
        fontSize: 16,
        color: AppColors.textSecondary,
      );

  static TextStyle get subtitle2 => GoogleFonts.inriaSerif(
        fontSize: 14,
        color: AppColors.textSecondary,
      );

  static TextStyle get tagline => GoogleFonts.inriaSerif(
        fontSize: 18,
        fontWeight: FontWeight.w500,
        color: AppColors.text,
      );

  // Styles pour le corps de texte
  static TextStyle get bodyLarge => GoogleFonts.inriaSerif(
        fontSize: 16,
        color: AppColors.text,
      );

  static TextStyle get bodyMedium => GoogleFonts.inriaSerif(
        fontSize: 14,
        color: AppColors.text,
      );

  static TextStyle get bodySmall => GoogleFonts.inriaSerif(
        fontSize: 12,
        color: AppColors.text,
      );

  // Styles pour les boutons
  static TextStyle get buttonLarge => GoogleFonts.inriaSerif(
        fontSize: 18,
        fontWeight: FontWeight.bold,
        color: Colors.white,
      );

  static TextStyle get buttonMedium => GoogleFonts.inriaSerif(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: Colors.white,
      );

  static TextStyle get buttonSmall => GoogleFonts.inriaSerif(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: Colors.white,
      );

  // Styles pour les labels
  static TextStyle get label => GoogleFonts.inriaSerif(
        fontSize: 14,
        fontWeight: FontWeight.w500,
        color: AppColors.text,
      );

  static TextStyle get labelBold => GoogleFonts.inriaSerif(
        fontSize: 14,
        fontWeight: FontWeight.bold,
        color: AppColors.text,
      );

  // Styles spécifiques
  static TextStyle get sectionTitle => GoogleFonts.inriaSerif(
        fontSize: 22,
        fontWeight: FontWeight.bold,
        color: AppColors.text,
      );

  static TextStyle get hint => GoogleFonts.inriaSerif(
        fontSize: 14,
        color: AppColors.textSecondary.withOpacity(0.5),
      );

  // Style pour le texte blanc
  static TextStyle get whiteText => GoogleFonts.inriaSerif(
        fontSize: 14,
        color: Colors.white,
      );

  static TextStyle get whiteTextBold => GoogleFonts.inriaSerif(
        fontSize: 16,
        fontWeight: FontWeight.bold,
        color: Colors.white,
      );
}
