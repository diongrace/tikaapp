import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:convert';
import '../../../services/order_service.dart';
import '../../../services/shop_service.dart';
import '../../../services/product_service.dart';
import '../../../services/models/order_model.dart';
import '../../../services/utils/api_endpoint.dart';
import '../../../core/services/boutique_theme_provider.dart';
import '../../../core/services/storage_service.dart';

/// Page de suivi de commande utilisant l'API
class OrderTrackingApiPage extends StatefulWidget {
  final String orderNumber;
  final String customerPhone;

  const OrderTrackingApiPage({
    super.key,
    required this.orderNumber,
    required this.customerPhone,
  });

  @override
  State<OrderTrackingApiPage> createState() => _OrderTrackingApiPageState();
}

class _OrderTrackingApiPageState extends State<OrderTrackingApiPage>
    with SingleTickerProviderStateMixin {
  bool _isLoading = true;
  bool _hasError = false;
  String? _errorMessage;
  Order? _order;
  String? _shopLogo;
  String? _shopPhone;

  // Détails enrichis des produits
  List<Map<String, dynamic>> _productsDetails = [];

  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat(reverse: true);
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.15).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
    _loadOrderData();
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  Future<void> _loadOrderData() async {
    setState(() {
      _isLoading = true;
      _hasError = false;
    });

    try {
      String customerPhone = widget.customerPhone;

      // Étape 1: Si vide, chercher dans le stockage local de la commande
      if (customerPhone.isEmpty) {
        final storedOrders = await _getStoredOrders();
        final matchingOrder = storedOrders.where(
          (o) => o['orderNumber'] == widget.orderNumber,
        ).firstOrNull;

        if (matchingOrder != null && matchingOrder['customerPhone'] != null) {
          customerPhone = matchingOrder['customerPhone'].toString();
        }
      }

      // Étape 2: Si toujours vide, chercher dans les infos client sauvegardées
      if (customerPhone.isEmpty) {
        final customerInfo = await StorageService.getCustomerInfo();
        final savedPhone = customerInfo['phone'];
        if (savedPhone != null && savedPhone.isNotEmpty) {
          customerPhone = savedPhone;
        }
      }

      // Étape 3: Si toujours vide, afficher une erreur
      if (customerPhone.isEmpty) {
        throw Exception(
          'Impossible de suivre la commande : numéro de téléphone manquant.'
        );
      }

      final order = await OrderService.trackOrder(
        orderNumber: widget.orderNumber,
        customerPhone: customerPhone,
      );

      // Charger les infos de la boutique
      if (order.shopId > 0) {
        try {
          final shop = await ShopService.getShopById(order.shopId);
          _shopLogo = shop.logoUrl.isNotEmpty ? shop.logoUrl : null;
          _shopPhone = (shop.phone?.isNotEmpty == true) ? shop.phone : null;
        } catch (e) {
          print('Erreur chargement boutique: $e');
        }
      }

      // Charger les détails des produits
      _productsDetails = await _loadProductsDetails(order);

      setState(() {
        _order = order;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _hasError = true;
        _errorMessage = e.toString().replaceAll('Exception: ', '');
        _isLoading = false;
      });
    }
  }

  Future<List<Map<String, dynamic>>> _getStoredOrders() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final ordersJson = prefs.getStringList('orders') ?? [];
      return ordersJson
          .map((json) => jsonDecode(json) as Map<String, dynamic>)
          .toList();
    } catch (e) {
      return [];
    }
  }

  /// Charger les détails des produits via l'API
  Future<List<Map<String, dynamic>>> _loadProductsDetails(Order order) async {
    List<Map<String, dynamic>> details = [];

    for (var item in order.items) {
      try {
        String? imageUrl;
        String productName = item.productName ?? 'Produit';
        double productPrice = item.price;

        // Essayer de charger les détails du produit via l'API si productId existe
        if (item.productId != null && item.productId! > 0) {
          try {
            final product = await ProductService.getProductById(item.productId!);

            // Utiliser le nom du produit si disponible
            if (product.name.isNotEmpty) {
              productName = product.name;
            }

            // Utiliser le prix du produit si le prix de l'item est 0
            if (item.price <= 0 && product.price != null && product.price! > 0) {
              productPrice = product.price!.toDouble();
            }

            // Construire l'URL complète de l'image depuis le produit
            if (product.primaryImageUrl != null && product.primaryImageUrl!.isNotEmpty) {
              imageUrl = product.primaryImageUrl!;
              if (!imageUrl.startsWith('http')) {
                imageUrl = '${Endpoints.storageBaseUrl}/${imageUrl.startsWith('/') ? imageUrl.substring(1) : imageUrl}';
              }
            }
          } catch (e) {
            print('Erreur chargement produit ${item.productId}: $e');
          }
        }

        // Si pas d'image du produit, utiliser l'image de l'item
        if ((imageUrl == null || imageUrl.isEmpty) && item.image != null && item.image!.isNotEmpty) {
          imageUrl = item.image;
          if (!imageUrl!.startsWith('http')) {
            imageUrl = '${Endpoints.storageBaseUrl}/${imageUrl.startsWith('/') ? imageUrl.substring(1) : imageUrl}';
          }
        }

        details.add({
          'id': item.productId ?? 0,
          'name': productName,
          'image': imageUrl,
          'price': productPrice,
          'quantity': item.quantity,
        });
      } catch (e) {
        // Si erreur globale, utiliser les données de base de l'item
        print('Erreur traitement item: $e');

        String? imageUrl = item.image;
        if (imageUrl != null && imageUrl.isNotEmpty && !imageUrl.startsWith('http')) {
          imageUrl = '${Endpoints.storageBaseUrl}/${imageUrl.startsWith('/') ? imageUrl.substring(1) : imageUrl}';
        }

        details.add({
          'id': item.productId ?? 0,
          'name': item.productName ?? 'Produit',
          'image': imageUrl,
          'price': item.price,
          'quantity': item.quantity,
        });
      }
    }

    return details;
  }

  Future<void> _callShop() async {
    if (_shopPhone != null && _shopPhone!.isNotEmpty) {
      final uri = Uri.parse('tel:$_shopPhone');
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri);
      }
    }
  }

  Future<void> _whatsappShop() async {
    if (_shopPhone != null && _shopPhone!.isNotEmpty) {
      // Nettoyer le numéro de téléphone
      String phone = _shopPhone!.replaceAll(RegExp(r'[^0-9]'), '');
      if (phone.startsWith('0')) {
        phone = '225$phone'; // Ajouter l'indicatif Côte d'Ivoire
      }
      final message = 'Bonjour, je souhaite avoir des informations sur ma commande #${widget.orderNumber}';
      final uri = Uri.parse('https://wa.me/$phone?text=${Uri.encodeComponent(message)}');
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final primaryColor = BoutiqueThemeProvider.of(context).primary;

    return WillPopScope(
      onWillPop: () async {
        Navigator.of(context).pop();
        return false;
      },
      child: Scaffold(
        backgroundColor: const Color(0xFFF8F9FA),
        body: Column(
          children: [
            // Header amélioré
            _buildHeader(primaryColor),
            // Contenu
            Expanded(
              child: _buildContent(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(Color primaryColor) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            primaryColor,
            primaryColor.withOpacity(0.8),
            const Color(0xFFD48EFC),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(28)),
        boxShadow: [
          BoxShadow(
            color: primaryColor.withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(8, 8, 16, 24),
          child: Column(
            children: [
              // Row avec bouton retour et titre
              Row(
                children: [
                  IconButton(
                    icon: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.arrow_back, color: Colors.white, size: 20),
                    ),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Suivi de commande',
                          style: GoogleFonts.poppins(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        Container(
                          margin: const EdgeInsets.only(top: 4),
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            '#${widget.orderNumber}',
                            style: GoogleFonts.openSans(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Bouton refresh
                  IconButton(
                    icon: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.refresh_rounded, color: Colors.white, size: 20),
                    ),
                    onPressed: _loadOrderData,
                  ),
                ],
              ),
              // Logo boutique si disponible
              if (_order != null && !_isLoading) ...[
                const SizedBox(height: 20),
                Row(
                  children: [
                    const SizedBox(width: 16),
                    // Logo boutique
                    Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.15),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(13),
                        child: _shopLogo != null && _shopLogo!.isNotEmpty
                            ? Image.network(
                                _shopLogo!,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) {
                                  return Container(
                                    color: Colors.grey[100],
                                    child: Icon(
                                      Icons.store_rounded,
                                      size: 28,
                                      color: primaryColor,
                                    ),
                                  );
                                },
                              )
                            : Container(
                                color: Colors.grey[100],
                                child: Icon(
                                  Icons.store_rounded,
                                  size: 28,
                                  color: primaryColor,
                                ),
                              ),
                      ),
                    ),
                    const SizedBox(width: 14),
                    // Infos boutique
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _order!.shopName ?? 'Boutique',
                            style: GoogleFonts.poppins(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${_order!.totalAmount.toInt()} FCFA',
                            style: GoogleFonts.poppins(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildContent() {
    if (_isLoading) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(
              color: BoutiqueThemeProvider.of(context).primary,
            ),
            const SizedBox(height: 16),
            Text(
              'Chargement de votre commande...',
              style: GoogleFonts.openSans(
                fontSize: 14,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      );
    }

    if (_hasError) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.error_outline_rounded,
                  size: 40,
                  color: Colors.red,
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'Erreur de chargement',
                style: GoogleFonts.poppins(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                _errorMessage ?? 'Une erreur est survenue',
                style: GoogleFonts.openSans(
                  fontSize: 14,
                  color: Colors.grey.shade600,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: _loadOrderData,
                icon: const Icon(Icons.refresh_rounded, size: 20),
                label: Text(
                  'Réessayer',
                  style: GoogleFonts.openSans(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: BoutiqueThemeProvider.of(context).primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (_order == null) {
      return Center(
        child: Text(
          'Commande introuvable',
          style: GoogleFonts.openSans(fontSize: 16),
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Timeline de statut
          _buildModernTimeline(_order!),
          const SizedBox(height: 20),
          // Infos de livraison
          _buildDeliveryInfo(_order!),
          const SizedBox(height: 20),
          // Contact boutique
          if (_shopPhone != null && _shopPhone!.isNotEmpty) ...[
            _buildContactSection(),
            const SizedBox(height: 20),
          ],
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildProductsDetails(Order order) {
    final primaryColor = BoutiqueThemeProvider.of(context).primary;
    final hasDetails = _productsDetails.isNotEmpty;
    final itemsCount = hasDetails
        ? _productsDetails.length
        : (order.items.isNotEmpty ? order.items.length : (order.itemsCount > 0 ? order.itemsCount : 1));

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Container(
                width: 4,
                height: 20,
                decoration: BoxDecoration(
                  color: primaryColor,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Détails de la commande',
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '$itemsCount article${itemsCount > 1 ? 's' : ''}',
                  style: GoogleFonts.openSans(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: primaryColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Liste des produits avec détails enrichis
          if (hasDetails)
            ..._productsDetails.asMap().entries.map((entry) {
              final index = entry.key;
              final product = entry.value;
              final isLast = index == _productsDetails.length - 1;
              final name = product['name'] as String;
              final image = product['image'] as String?;
              final price = product['price'] as double;
              final quantity = product['quantity'] as int;

              return Container(
                margin: EdgeInsets.only(bottom: isLast ? 0 : 12),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: Colors.grey[200]!),
                ),
                child: Row(
                  children: [
                    // Image du produit
                    Container(
                      width: 70,
                      height: 70,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey[200]!),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(11),
                        child: image != null && image.isNotEmpty
                            ? Image.network(
                                image,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) {
                                  return Container(
                                    color: Colors.grey[100],
                                    child: Icon(
                                      Icons.fastfood_rounded,
                                      size: 30,
                                      color: Colors.grey[400],
                                    ),
                                  );
                                },
                              )
                            : Container(
                                color: Colors.grey[100],
                                child: Icon(
                                  Icons.fastfood_rounded,
                                  size: 30,
                                  color: Colors.grey[400],
                                ),
                              ),
                      ),
                    ),
                    const SizedBox(width: 14),
                    // Nom et quantité
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            name,
                            style: GoogleFonts.openSans(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: Colors.black87,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.grey[200],
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              'Qté: $quantity',
                              style: GoogleFonts.openSans(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: Colors.grey[700],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 10),
                    // Prix
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          '${(price * quantity).toInt()} F',
                          style: GoogleFonts.poppins(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: primaryColor,
                          ),
                        ),
                        if (quantity > 1)
                          Text(
                            '${price.toInt()} F/u',
                            style: GoogleFonts.openSans(
                              fontSize: 11,
                              color: Colors.grey[500],
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              );
            })
          else
            // Si pas de détails des produits
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: BorderRadius.circular(14),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.inventory_2_outlined, color: primaryColor, size: 28),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '$itemsCount article${itemsCount > 1 ? 's' : ''} commandé${itemsCount > 1 ? 's' : ''}',
                          style: GoogleFonts.openSans(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Détails disponibles après traitement',
                          style: GoogleFonts.openSans(
                            fontSize: 12,
                            color: Colors.grey[500],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

          // Total
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  primaryColor.withOpacity(0.1),
                  primaryColor.withOpacity(0.05),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: primaryColor.withOpacity(0.2)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: primaryColor.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        Icons.receipt_long_rounded,
                        color: primaryColor,
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'Total',
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                    ),
                  ],
                ),
                Text(
                  '${order.totalAmount.toInt()} FCFA',
                  style: GoogleFonts.poppins(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: primaryColor,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModernTimeline(Order order) {
    final statuses = ['reçue', 'en_traitement', 'prête', 'en_livraison'];
    final statusLabels = {
      'reçue': 'Commande reçue',
      'en_traitement': 'En préparation',
      'prête': 'Prête à récupérer',
      'en_livraison': 'En livraison',
    };
    final statusDescriptions = {
      'reçue': 'Votre commande a été enregistrée',
      'en_traitement': 'La boutique prépare votre commande',
      'prête': 'Votre commande vous attend',
      'en_livraison': 'Le livreur est en route',
    };
    final statusIcons = {
      'reçue': Icons.shopping_cart_checkout_rounded,
      'en_traitement': Icons.restaurant_rounded,
      'prête': Icons.inventory_2_rounded,
      'en_livraison': Icons.delivery_dining_rounded,
    };
    // Couleurs spécifiques pour chaque étape
    final statusColors = {
      'reçue': const Color(0xFF4CAF50),          // Vert
      'en_traitement': const Color(0xFFFF9800),  // Orange
      'prête': const Color(0xFF2196F3),          // Bleu
      'en_livraison': const Color(0xFF4CAF50),   // Vert
    };

    // Mapper le statut de l'API vers nos étapes
    int currentIndex = _getStatusIndex(order.status, statuses);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 4,
                height: 20,
                decoration: BoxDecoration(
                  color: statusColors[order.status] ?? const Color(0xFF4CAF50),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 10),
              Text(
                'Suivi en temps réel',
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          ...statuses.asMap().entries.map((entry) {
            final index = entry.key;
            final status = entry.value;
            final label = statusLabels[status] ?? status;
            final description = statusDescriptions[status] ?? '';
            final icon = statusIcons[status] ?? Icons.circle;
            final stepColor = statusColors[status] ?? const Color(0xFF4CAF50);
            final isCompleted = index < currentIndex;
            final isCurrent = index == currentIndex;
            final isPassed = index <= currentIndex;
            final isLast = index == statuses.length - 1;

            return Column(
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Icône avec animation
                    Column(
                      children: [
                        isCurrent
                            ? AnimatedBuilder(
                                animation: _pulseAnimation,
                                builder: (context, child) {
                                  return Transform.scale(
                                    scale: _pulseAnimation.value,
                                    child: Container(
                                      width: 48,
                                      height: 48,
                                      decoration: BoxDecoration(
                                        gradient: LinearGradient(
                                          colors: [stepColor, stepColor.withOpacity(0.7)],
                                          begin: Alignment.topLeft,
                                          end: Alignment.bottomRight,
                                        ),
                                        shape: BoxShape.circle,
                                        boxShadow: [
                                          BoxShadow(
                                            color: stepColor.withOpacity(0.4),
                                            blurRadius: 12,
                                            offset: const Offset(0, 4),
                                          ),
                                        ],
                                      ),
                                      child: Icon(icon, size: 24, color: Colors.white),
                                    ),
                                  );
                                },
                              )
                            : Container(
                                width: 48,
                                height: 48,
                                decoration: BoxDecoration(
                                  color: isCompleted
                                      ? stepColor
                                      : Colors.grey[100],
                                  shape: BoxShape.circle,
                                  border: isCompleted
                                      ? null
                                      : Border.all(color: Colors.grey[300]!, width: 2),
                                ),
                                child: Icon(
                                  icon,
                                  size: 22,
                                  color: isCompleted ? Colors.white : Colors.grey[400],
                                ),
                              ),
                        if (!isLast)
                          Container(
                            width: 3,
                            height: 50,
                            margin: const EdgeInsets.symmetric(vertical: 4),
                            decoration: BoxDecoration(
                              color: isCompleted ? stepColor : Colors.grey[200],
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(width: 16),
                    // Contenu
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              label,
                              style: GoogleFonts.poppins(
                                fontSize: 15,
                                fontWeight: isPassed ? FontWeight.w600 : FontWeight.w500,
                                color: isPassed ? Colors.black87 : Colors.grey[400],
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              isCurrent
                                  ? 'En cours...'
                                  : isCompleted
                                      ? 'Terminé ✓'
                                      : description,
                              style: GoogleFonts.openSans(
                                fontSize: 13,
                                color: isCurrent
                                    ? stepColor
                                    : isCompleted
                                        ? stepColor
                                        : Colors.grey[500],
                                fontWeight: isPassed ? FontWeight.w600 : FontWeight.normal,
                              ),
                            ),
                            if (!isLast) const SizedBox(height: 16),
                          ],
                        ),
                      ),
                    ),
                    // Badge de statut à droite
                    if (isPassed)
                      Container(
                        margin: const EdgeInsets.only(top: 8),
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: stepColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              isCurrent ? Icons.hourglass_top_rounded : Icons.check_circle_rounded,
                              size: 14,
                              color: stepColor,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              isCurrent ? 'Actuel' : 'Fait',
                              style: GoogleFonts.openSans(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: stepColor,
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ],
            );
          }),
        ],
      ),
    );
  }

  Widget _buildDeliveryInfo(Order order) {
    final primaryColor = BoutiqueThemeProvider.of(context).primary;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 4,
                height: 20,
                decoration: BoxDecoration(
                  color: const Color(0xFFFF9800),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 10),
              Text(
                'Informations',
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Mode de récupération
          _buildInfoTile(
            icon: order.serviceType.toLowerCase().contains('livraison')
                ? Icons.delivery_dining_rounded
                : Icons.store_mall_directory_rounded,
            iconColor: primaryColor,
            label: 'Mode de récupération',
            value: order.serviceType.isNotEmpty ? order.serviceType : 'Retrait en boutique',
          ),
          if (order.deliveryAddress != null && order.deliveryAddress!.isNotEmpty) ...[
            const SizedBox(height: 12),
            _buildInfoTile(
              icon: Icons.location_on_rounded,
              iconColor: const Color(0xFFFF9800),
              label: 'Adresse de livraison',
              value: order.deliveryAddress!,
            ),
          ],
          const SizedBox(height: 12),
          _buildInfoTile(
            icon: Icons.schedule_rounded,
            iconColor: Colors.blue,
            label: 'Date de commande',
            value: _formatDate(order.createdAt),
          ),
          const SizedBox(height: 12),
          _buildInfoTile(
            icon: Icons.payments_rounded,
            iconColor: const Color(0xFF4CAF50),
            label: 'Paiement',
            value: _getPaymentMethodLabel(order.paymentMethod),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoTile({
    required IconData icon,
    required Color iconColor,
    required String label,
    required String value,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: iconColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: iconColor, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: GoogleFonts.openSans(
                    fontSize: 11,
                    color: Colors.grey[500],
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: GoogleFonts.openSans(
                    fontSize: 14,
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

  Widget _buildContactSection() {
    final primaryColor = BoutiqueThemeProvider.of(context).primary;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            primaryColor.withOpacity(0.08),
            primaryColor.withOpacity(0.03),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: primaryColor.withOpacity(0.15)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(
                  Icons.support_agent_rounded,
                  color: primaryColor,
                  size: 26,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Besoin d\'aide ?',
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                    ),
                    Text(
                      'Contactez la boutique directement',
                      style: GoogleFonts.openSans(
                        fontSize: 13,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              // Bouton Appeler
              Expanded(
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: _callShop,
                    borderRadius: BorderRadius.circular(14),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: primaryColor.withOpacity(0.3)),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.phone_rounded, color: primaryColor, size: 20),
                          const SizedBox(width: 8),
                          Text(
                            'Appeler',
                            style: GoogleFonts.poppins(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: primaryColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              // Bouton WhatsApp
              Expanded(
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: _whatsappShop,
                    borderRadius: BorderRadius.circular(14),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF25D366), Color(0xFF128C7E)],
                        ),
                        borderRadius: BorderRadius.circular(14),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF25D366).withOpacity(0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.chat_rounded, color: Colors.white, size: 20),
                          const SizedBox(width: 8),
                          Text(
                            'WhatsApp',
                            style: GoogleFonts.poppins(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
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
        ],
      ),
    );
  }

  String _getPaymentMethodLabel(String method) {
    switch (method.toLowerCase()) {
      case 'especes':
      case 'cash':
        return 'Espèces à la livraison';
      case 'mobile_money':
      case 'mobile':
        return 'Mobile Money';
      case 'carte':
      case 'card':
        return 'Carte bancaire';
      case 'wave':
        return 'Wave';
      case 'orange_money':
        return 'Orange Money';
      case 'mtn_money':
        return 'MTN Money';
      default:
        return method;
    }
  }

  String? _getFullImageUrl(String? url) {
    if (url == null || url.isEmpty) return null;
    if (url.startsWith('http://') || url.startsWith('https://')) return url;
    final cleanUrl = url.startsWith('/') ? url.substring(1) : url;
    return '${Endpoints.storageBaseUrl}/$cleanUrl';
  }

  String _formatDate(DateTime date) {
    final months = [
      'janvier', 'février', 'mars', 'avril', 'mai', 'juin',
      'juillet', 'août', 'septembre', 'octobre', 'novembre', 'décembre'
    ];
    return '${date.day} ${months[date.month - 1]} ${date.year} à ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }

  /// Mapper le statut de l'API vers l'index de la timeline
  int _getStatusIndex(String status, List<String> statuses) {
    final statusLower = status.toLowerCase().trim();

    // Mapping des différentes valeurs possibles de statut
    // Index 0: reçue
    if (statusLower == 'reçue' ||
        statusLower == 'recue' ||
        statusLower == 'received' ||
        statusLower == 'pending' ||
        statusLower == 'new' ||
        statusLower == 'nouvelle') {
      return 0;
    }

    // Index 1: en_traitement (en préparation)
    if (statusLower == 'en_traitement' ||
        statusLower == 'en traitement' ||
        statusLower == 'preparation' ||
        statusLower == 'en_preparation' ||
        statusLower == 'en préparation' ||
        statusLower == 'processing' ||
        statusLower == 'preparing') {
      return 1;
    }

    // Index 2: prête (à récupérer)
    if (statusLower == 'prête' ||
        statusLower == 'prete' ||
        statusLower == 'ready' ||
        statusLower == 'prêt' ||
        statusLower == 'pret' ||
        statusLower == 'a_recuperer' ||
        statusLower == 'à récupérer') {
      return 2;
    }

    // Index 3: en_livraison
    if (statusLower == 'en_livraison' ||
        statusLower == 'en livraison' ||
        statusLower == 'livraison' ||
        statusLower == 'delivering' ||
        statusLower == 'shipped' ||
        statusLower == 'delivery' ||
        statusLower == 'out_for_delivery' ||
        statusLower == 'livrée' ||
        statusLower == 'livree' ||
        statusLower == 'delivered' ||
        statusLower == 'terminée' ||
        statusLower == 'terminee' ||
        statusLower == 'completed' ||
        statusLower == 'done') {
      return 3;
    }

    // Par défaut, essayer indexOf
    final directIndex = statuses.indexOf(status);
    if (directIndex >= 0) return directIndex;

    // Sinon, retourner 0
    print('⚠️ Statut inconnu: $status - défaut à index 0');
    return 0;
  }
}
