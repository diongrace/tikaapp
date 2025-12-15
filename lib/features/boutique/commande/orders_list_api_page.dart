import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../services/order_service.dart';
import '../../../services/device_service.dart';
import '../../../services/models/order_model.dart';
import 'order_tracking_api_page.dart';
import '../../../core/services/boutique_theme_provider.dart';
import '../../../core/services/storage_service.dart';
import '../loading_screens/loading_screens.dart';

/// Page de liste des commandes utilisant l'API
class OrdersListApiPage extends StatefulWidget {
  final String? customerPhone; // Optionnel : si l'utilisateur est connecté

  const OrdersListApiPage({
    super.key,
    this.customerPhone,
  });

  @override
  State<OrdersListApiPage> createState() => _OrdersListApiPageState();
}

class _OrdersListApiPageState extends State<OrdersListApiPage> {
  bool _isLoading = true;
  bool _hasError = false;
  String? _errorMessage;
  List<Order> _orders = [];
  int _currentPage = 1;
  bool _hasMorePages = false;

  @override
  void initState() {
    super.initState();
    _loadOrders();
  }

  /// Naviguer vers la page de tracking avec récupération du téléphone si besoin
  Future<void> _navigateToTracking(Order order) async {
    String phoneToUse = order.customerPhone;

    // Si le téléphone de la commande est vide, récupérer depuis les infos client
    if (phoneToUse.isEmpty) {
      final customerInfo = await StorageService.getCustomerInfo();
      final savedPhone = customerInfo['phone'];
      if (savedPhone != null && savedPhone.isNotEmpty) {
        phoneToUse = savedPhone;
      }
    }

    if (!mounted) return;

    final shop = BoutiqueThemeProvider.shopOf(context);
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => BoutiqueThemeProvider(
          shop: shop,
          child: OrderTrackingApiPage(
            orderNumber: order.orderNumber,
            customerPhone: phoneToUse,
          ),
        ),
      ),
    );
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
      print('🔍 [OrdersListApiPage] Récupération du device fingerprint...');
      final deviceFingerprint = await DeviceService.getDeviceFingerprint();
      print('📱 [OrdersListApiPage] Device Fingerprint: $deviceFingerprint');

      // Appeler l'API pour récupérer les commandes par appareil
      print('📤 [OrdersListApiPage] Appel API getOrdersByDevice...');
      final response = await OrderService.getOrdersByDevice(
        deviceFingerprint: deviceFingerprint,
        page: loadMore ? _currentPage + 1 : 1,
      );

      final orders = response['orders'] as List<Order>;
      final pagination = response['pagination'] as Map<String, dynamic>;

      print('✅ [OrdersListApiPage] ${orders.length} commandes récupérées');
      if (orders.isNotEmpty) {
        print('📋 [OrdersListApiPage] Première commande:');
        print('   - ID: ${orders[0].id}');
        print('   - Numéro: ${orders[0].orderNumber}');
        print('   - Statut: ${orders[0].status}');
        print('   - Total: ${orders[0].totalAmount}');
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

      print('✅ [OrdersListApiPage] État mis à jour: ${_orders.length} commandes affichées');
    } catch (e) {
      print('❌ [OrdersListApiPage] Erreur: $e');
      setState(() {
        _hasError = true;
        _errorMessage = e.toString().replaceAll('Exception: ', '');
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Container(
              color: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: const Icon(Icons.arrow_back, size: 24),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Text(
                      'Mes commandes',
                      style: GoogleFonts.openSans(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  // Bouton rafraîchir
                  IconButton(
                    icon: const Icon(Icons.refresh, size: 24),
                    onPressed: () => _loadOrders(),
                  ),
                ],
              ),
            ),

            // Contenu
            Expanded(
              child: _buildContent(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent() {
    if (_isLoading && _orders.isEmpty) {
      return const OrdersHistoryLoadingScreen();
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
                  backgroundColor: BoutiqueThemeProvider.of(context).primary,
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
      color: BoutiqueThemeProvider.of(context).primary,
      child: ListView.builder(
        padding: const EdgeInsets.all(20),
        itemCount: _orders.length + (_hasMorePages ? 1 : 0),
        itemBuilder: (context, index) {
          if (index == _orders.length) {
            // Bouton "Charger plus"
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Center(
                child: ElevatedButton(
                  onPressed: () => _loadOrders(loadMore: true),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: BoutiqueThemeProvider.of(context).primary,
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

          final order = _orders[index];
          return _buildOrderCard(context, order);
        },
      ),
    );
  }

  // État vide
  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.shopping_bag_outlined,
              size: 64,
              color: Colors.grey.shade400,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Aucune commande',
            style: GoogleFonts.openSans(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade700,
            ),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40),
            child: Text(
              'Vous n\'avez pas encore passé de commande sur cet appareil',
              textAlign: TextAlign.center,
              style: GoogleFonts.openSans(
                fontSize: 14,
                color: Colors.grey.shade600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Carte de commande
  Widget _buildOrderCard(BuildContext context, Order order) {
    final statusColor = _getStatusColor(order.status);
    final statusLabel = _getStatusLabel(order.status);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _navigateToTracking(order),
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // En-tête avec numéro et statut
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Commande #${order.orderNumber}',
                            style: GoogleFonts.openSans(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _formatDate(order.createdAt),
                            style: GoogleFonts.openSans(
                              fontSize: 13,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: statusColor,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        statusLabel,
                        style: GoogleFonts.openSans(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Divider(color: Colors.grey.shade200),
                const SizedBox(height: 16),

                // Informations de la commande
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildInfoColumn(
                      icon: Icons.store_outlined,
                      label: 'Boutique',
                      value: 'Shop #${order.shopId}',
                    ),
                    _buildInfoColumn(
                      icon: Icons.local_shipping_outlined,
                      label: 'Service',
                      value: order.serviceType,
                    ),
                    _buildInfoColumn(
                      icon: Icons.attach_money,
                      label: 'Total',
                      value: '${order.totalAmount.toInt()} FCFA',
                      valueColor: BoutiqueThemeProvider.of(context).primary,
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Bouton voir détails
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton.icon(
                    onPressed: () => _navigateToTracking(order),
                    icon: const Icon(Icons.arrow_forward, size: 18),
                    label: Text(
                      'Voir détails',
                      style: GoogleFonts.openSans(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Colonne d'information
  Widget _buildInfoColumn({
    required IconData icon,
    required String label,
    required String value,
    Color? valueColor,
  }) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: Colors.grey.shade600),
              const SizedBox(width: 4),
              Flexible(
                child: Text(
                  label,
                  style: GoogleFonts.openSans(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: GoogleFonts.openSans(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: valueColor ?? Colors.black87,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  // Obtenir la couleur du statut selon l'API
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
        return const Color(0xFFF44336);
      default:
        return Colors.grey;
    }
  }

  // Obtenir le label du statut
  String _getStatusLabel(String status) {
    switch (status) {
      case 'reçue':
        return 'Reçue';
      case 'en_traitement':
        return 'En préparation';
      case 'prête':
        return 'Prête';
      case 'en_livraison':
        return 'En livraison';
      case 'livrée':
        return 'Livrée';
      case 'annulée':
        return 'Annulée';
      default:
        return status;
    }
  }

  // Formater la date
  String _formatDate(DateTime date) {
    final months = [
      'janvier', 'février', 'mars', 'avril', 'mai', 'juin',
      'juillet', 'août', 'septembre', 'octobre', 'novembre', 'décembre'
    ];

    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }
}
