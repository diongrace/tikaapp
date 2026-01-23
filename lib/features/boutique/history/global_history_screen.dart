import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../services/order_service.dart';
import '../../../services/device_service.dart';
import '../../../services/shop_service.dart';
import '../../../services/product_service.dart';
import '../../../services/models/order_model.dart';
import '../../../services/models/product_model.dart';
import '../../../core/services/storage_service.dart';
import '../commande/order_tracking_api_page.dart';

/// Écran d'historique global de toutes les commandes du client
/// Utilise l'API pour récupérer les commandes via device_fingerprint
class GlobalHistoryScreen extends StatefulWidget {
  const GlobalHistoryScreen({super.key});

  @override
  State<GlobalHistoryScreen> createState() => _GlobalHistoryScreenState();
}

class _GlobalHistoryScreenState extends State<GlobalHistoryScreen> {
  bool _isLoading = true;
  bool _hasError = false;
  String? _errorMessage;
  List<Order> _orders = [];
  int _currentPage = 1;
  bool _hasMorePages = false;

  // Cache des logos des boutiques
  final Map<int, String?> _shopLogosCache = {};

  // Cache des produits (id -> Product)
  final Map<int, Product> _productsCache = {};

  @override
  void initState() {
    super.initState();
    _loadOrders();
  }

  /// Récupérer le logo d'une boutique (avec cache)
  Future<String?> _getShopLogo(int shopId) async {
    // Vérifier le cache d'abord
    if (_shopLogosCache.containsKey(shopId)) {
      return _shopLogosCache[shopId];
    }

    try {
      final shop = await ShopService.getShopById(shopId);
      final logoUrl = shop.logoUrl.isNotEmpty ? shop.logoUrl : null;
      _shopLogosCache[shopId] = logoUrl;
      return logoUrl;
    } catch (e) {
      print('❌ Erreur récupération logo boutique $shopId: $e');
      _shopLogosCache[shopId] = null;
      return null;
    }
  }

  /// Charger les logos de toutes les boutiques des commandes
  Future<void> _loadShopLogos() async {
    // Récupérer les IDs uniques des boutiques
    final shopIds = _orders.map((o) => o.shopId).toSet();

    for (final shopId in shopIds) {
      if (!_shopLogosCache.containsKey(shopId)) {
        await _getShopLogo(shopId);
      }
    }

    // Rafraîchir l'UI
    if (mounted) {
      setState(() {});
    }
  }

  Future<void> _loadOrders({bool loadMore = false}) async {
    if (loadMore && !_hasMorePages) return;

    setState(() {
      if (!loadMore) {
        _isLoading = true;
        _hasError = false;
        _currentPage = 1;
      }
    });

    try {
      // Récupérer le device fingerprint
      final deviceFingerprint = await DeviceService.getDeviceFingerprint();
      print('📱 [GlobalHistory] Device Fingerprint: $deviceFingerprint');

      // Appeler l'API pour récupérer les commandes par appareil
      final response = await OrderService.getOrdersByDevice(
        deviceFingerprint: deviceFingerprint,
        page: loadMore ? _currentPage + 1 : 1,
      );

      print('📦 [GlobalHistory] Response type: ${response.runtimeType}');
      print('📦 [GlobalHistory] Orders type: ${response['orders'].runtimeType}');

      // Correction: la méthode retourne déjà une List<Order>
      final List<Order> orders = List<Order>.from(response['orders']);
      final pagination = response['pagination'] as Map<String, dynamic>;

      print('✅ [GlobalHistory] ${orders.length} commande(s) récupérée(s)');
      if (orders.isNotEmpty) {
        print('📋 [GlobalHistory] Première commande: ${orders[0].orderNumber}');
      } else {
        print('ℹ️ [GlobalHistory] Aucune commande trouvée pour cet appareil');
      }

      setState(() {
        if (loadMore) {
          _orders.addAll(orders);
          _currentPage++;
        } else {
          _orders = orders;
        }
        _hasMorePages = pagination['current_page'] < pagination['last_page'];
        _isLoading = false;
      });

      // Charger les logos des boutiques en arrière-plan
      _loadShopLogos();
    } catch (e, stackTrace) {
      print('❌ [GlobalHistory] Erreur détaillée: $e');
      print('❌ [GlobalHistory] Stack trace: $stackTrace');
      setState(() {
        _hasError = true;
        _errorMessage = e.toString().replaceAll('Exception: ', '');
        _isLoading = false;
      });
    }
  }

