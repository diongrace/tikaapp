import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import '../boutique/favorites/favorites_boutiques_screen.dart';
import '../qr_scanner/qr_scanner_screen.dart';
import '../../services/shop_service.dart';
import '../../services/models/shop_model.dart';
import '../boutique/home/home_online_screen.dart';
import '../../services/auth_service.dart';
import '../../services/loyalty_service.dart';
import '../../services/models/loyalty_card_model.dart';
import '../auth/auth_choice_screen.dart';
import '../dashboard/dashboard_screen.dart';
import '../boutique/loyalty/loyalty_card_page.dart';
import '../boutique/loyalty/loyalty_card_list_item.dart';
import '../../core/services/boutique_theme_provider.dart';

class AccessBoutiqueScreen extends StatefulWidget {
  const AccessBoutiqueScreen({super.key});

  @override
  State<AccessBoutiqueScreen> createState() => _AccessBoutiqueScreenState();
}

class _AccessBoutiqueScreenState extends State<AccessBoutiqueScreen> {
  final TextEditingController _linkController = TextEditingController();
  bool _isLoading = false;
  bool _hasText = false;

  @override
  void initState() {
    super.initState();
    _linkController.addListener(() {
      setState(() => _hasText = _linkController.text.isNotEmpty);
    });
  }

  @override
  void dispose() {
    _linkController.dispose();
    super.dispose();
  }

