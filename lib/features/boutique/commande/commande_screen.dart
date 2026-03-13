import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import '../panier/cart_manager.dart';
import 'form_widgets.dart';
import 'loading_success_page.dart';
import 'order_summary_page.dart';
import 'wave_payment_screen.dart';
import '../../../core/messages/message_modal.dart';
import '../../../core/services/storage_service.dart';
import '../../../core/services/boutique_theme_provider.dart';
import '../../../services/order_service.dart';
import '../../../services/wave_payment_service.dart';
import '../../../services/device_service.dart';
import '../../../services/utils/api_endpoint.dart';
import '../../../services/shop_service.dart';
import '../../../services/models/shop_model.dart';
import '../../../services/auth_service.dart';
import '../../../services/profile_service.dart';
import '../../../services/models/profile_model.dart';

/// Écran de finalisation de commande
/// LOGIQUE EXACTE DE L'API TIKA (docs-api-flutter/08-API-ORDERS.md)
///
/// Flux:
/// 1. Informations client
/// 2. Mode de livraison
/// 3. Méthode de paiement
/// 4. Créer la commande (AVEC payment_method)
class CommandeScreen extends StatefulWidget {
  final int shopId;
  final Shop? shop;
  final String? couponCode;
  final double? couponDiscountAmount;
  final int? loyaltyCardId;
  final int? loyaltyPointsUsed;
  final double? loyaltyDiscount;
  final int? loyaltyPointValue;

  const CommandeScreen({
    super.key,
    required this.shopId,
    this.shop,
    this.couponCode,
    this.couponDiscountAmount,
    this.loyaltyCardId,
    this.loyaltyPointsUsed,
    this.loyaltyDiscount,
    this.loyaltyPointValue,
  });

  @override
  State<CommandeScreen> createState() => _CommandeScreenState();
}

class _CommandeScreenState extends State<CommandeScreen> {
  int _currentStep = 0;

  // Thème boutique
  ShopTheme get _theme => widget.shop?.theme ?? ShopTheme.defaultTheme();
  Color get _primaryColor => _theme.primary;

  final _formKey = GlobalKey<FormState>();
  final CartManager _cartManager = CartManager();

  // Étape 1 - Informations client
  final _nomController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();

  // Adresses enregistrées
  List<Map<String, dynamic>> _localAddresses = [];
  List<ProfileAddress> _apiAddresses = [];

  // Étape 2 - Mode de livraison
  String? _selectedDeliveryMode; // "Livraison" ou "À emporter"
  DateTime? _selectedPickupDate; // Date de récupération (pour À emporter)
  TimeOfDay? _selectedPickupTime; // Heure de récupération (pour À emporter)

  // Zones de livraison du vendeur
  List<DeliveryZone> _deliveryZones = [];
  DeliveryZone? _selectedZone;
  bool _isLoadingZones = false;

  // Sous-mode de livraison : 'yango' ou 'vendeur'
  String? _selectedLivraisonProvider;

  // Étape 3 - Méthode de paiement
  String _selectedPaymentMethod = 'especes'; // "especes", "mobile_money", "carte"

  @override
  void initState() {
    super.initState();
    _loadSavedData();
  }

  /// Charger les infos client et adresses enregistrées
  Future<void> _loadSavedData() async {
    // Charger les zones de livraison du vendeur
    _loadDeliveryZones();

    // Charger le nom et téléphone sauvegardés
    final savedName = await StorageService.getCustomerName();
    final savedPhone = await StorageService.getCustomerPhone();
    final savedEmail = await StorageService.getCustomerEmail();

    if (AuthService.isAuthenticated) {
      _apiAddresses = await ProfileService.getAddresses();
      final defaultAddr = _apiAddresses.where((a) => a.isDefault).firstOrNull
          ?? (_apiAddresses.isNotEmpty ? _apiAddresses.first : null);
      if (mounted) {
        setState(() {
          if (savedName != null) _nomController.text = savedName;
          if (savedPhone != null) _phoneController.text = savedPhone;
          if (savedEmail != null) _emailController.text = savedEmail;
          if (defaultAddr != null) _addressController.text = defaultAddr.fullAddress;
        });
      }
    } else {
      _localAddresses = await StorageService.getCustomerAddresses();
      final defaultAddr = _localAddresses.where((a) => a['isDefault'] == true).firstOrNull
          ?? (_localAddresses.isNotEmpty ? _localAddresses.first : null);
      if (mounted) {
        setState(() {
          if (savedName != null) _nomController.text = savedName;
          if (savedPhone != null) _phoneController.text = savedPhone;
          if (savedEmail != null) _emailController.text = savedEmail;
          if (defaultAddr != null) _addressController.text = defaultAddr['address'] ?? '';
        });
      }
    }
  }

