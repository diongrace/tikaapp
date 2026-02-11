import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:uuid/uuid.dart';
import '../panier/cart_manager.dart';
import 'form_widgets.dart';
import 'loading_success_page.dart';
import 'order_summary_page.dart';
import 'wave_payment_screen.dart';
import '../../../core/messages/message_modal.dart';
import '../../../core/services/storage_service.dart';
import '../../../core/services/boutique_theme_provider.dart';
import '../../../services/order_service.dart';
import '../../../services/device_service.dart';
import '../../../services/shop_service.dart';
import '../../../services/models/shop_model.dart';

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

  const CommandeScreen({super.key, required this.shopId, this.shop});

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

  // Étape 2 - Mode de livraison
  String? _selectedDeliveryMode; // "Livraison" ou "À emporter"
  DateTime? _selectedPickupDate; // Date de récupération (pour À emporter)
  TimeOfDay? _selectedPickupTime; // Heure de récupération (pour À emporter)

  // Étape 3 - Méthode de paiement
  String _selectedPaymentMethod = 'especes'; // "especes", "mobile_money", "carte"

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
        setState(() {
          _currentStep++;
        });
      }
    } else if (_currentStep == 1) {
      // Vérifier qu'un mode de livraison est sélectionné
      if (_selectedDeliveryMode == null) {
        showErrorModal(context, 'Veuillez sélectionner un mode de livraison');
        return;
      }

      // Si Livraison, vérifier l'adresse
      if (_selectedDeliveryMode == 'Livraison' && _addressController.text.isEmpty) {
        showErrorModal(context, 'Veuillez entrer votre adresse de livraison');
        return;
      }

      // Si À emporter, vérifier date/heure et créer la commande directement
      if (_selectedDeliveryMode == 'À emporter') {
        if (_selectedPickupDate == null) {
          showErrorModal(context, 'Veuillez sélectionner la date de récupération');
          return;
        }
        if (_selectedPickupTime == null) {
          showErrorModal(context, 'Veuillez sélectionner l\'heure de récupération');
          return;
        }
        // Créer la commande directement (paiement en boutique)
        _createOrder();
        return;
      }

      // Si Livraison, passer à l'étape 3 (paiement)
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
            onConfirm: () {
              // Fermer la page de résumé
              Navigator.of(context).pop();

              // Wave → page de paiement Wave, sinon création de commande
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

  /// Naviguer vers l'écran de paiement Wave (Mode Screenshot)
  ///
  /// Flux:
  /// 1. Sauvegarder commande en attente localement
  /// 2. Afficher le lien Wave du vendeur → client paie
  /// 3. Client prend screenshot de la confirmation
  /// 4. POST /mobile/orders/create-with-wave-proof (commande + preuve)
  Future<void> _navigateToWavePayment() async {
    if (!mounted) return;

    // Générer un ID unique pour la commande en attente
    final pendingOrderId = const Uuid().v4();
    final total = _cartManager.totalPrice.toDouble();

    // Sauvegarder les données de commande en cache pour Wave
    final pendingOrderData = {
      'pending_order_id': pendingOrderId,
      'shop_id': widget.shopId,
      'customer_name': _nomController.text,
      'customer_phone': _phoneController.text,
      'customer_email': _emailController.text.isNotEmpty ? _emailController.text : null,
      'service_type': _mapDeliveryModeToApi(_selectedDeliveryMode),
      'delivery_address': _addressController.text.isNotEmpty ? _addressController.text : null,
      'items': _cartManager.getItemsForOrder(),
      'total': total,
      'created_at': DateTime.now().toIso8601String(),
    };

    // Sauvegarder en cache local
    await StorageService.savePendingWaveOrder(pendingOrderData);

    // Récupérer le lien Wave du vendeur
    String? wavePaymentLink = widget.shop?.wavePaymentLink;

    print('🌊 ━━━ WAVE NAVIGATION ━━━');
    print('🌊 Shop: ${widget.shop?.name} (ID: ${widget.shopId})');
    print('🌊 wavePaymentLink en memoire: $wavePaymentLink');

    // Si pas de lien en mémoire, rechercher via les API
    if (wavePaymentLink == null) {
      try {
        wavePaymentLink = await ShopService.getWavePaymentLink(widget.shopId);
      } catch (e) {
        print('🌊 Erreur recherche wave link: $e');
      }
    }

    print('🌊 wavePaymentLink final: $wavePaymentLink');
    print('🌊 ━━━━━━━━━━━━━━━━━━━━━━');

    if (!mounted) return;

    // Naviguer vers l'écran Wave
    final result = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (context) => BoutiqueThemeProvider(
          shop: widget.shop,
          child: WavePaymentScreen(
            pendingOrderId: pendingOrderId,
            amount: total,
            wavePaymentLink: wavePaymentLink,
            onPaymentSuccess: (response) {
              print('✅ Wave payment success: ${response.orderNumber}');
            },
            onCancel: () {
              print('❌ Wave payment cancelled');
            },
          ),
        ),
      ),
    );

    if (result == true && mounted) {
      // Paiement réussi - nettoyer et retourner
      _cartManager.clear();
      await StorageService.deletePendingWaveOrder(pendingOrderId);
      Navigator.of(context).pop(true);
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
      if (_selectedDeliveryMode == 'Livraison' && _addressController.text.isNotEmpty) {
        deliveryAddress = _addressController.text;
        print('📍 Adresse: $deliveryAddress');
      }

      // Appeler l'API - AVEC payment_method
      final response = await OrderService.createOrder(
        shopId: widget.shopId,
        customerName: _nomController.text,
        customerPhone: _phoneController.text,
        serviceType: serviceType,
        deviceFingerprint: deviceFingerprint,
        items: items,
        paymentMethod: _selectedPaymentMethod, // ✅ AJOUTÉ
        customerEmail: _emailController.text.isNotEmpty ? _emailController.text : null,
        customerAddress: _addressController.text.isNotEmpty ? _addressController.text : null,
        deliveryAddress: deliveryAddress,
      );

      print('✅ Commande créée !');
      print('   - Order Number: ${response['order_number']}');
      print('   - Status: ${response['status']}');
      print('   - Payment Status: ${response['payment_status']}');

      // GESTION REDIRECTION WAVE — Ouvrir Wave directement (comme le web)
      // Accepter wave_redirect OU wave_url seul (certains backends ne renvoient que l'URL)
      final waveUrl = response['wave_url']?.toString();
      if (response['wave_redirect'] == true || (waveUrl != null && waveUrl.isNotEmpty)) {
        print('🌊 REDIRECTION WAVE DÉTECTÉE');
        print('   - Wave URL: $waveUrl');
        print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');

        if (waveUrl != null && waveUrl.isNotEmpty) {
          // Ouvrir l'URL Wave → Wave app s'ouvre avec montant + marchand
          try {
            await launchUrl(
              Uri.parse(waveUrl),
              mode: LaunchMode.externalApplication,
            );
            print('🌊 Wave ouvert avec succes');
          } catch (e) {
            print('🌊 Erreur ouverture Wave: $e');
          }
        }

        // Continuer vers la page de succes (la commande est deja creee)
        // Le backend confirmera le paiement via webhook Wave
      }

      print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');

      // Préparer les données pour la page de succès
      final orderNumber = response['order_number'] as String;

      // Utiliser les URLs de l'API si disponibles, sinon construire les URLs
      final receiptUrl = response['receipt_url'] ??
          'https://prepro.tika-ci.com/api/client/orders/$orderNumber/receipt/download';
      final receiptViewUrl = response['receipt_view_url'] ??
          'https://prepro.tika-ci.com/api/client/orders/$orderNumber/receipt';

      print('📄 Receipt URL: $receiptUrl');
      print('📄 Receipt View URL: $receiptViewUrl');

      final orderData = {
        'orderNumber': orderNumber,
        'customerPhone': _phoneController.text,
        'customerName': _nomController.text,
        'receiptUrl': receiptUrl,
        'receiptViewUrl': receiptViewUrl,
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
                    style: GoogleFonts.openSans(
                      fontSize: 20,
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
                  _buildStepIndicator(1, 'Info', _currentStep >= 0),
                  Expanded(
                    child: Container(
                      height: 2,
                      color: _currentStep >= 1 ? _primaryColor : Colors.grey.shade300,
                    ),
                  ),
                  _buildStepIndicator(
                    2,
                    _selectedDeliveryMode == 'À emporter' ? 'Récupération' : 'Livraison',
                    _currentStep >= 1,
                  ),
                  // Afficher l'étape paiement seulement si Livraison
                  if (_selectedDeliveryMode == 'Livraison') ...[
                    Expanded(
                      child: Container(
                        height: 2,
                        color: _currentStep >= 2 ? _primaryColor : Colors.grey.shade300,
                      ),
                    ),
                    _buildStepIndicator(3, 'Paiement', _currentStep >= 2),
                  ],
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
                      child: OutlinedButton(
                        onPressed: _previousStep,
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          side: BorderSide(color: _primaryColor),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Text(
                          'Retour',
                          style: GoogleFonts.openSans(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: _primaryColor,
                          ),
                        ),
                      ),
                    ),
                  if (_currentStep > 0) const SizedBox(width: 12),
                  Expanded(
                    flex: _currentStep == 0 ? 1 : 2,
                    child: ElevatedButton(
                      onPressed: _nextStep,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        backgroundColor: _primaryColor,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        (_currentStep == 2 && _selectedDeliveryMode == 'Livraison') ||
                                (_currentStep == 1 && _selectedDeliveryMode == 'À emporter')
                            ? 'Valider la commande'
                            : 'Continuer',
                        style: GoogleFonts.openSans(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
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

  Widget _buildStepIndicator(int step, String label, bool isActive) {
    return Column(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: isActive ? _primaryColor : Colors.grey.shade300,
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Text(
              '$step',
              style: GoogleFonts.openSans(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: GoogleFonts.openSans(
            fontSize: 12,
            color: isActive ? _primaryColor : Colors.grey.shade600,
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
            style: GoogleFonts.poppins(
              fontSize: 20,
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

          FormFieldWidget(
            label: 'Adresse (optionnel)',
            hint: 'Votre adresse',
            icon: Icons.location_on,
            controller: _addressController,
            maxLines: 2,
            required: false,
          ),
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
          style: GoogleFonts.poppins(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 20),

        // Option Livraison à domicile
        _buildDeliveryOption(
          id: 'Livraison',
          icon: Icons.delivery_dining,
          title: 'Livraison à domicile',
          description: 'Nous livrons à votre adresse',
        ),
        const SizedBox(height: 12),

        // Option À emporter
        _buildDeliveryOption(
          id: 'À emporter',
          icon: Icons.shopping_bag,
          title: 'À emporter',
          description: 'Récupérer en boutique',
        ),

        // Si Livraison sélectionnée, afficher champ adresse
        if (_selectedDeliveryMode == 'Livraison') ...[
          const SizedBox(height: 20),
          FormFieldWidget(
            label: 'Adresse de livraison',
            hint: 'Entrez votre adresse complète',
            icon: Icons.location_on,
            controller: _addressController,
            maxLines: 3,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'L\'adresse est requise pour la livraison';
              }
              return null;
            },
          ),
        ],

        // Si À emporter sélectionné, afficher date/heure de récupération
        if (_selectedDeliveryMode == 'À emporter') ...[
          const SizedBox(height: 28),
          Text(
            'Quand souhaitez-vous récupérer votre commande ?',
            style: GoogleFonts.openSans(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 16),

          // Sélection de date
          GestureDetector(
            onTap: () => _selectPickupDate(),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: _selectedPickupDate != null
                      ? _primaryColor
                      : Colors.grey.shade300,
                  width: _selectedPickupDate != null ? 2 : 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.calendar_today_outlined,
                    color: _selectedPickupDate != null
                        ? _primaryColor
                        : Colors.grey.shade600,
                    size: 22,
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Date de récupération',
                          style: GoogleFonts.openSans(
                            fontSize: 12,
                            color: Colors.grey.shade600,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _formatDate(_selectedPickupDate),
                          style: GoogleFonts.openSans(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: _selectedPickupDate != null
                                ? Colors.black87
                                : Colors.grey.shade500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    Icons.arrow_forward_ios,
                    size: 16,
                    color: Colors.grey.shade400,
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Sélection d'heure
          GestureDetector(
            onTap: () => _selectPickupTime(),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: _selectedPickupTime != null
                      ? _primaryColor
                      : Colors.grey.shade300,
                  width: _selectedPickupTime != null ? 2 : 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.access_time_outlined,
                    color: _selectedPickupTime != null
                        ? _primaryColor
                        : Colors.grey.shade600,
                    size: 22,
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Heure de récupération',
                          style: GoogleFonts.openSans(
                            fontSize: 12,
                            color: Colors.grey.shade600,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _formatTime(_selectedPickupTime),
                          style: GoogleFonts.openSans(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: _selectedPickupTime != null
                                ? Colors.black87
                                : Colors.grey.shade500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    Icons.arrow_forward_ios,
                    size: 16,
                    color: Colors.grey.shade400,
                  ),
                ],
              ),
            ),
          ),
        ],
      ],
    );
  }

  /// ÉTAPE 3: Méthode de paiement
  Widget _buildStep3() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Méthode de paiement',
          style: GoogleFonts.poppins(
            fontSize: 20,
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
        const SizedBox(height: 12),

        // Option Wave (avec capture d'écran)
        _buildPaymentOptionWithImage(
          id: 'wave',
          imagePath: 'lib/core/assets/WAVE.png',
          title: 'Wave',
          description: 'Paiement par capture d\'écran',
          color: const Color(0xFF1BA5E0),
          badge: 'Recommandé',
        ),

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
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected ? color.withOpacity(0.1) : Colors.grey.shade50,
          border: Border.all(
            color: isSelected ? color : Colors.grey.shade300,
            width: isSelected ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Container(
              width: 50,
              height: 50,
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.grey.shade200),
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
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: isSelected ? color : Colors.black87,
                        ),
                      ),
                      if (badge != null) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: color,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            badge,
                            style: GoogleFonts.openSans(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    description,
                    style: GoogleFonts.openSans(
                      fontSize: 13,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ),
            if (isSelected)
              Icon(Icons.check_circle, color: color, size: 24),
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
      onTap: () {
        setState(() {
          _selectedDeliveryMode = id;
        });
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected ? _primaryColor.withOpacity(0.1) : Colors.grey.shade50,
          border: Border.all(
            color: isSelected ? _primaryColor : Colors.grey.shade300,
            width: isSelected ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: isSelected ? _primaryColor : Colors.grey.shade300,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: Colors.white, size: 28),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: isSelected ? _primaryColor : Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    description,
                    style: GoogleFonts.openSans(
                      fontSize: 13,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ),
            if (isSelected)
              Icon(Icons.check_circle, color: _primaryColor, size: 24),
          ],
        ),
      ),
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
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected ? _primaryColor.withOpacity(0.1) : Colors.grey.shade50,
          border: Border.all(
            color: isSelected ? _primaryColor : Colors.grey.shade300,
            width: isSelected ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: isSelected ? _primaryColor : Colors.grey.shade300,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: Colors.white, size: 28),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: isSelected ? _primaryColor : Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    description,
                    style: GoogleFonts.openSans(
                      fontSize: 13,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ),
            if (isSelected)
              Icon(Icons.check_circle, color: _primaryColor, size: 24),
          ],
        ),
      ),
    );
  }
}
