import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'loyalty_card_page.dart';
import '../../../services/loyalty_service.dart';
import '../../../services/auth_service.dart';
import '../../../services/models/loyalty_card_model.dart';
import '../../../services/models/shop_model.dart';
import '../../../services/shop_service.dart';
import '../home/home_online_screen.dart';
import '../../auth/login_screen.dart';


/// Page de creation de carte de fidelite
/// L'API n'a besoin que du shop_id (le PIN est auto-genere)
class CreateLoyaltyCardPage extends StatefulWidget {
  final int shopId;
  final String boutiqueName;
  final Shop? shop;
  /// true = on arrive ici après une suppression.
  /// On saute la vérification de carte existante pour éviter
  /// que getMyCards() (plus lent à refléter la suppression) redirige
  /// vers la carte supprimée.
  final bool cardWasDeleted;

  const CreateLoyaltyCardPage({
    super.key,
    required this.shopId,
    required this.boutiqueName,
    this.shop,
    this.cardWasDeleted = false,
  });

  @override
  State<CreateLoyaltyCardPage> createState() => _CreateLoyaltyCardPageState();
}

class _CreateLoyaltyCardPageState extends State<CreateLoyaltyCardPage> {
  bool _isLoading = false;
  bool _isCheckingExisting = true;
  Shop? _loadedShop;

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  Future<void> _initialize() async {
    // Verifier la connexion
    await AuthService.ensureToken();
    if (!AuthService.isAuthenticated) {
      if (mounted) _showLoginRequired();
      return;
    }

    // Charger la boutique si pas fournie
    if (widget.shop == null) {
      _loadShop();
    }

    // Si on arrive après une suppression, afficher le formulaire directement.
    // getMyCards() peut être plus lent à refléter la suppression que getCardForShop(),
    // ce qui causerait une redirection vers la carte supprimée.
    print('[CREATE] cardWasDeleted=${widget.cardWasDeleted}');
    if (widget.cardWasDeleted) {
      print('[CREATE] Suppression récente → formulaire direct, skip vérification');
      if (mounted) setState(() => _isCheckingExisting = false);
      return;
    }

    // Verifier si une carte existe deja (primary: getCardForShop, fallback: getMyCards)
    try {
      LoyaltyCard? existingCard = await LoyaltyService.getCardForShop(widget.shopId);
      print('[CREATE] getCardForShop(${widget.shopId}) → ${existingCard?.id ?? 'null'}');

      // Fallback: si null (ex: 422 sur cet endpoint), chercher via getMyCards
      if (existingCard == null) {
        try {
          final allCards = await LoyaltyService.getMyCards();
          existingCard = allCards.firstWhere((c) => c.shopId == widget.shopId);
          print('[CREATE] fallback getMyCards → trouvé id=${existingCard.id}');
        } catch (_) {
          print('[CREATE] fallback getMyCards → aucune carte trouvée');
        }
      }

      if (existingCard != null && mounted) {
        // Carte deja existante: naviguer directement
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (context) => LoyaltyCardPage(loyaltyCard: existingCard!),
          ),
        );
        return;
      }
    } catch (_) {}

    if (mounted) {
      setState(() => _isCheckingExisting = false);
    }
  }

  void _showLoginRequired() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        contentPadding: const EdgeInsets.all(24),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFF3E5F5),
                shape: BoxShape.circle,
              ),
              alignment: Alignment.center,
              child: const FaIcon(
                FontAwesomeIcons.lock,
                size: 36,
                color: Color(0xFF670C88),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Connexion requise',
              style: GoogleFonts.inriaSerif(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF1E293B),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Vous devez être connecté pour créer une carte de fidélité.',
              style: GoogleFonts.inriaSerif(
                fontSize: 14,
                color: Colors.grey.shade800,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              Navigator.of(context).pop();
            },
            child: Text(
              'Annuler',
              style: GoogleFonts.inriaSerif(
                color: Colors.grey.shade800,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              Navigator.of(context).pushReplacement(
                MaterialPageRoute(builder: (_) => const LoginScreen()),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF670C88),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: Text(
              'Se connecter',
              style: GoogleFonts.inriaSerif(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _loadShop() async {
    try {
      final shop = await ShopService.getShopById(widget.shopId);
      if (mounted) {
        setState(() => _loadedShop = shop);
      }
    } catch (e) {
      print('Erreur chargement shop: $e');
    }
  }

  void _showCreationForm() {
    final client = AuthService.currentClient;
    final nameController = TextEditingController(text: client?.name ?? '');
    final phoneController = TextEditingController(text: client?.phone ?? '');
    final formKey = GlobalKey<FormState>();
    bool isSubmitting = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) => Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(ctx).viewInsets.bottom,
          ),
          child: Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Barre indicateur
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'Créer ma carte de fidélité',
                    style: GoogleFonts.inriaSerif(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF1E293B),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Vérifiez vos informations avant de confirmer',
                    style: GoogleFonts.inriaSerif(
                      fontSize: 13,
                      color: Colors.grey.shade600,
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Nom
                  Text(
                    'Votre nom',
                    style: GoogleFonts.inriaSerif(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF1E293B),
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: nameController,
                    style: GoogleFonts.inriaSerif(fontSize: 14),
                    decoration: InputDecoration(
                      hintText: 'Votre nom complet',
                      hintStyle: GoogleFonts.inriaSerif(color: Colors.grey.shade400),
                      filled: true,
                      fillColor: const Color(0xFFF8FAFC),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.grey.shade200),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.grey.shade200),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Color(0xFF670C88)),
                      ),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      prefixIcon: const Padding(
                        padding: EdgeInsets.all(14),
                        child: FaIcon(FontAwesomeIcons.user, size: 16, color: Color(0xFF670C88)),
                      ),
                      prefixIconConstraints: const BoxConstraints(minWidth: 48, minHeight: 48),
                    ),
                    validator: (v) => (v == null || v.trim().isEmpty) ? 'Champ requis' : null,
                  ),
                  const SizedBox(height: 16),

                  // Téléphone (lecture seule — sert de PIN)
                  Text(
                    'Numéro de téléphone',
                    style: GoogleFonts.inriaSerif(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF1E293B),
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: phoneController,
                    readOnly: true,
                    style: GoogleFonts.inriaSerif(fontSize: 14, color: Colors.grey.shade600),
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: Colors.grey.shade100,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.grey.shade200),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.grey.shade200),
                      ),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      prefixIcon: const Padding(
                        padding: EdgeInsets.all(14),
                        child: FaIcon(FontAwesomeIcons.phone, size: 16, color: Colors.grey),
                      ),
                      prefixIconConstraints: const BoxConstraints(minWidth: 48, minHeight: 48),
                      suffixIcon: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: const Color(0xFF2196F3).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            'PIN auto',
                            style: GoogleFonts.inriaSerif(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFF2196F3),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 28),

                  // Bouton confirmer
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      onPressed: isSubmitting
                          ? null
                          : () async {
                              if (!formKey.currentState!.validate()) return;
                              setSheetState(() => isSubmitting = true);
                              Navigator.of(ctx).pop();
                              await _createCard();
                            },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF670C88),
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: isSubmitting
                          ? const SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.5,
                                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            )
                          : Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const FaIcon(FontAwesomeIcons.creditCard, size: 18),
                                const SizedBox(width: 10),
                                Text(
                                  'Confirmer la création',
                                  style: GoogleFonts.inriaSerif(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Center(
                    child: TextButton(
                      onPressed: () => Navigator.of(ctx).pop(),
                      child: Text(
                        'Annuler',
                        style: GoogleFonts.inriaSerif(
                          fontSize: 14,
                          color: Colors.grey.shade600,
                        ),
                      ),
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

  Future<void> _createCard() async {
    setState(() => _isLoading = true);

    try {
      final loyaltyCard = await LoyaltyService.createCard(shopId: widget.shopId);

      if (!mounted) return;

      await showDialog(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          contentPadding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  color: const Color(0xFF10B981).withOpacity(0.12),
                  shape: BoxShape.circle,
                ),
                child: const FaIcon(
                  FontAwesomeIcons.solidCircleCheck,
                  color: Color(0xFF10B981),
                  size: 36,
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'Carte créée avec succès !',
                style: GoogleFonts.inriaSerif(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF1E293B),
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 10),
              Text(
                'Votre carte de fidélité ${widget.boutiqueName} est prête. Cumulez des points à chaque commande !',
                style: GoogleFonts.inriaSerif(
                  fontSize: 13,
                  color: Colors.grey.shade600,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: () => Navigator.of(ctx).pop(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF10B981),
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    'Voir ma carte',
                    style: GoogleFonts.inriaSerif(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      );

      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (context) => LoyaltyCardPage(loyaltyCard: loyaltyCard),
        ),
      );
    } catch (e) {
      if (!mounted) return;

      final errorMessage = e.toString().replaceAll('Exception: ', '');

      // Si la carte existe deja, essayer de la recuperer
      if (errorMessage.contains('existe') || errorMessage.contains('already')) {
        try {
          final existingCard = await LoyaltyService.getCardForShop(widget.shopId);
          if (existingCard != null && mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: const Text('Carte existante trouvee'),
                backgroundColor: const Color(0xFFF59E0B),
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
            );
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(
                builder: (context) => LoyaltyCardPage(loyaltyCard: existingCard),
              ),
            );
            return;
          }
        } catch (_) {}
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const FaIcon(FontAwesomeIcons.circleExclamation, color: Colors.white, size: 20),
              const SizedBox(width: 12),
              Expanded(child: Text(errorMessage)),
            ],
          ),
          backgroundColor: const Color(0xFFEF4444),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          duration: const Duration(seconds: 4),
        ),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentShop = widget.shop ?? _loadedShop;
    final shopTheme = currentShop?.theme ?? ShopTheme.defaultTheme();
    final primaryColor = shopTheme.primary;

    if (_isCheckingExisting) {
      return Scaffold(
        backgroundColor: const Color(0xFFF8FAFC),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 1,
        leading: IconButton(
          icon: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(10),
            ),
            child: FaIcon(FontAwesomeIcons.arrowLeft, size: 18, color: Colors.grey.shade700),
          ),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Column(
          children: [
            Text(
              'Carte de fidelite',
              style: GoogleFonts.inriaSerif(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF1E293B),
              ),
            ),
            Text(
              widget.boutiqueName,
              style: GoogleFonts.inriaSerif(
                fontSize: 13,
                color: Colors.grey.shade800,
              ),
            ),
          ],
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Header card
            Container(
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF1E293B), Color(0xFF334155)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF1E293B).withOpacity(0.3),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: primaryColor.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: FaIcon(
                          FontAwesomeIcons.idCard,
                          color: primaryColor,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Programme Fidelite',
                              style: GoogleFonts.inriaSerif(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Rejoignez-nous et profitez d\'avantages exclusifs',
                              style: GoogleFonts.inriaSerif(
                                fontSize: 13,
                                color: Colors.white.withOpacity(0.7),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _buildBadge('Points cumules', FontAwesomeIcons.solidStar),
                      _buildBadge('Reductions', FontAwesomeIcons.percent),
                      _buildBadge('Offres VIP', Icons.diamond_rounded),
                    ],
                  ),
                ],
              ),
            ),

            // Avantages
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey.shade200),
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
                          color: primaryColor,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        'Vos avantages',
                        style: GoogleFonts.inriaSerif(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF1E293B),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _buildAdvantageItem(
                    FontAwesomeIcons.solidStar,
                    'Cumulez des points',
                    'Gagnez des points a chaque commande',
                    const Color(0xFFFF9800),
                  ),
                  const SizedBox(height: 12),
                  _buildAdvantageItem(
                    FontAwesomeIcons.gift,
                    'Debloquez des recompenses',
                    'Livraison gratuite, reductions, produits offerts',
                    const Color(0xFF4CAF50),
                  ),
                  const SizedBox(height: 12),
                  _buildAdvantageItem(
                    FontAwesomeIcons.arrowTrendUp,
                    'Montez de niveau',
                    'Bronze, Argent, Or, Platine',
                    const Color(0xFF2196F3),
                  ),
                  const SizedBox(height: 12),
                  _buildAdvantageItem(
                    FontAwesomeIcons.qrcode,
                    'QR Code personnel',
                    'Scannez en boutique pour cumuler vos points',
                    const Color(0xFF9C27B0),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Info PIN
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFF0F9FF),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFF2196F3).withOpacity(0.2)),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF2196F3).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const FaIcon(FontAwesomeIcons.circleInfo, color: Color(0xFF2196F3), size: 20),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Code PIN automatique',
                          style: GoogleFonts.inriaSerif(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF1E40AF),
                          ),
                        ),
                        Text(
                          'Votre PIN sera les 4 derniers chiffres du numéro de téléphone de votre compte',
                          style: GoogleFonts.inriaSerif(
                            fontSize: 13,
                            color: const Color(0xFF1E40AF).withOpacity(0.8),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Bouton creer
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _showCreationForm,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryColor,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const FaIcon(FontAwesomeIcons.creditCard, size: 20),
                            const SizedBox(width: 10),
                            Text(
                              'Creer ma carte',
                              style: GoogleFonts.inriaSerif(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                ),
              ),
            ),
            const SizedBox(height: 12),

            // Retour boutique
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: TextButton(
                onPressed: () {
                  final shop = widget.shop ?? _loadedShop;
                  Navigator.of(context).pushReplacement(
                    MaterialPageRoute(
                      builder: (context) => HomeScreen(
                        shop: shop,
                        shopId: widget.shopId,
                      ),
                    ),
                  );
                },
                style: TextButton.styleFrom(foregroundColor: Colors.grey.shade800),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    FaIcon(FontAwesomeIcons.store, size: 18, color: Colors.grey.shade500),
                    const SizedBox(width: 8),
                    Text(
                      'Retour a la boutique',
                      style: GoogleFonts.inriaSerif(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: Colors.grey.shade800,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Confiance
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFF0FDF4),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFF10B981).withOpacity(0.2)),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF10B981).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const FaIcon(
                      FontAwesomeIcons.shieldHalved,
                      color: Color(0xFF10B981),
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Vos donnees sont protegees',
                          style: GoogleFonts.inriaSerif(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF166534),
                          ),
                        ),
                        Text(
                          'Nous ne partageons jamais vos informations personnelles',
                          style: GoogleFonts.inriaSerif(
                            fontSize: 13,
                            color: const Color(0xFF166534).withOpacity(0.8),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  Widget _buildBadge(String text, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white.withOpacity(0.9), size: 14),
          const SizedBox(width: 6),
          Text(
            text,
            style: GoogleFonts.inriaSerif(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: Colors.white.withOpacity(0.9),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAdvantageItem(IconData icon, String title, String subtitle, Color color) {
    return Row(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: color, size: 20),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: GoogleFonts.inriaSerif(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF1E293B),
                ),
              ),
              Text(
                subtitle,
                style: GoogleFonts.inriaSerif(
                  fontSize: 13,
                  color: Colors.grey.shade800,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
