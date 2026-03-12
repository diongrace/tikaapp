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

class BoutiqueInfoCard extends StatefulWidget {

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

  @override
  State<BoutiqueInfoCard> createState() => _BoutiqueInfoCardState();
}

class _BoutiqueInfoCardState extends State<BoutiqueInfoCard>
    with SingleTickerProviderStateMixin {
  int get shopId => widget.shopId;
  String get boutiqueName => widget.boutiqueName;
  String get boutiqueDescription => widget.boutiqueDescription;
  String get boutiqueLogoPath => widget.boutiqueLogoPath;
  String get phoneNumber => widget.phoneNumber;
  double get averageRating => widget.averageRating;
  int get totalReviews => widget.totalReviews;

  bool _isExpanded = false;
  OverlayEntry? _overlayEntry;
  final GlobalKey _btnKey = GlobalKey();
  late final AnimationController _animCtrl;

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 250),
    );
  }

  @override
  void dispose() {
    _removeOverlay();
    _animCtrl.dispose();
    super.dispose();
  }

  void _toggleSpeedDial(ShopTheme t) {
    if (_isExpanded) {
      _removeOverlay();
    } else {
      _showSpeedDial(t);
    }
    setState(() => _isExpanded = !_isExpanded);
  }

  void _removeOverlay() {
    _overlayEntry?.remove();
    _overlayEntry = null;
  }

  void _showSpeedDial(ShopTheme t) {
    final box = _btnKey.currentContext?.findRenderObject() as RenderBox?;
    if (box == null) return;
    final pos = box.localToGlobal(Offset.zero);
    final size = box.size;

    final actions = [
      _SpeedDialItem(icon: Icons.phone_rounded,          color: t.primary,                  label: 'Appeler',    onTap: () { _closeAndRun(_call); }),
      _SpeedDialItem(faIcon: FontAwesomeIcons.whatsapp,  color: const Color(0xFF25D366),    label: 'WhatsApp',   onTap: () { _closeAndRun(_whatsapp); }),
      _SpeedDialItem(icon: Icons.receipt_long_rounded,   color: const Color(0xFF3B82F6),    label: 'Commandes',  onTap: () { _closeAndRun(() => _orders(context)); }),
      _SpeedDialItem(icon: Icons.workspace_premium_rounded, color: const Color(0xFFF59E0B), label: 'Fidélité',   onTap: () { _closeAndRun(() => _loyalty(context)); }),
    ];

    _overlayEntry = OverlayEntry(
      builder: (_) => _SpeedDialOverlay(
        anchorRight: MediaQuery.of(context).size.width - pos.dx - size.width,
        anchorTop: pos.dy + size.height + 8,
        actions: actions,
        controller: _animCtrl,
        onDismiss: () {
          _removeOverlay();
          if (mounted) setState(() => _isExpanded = false);
        },
      ),
    );

    Overlay.of(context).insert(_overlayEntry!);
    _animCtrl.forward(from: 0);
  }

  void _closeAndRun(VoidCallback fn) {
    _removeOverlay();
    if (mounted) setState(() => _isExpanded = false);
    fn();
  }

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

            // ── Logo + Nom + Description + bouton ··· ─────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 8, 14),
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
                            fontSize: 17.5,
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
                            fontSize: 13.5,
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
                                style: GoogleFonts.inriaSerif(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                  color: const Color(0xFF1C1C1E),
                                ),
                              ),
                              if (totalReviews > 0) ...[
                                const SizedBox(width: 4),
                                Text(
                                  '($totalReviews avis)',
                                  style: GoogleFonts.inriaSerif(
                                    fontSize: 13,
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

                  // Bouton Speed Dial
                  GestureDetector(
                    key: _btnKey,
                    onTap: () => _toggleSpeedDial(t),
                    child: Container(
                      width: 46,
                      height: 46,
                      decoration: BoxDecoration(
                        color: _isExpanded ? Colors.grey.shade400 : t.primary,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: t.primary.withOpacity(0.35),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Icon(
                        _isExpanded ? Icons.close : Icons.phone_rounded,
                        color: Colors.white,
                        size: 22,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
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

}

// ── Modèle d'action Speed Dial ────────────────────────────────────────────────
class _SpeedDialItem {
  final IconData? icon;
  final IconData? faIcon;
  final Color color;
  final String label;
  final VoidCallback onTap;
  const _SpeedDialItem({this.icon, this.faIcon, required this.color, required this.label, required this.onTap});
}

// ── Overlay Speed Dial ────────────────────────────────────────────────────────
class _SpeedDialOverlay extends StatelessWidget {
  final double anchorRight;
  final double anchorTop;
  final List<_SpeedDialItem> actions;
  final AnimationController controller;
  final VoidCallback onDismiss;

  const _SpeedDialOverlay({
    required this.anchorRight,
    required this.anchorTop,
    required this.actions,
    required this.controller,
    required this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onDismiss,
      behavior: HitTestBehavior.translucent,
      child: Stack(
        children: [
          ...List.generate(actions.length, (i) {
            final delay = i * 0.15;
            final anim = CurvedAnimation(
              parent: controller,
              curve: Interval(delay, delay + 0.5, curve: Curves.easeOut),
            );
            return Positioned(
              right: anchorRight,
              top: anchorTop + i * 70.0,
              child: AnimatedBuilder(
                animation: anim,
                builder: (_, __) => Opacity(
                  opacity: anim.value,
                  child: Transform.translate(
                    offset: Offset(0, 20 * (1 - anim.value)),
                    child: _SpeedDialButton(item: actions[i]),
                  ),
                ),
              ),
            );
          }),
        ],
      ),
    );
  }
}

class _SpeedDialButton extends StatelessWidget {
  final _SpeedDialItem item;
  const _SpeedDialButton({required this.item});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: item.onTap,
      child: Container(
        width: 50,
        height: 50,
        decoration: BoxDecoration(
          color: item.color,
          shape: BoxShape.circle,
          boxShadow: [BoxShadow(color: item.color.withOpacity(0.4), blurRadius: 10, offset: const Offset(0, 4))],
        ),
        child: Center(
          child: item.faIcon != null
              ? FaIcon(item.faIcon!, color: Colors.white, size: 22)
              : Icon(item.icon!, color: Colors.white, size: 22),
        ),
      ),
    );
  }
}
