import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../../commande/orders_list_api_page.dart';
import '../../loyalty/create_loyalty_card_page.dart';
import '../../loyalty/loyalty_card_page.dart';
import '../../../../core/services/storage_service.dart';
import '../../../../core/services/boutique_theme_provider.dart';
import '../../../../services/loyalty_service.dart';
import '../../../../services/models/shop_model.dart';
import '../../../../services/utils/api_endpoint.dart';

/// Carte d'informations de la boutique avec actions rapides
class BoutiqueInfoCard extends StatelessWidget {
  final int shopId;
  final String boutiqueName;
  final String boutiqueDescription;
  final String boutiqueLogoPath;
  final String phoneNumber;

  const BoutiqueInfoCard({
    super.key,
    required this.shopId,
    required this.boutiqueName,
    required this.boutiqueDescription,
    required this.boutiqueLogoPath,
    required this.phoneNumber,
  });

  // Construire l'URL complète de l'image
  String? _getFullImageUrl(String? url) {
    if (url == null || url.isEmpty) return null;

    // Si l'URL commence déjà par http, la retourner telle quelle
    if (url.startsWith('http://') || url.startsWith('https://')) {
      return url;
    }

    // Sinon, construire l'URL complète avec le domaine de base
    final cleanUrl = url.startsWith('/') ? url.substring(1) : url;
    return '${Endpoints.storageBaseUrl}/$cleanUrl';
  }

  @override
  Widget build(BuildContext context) {
    // Obtenir le thème de la boutique pour les couleurs dynamiques
    final shopTheme = BoutiqueThemeProvider.of(context);
    final String? fullLogoUrl = _getFullImageUrl(boutiqueLogoPath);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.12),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Logo et nom de la boutique avec icônes d'actions
          Row(
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(14),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(14),
                  child: fullLogoUrl != null
                      ? Image.network(
                          fullLogoUrl,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return Container(
                              color: Colors.grey[300],
                              child: const Icon(Icons.store, size: 35, color: Colors.grey),
                            );
                          },
                          loadingBuilder: (context, child, loadingProgress) {
                            if (loadingProgress == null) return child;
                            return Center(
                              child: CircularProgressIndicator(
                                color: shopTheme.primary,
                                value: loadingProgress.expectedTotalBytes != null
                                    ? loadingProgress.cumulativeBytesLoaded /
                                        loadingProgress.expectedTotalBytes!
                                    : null,
                              ),
                            );
                          },
                        )
                      : Container(
                          color: Colors.grey[300],
                          child: const Icon(Icons.store, size: 35, color: Colors.grey),
                        ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      boutiqueName,
                      style: GoogleFonts.openSans(
                        fontSize: 19,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 3),
                    Text(
                      boutiqueDescription,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.openSans(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                        height: 1.3,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // Afficher le bottom sheet avec toutes les actions
  void _showActionsBottomSheet(BuildContext context, ShopTheme shopTheme) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(

        
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
              'Actions rapides',
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 20),

            // Bouton Appeler
            _buildBottomSheetButton(
              Icons.phone,
              'Appeler',
              shopTheme.primary,
              () async {
                Navigator.pop(context);
                final Uri telUri = Uri(scheme: 'tel', path: phoneNumber);
                if (await canLaunchUrl(telUri)) {
                  await launchUrl(telUri);
                }
              },
            ),
            const SizedBox(height: 12),

            // Bouton WhatsApp
            _buildBottomSheetButton(
              FontAwesomeIcons.whatsapp,
              'WhatsApp',
              shopTheme.primary,
              () async {
                Navigator.pop(context);
                final Uri whatsappUri = Uri.parse('https://wa.me/$phoneNumber');
                if (await canLaunchUrl(whatsappUri)) {
                  await launchUrl(whatsappUri, mode: LaunchMode.externalApplication);
                }
              },
            ),
            const SizedBox(height: 12),

            // Bouton Mes commandes
            _buildBottomSheetButton(
              Icons.inventory_2_outlined,
              'Mes commandes',
              shopTheme.primary,
              () {
                Navigator.pop(context);
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => const OrdersListApiPage(),
                  ),
                );
              },
            ),
            const SizedBox(height: 12),

            // Bouton Carte de fidélité
            _buildBottomSheetButton(
              Icons.credit_card,
              'Carte de fidélité',
              shopTheme.primary,
              () async {
                Navigator.pop(context);

                // Récupérer le téléphone depuis le stockage local
                final cardData = await StorageService.getLoyaltyCard();
                final phone = cardData?['phone'];

                if (!context.mounted) return;

                if (phone != null && phone.isNotEmpty) {
                  // Vérifier si une carte existe sur l'API
                  try {
                    final loyaltyCard = await LoyaltyService.getCard(
                      shopId: shopId,
                      phone: phone,
                    );

                    if (!context.mounted) return;

                    if (loyaltyCard != null) {
                      // Carte trouvée, afficher
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => LoyaltyCardPage(
                            loyaltyCard: loyaltyCard,
                          ),
                        ),
                      );
                    } else {
                      // Pas de carte, créer
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => CreateLoyaltyCardPage(
                            shopId: shopId,
                            boutiqueName: boutiqueName,
                            shop: BoutiqueThemeProvider.shopOf(context),
                          ),
                        ),
                      );
                    }
                  } catch (e) {
                    if (!context.mounted) return;
                    // En cas d'erreur, aller vers création
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => CreateLoyaltyCardPage(
                          shopId: shopId,
                          boutiqueName: boutiqueName,
                          shop: BoutiqueThemeProvider.shopOf(context),
                        ),
                      ),
                    );
                  }
                } else {
                  // Pas de téléphone enregistré, créer carte
                  if (!context.mounted) return;
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => CreateLoyaltyCardPage(
                        shopId: shopId,
                        boutiqueName: boutiqueName,
                        shop: BoutiqueThemeProvider.shopOf(context),
                      ),
                    ),
                  );
                }
              },
            ),

            const SizedBox(height: 10),
          ],
        ),
      ),
    );
  }

  // Widget pour un bouton dans le bottom sheet
  Widget _buildBottomSheetButton(
    IconData icon,
    String label,
    Color color,
    VoidCallback onTap,
  ) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          border: Border.all(color: color.withOpacity(0.3)),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(width: 14),
            Text(
              label,
              style: GoogleFonts.openSans(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
            const Spacer(),
            Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey.shade400),
          ],
        ),
      ),
    );
  }
}
