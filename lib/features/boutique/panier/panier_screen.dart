import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'cart_manager.dart';
import '../commande/commande_screen.dart';
import '../../../services/models/shop_model.dart';
import '../../../services/models/loyalty_card_model.dart';
import '../../../services/shop_service.dart';
import '../../../services/loyalty_service.dart';
import '../../../services/auth_service.dart';
import '../loyalty/create_loyalty_card_page.dart';
import '../../../services/gift_service.dart';
import '../../../services/models/gift_model.dart';
import '../../../services/utils/api_endpoint.dart';
import '../../../core/services/boutique_theme_provider.dart';
import '../../../core/utils/responsive.dart';
import '../../../core/utils/format_utils.dart';

class PanierScreen extends StatefulWidget {
  final int shopId;
  final Shop? shop;

  const PanierScreen({super.key, required this.shopId, this.shop});

  /// Affiche le panier comme une modal bottom sheet
  static Future<bool?> show(BuildContext context, {required int shopId, Shop? shop}) {
    return showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      useSafeArea: true,
      builder: (context) => ClipRRect(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        child: SizedBox(
          height: MediaQuery.of(context).size.height * 0.95,
          child: BoutiqueThemeProvider(
            shop: shop,
            child: PanierScreen(shopId: shopId, shop: shop),
          ),
        ),
      ),
    );
  }

  @override
  State<PanierScreen> createState() => _PanierScreenState();
}

class _PanierScreenState extends State<PanierScreen> {
  final CartManager _cartManager = CartManager();
  final TextEditingController _promoController = TextEditingController();

  // Code promo
  Coupon? _appliedCoupon;
  bool _isValidatingCoupon = false;
  String? _couponError;

  // Carte de fidélité
  final TextEditingController _loyaltyCardController = TextEditingController();
  final TextEditingController _loyaltyPinController = TextEditingController();
  LoyaltyCard? _autoLoadedCard;   // Carte auto-détectée pour cette boutique
  LoyaltyCard? _verifiedLoyaltyCard;
  bool _isLoadingCard = true;
  bool _isVerifyingLoyalty = false;
  String? _loyaltyError;
  int _loyaltyDiscount = 0;
  int _loyaltyPointsUsed = 0;

  // Carte cadeau
  final TextEditingController _giftCardController = TextEditingController();
  GiftCardValidation? _appliedGiftCard;
  bool _isValidatingGiftCard = false;
  String? _giftCardError;
  int _giftCardDiscount = 0;

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

