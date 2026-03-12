import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/services/boutique_theme_provider.dart';
import '../../../../services/utils/api_endpoint.dart';

/// Carte produit – grille 2 colonnes, design maquette
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

class _ProductCardState extends State<ProductCard> {
  bool _pressed = false;

  String? _fullImageUrl(String? url) {
    if (url == null || url.isEmpty) return null;
    if (url.startsWith('http://') || url.startsWith('https://')) return url;
    final clean = url.startsWith('/') ? url.substring(1) : url;
    return '${Endpoints.storageBaseUrl}/$clean';
  }

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

  @override
  Widget build(BuildContext context) {
    // ignore: unused_local_variable
    final shopTheme = BoutiqueThemeProvider.of(context);
    final p = widget.product;

    final int stock       = p['stock'] ?? 0;
    final bool available  = p['isAvailable'] ?? true;
    final bool outOfStock = stock == 0 || !available;
    final int? discount   = p['discount'];
    final String? imgUrl  = _fullImageUrl(p['image']?.toString());
    final String? description = p['description']?.toString();
    final bool hasOldPrice = p['oldPrice'] != null;

    return GestureDetector(
      onTap: widget.onTap,
      onTapDown:   (_) => setState(() => _pressed = true),
      onTapUp:     (_) => setState(() => _pressed = false),
      onTapCancel: ()  => setState(() => _pressed = false),
      child: AnimatedScale(
        scale: _pressed ? 0.96 : 1.0,
        duration: const Duration(milliseconds: 130),
        curve: Curves.easeInOut,
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.08),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          clipBehavior: Clip.hardEdge,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Zone image (~63% hauteur) ──────────────────────────
              Expanded(
                flex: 63,
                child: Stack(
                  children: [
                    // Image plein-bleed
                    Positioned.fill(
                      child: ColorFiltered(
                        colorFilter: outOfStock
                            ? const ColorFilter.mode(
                                Colors.grey, BlendMode.saturation)
                            : const ColorFilter.mode(
                                Colors.transparent, BlendMode.multiply),
                        child: Container(
                          color: const Color(0xFFF5F5F5),
                          child: _buildImage(imgUrl),
                        ),
                      ),
                    ),

                    // Badge -X% rouge pill (haut gauche)
                    if (discount != null && discount > 0 && !outOfStock)
                      Positioned(
                        top: 10,
                        left: 10,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(
                            color: const Color(0xFFE53935),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            '-$discount%',
                            style: GoogleFonts.inriaSerif(
                              fontSize: 12,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),

                    // Overlay rupture de stock
                    if (outOfStock)
                      Positioned.fill(
                        child: Container(
                          color: Colors.white.withOpacity(0.72),
                          alignment: Alignment.center,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(10),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.10),
                                  blurRadius: 10,
                                ),
                              ],
                            ),
                            child: Text(
                              'Rupture de stock',
                              style: GoogleFonts.inriaSerif(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: Colors.grey.shade700,
                              ),
                            ),
                          ),
                        ),
                      ),

                    // Bouton + blanc (bas droite)
                    if (!outOfStock)
                      Positioned(
                        bottom: 10,
                        right: 10,
                        child: GestureDetector(
                          onTap: widget.onAddToCart ?? widget.onTap,
                          child: Container(
                            width: 38,
                            height: 38,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.18),
                                  blurRadius: 10,
                                  offset: const Offset(0, 3),
                                ),
                              ],
                            ),
                            child: const Icon(
                              Icons.add_rounded,
                              size: 22,
                              color: Color(0xFF1C1C1E),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),

              // ── Zone texte (~37% hauteur) ──────────────────────────
              Expanded(
                flex: 37,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Prix
                      if (hasOldPrice && !outOfStock)
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.baseline,
                          textBaseline: TextBaseline.alphabetic,
                          children: [
                            Text(
                              '${_fmt(p['price'])} F',
                              style: GoogleFonts.inriaSerif(
                                fontSize: 15,
                                fontWeight: FontWeight.w800,
                                color: Colors.black,
                              ),
                            ),
                            const SizedBox(width: 5),
                            Text(
                              '${_fmt(p['oldPrice'])} F',
                              style: GoogleFonts.inriaSerif(
                                fontSize: 11,
                                color: Colors.grey.shade400,
                                decoration: TextDecoration.lineThrough,
                                decorationColor: Colors.grey.shade400,
                              ),
                            ),
                          ],
                        )
                      else
                        Text(
                          '${_fmt(p['price'])} F',
                          style: GoogleFonts.inriaSerif(
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                            color: outOfStock
                                ? Colors.grey.shade400
                                : Colors.black,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),

                      const SizedBox(height: 2),

                      // Nom
                      Text(
                        p['name'] ?? '',
                        style: GoogleFonts.inriaSerif(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w500,
                          color: const Color(0xFF1C1C1E),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),

                      // Description / poids
                      if (description != null && description.isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Text(
                          description,
                          style: GoogleFonts.inriaSerif(
                            fontSize: 11,
                            color: Colors.grey.shade500,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildImage(String? url) {
    if (url == null) return _placeholder();
    return Image.network(
      url,
      fit: BoxFit.cover,
      width: double.infinity,
      height: double.infinity,
      errorBuilder: (_, __, ___) {
        if (!ProductCard._loggedErrors.contains(url)) {
          ProductCard._loggedErrors.add(url);
        }
        return _placeholder();
      },
      loadingBuilder: (_, child, progress) {
        if (progress == null) return child;
        return Container(color: const Color(0xFFF5F5F5));
      },
    );
  }

  Widget _placeholder() => Center(
        child: Icon(
          Icons.image_search_rounded,
          size: 36,
          color: Colors.grey.shade300,
        ),
      );
}
