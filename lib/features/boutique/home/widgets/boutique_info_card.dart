import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../../../../core/services/boutique_theme_provider.dart';
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

  Widget _logoFallback(ShopTheme t) => Container(
        color: t.primary.withOpacity(0.07),
        child: FaIcon(FontAwesomeIcons.store, size: 28, color: t.primary),
      );


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

            // ── Logo + Nom + Description ───────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Logo
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

                  const SizedBox(width: 14),

                  // Nom + Description + Rating
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          boutiqueName,
                          style: GoogleFonts.inriaSerif(
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                            color: const Color(0xFF0D0D26),
                            letterSpacing: -0.3,
                            height: 1.2,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 5),
                        Text(
                          boutiqueDescription,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.inriaSerif(
                            fontSize: 13,
                            color: const Color(0xFF6C7489),
                            height: 1.45,
                          ),
                        ),
                        if (averageRating > 0) ...[
                          const SizedBox(height: 5),
                          Row(
                            children: [
                              const FaIcon(FontAwesomeIcons.solidStar, size: 14, color: Color(0xFFF59E0B)),
                              const SizedBox(width: 3),
                              Flexible(
                                child: Text(
                                  averageRating.toStringAsFixed(1),
                                  style: GoogleFonts.inriaSerif(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                    color: const Color(0xFF1C1C1E),
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              if (totalReviews > 0) ...[
                                const SizedBox(width: 4),
                                Flexible(
                                  child: Text(
                                    '($totalReviews avis)',
                                    style: GoogleFonts.inriaSerif(
                                      fontSize: 13,
                                      color: const Color(0xFF6C7489),
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
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

            // ── Séparateur ────────────────────────────────────────
            Divider(height: 1, thickness: 1, color: Colors.grey.shade100),

            // ── Boutons contact ───────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
              child: Row(
                children: [
                  _contactBtn(icon: Icons.call_rounded, color: const Color(0xFF34C759), label: 'Appeler', onTap: _call),
                  const SizedBox(width: 10),
                  _contactBtn(icon: FontAwesomeIcons.whatsapp, color: const Color(0xFF25D366), label: 'WhatsApp', onTap: _whatsapp, isFa: true),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _contactBtn({required IconData icon, required Color color, required String label, required VoidCallback onTap, bool isFa = false}) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(14),
            boxShadow: [BoxShadow(color: color.withOpacity(0.3), blurRadius: 8, offset: const Offset(0, 3))],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              isFa ? FaIcon(icon, color: Colors.white, size: 16) : Icon(icon, color: Colors.white, size: 18),
              const SizedBox(width: 6),
              Text(label, style: GoogleFonts.inriaSerif(fontSize: 13, fontWeight: FontWeight.w700, color: Colors.white)),
            ],
          ),
        ),
      ),
    );
  }
}
