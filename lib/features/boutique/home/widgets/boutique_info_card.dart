import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../../commande/orders_list_api_page.dart';
import '../../loyalty/create_loyalty_card_page.dart';
import '../../loyalty/loyalty_card_page.dart';
import '../../../../core/services/boutique_theme_provider.dart';
import '../../../../services/loyalty_service.dart';
import '../../../../services/auth_service.dart';
import '../../../../services/models/shop_model.dart';
import '../../../../services/utils/api_endpoint.dart';

class BoutiqueInfoCard extends StatelessWidget {

  final int shopId;
  final String boutiqueName;
  final String boutiqueDescription;
  final String boutiqueLogoPath;
  final String phoneNumber;
  final double averageRating;
  final int totalReviews;

  const BoutiqueInfoCard({
    super.key,
    required this.shopId,
    required this.boutiqueName,
    required this.boutiqueDescription,
    required this.boutiqueLogoPath,
    required this.phoneNumber,
    this.averageRating = 0.0,
    this.totalReviews = 0,
  });

  String? _logoUrl(String? url) {
    if (url == null || url.isEmpty) return null;
    if (url.startsWith('http://') || url.startsWith('https://')) return url;
    final c = url.startsWith('/') ? url.substring(1) : url;
    return '${Endpoints.storageBaseUrl}/$c';
  }

  Future<void> _call() async {
    final uri = Uri(scheme: 'tel', path: phoneNumber);
    if (await canLaunchUrl(uri)) await launchUrl(uri);
  }

