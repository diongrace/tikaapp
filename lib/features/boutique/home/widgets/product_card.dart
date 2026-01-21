import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/services/boutique_theme_provider.dart';
import '../../../../services/utils/api_endpoint.dart';

/// Carte de produit affichant les informations du produit
class ProductCard extends StatelessWidget {
  final Map<String, dynamic> product;
  final VoidCallback onTap;
  final bool isRestaurant; // Pour afficher le temps de préparation

  // Cache statique pour éviter de logger la même erreur plusieurs fois
  static final Set<String> _loggedErrors = {};

  const ProductCard({
    super.key,
    required this.product,
    required this.onTap,
    this.isRestaurant = false,
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

  // Obtenir le texte de stock approprié selon l'état du produit
  String _getStockText(int stock, bool isAvailable) {
    if (!isAvailable && stock > 0) {
      return 'Non disponible';
    } else if (stock == 0) {
      return 'Rupture de stock';
    } else {
      return 'En stock: $stock';
    }
  }

  // Vérifie si le produit est un plat (pas boisson/pâtisserie)
  bool _isDish() {
    final category = (product['category']?.toString() ?? '').toLowerCase();
    final nonDishCategories = [
      'boisson', 'boissons', 'drink', 'drinks',
      'patisserie', 'pâtisserie', 'patisseries', 'pâtisseries',
      'dessert', 'desserts', 'jus', 'juice',
      'cafe', 'café', 'coffee', 'the', 'thé', 'tea',
      'glace', 'glaces', 'gateau', 'gâteau',
    ];
    for (final nonDish in nonDishCategories) {
      if (category.contains(nonDish)) return false;
    }
    return true;
  }

  // Obtenir le temps de préparation formaté (uniquement pour les plats)
  String? _getPreparationTime() {
    // Ne pas afficher pour boissons/pâtisseries
    if (!_isDish()) return null;

    final prepTime = product['preparation_time'] ??
        product['preparationTime'] ??
        product['cooking_time'] ??
        product['cookingTime'];
    if (prepTime == null) return null;
    return '$prepTime min';
  }

  @override
  Widget build(BuildContext context) {
    // Obtenir le thème de la boutique pour les couleurs dynamiques
    final shopTheme = BoutiqueThemeProvider.of(context);

    final int stock = product['stock'] ?? 0;
    final bool isAvailable = product['isAvailable'] ?? true;
    final bool isOutOfStock = stock == 0 || !isAvailable;
    final int? discount = product['discount'];
    final bool hasLowStock = stock > 0 && stock <= 10 && !isOutOfStock;
    final String? fullImageUrl = _getFullImageUrl(product['image']?.toString());

    return GestureDetector(
      onTap: () {
        print('👆 Clic détecté sur produit: ${product['name']}');
        onTap();
      },
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        clipBehavior: Clip.hardEdge,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Image du produit (plus grande)
            Stack(
              children: [
                ClipRRect(
                  borderRadius:
                      const BorderRadius.vertical(top: Radius.circular(16)),
                  child: ColorFiltered(
                    colorFilter: isOutOfStock
                        ? const ColorFilter.mode(
                            Colors.grey,
                            BlendMode.saturation,
                          )
                        : const ColorFilter.mode(
                            Colors.transparent,
                            BlendMode.multiply,
                          ),
                    child: fullImageUrl != null
                        ? Image.network(
                            fullImageUrl,
                            height: 180,
                            width: double.infinity,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              if (!_loggedErrors.contains(fullImageUrl)) {
                                _loggedErrors.add(fullImageUrl);
                                print(
                                    '⚠️ Image produit non disponible: "${product['name']}"');
                              }
                              return Container(
                                height: 180,
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [
                                      Colors.grey.shade200,
                                      Colors.grey.shade300,
                                    ],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  ),
                                ),
                                child: Center(
                                  child: Icon(
                                    Icons.image_outlined,
                                    size: 50,
                                    color: Colors.grey.shade400,
                                  ),
                                ),
                              );
                            },
                            loadingBuilder: (context, child, loadingProgress) {
                              if (loadingProgress == null) return child;
                              return Container(
                                height: 180,
                                color: Colors.grey[100],
                                child: Center(
                                  child: CircularProgressIndicator(
                                    color: shopTheme.primary,
                                    strokeWidth: 2,
                                    value: loadingProgress
                                                .expectedTotalBytes !=
                                            null
                                        ? loadingProgress
                                                .cumulativeBytesLoaded /
                                            loadingProgress
                                                .expectedTotalBytes!
                                        : null,
                                  ),
                                ),
                              );
                            },
                          )
                        : Container(
                            height: 180,
                            decoration: BoxDecoration(
                              borderRadius: const BorderRadius.vertical(
                                  top: Radius.circular(16)),
                              gradient: LinearGradient(
                                colors: [
                                  Colors.grey.shade200,
                                  Colors.grey.shade300,
                                ],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                            ),
                            child: Center(
                              child: Icon(
                                Icons.image_outlined,
                                size: 50,
                                color: Colors.grey.shade400,
                              ),
                            ),
                          ),
                  ),
                ),

                // Badge "Stock limité" (en haut à gauche, uniquement si stock faible et pas en rupture)
                if (hasLowStock && !isOutOfStock)
                  Positioned(
                    top: 12,
                    left: 12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFF8C00),
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color:
                                const Color(0xFFFF8C00).withOpacity(0.3),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Text(
                        'Stock limité',
                        style: GoogleFonts.poppins(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),

                // Badge réduction (en haut à droite, sous le stock limité)
                if (discount != null && !isOutOfStock)
                  Positioned(
                    top: hasLowStock ? 48 : 12,
                    right: 12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [
                            Color(0xFFE91E63),
                            Color(0xFFD81B60),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color:
                                const Color(0xFFE91E63).withOpacity(0.3),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.local_offer,
                              size: 12, color: Colors.white),
                          const SizedBox(width: 4),
                          Text(
                            '-$discount%',
                            style: GoogleFonts.poppins(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                // Bouton "+" en bas à droite (comme dans le design)
                if (!isOutOfStock)
                  Positioned(
                    bottom: 12,
                    right: 12,
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.15),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: IconButton(
                        icon: const Icon(Icons.add, size: 20),
                        color: Colors.black87,
                        padding: EdgeInsets.zero,
                        onPressed: onTap,
                      ),
                    ),
                  ),

                // Badge "Rupture de stock" (si rupture)
                if (isOutOfStock)
                  Positioned(
                    bottom: 12,
                    left: 12,
                    right: 12,
                    child: Center(
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.15),
                              blurRadius: 6,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Text(
                          'Rupture de stock',
                          style: GoogleFonts.poppins(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF666666),
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),

            // Infos du produit (design épuré)
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Prix en gros (comme dans le design)
                  Row(
                    children: [
                      Text(
                        '${product['price']}',
                        style: GoogleFonts.poppins(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: Colors.black87,
                        ),
                      ),
                      Text(
                        'F',
                        style: GoogleFonts.poppins(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: Colors.black87,
                        ),
                      ),
                      // Prix barré (compare_price) si disponible
                      if (product['oldPrice'] != null)
                        Flexible(
                          child: Padding(
                            padding: const EdgeInsets.only(left: 8),
                            child: Text(
                              '${product['oldPrice']}F',
                              style: GoogleFonts.poppins(
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                                color: Colors.grey.shade500,
                                decoration: TextDecoration.lineThrough,
                                decorationColor: Colors.grey.shade500,
                                decorationThickness: 2,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 2),

                  // Nom du produit
                  Text(
                    product['name'],
                    style: GoogleFonts.openSans(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: const Color(0xFF666666),
                      height: 1.2,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),

                  // Info stock (afficher pour tous les produits)
                  if (!isOutOfStock)
                    Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: Text(
                        'Stock: $stock',
                        style: GoogleFonts.openSans(
                          fontSize: 11,
                          color: stock <= 5
                              ? const Color(0xFFFF8C00) // Orange pour stock critique
                              : stock <= 10
                                  ? const Color(0xFFFFA726) // Orange clair pour stock faible
                                  : const Color(0xFF4CAF50), // Vert pour stock normal
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
