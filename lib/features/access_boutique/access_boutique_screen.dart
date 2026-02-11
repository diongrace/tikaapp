import 'package:flutter/material.dart';
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
import '../boutique/loyalty/create_loyalty_card_page.dart';

class AccessBoutiqueScreen extends StatefulWidget {
  const AccessBoutiqueScreen({super.key});

  @override
  State<AccessBoutiqueScreen> createState() => _AccessBoutiqueScreenState();
}

class _AccessBoutiqueScreenState extends State<AccessBoutiqueScreen> {
  final TextEditingController _linkController = TextEditingController();
  bool _isLoading = false;

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
              child: const Icon(Icons.card_giftcard, color: Color(0xFFFF9800), size: 30),
            ),
            const SizedBox(height: 16),
            Text(
              'Carte de fidelite',
              style: GoogleFonts.openSans(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Vous n\'avez pas encore de carte.\nScannez ou entrez le lien d\'une boutique, puis creez votre carte depuis la page de la boutique.',
              textAlign: TextAlign.center,
              style: GoogleFonts.openSans(
                fontSize: 14,
                color: Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.pop(ctx);
                },
                icon: const Icon(Icons.qr_code_scanner, size: 18),
                label: Text(
                  'Scanner une boutique',
                  style: GoogleFonts.openSans(fontWeight: FontWeight.w600),
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
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => LoyaltyCardPage(loyaltyCard: cards.first),
          ),
        );
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

  void _showLoyaltyCardPicker(List<LoyaltyCard> cards) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Mes cartes de fidelite',
              style: GoogleFonts.openSans(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            ...cards.map((card) => ListTile(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  tileColor: const Color(0xFFF5F5F5),
                  leading: Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: const Color(0xFF8936A8).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.card_giftcard, color: Color(0xFF8936A8), size: 22),
                  ),
                  title: Text(
                    card.shopName,
                    style: GoogleFonts.openSans(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  subtitle: Text(
                    '${card.points} points',
                    style: GoogleFonts.openSans(fontSize: 12, color: Colors.grey),
                  ),
                  trailing: const Icon(Icons.chevron_right, color: Colors.grey),
                  onTap: () {
                    Navigator.pop(ctx);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => LoyaltyCardPage(loyaltyCard: card),
                      ),
                    );
                  },
                )),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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

            // Logo Tika
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
              alignment: Alignment.bottomCenter,
              child: Padding(
                padding: const EdgeInsets.only(bottom: 120.0),
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
                              style: GoogleFonts.openSans(
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
                        style: GoogleFonts.openSans(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: Colors.grey[500],
                        ),
                      ),
                      const SizedBox(height: 12),
                      // Champ de saisie du lien boutique
                      Container(
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
                            if (value.isNotEmpty) {
                              _openLink(value);
                            }
                          },
                          decoration: InputDecoration(
                            hintText: 'Entrez le lien de la boutique',
                            hintStyle: GoogleFonts.openSans(
                              fontSize: 13,
                              color: Colors.grey[400],
                            ),
                            prefixIcon: const Icon(
                              Icons.link,
                              color: Color(0xFF8936A8),
                              size: 18,
                            ),
                            border: InputBorder.none,
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 18,
                              vertical: 12,
                            ),
                          ),
                          style: GoogleFonts.openSans(
                            fontSize: 13,
                            color: Colors.black87,
                          ),
                        ),
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
                    child: IconButton(
                      icon: Icon(
                        AuthService.isAuthenticated ? Icons.person : Icons.person_outline,
                        color: Colors.white,
                        size: 18,
                      ),
                      padding: EdgeInsets.zero,
                      onPressed: () async {
                        if (AuthService.isAuthenticated) {
                          // Si connecté, aller au dashboard
                          await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const DashboardScreen(),
                            ),
                          );
                          // Rafraîchir l'état après retour du profil
                          if (mounted) setState(() {});
                        } else {
                          // Si non connecté, afficher le choix d'authentification
                          final result = await Navigator.push<bool>(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const AuthChoiceScreen(),
                            ),
                          );
                          // Rafraîchir l'état si l'utilisateur s'est connecté
                          if (result == true && mounted) {
                            setState(() {});
                          }
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
                    child: IconButton(
                      icon: const Icon(Icons.favorite, color: Colors.white, size: 18),
                      padding: EdgeInsets.zero,
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const FavoritesBoutiquesScreen(),
                          ),
                        );
                      },
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
                    child: IconButton(
                      icon: const Icon(Icons.card_giftcard, color: Colors.white, size: 18),
                      padding: EdgeInsets.zero,
                      onPressed: () => _openLoyaltyCard(),
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
                    child: IconButton(
                      icon: const Icon(Icons.history, color: Colors.white, size: 18),
                      padding: EdgeInsets.zero,
                      onPressed: () {
                        Navigator.pushNamed(context, '/history');
                      },
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
