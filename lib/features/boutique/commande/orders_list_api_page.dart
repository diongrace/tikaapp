import 'dart:convert';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:dio/dio.dart';
import '../../../services/order_service.dart';
import '../../../services/device_service.dart';
import '../../../services/auth_service.dart';
import '../../../services/models/order_model.dart';
import '../../../services/utils/api_endpoint.dart';
import 'order_tracking_api_page.dart';
import 'receipt_view_page.dart';
import '../../../core/services/boutique_theme_provider.dart';
import '../../../core/services/storage_service.dart';
import '../loading_screens/loading_screens.dart';

/// Page de liste des commandes - Design professionnel
class OrdersListApiPage extends StatefulWidget {
  final String? customerPhone;

  const OrdersListApiPage({
    super.key,
    this.customerPhone,
  });

  @override
  State<OrdersListApiPage> createState() => _OrdersListApiPageState();
}

class _OrdersListApiPageState extends State<OrdersListApiPage>
    with SingleTickerProviderStateMixin {
  bool _isLoading = true;
  bool _hasError = false;
  String? _errorMessage;
  List<Order> _orders = [];
  int _currentPage = 1;
  bool _hasMorePages = false;
  late AnimationController _animController;

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _loadOrders();
  }

  Future<void> _navigateToTracking(Order order) async {
    String phoneToUse = order.customerPhone;

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

  /// Vérifier si une commande est annulable
  bool _canCancel(Order order) {
    if (order.status == 'annulée' || order.status == 'livrée' || order.status == 'prete') return false;
    // Toutes les boutiques: annulable si statut = recue
    if (order.status == 'recue') return true;
    // Boutiques non-restaurant: aussi annulable si en_traitement ET < 20 min
    if (order.status == 'en_traitement') {
      final elapsed = DateTime.now().difference(order.createdAt);
      return elapsed.inMinutes < 20;
    }
    return false;
  }

  /// Temps restant pour annuler (en minutes)
  int _cancelMinutesLeft(Order order) {
    if (order.status != 'en_traitement') return -1;
    final elapsed = DateTime.now().difference(order.createdAt);
    return (20 - elapsed.inMinutes).clamp(0, 20);
  }

  Future<void> _reorder(Order order) async {
    if (!AuthService.isAuthenticated) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Connectez-vous pour recommander'), backgroundColor: Colors.orange),
      );
      return;
    }

    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Recommander', style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
        content: Text('Voulez-vous passer la meme commande #${order.orderNumber} ?', style: GoogleFonts.openSans(fontSize: 14)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text('Annuler', style: GoogleFonts.openSans(color: Colors.grey))),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF10B981)),
            child: Text('Oui', style: GoogleFonts.openSans(color: Colors.white, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );

    if (confirm != true || !mounted) return;

    try {
      final token = AuthService.authToken!;
      // Étape 1: Vérifier la disponibilité
      final checkResult = await OrderService.reorder(order.id, token);
      print('📋 REORDER checkResult: $checkResult');

      if (!mounted) return;

      // Étape 2: Afficher le récapitulatif
      final reorderData = checkResult['data'];
      final items = reorderData?['items'] as List? ?? [];
      final total = reorderData?['total'] ?? reorderData?['total_amount'] ?? order.totalAmount;

      final confirmReorder = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: Text('Récapitulatif', style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Commande #${order.orderNumber}', style: GoogleFonts.openSans(fontSize: 13, color: Colors.grey)),
              const SizedBox(height: 12),
              if (items.isNotEmpty)
                ...items.map((item) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 2),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(child: Text(
                        '${item['quantity'] ?? 1}x ${item['product_name'] ?? item['name'] ?? 'Produit'}',
                        style: GoogleFonts.openSans(fontSize: 13),
                      )),
                      Text('${item['price'] ?? ''} F', style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w600)),
                    ],
                  ),
                ))
              else
                Text('${order.itemsCount > 0 ? order.itemsCount : order.items.length} article(s)', style: GoogleFonts.openSans(fontSize: 13)),
              const Divider(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Total', style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
                  Text('$total F', style: GoogleFonts.poppins(fontWeight: FontWeight.w700, color: const Color(0xFF10B981))),
                ],
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text('Annuler', style: GoogleFonts.openSans(color: Colors.grey))),
            ElevatedButton(
              onPressed: () => Navigator.pop(ctx, true),
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF10B981)),
              child: Text('Confirmer', style: GoogleFonts.openSans(color: Colors.white, fontWeight: FontWeight.w600)),
            ),
          ],
        ),
      );

      if (confirmReorder != true || !mounted) return;

      // Étape 3: Confirmer la recommande
      final result = await OrderService.confirmReorder(orderId: order.id, token: token);
      print('📋 CONFIRM REORDER result: $result');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(result['message'] ?? 'Commande recréée !', textAlign: TextAlign.center), backgroundColor: const Color(0xFF10B981)),
        );
        await Future.delayed(const Duration(milliseconds: 800));
        if (mounted) await _loadOrders();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString().replaceAll('Exception: ', ''), textAlign: TextAlign.center), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _cancelOrder(Order order) async {
    if (!AuthService.isAuthenticated) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Connectez-vous pour annuler'), backgroundColor: Colors.orange),
      );
      return;
    }

    final reasonController = TextEditingController();
    final minutesLeft = _cancelMinutesLeft(order);

    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Annuler la commande', style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Voulez-vous annuler #${order.orderNumber} ?', style: GoogleFonts.openSans(fontSize: 14)),
            if (minutesLeft > 0) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFFFEF3C7),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'Temps restant: $minutesLeft min',
                  style: GoogleFonts.openSans(fontSize: 12, color: const Color(0xFFF59E0B), fontWeight: FontWeight.w600),
                ),
              ),
            ],
            const SizedBox(height: 16),
            TextField(
              controller: reasonController,
              maxLines: 2,
              maxLength: 500,
              decoration: InputDecoration(
                hintText: 'Raison (optionnel)',
                hintStyle: GoogleFonts.openSans(fontSize: 13),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text('Non', style: GoogleFonts.openSans(color: Colors.grey))),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, {'reason': reasonController.text}),
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFEF4444)),
            child: Text('Oui, annuler', style: GoogleFonts.openSans(color: Colors.white, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );

    if (result == null || !mounted) return;

    try {
      final token = AuthService.authToken!;
      final response = await OrderService.cancelOrder(order.id, token, reason: result['reason']?.toString());
      if (mounted) {
        final success = response['success'] == true;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(response['message'] ?? 'Commande annulée', textAlign: TextAlign.center),
            backgroundColor: success ? const Color(0xFFEF4444) : const Color(0xFFF59E0B),
          ),
        );
        if (success) _loadOrders();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString().replaceAll('Exception: ', ''), textAlign: TextAlign.center), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _rateOrder(Order order) async {
    if (!AuthService.isAuthenticated) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Connectez-vous pour noter'), backgroundColor: Colors.orange),
      );
      return;
    }

    int selectedRating = 5;
    final commentController = TextEditingController();

    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: Text('Noter', style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('#${order.orderNumber}', style: GoogleFonts.openSans(fontSize: 13, color: Colors.grey)),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(5, (i) => GestureDetector(
                  onTap: () => setDialogState(() => selectedRating = i + 1),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: Icon(
                      i < selectedRating ? Icons.star_rounded : Icons.star_outline_rounded,
                      color: const Color(0xFFF59E0B), size: 36,
                    ),
                  ),
                )),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: commentController,
                maxLines: 3,
                decoration: InputDecoration(
                  hintText: 'Commentaire global (optionnel)',
                  hintStyle: GoogleFonts.openSans(fontSize: 13),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: Text('Annuler', style: GoogleFonts.openSans(color: Colors.grey))),
            ElevatedButton(
              onPressed: () => Navigator.pop(ctx, {'rating': selectedRating, 'comment': commentController.text}),
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFF59E0B)),
              child: Text('Envoyer', style: GoogleFonts.openSans(color: Colors.white, fontWeight: FontWeight.w600)),
            ),
          ],
        ),
      ),
    );

    if (result == null || !mounted) return;

    try {
      final token = AuthService.authToken!;
      final rateItems = order.items.map((item) => {
        'order_item_id': item.id,
        'rating': result['rating'],
      }).toList();
      final response = await OrderService.rateOrder(
        orderId: order.id,
        token: token,
        items: rateItems,
        globalComment: result['comment']?.toString(),
      );
      if (mounted) {
        final alreadyRated = response['already_rated'] == true;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(response['message'] ?? 'Merci !', textAlign: TextAlign.center),
            backgroundColor: alreadyRated ? const Color(0xFFF59E0B) : const Color(0xFF10B981),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString().replaceAll('Exception: ', ''), textAlign: TextAlign.center), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _viewReceipt(Order order) async {
    if (order.id == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Recu non disponible'), backgroundColor: Colors.orange),
      );
      return;
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black26,
      builder: (ctx) => Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(width: 36, height: 36, child: CircularProgressIndicator(strokeWidth: 3)),
              const SizedBox(height: 16),
              Text('Chargement du recu...', style: GoogleFonts.poppins(fontSize: 14)),
            ],
          ),
        ),
      ),
    );

    try {
      final url = Endpoints.orderReceipt(order.id);
      await AuthService.ensureToken();
      final token = AuthService.authToken;

      final response = await Dio().get(
        url,
        options: Options(
          followRedirects: true,
          validateStatus: (status) => true,
          headers: {
            'Accept': 'application/json',
            if (token != null) 'Authorization': 'Bearer $token',
          },
        ),
      );

      if (!mounted) return;
      Navigator.of(context, rootNavigator: true).pop();

      if (response.statusCode != 200) {
        throw Exception('Erreur ${response.statusCode}');
      }

      final data = response.data is String ? jsonDecode(response.data) : response.data;
      if (data is! Map<String, dynamic> || data['success'] != true) {
        throw Exception('Recu non disponible');
      }

      final shop = BoutiqueThemeProvider.shopOf(context);
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => BoutiqueThemeProvider(
            shop: shop,
            child: ReceiptViewPage(receiptData: data),
          ),
        ),
      );
    } catch (e) {
      if (mounted) {
        Navigator.of(context, rootNavigator: true).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Impossible de charger le recu'), backgroundColor: Colors.red),
        );
      }
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
      final deviceFingerprint = await DeviceService.getDeviceFingerprint();

      final response = await OrderService.getOrdersByDevice(
        deviceFingerprint: deviceFingerprint,
        page: loadMore ? _currentPage + 1 : 1,
      );

      final orders = response['orders'] as List<Order>;
      final pagination = response['pagination'] as Map<String, dynamic>;

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
      _animController.forward(from: 0);
    } catch (e) {
      setState(() {
        _hasError = true;
        _errorMessage = e.toString().replaceAll('Exception: ', '');
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final primaryColor = BoutiqueThemeProvider.of(context).primary;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      body: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          // -- AppBar moderne --
          SliverAppBar(
            backgroundColor: Colors.white,
            elevation: 0,
            scrolledUnderElevation: 0.5,
            pinned: true,
            expandedHeight: 100,
            leading: Padding(
              padding: const EdgeInsets.all(8),
              child: GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: Icon(Icons.arrow_back_ios_new, size: 16, color: Colors.grey.shade700),
                ),
              ),
            ),
            actions: [
              Padding(
                padding: const EdgeInsets.only(right: 12),
                child: GestureDetector(
                  onTap: () => _loadOrders(),
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [primaryColor.withOpacity(0.1), primaryColor.withOpacity(0.05)],
                      ),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: primaryColor.withOpacity(0.2)),
                    ),
                    child: Icon(Icons.refresh_rounded, size: 20, color: primaryColor),
                  ),
                ),
              ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              centerTitle: true,
              titlePadding: const EdgeInsets.only(bottom: 12),
              title: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Text(
                    'Mes commandes',
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF1E293B),
                    ),
                  ),
                  if (_orders.isNotEmpty)
                    Text(
                      '${_orders.length} commande${_orders.length > 1 ? 's' : ''}',
                      style: GoogleFonts.openSans(
                        fontSize: 10,
                        color: Colors.grey.shade500,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                ],
              ),
            ),
          ),
          // -- Contenu --
          ..._buildSliverContent(),
        ],
      ),
    );
  }

  List<Widget> _buildSliverContent() {
    if (_isLoading && _orders.isEmpty) {
      return [
        const SliverFillRemaining(
          child: OrdersHistoryLoadingScreen(),
        ),
      ];
    }

    if (_hasError && _orders.isEmpty) {
      return [
        SliverFillRemaining(child: _buildErrorState()),
      ];
    }

    if (_orders.isEmpty) {
      return [
        SliverFillRemaining(child: _buildEmptyState()),
      ];
    }

    return [
      CupertinoSliverRefreshControl(
        onRefresh: () => _loadOrders(),
      ),
      SliverPadding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
        sliver: SliverList(
          delegate: SliverChildBuilderDelegate(
            (context, index) {
              if (index == _orders.length) {
                return _buildLoadMoreButton();
              }
              final delay = (index * 0.1).clamp(0.0, 0.5);
              return AnimatedBuilder(
                animation: _animController,
                builder: (context, child) {
                  final value = Curves.easeOutCubic.transform(
                    (_animController.value - delay).clamp(0.0, 1.0) / (1.0 - delay).clamp(0.01, 1.0),
                  );
                  return Transform.translate(
                    offset: Offset(0, 30 * (1 - value)),
                    child: Opacity(
                      opacity: value.clamp(0.0, 1.0),
                      child: child,
                    ),
                  );
                },
                child: _buildOrderCard(_orders[index], index),
              );
            },
            childCount: _orders.length + (_hasMorePages ? 1 : 0),
          ),
        ),
      ),
    ];
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFFFEE2E2),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.cloud_off_rounded,
                size: 48,
                color: Color(0xFFEF4444),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Connexion impossible',
              style: GoogleFonts.poppins(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF1E293B),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _errorMessage ?? 'Vérifiez votre connexion internet',
              style: GoogleFonts.openSans(
                fontSize: 14,
                color: Colors.grey.shade600,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () => _loadOrders(),
              icon: const Icon(Icons.refresh_rounded, size: 20),
              label: Text(
                'Réessayer',
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: BoutiqueThemeProvider.of(context).primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: const Color(0xFFF1F5F9),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.receipt_long_rounded,
                size: 56,
                color: Colors.grey.shade400,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Aucune commande',
              style: GoogleFonts.poppins(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF1E293B),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Vos commandes apparaîtront ici\naprès votre premier achat',
              textAlign: TextAlign.center,
              style: GoogleFonts.openSans(
                fontSize: 14,
                color: Colors.grey.shade600,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 32),
            OutlinedButton.icon(
              onPressed: () => Navigator.pop(context),
              icon: const Icon(Icons.storefront_outlined, size: 20),
              label: Text(
                'Découvrir la boutique',
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              style: OutlinedButton.styleFrom(
                foregroundColor: BoutiqueThemeProvider.of(context).primary,
                side: BorderSide(color: BoutiqueThemeProvider.of(context).primary),
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadMoreButton() {
    final primaryColor = BoutiqueThemeProvider.of(context).primary;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 20),
      child: Center(
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () => _loadOrders(loadMore: true),
            borderRadius: BorderRadius.circular(14),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              decoration: BoxDecoration(
                color: primaryColor.withOpacity(0.08),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: primaryColor.withOpacity(0.15)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.expand_more_rounded, size: 20, color: primaryColor),
                  const SizedBox(width: 8),
                  Text(
                    'Voir plus de commandes',
                    style: GoogleFonts.poppins(
                      fontSize: 13,
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
    );
  }

  Widget _buildOrderCard(Order order, int index) {
    final statusInfo = _getStatusInfo(order.status);
    final statusColor = statusInfo['color'] as Color;
    final primaryColor = BoutiqueThemeProvider.of(context).primary;
    final itemCount = order.itemsCount > 0 ? order.itemsCount : order.items.length;

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: statusColor.withOpacity(0.08),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          onTap: () => _navigateToTracking(order),
          borderRadius: BorderRadius.circular(20),
          child: Column(
            children: [
              // -- Bande de couleur en haut --
              Container(
                height: 4,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [statusColor, statusColor.withOpacity(0.3)],
                  ),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(20),
                    topRight: Radius.circular(20),
                  ),
                ),
              ),

              Padding(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
                child: Column(
                  children: [
                    // -- Header: Numéro + Status badge --
                    Row(
                      children: [
                        // Icône statut avec gradient
                        Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                statusColor.withOpacity(0.15),
                                statusColor.withOpacity(0.05),
                              ],
                            ),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Icon(
                            statusInfo['icon'],
                            size: 22,
                            color: statusColor,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '#${order.orderNumber}',
                                style: GoogleFonts.poppins(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700,
                                  color: const Color(0xFF1E293B),
                                  letterSpacing: -0.3,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Row(
                                children: [
                                  Icon(Icons.access_time_rounded, size: 12, color: Colors.grey.shade400),
                                  const SizedBox(width: 4),
                                  Text(
                                    _formatDate(order.createdAt),
                                    style: GoogleFonts.openSans(
                                      fontSize: 11.5,
                                      color: Colors.grey.shade500,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        // Badge statut premium
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                statusColor.withOpacity(0.12),
                                statusColor.withOpacity(0.06),
                              ],
                            ),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 7,
                                height: 7,
                                decoration: BoxDecoration(
                                  color: statusColor,
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                      color: statusColor.withOpacity(0.4),
                                      blurRadius: 4,
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                statusInfo['label'],
                                style: GoogleFonts.poppins(
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
                    const SizedBox(height: 14),

                    // -- Ligne d'infos compacte --
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8F9FC),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Row(
                        children: [
                          // Total
                          Expanded(
                            child: Row(
                              children: [
                                Icon(Icons.payments_outlined, size: 18, color: primaryColor),
                                const SizedBox(width: 8),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Total',
                                      style: GoogleFonts.openSans(
                                        fontSize: 10,
                                        color: Colors.grey.shade500,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    Text(
                                      '${_formatAmount(order.totalAmount)} F',
                                      style: GoogleFonts.poppins(
                                        fontSize: 15,
                                        fontWeight: FontWeight.w700,
                                        color: primaryColor,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          // Divider vertical
                          Container(
                            width: 1,
                            height: 30,
                            color: Colors.grey.shade200,
                          ),
                          // Articles
                          Expanded(
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.shopping_bag_outlined, size: 18, color: Colors.grey.shade600),
                                const SizedBox(width: 8),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Articles',
                                      style: GoogleFonts.openSans(
                                        fontSize: 10,
                                        color: Colors.grey.shade500,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    Text(
                                      '$itemCount produit${itemCount > 1 ? 's' : ''}',
                                      style: GoogleFonts.poppins(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600,
                                        color: const Color(0xFF1E293B),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          // Bouton suivre
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: Colors.grey.shade200),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  'Suivre',
                                  style: GoogleFonts.poppins(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: const Color(0xFF475569),
                                  ),
                                ),
                                const SizedBox(width: 4),
                                Icon(
                                  Icons.arrow_forward_ios_rounded,
                                  size: 11,
                                  color: Colors.grey.shade600,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),

                    // -- Actions rapides --
                    Row(
                      children: [
                        _buildActionChip(
                          icon: Icons.receipt_long_rounded,
                          label: 'Recu',
                          color: const Color(0xFF3B82F6),
                          onTap: () => _viewReceipt(order),
                        ),
                        const SizedBox(width: 8),
                        _buildActionChip(
                          icon: Icons.replay_rounded,
                          label: 'Recommander',
                          color: const Color(0xFF10B981),
                          onTap: () => _reorder(order),
                        ),
                        if (order.status == 'livrée' || order.status == 'prete') ...[
                          const SizedBox(width: 8),
                          _buildActionChip(
                            icon: Icons.star_rounded,
                            label: 'Noter',
                            color: const Color(0xFFF59E0B),
                            onTap: () => _rateOrder(order),
                          ),
                        ],
                        if (_canCancel(order)) ...[
                          const SizedBox(width: 8),
                          _buildActionChip(
                            icon: Icons.cancel_outlined,
                            label: _cancelMinutesLeft(order) > 0
                                ? 'Annuler (${_cancelMinutesLeft(order)}m)'
                                : 'Annuler',
                            color: const Color(0xFFEF4444),
                            onTap: () => _cancelOrder(order),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActionChip({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 10),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [color.withOpacity(0.1), color.withOpacity(0.04)],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: color.withOpacity(0.15)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, size: 15, color: color),
                const SizedBox(width: 5),
                Flexible(
                  child: Text(
                    label,
                    style: GoogleFonts.poppins(
                      fontSize: 10.5,
                      fontWeight: FontWeight.w600,
                      color: color,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Map<String, dynamic> _getStatusInfo(String status) {
    switch (status) {
      case 'reçue':
        return {
          'color': const Color(0xFFF59E0B),
          'label': 'Reçue',
          'icon': Icons.inbox_rounded,
        };
      case 'en_traitement':
        return {
          'color': const Color(0xFF3B82F6),
          'label': 'En préparation',
          'icon': Icons.sync_rounded,
        };
      case 'prête':
        return {
          'color': const Color(0xFF8B5CF6),
          'label': 'Prête',
          'icon': Icons.inventory_2_rounded,
        };
      case 'en_livraison':
        return {
          'color': const Color(0xFFF97316),
          'label': 'En livraison',
          'icon': Icons.local_shipping_rounded,
        };
      case 'livrée':
        return {
          'color': const Color(0xFF10B981),
          'label': 'Livrée',
          'icon': Icons.check_circle_rounded,
        };
      case 'annulée':
        return {
          'color': const Color(0xFFEF4444),
          'label': 'Annulée',
          'icon': Icons.cancel_rounded,
        };
      default:
        return {
          'color': Colors.grey,
          'label': status,
          'icon': Icons.help_outline_rounded,
        };
    }
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      return "Aujourd'hui, ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}";
    } else if (difference.inDays == 1) {
      return 'Hier';
    } else if (difference.inDays < 7) {
      return 'Il y a ${difference.inDays} jours';
    } else {
      final months = [
        'jan', 'fév', 'mar', 'avr', 'mai', 'juin',
        'juil', 'août', 'sep', 'oct', 'nov', 'déc'
      ];
      return '${date.day} ${months[date.month - 1]} ${date.year}';
    }
  }

  String _formatAmount(double amount) {
    if (amount >= 1000) {
      return amount.toInt().toString().replaceAllMapped(
        RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
        (Match m) => '${m[1]} ',
      );
    }
    return amount.toInt().toString();
  }
}
