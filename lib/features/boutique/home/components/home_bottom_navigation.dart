import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../../../../services/models/shop_model.dart';
import '../../panier/cart_manager.dart';
import '../../panier/panier_screen.dart';
import '../../profile/profile_screen.dart';
import '../../favorites/favorites_boutiques_screen.dart';
import '../../../../core/services/boutique_theme_provider.dart';
import '../../commande/orders_list_api_page.dart';
import '../../gift/gift_bottom_sheet.dart';
import '../../loyalty/create_loyalty_card_page.dart';
import '../../loyalty/loyalty_card_page.dart';
import '../../../../services/loyalty_service.dart';
import '../../../../services/auth_service.dart';

/// Navbar flottante pill — panier central gradient, icônes outlined/filled
/// StatefulWidget : gère CartManager et animation badge en interne.
class HomeBottomNavigation extends StatefulWidget {
  final int selectedIndex;
  final Shop? currentShop;
  final Function(int)? onIndexChanged;
  final VoidCallback? onSearchTap;
  final VoidCallback? onActionsTap;
  final Function()? onProductsReload;

  const HomeBottomNavigation({
    super.key,
    required this.selectedIndex,
    required this.currentShop,
    this.onIndexChanged,
    this.onSearchTap,
    this.onActionsTap,
    this.onProductsReload,
  });

  @override
  State<HomeBottomNavigation> createState() => _HomeBottomNavigationState();
}

