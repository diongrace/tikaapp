import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Barre de recherche pour les produits
class SearchBarWidget extends StatelessWidget {
  final ValueChanged<String>? onSearchChanged;
  final ValueChanged<String>? onChanged;
  final TextEditingController? controller;

  const SearchBarWidget({
    super.key,
    this.onSearchChanged,
    this.onChanged,
    this.controller,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 44,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: TextField(
        controller: controller,
        onChanged: onSearchChanged ?? onChanged,
        decoration: InputDecoration(
          hintText: 'Rechercher un produit...',
          hintStyle: GoogleFonts.openSans(
            color: Colors.grey.shade400,
            fontSize: 13,
          ),
          prefixIcon: Icon(
            Icons.search,
            color: Colors.grey.shade400,
            size: 20,
          ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 12,
          ),
        ),
      ),
    );
  }
}
