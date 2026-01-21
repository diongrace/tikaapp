import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'cart_manager.dart';
import '../commande/commande_screen.dart';
import '../../../services/models/shop_model.dart';
import '../../../services/utils/api_endpoint.dart';
import '../../../core/services/boutique_theme_provider.dart';

class PanierScreen extends StatefulWidget {
  final int shopId;
  final Shop? shop;

  const PanierScreen({super.key, required this.shopId, this.shop});

  @override
  State<PanierScreen> createState() => _PanierScreenState();
}

class _PanierScreenState extends State<PanierScreen> {
  final CartManager _cartManager = CartManager();
  final TextEditingController _promoController = TextEditingController();

  // Thème de la boutique - Utiliser une variable late pour éviter les recalculs
  late final ShopTheme _theme;
  late final Color _primaryColor;

  @override
  void initState() {
    super.initState();
    print('🛒 [PanierScreen] initState démarré');

    try {
      // Initialiser le thème une seule fois
      _theme = widget.shop?.theme ?? ShopTheme.defaultTheme();
      _primaryColor = _theme.primary;

      print('🛒 [PanierScreen] Thème initialisé - shopId: ${widget.shopId}, shop: ${widget.shop?.name}');
      print('🛒 [PanierScreen] Primary color: $_primaryColor');

      // Ajouter le listener après un court délai pour éviter les problèmes de synchronisation
      Future.microtask(() {
        if (mounted) {
          _cartManager.addListener(_onCartChanged);
          print('🛒 [PanierScreen] Listener ajouté au CartManager');
        }
      });

      // Forcer un rebuild après le premier frame pour éviter les blocages
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          print('🛒 [PanierScreen] Premier frame rendu - déclenchement du rebuild');
          setState(() {});
        }
      });
    } catch (e, stackTrace) {
      print('❌ [PanierScreen] Erreur dans initState: $e');
      print('Stack trace: $stackTrace');
    }
  }


  @override
  void dispose() {
    print('🛒 [PanierScreen] dispose appelé');
    try {
      _cartManager.removeListener(_onCartChanged);
      _promoController.dispose();
    } catch (e) {
      print('❌ [PanierScreen] Erreur dans dispose: $e');
    }
    super.dispose();
  }

  void _onCartChanged() {
    // Utiliser microtask pour éviter de setState pendant le build
    Future.microtask(() {
      if (mounted) {
        setState(() {});
      }
    });
  }

  String? _getFullImageUrl(String? url) {
    if (url == null || url.isEmpty) return null;
    if (url.startsWith('http://') || url.startsWith('https://')) {
      return url;
    }
    final cleanUrl = url.startsWith('/') ? url.substring(1) : url;
    return '${Endpoints.storageBaseUrl}/$cleanUrl';
  }

  int? _getDiscount(Map<String, dynamic> item) {
    final oldPrice = item['oldPrice'];
    final price = item['price'];
    if (oldPrice != null && oldPrice > price) {
      return (((oldPrice - price) / oldPrice) * 100).round();
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    print('🛒 [PanierScreen] build appelé');

    final items = _cartManager.items;
    final total = _cartManager.totalPrice;
    final itemCount = _cartManager.itemCount;

    print('🛒 [PanierScreen] items: ${items.length}, total: $total, itemCount: $itemCount');

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      body: Stack(
        children: [

          SafeArea(
            child: Column(
              children: [
                // Header moderne
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.9),
                    border: Border(
                      bottom: BorderSide(color: Colors.grey.shade200),
                    ),
                  ),
                  child: Row(
                    children: [
                      // Bouton retour avec cercle
                      GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            color: Colors.grey.shade100,
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.grey.shade200),
                          ),
                          child: const Icon(
                            Icons.arrow_back,
                            size: 20,
                            color: Colors.black87,
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      // Titre et compteur
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Mon panier',
                              style: GoogleFonts.poppins(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: Colors.black87,
                              ),
                            ),
                            Text(
                              '$itemCount article${itemCount > 1 ? 's' : ''}',
                              style: GoogleFonts.openSans(
                                fontSize: 13,
                                color: Colors.grey.shade500,
                              ),
                            ),
                          ],
                        ),
                      ),
                      // Bouton panier simplifié
                      Container(
                        width: 56,
                        height: 56,
                        decoration: BoxDecoration(
                          color: _primaryColor,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: const Icon(
                          Icons.shopping_bag_outlined,
                          color: Colors.white,
                          size: 24,
                        ),
                      ),
                    ],
                  ),
                ),

                // Contenu
                Expanded(
                  child: items.isEmpty
                      ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            width: 120,
                            height: 120,
                            decoration: BoxDecoration(
                              color: Colors.grey.shade100,
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.shopping_bag_outlined,
                              size: 60,
                              color: Colors.grey.shade400,
                            ),
                          ),
                          const SizedBox(height: 24),
                          Text(
                            'Votre panier est vide',
                            style: GoogleFonts.openSans(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'Ajoutez des produits pour commencer vos achats',
                            style: GoogleFonts.openSans(
                              fontSize: 14,
                              color: Colors.grey.shade600,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 32),
                          InkWell(
                            onTap: () => Navigator.pop(context),
                            borderRadius: BorderRadius.circular(12),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 32,
                                vertical: 14,
                              ),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [_primaryColor, _primaryColor],
                                ),
                                borderRadius: BorderRadius.circular(12),
                                boxShadow: [
                                  BoxShadow(
                                    color: _primaryColor.withOpacity(0.4),
                                    blurRadius: 12,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: Text(
                                'Continuer mes achats',
                                style: GoogleFonts.poppins(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    )
                  : SingleChildScrollView(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          // Liste des articles
                          ...items.asMap().entries.map((entry) {
                            final index = entry.key;
                            final item = entry.value;
                            return _buildCartItem(index, item);
                          }).toList(),

                          const SizedBox(height: 16),

                          // Section Code promo
                          Container(
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.08),
                                  blurRadius: 16,
                                  offset: const Offset(0, 4),
                                  spreadRadius: 0,
                                ),
                              ],
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    const Icon(
                                      Icons.local_offer_outlined,
                                      color: Color(0xFF10B981),
                                      size: 22,
                                    ),
                                    const SizedBox(width: 12),
                                    Text(
                                      'Code promo',
                                      style: GoogleFonts.openSans(
                                        fontSize: 15,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.black87,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                Row(
                                  children: [
                                    Expanded(
                                      child: TextField(
                                        controller: _promoController,
                                        decoration: InputDecoration(
                                          hintText: 'Entrez votre code...',
                                          hintStyle: GoogleFonts.openSans(
                                            fontSize: 13,
                                            color: Colors.grey.shade400,
                                          ),
                                          filled: true,
                                          fillColor: Colors.grey.shade50,
                                          contentPadding: const EdgeInsets.symmetric(
                                            horizontal: 14,
                                            vertical: 12,
                                          ),
                                          border: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(10),
                                            borderSide: BorderSide(color: Colors.grey.shade200),
                                          ),
                                          enabledBorder: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(10),
                                            borderSide: BorderSide(color: Colors.grey.shade200),
                                          ),
                                          focusedBorder: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(10),
                                            borderSide: const BorderSide(
                                              color: Color(0xFF10B981),
                                              width: 1.5,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    ElevatedButton(
                                      onPressed: () {
                                        // Appliquer le code promo
                                      },
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: const Color(0xFF10B981),
                                        foregroundColor: Colors.white,
                                        elevation: 0,
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 24,
                                          vertical: 16,
                                        ),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                      ),
                                      child: Text(
                                        'Appliquer',
                                        style: GoogleFonts.poppins(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 16),

                          // Résumé de la commande
                          Container(
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.04),
                                  blurRadius: 10,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(8),
                                      decoration: BoxDecoration(
                                        color: _primaryColor.withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Icon(
                                        Icons.receipt_long,
                                        color: _primaryColor,
                                        size: 20,
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Text(
                                      'Résumé de la commande',
                                      style: GoogleFonts.openSans(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.black87,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 16),
                                // Sous-total
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      'Sous-total',
                                      style: GoogleFonts.openSans(
                                        fontSize: 14,
                                        color: Colors.grey.shade600,
                                      ),
                                    ),
                                    Text(
                                      '$total FCFA',
                                      style: GoogleFonts.poppins(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.black87,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 16),
                                const Divider(height: 1),
                                const SizedBox(height: 16),
                                // Total
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      'Total',
                                      style: GoogleFonts.openSans(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.black87,
                                      ),
                                    ),
                                    Row(
                                      crossAxisAlignment: CrossAxisAlignment.end,
                                      children: [
                                        Text(
                                          '$total',
                                          style: GoogleFonts.poppins(
                                            fontSize: 26,
                                            fontWeight: FontWeight.bold,
                                            color: _primaryColor,
                                            height: 1,
                                          ),
                                        ),
                                        const SizedBox(width: 4),
                                        Padding(
                                          padding: const EdgeInsets.only(bottom: 2),
                                          child: Text(
                                            'FCFA',
                                            style: GoogleFonts.poppins(
                                              fontSize: 14,
                                              fontWeight: FontWeight.w600,
                                              color: _primaryColor,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 100),
                        ],
                      ),
                    ),
            ),
          ],
        ),
      ),
        ],
      ),
      // Bouton Commander maintenant
      bottomNavigationBar: items.isEmpty
          ? null
          : Container(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 20),
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
              child: SafeArea(
                top: false,
                child: InkWell(
                  onTap: () async {
                    // Attendre le résultat de CommandeScreen
                    final orderCompleted = await Navigator.push<bool>(
                      context,
                      MaterialPageRoute(
                        builder: (context) => BoutiqueThemeProvider(
                          shop: widget.shop,
                          child: CommandeScreen(
                            shopId: widget.shopId,
                            shop: widget.shop,
                          ),
                        ),
                      ),
                    );

                    // Si une commande a été passée avec succès, propager le résultat
                    // pour que HomeScreen puisse rafraîchir le stock des produits
                    if (orderCompleted == true && mounted) {
                      Navigator.pop(context, true);
                    }
                  },
                  borderRadius: BorderRadius.circular(14),
                  child: Container(
                    height: 54,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [_primaryColor, _primaryColor],
                      ),
                      borderRadius: BorderRadius.circular(14),
                      boxShadow: [
                        BoxShadow(
                          color: _primaryColor.withOpacity(0.4),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Center(
                      child: Text(
                        'Commander maintenant',
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
    );
  }

  Widget _buildCartItem(int index, Map<String, dynamic> item) {
    final String? imageUrl = _getFullImageUrl(item['image']?.toString());
    final int? discount = _getDiscount(item);
    final int subtotal = (item['price'] as int) * (item['quantity'] as int);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 16,
            offset: const Offset(0, 4),
            spreadRadius: 0,
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Image du produit avec badge réduction
              Stack(
                clipBehavior: Clip.none,
                children: [
                  Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      color: Colors.grey.shade100,
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: imageUrl != null
                          ? Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: Image.network(
                                imageUrl,
                                width: 100,
                                height: 100,
                                fit: BoxFit.contain,
                                errorBuilder: (context, error, stackTrace) {
                                  return Center(
                                    child: Icon(
                                      Icons.shopping_bag_outlined,
                                      size: 40,
                                      color: Colors.grey.shade400,
                                    ),
                                  );
                                },
                              ),
                            )
                          : Center(
                              child: Icon(
                                Icons.shopping_bag_outlined,
                                size: 40,
                                color: Colors.grey.shade400,
                              ),
                            ),
                    ),
                  ),
                  // Badge réduction
                  if (discount != null)
                    Positioned(
                      top: 0,
                      left: 0,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFFF43F5E), Color(0xFFEC4899)],
                          ),
                          borderRadius: const BorderRadius.only(
                            topLeft: Radius.circular(16),
                            bottomRight: Radius.circular(12),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.auto_awesome, size: 10, color: Colors.white),
                            const SizedBox(width: 4),
                            Text(
                              '-$discount%',
                              style: GoogleFonts.poppins(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),

              const SizedBox(width: 16),

              // Informations produit
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Nom du produit
                    Text(
                      item['name'],
                      style: GoogleFonts.openSans(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),

                    // Prix
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          '${item['price']}',
                          style: GoogleFonts.poppins(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: const Color.fromARGB(255, 9, 9, 9),
                          ),
                        ),
                        const SizedBox(width: 4),
                        Padding(
                          padding: const EdgeInsets.only(bottom: 3),
                          child: Text(
                            'FCFA',
                            style: GoogleFonts.poppins(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: const Color.fromARGB(255, 162, 160, 166),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // Contrôles de quantité et suppression
                    Row(
                      children: [
                        // Contrôles de quantité
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.grey.shade50,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.grey.shade200),
                          ),
                          child: Row(
                            children: [
                              // Bouton -
                              GestureDetector(
                                onTap: () {
                                  if (item['quantity'] > 1) {
                                    _cartManager.updateQuantity(
                                      index,
                                      item['quantity'] - 1,
                                    );
                                  }
                                },
                                child: Container(
                                  width: 36,
                                  height: 36,
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: const Icon(
                                    Icons.remove,
                                    size: 18,
                                    color: Color.fromARGB(255, 146, 16, 135),
                                  ),
                                ),
                              ),

                              // Quantité
                              SizedBox(
                                width: 40,
                                child: Center(
                                  child: Text(
                                    '${item['quantity']}',
                                    style: GoogleFonts.poppins(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: const Color.fromARGB(221, 0, 0, 0),
                                    ),
                                  ),
                                ),
                              ),

                              // Bouton +
                              GestureDetector(
                                onTap: () {
                                  final error = _cartManager.updateQuantity(
                                    index,
                                    item['quantity'] + 1,
                                  );

                                  if (error != null) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(error),
                                        backgroundColor: Colors.red,
                                        duration: const Duration(seconds: 2),
                                      ),
                                    );
                                  }
                                },
                                child: Container(
                                  width: 36,
                                  height: 36,
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: [_primaryColor, _primaryColor],
                                    ),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: const Icon(
                                    Icons.add,
                                    size: 18,
                                    color: Colors.white,

                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),

                        const Spacer(),

                        // Bouton supprimer
                        GestureDetector(
                          onTap: () {
                            _cartManager.removeItem(index);
                          },
                          child: Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: const Color(0xFFFEE2E2),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(
                              Icons.delete_rounded,
                              size: 20,
                              color: Color(0xFFEF4444),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // Sous-total
          Container(
            padding: const EdgeInsets.only(top: 12),
            decoration: BoxDecoration(
              border: Border(
                top: BorderSide(
                  color: Colors.grey.shade200,
                  width: 1,
                ),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Sous-total',
                  style: GoogleFonts.openSans(
                    fontSize: 14,
                    color: Colors.grey.shade600,
                  ),
                ),
                Text(
                  '${subtotal.toStringAsFixed(0)} FCFA',
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
