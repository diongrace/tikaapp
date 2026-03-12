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
        color: const Color(0xFFF5F5F5),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.grey.shade300, width: 1.5),
      ),
      child: TextField(
        controller: controller,
        onChanged: onSearchChanged ?? onChanged,
        style: GoogleFonts.inriaSerif(
          color: Colors.black87,
          fontSize: 15,
        ),
        decoration: InputDecoration(
          hintText: 'Rechercher un produit...',
          hintStyle: GoogleFonts.inriaSerif(
            color: Colors.grey.shade600,
            fontSize: 15,
          ),
          prefixIcon: Icon(
            Icons.search,
            color: Colors.grey.shade800,
            size: 22,
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