      // Charger la carte de fidélité pour cette boutique
      _loadLoyaltyCard();
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
      _loyaltyCardController.dispose();
      _loyaltyPinController.dispose();
      _giftCardController.dispose();
    } catch (e) {
      print('❌ [PanierScreen] Erreur dans dispose: $e');
    }
    super.dispose();
  }

  /// Charge automatiquement la carte de fidélité pour cette boutique
  Future<void> _loadLoyaltyCard() async {
    try {
      // S'assurer que le token est chargé avant tout appel API
      await AuthService.ensureToken();

      if (!AuthService.isAuthenticated) {
        print('🎴 [Fidélité] Non authentifié — carte non chargée');
        if (mounted) setState(() => _isLoadingCard = false);
        return;
      }

      // 1. Essayer l'endpoint dédié par boutique
      LoyaltyCard? card;
      try {
        card = await LoyaltyService.getCardForShop(widget.shopId);
        print('🎴 [Fidélité] getCardForShop(${widget.shopId}): ${card != null ? "carte trouvée (${card.points} pts)" : "aucune carte"}');
      } catch (e) {
        print('🎴 [Fidélité] getCardForShop erreur: $e — tentative via getMyCards()');
      }

      // 2. Fallback : chercher dans la liste complète des cartes
      if (card == null) {
        try {
          final allCards = await LoyaltyService.getMyCards();
          print('🎴 [Fidélité] getMyCards(): ${allCards.length} cartes trouvées');
          try {
            card = allCards.firstWhere((c) => c.shopId == widget.shopId);
            print('🎴 [Fidélité] Carte trouvée via fallback: ${card.cardNumber} (${card.points} pts)');
            // getMyCards() ne retourne pas pinCodeHint → charger le détail
            try {
              final detail = await LoyaltyService.getCardDetail(card.id);
              card = detail.card;
              print('🎴 [Fidélité] Détail chargé — pinCodeHint: ${card.pinCodeHint ?? "null"}');
            } catch (_) {
              print('🎴 [Fidélité] Détail non disponible, carte basique utilisée');
            }
          } catch (_) {
            print('🎴 [Fidélité] Aucune carte pour shopId=${widget.shopId}');
          }
        } catch (e) {
          print('🎴 [Fidélité] getMyCards() erreur: $e');
        }
      }

      if (mounted) {
        setState(() {
          _autoLoadedCard = card;
          _isLoadingCard = false;
        });
      }
    } catch (e) {
      print('🎴 [Fidélité] Erreur inattendue: $e');
      if (mounted) setState(() => _isLoadingCard = false);
    }
  }

  Future<void> _verifyLoyaltyCard(int total) async {
    final pin = _loyaltyPinController.text.trim();
    if (pin.isEmpty || _autoLoadedCard == null) return;

    setState(() { _isVerifyingLoyalty = true; _loyaltyError = null; });

    try {
      // 1. Vérifier le PIN via l'API
      await LoyaltyService.verifyPin(cardId: _autoLoadedCard!.id, pinCode: pin);

      // 2. Calculer la réduction localement : pointsValue = points × point_value (en FCFA)
      // Pas d'appel API — la valeur est déjà dans le modèle LoyaltyCard
      int discountAmount = 0;
      int pointsUsed = 0;
      if (_autoLoadedCard!.points > 0) {
        // Ne peut pas dépasser le total de la commande
        discountAmount = _autoLoadedCard!.pointsValue.clamp(0, total);
        pointsUsed = _autoLoadedCard!.points;
      }

      setState(() {
        _verifiedLoyaltyCard = _autoLoadedCard;
        _loyaltyDiscount = discountAmount;
        _loyaltyPointsUsed = pointsUsed;
        _isVerifyingLoyalty = false;
      });
    } catch (e) {
      setState(() {
        _loyaltyError = e.toString().replaceFirst('Exception: ', '');
        _verifiedLoyaltyCard = null;
        _loyaltyDiscount = 0;
        _loyaltyPointsUsed = 0;
        _isVerifyingLoyalty = false;
      });
    }
  }

  Future<void> _applyPromoCode(int total) async {
    final code = _promoController.text.trim();
    if (code.isEmpty) return;

    setState(() { _isValidatingCoupon = true; _couponError = null; });

    try {
      final coupon = await ShopService.validateCoupon(
        code: code,
        shopId: widget.shopId,
        amount: total,
      );
      setState(() { _appliedCoupon = coupon; _isValidatingCoupon = false; });
    } catch (e) {
      setState(() {
        _couponError = e.toString().replaceFirst('Exception: ', '');
        _appliedCoupon = null;
        _isValidatingCoupon = false;
      });
    }
  }

  int _calculateDiscount(int total) {
    if (_appliedCoupon == null) return 0;
    final coupon = _appliedCoupon!;
    int discount = 0;
    if (coupon.discountType == 'percentage') {
      discount = (total * coupon.discountValue / 100).round();
      if (coupon.maxDiscount != null && discount > coupon.maxDiscount!) {
        discount = coupon.maxDiscount!.toInt();
      }
    } else {
      discount = coupon.discountValue.toInt();
    }
    return discount > total ? total : discount;
  }

  Future<void> _applyGiftCard() async {
    final code = _giftCardController.text.trim();
    if (code.isEmpty) return;
    setState(() { _isValidatingGiftCard = true; _giftCardError = null; });
    try {
      final validation = await GiftService.validateGiftCard(
        code: code,
        shopId: widget.shopId,
      );
      final total = _cartManager.totalPrice;
      final discount = validation.balance > total ? total : validation.balance;
      setState(() {
        _appliedGiftCard = validation;
        _giftCardDiscount = discount;
        _isValidatingGiftCard = false;
      });
    } catch (e) {
      setState(() {
        _giftCardError = e.toString().replaceFirst('Exception: ', '');
        _appliedGiftCard = null;
        _giftCardDiscount = 0;
        _isValidatingGiftCard = false;
      });
    }
  }

  int _totalAfterDiscounts(int total) {
    final couponDiscount = _calculateDiscount(total);
    final afterCoupon = total - couponDiscount;
    final afterLoyalty = afterCoupon - _loyaltyDiscount;
    final afterGiftCard = afterLoyalty - _giftCardDiscount;
    return afterGiftCard < 0 ? 0 : afterGiftCard;
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
                // Drag handle (modal indicator)
                Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(top: 10, bottom: 4),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                // Header premium
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: Responsive.horizontalPadding(context),
                    vertical: 14,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    border: Border(
                      bottom: BorderSide(color: Colors.grey.shade100),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.04),
                        blurRadius: 12,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      // Bouton retour
                      GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: Container(
                          width: 44,
                          height: 44,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: Colors.grey.shade100,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: Colors.grey.shade200,
                              width: 1.5,
                            ),
                          ),
                          child: FaIcon(
                            FontAwesomeIcons.arrowLeft,
                            size: 17,
                            color: Colors.grey.shade900,
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
                              style: GoogleFonts.inriaSerif(
                                fontSize: 20,
                                fontWeight: FontWeight.w800,
                                color: const Color(0xFF0D0D26),
                                letterSpacing: -0.5,
                              ),
                            ),
                            Text(
                              '$itemCount article${itemCount > 1 ? 's' : ''}',
                              style: GoogleFonts.inriaSerif(
                                fontSize: 13,
                                color: Colors.grey.shade800,
                              ),
                            ),
                          ],
                        ),
                      ),
                      // Icône panier
                      Container(
                        width: 48,
                        height: 48,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: Colors.grey.shade200, width: 1.5),
                        ),
                        child: FaIcon(
                          FontAwesomeIcons.bagShopping,
                          color: Colors.grey.shade800,
                          size: 22,
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
                            alignment: Alignment.center,
                            child: FaIcon(
                              FontAwesomeIcons.bagShopping,
                              size: 60,
                              color: Colors.grey.shade900,
                            ),
                          ),
                          const SizedBox(height: 24),
                          Text(
                            'Votre panier est vide',
                            style: GoogleFonts.inriaSerif(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'Ajoutez des produits pour commencer vos achats',
                            style: GoogleFonts.inriaSerif(
                              fontSize: 14,
                              color: Colors.grey.shade800,
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
                                  colors: [_primaryColor, _theme.gradientEnd],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
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
                                style: GoogleFonts.inriaSerif(
                                  fontSize: 14,
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
                      padding: Responsive.screenPadding(context),
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
                            padding: const EdgeInsets.all(14),
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
                                    Container(
                                      width: 4,
                                      height: 22,
                                      decoration: BoxDecoration(
                                        color: Colors.grey.shade300,
                                        borderRadius: BorderRadius.circular(2),
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    FaIcon(
                                      FontAwesomeIcons.tag,
                                      color: Colors.grey.shade800,
                                      size: 18,
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      'Code promo',
                                      style: GoogleFonts.inriaSerif(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w700,
                                        color: const Color(0xFF1A1A2E),
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
                                          hintStyle: GoogleFonts.inriaSerif(
                                            fontSize: 14,
                                            color: Colors.grey.shade800,
                                          ),
                                          filled: true,
                                          fillColor: Colors.grey.shade100,
                                          contentPadding: const EdgeInsets.symmetric(
                                            horizontal: 14,
                                            vertical: 12,
                                          ),
                                          border: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(10),
                                            borderSide: BorderSide(color: Colors.grey.shade900),
                                          ),
                                          enabledBorder: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(10),
                                            borderSide: BorderSide(color: Colors.grey.shade900),
                                          ),
                                          focusedBorder: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(10),
                                            borderSide: BorderSide(
                                              color: _primaryColor,
                                              width: 2,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    GestureDetector(
                                      onTap: _isValidatingCoupon ? null : () => _applyPromoCode(total),
                                      child: AnimatedContainer(
                                        duration: const Duration(milliseconds: 200),
                                        height: 40,
                                        padding: const EdgeInsets.symmetric(horizontal: 14),
                                        decoration: BoxDecoration(
                                          color: _primaryColor,
                                          borderRadius: BorderRadius.circular(12),
                                          boxShadow: [
                                            BoxShadow(
                                              color: _primaryColor.withOpacity(0.35),
                                              blurRadius: 8,
                                              offset: const Offset(0, 3),
                                            ),
                                          ],
                                        ),
                                        child: Center(
                                          child: _isValidatingCoupon
                                              ? const SizedBox(
                                                  width: 16, height: 16,
                                                  child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                                                )
                                              : Text(
                                                  'Appliquer',
                                                  style: GoogleFonts.inriaSerif(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.white),
                                                ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),

                                // Coupon appliqué avec succès
                                if (_appliedCoupon != null) ...[
                                  const SizedBox(height: 10),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFDCFCE7),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Row(
                                      children: [
                                        const FaIcon(FontAwesomeIcons.solidCircleCheck, color: Color(0xFF16A34A), size: 16),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: Text(
                                            'Code "${_appliedCoupon!.code}" appliqué — ${_appliedCoupon!.discountType == 'percentage' ? '-${_appliedCoupon!.discountValue.toInt()}%' : '-${_appliedCoupon!.discountValue.toInt()} FCFA'}',
                                            style: GoogleFonts.inriaSerif(fontSize: 13, color: const Color(0xFF15803D), fontWeight: FontWeight.w600),
                                          ),
                                        ),
                                        GestureDetector(
                                          onTap: () => setState(() { _appliedCoupon = null; _promoController.clear(); }),
                                          child: const FaIcon(FontAwesomeIcons.xmark, size: 16, color: Color(0xFF15803D)),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],

                                // Erreur coupon
                                if (_couponError != null) ...[
                                  const SizedBox(height: 10),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFFEE2E2),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Row(
                                      children: [
                                        const FaIcon(FontAwesomeIcons.circleExclamation, color: Color(0xFFDC2626), size: 16),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: Text(
                                            _couponError!,
                                            style: GoogleFonts.inriaSerif(fontSize: 13, color: const Color(0xFFDC2626)),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),

                          const SizedBox(height: 16),

                          // Section Carte cadeau
                          _buildGiftCardSection(total),

                          const SizedBox(height: 16),

                          // Section Carte de fidélité
                          Container(
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.08),
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
                                      height: 22,
                                      decoration: BoxDecoration(
                                        color: Colors.grey.shade300,
                                        borderRadius: BorderRadius.circular(2),
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    Icon(
                                      Icons.workspace_premium_rounded,
                                      color: Colors.grey.shade800,
                                      size: 18,
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      'Carte de fidélité',
                                      style: GoogleFonts.inriaSerif(fontSize: 14, fontWeight: FontWeight.w700, color: const Color(0xFF1A1A2E)),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 10),

                                // Chargement en cours
                                if (_isLoadingCard)
                                  Center(
                                    child: SizedBox(
                                      width: 20, height: 20,
                                      child: CircularProgressIndicator(strokeWidth: 2, color: _primaryColor),
                                    ),
                                  )

                                // Aucune carte — invitation à créer
                                else if (_autoLoadedCard == null) ...[
                                  const SizedBox(height: 4),
                                  Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.all(10),
                                        decoration: BoxDecoration(
                                          color: Colors.grey.shade100,
                                          borderRadius: BorderRadius.circular(10),
                                        ),
                                        child: FaIcon(FontAwesomeIcons.gift, color: Colors.grey.shade500, size: 22),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              'Pas encore de carte fidélité',
                                              style: GoogleFonts.inriaSerif(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.black87),
                                            ),
                                            Text(
                                              'Gagnez des points à chaque commande',
                                              style: GoogleFonts.inriaSerif(fontSize: 13, color: Colors.grey.shade800),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 12),
                                  SizedBox(
                                    width: double.infinity,
                                    child: OutlinedButton.icon(
                                      onPressed: () async {
                                        final shop = BoutiqueThemeProvider.shopOf(context);
                                        final created = await Navigator.of(context).push<bool>(
                                          MaterialPageRoute(
                                            builder: (context) => BoutiqueThemeProvider(
                                              shop: widget.shop,
                                              child: CreateLoyaltyCardPage(
                                                shopId: widget.shopId,
                                                boutiqueName: widget.shop?.name ?? 'Boutique',
                                                shop: shop,
                                              ),
                                            ),
                                          ),
                                        );
                                        // Recharger la carte si elle vient d'être créée
                                        if (mounted) {
                                          setState(() => _isLoadingCard = true);
                                          _loadLoyaltyCard();
                                        }
                                      },
                                      icon: FaIcon(FontAwesomeIcons.creditCard, size: 18, color: _primaryColor),
                                      label: Text(
                                        'Créer ma carte de fidélité',
                                        style: GoogleFonts.inriaSerif(fontSize: 14, fontWeight: FontWeight.w600, color: _primaryColor),
                                      ),
                                      style: OutlinedButton.styleFrom(
                                        foregroundColor: _primaryColor,
                                        side: BorderSide(color: _primaryColor, width: 1.5),
                                        padding: const EdgeInsets.symmetric(vertical: 12),
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                      ),
                                    ),
                                  ),
                                ]

                                // Carte détectée — non encore vérifiée
                                else if (_verifiedLoyaltyCard == null) ...[
                                  Text(
                                    'Utilisez vos points de fidélité',
                                    style: GoogleFonts.inriaSerif(fontSize: 13, color: Colors.grey.shade800),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Vous avez ${_autoLoadedCard!.points} points disponibles (${_autoLoadedCard!.pointsValue} FCFA)',
                                    style: GoogleFonts.inriaSerif(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w700,
                                      color: const Color(0xFF1A1A2E),
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  // Indice du PIN
                                  Builder(builder: (context) {
                                    final phone = AuthService.currentClient?.phone;
                                    String hint;
                                    if (_autoLoadedCard!.pinCodeHint != null) {
                                      hint = _autoLoadedCard!.pinCodeHint!;
                                    } else if (phone != null && phone.length >= 4) {
                                      final digits = phone.replaceAll(RegExp(r'\D'), '');
                                      final masked = digits.length >= 4
                                          ? '••••${digits.substring(digits.length - 4)}'
                                          : phone;
                                      hint = 'PIN = 4 derniers chiffres de votre tél. ($masked)';
                                    } else {
                                      hint = 'PIN = 4 derniers chiffres de votre numéro de compte';
                                    }
                                    return Container(
                                      margin: const EdgeInsets.only(bottom: 8),
                                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                      decoration: BoxDecoration(
                                        color: Colors.grey.shade100,
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Row(
                                        children: [
                                          FaIcon(FontAwesomeIcons.circleInfo, size: 14, color: Colors.grey.shade600),
                                          const SizedBox(width: 6),
                                          Expanded(
                                            child: Text(hint, style: GoogleFonts.inriaSerif(fontSize: 13, color: Colors.grey.shade900)),
                                          ),
                                        ],
                                      ),
                                    );
                                  }),
                                  // Champ code PIN uniquement
                                  TextField(
                                    controller: _loyaltyPinController,
                                    keyboardType: TextInputType.number,
                                    maxLength: 4,
                                    obscureText: true,
                                    decoration: InputDecoration(
                                      hintText: 'Code PIN (4 chiffres)',
                                      counterText: '',
                                      hintStyle: GoogleFonts.inriaSerif(fontSize: 14, color: Colors.grey.shade800),
                                      filled: true,
                                      fillColor: Colors.grey.shade100,
                                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: Colors.grey.shade400)),
                                      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: Colors.grey.shade400)),
                                      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: _primaryColor, width: 2)),
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  GestureDetector(
                                    onTap: _isVerifyingLoyalty ? null : () => _verifyLoyaltyCard(total),
                                    child: AnimatedContainer(
                                      duration: const Duration(milliseconds: 200),
                                      width: double.infinity,
                                      height: 52,
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        borderRadius: BorderRadius.circular(14),
                                        border: Border.all(color: Colors.grey.shade300),
                                        boxShadow: [
                                          BoxShadow(
                                            color: Colors.black.withOpacity(0.08),
                                            blurRadius: 8,
                                            offset: const Offset(0, 2),
                                          ),
                                        ],
                                      ),
                                      child: Center(
                                        child: _isVerifyingLoyalty
                                            ? SizedBox(width: 18, height: 18, child: CircularProgressIndicator(color: Colors.grey.shade600, strokeWidth: 2))
                                            : Text('Valider le code PIN', style: GoogleFonts.inriaSerif(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.grey.shade800)),
                                      ),
                                    ),
                                  ),
                                  // Erreur PIN
                                  if (_loyaltyError != null) ...[
                                    const SizedBox(height: 10),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                      decoration: BoxDecoration(color: const Color(0xFFFEE2E2), borderRadius: BorderRadius.circular(8)),
                                      child: Row(
                                        children: [
                                          const FaIcon(FontAwesomeIcons.circleExclamation, color: Color(0xFFDC2626), size: 16),
                                          const SizedBox(width: 8),
                                          Expanded(child: Text(_loyaltyError!, style: GoogleFonts.inriaSerif(fontSize: 13, color: const Color(0xFFDC2626)))),
                                        ],
                                      ),
                                    ),
                                  ],
                                ]

                                // Carte vérifiée avec succès
                                else ...[
                                  Container(
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFEDF7ED),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: Row(
                                      children: [
                                        const FaIcon(FontAwesomeIcons.solidStar, color: Color(0xFF2E7D32), size: 20),
                                        const SizedBox(width: 10),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                'Carte vérifiée ✓',
                                                style: GoogleFonts.inriaSerif(fontSize: 14, fontWeight: FontWeight.w700, color: const Color(0xFF2E7D32)),
                                              ),
                                              Text(
                                                '${_verifiedLoyaltyCard!.points} pts${_loyaltyDiscount > 0 ? ' · −$_loyaltyDiscount FCFA appliqué' : ' utilisés'}',
                                                style: GoogleFonts.inriaSerif(fontSize: 13, color: const Color(0xFF4CAF50)),
                                              ),
                                            ],
                                          ),
                                        ),
                                        GestureDetector(
                                          onTap: () => setState(() {
                                            _verifiedLoyaltyCard = null;
                                            _loyaltyDiscount = 0;
                                            _loyaltyPointsUsed = 0;
                                            _loyaltyPinController.clear();
                                          }),
                                          child: const FaIcon(FontAwesomeIcons.xmark, size: 16, color: Color(0xFF2E7D32)),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),

                          const SizedBox(height: 16),

                          // Résumé de la commande
                          Container(
                            padding: const EdgeInsets.all(14),
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
                                        color: Colors.grey.shade100,
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: FaIcon(
                                        FontAwesomeIcons.receipt,
                                        color: Colors.grey.shade800,
                                        size: 20,
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Text(
                                      'Résumé de la commande',
                                      style: GoogleFonts.inriaSerif(
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
                                      style: GoogleFonts.inriaSerif(
                                        fontSize: 14,
                                        color: Colors.grey.shade800,
                                      ),
                                    ),
                                    Text(
                                      '$total FCFA',
                                      style: GoogleFonts.inriaSerif(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.black87,
                                      ),
                                    ),
                                  ],
                                ),
                                // Ligne réduction coupon
                                if (_appliedCoupon != null) ...[
                                  const SizedBox(height: 10),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        'Réduction (${_appliedCoupon!.code})',
                                        style: GoogleFonts.inriaSerif(fontSize: 14, color: const Color(0xFF16A34A)),
                                      ),
                                      Text(
                                        '-${_calculateDiscount(total)} FCFA',
                                        style: GoogleFonts.inriaSerif(fontSize: 14, fontWeight: FontWeight.w600, color: const Color(0xFF16A34A)),
                                      ),
                                    ],
                                  ),
                                ],
                                // Ligne réduction carte cadeau
                                if (_appliedGiftCard != null && _giftCardDiscount > 0) ...[
                                  const SizedBox(height: 10),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        'Carte cadeau (${_appliedGiftCard!.code})',
                                        style: GoogleFonts.inriaSerif(fontSize: 14, color: const Color(0xFF6B21A8)),
                                      ),
                                      Text(
                                        '-$_giftCardDiscount FCFA',
                                        style: GoogleFonts.inriaSerif(fontSize: 14, fontWeight: FontWeight.w600, color: const Color(0xFF6B21A8)),
                                      ),
                                    ],
                                  ),
                                ],
                                // Ligne réduction fidélité
                                if (_verifiedLoyaltyCard != null && _loyaltyDiscount > 0) ...[
                                  const SizedBox(height: 10),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        'Fidélité (${_verifiedLoyaltyCard!.points} pts)',
                                        style: GoogleFonts.inriaSerif(fontSize: 14, color: const Color(0xFF16A34A)),
                                      ),
                                      Text(
                                        '-$_loyaltyDiscount FCFA',
                                        style: GoogleFonts.inriaSerif(fontSize: 14, fontWeight: FontWeight.w600, color: const Color(0xFF16A34A)),
                                      ),
                                    ],
                                  ),
                                ],
                                const SizedBox(height: 16),
                                const Divider(height: 1),
                                const SizedBox(height: 16),
                                // Total
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      'Total',
                                      style: GoogleFonts.inriaSerif(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.black87),
                                    ),
                                    Row(
                                      crossAxisAlignment: CrossAxisAlignment.end,
                                      children: [
                                        Text(
                                          fmtAmount(_totalAfterDiscounts(total)),
                                          style: GoogleFonts.inriaSerif(fontSize: sp(20, MediaQuery.of(context).size.width), fontWeight: FontWeight.bold, color: const Color(0xFF0D0D26), height: 1),
                                        ),
                                        const SizedBox(width: 4),
                                        Padding(
                                          padding: const EdgeInsets.only(bottom: 2),
                                          child: Text(
                                            'FCFA',
                                            style: GoogleFonts.inriaSerif(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.grey.shade800),
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
                    color: Colors.black.withOpacity(0.08),
                    blurRadius: 20,
                    offset: const Offset(0, -4),
                  ),
                  BoxShadow(
                    color: Colors.black.withOpacity(0.04),
                    blurRadius: 8,
                    offset: const Offset(0, -1),
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
                            couponCode: _appliedCoupon?.code,
                            couponDiscountAmount: _appliedCoupon != null
                                ? _calculateDiscount(total).toDouble()
                                : null,
                            loyaltyCardId: _verifiedLoyaltyCard?.id,
                            loyaltyPointsUsed: _loyaltyPointsUsed > 0 ? _loyaltyPointsUsed : null,
                            loyaltyDiscount: _loyaltyDiscount > 0
                                ? _loyaltyDiscount.toDouble()
                                : null,
                            loyaltyPointValue: _autoLoadedCard?.pointValue,
                            giftCardCode: _appliedGiftCard?.code,
                            giftCardDiscount: _giftCardDiscount > 0
                                ? _giftCardDiscount.toDouble()
                                : null,
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
                        colors: [_primaryColor, _theme.gradientEnd],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
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
                        style: GoogleFonts.inriaSerif(
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

  Widget _buildGiftCardSection(int total) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Container(
              width: 4, height: 22,
              decoration: BoxDecoration(
                color: const Color(0xFF6B21A8).withOpacity(0.5),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(width: 10),
            const FaIcon(FontAwesomeIcons.creditCard, color: Color(0xFF6B21A8), size: 17),
            const SizedBox(width: 8),
            Text('Carte cadeau', style: GoogleFonts.inriaSerif(
              fontSize: 14, fontWeight: FontWeight.w700, color: const Color(0xFF1A1A2E))),
          ]),
          const SizedBox(height: 12),

          if (_appliedGiftCard == null) ...[
            Row(children: [
              Expanded(
                child: TextField(
                  controller: _giftCardController,
                  textCapitalization: TextCapitalization.characters,
                  decoration: InputDecoration(
                    hintText: 'Code carte (GC-XXXXXXXX)',
                    hintStyle: GoogleFonts.inriaSerif(fontSize: 13, color: Colors.grey.shade500),
                    filled: true,
                    fillColor: const Color(0xFFF5F5F5),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  style: GoogleFonts.inriaSerif(fontSize: 14, fontWeight: FontWeight.w600),
                ),
              ),
              const SizedBox(width: 10),
              GestureDetector(
                onTap: _isValidatingGiftCard ? null : _applyGiftCard,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF6B21A8),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: _isValidatingGiftCard
                      ? const SizedBox(width: 18, height: 18,
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : Text('Appliquer', style: GoogleFonts.inriaSerif(
                          color: Colors.white, fontWeight: FontWeight.w700, fontSize: 13)),
                ),
              ),
            ]),
            if (_giftCardError != null) ...[
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFFFEF2F2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(children: [
                  const FaIcon(FontAwesomeIcons.circleExclamation, color: Color(0xFFDC2626), size: 14),
                  const SizedBox(width: 8),
                  Expanded(child: Text(_giftCardError!, style: GoogleFonts.inriaSerif(
                    fontSize: 12, color: const Color(0xFFDC2626)))),
                ]),
              ),
            ],
          ] else ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: const Color(0xFF6B21A8).withOpacity(0.06),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFF6B21A8).withOpacity(0.3)),
              ),
              child: Row(children: [
                const FaIcon(FontAwesomeIcons.circleCheck, color: Color(0xFF6B21A8), size: 16),
                const SizedBox(width: 10),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(_appliedGiftCard!.code, style: GoogleFonts.inriaSerif(
                    fontSize: 13, fontWeight: FontWeight.w800, color: const Color(0xFF6B21A8))),
                  Text(
                    'Solde: ${_appliedGiftCard!.balance} FCFA · −$_giftCardDiscount FCFA appliqué',
                    style: GoogleFonts.inriaSerif(fontSize: 12, color: const Color(0xFF6B21A8)),
                  ),
                ])),
                GestureDetector(
                  onTap: () => setState(() {
                    _appliedGiftCard = null;
                    _giftCardDiscount = 0;
                    _giftCardController.clear();
                  }),
                  child: const FaIcon(FontAwesomeIcons.xmark, size: 16, color: Color(0xFF6B21A8)),
                ),
              ]),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildCartItem(int index, Map<String, dynamic> item) {
    final String? imageUrl = _getFullImageUrl(item['image']?.toString());
    final int? discount = _getDiscount(item);
    final p = item['price'];
    final q = item['quantity'];
    final int subtotal = (p is int ? p : (p is num ? p.toInt() : int.tryParse(p?.toString() ?? '0') ?? 0))
        * (q is int ? q : (q is num ? q.toInt() : int.tryParse(q?.toString() ?? '1') ?? 1));

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
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
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
                                    child: FaIcon(
                                      FontAwesomeIcons.bagShopping,
                                      size: 40,
                                      color: Colors.grey.shade900,
                                    ),
                                  );
                                },
                              ),
                            )
                          : Center(
                              child: FaIcon(
                                FontAwesomeIcons.bagShopping,
                                size: 40,
                                color: Colors.grey.shade900,
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
                          color: const Color(0xFFCC0000),
                          borderRadius: const BorderRadius.only(
                            topLeft: Radius.circular(16),
                            bottomRight: Radius.circular(12),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const FaIcon(FontAwesomeIcons.wandMagicSparkles, size: 10, color: Colors.white),
                            const SizedBox(width: 4),
                            Text(
                              '-$discount%',
                              style: GoogleFonts.inriaSerif(
                                fontSize: 12,
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
                      style: GoogleFonts.inriaSerif(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    // Taille sélectionnée
                    if (item['size'] != null) ...[
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          'Taille : ${item['size']}',
                          style: GoogleFonts.inriaSerif(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: Colors.grey.shade900,
                          ),
                        ),
                      ),
                    ],
                    const SizedBox(height: 8),

                    // Prix
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          '${item['price']}',
                          style: GoogleFonts.inriaSerif(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: const Color.fromARGB(255, 9, 9, 9),
                          ),
                        ),
                        const SizedBox(width: 4),
                        Padding(
                          padding: const EdgeInsets.only(bottom: 3),
                          child: Text(
                            'FCFA',
                            style: GoogleFonts.inriaSerif(
                              fontSize: 13,
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
                        // Contrôles de quantité (cercles premium)
                        Row(
                          children: [
                            // Bouton - (cercle outline)
                            GestureDetector(
                              onTap: () {
                                if (item['quantity'] > 1) {
                                  _cartManager.updateQuantity(
                                    index,
                                    item['quantity'] - 1,
                                  );
                                }
                              },
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 180),
                                width: 30,
                                height: 30,
                                alignment: Alignment.center,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: Colors.white,
                                  border: Border.all(
                                    color: item['quantity'] > 1
                                        ? Colors.grey.shade900
                                        : Colors.grey.shade300,
                                    width: 1.5,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.10),
                                      blurRadius: 6,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: FaIcon(
                                  FontAwesomeIcons.minus,
                                  size: 13,
                                  color: item['quantity'] > 1
                                      ? Colors.grey.shade900
                                      : Colors.grey.shade900,
                                ),
                              ),
                            ),

                            // Quantité
                            SizedBox(
                              width: 38,
                              child: Center(
                                child: Text(
                                  '${item['quantity']}',
                                  style: GoogleFonts.inriaSerif(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: const Color(0xFF0D0D26),
                                  ),
                                ),
                              ),
                            ),

                            // Bouton + (cercle gradient)
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
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 180),
                                width: 30,
                                height: 30,
                                alignment: Alignment.center,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  gradient: LinearGradient(
                                    colors: [_primaryColor, _theme.gradientEnd],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: _primaryColor.withOpacity(0.36),
                                      blurRadius: 8,
                                      offset: const Offset(0, 3),
                                    ),
                                  ],
                                ),
                                child: const FaIcon(
                                  FontAwesomeIcons.plus,
                                  size: 13,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ],
                        ),

                        const Spacer(),

                        // Bouton supprimer
                        GestureDetector(
                          onTap: () {
                            _cartManager.removeItem(index);
                          },
                          child: Container(
                            width: 32,
                            height: 32,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: const Color(0xFFFEE2E2),
                              borderRadius: BorderRadius.circular(8),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.red.withOpacity(0.18),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: const FaIcon(
                              FontAwesomeIcons.trash,
                              size: 14,
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
                  style: GoogleFonts.inriaSerif(
                    fontSize: 14,
                    color: Colors.grey.shade800,
                  ),
                ),
                Text(
                  '${fmtAmount(subtotal)} FCFA',
                  style: GoogleFonts.inriaSerif(
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