  Future<void> _whatsapp() async {
    final uri = Uri.parse('https://wa.me/$phoneNumber');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  void _orders(BuildContext ctx) => Navigator.of(ctx).push(
        MaterialPageRoute(builder: (_) => const OrdersListApiPage()),
      );

  Future<void> _loyalty(BuildContext ctx) async {
    try {
      await AuthService.ensureToken();

      // LoyaltyService.getCardForShop() filtre déjà les cartes supprimées localement.
      // Si null → pas de carte (ou supprimée) → formulaire de création.
      final card = await LoyaltyService.getCardForShop(shopId);
      if (!ctx.mounted) return;

      if (card != null) {
        print('[LOYALTY] Carte trouvée id=${card.id}, ouverture LoyaltyCardPage');
        final deleted = await Navigator.of(ctx).push<bool>(
          MaterialPageRoute(builder: (_) => LoyaltyCardPage(loyaltyCard: card)),
        );
        print('[LOYALTY] Retour LoyaltyCardPage → deleted=$deleted');
        // Après suppression → ouvrir le formulaire de création
        if (deleted == true && ctx.mounted) {
          await Navigator.of(ctx).push(MaterialPageRoute(
            builder: (_) => CreateLoyaltyCardPage(
              shopId: shopId,
              boutiqueName: boutiqueName,
              shop: BoutiqueThemeProvider.shopOf(ctx),
              cardWasDeleted: true,
            ),
          ));
        }
      } else {
        await Navigator.of(ctx).push(MaterialPageRoute(
          builder: (_) => CreateLoyaltyCardPage(
            shopId: shopId,
            boutiqueName: boutiqueName,
            shop: BoutiqueThemeProvider.shopOf(ctx),
          ),
        ));
      }
    } catch (_) {
      if (!ctx.mounted) return;
      await Navigator.of(ctx).push(MaterialPageRoute(
        builder: (_) => CreateLoyaltyCardPage(
          shopId: shopId,
          boutiqueName: boutiqueName,
          shop: BoutiqueThemeProvider.shopOf(ctx),
        ),
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = BoutiqueThemeProvider.of(context);
    final logo = _logoUrl(boutiqueLogoPath);

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.13),
            blurRadius: 30,
            offset: const Offset(0, 10),
          ),
          BoxShadow(
            color: t.primary.withOpacity(0.08),
            blurRadius: 14,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // ── Barre gradient boutique ───────────────────────────
            Container(
              height: 4,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [t.primary, t.gradientEnd],
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                ),
              ),
            ),

            // ── Logo + Nom + Description ──────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Logo avec badge vérifié
                  Stack(
                    clipBehavior: Clip.none,
                    children: [
                      Container(
                        width: 68,
                        height: 68,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white,
                          border: Border.all(color: Colors.white, width: 3),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.13),
                              blurRadius: 14,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: ClipOval(
                          child: logo != null
                              ? Image.network(
                                  logo,
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, __, ___) => _logoFallback(t),
                                  loadingBuilder: (_, child, p) =>
                                      p == null ? child : _logoFallback(t),
                                )
                              : _logoFallback(t),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(width: 14),

                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Nom de la boutique
                        Text(
                          boutiqueName,
                          style: GoogleFonts.poppins(
                            fontSize: 15.5,
                            fontWeight: FontWeight.w800,
                            color: const Color(0xFF0D0D26),
                            letterSpacing: -0.3,
                            height: 1.2,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 5),
                        // Description
                        Text(
                          boutiqueDescription,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.openSans(
                            fontSize: 11.5,
                            color: const Color(0xFF6C7489),
                            height: 1.45,
                          ),
                        ),
                        if (averageRating > 0) ...[
                          const SizedBox(height: 5),
                          Row(
                            children: [
                              const Icon(Icons.star_rounded, size: 14, color: Color(0xFFF59E0B)),
                              const SizedBox(width: 3),
                              Text(
                                averageRating.toStringAsFixed(1),
                                style: GoogleFonts.poppins(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: const Color(0xFF1C1C1E),
                                ),
                              ),
                              if (totalReviews > 0) ...[
                                const SizedBox(width: 4),
                                Text(
                                  '($totalReviews avis)',
                                  style: GoogleFonts.openSans(
                                    fontSize: 11,
                                    color: const Color(0xFF6C7489),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // ── Boutons contact gradient ──────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 0, 14, 12),
              child: Row(
                children: [
                  _actionBtn(
                    icon: Icons.phone_in_talk_rounded,
                    label: 'Appeler',
                    colors: [t.primary, t.gradientEnd],
                    onTap: _call,
                  ),
                  const SizedBox(width: 8),
                  _actionBtn(
                    iconWidget: const FaIcon(
                      FontAwesomeIcons.whatsapp,
                      size: 15,
                      color: Colors.white,
                    ),
                    label: 'WhatsApp',
                    colors: const [Color(0xFF25D366), Color(0xFF128C7E)],
                    onTap: _whatsapp,
                  ),
                ],
              ),
            ),

            // ── Séparateur ────────────────────────────────────────
            Container(height: 1, color: const Color(0xFFF0F2F6)),

            // ── Boutons action gradient ───────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 11, 14, 13),
              child: Row(
                children: [
                  // Commandes
                  _actionBtn(
                    icon: Icons.receipt_long_rounded,
                    label: 'Commandes',
                    colors: [t.primary, t.primary.withOpacity(0.78)],
                    onTap: () => _orders(context),
                  ),
                  const SizedBox(width: 10),
                  // Fidélité
                  _actionBtn(
                    icon: Icons.workspace_premium_rounded,
                    label: 'Fidélité',
                    colors: const [Color(0xFFFF6B35), Color(0xFFFF9A5C)],
                    onTap: () => _loyalty(context),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

  Widget _logoFallback(ShopTheme t) => Container(
        color: t.primary.withOpacity(0.07),
        child: Icon(Icons.storefront_rounded, size: 28, color: t.primary),
      );

  Widget _actionBtn({
    IconData? icon,
    Widget? iconWidget,
    required String label,
    required List<Color> colors,
    required VoidCallback onTap,
  }) =>
      Expanded(
        child: GestureDetector(
          onTap: onTap,
          child: Container(
            height: 36,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: colors,
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(11),
              boxShadow: [
                BoxShadow(
                  color: colors.first.withOpacity(0.36),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                iconWidget ?? Icon(icon!, size: 15, color: Colors.white),
                const SizedBox(width: 6),
                Text(
                  label,
                  style: GoogleFonts.poppins(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                    letterSpacing: 0.1,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
}
