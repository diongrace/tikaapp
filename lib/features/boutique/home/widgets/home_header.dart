import 'package:flutter/material.dart';
import '../../notifications/notifications_list_screen.dart';
import '../../../../core/services/boutique_theme_provider.dart';

/// Widget d'en-tête avec image de fond et boutons d'action
/// Gère l'affichage conditionnel de la page de couverture:
/// - Si la boutique a une bannière (bannerUrl), elle est affichée
/// - Si le banner de l'API échoue ou n'existe pas, affiche le banner par défaut (Black Friday)
/// - Si le banner par défaut n'existe pas, affiche un fond de couleur avec le thème de la boutique
class HomeHeader extends StatelessWidget {
  final bool isFavorite;
  final VoidCallback onFavoriteToggle;
  final VoidCallback onBackPressed;
  final String? bannerUrl; // URL de l'image de couverture depuis l'API

  const HomeHeader({
    super.key,
    required this.isFavorite,
    required this.onFavoriteToggle,
    required this.onBackPressed,
    this.bannerUrl,
  });

  // Construire l'URL complète de l'image
  String? _getFullImageUrl(String? url) {
    if (url == null || url.isEmpty) return null;

    // Si l'URL commence déjà par http, la retourner telle quelle
    if (url.startsWith('http://') || url.startsWith('https://')) {
      return url;
    }
// 
    // Sinon, construire l'URL complète avec le domaine de base
    // Nettoyer l'URL (enlever le slash de début si présent)
    final cleanUrl = url.startsWith('/') ? url.substring(1) : url;
    return 'https://tika-ci.com/$cleanUrl';
  }

  @override
  Widget build(BuildContext context) {
    // Obtenir le thème de la boutique pour les couleurs dynamiques
    final shopTheme = BoutiqueThemeProvider.of(context);
    final fullImageUrl = _getFullImageUrl(bannerUrl);
    final hasCoverPage = fullImageUrl != null && fullImageUrl.isNotEmpty;

    // Debug détaillé
    print('');
    print('════════════════════════════════════');
    print('🖼️  HOME HEADER - PAGE DE COUVERTURE');
    print('════════════════════════════════════');
    print('📥 banner_url reçu: $bannerUrl');
    print('📊 Type: ${bannerUrl.runtimeType}');
    print('🔗 URL complète: $fullImageUrl');
    if (hasCoverPage) {
      print('✅ COUVERTURE PERSONNALISÉE trouvée');
      print('   → Chargement: $fullImageUrl');
    } else {
      print('ℹ️  PAS DE COUVERTURE PERSONNALISÉE');
      print('   → Banner par défaut utilisé (Black Friday)');
    }
    print('🎨 Couleur boutique: ${shopTheme.primaryColor}');
    print('════════════════════════════════════');
    print('');

    return Stack(
      children: [
        // Image de couverture (banner) - Sans padding et sans border radius
        Container(
          height: 200,
          width: double.infinity,
          child: Stack(
            children: [
              // Afficher uniquement le banner de l'API ou un fond de couleur
              if (hasCoverPage)
                // Si la boutique a une page de couverture, l'afficher
                Image.network(
                  fullImageUrl,
                  fit: BoxFit.cover,
                  alignment: Alignment.center,
                  width: double.infinity,
                  height: double.infinity,
                  errorBuilder: (context, error, stackTrace) {
                    print('❌ Erreur chargement banner depuis API: $error');
                    print('   → Affichage banner par défaut (Black Friday)');
                    // En cas d'erreur, afficher le banner par défaut (Black Friday)
                    return Image.asset(
                      'lib/core/assets/couvre.jpeg',
                      fit: BoxFit.cover,
                      alignment: Alignment.center,
                      width: double.infinity,
                      height: double.infinity,
                      errorBuilder: (context, error, stackTrace) {
                        // Si le banner par défaut n'existe pas, afficher le fond de couleur
                        print('⚠️ Banner par défaut introuvable, affichage fond de couleur');
                        return Container(
                          width: double.infinity,
                          height: double.infinity,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                shopTheme.primary,
                                shopTheme.secondary,
                              ],
                            ),
                          ),
                        );
                      },
                    );
                  },
                  loadingBuilder: (context, child, loadingProgress) {
                    if (loadingProgress == null) {
                      return child;
                    }
                    // Pendant le chargement, afficher un indicateur avec couleur boutique
                    return Container(
                      color: shopTheme.primaryLight,
                      child: Center(
                        child: CircularProgressIndicator(
                          value: loadingProgress.expectedTotalBytes != null
                              ? loadingProgress.cumulativeBytesLoaded /
                                  loadingProgress.expectedTotalBytes!
                              : null,
                          color: shopTheme.primary,
                          strokeWidth: 3,
                        ),
                      ),
                    );
                  },
                )
              else
                // Si pas de page de couverture, afficher le banner par défaut (Black Friday)
                Builder(
                  builder: (context) {
                    print('📸 Chargement banner par défaut: lib/core/assets/couvre.jpeg');
                    return Image.asset(
                      'lib/core/assets/couvre.jpeg',
                      fit: BoxFit.cover,
                      alignment: Alignment.center,
                      width: double.infinity,
                      height: double.infinity,
                      errorBuilder: (context, error, stackTrace) {
                        // Si le banner par défaut n'existe pas, afficher un fond de couleur avec le thème de la boutique
                        print('⚠️ Banner par défaut introuvable: $error');
                        print('   → Affichage fond de couleur');
                        return Container(
                          width: double.infinity,
                          height: double.infinity,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                shopTheme.primary,
                                shopTheme.secondary,
                              ],
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
            ],
          ),
        ),
        // Boutons d'action
        SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Bouton retour
                _buildCircleButton(
                  icon: Icons.arrow_back,
                  onPressed: onBackPressed,
                ),
                // Boutons favoris et notifications
                Row(
                  children: [
                    _buildCircleButton(
                      icon: isFavorite ? Icons.favorite : Icons.favorite_border,
                      color: isFavorite ? Colors.red : Colors.black87,
                      onPressed: onFavoriteToggle,
                    ),
                    const SizedBox(width: 12),
                    _buildCircleButton(
                      icon: Icons.notifications_outlined,
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const NotificationsListScreen(),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCircleButton({
    required IconData icon,
    required VoidCallback onPressed,
    Color color = Colors.black87,
  }) {
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: IconButton(
        icon: Icon(icon, color: color, size: 22),
        onPressed: onPressed,
        padding: EdgeInsets.zero,
      ),
    );
  }
}

