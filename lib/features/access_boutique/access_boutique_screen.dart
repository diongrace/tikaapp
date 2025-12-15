import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../boutique/favorites/favorites_boutiques_screen.dart';
import '../qr_scanner/qr_scanner_screen.dart';
import '../../services/shop_service.dart';
import '../../services/models/shop_model.dart';
import '../boutique/home/home_online_screen.dart';

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
