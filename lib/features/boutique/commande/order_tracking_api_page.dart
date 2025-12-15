import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../../../services/order_service.dart';
import '../../../services/models/order_model.dart';
import '../../../core/services/boutique_theme_provider.dart';
import '../../../core/services/storage_service.dart';
import '../home/home_online_screen.dart';

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

class _OrderTrackingApiPageState extends State<OrderTrackingApiPage> {
  bool _isLoading = true;
  bool _hasError = false;
  String? _errorMessage;
  Order? _order;

  @override
  void initState() {
    super.initState();
    _loadOrderData();
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

  /// Récupérer le shopId depuis différentes sources
  int? _getShopId() {
    // 1. Depuis la commande chargée
    if (_order != null && _order!.shopId > 0) {
      return _order!.shopId;
    }

    // 2. Depuis le thème de la boutique (contexte)
    try {
      final shop = BoutiqueThemeProvider.shopOf(context);
      if (shop != null && shop.id > 0) {
        return shop.id;
      }
    } catch (e) {
      // Ignorer si pas de shop dans le contexte
    }

    return null;
  }

 
  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        final shopId = _getShopId();
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(
            builder: (context) => HomeScreen(shopId: shopId),
          ),
          (route) => false,
        );
        return false;
      },
      child: Scaffold(
        backgroundColor: const Color(0xFFF5F5F5),
        body: SafeArea(
          child: Column(
            children: [
              // Header violet avec numéro de commande
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      BoutiqueThemeProvider.of(context).primary,
                      const Color(0xFFD48EFC)
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.arrow_back, color: Colors.white),
                          onPressed: () {
                            final shopId = _getShopId();
                            if (shopId != null) {
                              Navigator.of(context).pushAndRemoveUntil(
                                MaterialPageRoute(
                                  builder: (context) => HomeScreen(shopId: shopId),
                                ),
                                (route) => false,
                              );
                            } else {
                              // Si pas de shopId, juste pop
                              Navigator.of(context).pop();
                            }
                          },
                        ),
                        Expanded(
                          child: Text(
                            'Suivi de commande',
                            style: GoogleFonts.openSans(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.refresh, color: Colors.white),
                          onPressed: _loadOrderData,
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Padding(
                      padding: const EdgeInsets.only(left: 56), // Aligné avec le texte après le bouton retour
                      child: Text(
                        '#${widget.orderNumber}',
                        style: GoogleFonts.openSans(
                          fontSize: 14,
                          color: Colors.white.withOpacity(0.9),
                        ),
                      ),
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
      ),
    );
  }

  Widget _buildContent() {
    if (_isLoading) {
      return Center(
        child: CircularProgressIndicator(
          color: BoutiqueThemeProvider.of(context).primary,
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
                onPressed: _loadOrderData,
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
          _buildOrderInfoCard(_order!),
          const SizedBox(height: 20),
          _buildOrderStatusCard(_order!),
          const SizedBox(height: 20),
          _buildCustomerInfoCard(_order!),
          const SizedBox(height: 20),
          _buildOrderedItemsCard(_order!),
          const SizedBox(height: 20),
        ],
      ),
    );
  }
   
  Widget _buildOrderInfoCard(Order order) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(
          color: Colors.black.withOpacity(0.05),
          blurRadius: 10,
          offset: const Offset(0, 2),
        )],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
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
              _buildStatusBadge(order.status),
            ],
          ),
          const SizedBox(height: 16),
          Divider(color: Colors.grey.shade200),
          const SizedBox(height: 16),
          _buildInfoRow('Boutique:', order.shopName ?? 'Boutique #${order.shopId}'),
          const SizedBox(height: 8),
          _buildInfoRow(
            'Total:',
            '${order.totalAmount.toInt()} FCFA',
            valueColor: BoutiqueThemeProvider.of(context).primary,
          ),
        ],
      ),
    );
  }

  Widget _buildStatusBadge(String status) {
    Color badgeColor;
    String badgeText;

    switch (status) {
      case 'reçue': badgeColor = const Color(0xFFFFA726); badgeText = 'Reçue'; break;
      case 'en_traitement': badgeColor = const Color(0xFF42A5F5); badgeText = 'En préparation'; break;
      case 'prête': badgeColor = const Color(0xFF9C27B0); badgeText = 'Prête'; break;
      case 'en_livraison': badgeColor = const Color(0xFFFF9800); badgeText = 'En livraison'; break;
      case 'annulée': badgeColor = const Color(0xFFF44336); badgeText = 'Annulée'; break;
      default: badgeColor = Colors.grey; badgeText = status;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: badgeColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        badgeText,
        style: GoogleFonts.openSans(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: Colors.white,
        ),
      ),
    );
  }

  Widget _buildOrderStatusCard(Order order) {
    final statuses = ['reçue', 'en_traitement', 'prête', 'en_livraison'];
    final statusLabels = {
      'reçue': 'Commande reçue',
      'en_traitement': 'En préparation',
      'prête': 'Prête',
      'en_livraison': 'En livraison',
    };
    final currentIndex = statuses.indexOf(order.status);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(
          color: Colors.black.withOpacity(0.05),
          blurRadius: 10,
          offset: const Offset(0, 2),
        )],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('État de la commande',
            style: GoogleFonts.openSans(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 20),
          ...statuses.asMap().entries.map((entry) {
            final index = entry.key;
            final status = entry.value;
            final label = statusLabels[status] ?? status;
            final isCompleted = index < currentIndex;
            final isCurrent = index == currentIndex;
            final isLast = index == statuses.length - 1;

            return _buildTimelineStep(
              icon: _getIconForStatus(status),
              title: label,
              subtitle: isCurrent ? 'En cours...' : '',
              isActive: isCurrent,
              isCompleted: isCompleted,
              isLast: isLast,
            );
          }).toList(),
        ],
      ),
    );
  }

  IconData _getIconForStatus(String status) {
    switch (status) {
      case 'reçue': return Icons.shopping_cart_checkout;
      case 'en_traitement': return Icons.inventory_2_outlined;
      case 'prête': return Icons.all_inbox;
      case 'en_livraison': return Icons.local_shipping_outlined;
      default: return Icons.circle_outlined;
    }
  }

  Widget _buildTimelineStep({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool isActive,
    required bool isCompleted,
    required bool isLast,
  }) {
    final Color iconColor = isActive
        ? BoutiqueThemeProvider.of(context).primary
        : isCompleted
            ? const Color(0xFF4CAF50)
            : Colors.grey.shade400;

    final Color lineColor = isCompleted ? BoutiqueThemeProvider.of(context).primary : Colors.grey.shade300;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: isActive || isCompleted
                    ? iconColor.withOpacity(0.15)
                    : Colors.grey.shade100,
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 20, color: iconColor),
            ),
            if (!isLast)
              Container(width: 2, height: 40, color: lineColor),
          ],
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(top: 8, bottom: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.openSans(
                    fontSize: 15,
                    fontWeight: isActive ? FontWeight.bold : FontWeight.w600,
                    color: isActive || isCompleted ? Colors.black87 : Colors.grey.shade500,
                  ),
                ),
                if (subtitle.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      subtitle,
                      style: GoogleFonts.openSans(
                        fontSize: 13,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCustomerInfoCard(Order order) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(
          color: Colors.black.withOpacity(0.05),
          blurRadius: 10,
          offset: const Offset(0, 2),
        )],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.person, color: Colors.green, size: 24),
              const SizedBox(width: 8),
              Text(
                'Informations client',
                style: GoogleFonts.openSans(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildCustomerInfoItem('Nom complet', order.customerName.isNotEmpty ? order.customerName : 'N/A'),
          if (order.customerPhone.isNotEmpty) ...[
            const SizedBox(height: 12),
            _buildCustomerInfoItem('Téléphone', order.customerPhone),
          ],
          if (order.deliveryAddress != null && order.deliveryAddress!.isNotEmpty) ...[
            const SizedBox(height: 12),
            _buildCustomerInfoItem('Adresse de livraison', order.deliveryAddress!),
          ],
          if (order.serviceType.isNotEmpty) ...[
            const SizedBox(height: 12),
            _buildCustomerInfoItem('Mode de récupération', order.serviceType),
          ],
        ],
      ),
    );
  }

  Widget _buildCustomerInfoItem(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: GoogleFonts.openSans(fontSize: 12, color: Colors.grey.shade600)),
        const SizedBox(height: 4),
        Text(value, style: GoogleFonts.openSans(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.black87)),
      ],
    );
  }

  Widget _buildOrderedItemsCard(Order order) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(
          color: Colors.black.withOpacity(0.05),
          blurRadius: 10,
          offset: const Offset(0, 2),
        )],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.shopping_bag, color: BoutiqueThemeProvider.of(context).primary, size: 24),
              const SizedBox(width: 8),
              Text('Articles commandés', style: GoogleFonts.openSans(fontSize: 16, fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 16),
          if (order.items.isNotEmpty)
            ...order.items.map((item) => _buildOrderItem(item))
          else
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Icon(Icons.inventory_2_outlined, color: BoutiqueThemeProvider.of(context).primary, size: 40),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${order.itemsCount} article${order.itemsCount > 1 ? 's' : ''}',
                          style: GoogleFonts.openSans(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.black87),
                        ),
                        const SizedBox(height: 4),
                        Text('Détails disponibles après traitement', style: GoogleFonts.openSans(fontSize: 13, color: Colors.grey.shade600)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildOrderItem(OrderItem item) {
    final fullImageUrl = _getFullImageUrl(item.image);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Container(
              width: 60,
              height: 60,
              color: Colors.grey.shade200,
              child: fullImageUrl != null
                  ? Image.network(
                      fullImageUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => Container(
                        color: Colors.grey.shade200,
                        child: Icon(Icons.image_outlined, size: 30, color: Colors.grey.shade400),
                      ),
                      loadingBuilder: (context, child, loadingProgress) {
                        if (loadingProgress == null) return child;
                        return Center(
                          child: CircularProgressIndicator(strokeWidth: 2, color: BoutiqueThemeProvider.of(context).primary),
                        );
                      },
                    )
                  : Icon(Icons.image_outlined, size: 30, color: Colors.grey.shade400),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item.productName ?? 'Produit', style: GoogleFonts.openSans(fontSize: 14, fontWeight: FontWeight.w600), maxLines: 2, overflow: TextOverflow.ellipsis),
                const SizedBox(height: 4),
                Text('Quantité: ${item.quantity}', style: GoogleFonts.openSans(fontSize: 13, color: Colors.grey.shade600)),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text('${(item.price * item.quantity).toInt()} FCFA', style: GoogleFonts.openSans(fontSize: 14, fontWeight: FontWeight.bold, color: BoutiqueThemeProvider.of(context).primary)),
              const SizedBox(height: 2),
              Text('${item.price.toInt()} FCFA/unité', style: GoogleFonts.openSans(fontSize: 11, color: Colors.grey.shade500)),
            ],
          ),
        ],
      ),
    );
  }

  String? _getFullImageUrl(String? url) {
    if (url == null || url.isEmpty) return null;
    if (url.startsWith('http://') || url.startsWith('https://')) return url;
    final cleanUrl = url.startsWith('/') ? url.substring(1) : url;
    return 'https://tika-ci.com/$cleanUrl';
  }

  Widget _buildInfoRow(String label, String value, {Color? valueColor}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: GoogleFonts.openSans(fontSize: 14, color: Colors.grey.shade600)),
        const SizedBox(width: 8),
        Expanded(
          child: Text(value, style: GoogleFonts.openSans(fontSize: 14, fontWeight: FontWeight.w600, color: valueColor ?? Colors.black87)),
        ),
      ],
    );
  }

  String _formatDate(DateTime date) {
    final months = [
      'janvier','février','mars','avril','mai','juin','juillet','août','septembre','octobre','novembre','décembre'
    ];
    return '${date.day} ${months[date.month - 1]} ${date.year} à ${date.hour.toString().padLeft(2,'0')}:${date.minute.toString().padLeft(2,'0')}';
  }
}