  /// Ouvrir le sélecteur d'adresses enregistrées
  void _showAddressPicker() {
    final addresses = AuthService.isAuthenticated
        ? _apiAddresses.map((a) => {'name': a.label, 'address': a.fullAddress, 'isDefault': a.isDefault}).toList()
        : _localAddresses;

    if (addresses.isEmpty) return;

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Choisir une adresse',
              style: GoogleFonts.inriaSerif(fontSize: 12, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            ...addresses.map((addr) {
              final name = addr['name'] as String? ?? '';
              final address = addr['address'] as String? ?? '';
              final isDefault = addr['isDefault'] as bool? ?? false;
              return ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: _primaryColor.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.location_on, color: _primaryColor, size: 20),
                ),
                title: Row(
                  children: [
                    Text(name, style: GoogleFonts.inriaSerif(fontWeight: FontWeight.w600)),
                    if (isDefault) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: _primaryColor,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text('Par défaut',
                            style: GoogleFonts.inriaSerif(fontSize: 12, color: Colors.white, fontWeight: FontWeight.w600)),
                      ),
                    ],
                  ],
                ),
                subtitle: Text(address, style: GoogleFonts.inriaSerif(fontSize: 12, color: Colors.grey.shade800)),
                onTap: () {
                  setState(() {
                    _addressController.text = address;
                  });
                  Navigator.pop(context);
                },
              );
            }),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _nomController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  void _nextStep() {
    if (_currentStep == 0) {
      // Valider le formulaire étape 1
      if (_formKey.currentState!.validate()) {
        setState(() { _currentStep++; });
        // Recharger les zones si pas encore disponibles
        if (_deliveryZones.isEmpty && !_isLoadingZones) _loadDeliveryZones();
      }
    } else if (_currentStep == 1) {
      // Vérifier qu'un mode de livraison est sélectionné
      if (_selectedDeliveryMode == null) {
        showErrorModal(context, 'Veuillez sélectionner un mode de livraison');
        return;
      }

      // Si Livraison avec zones disponibles, vérifier le sous-mode
      if (_selectedDeliveryMode == 'Livraison' &&
          _deliveryZones.isNotEmpty &&
          _selectedLivraisonProvider == null) {
        showErrorModal(context, 'Veuillez choisir un mode de livraison (Yango ou zone vendeur)');
        return;
      }

      // Passer à l'étape 3 (paiement) — pour Livraison ET À emporter
      setState(() {
        _currentStep++;
      });
    } else if (_currentStep == 2) {
      // Naviguer vers la page de résumé de commande
      _showOrderSummary();
    }
  }

  void _previousStep() {
    if (_currentStep > 0) {
      setState(() {
        _currentStep--;
      });
    }
  }

  /// Construire l'URL Wave avec le montant pré-rempli
  /// Format Wave: https://wave.com/m/M_xxx?amount=3500
  String _buildWaveUrlWithAmount(String waveUrl, int amount) {
    final uri = Uri.tryParse(waveUrl);
    if (uri == null) return waveUrl;

    // Si l'URL a déjà un paramètre amount, ne pas le remplacer
    if (uri.queryParameters.containsKey('amount')) {
      return waveUrl;
    }

    // Ajouter le montant en query parameter
    final newUri = uri.replace(queryParameters: {
      ...uri.queryParameters,
      'amount': amount.toString(),
    });
    return newUri.toString();
  }

  /// Ouvrir Wave directement avec le montant (fallback si l'API échoue)
  Future<void> _openWaveDirectly() async {
    final total = _cartManager.totalPrice;

    // Chercher le lien Wave
    String? waveUrl = widget.shop?.wavePaymentLink;
    if (waveUrl == null || waveUrl.isEmpty) {
      try {
        waveUrl = await ShopService.getWavePaymentLink(widget.shopId);
      } catch (_) {}
    }

    if (waveUrl == null || waveUrl.isEmpty) {
      final wavePhone = widget.shop?.wavePhone;
      if (wavePhone != null && wavePhone.isNotEmpty) {
        waveUrl = 'https://wave.com/m/$wavePhone';
      }
    }

    if (waveUrl != null && waveUrl.isNotEmpty) {
      final urlWithAmount = _buildWaveUrlWithAmount(
        waveUrl.startsWith('http') ? waveUrl : 'https://wave.com/m/$waveUrl',
        total,
      );

      print('🌊 Ouverture Wave directe: $urlWithAmount (montant: $total FCFA)');

      try {
        await launchUrl(
          Uri.parse(urlWithAmount),
          mode: LaunchMode.externalApplication,
        );
      } catch (e) {
        print('🌊 Erreur ouverture Wave: $e');
        if (mounted) {
          showErrorModal(context, 'Impossible d\'ouvrir Wave');
        }
      }
    } else {
      if (mounted) {
        showErrorModal(context, 'Le lien de paiement Wave n\'est pas disponible pour cette boutique');
      }
    }
  }

  /// Mapper le mode de livraison au format API
  /// API attend: "Livraison à domicile", "À emporter", "Sur place"
  String _mapDeliveryModeToApi(String? mode) {
    switch (mode) {
      case 'Livraison':
        return 'Livraison à domicile';
      case 'À emporter':
        return 'À emporter';
      default:
        return 'À emporter';
    }
  }

  /// Sélectionner la date de récupération
  Future<void> _selectPickupDate() async {
    final DateTime now = DateTime.now();
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedPickupDate ?? now,
      firstDate: now,
      lastDate: now.add(const Duration(days: 30)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: _primaryColor,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _selectedPickupDate = picked;
      });
    }
  }

  /// Sélectionner l'heure de récupération
  Future<void> _selectPickupTime() async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _selectedPickupTime ?? TimeOfDay.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: _primaryColor,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _selectedPickupTime = picked;
      });
    }
  }

  /// Formater la date
  String _formatDate(DateTime? date) {
    if (date == null) return 'Sélectionner une date';
    final months = ['jan', 'fév', 'mar', 'avr', 'mai', 'juin', 'juil', 'août', 'sep', 'oct', 'nov', 'déc'];
    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }

  /// Formater l'heure
  String _formatTime(TimeOfDay? time) {
    if (time == null) return 'Sélectionner une heure';
    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  /// Afficher la page de résumé de commande
  void _showOrderSummary() async {
    if (!mounted) return;

    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => BoutiqueThemeProvider(
          shop: widget.shop,
          child: OrderSummaryPage(
            customerName: _nomController.text,
            customerPhone: _phoneController.text,
            customerEmail: _emailController.text.isNotEmpty ? _emailController.text : null,
            deliveryMode: _selectedDeliveryMode ?? 'Livraison',
            deliveryAddress: _addressController.text.isNotEmpty ? _addressController.text : null,
            paymentMethod: _selectedPaymentMethod,
            deliveryLabel: _selectedDeliveryMode == 'À emporter'
                ? 'Récupération en boutique'
                : _selectedLivraisonProvider == 'yango'
                    ? 'Yango Livraison'
                    : _selectedZone != null
                        ? _selectedZone!.name
                        : 'Livraison à domicile',
            deliveryFeeLabel: _selectedDeliveryMode == 'À emporter'
                ? 'Gratuit'
                : _selectedLivraisonProvider == 'yango'
                    ? 'Frais variables'
                    : _selectedZone != null
                        ? (_selectedZone!.deliveryFee == 0
                            ? 'Gratuit'
                            : '${_selectedZone!.deliveryFee.toInt()} F CFA')
                        : null,
            onConfirm: () {
              // Fermer la page de résumé
              Navigator.of(context).pop();

              // Wave → WavePaymentScreen (ouvre Wave + capture), sinon création directe
              if (_selectedPaymentMethod == 'wave') {
                _navigateToWavePayment();
              } else {
                _createOrder();
              }
            },
            onBack: () {
              Navigator.of(context).pop();
            },
          ),
        ),
      ),
    );
  }

  /// Naviguer vers l'écran de paiement Wave
  ///
  /// Flux correct (selon le dev back):
  /// 1. Afficher WavePaymentScreen SANS créer de commande
  /// 2. Client ouvre Wave, effectue le paiement
  /// 3. Client revient, soumet la capture d'écran
  /// 4. POST /mobile/orders/create-with-wave-proof → crée la commande + valide le paiement
  Future<void> _navigateToWavePayment() async {
    if (!mounted) return;

    try {
      print('🌊 ━━━ WAVE: OUVERTURE ÉCRAN PAIEMENT ━━━');
      final items = _cartManager.getItemsForOrder();
      final deviceFingerprint = await DeviceService.getDeviceFingerprint();
      final serviceType = _mapDeliveryModeToApi(_selectedDeliveryMode);
      final totalAmount = _cartManager.totalPrice.toDouble();

      String? deliveryAddress;
      if (_selectedDeliveryMode == 'Livraison' &&
          _addressController.text.isNotEmpty) {
        deliveryAddress = _addressController.text;
      }

      // Récupérer le lien Wave
      String? wavePaymentLink = widget.shop?.wavePaymentLink;
      if (wavePaymentLink == null || wavePaymentLink.isEmpty) {
        try {
          wavePaymentLink = await ShopService.getWavePaymentLink(widget.shopId);
        } catch (_) {}
      }

      print('🌊 Montant: $totalAmount FCFA');
      print('🌊 wavePaymentLink: $wavePaymentLink');
      print('🌊 ━━━━━━━━━━━━━━━━━━━━━━');

      if (!mounted) return;

      // Naviguer vers WavePaymentScreen avec les données de commande
      // La commande sera créée au moment de la soumission de la preuve
      final result = await Navigator.of(context).push<WaveProofResponse>(
        MaterialPageRoute(
          builder: (context) => BoutiqueThemeProvider(
            shop: widget.shop,
            child: WavePaymentScreen(
              amount: totalAmount,
              wavePaymentLink: wavePaymentLink,
              vendorWaveNumber: widget.shop?.wavePhone,
              shopId: widget.shopId,
              customerName: _nomController.text,
              customerPhone: _phoneController.text,
              serviceType: serviceType,
              deviceFingerprint: deviceFingerprint,
              items: items,
              customerEmail: _emailController.text.isNotEmpty ? _emailController.text : null,
              customerAddress: _addressController.text.isNotEmpty ? _addressController.text : null,
              deliveryAddress: deliveryAddress,
              couponCode: widget.couponCode,
              couponDiscountAmount: widget.couponDiscountAmount,
              loyaltyCardId: widget.loyaltyCardId,
              loyaltyPointsUsed: widget.loyaltyPointsUsed,
              loyaltyDiscount: widget.loyaltyDiscount,
              pickupDate: _selectedPickupDate != null
                  ? '${_selectedPickupDate!.year}-${_selectedPickupDate!.month.toString().padLeft(2, '0')}-${_selectedPickupDate!.day.toString().padLeft(2, '0')}'
                  : null,
              pickupTime: _selectedPickupTime != null
                  ? '${_selectedPickupTime!.hour.toString().padLeft(2, '0')}:${_selectedPickupTime!.minute.toString().padLeft(2, '0')}'
                  : null,
              deliveryZoneId: (_selectedLivraisonProvider?.startsWith('vendeur_') == true) ? _selectedZone?.id : null,
              onPaymentSuccess: (waveResponse) {
                print('✅ Wave: commande créée + preuve soumise');
              },
              onCancel: () {
                print('❌ Wave annulé');
              },
            ),
          ),
        ),
      );

      if (mounted && result != null) {
        // La commande a été créée avec succès via createOrderWithWaveProof
        final orderNumber = result.orderNumber ?? '';
        final orderId = result.orderId;
        final receiptUrl = orderId != null
            ? Endpoints.orderReceipt(orderId)
            : null;

        final orderData = {
          'orderNumber': orderNumber,
          'orderId': orderId,
          'customerPhone': _phoneController.text,
          'customerName': _nomController.text,
          'receiptUrl': receiptUrl,
          'authToken': AuthService.authToken,
          'shopId': widget.shopId,
          'orderDate': DateTime.now(),
          'boutiqueName': widget.shop?.name ?? 'Tika Shop',
          'shopLogoUrl': widget.shop?.logoUrl ?? 'lib/core/assets/logo.png',
          'total': result.totalAmount ?? totalAmount,
          'deliveryMode': _selectedDeliveryMode ?? 'À emporter',
          'paymentMode': 'Wave (preuve envoyée)',
          'items': _cartManager.items.map((item) {
            return {
              'name': item['name'],
              'quantity': item['quantity'],
              'price': item['price'],
              'image': item['image'],
            };
          }).toList(),
          'deliveryInfo': {
            'name': _nomController.text,
            'phone': _phoneController.text,
            'address': _addressController.text,
          },
          if (widget.loyaltyCardId != null) 'loyaltyCardId': widget.loyaltyCardId,
          if (widget.loyaltyPointValue != null) 'loyaltyPointValue': widget.loyaltyPointValue,
        };

        await StorageService.saveOrder(orderData);
        await StorageService.saveCustomerInfo(
          name: _nomController.text,
          phone: _phoneController.text,
          email: _emailController.text.isNotEmpty ? _emailController.text : null,
        );
        _cartManager.clear();

        await Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => BoutiqueThemeProvider(
              shop: widget.shop,
              child: LoadingSuccessPage(orderData: orderData),
            ),
          ),
        );

        if (mounted) {
          Navigator.of(context).pop(true);
        }
      }
    } catch (e) {
      print('🌊 ❌ Erreur Wave: $e');
      if (mounted) {
        final errorDetails = e.toString().replaceAll('Exception:', '').trim();
        print('🌊 ❌ Détails erreur: $errorDetails');
        showErrorModal(context, errorDetails.isNotEmpty
            ? errorDetails
            : 'Erreur lors du paiement Wave.');
      }
    }
  }

  /// Charger les zones de livraison
  Future<void> _loadDeliveryZones() async {
    if (!mounted) return;
    setState(() => _isLoadingZones = true);
    try {
      final zones = await ShopService.getDeliveryZones(widget.shopId);
      print('🚚 Zones: ${zones.length} → ${zones.map((z) => z.name).toList()}');
      if (mounted) setState(() { _deliveryZones = zones; _isLoadingZones = false; });
    } catch (e) {
      print('❌ Erreur zones: $e');
      if (mounted) setState(() => _isLoadingZones = false);
    }
  }

  /// Créer la commande via l'API
  /// LOGIQUE EXACTE: AVEC payment_method (docs-api-flutter)
  void _createOrder() async {
    // PAS de dialog de chargement, création directe
    if (!mounted) return;

    try {
      print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
      print('📤 CRÉATION DE COMMANDE - LOGIQUE API');
      print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');

      // Récupérer les items du panier
      final items = _cartManager.getItemsForOrder();
      print('📦 Items: ${items.length} produits');

      // Device fingerprint
      final deviceFingerprint = await DeviceService.getDeviceFingerprint();
      print('📱 Device: $deviceFingerprint');

      // Service type
      final serviceType = _mapDeliveryModeToApi(_selectedDeliveryMode);
      print('🚚 Service: $serviceType');

      // Adresse de livraison (si applicable)
      String? deliveryAddress;
      if (_selectedDeliveryMode == 'Livraison' &&
          _addressController.text.isNotEmpty) {
        deliveryAddress = _addressController.text;
        print('📍 Adresse: $deliveryAddress');
      }

      // Date/heure de récupération (si À emporter)
      String? pickupDate;
      String? pickupTime;
      if (_selectedDeliveryMode == 'À emporter') {
        if (_selectedPickupDate != null) {
          final d = _selectedPickupDate!;
          pickupDate = '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
        }
        if (_selectedPickupTime != null) {
          final t = _selectedPickupTime!;
          pickupTime = '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';
        }
        print('📅 Pickup: $pickupDate à $pickupTime');
      }

      // Appeler l'API - AVEC payment_method, coupon et fidélité
      final response = await OrderService.createOrder(
        shopId: widget.shopId,
        customerName: _nomController.text,
        customerPhone: _phoneController.text,
        serviceType: serviceType,
        deviceFingerprint: deviceFingerprint,
        items: items,
        paymentMethod: _selectedPaymentMethod,
        customerEmail: _emailController.text.isNotEmpty ? _emailController.text : null,
        customerAddress: _addressController.text.isNotEmpty ? _addressController.text : null,
        deliveryAddress: deliveryAddress,
        couponCode: widget.couponCode,
        discountAmount: widget.couponDiscountAmount,
        loyaltyCardId: widget.loyaltyCardId,
        loyaltyPointsUsed: widget.loyaltyPointsUsed,
        loyaltyDiscount: widget.loyaltyDiscount,
        pickupDate: pickupDate,
        pickupTime: pickupTime,
        deliveryZoneId: (_selectedLivraisonProvider?.startsWith('vendeur_') == true) ? _selectedZone?.id : null,
      );

      print('✅ Commande créée !');
      print('   - Order Number: ${response['order_number']}');
      print('   - Status: ${response['status']}');
      print('   - Payment Status: ${response['payment_status']}');

      print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');

      // Préparer les données pour la page de succès
      final orderNumber = response['order_number'] as String;
      final orderId = response['order_id'];
      // URL du recu: GET /client/orders/{id}/receipt
      final receiptUrl = response['receipt_url']
          ?? (orderId != null ? Endpoints.orderReceipt(orderId as int) : null);

      print('📄 Receipt URL: $receiptUrl');
      print('📄 Order ID: $orderId');

      final orderData = {
        'orderNumber': orderNumber,
        'orderId': orderId,
        'customerPhone': _phoneController.text,
        'customerName': _nomController.text,
        'receiptUrl': receiptUrl,
        'authToken': AuthService.authToken,
        'shopId': widget.shopId,
        'orderDate': DateTime.now(),
        'boutiqueName': widget.shop?.name ?? 'Tika Shop',
        'shopLogoUrl': widget.shop?.logoUrl ?? 'lib/core/assets/logo.png',
        'total': response['total_amount'] ?? _cartManager.totalPrice,
        'deliveryMode': _selectedDeliveryMode ?? 'À emporter',
        'paymentMode': 'Paiement à confirmer',
        'items': _cartManager.items.map((item) {
          return {
            'name': item['name'],
            'quantity': item['quantity'],
            'price': item['price'],
            'image': item['image'],
          };
        }).toList(),
        'deliveryInfo': {
          'name': _nomController.text,
          'phone': _phoneController.text,
          'address': _addressController.text,
        },
        if (widget.loyaltyCardId != null) 'loyaltyCardId': widget.loyaltyCardId,
        if (widget.loyaltyPointValue != null) 'loyaltyPointValue': widget.loyaltyPointValue,
      };

      // Sauvegarder localement
      await StorageService.saveOrder(orderData);

      // Sauvegarder les infos client pour utilisation future
      await StorageService.saveCustomerInfo(
        name: _nomController.text,
        phone: _phoneController.text,
        email: _emailController.text.isNotEmpty ? _emailController.text : null,
      );

      // Vider le panier
      _cartManager.clear();

      // Naviguer directement vers la page de succès (pas de dialog de chargement)
      if (mounted) {
        // Navigation vers la page de succès
        await Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => BoutiqueThemeProvider(
              shop: widget.shop,
              child: LoadingSuccessPage(orderData: orderData),
            ),
          ),
        );

        // Retourner à l'accueil
        if (mounted) {
          Navigator.of(context).pop(true);
        }
      }
    } catch (e) {
      print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
      print('❌ Erreur: $e');
      print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');

      // Extraire le message d'erreur
      String errorMessage = 'Erreur lors de la création de la commande. Veuillez réessayer.';
      if (e.toString().contains('Exception:')) {
        errorMessage = e.toString().replaceAll('Exception:', '').trim();
      }

      // Afficher l'erreur directement
      if (mounted) {
        showErrorModal(context, errorMessage);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: const Icon(Icons.arrow_back, size: 24),
                  ),
                  const SizedBox(width: 16),
                  Text(
                    'Finaliser la commande',
                    style: GoogleFonts.inriaSerif(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),

            // Indicateur d'étapes (2 ou 3 étapes selon le mode)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: Row(
                children: [
                  _buildStepIndicator(1, 'Info', _currentStep >= 0, isPast: _currentStep > 0),
                  Expanded(
                    child: Container(
                      height: 2,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: _currentStep >= 1
                              ? [_primaryColor, _primaryColor.withOpacity(0.6)]
                              : [Colors.grey.shade300, Colors.grey.shade300],
                        ),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  _buildStepIndicator(
                    2,
                    _selectedDeliveryMode == 'À emporter' ? 'Récupération' : 'Livraison',
                    _currentStep >= 1,
                    isPast: _currentStep > 1,
                  ),
                  // Étape paiement — toujours affichée
                  Expanded(
                    child: Container(
                      height: 2,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: _currentStep >= 2
                              ? [_primaryColor, _primaryColor.withOpacity(0.6)]
                              : [Colors.grey.shade300, Colors.grey.shade300],
                        ),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  _buildStepIndicator(3, 'Paiement', _currentStep >= 2, isPast: _currentStep > 2),
                ],
              ),
            ),

            // Contenu des étapes
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: _currentStep == 0
                    ? _buildStep1()
                    : _currentStep == 1
                        ? _buildStep2()
                        : _buildStep3(),
              ),
            ),

            // Footer avec boutons
            Container(
              padding: const EdgeInsets.all(20),
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
              child: Row(
                children: [
                  if (_currentStep > 0)
                    Expanded(
                      child: GestureDetector(
                        onTap: _previousStep,
                        child: Container(
                          height: 52,
                          decoration: BoxDecoration(
                            color: Colors.grey.shade100,
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.arrow_back_ios_rounded, size: 14, color: Colors.grey.shade600),
                              const SizedBox(width: 4),
                              Text(
                                'Retour',
                                style: GoogleFonts.inriaSerif(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.grey.shade900,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  if (_currentStep > 0) const SizedBox(width: 12),
                  Expanded(
                    flex: _currentStep == 0 ? 1 : 2,
                    child: GestureDetector(
                      onTap: _nextStep,
                      child: Container(
                        height: 52,
                        decoration: BoxDecoration(
                          color: _primaryColor,
                          borderRadius: BorderRadius.circular(14),
                          boxShadow: [
                            BoxShadow(
                              color: _primaryColor.withOpacity(0.40),
                              blurRadius: 12,
                              offset: const Offset(0, 5),
                            ),
                          ],
                        ),
                        child: Center(
                          child: Text(
                            _currentStep == 2
                                ? 'Valider la commande'
                                : 'Continuer',
                            style: GoogleFonts.inriaSerif(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
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

  Widget _buildStepIndicator(int step, String label, bool isActive, {bool isPast = false}) {
    return Column(
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: isActive ? _primaryColor : Colors.grey.shade200,
            shape: BoxShape.circle,
            boxShadow: isActive
                ? [
                    BoxShadow(
                      color: _primaryColor.withOpacity(0.35),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ]
                : [],
          ),
          child: Center(
            child: isPast
                ? const Icon(Icons.check, color: Colors.white, size: 18)
                : Text(
                    '$step',
                    style: GoogleFonts.inriaSerif(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: isActive ? Colors.white : Colors.grey.shade800,
                    ),
                  ),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          label,
          style: GoogleFonts.inriaSerif(
            fontSize: 12,
            fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
            color: isActive ? _primaryColor : Colors.grey.shade800,
          ),
        ),
      ],
    );
  }

  /// ÉTAPE 1: Informations client
  Widget _buildStep1() {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Vos informations',
            style: GoogleFonts.inriaSerif(
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 20),

          FormFieldWidget(
            label: 'Nom complet',
            hint: 'Entrez votre nom complet',
            icon: Icons.person,
            controller: _nomController,
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'[a-zA-ZÀ-ÿ\s]')), // Lettres et espaces uniquement
            ],
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Le nom est requis';
              }
              if (!RegExp(r'^[a-zA-ZÀ-ÿ\s]+$').hasMatch(value)) {
                return 'Le nom ne doit contenir que des lettres';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),

          FormFieldWidget(
            label: 'Téléphone',
            hint: '07 XX XX XX XX',
            icon: Icons.phone,
            controller: _phoneController,
            keyboardType: TextInputType.phone,
            maxLength: 10,
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly, // Chiffres uniquement
            ],
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Le téléphone est requis';
              }
              // Nettoyer le numéro (enlever espaces, tirets, parenthèses)
              final cleanedNumber = value.replaceAll(RegExp(r'[\s\-\(\)\.]'), '');
              // Vérifier que le numéro contient uniquement des chiffres
              if (!RegExp(r'^[0-9]+$').hasMatch(cleanedNumber)) {
                return 'Le numéro ne doit contenir que des chiffres';
              }
              // Vérifier que le numéro fait exactement 10 chiffres
              if (cleanedNumber.length != 10) {
                return 'Le numéro doit contenir exactement 10 chiffres';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),

          FormFieldWidget(
            label: 'Email (optionnel)',
            hint: 'exemple@email.com',
            icon: Icons.email,
            controller: _emailController,
            keyboardType: TextInputType.emailAddress,
            required: false,
          ),
          const SizedBox(height: 16),

          _buildAddressField(required: false),
        ],
      ),
    );
  }

  /// ÉTAPE 2: Mode de livraison
  Widget _buildStep2() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Mode de livraison',
          style: GoogleFonts.inriaSerif(
            fontSize: 12,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 20),

        // Option Livraison
        _buildDeliveryOption(
          id: 'Livraison',
          icon: Icons.delivery_dining,
          title: 'Livraison',
          description: 'Livraison à votre adresse',
        ),
        const SizedBox(height: 12),

        // Option À emporter
        _buildDeliveryOption(
          id: 'À emporter',
          icon: Icons.shopping_bag,
          title: 'À emporter',
          description: 'Récupérer en boutique',
        ),

        // ── Sous-options Livraison (seulement si le vendeur a des zones) ───
        if (_selectedDeliveryMode == 'Livraison' &&
            (_isLoadingZones || _deliveryZones.isNotEmpty)) ...[
          const SizedBox(height: 20),
          Text(
            'Choisissez votre livreur',
            style: GoogleFonts.inriaSerif(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 12),

          // ── Yango ──────────────────────────────────────────────────────────
          _buildLivraisonProviderCard(
            id: 'yango',
            icon: Icons.two_wheeler_rounded,
            title: 'Livraison Yango',
            subtitle: 'Frais variables · selon le chauffeur',
            color: const Color(0xFFFFD600),
            iconColor: Colors.black87,
          ),
          const SizedBox(height: 10),

          // ── Zones vendeur ──────────────────────────────────────────────────
          if (_isLoadingZones)
            Center(child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: SizedBox(height: 24, width: 24, child: CircularProgressIndicator(strokeWidth: 2, color: _primaryColor)),
            ))
          else ...[
            ..._deliveryZones.map((zone) {
              final fee = zone.deliveryFee == 0
                  ? 'Livraison gratuite'
                  : '${zone.deliveryFee.toInt()} F CFA';
              final sub = zone.estimatedTime != null ? '$fee · ${zone.estimatedTime}' : fee;
              return Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: _buildLivraisonProviderCard(
                  id: 'vendeur_${zone.id}',
                  icon: Icons.location_on_rounded,
                  title: zone.name,
                  subtitle: sub,
                  color: _primaryColor,
                  iconColor: Colors.white,
                  onTap: () => setState(() {
                    _selectedLivraisonProvider = 'vendeur_${zone.id}';
                    _selectedZone = zone;
                    _addressController.text = zone.name;
                  }),
                ),
              );
            }),
          ],

          const SizedBox(height: 16),
          _buildAddressField(required: false),
        ],

      ],
    );
  }

  Widget _buildLivraisonProviderCard({
    required String id,
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required Color iconColor,
    VoidCallback? onTap,
  }) {
    final isSelected = _selectedLivraisonProvider == id;
    return GestureDetector(
      onTap: onTap ?? () => setState(() {
        _selectedLivraisonProvider = id;
        if (id == 'yango') {
          _selectedZone = null;
          _addressController.clear();
        }
      }),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isSelected ? color.withOpacity(0.08) : Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: isSelected ? color : Colors.grey.shade200, width: isSelected ? 2 : 1),
          boxShadow: [BoxShadow(color: isSelected ? color.withOpacity(0.15) : Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 3))],
        ),
        child: Row(
          children: [
            Container(
              width: 44, height: 44,
              decoration: BoxDecoration(color: isSelected ? color : Colors.grey.shade100, borderRadius: BorderRadius.circular(12)),
              child: Icon(icon, color: isSelected ? iconColor : Colors.grey.shade700, size: 22),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: GoogleFonts.inriaSerif(fontSize: 13, fontWeight: FontWeight.w700, color: isSelected ? color : Colors.black87)),
                  Text(subtitle, style: GoogleFonts.inriaSerif(fontSize: 12, color: Colors.grey.shade600)),
                ],
              ),
            ),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              child: isSelected
                  ? Icon(Icons.check_circle_rounded, color: color, size: 22, key: ValueKey('sel_$id'))
                  : Icon(Icons.radio_button_unchecked, color: Colors.grey.shade300, size: 22, key: ValueKey('unsel_$id')),
            ),
          ],
        ),
      ),
    );
  }

  /// ÉTAPE 3: Méthode de paiement
  Widget _buildStep3() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Méthode de paiement',
          style: GoogleFonts.inriaSerif(
            fontSize: 12,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 20),

        // Option Espèces
        _buildPaymentOption(
          id: 'especes',
          icon: Icons.money,
          title: 'Espèces',
          description: 'Paiement à la livraison ou au retrait',
        ),

        // Option Wave (affichée seulement si Wave est activé pour cette boutique)
        if (widget.shop?.waveEnabled ?? false) ...[
          const SizedBox(height: 12),
          _buildPaymentOptionWithImage(
            id: 'wave',
            imagePath: 'lib/core/assets/WAVE.png',
            title: 'Wave',
            description: widget.shop?.wavePartialPaymentEnabled == true
                ? 'Paiement partiel (${widget.shop?.wavePartialPaymentPercentage}%) ou total'
                : 'Paiement mobile Wave',
            color: const Color(0xFF1BA5E0),
            badge: 'Recommandé',
          ),
        ],

        // ============================================================
        // MODES DE PAIEMENT NON DISPONIBLES DANS L'API ACTUELLE
        // Décommenter quand l'API les supportera
        // ============================================================

        // const SizedBox(height: 12),
        // // Option Orange Money
        // _buildPaymentOptionWithImage(
        //   id: 'orange_money',
        //   imagePath: 'lib/core/assets/orange.png',
        //   title: 'Orange Money',
        //   description: 'Paiement mobile Orange',
        //   color: const Color(0xFFFF7900),
        // ),

        // const SizedBox(height: 12),
        // // Option Moov Money
        // _buildPaymentOptionWithImage(
        //   id: 'moov_money',
        //   imagePath: 'lib/core/assets/moov.png',
        //   title: 'Moov Money',
        //   description: 'Paiement mobile Moov',
        //   color: const Color(0xFFFF6600),
        // ),

        // const SizedBox(height: 12),
        // // Option Carte bancaire
        // _buildPaymentOption(
        //   id: 'carte',
        //   icon: Icons.credit_card,
        //   title: 'Carte bancaire',
        //   description: 'Visa / Mastercard via CinetPay',
        // ),
      ],
    );
  }

  Widget _buildPaymentOptionWithImage({
    required String id,
    required String imagePath,
    required String title,
    required String description,
    required Color color,
    String? badge,
  }) {
    final isSelected = _selectedPaymentMethod == id;

    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedPaymentMethod = id;
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: isSelected
              ? LinearGradient(
                  colors: [
                    color.withOpacity(0.10),
                    color.withOpacity(0.04),
                  ],
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                )
              : null,
          color: isSelected ? null : Colors.white,
          border: Border.all(
            color: isSelected ? color : Colors.grey.shade200,
            width: isSelected ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: isSelected
                  ? color.withOpacity(0.15)
                  : Colors.black.withOpacity(0.04),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 52,
              height: 52,
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: Colors.grey.shade200),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Image.asset(
                imagePath,
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) {
                  return Icon(Icons.payment, color: color, size: 28);
                },
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        title,
                        style: GoogleFonts.inriaSerif(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: isSelected ? color : Colors.black87,
                        ),
                      ),
                      if (badge != null) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: color,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            badge,
                            style: GoogleFonts.inriaSerif(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 3),
                  Text(
                    description,
                    style: GoogleFonts.inriaSerif(
                      fontSize: 12,
                      color: Colors.grey.shade800,
                    ),
                  ),
                ],
              ),
            ),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              child: isSelected
                  ? Icon(Icons.check_circle_rounded, color: color, size: 26, key: const ValueKey('checked'))
                  : Icon(Icons.radio_button_unchecked, color: Colors.grey.shade300, size: 26, key: const ValueKey('unchecked')),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDeliveryOption({
    required String id,
    required IconData icon,
    required String title,
    required String description,
  }) {
    final isSelected = _selectedDeliveryMode == id;
    return GestureDetector(
      onTap: () => setState(() {
        _selectedDeliveryMode = id;
        _selectedLivraisonProvider = null;
        _selectedZone = null;
      }),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: isSelected
              ? LinearGradient(
                  colors: [_primaryColor.withOpacity(0.10), _primaryColor.withOpacity(0.04)],
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                )
              : null,
          color: isSelected ? null : Colors.white,
          border: Border.all(color: isSelected ? _primaryColor : Colors.grey.shade200, width: isSelected ? 2 : 1),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [BoxShadow(color: isSelected ? _primaryColor.withOpacity(0.15) : Colors.black.withOpacity(0.04), blurRadius: 12, offset: const Offset(0, 4))],
        ),
        child: Row(
          children: [
            Container(
              width: 52, height: 52,
              decoration: BoxDecoration(
                color: isSelected ? _primaryColor : Colors.grey.shade100,
                borderRadius: BorderRadius.circular(14),
                boxShadow: isSelected ? [BoxShadow(color: _primaryColor.withOpacity(0.3), blurRadius: 8, offset: const Offset(0, 3))] : [],
              ),
              child: Icon(icon, color: isSelected ? Colors.white : Colors.grey.shade900, size: 26),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: GoogleFonts.inriaSerif(fontSize: 14, fontWeight: FontWeight.w600, color: isSelected ? _primaryColor : Colors.black87)),
                  const SizedBox(height: 3),
                  Text(description, style: GoogleFonts.inriaSerif(fontSize: 12, color: Colors.grey.shade800)),
                ],
              ),
            ),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              child: isSelected
                  ? Icon(Icons.check_circle_rounded, color: _primaryColor, size: 26, key: const ValueKey('checked'))
                  : Icon(Icons.radio_button_unchecked, color: Colors.grey.shade300, size: 26, key: const ValueKey('unchecked')),
            ),
          ],
        ),
      ),
    );
  }

  /// Champ adresse avec sélecteur d'adresses enregistrées
  Widget _buildAddressField({required bool required}) {
    final hasAddresses = AuthService.isAuthenticated
        ? _apiAddresses.isNotEmpty
        : _localAddresses.isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Bouton "Choisir une adresse enregistrée" si disponible
        if (hasAddresses) ...[
          GestureDetector(
            onTap: _showAddressPicker,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: _primaryColor.withOpacity(0.08),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: _primaryColor.withOpacity(0.3)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.location_on, color: _primaryColor, size: 16),
                  const SizedBox(width: 6),
                  Text(
                    'Utiliser une adresse enregistrée',
                    style: GoogleFonts.inriaSerif(
                      fontSize: 12,
                      color: _primaryColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Icon(Icons.arrow_drop_down, color: _primaryColor, size: 18),
                ],
              ),
            ),
          ),
          const SizedBox(height: 10),
        ],
        // Champ texte
        FormFieldWidget(
          label: required ? 'Adresse de livraison' : 'Adresse (optionnel)',
          hint: 'Votre adresse complète',
          icon: Icons.location_on,
          controller: _addressController,
          maxLines: 2,
          required: required,
          validator: required
              ? (value) {
                  if (value == null || value.isEmpty) {
                    return 'L\'adresse est requise pour la livraison';
                  }
                  return null;
                }
              : null,
        ),
      ],
    );
  }

  Widget _buildPaymentOption({
    required String id,
    required IconData icon,
    required String title,
    required String description,
  }) {
    final isSelected = _selectedPaymentMethod == id;

    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedPaymentMethod = id;
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: isSelected
              ? LinearGradient(
                  colors: [
                    _primaryColor.withOpacity(0.10),
                    _primaryColor.withOpacity(0.04),
                  ],
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                )
              : null,
          color: isSelected ? null : Colors.white,
          border: Border.all(
            color: isSelected ? _primaryColor : Colors.grey.shade200,
            width: isSelected ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: isSelected
                  ? _primaryColor.withOpacity(0.15)
                  : Colors.black.withOpacity(0.04),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: isSelected ? _primaryColor : Colors.grey.shade100,
                borderRadius: BorderRadius.circular(14),
                boxShadow: isSelected
                    ? [
                        BoxShadow(
                          color: _primaryColor.withOpacity(0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 3),
                        ),
                      ]
                    : [],
              ),
              child: Icon(
                icon,
                color: isSelected ? Colors.white : Colors.grey.shade900,
                size: 26,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.inriaSerif(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: isSelected ? _primaryColor : Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    description,
                    style: GoogleFonts.inriaSerif(
                      fontSize: 12,
                      color: Colors.grey.shade800,
                    ),
                  ),
                ],
              ),
            ),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              child: isSelected
                  ? Icon(Icons.check_circle_rounded, color: _primaryColor, size: 26, key: const ValueKey('checked'))
                  : Icon(Icons.radio_button_unchecked, color: Colors.grey.shade300, size: 26, key: const ValueKey('unchecked')),
            ),
          ],
        ),
      ),
    );
  }
}
