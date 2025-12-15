import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../../../../services/models/shop_model.dart';
import '../widgets/search_bar_widget.dart';
import '../../commande/orders_list_api_page.dart';

/// Dialogues pour l'écran d'accueil
class HomeDialogs {
  /// Afficher le dialogue de recherche
  static void showSearchDialog({
    required BuildContext context,
    required Shop? currentShop,
    required TextEditingController searchController,
    required Function(String) onSearchChanged,
  }) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Poignée de glissement
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 20),

              // Titre
              Text(
                'Rechercher un produit',
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 20),

              // Barre de recherche
              SearchBarWidget(
                controller: searchController,
                onSearchChanged: onSearchChanged,
              ),

              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  /// Afficher le bottom sheet avec les actions rapides
  static void showActionsBottomSheet({
    required BuildContext context,
    required Shop? currentShop,
    required VoidCallback onLoyaltyCardTap,
  }) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Poignée de glissement
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 24),

            // Titre
            Text(
              'Actions rapides',
              style: GoogleFonts.poppins(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 24),

            // Grille d'icônes 2x2
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                // Appeler
                _ActionButton(
                  icon: Icons.phone,
                  label: 'Appeler',
                  color: const Color(0xFF25D366),
                  onTap: () async {
                    Navigator.pop(context);
                    final Uri telUri = Uri(scheme: 'tel', path: currentShop?.phone ?? '');
                    if (await canLaunchUrl(telUri)) {
                      await launchUrl(telUri);
                    }
                  },
                ),
                // Contact WhatsApp
                _ActionButton(
                  icon: FontAwesomeIcons.whatsapp,
                  label: 'Contact WhatsApp',
                  color: const Color(0xFF25D366),
                  onTap: () async {
                    Navigator.pop(context);
                    final Uri whatsappUri = Uri.parse('https://wa.me/${currentShop?.phone ?? ''}');
                    if (await canLaunchUrl(whatsappUri)) {
                      await launchUrl(whatsappUri, mode: LaunchMode.externalApplication);
                    }
                  },
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                // Mes commandes
                _ActionButton(
                  icon: Icons.inventory_2_outlined,
                  label: 'Mes commandes',
                  color: const Color(0xFFFF9800),
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => const OrdersListApiPage(),
                      ),
                    );
                  },
                ),
                // Carte de fidélité
                _ActionButton(
                  icon: Icons.credit_card,
                  label: 'Carte de fidélité',
                  color: const Color.fromARGB(255, 151, 15, 110),
                  onTap: () {
                    Navigator.pop(context);
                    onLoyaltyCardTap();
                  },
                ),
              ],
            ),

            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}

/// Widget pour un bouton d'action dans le bottom sheet
class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _ActionButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 150,
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withOpacity(0.3), width: 1.5),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: color.withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Icon(
                icon,
                color: Colors.white,
                size: 28,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              label,
              style: GoogleFonts.openSans(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
