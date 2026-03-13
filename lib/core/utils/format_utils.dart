/// Utilitaires de formatage partagés dans l'app
library format_utils;

/// Formate un montant avec séparateur d'espace (1 000 000)
String fmtAmount(dynamic value) {
  if (value == null) return '0';
  final n = value is num ? value : num.tryParse(value.toString()) ?? 0;
  final intVal = n.round();
  return intVal.toString().replaceAllMapped(
    RegExp(r'(\d)(?=(\d{3})+(?!\d))'),
    (m) => '${m[1]} ',
  );
}

/// FontSize adaptative selon la largeur de l'écran
/// [base] = taille sur un écran de référence 390px (iPhone 14)
double sp(double base, double screenWidth) {
  final scale = (screenWidth / 390).clamp(0.85, 1.25);
  return base * scale;
}
