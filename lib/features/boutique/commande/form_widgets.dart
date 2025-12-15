import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/services/boutique_theme_provider.dart';

/// Widget pour créer un champ de formulaire stylisé
class FormFieldWidget extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String hint;
  final IconData icon;
  final bool required;
  final TextInputType keyboardType;
  final int maxLines;
  final int? maxLength;
  final String? Function(String?)? validator;
  final List<TextInputFormatter>? inputFormatters;

  const FormFieldWidget({
    super.key,
    required this.controller,
    required this.label,
    required this.hint,
    required this.icon,
    this.required = true,
    this.keyboardType = TextInputType.text,
    this.maxLines = 1,
    this.maxLength,
    this.validator,
    this.inputFormatters,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          required ? '$label *' : label,
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
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: TextFormField(
            controller: controller,
            keyboardType: keyboardType,
            maxLines: maxLines,
            minLines: 1,
            maxLength: maxLength,
            validator: validator,
            inputFormatters: inputFormatters,
            buildCounter: maxLength != null
                ? (context, {required currentLength, required isFocused, maxLength}) {
                    return Text(
                      '$currentLength/$maxLength',
                      style: GoogleFonts.openSans(
                        fontSize: 12,
                        color: currentLength == maxLength
                            ? const Color(0xFF4CAF50)
                            : Colors.grey.shade600,
                      ),
                    );
                  }
                : null,
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: GoogleFonts.openSans(
                fontSize: 14,
                color: Colors.grey.shade400,
              ),
              prefixIcon: Icon(icon, color: Colors.grey.shade600, size: 22),
              filled: true,
              fillColor: Colors.white,
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
                borderSide: BorderSide(color: BoutiqueThemeProvider.of(context).primary, width: 2),
              ),
              errorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Colors.red, width: 1),
              ),
              focusedErrorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Colors.red, width: 2),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// Widget pour afficher un indicateur d'étape professionnel avec icône
class StepIndicator extends StatelessWidget {
  final int step;
  final String label;
  final bool isActive;
  final VoidCallback? onTap;

  const StepIndicator({
    super.key,
    required this.step,
    required this.label,
    required this.isActive,
    this.onTap,
  });

  IconData _getIconForStep(int step) {
    switch (step) {
      case 1:
        return Icons.person_outline;
      case 2:
        return Icons.shopping_bag_outlined;
      case 3:
        return Icons.payment;
      default:
        return Icons.check_circle_outline;
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: MouseRegion(
        cursor: onTap != null ? SystemMouseCursors.click : SystemMouseCursors.basic,
        child: Column(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                gradient: isActive
                    ? LinearGradient(
                        colors: [BoutiqueThemeProvider.of(context).primary, BoutiqueThemeProvider.of(context).primary],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      )
                    : null,
                color: isActive ? null : Colors.grey.shade200,
                shape: BoxShape.circle,
                boxShadow: isActive
                    ? [
                        BoxShadow(
                          color: BoutiqueThemeProvider.of(context).primary.withOpacity(0.3),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ]
                    : null,
              ),
              child: Icon(
                isActive ? Icons.check : _getIconForStep(step),
                size: 24,
                color: isActive ? Colors.white : Colors.grey.shade500,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: GoogleFonts.openSans(
                fontSize: 12,
                fontWeight: isActive ? FontWeight.bold : FontWeight.w500,
                color: isActive ? BoutiqueThemeProvider.of(context).primary : Colors.grey.shade600,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

/// Widget pour la ligne entre les étapes
class StepLine extends StatelessWidget {
  final bool isActive;

  const StepLine({
    super.key,
    required this.isActive,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 2,
      margin: const EdgeInsets.only(bottom: 30),
      color: isActive ? BoutiqueThemeProvider.of(context).primary : Colors.grey.shade300,
    );
  }
}

/// Widget pour afficher une ligne de résumé avec icône
class SummaryRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const SummaryRow({
    super.key,
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: BoutiqueThemeProvider.of(context).primary.withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, size: 20, color: BoutiqueThemeProvider.of(context).primary),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: GoogleFonts.openSans(
                  fontSize: 12,
                  color: Colors.grey.shade600,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: GoogleFonts.openSans(
                  fontSize: 14,
                  color: Colors.black87,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
