import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

/// Widget de champ téléphone avec indicatif pays (+225 pour Côte d'Ivoire)
///
/// Utilisé dans les écrans d'authentification (login, register, otp)
class PhoneField extends StatelessWidget {
  final TextEditingController controller;
  final String? Function(String?)? validator;
  final bool enabled;
  final bool autofocus;
  final Function(String)? onChanged;
  final Function(String)? onSubmitted;
  final FocusNode? focusNode;

  const PhoneField({
    super.key,
    required this.controller,
    this.validator,
    this.enabled = true,
    this.autofocus = false,
    this.onChanged,
    this.onSubmitted,
    this.focusNode,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Numéro de téléphone *',
          style: GoogleFonts.openSans(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: TextFormField(
            controller: controller,
            keyboardType: TextInputType.phone,
            enabled: enabled,
            autofocus: autofocus,
            focusNode: focusNode,
            validator: validator ?? _defaultValidator,
            onChanged: onChanged,
            onFieldSubmitted: onSubmitted,
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
              LengthLimitingTextInputFormatter(10),
              _PhoneNumberFormatter(),
            ],
            decoration: InputDecoration(
              hintText: '07 00 00 00 00',
              hintStyle: GoogleFonts.openSans(
                fontSize: 14,
                color: Colors.grey.shade400,
              ),
              prefixIcon: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Drapeau Côte d'Ivoire
                    Container(
                      width: 28,
                      height: 20,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(2),
                        border: Border.all(color: Colors.grey.shade300, width: 0.5),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(2),
                        child: Row(
                          children: [
                            Expanded(
                              child: Container(color: const Color(0xFFFF8200)), // Orange
                            ),
                            Expanded(
                              child: Container(color: Colors.white), // Blanc
                            ),
                            Expanded(
                              child: Container(color: const Color(0xFF00A651)), // Vert
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '+225',
                      style: GoogleFonts.openSans(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                    ),
                    Container(
                      margin: const EdgeInsets.only(left: 8),
                      width: 1,
                      height: 24,
                      color: Colors.grey.shade300,
                    ),
                  ],
                ),
              ),
              filled: true,
              fillColor: enabled ? Colors.white : Colors.grey.shade100,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 16,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey.shade200, width: 1),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Color(0xFF8936A8), width: 2),
              ),
              errorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Colors.red, width: 1),
              ),
              focusedErrorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Colors.red, width: 2),
              ),
              disabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey.shade200, width: 1),
              ),
            ),
          ),
        ),
      ],
    );
  }

  /// Validateur par défaut pour les numéros ivoiriens
  String? _defaultValidator(String? value) {
    if (value == null || value.isEmpty) {
      return 'Veuillez entrer votre numéro de téléphone';
    }

    // Supprimer les espaces pour la validation
    final cleanNumber = value.replaceAll(' ', '');

    if (cleanNumber.length < 10) {
      return 'Le numéro doit contenir 10 chiffres';
    }

    // Vérifier que le numéro commence par un préfixe valide
    // 01, 05, 07 (Orange), 21, 25, 27 (MTN), 41, 45, 47 (Moov)
    final validPrefixes = ['01', '05', '07', '21', '25', '27', '41', '45', '47'];
    final prefix = cleanNumber.substring(0, 2);

    if (!validPrefixes.contains(prefix)) {
      return 'Numéro de téléphone invalide';
    }

    return null;
  }
}

/// Formatter pour afficher le numéro avec des espaces
/// Format: XX XX XX XX XX
class _PhoneNumberFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    // Supprimer tous les espaces
    final digitsOnly = newValue.text.replaceAll(' ', '');

    // Formater avec des espaces tous les 2 chiffres
    final buffer = StringBuffer();
    for (int i = 0; i < digitsOnly.length; i++) {
      if (i > 0 && i % 2 == 0) {
        buffer.write(' ');
      }
      buffer.write(digitsOnly[i]);
    }

    final formatted = buffer.toString();

    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}

/// Extension pour obtenir le numéro sans espaces
extension PhoneFieldExtension on TextEditingController {
  /// Récupère le numéro de téléphone sans espaces
  String get phoneNumber => text.replaceAll(' ', '');

  /// Récupère le numéro avec l'indicatif +225
  String get fullPhoneNumber => '+225${text.replaceAll(' ', '')}';
}
