import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../panier/cart_manager.dart';
import '../../../services/models/shop_model.dart';
import '../../../services/models/product_model.dart';
import '../../../services/product_service.dart';
import '../../../services/utils/api_endpoint.dart';
import 'widgets/product_details_section.dart';
import '../home/components/home_bottom_navigation.dart';
import '../home/widgets/product_card.dart';

/// Écran de détails d'un produit
class ProductDetailScreen extends StatefulWidget {
  final Map<String, dynamic> product;
  final Shop? shop;

  const ProductDetailScreen({
    super.key,
    required this.product,
    this.shop,
  });

  @override
  State<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen> {
  int _quantity = 1;
  bool _isPressed = false;
  String? _selectedSize;
  int? _selectedPortionId;

  // Produits similaires
  List<Map<String, dynamic>> _similarProducts = [];
  bool _loadingSimilar = false;
  int _similarPageIndex = 0;
  final PageController _carouselCtrl = PageController();

  // Thème de la boutique
  ShopTheme get _theme => widget.shop?.theme ?? ShopTheme.defaultTheme();
  Color get _primaryColor => _theme.primary;

  @override
  void initState() {
    super.initState();
    _loadSimilarProducts();
  }

  @override
  void dispose() {
    _carouselCtrl.dispose();
    super.dispose();
  }


  Future<void> _loadSimilarProducts() async {
    final shopId = widget.product['shopId'] as int?;
    final categoryId = widget.product['categoryId'] as int?;
    if (shopId == null) return;

    if (mounted) setState(() => _loadingSimilar = true);
    try {
      final result = await ProductService.getProducts(
        shopId: shopId,
        categoryId: categoryId,
      );
      final products = result['products'] as List<Product>;
      final currentId = widget.product['id'];
      if (!mounted) return;
      setState(() {
        _similarProducts = products
            .where((p) => p.id != currentId)
            .take(10)
            .map((p) => {
                  'id': p.id,
                  'name': p.name,
                  'price': p.price,
                  'oldPrice': p.comparePrice,
                  'discount': p.discountPercentage,
                  'stock': p.stockQuantity,
                  'isAvailable': p.isAvailable,
                  'image': p.primaryImageUrl ?? '',
                  'description': p.description,
                  'category': p.category?.name,
                  'categoryId': p.category?.id,
                  'shopId': shopId,
                  'preparation_time': p.cookingTime,
                  'portions': p.portions?.map((pt) => pt.toJson()).toList(),
                  'sizes': p.sizes,
                  'colors': p.colors,
                  'material': p.material,
                })
            .toList();
        _loadingSimilar = false;
      });
    } catch (_) {
      if (mounted) setState(() => _loadingSimilar = false);
    }
  }

  void _incrementQuantity() {
    final int stock = widget.product['stock'] ?? 0;
    if (_quantity < stock) {
      setState(() {
        _quantity++;
      });
    }
  }

  void _decrementQuantity() {
    if (_quantity > 1) {
      setState(() {
        _quantity--;
      });
    }
  }

  String _getDescription() {
    final apiDescription = widget.product['description']?.toString();
    if (apiDescription != null && apiDescription.isNotEmpty) {
      return apiDescription;
    }
    return 'Découvrez ce produit de qualité disponible dans notre boutique.';
  }

  String _formatPrice(dynamic value) {
    if (value == null) return '0';
    final n = value is num ? value : num.tryParse(value.toString()) ?? 0;
    return n.round().toString().replaceAllMapped(
      RegExp(r'(\d)(?=(\d{3})+(?!\d))'),
      (m) => '${m[1]} ',
    );
  }

  String? _getFullImageUrl(String? url) {
    if (url == null || url.isEmpty) return null;
    if (url.startsWith('http://') || url.startsWith('https://')) {
      return url;
    }
    final cleanUrl = url.startsWith('/') ? url.substring(1) : url;
    return '${Endpoints.storageBaseUrl}/$cleanUrl';
  }

  void _showZoomableImage(String imageUrl) {
    showDialog(
      context: context,
      barrierColor: Colors.black87,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: EdgeInsets.zero,
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Image zoomable
            InteractiveViewer(
              minScale: 0.5,
              maxScale: 4.0,
              child: Center(
                child: Image.network(
                  imageUrl,
                  fit: BoxFit.contain,
                  loadingBuilder: (context, child, loadingProgress) {
                    if (loadingProgress == null) return child;
                    return Center(
                      child: CircularProgressIndicator(
                        value: loadingProgress.expectedTotalBytes != null
                            ? loadingProgress.cumulativeBytesLoaded /
                                loadingProgress.expectedTotalBytes!
                            : null,
                        color: Colors.white,
                      ),
                    );
                  },
                  errorBuilder: (context, error, stackTrace) {
                    return Icon(
                      Icons.broken_image_outlined,
                      size: 100,
                      color: Colors.white54,
                    );
                  },
                ),
              ),
            ),
            // Bouton fermer
            Positioned(
              top: MediaQuery.of(context).padding.top + 16,
              right: 16,
              child: GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: Colors.black54,
                    shape: BoxShape.circle,
                  ),
                  alignment: Alignment.center,
                  child: const FaIcon(
                    FontAwesomeIcons.xmark,
                    color: Colors.white,
                    size: 18,
                  ),
                ),
              ),
            ),
            // Indication de zoom
            Positioned(
              bottom: MediaQuery.of(context).padding.bottom + 24,
              left: 0,
              right: 0,
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.black54,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    'Pincez pour zoomer',
                    style: GoogleFonts.inriaSerif(
                      fontSize: 14,
                      color: Colors.white70,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProductImage() {
    final String? imageUrl = widget.product['image']?.toString();
    final String? fullImageUrl = _getFullImageUrl(imageUrl);

    if (fullImageUrl == null || fullImageUrl.isEmpty) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Container(
          color: Colors.grey[300],
          child: Center(
            child: FaIcon(
              FontAwesomeIcons.bagShopping,
              size: 100,
              color: _primaryColor,
            ),
          ),
        ),
      );
    }

    return GestureDetector(
      onTap: () => _showZoomableImage(fullImageUrl),
      child: Stack(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: Image.network(
              fullImageUrl,
              fit: BoxFit.contain,
              loadingBuilder: (context, child, loadingProgress) {
                if (loadingProgress == null) return child;
                return Center(
                  child: CircularProgressIndicator(
                    value: loadingProgress.expectedTotalBytes != null
                        ? loadingProgress.cumulativeBytesLoaded /
                            loadingProgress.expectedTotalBytes!
                        : null,
                  ),
                );
              },
              errorBuilder: (context, error, stackTrace) {
                return Container(
                  color: Colors.grey[300],
                  child: Center(
                    child: FaIcon(
                      FontAwesomeIcons.bagShopping,
                      size: 100,
                      color: _primaryColor,
                    ),
                  ),
                );
              },
            ),
          ),
          // Icône de zoom
          Positioned(
            bottom: 12,
            right: 12,
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.black45,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.zoom_in,
                color: Colors.white,
                size: 20,
              ),
            ),
          ),
        ],
      ),
    );
  }


  @override
  Widget build(BuildContext context) {
    // Debug: Vérifier le type de boutique
    print('📱 ProductDetailScreen - shop: ${widget.shop?.name}');
    print('📱 ProductDetailScreen - category: ${widget.shop?.category}');
    print('📱 ProductDetailScreen - isRestaurant: ${widget.shop?.isRestaurant}');

    final int stock = widget.product['stock'] ?? 0;
    final bool isAvailable = widget.product['isAvailable'] ?? true;
    final bool isOutOfStock = stock == 0 || !isAvailable;
    final int? discount = widget.product['discount'];
    final int? oldPrice = widget.product['oldPrice'];
    final int? price = widget.product['price'] as int?; // Prix nullable - peut être null si l'API ne fournit pas de prix
    final int savings = (oldPrice != null && price != null) ? (oldPrice - price) : 0;
    final int? totalPrice = price != null ? (price * _quantity) : null;

    return Scaffold(
      backgroundColor: Colors.white,
      bottomNavigationBar: HomeBottomNavigation(
        selectedIndex: 0,
        currentShop: widget.shop,
      ),
      body: Stack(
        children: [
          // Contenu scrollable
          SingleChildScrollView(
            child: Column(
              children: [
            // Image du produit
            Stack(
              children: [
                // Fond dégradé + image + thumbnails
                Container(
                  width: double.infinity,
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Color(0xFFF8F8F8),
                        Colors.white,
                      ],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ),
                  ),
                  child: Column(
                    children: [
                      // Image principale (carousel si le vendeur a uploadé plusieurs images)
                      Builder(builder: (context) {
                        // Récupérer toutes les images du produit (uploadées par le vendeur)
                        final rawImages = widget.product['images'];
                        final List<String> allImages = [];
                        if (rawImages is List && rawImages.isNotEmpty) {
                          for (final img in rawImages) {
                            final url = img?.toString() ?? '';
                            if (url.isNotEmpty) allImages.add(url);
                          }
                        }
                        // Fallback : primary_image_url si images[] vide
                        if (allImages.isEmpty) {
                          final primary = widget.product['image']?.toString() ?? '';
                          if (primary.isNotEmpty) allImages.add(primary);
                        }
                        final hasMultiple = allImages.length > 1;
                        final pageIndex = _similarPageIndex.clamp(0, allImages.isEmpty ? 0 : allImages.length - 1);

                        return Padding(
                          padding: const EdgeInsets.fromLTRB(16, 70, 16, 16),
                          child: Stack(
                            children: [
                              // Conteneur image
                              Container(
                                height: 320,
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(24),
                                  border: Border.all(color: Colors.grey.shade300, width: 1.5),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.12),
                                      blurRadius: 16,
                                      offset: const Offset(0, 6),
                                      spreadRadius: 2,
                                    ),
                                  ],
                                ),
                                clipBehavior: Clip.antiAlias,
                                child: ColorFiltered(
                                  colorFilter: isOutOfStock
                                      ? const ColorFilter.mode(Color.fromARGB(255, 249, 249, 249), BlendMode.saturation)
                                      : const ColorFilter.mode(Color.fromARGB(255, 253, 253, 253), BlendMode.multiply),
                                  child: !hasMultiple
                                      ? _buildProductImage()
                                      : PageView.builder(
                                          controller: _carouselCtrl,
                                          itemCount: allImages.length,
                                          onPageChanged: (i) => setState(() => _similarPageIndex = i),
                                          itemBuilder: (_, i) {
                                            final url = allImages[i];
                                            final fullUrl = _getFullImageUrl(url) ?? url;
                                            return GestureDetector(
                                              onTap: () => _showZoomableImage(fullUrl),
                                              child: Stack(
                                                children: [
                                                  Image.network(
                                                    fullUrl,
                                                    fit: BoxFit.contain,
                                                    width: double.infinity,
                                                    height: double.infinity,
                                                    errorBuilder: (_, __, ___) => Center(
                                                      child: FaIcon(FontAwesomeIcons.image, size: 48, color: Colors.grey.shade300),
                                                    ),
                                                  ),
                                                  Positioned(
                                                    bottom: 12,
                                                    left: 12,
                                                    child: Container(
                                                      padding: const EdgeInsets.all(7),
                                                      decoration: BoxDecoration(
                                                        color: Colors.black45,
                                                        borderRadius: BorderRadius.circular(8),
                                                      ),
                                                      child: const Icon(Icons.zoom_in, color: Colors.white, size: 20),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            );
                                          },
                                        ),
                                ),
                              ),

                              // Flèche gauche
                              if (hasMultiple && pageIndex > 0)
                                Positioned(
                                  left: 8, top: 0, bottom: 0,
                                  child: Center(
                                    child: GestureDetector(
                                      onTap: () => _carouselCtrl.previousPage(
                                        duration: const Duration(milliseconds: 300),
                                        curve: Curves.easeInOut,
                                      ),
                                      child: Container(
                                        width: 34, height: 34,
                                        decoration: BoxDecoration(
                                          color: Colors.white.withOpacity(0.92),
                                          shape: BoxShape.circle,
                                          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.15), blurRadius: 6)],
                                        ),
                                        child: const Icon(Icons.chevron_left, color: Colors.black87, size: 22),
                                      ),
                                    ),
                                  ),
                                ),

                              // Flèche droite
                              if (hasMultiple && pageIndex < allImages.length - 1)
                                Positioned(
                                  right: 8, top: 0, bottom: 0,
                                  child: Center(
                                    child: GestureDetector(
                                      onTap: () => _carouselCtrl.nextPage(
                                        duration: const Duration(milliseconds: 300),
                                        curve: Curves.easeInOut,
                                      ),
                                      child: Container(
                                        width: 34, height: 34,
                                        decoration: BoxDecoration(
                                          color: Colors.white.withOpacity(0.92),
                                          shape: BoxShape.circle,
                                          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.15), blurRadius: 6)],
                                        ),
                                        child: const Icon(Icons.chevron_right, color: Colors.black87, size: 22),
                                      ),
                                    ),
                                  ),
                                ),

                              // Compteur (ex: 1 / 3)
                              if (hasMultiple)
                                Positioned(
                                  bottom: 10, right: 14,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: Colors.black.withOpacity(0.5),
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: Text(
                                      '${pageIndex + 1} / ${allImages.length}',
                                      style: GoogleFonts.inriaSerif(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.white),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        );
                      }),
                      // Thumbnails des images du produit (uploadées par le vendeur)
                      Builder(builder: (context) {
                        final rawImages = widget.product['images'];
                        final List<String> allImages = [];
                        if (rawImages is List && rawImages.isNotEmpty) {
                          for (final img in rawImages) {
                            final url = img?.toString() ?? '';
                            if (url.isNotEmpty) allImages.add(url);
                          }
                        }
                        if (allImages.isEmpty) {
                          final primary = widget.product['image']?.toString() ?? '';
                          if (primary.isNotEmpty) allImages.add(primary);
                        }
                        if (allImages.length <= 1) return const SizedBox(height: 14);
                        final pageIndex = _similarPageIndex.clamp(0, allImages.length - 1);

                        return Padding(
                          padding: const EdgeInsets.only(left: 16, right: 16, bottom: 14),
                          child: SizedBox(
                            height: 74,
                            child: ListView.builder(
                              scrollDirection: Axis.horizontal,
                              itemCount: allImages.length,
                              itemBuilder: (_, i) {
                                final img = allImages[i];
                                final isSelected = i == pageIndex;
                                return GestureDetector(
                                  onTap: () {
                                    setState(() => _similarPageIndex = i);
                                    _carouselCtrl.animateToPage(
                                      i,
                                      duration: const Duration(milliseconds: 300),
                                      curve: Curves.easeInOut,
                                    );
                                  },
                                  child: AnimatedContainer(
                                    duration: const Duration(milliseconds: 200),
                                    width: 70,
                                    height: 70,
                                    margin: const EdgeInsets.only(right: 10),
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                        color: isSelected ? _primaryColor : Colors.transparent,
                                        width: isSelected ? 2.5 : 0,
                                      ),
                                      color: Colors.white,
                                      boxShadow: isSelected
                                          ? [
                                              BoxShadow(
                                                color: _primaryColor.withOpacity(0.30),
                                                blurRadius: 10,
                                                offset: const Offset(0, 4),
                                                spreadRadius: 1,
                                              ),
                                            ]
                                          : [
                                              BoxShadow(
                                                color: Colors.black.withOpacity(0.10),
                                                blurRadius: 8,
                                                offset: const Offset(0, 3),
                                                spreadRadius: 0,
                                              ),
                                            ],
                                    ),
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(10),
                                      child: Image.network(img, fit: BoxFit.contain,
                                          errorBuilder: (_, __, ___) => Icon(
                                              Icons.image_not_supported,
                                              color: Colors.grey.shade300, size: 20)),
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                        );
                      }),
                    ],
                  ),
                ),

                // Bouton retour
                Positioned(
                  top: MediaQuery.of(context).padding.top + 12,
                  left: 16,
                  right: 16,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.95),
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: IconButton(
                          icon: const FaIcon(FontAwesomeIcons.arrowLeft, color: Colors.black87, size: 20),
                          onPressed: () => Navigator.pop(context),
                          padding: const EdgeInsets.only(left: 4),
                        ),
                      ),
                      const SizedBox.shrink(),
                    ],
                  ),
                ),
              ],
            ),

            // Carte blanche avec infos
            Transform.translate(
              offset: const Offset(0, 0),
              child: Container(
                width: double.infinity,
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(32),
                    topRight: Radius.circular(32),
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // ── Catégorie + Nom ──────────────────────────────────
                      if (widget.product['category'] != null)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                          decoration: BoxDecoration(
                            color: _primaryColor.withOpacity(0.07),
                            borderRadius: BorderRadius.circular(50),
                            border: Border.all(color: _primaryColor.withOpacity(0.25), width: 1),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              FaIcon(FontAwesomeIcons.tag, size: 11, color: _primaryColor),
                              const SizedBox(width: 6),
                              Text(
                                widget.product['category'],
                                style: GoogleFonts.inriaSerif(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: _primaryColor,
                                ),
                              ),
                            ],
                          ),
                        ),
                      const SizedBox(height: 8),
                      Text(
                        widget.product['name'] ?? '',
                        style: GoogleFonts.inriaSerif(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF1A1A2E),
                          height: 1.25,
                        ),
                      ),

                      // ── Rating ───────────────────────────────────────────
                      if ((widget.product['average_rating'] ?? 0.0) > 0) ...[
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            ...List.generate(5, (i) {
                              final r = (widget.product['average_rating'] as num).toDouble();
                              return Icon(
                                i < r.floor()
                                    ? Icons.star_rounded
                                    : (i < r ? Icons.star_half_rounded : Icons.star_outline_rounded),
                                color: const Color(0xFFFFC107),
                                size: 18,
                              );
                            }),
                            const SizedBox(width: 6),
                            Text(
                              '${(widget.product['average_rating'] as num).toStringAsFixed(1)}',
                              style: GoogleFonts.inriaSerif(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: const Color(0xFF7A7A7A),
                              ),
                            ),
                            if ((widget.product['rating_count'] ?? 0) > 0) ...[
                              const SizedBox(width: 4),
                              Text(
                                '(${widget.product['rating_count']} avis)',
                                style: GoogleFonts.inriaSerif(fontSize: 12, color: Colors.grey.shade500),
                              ),
                            ],
                          ],
                        ),
                      ],

                      const SizedBox(height: 16),
                      Divider(height: 1, color: Colors.grey.shade100),
                      const SizedBox(height: 16),

                      // ── Prix ─────────────────────────────────────────────
                      if (price != null) ...[
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Text(
                              _formatPrice(price),
                              style: GoogleFonts.inriaSerif(
                                fontSize: 22,
                                fontWeight: FontWeight.w800,
                                color: _primaryColor,
                                height: 1,
                              ),
                            ),
                            const SizedBox(width: 4),
                            Padding(
                              padding: const EdgeInsets.only(top: 4),
                              child: Text(
                                'FCFA',
                                style: GoogleFonts.inriaSerif(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: _primaryColor.withOpacity(0.75),
                                ),
                              ),
                            ),
                            if (oldPrice != null) ...[
                              const SizedBox(width: 12),
                              Text(
                                _formatPrice(oldPrice),
                                style: GoogleFonts.inriaSerif(
                                  fontSize: 15,
                                  color: Colors.grey.shade400,
                                  decoration: TextDecoration.lineThrough,
                                  decorationColor: Colors.grey.shade400,
                                  decorationThickness: 2,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFE53935),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  '-${(((oldPrice! - price!) / oldPrice!) * 100).round()}%',
                                  style: GoogleFonts.inriaSerif(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w800,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                        if (oldPrice != null && savings > 0) ...[
                          const SizedBox(height: 10),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                            decoration: BoxDecoration(
                              color: const Color(0xFFE8F5E9),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: const Color(0xFF4CAF50).withOpacity(0.3)),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.local_offer_rounded, size: 15, color: Color(0xFF2E7D32)),
                                const SizedBox(width: 6),
                                Text(
                                  'Vous économisez ${_formatPrice(savings)} FCFA',
                                  style: GoogleFonts.inriaSerif(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: const Color(0xFF2E7D32),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ] else
                        Text(
                          'Prix non disponible',
                          style: GoogleFonts.inriaSerif(
                            fontSize: 16,
                            color: Colors.grey.shade500,
                            fontStyle: FontStyle.italic,
                          ),
                        ),

                      const SizedBox(height: 16),

                      // ── Stock + Quantité ─────────────────────────────────
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                            decoration: BoxDecoration(
                              color: isOutOfStock ? const Color(0xFFFFEBEE) : const Color(0xFFE8F5E9),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: isOutOfStock
                                    ? const Color(0xFFE53935).withOpacity(0.3)
                                    : const Color(0xFF4CAF50).withOpacity(0.3),
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  isOutOfStock ? Icons.cancel_rounded : Icons.check_circle_rounded,
                                  color: isOutOfStock ? const Color(0xFFE53935) : const Color(0xFF4CAF50),
                                  size: 16,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  isOutOfStock ? 'Rupture de stock' : '$stock en stock',
                                  style: GoogleFonts.inriaSerif(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: isOutOfStock ? const Color(0xFFE53935) : const Color(0xFF2E7D32),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          if (!isOutOfStock)
                            Container(
                              decoration: BoxDecoration(
                                color: Colors.grey.shade50,
                                borderRadius: BorderRadius.circular(30),
                                border: Border.all(color: Colors.grey.shade200),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  GestureDetector(
                                    onTap: _decrementQuantity,
                                    child: Container(
                                      width: 38,
                                      height: 38,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: _quantity > 1 ? _primaryColor.withOpacity(0.08) : Colors.transparent,
                                      ),
                                      alignment: Alignment.center,
                                      child: FaIcon(
                                        FontAwesomeIcons.minus,
                                        size: 13,
                                        color: _quantity > 1 ? _primaryColor : Colors.grey.shade400,
                                      ),
                                    ),
                                  ),
                                  SizedBox(
                                    width: 36,
                                    child: Text(
                                      '$_quantity',
                                      textAlign: TextAlign.center,
                                      style: GoogleFonts.inriaSerif(
                                        fontSize: 17,
                                        fontWeight: FontWeight.w800,
                                        color: const Color(0xFF1A1A2E),
                                      ),
                                    ),
                                  ),
                                  GestureDetector(
                                    onTap: _incrementQuantity,
                                    child: Container(
                                      width: 38,
                                      height: 38,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        gradient: _quantity < stock
                                            ? LinearGradient(
                                                colors: [_primaryColor, _theme.gradientEnd],
                                                begin: Alignment.topLeft,
                                                end: Alignment.bottomRight,
                                              )
                                            : null,
                                        color: _quantity < stock ? null : Colors.transparent,
                                        boxShadow: _quantity < stock
                                            ? [BoxShadow(color: _primaryColor.withOpacity(0.3), blurRadius: 8, offset: const Offset(0, 3))]
                                            : [],
                                      ),
                                      alignment: Alignment.center,
                                      child: FaIcon(
                                        FontAwesomeIcons.plus,
                                        size: 13,
                                        color: _quantity < stock ? Colors.white : Colors.grey.shade400,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                        ],
                      ),

                      const SizedBox(height: 20),

                      // Pour Restaurant: Temps de préparation + Préférences AVANT Description
                      if (widget.shop != null && widget.shop!.isRestaurant) ...[
                        ProductDetailsSection(
                          product: widget.product,
                          boutiqueType: widget.shop!.boutiqueType,
                          onPortionSelected: (portionId) {
                            setState(() { _selectedPortionId = portionId; });
                          },
                        ),
                        const SizedBox(height: 24),
                      ],

                      // Description
                      Padding(
                        padding: const EdgeInsets.only(bottom: 2),
                        child: Row(
                          children: [
                            Container(
                              width: 4,
                              height: 22,
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [_primaryColor, _theme.gradientEnd],
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                ),
                                borderRadius: BorderRadius.circular(2),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Text(
                              'Description',
                              style: GoogleFonts.inriaSerif(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: const Color(0xFF1A1A2E),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        _getDescription(),
                        style: GoogleFonts.inriaSerif(
                          fontSize: 14,
                          color: Colors.grey.shade900,
                          height: 1.5,
                        ),
                      ),

                      // Pour autres types: Détails APRÈS Description
                      if (widget.shop != null && !widget.shop!.isRestaurant) ...[
                        const SizedBox(height: 24),
                        ProductDetailsSection(
                          product: widget.product,
                          boutiqueType: widget.shop!.boutiqueType,
                          onSizeSelected: (size) {
                            setState(() { _selectedSize = size; });
                          },
                          onPortionSelected: (portionId) {
                            setState(() { _selectedPortionId = portionId; });
                          },
                        ),
                      ],

                      // Espace pour le bouton fixe en bas
                      const SizedBox(height: 100),
                    ],
                  ),
                ),
              ),
            ),
              ],
            ),
          ),

          // Bouton fixe en bas (TOTAL + Ajouter)
          if (!isOutOfStock)
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.08),
                      blurRadius: 20,
                      offset: const Offset(0, -6),
                      spreadRadius: 0,
                    ),
                  ],
                ),
                child: SafeArea(
                  top: false,
                  child: Row(
                    children: [
                      // Total
                      Expanded(
                        flex: 2,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'Total',
                              style: GoogleFonts.inriaSerif(
                                fontSize: 11,
                                color: Colors.grey.shade500,
                                fontWeight: FontWeight.w500,
                                letterSpacing: 0.5,
                              ),
                            ),
                            const SizedBox(height: 1),
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                // Afficher le prix total seulement si le prix existe
                                if (totalPrice != null) ...[
                                  Text(
                                    _formatPrice(totalPrice),
                                    style: GoogleFonts.inriaSerif(
                                      fontSize: 20,
                                      fontWeight: FontWeight.w900,
                                      color: const Color(0xFF1A1A2E),
                                      height: 1,
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  Padding(
                                    padding: const EdgeInsets.only(bottom: 2),
                                    child: Text(
                                      'FCFA',
                                      style: GoogleFonts.inriaSerif(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w700,
                                        color: Colors.grey.shade600,
                                      ),
                                    ),
                                  ),
                                ] else ...[
                                  Text(
                                    'Prix non disponible',
                                    style: GoogleFonts.inriaSerif(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.grey.shade800,
                                      fontStyle: FontStyle.italic,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(width: 16),

                      // Bouton Ajouter
                      Expanded(
                        flex: 2,
                        child: GestureDetector(
                          onTapDown: (_) {
                            setState(() => _isPressed = true);
                            HapticFeedback.lightImpact();
                          },
                          onTapUp: (_) {
                            setState(() => _isPressed = false);
                          },
                          onTapCancel: () {
                            setState(() => _isPressed = false);
                          },
                          onTap: () async {
                            // Vérifier si le prix existe avant d'ajouter au panier
                            if (price == null) {
                              if (mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: const Text('Impossible d\'ajouter au panier : prix non disponible'),
                                    backgroundColor: Colors.red,
                                    duration: const Duration(seconds: 3),
                                  ),
                                );
                              }
                              return;
                            }

                            // Vérifier si une taille doit être sélectionnée
                            final sizes = widget.product['sizes'];
                            final bool hasSizes = sizes != null && sizes is List && sizes.isNotEmpty;
                            if (hasSizes && _selectedSize == null) {
                              if (mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: const Text('Veuillez choisir une taille'),
                                    backgroundColor: Colors.orange.shade700,
                                    duration: const Duration(seconds: 2),
                                  ),
                                );
                              }
                              return;
                            }

                            // Ajouter au panier
                            final error = CartManager().addItem(
                              widget.product,
                              _quantity,
                              shopId: widget.product['shopId'] as int?,
                              selectedSize: _selectedSize,
                              portionId: _selectedPortionId,
                            );

                            if (error != null) {
                              if (mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(error),
                                    backgroundColor: Colors.red,
                                    duration: const Duration(seconds: 3),
                                  ),
                                );
                              }
                              return;
                            }

                            // Afficher notification de succès au centre
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.all(8),
                                        decoration: BoxDecoration(
                                          color: Colors.white.withOpacity(0.2),
                                          shape: BoxShape.circle,
                                        ),
                                        alignment: Alignment.center,
                                        child: const FaIcon(
                                          FontAwesomeIcons.solidCircleCheck,
                                          color: Colors.white,
                                          size: 24,
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Text(
                                        'Produit ajouté avec succès',
                                        style: GoogleFonts.inriaSerif(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w600,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ],
                                  ),
                                  backgroundColor: const Color.fromARGB(255, 32, 193, 18),
                                  duration: const Duration(seconds: 2),
                                  behavior: SnackBarBehavior.floating,
                                  margin: EdgeInsets.only(
                                    left: 16,
                                    right: 16,
                                    bottom: MediaQuery.of(context).size.height / 2 - 50,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  elevation: 6,
                                ),
                              );

                              // Attendre 2 secondes puis retourner à l'accueil
                              await Future.delayed(const Duration(seconds: 0));

                              if (mounted) {
                                Navigator.pop(context); // Fermer ProductDetailScreen
                              }
                            }
                          },
                          child: AnimatedScale(
                            scale: _isPressed ? 0.96 : 1.0,
                            duration: const Duration(milliseconds: 150),
                            child: Container(
                              height: 50,
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    _primaryColor,
                                    _theme.gradientEnd,
                                  ],
                                  begin: Alignment.centerLeft,
                                  end: Alignment.centerRight,
                                ),
                                borderRadius: BorderRadius.circular(25),
                                boxShadow: [
                                  BoxShadow(
                                    color: _primaryColor.withOpacity(0.35),
                                    blurRadius: 14,
                                    offset: const Offset(0, 6),
                                  ),
                                ],
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const FaIcon(
                                    FontAwesomeIcons.bagShopping,
                                    color: Colors.white,
                                    size: 20,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Ajouter',
                                    style: GoogleFonts.inriaSerif(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w700,
                                      color: Colors.white,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}