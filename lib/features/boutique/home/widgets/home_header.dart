import 'dart:async';
import 'package:flutter/material.dart';
import '../../notifications/notifications_list_screen.dart';
import '../../../../core/services/boutique_theme_provider.dart';
import '../../../../core/utils/responsive.dart';
import '../../../../services/utils/api_endpoint.dart';
import '../../../../services/push_notification_service.dart';

/// Widget d'en-tête avec image de fond et boutons d'action
/// Gère l'affichage conditionnel de la page de couverture:
/// - Si la boutique a une bannière (bannerUrl), elle est affichée
/// - Si le banner de l'API échoue ou n'existe pas, affiche le banner par défaut (Black Friday)
/// - Si le banner par défaut n'existe pas, affiche un fond de couleur avec le thème de la boutique
class HomeHeader extends StatefulWidget {
  final bool isFavorite;
  final VoidCallback onFavoriteToggle;
  final VoidCallback onBackPressed;
  final VoidCallback? onHomeTap;
  final String? bannerUrl; // URL de l'image de couverture depuis l'API

  const HomeHeader({
    super.key,
    required this.isFavorite,
    required this.onFavoriteToggle,
    required this.onBackPressed,
    this.onHomeTap,
    this.bannerUrl,
  });

  @override
  State<HomeHeader> createState() => _HomeHeaderState();
}

class _HomeHeaderState extends State<HomeHeader> with SingleTickerProviderStateMixin {
  late AnimationController _bellController;
  late Animation<double> _shakeAnimation;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _bellController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _shakeAnimation = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0, end: 0.15), weight: 1),
      TweenSequenceItem(tween: Tween(begin: 0.15, end: -0.15), weight: 1),
      TweenSequenceItem(tween: Tween(begin: -0.15, end: 0.1), weight: 1),
      TweenSequenceItem(tween: Tween(begin: 0.1, end: -0.1), weight: 1),
      TweenSequenceItem(tween: Tween(begin: -0.1, end: 0.05), weight: 1),
      TweenSequenceItem(tween: Tween(begin: 0.05, end: 0), weight: 1),
    ]).animate(CurvedAnimation(parent: _bellController, curve: Curves.easeInOut));
    _pulseAnimation = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.3), weight: 1),
      TweenSequenceItem(tween: Tween(begin: 1.3, end: 1.0), weight: 1),
    ]).animate(CurvedAnimation(parent: _bellController, curve: Curves.easeInOut));

    // Ecouter les changements de compteur pour declencher l'animation
    PushNotificationService.unreadCount.addListener(_onUnreadChanged);
    // Lancer l'animation periodique si deja des non-lues
    if (PushNotificationService.unreadCount.value > 0) {
      _startPeriodicShake();
    }
  }

  Timer? _shakeTimer;

  void _onUnreadChanged() {
    if (PushNotificationService.unreadCount.value > 0) {
      _bellController.forward(from: 0);
      _startPeriodicShake();
    } else {
      _shakeTimer?.cancel();
      _shakeTimer = null;
    }
  }

  void _startPeriodicShake() {
    _shakeTimer?.cancel();
    _bellController.forward(from: 0);
    _shakeTimer = Timer.periodic(const Duration(seconds: 4), (_) {
      if (mounted && PushNotificationService.unreadCount.value > 0) {
        _bellController.forward(from: 0);
      }
    });
  }

  @override
  void dispose() {
    _shakeTimer?.cancel();
    PushNotificationService.unreadCount.removeListener(_onUnreadChanged);
    _bellController.dispose();
    super.dispose();
  }

  // Construire l'URL complète de l'image
  String? _getFullImageUrl(String? url) {
    if (url == null || url.isEmpty) return null;

    // Si l'URL commence déjà par http, la retourner telle quelle
    if (url.startsWith('http://') || url.startsWith('https://')) {
      return url;
    }

    // Sinon, construire l'URL complète avec le domaine de base
    // Nettoyer l'URL (enlever le slash de début si présent)
    final cleanUrl = url.startsWith('/') ? url.substring(1) : url;
    return '${Endpoints.storageBaseUrl}/$cleanUrl';
  }

  @override
  Widget build(BuildContext context) {
    // Obtenir le thème de la boutique pour les couleurs dynamiques
    final shopTheme = BoutiqueThemeProvider.of(context);
    final fullImageUrl = _getFullImageUrl(widget.bannerUrl);
    final hasCoverPage = fullImageUrl != null && fullImageUrl.isNotEmpty;

    // Debug détaillé
    print('');
    print('════════════════════════════════════');
    print('🖼️  HOME HEADER - PAGE DE COUVERTURE');
    print('════════════════════════════════════');
    print('📥 banner_url reçu: ${widget.bannerUrl}');
    print('📊 Type: ${widget.bannerUrl.runtimeType}');
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
            padding: EdgeInsets.fromLTRB(
              Responsive.horizontalPadding(context), 4,
              Responsive.horizontalPadding(context), 8,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Bouton retour + bouton accueil TIKA
                Row(
                  children: [
                    _buildCircleButton(
                      icon: Icons.arrow_back,
                      onPressed: widget.onBackPressed,
                    ),
                    if (widget.onHomeTap != null) ...[
                      const SizedBox(width: 10),
                      _buildCircleButton(
                        icon: Icons.storefront_outlined,
                        onPressed: widget.onHomeTap!,
                      ),
                    ],
                  ],
                ),
                // Boutons favoris et notifications
                Row(
                  children: [
                    _buildCircleButton(
                      icon: widget.isFavorite ? Icons.favorite : Icons.favorite_border,
                      color: widget.isFavorite ? Colors.red : Colors.black87,
                      onPressed: widget.onFavoriteToggle,
                    ),
                    const SizedBox(width: 12),
                    _buildNotificationButton(context),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildNotificationButton(BuildContext context) {
    return ValueListenableBuilder<int>(
      valueListenable: PushNotificationService.unreadCount,
      builder: (context, count, _) {
        return Stack(
          clipBehavior: Clip.none,
          children: [
            // Icone cloche avec animation de secousse
            AnimatedBuilder(
              animation: _shakeAnimation,
              builder: (context, child) {
                return Transform.rotate(
                  angle: count > 0 ? _shakeAnimation.value : 0,
                  child: child,
                );
              },
              child: _buildCircleButton(
                icon: Icons.notifications_outlined,
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const NotificationsListScreen(),
                    ),
                  ).then((_) {
                    PushNotificationService.refreshUnreadCount();
                  });
                },
              ),
            ),
            // Badge avec animation de pulsation
            if (count > 0)
              Positioned(
                right: -2,
                top: -2,
                child: AnimatedBuilder(
                  animation: _pulseAnimation,
                  builder: (context, child) {
                    return Transform.scale(
                      scale: _pulseAnimation.value,
                      child: child,
                    );
                  },
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: Colors.red,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.red.withOpacity(0.4),
                          blurRadius: 6,
                          spreadRadius: 1,
                        ),
                      ],
                    ),
                    constraints: const BoxConstraints(
                      minWidth: 18,
                      minHeight: 18,
                    ),
                    child: Text(
                      count > 99 ? '99+' : count.toString(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
              ),
          ],
        );
      },
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

