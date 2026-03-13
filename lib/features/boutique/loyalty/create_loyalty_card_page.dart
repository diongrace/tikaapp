import 'package:flutter/material.dart';
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
              child: const Icon(
                Icons.lock_outline_rounded,
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

  Future<void> _createCard() async {
    setState(() => _isLoading = true);

    try {
      final loyaltyCard = await LoyaltyService.createCard(shopId: widget.shopId);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.check_circle, color: Colors.white, size: 20),
              const SizedBox(width: 12),
              const Text('Carte creee avec succes !'),
            ],
          ),
          backgroundColor: const Color(0xFF10B981),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          duration: const Duration(seconds: 2),
        ),
      );

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
              const Icon(Icons.error_outline, color: Colors.white, size: 20),
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
            child: Icon(Icons.arrow_back_ios_new, size: 18, color: Colors.grey.shade700),
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
                        child: Icon(
                          Icons.card_membership_rounded,
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
                      _buildBadge('Points cumules', Icons.stars_rounded),
                      _buildBadge('Reductions', Icons.percent_rounded),
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
                    Icons.star_rounded,
                    'Cumulez des points',
                    'Gagnez des points a chaque commande',
                    const Color(0xFFFF9800),
                  ),
                  const SizedBox(height: 12),
                  _buildAdvantageItem(
                    Icons.card_giftcard_rounded,
                    'Debloquez des recompenses',
                    'Livraison gratuite, reductions, produits offerts',
                    const Color(0xFF4CAF50),
                  ),
                  const SizedBox(height: 12),
                  _buildAdvantageItem(
                    Icons.trending_up_rounded,
                    'Montez de niveau',
                    'Bronze, Argent, Or, Platine',
                    const Color(0xFF2196F3),
                  ),
                  const SizedBox(height: 12),
                  _buildAdvantageItem(
                    Icons.qr_code_rounded,
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
                    child: const Icon(Icons.info_outline, color: Color(0xFF2196F3), size: 20),
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
                  onPressed: _isLoading ? null : _createCard,
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
                            const Icon(Icons.add_card_rounded, size: 20),
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
                    Icon(Icons.storefront_outlined, size: 18, color: Colors.grey.shade500),
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
                    child: const Icon(
                      Icons.verified_user_outlined,
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
