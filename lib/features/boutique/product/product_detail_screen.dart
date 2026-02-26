import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../panier/cart_manager.dart';
import '../../../services/models/shop_model.dart';
import '../../../services/utils/api_endpoint.dart';
import 'widgets/product_details_section.dart';
import '../home/components/home_bottom_navigation.dart';

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

  // Thème de la boutique
  ShopTheme get _theme => widget.shop?.theme ?? ShopTheme.defaultTheme();
  Color get _primaryColor => _theme.primary;

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
                  child: const Icon(
                    Icons.close,
                    color: Colors.white,
                    size: 24,
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
                    style: GoogleFonts.poppins(
                      fontSize: 13,
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
            child: Icon(
              Icons.shopping_bag_outlined,
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
                    child: Icon(
                      Icons.shopping_bag_outlined,
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

  Widget _buildSimilarProductsSection() {
    // Produits similaires basés sur la même catégorie
    // Pour l'instant, on affiche un placeholder - à connecter avec l'API
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Produits similaires',
              style: GoogleFonts.poppins(
                fontSize: 17,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF2D2D2D),
              ),
            ),
            TextButton(
              onPressed: () {
                // TODO: Naviguer vers la liste complète
              },
              child: Text(
                'Voir tout',
                style: GoogleFonts.poppins(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: _primaryColor,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 180,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: 4, // Placeholder - à remplacer par les vrais produits
            itemBuilder: (context, index) {
              return _buildSimilarProductCard(index);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildSimilarProductCard(int index) {
    return Container(
      width: 130,
      margin: const EdgeInsets.only(right: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Image placeholder
          Container(
            height: 100,
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
            ),
            child: Center(
              child: Icon(
                Icons.image_outlined,
                size: 40,
                color: Colors.grey.shade400,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Produit ${index + 1}',
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF2D2D2D),
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  '0 FCFA',
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: _primaryColor,
                  ),
                ),
              ],
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
                // Image
                Container(
                  height: 380,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        _primaryColor.withOpacity(0.07),
                        Colors.white,
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                  padding: const EdgeInsets.fromLTRB(30, 70, 30, 30),
                  child: ColorFiltered(
                    colorFilter: isOutOfStock
                        ? const ColorFilter.mode(
                            Color.fromARGB(255, 249, 249, 249),
                            BlendMode.saturation,
                          )
                        : const ColorFilter.mode(
                            Color.fromARGB(255, 253, 253, 253),
                            BlendMode.multiply,
                          ),
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(
                          color: Colors.grey.shade300,
                          width: 1.5,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.12),
                            blurRadius: 16,
                            offset: const Offset(0, 6),
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                      child: _buildProductImage(),
                    ),
                  ),
                ),

                // Boutons en haut (back, favorite, share)
                Positioned(
                  top: MediaQuery.of(context).padding.top + 12,
                  left: 16,
                  right: 16,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Bouton retour
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
                          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.black87, size: 20),
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
              offset: const Offset(0, -20),
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
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Nom du produit
                      Text(
                        widget.product['name'],
                        style: GoogleFonts.poppins(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF2D2D2D),
                          height: 1.3,
                        ),
                      ),
                      const SizedBox(height: 8),

                      // Catégorie du produit
                      if (widget.product['category'] != null)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                _primaryColor.withOpacity(0.15),
                                _primaryColor.withOpacity(0.08),
                              ],
                              begin: Alignment.centerLeft,
                              end: Alignment.centerRight,
                            ),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.local_offer_rounded,
                                size: 16,
                                color: _primaryColor,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                widget.product['category'],
                                style: GoogleFonts.poppins(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: _primaryColor,
                                  letterSpacing: 0.3,
                                ),
                              ),
                            ],
                          ),
                        ),
                      const SizedBox(height: 16),

                      // Prix
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          // Afficher le prix réel de l'API ou "Prix non disponible"
                          if (price != null) ...[
                            Text(
                              '$price',
                              style: GoogleFonts.poppins(
                                fontSize: 25,
                                fontWeight: FontWeight.w700,
                                color: _primaryColor,
                                height: 1,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Padding(
                              padding: const EdgeInsets.only(bottom: 4),
                              child: Text(
                                'FCFA',
                                style: GoogleFonts.poppins(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: _primaryColor,
                                ),
                              ),
                            ),
                          ] else ...[
                            Text(
                              'Prix non disponible',
                              style: GoogleFonts.poppins(
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                                color: Colors.grey.shade600,
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                          ],
                          if (oldPrice != null && price != null) ...[
                            const SizedBox(width: 10),
                            Padding(
                              padding: const EdgeInsets.only(bottom: 4),
                              child: Text(
                                '$oldPrice',
                                style: GoogleFonts.poppins(
                                  fontSize: 16,
                                  color: Colors.grey.shade400,
                                  decoration: TextDecoration.lineThrough,
                                  decorationColor: Colors.grey.shade400,
                                  decorationThickness: 2,
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Padding(
                              padding: const EdgeInsets.only(bottom: 4),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFE91E63),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  '-${(((oldPrice! - price!) / oldPrice!) * 100).round()}%',
                                  style: GoogleFonts.poppins(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),

                      // Badge économies
                      if (oldPrice != null) ...[
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                const Color(0xFFFFE8F0),
                                const Color(0xFFFFE8F0).withOpacity(0.7),
                              ],
                            ),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.savings_outlined,
                                size: 18,
                                color: Color(0xFFE91E63),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Vous économisez $savings FCFA',
                                style: GoogleFonts.poppins(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: const Color(0xFFE91E63),
                                  letterSpacing: 0.2,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],

                      const SizedBox(height: 16),

                      // Badge stock — inline
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: isOutOfStock
                                    ? [const Color(0xFFFFEBEE), const Color(0xFFFFD6D8)]
                                    : [const Color(0xFFE8F8F0), const Color(0xFFD0F2E1)],
                              ),
                              borderRadius: BorderRadius.circular(30),
                              border: Border.all(
                                color: isOutOfStock
                                    ? const Color(0xFFE91E63).withOpacity(0.25)
                                    : const Color(0xFF4CAF50).withOpacity(0.25),
                                width: 1,
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  isOutOfStock ? Icons.cancel_rounded : Icons.check_circle_rounded,
                                  color: isOutOfStock
                                      ? const Color(0xFFE91E63)
                                      : const Color(0xFF4CAF50),
                                  size: 20,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  isOutOfStock ? 'Rupture de stock' : '$stock en stock',
                                  style: GoogleFonts.poppins(
                                    fontSize: 13.5,
                                    fontWeight: FontWeight.w600,
                                    color: isOutOfStock
                                        ? const Color(0xFFE91E63)
                                        : const Color(0xFF2E7D32),
                                    letterSpacing: 0.2,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),

                      // Quantité - Design simplifié
                      if (!isOutOfStock) ...[
                        const SizedBox(height: 20),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Quantité',
                              style: GoogleFonts.poppins(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                                color: const Color(0xFF2D2D2D),
                              ),
                            ),
                            // Sélecteur premium
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                // Bouton −
                                GestureDetector(
                                  onTap: _decrementQuantity,
                                  child: AnimatedContainer(
                                    duration: const Duration(milliseconds: 200),
                                    width: 40,
                                    height: 40,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: _quantity > 1
                                          ? _primaryColor.withOpacity(0.10)
                                          : Colors.grey.shade100,
                                      border: Border.all(
                                        color: _quantity > 1
                                            ? _primaryColor.withOpacity(0.50)
                                            : Colors.grey.shade300,
                                        width: 1.5,
                                      ),
                                    ),
                                    child: Icon(
                                      Icons.remove_rounded,
                                      size: 18,
                                      color: _quantity > 1
                                          ? _primaryColor
                                          : Colors.grey.shade400,
                                    ),
                                  ),
                                ),
                                // Quantité
                                Container(
                                  width: 54,
                                  alignment: Alignment.center,
                                  child: Text(
                                    '$_quantity',
                                    style: GoogleFonts.poppins(
                                      fontSize: 20,
                                      fontWeight: FontWeight.w700,
                                      color: const Color(0xFF1A1A2E),
                                    ),
                                  ),
                                ),
                                // Bouton +
                                GestureDetector(
                                  onTap: _incrementQuantity,
                                  child: AnimatedContainer(
                                    duration: const Duration(milliseconds: 200),
                                    width: 40,
                                    height: 40,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      gradient: _quantity < stock
                                          ? LinearGradient(
                                              colors: [_primaryColor, _theme.gradientEnd],
                                              begin: Alignment.topLeft,
                                              end: Alignment.bottomRight,
                                            )
                                          : null,
                                      color: _quantity < stock ? null : Colors.grey.shade100,
                                      boxShadow: _quantity < stock
                                          ? [
                                              BoxShadow(
                                                color: _primaryColor.withOpacity(0.38),
                                                blurRadius: 10,
                                                offset: const Offset(0, 4),
                                              ),
                                            ]
                                          : [],
                                    ),
                                    child: Icon(
                                      Icons.add_rounded,
                                      size: 18,
                                      color: _quantity < stock
                                          ? Colors.white
                                          : Colors.grey.shade400,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ],

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
                              style: GoogleFonts.poppins(
                                fontSize: 17,
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
                        style: GoogleFonts.poppins(
                          fontSize: 13,
                          color: Colors.grey.shade700,
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

                      // Section Produits similaires (à activer plus tard)
                      // const SizedBox(height: 24),
                      // _buildSimilarProductsSection(),

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
                margin: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.12),
                      blurRadius: 24,
                      offset: const Offset(0, -8),
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
                              'TOTAL',
                              style: GoogleFonts.poppins(
                                fontSize: 12,
                                color: Colors.grey.shade600,
                                fontWeight: FontWeight.w600,
                                letterSpacing: 1.2,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                // Afficher le prix total seulement si le prix existe
                                if (totalPrice != null) ...[
                                  Text(
                                    '$totalPrice',
                                    style: GoogleFonts.poppins(
                                      fontSize: 24,
                                      fontWeight: FontWeight.w800,
                                      color: const Color(0xFF2D2D2D),
                                      height: 1,
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  Padding(
                                    padding: const EdgeInsets.only(bottom: 2),
                                    child: Text(
                                      'FCFA',
                                      style: GoogleFonts.poppins(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w700,
                                        color: Colors.grey.shade700,
                                      ),
                                    ),
                                  ),
                                ] else ...[
                                  Text(
                                    'Prix non disponible',
                                    style: GoogleFonts.poppins(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.grey.shade600,
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
                                        child: const Icon(
                                          Icons.check_circle,
                                          color: Colors.white,
                                          size: 24,
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Text(
                                        'Produit ajouté avec succès',
                                        style: GoogleFonts.poppins(
                                          fontSize: 15,
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
                              height: 56,
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    _primaryColor,
                                    _primaryColor.withOpacity(0.85),
                                  ],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                                borderRadius: BorderRadius.circular(16),
                                boxShadow: [
                                  BoxShadow(
                                    color: _primaryColor.withOpacity(0.4),
                                    blurRadius: 12,
                                    offset: const Offset(0, 6),
                                  ),
                                ],
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(
                                    Icons.shopping_bag_rounded,
                                    color: Colors.white,
                                    size: 20,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Ajouter',
                                    style: GoogleFonts.poppins(
                                      fontSize: 16,
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