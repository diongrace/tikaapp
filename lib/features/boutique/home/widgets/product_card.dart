import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/services/boutique_theme_provider.dart';
import '../../../../services/utils/api_endpoint.dart';

/// Carte produit premium — image plein-bleed, overlay gradient,
/// badge discount moderne, bouton add circulaire, animation de pression.
class ProductCard extends StatefulWidget {
  final Map<String, dynamic> product;
  final VoidCallback onTap;
  final VoidCallback? onAddToCart;
  final bool isRestaurant;

  static final Set<String> _loggedErrors = {};

  const ProductCard({
    super.key,
    required this.product,
    required this.onTap,
    this.onAddToCart,
    this.isRestaurant = false,
  });

  @override
  State<ProductCard> createState() => _ProductCardState();
}

class _ProductCardState extends State<ProductCard>
    with SingleTickerProviderStateMixin {
  bool _pressed = false;

  // ── Helpers ────────────────────────────────────────────────────────────

  String? _fullImageUrl(String? url) {
    if (url == null || url.isEmpty) return null;
    if (url.startsWith('http://') || url.startsWith('https://')) return url;
    final clean = url.startsWith('/') ? url.substring(1) : url;
    return '${Endpoints.storageBaseUrl}/$clean';
  }

  /// Formate un nombre en "1 500" (espace millier)
  String _fmt(dynamic price) {
    if (price == null) return '0';
    final n = price is num ? price : num.tryParse(price.toString()) ?? 0;
    return n
        .toStringAsFixed(0)
        .replaceAllMapped(
          RegExp(r'(\d)(?=(\d{3})+(?!\d))'),
          (m) => '${m[1]} ',
        );
  }

  // ── Build ───────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final shopTheme = BoutiqueThemeProvider.of(context);
    final p = widget.product;

    final int stock      = p['stock'] ?? 0;
    final bool available = p['isAvailable'] ?? true;
    final bool outOfStock = stock == 0 || !available;
    final int? discount  = p['discount'];
    final bool lowStock  = stock > 0 && stock <= 10 && !outOfStock;
    final String? imgUrl = _fullImageUrl(p['image']?.toString());

    return GestureDetector(
      onTap: widget.onTap,
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp:   (_) => setState(() => _pressed = false),
      onTapCancel: ()  => setState(() => _pressed = false),
      child: AnimatedScale(
        scale: _pressed ? 0.955 : 1.0,
        duration: const Duration(milliseconds: 130),
        curve: Curves.easeInOut,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 130),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(_pressed ? 0.04 : 0.10),
                blurRadius: _pressed ? 6 : 18,
                spreadRadius: _pressed ? 0 : 0,
                offset: Offset(0, _pressed ? 2 : 6),
              ),
            ],
          ),
          clipBehavior: Clip.hardEdge,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ─── Zone image ───────────────────────────────────────────
              Expanded(
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    // Image
                    _image(imgUrl, outOfStock, shopTheme),


                    // Badge réduction (haut gauche, rectangulaire moderne)
                    if (discount != null && !outOfStock)
                      Positioned(
                        top: 10, left: 10,
                        child: _discountBadge(discount),
                      ),

                    // Badge stock limité (haut gauche, sous le discount)
                    if (lowStock)
                      Positioned(
                        top: discount != null ? 46 : 10,
                        left: 10,
                        child: _pill(
                          label: '⚡ Stock limité',
                          color: const Color(0xFFFF6D00),
                        ),
                      ),

                    // Overlay rupture de stock
                    if (outOfStock)
                      Positioned.fill(
                        child: Container(
                          color: Colors.black.withOpacity(0.45),
                          child: Center(
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 7),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(10),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.15),
                                    blurRadius: 10,
                                  ),
                                ],
                              ),
                              child: Text(
                                'Rupture de stock',
                                style: GoogleFonts.poppins(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: const Color(0xFF444444),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),

                    // Bouton "+" circulaire (bas droite, sur le gradient)
                    if (!outOfStock)
                      Positioned(
                        bottom: 10, right: 10,
                        child: GestureDetector(
                          onTap: widget.onAddToCart ?? widget.onTap,
                          child: Container(
                            width: 34, height: 34,
                            decoration: BoxDecoration(
                              color: shopTheme.primary,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: shopTheme.primary.withOpacity(0.45),
                                  blurRadius: 10,
                                  offset: const Offset(0, 3),
                                ),
                              ],
                            ),
                            child: const Icon(
                              Icons.add_rounded,
                              size: 20,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),

                    // Alerte stock critique (bas gauche, sur gradient)
                    if (!outOfStock && stock <= 5)
                      Positioned(
                        bottom: 16, left: 10,
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 6, height: 6,
                              decoration: const BoxDecoration(
                                color: Color(0xFFFF5252),
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 5),
                            Text(
                              'Plus que $stock',
                              style: GoogleFonts.poppins(
                                fontSize: 10.5,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                                shadows: const [
                                  Shadow(color: Colors.black54, blurRadius: 4),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),

              // ─── Zone info ────────────────────────────────────────────
              Padding(
                padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Nom
                    Text(
                      p['name'] ?? '',
                      style: GoogleFonts.poppins(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF1C1C1E),
                        height: 1.3,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),

                    // Rating
                    if ((p['average_rating'] ?? 0.0) > 0) ...[
                      const SizedBox(height: 3),
                      Row(
                        children: [
                          const Icon(Icons.star_rounded, size: 12, color: Color(0xFFF59E0B)),
                          const SizedBox(width: 2),
                          Text(
                            (p['average_rating'] as double).toStringAsFixed(1),
                            style: GoogleFonts.poppins(
                              fontSize: 10.5,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFF1C1C1E),
                            ),
                          ),
                          if ((p['rating_count'] ?? 0) > 0) ...[
                            const SizedBox(width: 2),
                            Text(
                              '(${p['rating_count']})',
                              style: GoogleFonts.openSans(
                                fontSize: 10,
                                color: Colors.grey.shade500,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],

                    const SizedBox(height: 5),

                    // Prix
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.baseline,
                      textBaseline: TextBaseline.alphabetic,
                      children: [
                        Text(
                          '${_fmt(p['price'])} F',
                          style: GoogleFonts.poppins(
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                            color: outOfStock
                                ? Colors.grey.shade400
                                : const Color(0xFF111827),
                          ),
                        ),
                        if (p['oldPrice'] != null) ...[
                          const SizedBox(width: 6),
                          Flexible(
                            child: Text(
                              '${_fmt(p['oldPrice'])} F',
                              style: GoogleFonts.poppins(
                                fontSize: 10.5,
                                color: Colors.grey.shade400,
                                decoration: TextDecoration.lineThrough,
                                decorationColor: Colors.grey.shade400,
                                decorationThickness: 1.5,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                        if (outOfStock) ...[
                          const Spacer(),
                          Text(
                            'Indisponible',
                            style: GoogleFonts.poppins(
                              fontSize: 10,
                              color: Colors.grey.shade400,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Sous-widgets ────────────────────────────────────────────────────────

  Widget _image(String? url, bool outOfStock, shopTheme) {
    final filter = outOfStock
        ? const ColorFilter.mode(Colors.grey, BlendMode.saturation)
        : const ColorFilter.mode(Colors.transparent, BlendMode.multiply);

    return ColorFiltered(
      colorFilter: filter,
      child: url != null
          ? Image.network(
              url,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) {
                if (!ProductCard._loggedErrors.contains(url)) {
                  ProductCard._loggedErrors.add(url);
                }
                return _placeholder();
              },
              loadingBuilder: (_, child, progress) {
                if (progress == null) return child;
                return _shimmer();
              },
            )
          : _placeholder(),
    );
  }

  Widget _placeholder() => Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.grey.shade100, Colors.grey.shade200],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Center(
          child: Icon(
            Icons.image_search_rounded,
            size: 42,
            color: Colors.grey.shade300,
          ),
        ),
      );

  Widget _shimmer() => Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Colors.grey.shade100,
              Colors.grey.shade200,
              Colors.grey.shade100,
            ],
            stops: const [0.0, 0.5, 1.0],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
      );

  Widget _discountBadge(int discount) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFFFF416C), Color(0xFFFF4B2B)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(8),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFFFF416C).withOpacity(0.45),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Text(
          '-$discount%',
          style: GoogleFonts.poppins(
            fontSize: 11.5,
            fontWeight: FontWeight.w800,
            color: Colors.white,
            letterSpacing: 0.3,
          ),
        ),
      );

  Widget _pill({required String label, required Color color}) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(8),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.4),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: 10,
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
      );
}
