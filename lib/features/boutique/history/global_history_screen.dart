import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../services/order_service.dart';
import '../../../services/device_service.dart';
import '../../../services/models/order_model.dart';
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

  @override
  void initState() {
    super.initState();
    _loadOrders();
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

  void _showOrderDetails(Order order) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => _buildOrderDetailsSheet(order),
    );
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black87),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Historique des commandes',
          style: GoogleFonts.openSans(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.black87),
            onPressed: () => _loadOrders(),
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(
            height: 1,
            color: Colors.grey[200],
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
    final statusColor = _getStatusColor(order.status);
    final statusInfo = _getStatusInfo(order.status);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // En-tête avec nom de la boutique
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey[50],
              borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
            ),
            child: Row(
              children: [
                // Icône boutique
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: const Color(0xFF8936A8).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.store,
                    size: 20,
                    color: Color(0xFF8936A8),
                  ),
                ),
                const SizedBox(width: 12),
                // Nom de la boutique
                Expanded(
                  child: Text(
                    order.shopName ?? 'Boutique #${order.shopId}',
                    style: GoogleFonts.openSans(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF8936A8),
                    ),
                  ),
                ),
                // Statut
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        statusInfo['icon'],
                        style: const TextStyle(fontSize: 12),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        statusInfo['label'],
                        style: GoogleFonts.openSans(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: statusColor,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Séparateur
          Container(
            height: 1,
            color: Colors.grey[200],
          ),

          // Corps de la commande
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Numéro de commande et date
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '#${order.orderNumber}',
                      style: GoogleFonts.openSans(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    Row(
                      children: [
                        Icon(
                          Icons.calendar_today,
                          size: 14,
                          color: Colors.grey[600],
                        ),
                        const SizedBox(width: 6),
                        Text(
                          _formatDate(order.createdAt),
                          style: GoogleFonts.openSans(
                            fontSize: 13,
                            color: Colors.grey[700],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                // Résumé
                Text(
                  '${order.itemsCount > 0 ? order.itemsCount : order.items.length} article${(order.itemsCount > 0 ? order.itemsCount : order.items.length) > 1 ? 's' : ''} - Total : ${order.totalAmount.toInt()} FCFA',
                  style: GoogleFonts.openSans(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 16),
                // Boutons
                Row(
                  children: [
                    // Bouton Voir détails
                    Expanded(
                      child: InkWell(
                        onTap: () => _showOrderDetails(order),
                        borderRadius: BorderRadius.circular(8),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          decoration: BoxDecoration(
                            border: Border.all(color: const Color(0xFF8936A8)),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Center(
                            child: Text(
                              'Voir détails',
                              style: GoogleFonts.openSans(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: const Color(0xFF8936A8),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    // Bouton Suivre
                    Expanded(
                      child: InkWell(
                        onTap: () => _navigateToTracking(order),
                        borderRadius: BorderRadius.circular(8),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFF8936A8), Color(0xFFB932D6)],
                            ),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Center(
                            child: Text(
                              'Suivre',
                              style: GoogleFonts.openSans(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                            ),
                          ),
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
    );
  }

  Widget _buildOrderDetailsSheet(Order order) {
    final statusColor = _getStatusColor(order.status);
    final statusInfo = _getStatusInfo(order.status);

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.8,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Barre de handle
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // Contenu scrollable
          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Boutique
                  Row(
                    children: [
                      Container(
                        width: 50,
                        height: 50,
                        decoration: BoxDecoration(
                          color: const Color(0xFF8936A8).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(
                          Icons.store,
                          size: 25,
                          color: Color(0xFF8936A8),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          order.shopName ?? 'Boutique #${order.shopId}',
                          style: GoogleFonts.openSans(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFF8936A8),
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 20),

                  // En-tête commande
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '#${order.orderNumber}',
                            style: GoogleFonts.openSans(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _formatDate(order.createdAt),
                            style: GoogleFonts.openSans(
                              fontSize: 14,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: statusColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              statusInfo['icon'],
                              style: const TextStyle(fontSize: 16),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              statusInfo['label'],
                              style: GoogleFonts.openSans(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: statusColor,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),

                  // Articles
                  Text(
                    'Articles (${order.items.length})',
                    style: GoogleFonts.openSans(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 12),

                  ...order.items.map((item) {
                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.grey[50],
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.grey[200]!),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  item.productName ?? 'Produit',
                                  style: GoogleFonts.openSans(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.black87,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Quantité: ${item.quantity}',
                                  style: GoogleFonts.openSans(
                                    fontSize: 12,
                                    color: Colors.grey[600],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Text(
                            '${(item.price * item.quantity).toInt()} F',
                            style: GoogleFonts.openSans(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: const Color(0xFF8936A8),
                            ),
                          ),
                        ],
                      ),
                    );
                  }),

                  const SizedBox(height: 16),

                  // Ligne de séparation
                  Container(
                    height: 1,
                    color: Colors.grey[300],
                  ),

                  const SizedBox(height: 16),

                  // Informations de livraison
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.grey[50],
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey[200]!),
                    ),
                    child: Column(
                      children: [
                        // Mode de récupération
                        Row(
                          children: [
                            Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                color: const Color(0xFF8936A8).withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Icon(
                                Icons.local_shipping_outlined,
                                color: Color(0xFF8936A8),
                                size: 20,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Mode de récupération',
                                    style: GoogleFonts.openSans(
                                      fontSize: 12,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    order.serviceType,
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
                        const SizedBox(height: 16),
                        // Client
                        Row(
                          children: [
                            Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                color: const Color(0xFF4CAF50).withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Icon(
                                Icons.person_outline,
                                color: Color(0xFF4CAF50),
                                size: 20,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Client',
                                    style: GoogleFonts.openSans(
                                      fontSize: 12,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    order.customerName,
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
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

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
                      Text(
                        '${order.totalAmount.toInt()} FCFA',
                        style: GoogleFonts.openSans(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF8936A8),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),

                  // Boutons
                  Row(
                    children: [
                      // Bouton Fermer
                      Expanded(
                        child: GestureDetector(
                          onTap: () => Navigator.pop(context),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            decoration: BoxDecoration(
                              border: Border.all(color: const Color(0xFF8936A8)),
                              borderRadius: BorderRadius.circular(30),
                            ),
                            child: Center(
                              child: Text(
                                'Fermer',
                                style: GoogleFonts.openSans(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: const Color(0xFF8936A8),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      // Bouton Suivre
                      Expanded(
                        child: GestureDetector(
                          onTap: () {
                            Navigator.pop(context);
                            _navigateToTracking(order);
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [Color(0xFF8936A8), Color(0xFFB932D6)],
                                begin: Alignment.centerLeft,
                                end: Alignment.centerRight,
                              ),
                              borderRadius: BorderRadius.circular(30),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFF8936A8).withOpacity(0.3),
                                  blurRadius: 12,
                                  offset: const Offset(0, 6),
                                ),
                              ],
                            ),
                            child: Center(
                              child: Text(
                                'Suivre',
                                style: GoogleFonts.openSans(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              color: const Color(0xFF8936A8).withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.receipt_long,
              size: 60,
              color: Color(0xFF8936A8),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Aucune commande',
            style: GoogleFonts.openSans(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 48),
            child: Text(
              'Vous n\'avez pas encore passé de commande sur cet appareil',
              textAlign: TextAlign.center,
              style: GoogleFonts.openSans(
                fontSize: 14,
                color: Colors.grey[600],
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