  /// Naviguer vers la page de suivi avec demande du téléphone si nécessaire
  Future<void> _navigateToTracking(Order order) async {
    String customerPhone = order.customerPhone;

    // Étape 1: Si le téléphone est vide, essayer de le récupérer automatiquement
    if (customerPhone.isEmpty) {
      print('⚠️ Téléphone manquant dans la commande, recherche automatique...');

      // Essayer de récupérer depuis les infos client sauvegardées
      final customerInfo = await StorageService.getCustomerInfo();
      String? storedPhone = customerInfo['phone'];

      // Si toujours vide, essayer depuis la carte de fidélité
      if (storedPhone == null || storedPhone.isEmpty) {
        final loyaltyCard = await StorageService.getLoyaltyCard();
        if (loyaltyCard != null && loyaltyCard['phone'] != null) {
          storedPhone = loyaltyCard['phone'].toString();
        }
      }

      // Si on a trouvé un téléphone, l'utiliser directement
      if (storedPhone != null && storedPhone.isNotEmpty) {
        print('✅ Téléphone trouvé automatiquement: $storedPhone');
        customerPhone = storedPhone;

        // Naviguer directement vers la page de suivi
        if (mounted) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => OrderTrackingApiPage(
                orderNumber: order.orderNumber,
                customerPhone: customerPhone,
              ),
            ),
          );
        }
        return;
      }

      // Étape 2: Si toujours vide, demander à l'utilisateur de l'entrer
      print('⚠️ Téléphone non trouvé, demande à l\'utilisateur...');

      final TextEditingController phoneController = TextEditingController(
        text: storedPhone ?? '',
      );

      final phone = await showDialog<String>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(
            'Numéro de téléphone requis',
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Pour suivre votre commande, veuillez entrer le numéro de téléphone utilisé lors de la commande :',
                style: GoogleFonts.openSans(fontSize: 14),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: phoneController,
                keyboardType: TextInputType.phone,
                autofocus: true,
                decoration: InputDecoration(
                  labelText: 'Numéro de téléphone',
                  hintText: 'Ex: 0700000000',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  prefixIcon: const Icon(Icons.phone),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                'Annuler',
                style: GoogleFonts.openSans(
                  color: Colors.grey.shade600,
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                if (phoneController.text.isNotEmpty) {
                  Navigator.pop(context, phoneController.text);
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF8936A8),
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
              child: Text(
                'Confirmer',
                style: GoogleFonts.openSans(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      );

      if (phone == null || phone.isEmpty) {
        return; // L'utilisateur a annulé
      }

      customerPhone = phone;

      // Sauvegarder le téléphone pour la prochaine fois
      await StorageService.saveCustomerPhone(customerPhone);
      print('✅ Téléphone sauvegardé: $customerPhone');
    }

    // Naviguer vers la page de suivi
    if (mounted) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => OrderTrackingApiPage(
            orderNumber: order.orderNumber,
            customerPhone: customerPhone,
          ),
        ),
      );
    }
  }

  /// Afficher les détails de la commande
  /// Récupère les détails complets via l'API avant d'afficher
  Future<void> _showOrderDetails(Order order) async {
    // Afficher un loader
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(color: Color(0xFF8936A8)),
      ),
    );

    try {
      // Récupérer les détails complets de la commande
      Order fullOrder = order;
      List<Map<String, dynamic>> productsDetails = [];

      if (order.items.isEmpty) {
        // Essayer d'abord getOrderByNumber (pas besoin de téléphone)
        try {
          fullOrder = await OrderService.getOrderByNumber(order.orderNumber);
          print('✅ Détails récupérés par numéro: ${fullOrder.items.length} items');
        } catch (e) {
          print('⚠️ getOrderByNumber échoué: $e');

          // Essayer avec trackOrder
          try {
            final customerInfo = await StorageService.getCustomerInfo();
            String? phone = customerInfo['phone'];

            if (phone == null || phone.isEmpty) {
              final loyaltyCard = await StorageService.getLoyaltyCard();
              if (loyaltyCard != null && loyaltyCard['phone'] != null) {
                phone = loyaltyCard['phone'].toString();
              }
            }

            if (phone != null && phone.isNotEmpty) {
              fullOrder = await OrderService.trackOrder(
                orderNumber: order.orderNumber,
                customerPhone: phone,
              );
              print('✅ Détails complets récupérés via trackOrder: ${fullOrder.items.length} items');
            }
          } catch (e2) {
            print('⚠️ trackOrder échoué: $e2');
          }
        }
      }

      // Récupérer les détails des produits (images, noms) via ProductService
      for (final item in fullOrder.items) {
        String productName = item.productName ?? '';
        String productImage = item.image ?? '';
        double price = item.price;

        // Si les infos sont manquantes et qu'on a un productId, récupérer les détails
        if (item.productId != null && (productName.isEmpty || productImage.isEmpty)) {
          try {
            final product = await ProductService.getProductById(item.productId!);
            if (productName.isEmpty) productName = product.name;
            if (productImage.isEmpty) productImage = product.primaryImageUrl ?? '';
            if (price == 0 && product.price != null) price = product.price!.toDouble();
            print('✅ Produit ${item.productId} récupéré: $productName');
          } catch (e) {
            print('⚠️ Erreur récupération produit ${item.productId}: $e');
          }
        }

        productsDetails.add({
          'name': productName.isNotEmpty ? productName : 'Produit',
          'image': productImage,
          'price': price,
          'quantity': item.quantity,
        });
      }

      print('📦 Produits avec détails: ${productsDetails.length}');

      // Fermer le loader
      if (mounted) Navigator.pop(context);

      // Afficher le bottom sheet avec les détails
      if (mounted) {
        showModalBottomSheet(
          context: context,
          backgroundColor: Colors.transparent,
          isScrollControlled: true,
          builder: (context) => _buildOrderDetailsSheet(fullOrder, productsDetails),
        );
      }
    } catch (e) {
      print('❌ Erreur globale: $e');
      // Fermer le loader
      if (mounted) Navigator.pop(context);

      // Afficher quand même avec les données partielles
      if (mounted) {
        showModalBottomSheet(
          context: context,
          backgroundColor: Colors.transparent,
          isScrollControlled: true,
          builder: (context) => _buildOrderDetailsSheet(order, []),
        );
      }
    }
  }

  // Obtenir la couleur du statut
  Color _getStatusColor(String status) {
    switch (status) {
      case 'reçue':
        return const Color(0xFFFFA726);
      case 'en_traitement':
        return const Color(0xFF42A5F5);
      case 'prête':
        return const Color(0xFF9C27B0);
      case 'en_livraison':
        return const Color(0xFFFF9800);
      case 'livrée':
        return const Color(0xFF4CAF50);
      case 'annulée':
        return const Color(0xFFE91E63);
      default:
        return Colors.grey;
    }
  }

  // Obtenir le label et l'icône du statut
  Map<String, dynamic> _getStatusInfo(String status) {
    switch (status) {
      case 'reçue':
        return {'label': 'Reçue', 'icon': '📥'};
      case 'en_traitement':
        return {'label': 'En préparation', 'icon': '⏳'};
      case 'prête':
        return {'label': 'Prête', 'icon': '✅'};
      case 'en_livraison':
        return {'label': 'En livraison', 'icon': '🚚'};
      case 'livrée':
        return {'label': 'Livrée', 'icon': '✅'};
      case 'annulée':
        return {'label': 'Annulée', 'icon': '❌'};
      default:
        return {'label': status, 'icon': '📦'};
    }
  }

  // Formater la date
  String _formatDate(DateTime date) {
    final months = [
      'Jan', 'Fév', 'Mar', 'Avr', 'Mai', 'Juin',
      'Juil', 'Août', 'Sep', 'Oct', 'Nov', 'Déc'
    ];
    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }

  // Formater la date et l'heure
  String _formatDateTime(DateTime date) {
    final months = [
      'Jan', 'Fév', 'Mar', 'Avr', 'Mai', 'Juin',
      'Juil', 'Août', 'Sep', 'Oct', 'Nov', 'Déc'
    ];
    final hour = date.hour.toString().padLeft(2, '0');
    final minute = date.minute.toString().padLeft(2, '0');
    return '${date.day} ${months[date.month - 1]} ${date.year} à $hour:$minute';
  }

  // Obtenir le label du mode de paiement
  String _getPaymentMethodLabel(String method) {
    switch (method.toLowerCase()) {
      case 'especes':
      case 'cash':
        return 'Espèces';
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

  // Obtenir l'icône du mode de paiement
  IconData _getPaymentMethodIcon(String method) {
    switch (method.toLowerCase()) {
      case 'especes':
      case 'cash':
        return Icons.payments_outlined;
      case 'mobile_money':
      case 'mobile':
      case 'wave':
      case 'orange_money':
      case 'mtn_money':
        return Icons.phone_android;
      case 'carte':
      case 'card':
        return Icons.credit_card;
      default:
        return Icons.payment;
    }
  }

  @override
  Widget build(BuildContext context) {
    const Color primaryColor = Color(0xFF670C88);

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: primaryColor.withOpacity(0.08),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.arrow_back_ios_rounded,
              color: primaryColor,
              size: 18,
            ),
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Historique',
              style: GoogleFonts.poppins(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF1E1E2E),
              ),
            ),
            Text(
              'Vos commandes',
              style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: FontWeight.w400,
                color: Colors.grey[500],
              ),
            ),
          ],
        ),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 16),
            child: IconButton(
              icon: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: primaryColor.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.refresh_rounded,
                  color: primaryColor,
                  size: 20,
                ),
              ),
              onPressed: () => _loadOrders(),
            ),
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(
            height: 1,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.transparent,
                  primaryColor.withOpacity(0.1),
                  primaryColor.withOpacity(0.1),
                  Colors.transparent,
                ],
                stops: const [0.0, 0.2, 0.8, 1.0],
              ),
            ),
          ),
        ),
      ),
      body: _buildContent(),
    );
  }

  Widget _buildContent() {
    if (_isLoading && _orders.isEmpty) {
      return const Center(
        child: CircularProgressIndicator(
          color: Color(0xFF8936A8),
        ),
      );
    }

    if (_hasError && _orders.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.error_outline,
                size: 64,
                color: Colors.red,
              ),
              const SizedBox(height: 16),
              Text(
                'Erreur de chargement',
                style: GoogleFonts.openSans(
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
              ElevatedButton(
                onPressed: () => _loadOrders(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF8936A8),
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                ),
                child: Text(
                  'Réessayer',
                  style: GoogleFonts.openSans(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (_orders.isEmpty) {
      return _buildEmptyState();
    }

    return RefreshIndicator(
      onRefresh: () => _loadOrders(),
      color: const Color(0xFF8936A8),
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _orders.length + (_hasMorePages ? 1 : 0),
        itemBuilder: (context, index) {
          if (index == _orders.length) {
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Center(
                child: ElevatedButton(
                  onPressed: () => _loadOrders(loadMore: true),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF8936A8),
                  ),
                  child: Text(
                    'Charger plus',
                    style: GoogleFonts.openSans(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            );
          }
          return _buildOrderCard(_orders[index]);
        },
      ),
    );
  }

  Widget _buildOrderCard(Order order) {
    // Utiliser le logo du cache ou celui de la commande
    final shopLogo = _shopLogosCache[order.shopId] ?? order.shopLogo;
    final statusColor = _getStatusColor(order.status);
    final statusInfo = _getStatusInfo(order.status);

    const Color primaryColor = Color(0xFF670C88);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: primaryColor.withOpacity(0.08),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => _showOrderDetails(order),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                // En-tête avec boutique et statut
                Row(
                  children: [
                    // Logo de la boutique
                    Container(
                      width: 52,
                      height: 52,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: primaryColor.withOpacity(0.15),
                          width: 1.5,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: primaryColor.withOpacity(0.1),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: shopLogo != null && shopLogo.isNotEmpty
                            ? Image.network(
                                shopLogo,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) {
                                  return Container(
                                    color: primaryColor.withOpacity(0.1),
                                    child: const Icon(
                                      Icons.store_rounded,
                                      size: 26,
                                      color: primaryColor,
                                    ),
                                  );
                                },
                              )
                            : Container(
                                color: primaryColor.withOpacity(0.1),
                                child: const Icon(
                                  Icons.store_rounded,
                                  size: 26,
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
                            order.shopName ?? 'Boutique #${order.shopId}',
                            style: GoogleFonts.poppins(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFF1E1E2E),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 5),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.grey[200],
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              '#${order.orderNumber}',
                              style: GoogleFonts.robotoMono(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: const Color(0xFF4B5563),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Badge statut
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: statusColor.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            _getStatusIcon(order.status),
                            size: 16,
                            color: statusColor,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            statusInfo['label'],
                            style: GoogleFonts.inter(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: statusColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                // Séparateur
                Container(
                  margin: const EdgeInsets.symmetric(vertical: 14),
                  height: 1,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.transparent,
                        Colors.grey[200]!,
                        Colors.grey[200]!,
                        Colors.transparent,
                      ],
                      stops: const [0.0, 0.2, 0.8, 1.0],
                    ),
                  ),
                ),

                // Ligne inférieure avec date, articles et total
                Row(
                  children: [
                    // Date et heure
                    Icon(
                      Icons.schedule_rounded,
                      size: 16,
                      color: primaryColor,
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        _formatDateTime(order.createdAt),
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF374151),
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 12),
                    // Nombre d'articles
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: Colors.grey[200],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '${order.itemsCount > 0 ? order.itemsCount : order.items.length} art.',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF374151),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    // Total
                    Text(
                      '${order.totalAmount.toInt()} F',
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: const Color.fromARGB(255, 49, 49, 49),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Obtenir l'icône du statut
  IconData _getStatusIcon(String status) {
    switch (status) {
      case 'reçue':
        return Icons.inbox_rounded;
      case 'en_traitement':
        return Icons.hourglass_top_rounded;
      case 'prête':
        return Icons.check_circle_rounded;
      case 'en_livraison':
        return Icons.local_shipping_rounded;
      case 'livrée':
        return Icons.check_circle_rounded;
      case 'annulée':
        return Icons.cancel_rounded;
      default:
        return Icons.inventory_2_rounded;
    }
  }

  /// Widget pour afficher un produit dans la liste
  Widget _buildProductItem(String name, String? image, double price, int quantity) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Row(
        children: [
          // Image du produit
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: Colors.grey[200],
              borderRadius: BorderRadius.circular(10),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: image != null && image.isNotEmpty
                  ? Image.network(
                      image,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          color: Colors.grey[200],
                          child: Icon(
                            Icons.fastfood,
                            size: 28,
                            color: Colors.grey[400],
                          ),
                        );
                      },
                    )
                  : Container(
                      color: Colors.grey[200],
                      child: Icon(
                        Icons.fastfood,
                        size: 28,
                        color: Colors.grey[400],
                      ),
                    ),
            ),
          ),
          const SizedBox(width: 12),
          // Détails du produit
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
                const SizedBox(height: 4),
                Text(
                  'Quantité: $quantity',
                  style: GoogleFonts.openSans(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
          // Prix
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${(price * quantity).toInt()} F',
                style: GoogleFonts.openSans(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF8936A8),
                ),
              ),
              if (quantity > 1)
                Text(
                  '${price.toInt()} F/unité',
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
  }

  Widget _buildOrderDetailsSheet(Order order, List<Map<String, dynamic>> productsDetails) {
    final statusColor = _getStatusColor(order.status);
    final statusInfo = _getStatusInfo(order.status);
    // Utiliser le logo du cache ou celui de la commande
    final shopLogo = _shopLogosCache[order.shopId] ?? order.shopLogo;
    // Vérifier si on a des détails de produits enrichis
    final hasProductDetails = productsDetails.isNotEmpty;

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.9,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header avec gradient et infos boutique
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  const Color(0xFF8936A8),
                  const Color(0xFFB932D6).withOpacity(0.9),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
            ),
            child: SafeArea(
              bottom: false,
              child: Column(
                children: [
                  // Barre de handle
                  Container(
                    margin: const EdgeInsets.only(top: 12),
                    width: 48,
                    height: 5,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.4),
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
                    child: Column(
                      children: [
                        // Logo boutique et infos
                        Row(
                          children: [
                            // Logo de la boutique
                            Container(
                              width: 64,
                              height: 64,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(16),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.15),
                                    blurRadius: 12,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(15),
                                child: shopLogo != null && shopLogo.isNotEmpty
                                    ? Image.network(
                                        shopLogo,
                                        fit: BoxFit.cover,
                                        errorBuilder: (context, error, stackTrace) {
                                          return Container(
                                            color: Colors.grey[100],
                                            child: const Icon(
                                              Icons.store_rounded,
                                              size: 32,
                                              color: Color(0xFF8936A8),
                                            ),
                                          );
                                        },
                                      )
                                    : Container(
                                        color: Colors.grey[100],
                                        child: const Icon(
                                          Icons.store_rounded,
                                          size: 32,
                                          color: Color(0xFF8936A8),
                                        ),
                                      ),
                              ),
                            ),
                            const SizedBox(width: 16),
                            // Infos boutique
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    order.shopName ?? 'Boutique #${order.shopId}',
                                    style: GoogleFonts.poppins(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 4),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withOpacity(0.2),
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: Text(
                                      '#${order.orderNumber}',
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
                          ],
                        ),
                        const SizedBox(height: 20),
                        // Statut et Date en row
                        Row(
                          children: [
                            // Badge Statut
                            Expanded(
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Row(
                                  children: [
                                    Container(
                                      width: 28,
                                      height: 28,
                                      decoration: BoxDecoration(
                                        color: statusColor.withOpacity(0.12),
                                        borderRadius: BorderRadius.circular(7),
                                      ),
                                      child: Center(
                                        child: Text(
                                          statusInfo['icon'],
                                          style: const TextStyle(fontSize: 12),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            'Statut',
                                            style: GoogleFonts.openSans(
                                              fontSize: 9,
                                              color: Colors.grey[500],
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                          Text(
                                            statusInfo['label'],
                                            style: GoogleFonts.poppins(
                                              fontSize: 11,
                                              fontWeight: FontWeight.w600,
                                              color: statusColor,
                                            ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            // Date
                            Expanded(
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Row(
                                  children: [
                                    Container(
                                      width: 28,
                                      height: 28,
                                      decoration: BoxDecoration(
                                        color: const Color(0xFF8936A8).withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(7),
                                      ),
                                      child: const Icon(
                                        Icons.schedule_rounded,
                                        size: 14,
                                        color: Color(0xFF8936A8),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            'Date',
                                            style: GoogleFonts.openSans(
                                              fontSize: 9,
                                              color: Colors.grey[500],
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                          Text(
                                            _formatDate(order.createdAt),
                                            style: GoogleFonts.poppins(
                                              fontSize: 11,
                                              fontWeight: FontWeight.w600,
                                              color: Colors.black87,
                                            ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
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
            ),
          ),

          // Contenu scrollable
          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Section Produits
                  Row(
                    children: [
                      Container(
                        width: 4,
                        height: 20,
                        decoration: BoxDecoration(
                          color: const Color(0xFF8936A8),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        'Produits commandés',
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
                        ),
                      ),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFF8936A8).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          '${hasProductDetails ? productsDetails.length : order.items.length} article${(hasProductDetails ? productsDetails.length : order.items.length) > 1 ? 's' : ''}',
                          style: GoogleFonts.openSans(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF8936A8),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Liste des produits
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.grey[50],
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.grey[200]!),
                    ),
                    child: Column(
                      children: [
                        if (hasProductDetails)
                          ...productsDetails.asMap().entries.map((entry) {
                            final index = entry.key;
                            final product = entry.value;
                            final name = product['name'] as String;
                            final image = product['image'] as String?;
                            final price = product['price'] as double;
                            final quantity = product['quantity'] as int;
                            final isLast = index == productsDetails.length - 1;

                            return _buildProductItemModern(name, image, price, quantity, isLast);
                          })
                        else if (order.items.isNotEmpty)
                          ...order.items.asMap().entries.map((entry) {
                            final index = entry.key;
                            final item = entry.value;
                            final isLast = index == order.items.length - 1;

                            return _buildProductItemModern(
                              item.productName ?? 'Produit',
                              item.image,
                              item.price,
                              item.quantity,
                              isLast,
                            );
                          })
                        else
                          Padding(
                            padding: const EdgeInsets.all(20),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.info_outline_rounded, color: Colors.grey[400], size: 20),
                                const SizedBox(width: 8),
                                Text(
                                  'Détails des produits non disponibles',
                                  style: GoogleFonts.openSans(
                                    fontSize: 13,
                                    color: Colors.grey[500],
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Infos de commande
                  Row(
                    children: [
                      Container(
                        width: 4,
                        height: 20,
                        decoration: BoxDecoration(
                          color: const Color(0xFF4CAF50),
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

                  // Cartes d'info en grille
                  Row(
                    children: [
                      // Mode de paiement
                      Expanded(
                        child: _buildInfoCard(
                          icon: _getPaymentMethodIcon(order.paymentMethod),
                          iconColor: const Color(0xFF4CAF50),
                          label: 'Paiement',
                          value: _getPaymentMethodLabel(order.paymentMethod),
                        ),
                      ),
                      const SizedBox(width: 12),
                      // Mode de récupération
                      Expanded(
                        child: _buildInfoCard(
                          icon: order.serviceType.toLowerCase().contains('livraison')
                              ? Icons.delivery_dining_rounded
                              : Icons.store_mall_directory_rounded,
                          iconColor: const Color(0xFF8936A8),
                          label: 'Récupération',
                          value: order.serviceType.isNotEmpty ? order.serviceType : 'Non spécifié',
                        ),
                      ),
                    ],
                  ),

                  // Adresse de livraison si disponible
                  if (order.deliveryAddress != null && order.deliveryAddress!.isNotEmpty) ...[
                    const SizedBox(height: 10),
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFF9800).withOpacity(0.08),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: const Color(0xFFFF9800).withOpacity(0.2)),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 32,
                            height: 32,
                            decoration: BoxDecoration(
                              color: const Color(0xFFFF9800).withOpacity(0.15),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(
                              Icons.location_on_rounded,
                              color: Color(0xFFFF9800),
                              size: 16,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Adresse de livraison',
                                  style: GoogleFonts.openSans(
                                    fontSize: 9,
                                    color: Colors.grey[600],
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                Text(
                                  order.deliveryAddress!,
                                  style: GoogleFonts.openSans(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.black87,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],

                  const SizedBox(height: 16),

                  // Total
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          const Color(0xFF8936A8).withOpacity(0.08),
                          const Color(0xFFB932D6).withOpacity(0.04),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: const Color(0xFF8936A8).withOpacity(0.15),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Total de la commande',
                              style: GoogleFonts.openSans(
                                fontSize: 12,
                                color: Colors.grey[600],
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${order.totalAmount.toInt()} FCFA',
                              style: GoogleFonts.poppins(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                                color: const Color(0xFF8936A8),
                              ),
                            ),
                          ],
                        ),
                        Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: const Color(0xFF8936A8).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(
                            Icons.receipt_long_rounded,
                            color: Color(0xFF8936A8),
                            size: 22,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Boutons
                  Row(
                    children: [
                      // Bouton Fermer
                      Expanded(
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: () => Navigator.pop(context),
                            borderRadius: BorderRadius.circular(12),
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              decoration: BoxDecoration(
                                border: Border.all(color: Colors.grey[300]!, width: 1.5),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Center(
                                child: Text(
                                  'Fermer',
                                  style: GoogleFonts.poppins(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.grey[700],
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      // Bouton Suivre
                      Expanded(
                        flex: 2,
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: () {
                              Navigator.pop(context);
                              _navigateToTracking(order);
                            },
                            borderRadius: BorderRadius.circular(12),
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: [Color(0xFF8936A8), Color(0xFFB932D6)],
                                  begin: Alignment.centerLeft,
                                  end: Alignment.centerRight,
                                ),
                                borderRadius: BorderRadius.circular(12),
                                boxShadow: [
                                  BoxShadow(
                                    color: const Color(0xFF8936A8).withOpacity(0.3),
                                    blurRadius: 10,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(
                                    Icons.local_shipping_rounded,
                                    color: Colors.white,
                                    size: 18,
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    'Suivre la commande',
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
                  const SizedBox(height: 8),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Widget pour afficher une carte d'info
  Widget _buildInfoCard({
    required IconData icon,
    required Color iconColor,
    required String label,
    required String value,
  }) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: iconColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              icon,
              color: iconColor,
              size: 16,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: GoogleFonts.openSans(
                    fontSize: 9,
                    color: Colors.grey[500],
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  value,
                  style: GoogleFonts.openSans(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Widget moderne pour afficher un produit
  Widget _buildProductItemModern(String name, String? image, double price, int quantity, bool isLast) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        border: isLast ? null : Border(bottom: BorderSide(color: Colors.grey[200]!)),
      ),
      child: Row(
        children: [
          // Image du produit
          Container(
            width: 64,
            height: 64,
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
                            size: 28,
                            color: Colors.grey[400],
                          ),
                        );
                      },
                    )
                  : Container(
                      color: Colors.grey[100],
                      child: Icon(
                        Icons.fastfood_rounded,
                        size: 28,
                        color: Colors.grey[400],
                      ),
                    ),
            ),
          ),
          const SizedBox(width: 14),
          // Détails du produit
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
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
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
          const SizedBox(width: 8),
          // Prix
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${(price * quantity).toInt()} F',
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF8936A8),
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
  }

  Widget _buildEmptyState() {
    const Color primaryColor = Color(0xFF670C88);

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: primaryColor.withOpacity(0.08),
                shape: BoxShape.circle,
                border: Border.all(
                  color: primaryColor.withOpacity(0.15),
                  width: 2,
                ),
              ),
              child: Icon(
                Icons.receipt_long_rounded,
                size: 56,
                color: primaryColor.withOpacity(0.6),
              ),
            ),
            const SizedBox(height: 28),
            Text(
              'Aucune commande',
              style: GoogleFonts.poppins(
                fontSize: 22,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF1E1E2E),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Vous n\'avez pas encore passé de commande sur cet appareil',
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                fontSize: 14,
                color: Colors.grey[500],
                height: 1.6,
              ),
            ),
            const SizedBox(height: 32),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              decoration: BoxDecoration(
                color: primaryColor.withOpacity(0.06),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: primaryColor.withOpacity(0.15),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.info_outline_rounded,
                    size: 18,
                    color: primaryColor.withOpacity(0.7),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    'Scannez un QR code pour commander',
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: primaryColor.withOpacity(0.8),
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
