import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../services/models/loyalty_card_model.dart';

/// Widget partagé pour afficher une carte de fidélité en liste.
/// Utilisé dans profile_screen.dart et access_boutique_screen.dart.
class LoyaltyCardListItem extends StatelessWidget {
  final LoyaltyCard card;
  final int index;
  final VoidCallback onTap;

  const LoyaltyCardListItem({
    super.key,
    required this.card,
    required this.index,
    required this.onTap,
  });

  static const _accentColors = [
    Color(0xFF8936A8),
    Color(0xFF1A73E8),
    Color(0xFF00897B),
    Color(0xFFF57C00),
    Color(0xFFE91E63),
    Color(0xFF0288D1),
  ];

  Color get _accent => _accentColors[index % _accentColors.length];

  /// Couleur fixe selon le niveau de fidélité
  Color get _tierColor {
    switch (card.tier.toLowerCase()) {
      case 'silver':   return const Color(0xFF78909C); // Gris acier
      case 'gold':     return const Color(0xFFFFB300); // Or
      case 'platinum': return const Color(0xFF546E7A); // Gris platine
      default:         return const Color(0xFF8D6E63); // Bronze brun
    }
  }

  Widget _buildLogo() {
    final hasLogo = card.shopLogo != null && card.shopLogo!.isNotEmpty;
    final initial = card.shopName.isNotEmpty ? card.shopName[0].toUpperCase() : '?';

    if (hasLogo) {
      final logoUrl = card.shopLogo!.startsWith('http')
          ? card.shopLogo!
          : 'https://prepro.tika-ci.com/storage/${card.shopLogo!}';
      return Container(
        width: 46, height: 46,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade200),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 6)],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(11),
          child: Image.network(logoUrl, fit: BoxFit.contain, width: 46, height: 46,
            errorBuilder: (_, __, ___) => _buildFallback(initial)),
        ),
      );
    }
    return _buildFallback(initial);
  }

  Widget _buildFallback(String initial) {
    return Container(
      width: 46, height: 46,
      decoration: BoxDecoration(
        color: _accent.withOpacity(0.12),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Center(child: Text(initial, style: GoogleFonts.inriaSerif(
        fontSize: 18, fontWeight: FontWeight.bold, color: _accent))),
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8, offset: const Offset(0, 2))],
        ),
        child: Row(children: [
          // Barre accent gauche
          Container(
            width: 5, height: 72,
            decoration: BoxDecoration(
              color: _accent,
              borderRadius: const BorderRadius.horizontal(left: Radius.circular(16)),
            ),
          ),
          const SizedBox(width: 14),
          // Logo
          _buildLogo(),
          const SizedBox(width: 14),
          // Infos
          Expanded(child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(card.shopName,
                style: GoogleFonts.inriaSerif(
                  fontSize: 14, fontWeight: FontWeight.w700,
                  color: const Color(0xFF1C1C1E)),
                maxLines: 1, overflow: TextOverflow.ellipsis),
              const SizedBox(height: 3),
              Text(
                '${card.points} pt${card.points > 1 ? 's' : ''}',
                style: GoogleFonts.inriaSerif(
                  fontSize: 12, color: Colors.grey.shade500)),
            ],
          )),
          // Tier badge — couleur fixe selon le niveau
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: _tierColor.withOpacity(0.12),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(card.tierLabel,
              style: GoogleFonts.inriaSerif(
                fontSize: 10, fontWeight: FontWeight.w800, color: _tierColor)),
          ),
          const SizedBox(width: 8),
          Icon(Icons.chevron_right_rounded, color: Colors.grey.shade400, size: 20),
          const SizedBox(width: 12),
        ]),
      ),
    );
  }
}
