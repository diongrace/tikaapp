import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../services/favorites_service.dart';
import '../../../services/auth_service.dart';
import '../../../services/models/shop_model.dart';
import '../../../services/utils/api_endpoint.dart';
import '../home/home_online_screen.dart';
import '../home/components/home_bottom_navigation.dart';
import '../loading_screens/loading_screens.dart';
import '../../auth/auth_choice_screen.dart';

/// Écran des boutiques favorites
/// Affiche la liste des boutiques mises en favoris par l'utilisateur
/// UTILISE LA LOGIQUE EXACTE DE L'API TIKA
class FavoritesBoutiquesScreen extends StatefulWidget {
  /// [showBottomNav] : true quand ouvert depuis la nav d'une boutique,
  /// false quand ouvert directement depuis AccessBoutiqueScreen
  final bool showBottomNav;

  const FavoritesBoutiquesScreen({super.key, this.showBottomNav = true});

  @override
  State<FavoritesBoutiquesScreen> createState() => _FavoritesBoutiquesScreenState();
}

class _FavoritesBoutiquesScreenState extends State<FavoritesBoutiquesScreen> {
  // Liste des boutiques favorites chargées depuis l'API
  List<Shop> _favoriteBoutiques = [];
  bool _isLoading = true;
  bool _hasError = false;
  bool _isNotAuthenticated = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadFavorites();
  }

  /// Charger les favoris depuis l'API
  /// GET /client/favorites (Bearer Token)
  Future<void> _loadFavorites() async {
    if (!mounted) return;

    setState(() {
      _isLoading = true;
      _hasError = false;
      _isNotAuthenticated = false;
      _errorMessage = null;
    });

    try {
      print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
      print('🔄 CHARGEMENT DES FAVORIS');
      print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');

      // Appel API via le service
      final favorites = await FavoritesService.getFavorites();

      if (!mounted) return;

      setState(() {
        _favoriteBoutiques = favorites;
        _isLoading = false;
      });

      print('✅ ${favorites.length} favoris chargés dans l\'UI');
      print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    } catch (e) {
      if (!mounted) return;

      print('❌ Erreur chargement favoris: $e');

      final isAuthError = e.toString().contains('Authentification') ||
          e.toString().contains('401');

      setState(() {
        _isLoading = false;
        _isNotAuthenticated = isAuthError;
        _hasError = !isAuthError;
        _errorMessage = isAuthError ? null : e.toString();
      });
    }
  }

  /// Retirer une boutique des favoris
  /// DELETE /client/favorites/{shopId} (Bearer Token)
  Future<void> _removeFavorite(Shop shop) async {
    if (!mounted) return;

    try {
      print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
      print('🗑️ RETRAIT DU FAVORI: ${shop.name}');
      print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');

      // Optimistic update: retirer immédiatement de l'UI
      setState(() {
        _favoriteBoutiques.removeWhere((b) => b.id == shop.id);
      });

      // Appeler l'API pour retirer le favori
      final result = await FavoritesService.removeFavorite(shop.id);

      if (!mounted) return;

      // Afficher le message de succès
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            result['message'] ?? 'Boutique retirée des favoris',
            style: GoogleFonts.openSans(),
          ),
          backgroundColor: const Color(0xFF8936A8),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          duration: const Duration(seconds: 2),
        ),
      );

      print('✅ Favori retiré avec succès');
      print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    } catch (e) {
      if (!mounted) return;

      print('❌ Erreur lors du retrait: $e');

      // Rollback: remettre la boutique dans la liste
      setState(() {
        if (!_favoriteBoutiques.any((b) => b.id == shop.id)) {
          _favoriteBoutiques.add(shop);
        }
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString().contains('401')
              ? 'Session expirée, reconnectez-vous'
              : 'Impossible de retirer ce favori'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    }
  }

  /// Ouvrir la page de la boutique
  void _openBoutique(Shop shop) async {
    print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    print('🏪 OUVERTURE DE LA BOUTIQUE: ${shop.name}');
    print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');

    // Naviguer vers la boutique
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => HomeScreen(
          shopId: shop.id,
          shop: shop,
        ),
      ),
    );

    // Recharger les favoris quand l'utilisateur revient
    // (au cas où il aurait retiré la boutique des favoris)
    if (mounted) {
      print('🔄 Retour à l\'écran favoris - Rechargement...');
      _loadFavorites();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F8F8),
      bottomNavigationBar: widget.showBottomNav
          ? const HomeBottomNavigation(
              selectedIndex: 3,
              currentShop: null,
            )
          : null,
      body: Stack(
        children: [
          // Fond avec gradient subtil
          Container(
            height: 220,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  const Color(0xFF8936A8),
                  const Color(0xFF9C4AB8),
                ],
              ),
            ),
          ),
          // Contenu
          SafeArea(
            child: Column(
              children: [
                // Header personnalisé
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Row(
                    children: [
                      // Bouton retour
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.25),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: Colors.white.withOpacity(0.3),
                            width: 1.5,
                          ),
                        ),
                        child: IconButton(
                          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 20),
                          padding: EdgeInsets.zero,
                          onPressed: () => Navigator.pop(context),
                        ),
                      ),
                      const SizedBox(width: 16),
                      // Titre
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Mes Boutiques',
                              style: GoogleFonts.poppins(
                                fontSize: 26,
                                fontWeight: FontWeight.w800,
                                color: Colors.white,
                                height: 1,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.25),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(Icons.favorite, color: Colors.white, size: 14),
                                      const SizedBox(width: 6),
                                      Text(
                                        '${_favoriteBoutiques.length} ${_favoriteBoutiques.length > 1 ? 'favoris' : 'favori'}',
                                        style: GoogleFonts.openSans(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w600,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                // Liste des boutiques
                Expanded(
                  child: _isLoading
                      ? const FavoritesLoadingScreen()
                      : _isNotAuthenticated
                          ? _buildNotAuthenticatedState()
                          : _hasError
                          ? _buildErrorState()
                          : _favoriteBoutiques.isEmpty
                              ? _buildEmptyState()
                              : RefreshIndicator(
                                  onRefresh: _loadFavorites,
                                  color: const Color(0xFF8936A8),
                                  child: GridView.builder(
                                    padding: const EdgeInsets.all(16),
                                    physics: const BouncingScrollPhysics(),
                                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                                      crossAxisCount: 2,
                                      childAspectRatio: 0.75,
                                      crossAxisSpacing: 12,
                                      mainAxisSpacing: 12,
                                    ),
                                    itemCount: _favoriteBoutiques.length,
                                    itemBuilder: (context, index) {
                                      return _buildBoutiqueCard(_favoriteBoutiques[index]);
                                    },
                                  ),
                                ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// État non connecté
  Widget _buildNotAuthenticatedState() {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: const Color(0xFF8936A8).withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.lock_outline_rounded,
                size: 60,
                color: Color(0xFF8936A8),
              ),
            ),
            const SizedBox(height: 28),
            Text(
              'Connexion requise',
              style: GoogleFonts.poppins(
                fontSize: 22,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF2D2D2D),
              ),
            ),
            const SizedBox(height: 10),
            Text(
              'Connectez-vous pour accéder\nà vos boutiques favorites',
              textAlign: TextAlign.center,
              style: GoogleFonts.openSans(
                fontSize: 14,
                color: Colors.grey[600],
                height: 1.5,
              ),
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: () async {
                await Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => const AuthChoiceScreen(),
                  ),
                );
                if (mounted && AuthService.isAuthenticated) {
                  _loadFavorites();
                }
              },
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 16),
                backgroundColor: const Color(0xFF8936A8),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                elevation: 0,
              ),
              child: Text(
                'Se connecter',
                style: GoogleFonts.poppins(
                  fontSize: 15,
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

  /// État d'erreur
  Widget _buildErrorState() {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 140,
              height: 140,
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.cloud_off_rounded,
                size: 70,
                color: Colors.redAccent,
              ),
            ),
            const SizedBox(height: 28),
            Text(
              'Oups !',
              style: GoogleFonts.poppins(
                fontSize: 24,
                fontWeight: FontWeight.w800,
                color: const Color(0xFF2D2D2D),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Impossible de charger vos favoris',
              textAlign: TextAlign.center,
              style: GoogleFonts.openSans(
                fontSize: 15,
                color: Colors.grey[600],
              ),
            ),
            if (_errorMessage != null) ...[
              const SizedBox(height: 12),
              Text(
                _errorMessage!,
                textAlign: TextAlign.center,
                style: GoogleFonts.openSans(
                  fontSize: 12,
                  color: Colors.grey[500],
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: _loadFavorites,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                backgroundColor: const Color(0xFF8936A8),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                elevation: 2,
                shadowColor: Colors.black.withOpacity(0.2),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.refresh, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    'Réessayer',
                    style: GoogleFonts.poppins(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
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

  /// État vide
  Widget _buildEmptyState() {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 160,
              height: 160,
              decoration: BoxDecoration(
                color: const Color(0xFF8936A8).withOpacity(0.08),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.favorite_border_rounded,
                size: 80,
                color: const Color(0xFF8936A8).withOpacity(0.5),
              ),
            ),
            const SizedBox(height: 32),
            Text(
              'Aucun favori pour le moment',
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                fontSize: 22,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF2D2D2D),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Découvrez et ajoutez vos boutiques préférées',
              textAlign: TextAlign.center,
              style: GoogleFonts.openSans(
                fontSize: 15,
                color: Colors.grey[600],
                height: 1.5,
              ),
            ),
            const SizedBox(height: 36),
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 36, vertical: 18),
                backgroundColor: const Color.fromARGB(255, 242, 237, 244),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                elevation: 2,
                shadowColor: Colors.black.withOpacity(0.2),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.explore_rounded, size: 22),
                  const SizedBox(width: 10),
                  Flexible(
                    child: Text(
                      'Explorer les boutiques',
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
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

  /// Carte d'une boutique favorite
  Widget _buildBoutiqueCard(Shop shop) {
    // Construire l'URL complète du logo
    String logoUrl = shop.logoUrl;
    if (!logoUrl.startsWith('http')) {
      logoUrl = logoUrl.startsWith('/')
          ? '${Endpoints.storageBaseUrl}$logoUrl'
          : '${Endpoints.storageBaseUrl}/$logoUrl';
    }

    return GestureDetector(
      onTap: () => _openBoutique(shop),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image de la boutique
            Expanded(
              child: Stack(
                children: [
                  // Background clean
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.grey.shade50,
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                    ),
                    child: Center(
                      child: Container(
                        width: 85,
                        height: 85,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 15,
                              spreadRadius: 2,
                            ),
                          ],
                        ),
                        child: ClipOval(
                          child: Image.network(
                            logoUrl,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return Icon(
                                Icons.storefront_rounded,
                                size: 45,
                                color: const Color(0xFF8936A8).withOpacity(0.5),
                              );
                            },
                          ),
                        ),
                      ),
                    ),
                  ),
                  // Badge favori
                  Positioned(
                    top: 10,
                    right: 10,
                    child: GestureDetector(
                      onTap: () => _removeFavorite(shop),
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.favorite,
                          size: 18,
                          color: Color(0xFFE91E63),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // Informations
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    shop.name,
                    style: GoogleFonts.poppins(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF2D2D2D),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: const Color(0xFF8936A8).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: const Color(0xFF8936A8).withOpacity(0.3),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.category, size: 12, color: Color(0xFF8936A8)),
                        const SizedBox(width: 5),
                        Flexible(
                          child: Text(
                            shop.category,
                            style: GoogleFonts.openSans(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFF8936A8),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
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
