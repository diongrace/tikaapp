import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../services/models/shop_model.dart';
import '../../panier/cart_manager.dart';
import '../../panier/panier_screen.dart';
import '../../profile/profile_screen.dart';
import '../../favorites/favorites_boutiques_screen.dart';
import '../../commande/orders_list_api_page.dart';
import '../../../../core/services/boutique_theme_provider.dart';

/// Barre de navigation inférieure pour l'écran d'accueil
class HomeBottomNavigation extends StatelessWidget {
  final int selectedIndex;
  final Shop? currentShop;
  final CartManager cartManager;
  final Animation<double> cartBadgeAnimation;
  final Function(int) onIndexChanged;
  final VoidCallback onSearchTap;
  final VoidCallback onActionsTap;
  final Function() onProductsReload;

  const HomeBottomNavigation({
    super.key,
    required this.selectedIndex,
    required this.currentShop,
    required this.cartManager,
    required this.cartBadgeAnimation,
    required this.onIndexChanged,
    required this.onSearchTap,
    required this.onActionsTap,
    required this.onProductsReload,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 65,
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildNavItemWithImage(context, 'lib/core/assets/lhome.png', 'Accueil', 0),
          _buildNavItemWithImage(context, 'lib/core/assets/cart.png', 'Panier', 1),
          _buildNavItemWithIcon(context, Icons.search, 'Rechercher', 2),
          _buildNavItemWithImage(context, 'lib/core/assets/favory.png', 'Favoris', 3),
          _buildNavItemWithIcon(context, Icons.apps, 'Services', 4),
          _buildNavItemWithImage(context, 'lib/core/assets/user.png', 'Profil', 5),
        ],
      ),
    );
  }

  Widget _buildNavItemWithIcon(BuildContext context, IconData icon, String label, int index) {
    final shopTheme = currentShop?.theme ?? ShopTheme.defaultTheme();
    final isSelected = selectedIndex == index;

    // Couleurs spécifiques pour chaque icône quand non sélectionnée
    Color iconColor;
    if (isSelected) {
      iconColor = shopTheme.primary;
    } else {
      if (index == 2) {
        iconColor = const Color.fromARGB(255, 21, 21, 21);
      } else if (index == 4) {
        iconColor = const Color.fromARGB(255, 10, 148, 77);
      } else {
        iconColor = Colors.grey.shade600;
      }
    }

    return GestureDetector(
      onTap: () {
        if (index == 2) {
          onSearchTap();
        } else if (index == 4) {
          onActionsTap();
        } else {
          onIndexChanged(index);
        }
      },
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: isSelected ? shopTheme.primary.withOpacity(0.1) : Colors.transparent,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              icon,
              size: 24,
              color: iconColor,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: GoogleFonts.openSans(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: iconColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavItemWithImage(BuildContext context, String imagePath, String label, int index) {
    final shopTheme = currentShop?.theme ?? ShopTheme.defaultTheme();
    final isSelected = selectedIndex == index;
    final isCartIcon = index == 1;
    final cartItemCount = cartManager.itemCount;

    // Couleurs spécifiques pour chaque icône
    Color iconColor;
    if (isSelected) {
      iconColor = shopTheme.primary;
    } else {
      if (index == 0) {
        iconColor = const Color.fromARGB(255, 79, 3, 92);
      } else if (index == 1) {
        iconColor = const Color.fromARGB(255, 10, 9, 10);
      } else if (index == 3) {
        iconColor = const Color(0xFFE91E63);
      } else if (index == 5) {
        iconColor = const Color.fromARGB(255, 113, 2, 121);
      } else {
        iconColor = Colors.grey.shade600;
      }
    }

    return GestureDetector(
      onTap: () async {
        if (index == 1) {
          await _handleCartNavigation(context);
        } else if (index == 5) {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const ProfileScreen()),
          );
        } else if (index == 4) {
          onActionsTap();
        } else if (index == 3) {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const FavoritesBoutiquesScreen()),
          );
        } else if (index == 2) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const OrdersListApiPage(),
            ),
          );
        } else {
          onIndexChanged(index);
        }
      },
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Stack(
            clipBehavior: Clip.none,
            children: [
              Image.asset(
                imagePath,
                width: 24,
                height: 24,
                color: iconColor,
                fit: BoxFit.contain,
              ),
              // Badge pour le panier
              if (isCartIcon && cartItemCount > 0)
                Positioned(
                  right: -8,
                  top: -8,
                  child: ScaleTransition(
                    scale: cartBadgeAnimation,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: const BoxDecoration(
                        color: Colors.red,
                        shape: BoxShape.circle,
                      ),
                      constraints: const BoxConstraints(
                        minWidth: 18,
                        minHeight: 18,
                      ),
                      child: Text(
                        '$cartItemCount',
                        style: GoogleFonts.openSans(
                          fontSize: 10,
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
          const SizedBox(height: 4),
          Text(
            label,
            style: GoogleFonts.openSans(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: iconColor,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _handleCartNavigation(BuildContext context) async {
    print('🛒 [HomeBottomNav] Clic sur le panier');

    final shopId = currentShop?.id;
    print('🛒 [HomeBottomNav] shopId: $shopId, shop: ${currentShop?.name}');

    if (shopId == null || shopId == 0) {
      print('❌ [HomeBottomNav] shopId invalide');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Impossible d\'accéder au panier: boutique non chargée'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return;
    }

    if (currentShop == null) {
      print('❌ [HomeBottomNav] currentShop est null');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Boutique non chargée, veuillez patienter'),
            backgroundColor: Colors.orange,
          ),
        );
      }
      return;
    }

    print('✅ [HomeBottomNav] Navigation vers PanierScreen...');

    try {
      final orderCompleted = await Navigator.push<bool>(
        context,
        MaterialPageRoute(
          builder: (context) => BoutiqueThemeProvider(
            shop: currentShop,
            child: PanierScreen(
              shopId: shopId,
              shop: currentShop,
            ),
          ),
        ),
      );

      print('🛒 [HomeBottomNav] Retour du panier, orderCompleted: $orderCompleted');

      if (orderCompleted == true && context.mounted) {
        print('🔄 Commande réussie - Rechargement des produits...');
        onProductsReload();
      }
    } catch (e) {
      print('❌ [HomeBottomNav] Erreur: $e');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Erreur lors de l\'ouverture du panier'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}
