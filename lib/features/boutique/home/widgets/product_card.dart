import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
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
    final intVal = n.round();
    return intVal.toString().replaceAllMapped(
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
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Cadre image séparé ─────────────────────────────────
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: const Color(0xFFF5F5F5),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.07),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                clipBehavior: Clip.antiAlias,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    // Image plein-bleed
                    ColorFiltered(
                      colorFilter: outOfStock
                          ? const ColorFilter.mode(
                              Colors.grey, BlendMode.saturation)
                          : const ColorFilter.mode(
                              Colors.transparent, BlendMode.multiply),
                      child: _buildImage(imgUrl),
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
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.grey.shade900,
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
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: Colors.grey.shade300,
                                  width: 1.5,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.20),
                                    blurRadius: 12,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              alignment: Alignment.center,
                              child: const FaIcon(
                                FontAwesomeIcons.plus,
                                size: 16,
                                color: Color(0xFF1C1C1E),
                              ),
                            ),
                          ),
                        ),
                  ],
                ),
              ),
            ),

            // ── Infos texte libres sous le cadre ──────────────────
            Padding(
              padding: const EdgeInsets.only(top: 8, left: 2, right: 2),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Prix
                  if (hasOldPrice && !outOfStock)
                    Wrap(
                      crossAxisAlignment: WrapCrossAlignment.center,
                      spacing: 6,
                      children: [
                        Text(
                          '${_fmt(p['price'])} F',
                          style: GoogleFonts.inriaSerif(
                            fontSize: 14,
                            fontWeight: FontWeight.w900,
                            color: const Color(0xFFE53935),
                          ),
                        ),
                        Text(
                          '${_fmt(p['oldPrice'])} F',
                          style: GoogleFonts.inriaSerif(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: Colors.grey.shade800,
                            decoration: TextDecoration.lineThrough,
                            decorationColor: Colors.grey.shade800,
                            decorationThickness: 2.0,
                          ),
                        ),
                      ],
                    )
                  else
                    Text(
                      '${_fmt(p['price'])} F',
                      style: GoogleFonts.inriaSerif(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: outOfStock
                            ? Colors.grey.shade900
                            : Colors.black,
                      ),
                    ),

                  const SizedBox(height: 2),

                  // Nom
                  Text(
                    p['name'] ?? '',
                    style: GoogleFonts.inriaSerif(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: const Color.fromARGB(255, 6, 6, 6),
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
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: Colors.grey.shade800,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImage(String? url) {
    if (url == null) return _placeholder();
    return Image.network(
      url,
      fit: BoxFit.contain,
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
        child: FaIcon(
          FontAwesomeIcons.magnifyingGlass,
          size: 36,
          color: Colors.grey.shade300,
        ),
      );
}