  Future<void> _openLink(String url) async {
    if (url.isEmpty) return;

    setState(() => _isLoading = true);

    try {
      // Récupérer la boutique via l'API
      final Shop shop = await ShopService.getShopByLink(url);

      if (mounted) {
        _linkController.clear();
        // Naviguer vers l'écran d'accueil de la boutique avec les données
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => HomeScreen(shop: shop),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: ${e.toString()}')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showCreateCardDialog() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: const Color(0xFFFF9800).withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              alignment: Alignment.center,
              child: const FaIcon(FontAwesomeIcons.gift, color: Color(0xFFFF9800), size: 30),
            ),
            const SizedBox(height: 16),
            Text(
              'Carte de fidelite',
              style: GoogleFonts.inriaSerif(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Vous n\'avez pas encore de carte.\nScannez ou entrez le lien d\'une boutique, puis creez votre carte depuis la page de la boutique.',
              textAlign: TextAlign.center,
              style: GoogleFonts.inriaSerif(
                fontSize: 14,
                color: Colors.grey.shade800,
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.pop(ctx);
                },
                icon: const FaIcon(FontAwesomeIcons.qrcode, size: 18),
                label: Text(
                  'Scanner une boutique',
                  style: GoogleFonts.inriaSerif(fontWeight: FontWeight.w600),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF8936A8),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }

  Future<void> _openLoyaltyCard() async {
    if (!AuthService.isAuthenticated) {
      // Non connecte: proposer la connexion
      final result = await Navigator.push<bool>(
        context,
        MaterialPageRoute(
          builder: (context) => const AuthChoiceScreen(),
        ),
      );
      if (result == true && mounted) setState(() {});
      return;
    }

    // Charger les cartes depuis l'API
    try {
      await AuthService.ensureToken();
      final cards = await LoyaltyService.getMyCards();

      if (!mounted) return;

      if (cards.isEmpty) {
        // Aucune carte: ouvrir le formulaire de creation
        _showCreateCardDialog();
        return;
      } else if (cards.length == 1) {
        final card = cards.first;
        final deleted = await Navigator.push<bool>(
          context,
          MaterialPageRoute(
            builder: (context) => LoyaltyCardPage(loyaltyCard: card),
          ),
        );
        if (deleted == true && mounted) {
          _showCreateCardDialog();
        }
      } else {
        // Plusieurs cartes: bottom sheet pour choisir
        _showLoyaltyCardPicker(cards);
      }
    } catch (e) {
      if (mounted) {
        // Si erreur backend SQL, afficher message generique
        final rawError = e.toString().replaceAll('Exception: ', '');
        final userMessage = rawError.contains('SQLSTATE') || rawError.contains('Column not found')
            ? 'Service temporairement indisponible. Reessayez plus tard.'
            : rawError;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(userMessage),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
      }
    }
  }

  Widget _buildShopLogo(LoyaltyCard card, Color accentColor) {
    final hasLogo = card.shopLogo != null && card.shopLogo!.isNotEmpty;
    final logoUrl = hasLogo
        ? (card.shopLogo!.startsWith('http')
            ? card.shopLogo!
            : 'https://prepro.tika-ci.com/storage/${card.shopLogo!}')
        : null;
    final initial = card.shopName.isNotEmpty ? card.shopName[0].toUpperCase() : '?';

    if (hasLogo) {
      return Container(
        width: 46, height: 46,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade200),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 6)],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(11),
          child: Image.network(logoUrl!, fit: BoxFit.contain,
            errorBuilder: (_, __, ___) => _buildLogoFallback(initial, accentColor)),
        ),
      );
    }
    return _buildLogoFallback(initial, accentColor);
  }

  Widget _buildLogoFallback(String initial, Color color) {
    return Container(
      width: 46, height: 46,
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Center(child: Text(initial, style: GoogleFonts.inriaSerif(
        fontSize: 18, fontWeight: FontWeight.bold, color: color))),
    );
  }

  void _showLoyaltyCardPicker(List<LoyaltyCard> cards) {
    const accentColors = [
      Color(0xFF8936A8),
      Color(0xFF1A73E8),
      Color(0xFF00897B),
      Color(0xFFF57C00),
      Color(0xFFE91E63),
      Color(0xFF0288D1),
    ];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.55,
        minChildSize: 0.4,
        maxChildSize: 0.9,
        builder: (_, scrollCtrl) => Container(
          decoration: const BoxDecoration(
            color: Color(0xFFF8F8FB),
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(children: [
            // Handle
            Container(
              width: 40, height: 4,
              margin: const EdgeInsets.only(top: 12, bottom: 16),
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2)),
            ),
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 14),
              child: Row(children: [
                Container(
                  width: 38, height: 38,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF8936A8), Color(0xFFD44CDA)]),
                    borderRadius: BorderRadius.circular(11),
                  ),
                  child: const FaIcon(FontAwesomeIcons.award, color: Colors.white, size: 16),
                ),
                const SizedBox(width: 12),
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('Mes cartes de fidélité', style: GoogleFonts.inriaSerif(
                    fontSize: 16, fontWeight: FontWeight.bold, color: const Color(0xFF1C1C1E))),
                  Text('${cards.length} carte${cards.length > 1 ? 's' : ''}',
                    style: GoogleFonts.inriaSerif(fontSize: 12, color: Colors.grey.shade500)),
                ]),
              ]),
            ),
            // Liste
            Expanded(
              child: ListView.separated(
                controller: scrollCtrl,
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                itemCount: cards.length,
                separatorBuilder: (_, __) => const SizedBox(height: 10),
                itemBuilder: (_, index) {
                  final card = cards[index];
                  return LoyaltyCardListItem(
                    card: card,
                    index: index,
                    onTap: () async {
                      Navigator.pop(ctx);
                      final deleted = await Navigator.push<bool>(
                        context,
                        MaterialPageRoute(
                          builder: (context) => BoutiqueThemeProvider(
                            shop: null,
                            child: LoyaltyCardPage(loyaltyCard: card),
                          ),
                        ),
                      );
                      if (deleted == true && mounted) _showCreateCardDialog();
                    },
                  );
                },
              ),
            ),
          ]),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final keyboardOpen = MediaQuery.of(context).viewInsets.bottom > 0;

    return Scaffold(
      resizeToAvoidBottomInset: false,
      body: SafeArea(
        child: Stack(
          children: [
            // Image de fond
            Positioned.fill(
              child: Image.asset(
                'lib/core/assets/imgbt.jpeg',
                fit: BoxFit.cover,
              ),
            ),

            // Overlay semi-transparent
            Positioned.fill(
              child: Container(color: Colors.white.withOpacity(0.10)),
            ),

            // Logo Tika — caché quand le clavier est ouvert
            if (!keyboardOpen)
              Positioned(
                top: 40,
                left: 0,
                right: 0,
                child: Center(
                  child: Image.asset(
                    'lib/core/assets/logo.png',
                    width: 80,
                    height: 80,
                  ),
                ),
              ),

            // Contenu principal
            Align(
              alignment: keyboardOpen ? Alignment.center : Alignment.bottomCenter,
              child: Padding(
                padding: EdgeInsets.only(
                  bottom: keyboardOpen ? 0 : 120.0,
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Bouton Scanner QR
                      GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const QrScannerScreen(),
                            ),
                          );
                        },
                        child: Container(
                          height: 50,
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFF8936A8), Color(0xFFB932D6)],
                              begin: Alignment.centerLeft,
                              end: Alignment.centerRight,
                            ),
                            borderRadius: BorderRadius.circular(100),
                            boxShadow: [
                              BoxShadow(
                                color: Color(0xFF8936A8).withOpacity(0.3),
                                blurRadius: 12,
                                offset: const Offset(0, 6),
                              ),
                            ],
                          ),
                          child: Center(
                            child: Text(
                              'Scanner Un Qr Code',
                              style: GoogleFonts.inriaSerif(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        '-ou-',
                        style: GoogleFonts.inriaSerif(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: Colors.grey[800],
                        ),
                      ),
                      const SizedBox(height: 12),
                      // Champ de saisie du lien boutique
                      Row(
                        children: [
                          Expanded(
                            child: Container(
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(100),
                                border: Border.all(
                                  color: Colors.grey[300]!,
                                  width: 1.5,
                                ),
                              ),
                              child: TextField(
                                controller: _linkController,
                                onSubmitted: (value) {
                                  if (value.isNotEmpty) _openLink(value);
                                },
                                decoration: InputDecoration(
                                  hintText: 'Entrez le lien de la boutique',
                                  hintStyle: GoogleFonts.inriaSerif(
                                    fontSize: 14,
                                    color: Colors.grey[900],
                                  ),
                                  prefixIcon: Align(
                                    alignment: Alignment.center,
                                    widthFactor: 1.0,
                                    child: const Padding(
                                      padding: EdgeInsets.symmetric(horizontal: 14),
                                      child: FaIcon(
                                        FontAwesomeIcons.link,
                                        color: Color(0xFF8936A8),
                                        size: 18,
                                      ),
                                    ),
                                  ),
                                  prefixIconConstraints: const BoxConstraints(minWidth: 46, minHeight: 46),
                                  border: InputBorder.none,
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 18,
                                    vertical: 12,
                                  ),
                                ),
                                style: GoogleFonts.inriaSerif(
                                  fontSize: 14,
                                  color: Colors.black87,
                                ),
                              ),
                            ),
                          ),
                          if (_hasText) ...[
                            const SizedBox(width: 10),
                            GestureDetector(
                              onTap: () => _openLink(_linkController.text),
                              child: Container(
                                height: 48,
                                padding: const EdgeInsets.symmetric(horizontal: 20),
                                decoration: BoxDecoration(
                                  gradient: const LinearGradient(
                                    colors: [Color(0xFF8936A8), Color(0xFFB932D6)],
                                  ),
                                  borderRadius: BorderRadius.circular(100),
                                  boxShadow: [
                                    BoxShadow(
                                      color: const Color(0xFF8936A8).withOpacity(0.3),
                                      blurRadius: 8,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                                ),
                                child: Center(
                                  child: Text(
                                    'Go',
                                    style: GoogleFonts.inriaSerif(
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      if (_isLoading) ...[
                        const SizedBox(height: 16),
                        const CircularProgressIndicator(),
                      ],
                    ],
                  ),
                ),
              ),
            ),

            // Icônes en bas à droite
            Positioned(
              bottom: 20,
              right: 20,
              child: Row(
                children: [
                  // Compte / Profil
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: AuthService.isAuthenticated
                          ? const Color(0xFF4CAF50) // Vert si connecté
                          : const Color(0xFF8936A8), // Violet sinon
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: (AuthService.isAuthenticated
                                  ? const Color(0xFF4CAF50)
                                  : const Color(0xFF8936A8))
                              .withOpacity(0.25),
                          blurRadius: 6,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    alignment: Alignment.center,
                    child: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      child: const FaIcon(FontAwesomeIcons.user, color: Colors.white, size: 16),
                      onTap: () async {
                        if (AuthService.isAuthenticated) {
                          await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const DashboardScreen(),
                            ),
                          );
                          if (mounted) setState(() {});
                        } else {
                          final result = await Navigator.push<bool>(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const AuthChoiceScreen(),
                            ),
                          );
                          if (result == true && mounted) setState(() {});
                        }
                      },
                    ),
                  ),

                  const SizedBox(width: 10),

                  // Favoris
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: const Color(0xFF8936A8),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Color(0xFF8936A8).withOpacity(0.25),
                          blurRadius: 6,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    alignment: Alignment.center,
                    child: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      child: const FaIcon(FontAwesomeIcons.solidHeart, color: Colors.white, size: 16),
                      onTap: () => Navigator.push(context,
                        MaterialPageRoute(builder: (context) => const FavoritesBoutiquesScreen(showBottomNav: false))),
                    ),
                  ),

                  const SizedBox(width: 10),

                  // Carte de fidelite
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: const Color(0xFF8936A8),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF8936A8).withOpacity(0.25),
                          blurRadius: 6,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    alignment: Alignment.center,
                    child: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      child: const FaIcon(FontAwesomeIcons.idCard, color: Colors.white, size: 16),
                      onTap: () => _openLoyaltyCard(),
                    ),
                  ),

                  const SizedBox(width: 10),

                  // Historique
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: const Color(0xFF8936A8),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: const Color.fromARGB(255, 222, 218, 224).withOpacity(0.25),
                          blurRadius: 6,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    alignment: Alignment.center,
                    child: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      child: const FaIcon(FontAwesomeIcons.clockRotateLeft, color: Colors.white, size: 16),
                      onTap: () => Navigator.pushNamed(context, '/history'),
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