class _HomeBottomNavigationState extends State<HomeBottomNavigation>
    with SingleTickerProviderStateMixin {
  final CartManager _cartManager = CartManager();
  late AnimationController _badgeController;
  late Animation<double> _badgeAnimation;
  int _prevCount = 0;

  @override
  void initState() {
    super.initState();
    _prevCount = _cartManager.itemCount;
    _badgeController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _badgeAnimation = Tween<double>(begin: 1.0, end: 1.3).animate(
      CurvedAnimation(parent: _badgeController, curve: Curves.easeInOut),
    );
    _cartManager.addListener(_onCartChanged);
  }

  @override
  void dispose() {
    _cartManager.removeListener(_onCartChanged);
    _badgeController.dispose();
    super.dispose();
  }

  void _onCartChanged() {
    final newCount = _cartManager.itemCount;
    if (newCount > _prevCount) {
      _badgeController
          .forward()
          .then((_) => _badgeController.reverse());
    }
    _prevCount = newCount;
    if (mounted) setState(() {});
  }

  ShopTheme get _shopTheme =>
      widget.currentShop?.theme ?? ShopTheme.defaultTheme();

  @override
  Widget build(BuildContext context) {
    final shopTheme = _shopTheme;

    final bottomInset = MediaQuery.of(context).padding.bottom;
    return Padding(
      padding: EdgeInsets.fromLTRB(14, 4, 14, 8 + bottomInset),
      child: Container(
        height: 54,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(34),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.14),
              blurRadius: 30,
              spreadRadius: 0,
              offset: const Offset(0, 8),
            ),
            BoxShadow(
              color: shopTheme.primary.withOpacity(0.07),
              blurRadius: 16,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _navItem(context, shopTheme: shopTheme,
              icon: FontAwesomeIcons.house, iconActive: FontAwesomeIcons.house,
              label: 'Accueil', index: 0),
            _navItem(context, shopTheme: shopTheme,
              icon: FontAwesomeIcons.magnifyingGlass, iconActive: FontAwesomeIcons.magnifyingGlass,
              label: 'Chercher', index: 2),

            // ── Bouton panier central ──────────────────────────────
            _cartButton(context, shopTheme),

            _navItem(context, shopTheme: shopTheme,
              icon: FontAwesomeIcons.heart, iconActive: FontAwesomeIcons.solidHeart,
              label: 'Favoris', index: 3),
            _navItem(context, shopTheme: shopTheme,
              icon: FontAwesomeIcons.bars, iconActive: FontAwesomeIcons.bars,
              label: 'Plus', index: 5),
          ],
        ),
      ),
    );
  }

  // ── Bouton panier gradient central ────────────────────────────────────────
  Widget _cartButton(BuildContext context, ShopTheme shopTheme) {
    final count = _cartManager.itemCount;

    return GestureDetector(
      onTap: () => _handleCartNavigation(context),
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.center,
        children: [
          // Halo externe pulsant
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  shopTheme.primary.withOpacity(0.18),
                  shopTheme.primary.withOpacity(0.00),
                ],
              ),
            ),
          ),

          // Bouton principal
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: [shopTheme.primary, shopTheme.gradientEnd],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              boxShadow: [
                BoxShadow(
                  color: shopTheme.primary.withOpacity(0.45),
                  blurRadius: 18,
                  spreadRadius: 0,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            alignment: Alignment.center,
            child: const FaIcon(
              FontAwesomeIcons.cartShopping,
              color: Colors.white,
              size: 22,
            ),
          ),

          // Badge quantité
          if (count > 0)
            Positioned(
              right: 3,
              top: 3,
              child: ScaleTransition(
                scale: _badgeAnimation,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFF3B30),
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.red.withOpacity(0.4),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  constraints: const BoxConstraints(minWidth: 20, minHeight: 20),
                  child: Text(
                    count > 99 ? '99+' : '$count',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  // ── Item de navigation standard ───────────────────────────────────────────
  Widget _navItem(
    BuildContext context, {
    required ShopTheme shopTheme,
    required IconData icon,
    required IconData iconActive,
    required String label,
    required int index,
  }) {
    final isSelected = widget.selectedIndex == index;
    final color = isSelected ? shopTheme.primary : const Color(0xFF6B7280);

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => _handleTap(context, index),
      child: SizedBox(
        width: 58,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 220),
              transitionBuilder: (child, anim) =>
                  ScaleTransition(scale: anim, child: child),
              child: FaIcon(
                isSelected ? iconActive : icon,
                key: ValueKey(isSelected),
                size: 18,
                color: color,
              ),
            ),
            const SizedBox(height: 2),
            AnimatedContainer(
              duration: const Duration(milliseconds: 220),
              width: isSelected ? 14 : 0,
              height: 2,
              decoration: BoxDecoration(
                color: shopTheme.primary,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 2),
            AnimatedDefaultTextStyle(
              duration: const Duration(milliseconds: 220),
              style: GoogleFonts.inriaSerif(
                fontSize: 10,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                color: color,
              ),
              child: Text(label),
            ),
          ],
        ),
      ),
    );
  }

  // ── Gestion des taps ──────────────────────────────────────────────────────
  void _handleTap(BuildContext context, int index) {
    switch (index) {
      case 0: // Accueil
        if (Navigator.of(context).canPop()) {
          Navigator.of(context).pop();
        } else {
          widget.onIndexChanged?.call(0);
        }
        break;
      case 2: // Chercher
        widget.onSearchTap?.call();
        break;
      case 3: // Favoris
        if (widget.selectedIndex != 3) {
          Navigator.push(context,
            MaterialPageRoute(builder: (_) => BoutiqueThemeProvider(
              shop: widget.currentShop,
              child: const FavoritesBoutiquesScreen(),
            )));
        }
        break;
      case 5: // Profil → bottom sheet actions
        _showActionsSheet(context);
        break;
      default:
        widget.onIndexChanged?.call(index);
    }
  }

  void _showActionsSheet(BuildContext context) {
    final shopTheme = _shopTheme;
    final shop = widget.currentShop;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: EdgeInsets.fromLTRB(20, 12, 20, 20 + MediaQuery.of(context).padding.bottom),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Pill handle
            Container(
              width: 40, height: 4,
              margin: const EdgeInsets.only(bottom: 20),
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),

            _sheetItem(
              context: context,
              icon: FontAwesomeIcons.gift,
              color: const Color(0xFFEC4899),
              label: 'Offrir un cadeau',
              subtitle: 'Envoyer un produit en cadeau',
              onTap: () {
                Navigator.pop(context);
                GiftBottomSheet.show(context, currentShop: shop);
              },
            ),
            const SizedBox(height: 12),
            _sheetItem(
              context: context,
              icon: FontAwesomeIcons.receipt,
              color: const Color(0xFF3B82F6),
              label: 'Mes commandes',
              subtitle: 'Suivi de vos commandes',
              onTap: () {
                Navigator.pop(context);
                Navigator.push(context,
                  MaterialPageRoute(builder: (_) => const OrdersListApiPage()));
              },
            ),
            const SizedBox(height: 12),
            _sheetItem(
              context: context,
              icon: FontAwesomeIcons.idCard,
              color: const Color(0xFFF59E0B),
              label: 'Carte fidélité',
              subtitle: 'Vos points et récompenses',
              onTap: () {
                Navigator.pop(context);
                if (shop != null) _openLoyalty(context, shop);
              },
            ),
            const SizedBox(height: 12),
            _sheetItem(
              context: context,
              icon: FontAwesomeIcons.solidUser,
              color: shopTheme.primary,
              label: 'Mon profil',
              subtitle: 'Informations personnelles',
              onTap: () {
                Navigator.pop(context);
                Navigator.push(context,
                  MaterialPageRoute(builder: (_) => BoutiqueThemeProvider(
                    shop: shop,
                    child: const ProfileScreen(),
                  )));
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _sheetItem({
    required BuildContext context,
    required IconData icon,
    required Color color,
    required String label,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: color.withOpacity(0.06),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withOpacity(0.15)),
        ),
        child: Row(
          children: [
            Container(
              width: 42, height: 42,
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(child: FaIcon(icon, color: Colors.white, size: 18)),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label, style: GoogleFonts.inriaSerif(
                    fontSize: 14, fontWeight: FontWeight.w700,
                    color: const Color(0xFF0D0D26),
                  )),
                  Text(subtitle, style: GoogleFonts.inriaSerif(
                    fontSize: 12, color: const Color(0xFF6C7489),
                  )),
                ],
              ),
            ),
            Icon(Icons.chevron_right_rounded, color: color, size: 22),
          ],
        ),
      ),
    );
  }

  Future<void> _openLoyalty(BuildContext ctx, Shop shop) async {
    try {
      await AuthService.ensureToken();
      final card = await LoyaltyService.getCardForShop(shop.id);
      if (!ctx.mounted) return;

      if (card != null) {
        final deleted = await Navigator.of(ctx).push<bool>(
          MaterialPageRoute(builder: (_) => LoyaltyCardPage(loyaltyCard: card)),
        );
        if (deleted == true && ctx.mounted) {
          await Navigator.of(ctx).push(MaterialPageRoute(
            builder: (_) => CreateLoyaltyCardPage(
              shopId: shop.id,
              boutiqueName: shop.name,
              shop: shop,
              cardWasDeleted: true,
            ),
          ));
        }
      } else {
        await Navigator.of(ctx).push(MaterialPageRoute(
          builder: (_) => CreateLoyaltyCardPage(
            shopId: shop.id,
            boutiqueName: shop.name,
            shop: shop,
          ),
        ));
      }
    } catch (_) {
      if (!ctx.mounted) return;
      await Navigator.of(ctx).push(MaterialPageRoute(
        builder: (_) => CreateLoyaltyCardPage(
          shopId: shop.id,
          boutiqueName: shop.name,
          shop: shop,
        ),
      ));
    }
  }

  Future<void> _handleCartNavigation(BuildContext context) async {
    final shop = widget.currentShop;
    if (shop == null || shop.id == 0) return;

    try {
      final orderCompleted = await PanierScreen.show(
        context,
        shopId: shop.id,
        shop: shop,
      );
      if (orderCompleted == true) {
        widget.onProductsReload?.call();
      }
    } catch (_) {}
  }
}
