import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'offer_product_screen.dart';
import 'purchase_card_screen.dart';
import 'sent_gifts_screen.dart';
import 'gift_order_track_screen.dart';
import 'gift_card_track_screen.dart';
import '../../../services/models/shop_model.dart';

class GiftBottomSheet extends StatelessWidget {
  final Shop? currentShop;
  const GiftBottomSheet({super.key, this.currentShop});

  static void show(BuildContext context, {Shop? currentShop}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withOpacity(0.4),
      builder: (_) => GiftBottomSheet(currentShop: currentShop),
    );
  }

  Widget _secondaryBtn(BuildContext context, {
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withOpacity(0.2)),
        ),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          FaIcon(icon, color: color, size: 16),
          const SizedBox(height: 4),
          Text(label, style: GoogleFonts.inriaSerif(
            fontSize: 11, fontWeight: FontWeight.w700, color: color),
            textAlign: TextAlign.center),
        ]),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.fromLTRB(20, 12, 20, MediaQuery.of(context).padding.bottom + 20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle
          Container(
            width: 40, height: 4,
            margin: const EdgeInsets.only(bottom: 20),
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // Title
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('🎁', style: TextStyle(fontSize: 22)),
              const SizedBox(width: 8),
              Text('Faire un cadeau',
                style: GoogleFonts.inriaSerif(
                  fontSize: 20, fontWeight: FontWeight.w800,
                  color: const Color(0xFF1C1C1E),
                )),
            ],
          ),
          const SizedBox(height: 24),

          // Offrir un produit
          GestureDetector(
            onTap: () {
              Navigator.pop(context);
              OfferProductScreen.show(context, currentShop: currentShop);
            },
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFFE91E8C), Color(0xFFFF5252)],
                  begin: Alignment.centerLeft, end: Alignment.centerRight,
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [BoxShadow(
                  color: const Color(0xFFE91E8C).withOpacity(0.3),
                  blurRadius: 12, offset: const Offset(0, 4))],
              ),
              child: Row(children: [
                const FaIcon(FontAwesomeIcons.gift, color: Colors.white, size: 28),
                const SizedBox(width: 14),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('Offrir un produit', style: GoogleFonts.inriaSerif(
                    fontSize: 16, fontWeight: FontWeight.w800, color: Colors.white)),
                  Text('Choisissez un produit et offrez-le',
                    style: GoogleFonts.inriaSerif(fontSize: 13, color: Colors.white70)),
                ])),
              ]),
            ),
          ),
          const SizedBox(height: 12),

          // Carte d'achat
          GestureDetector(
            onTap: () {
              Navigator.pop(context);
              PurchaseCardScreen.show(context, currentShop: currentShop);
            },
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 20),
              decoration: BoxDecoration(
                color: const Color(0xFF6B21A8),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [BoxShadow(
                  color: const Color(0xFF6B21A8).withOpacity(0.3),
                  blurRadius: 12, offset: const Offset(0, 4))],
              ),
              child: Row(children: [
                const FaIcon(FontAwesomeIcons.creditCard, color: Colors.white, size: 28),
                const SizedBox(width: 14),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text("Carte d'achat", style: GoogleFonts.inriaSerif(
                    fontSize: 16, fontWeight: FontWeight.w800, color: Colors.white)),
                  Text("Offrez un montant à dépenser en boutique",
                    style: GoogleFonts.inriaSerif(fontSize: 13, color: Colors.white70)),
                ])),
              ]),
            ),
          ),
          const SizedBox(height: 12),

          // Suivi & historique row
          Row(children: [
            Expanded(child: _secondaryBtn(
              context,
              icon: FontAwesomeIcons.magnifyingGlass,
              label: 'Suivi cadeau',
              color: const Color(0xFF0284C7),
              onTap: () {
                Navigator.pop(context);
                GiftOrderTrackScreen.show(context);
              },
            )),
            const SizedBox(width: 10),
            Expanded(child: _secondaryBtn(
              context,
              icon: FontAwesomeIcons.clockRotateLeft,
              label: 'Mes cadeaux',
              color: const Color(0xFF7C3AED),
              onTap: () {
                Navigator.pop(context);
                SentGiftsScreen.show(context);
              },
            )),
            const SizedBox(width: 10),
            Expanded(child: _secondaryBtn(
              context,
              icon: FontAwesomeIcons.creditCard,
              label: 'Suivi carte',
              color: const Color(0xFF6B21A8),
              onTap: () {
                Navigator.pop(context);
                GiftCardTrackScreen.show(context);
              },
            )),
          ]),

          const SizedBox(height: 16),

          // Annuler
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 14),
              child: Text('Annuler',
                textAlign: TextAlign.center,
                style: GoogleFonts.inriaSerif(
                  fontSize: 15, color: Colors.grey.shade600, fontWeight: FontWeight.w600)),
            ),
          ),
        ],
      ),
    );
  }
}
