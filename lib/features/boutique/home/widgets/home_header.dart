import 'dart:async';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../../notifications/notifications_list_screen.dart';
import '../../../../core/services/boutique_theme_provider.dart';
import '../../../../core/utils/responsive.dart';
import '../../../../services/utils/api_endpoint.dart';
import '../../../../services/push_notification_service.dart';
import '../../../../services/models/shop_model.dart';

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
  final String? bannerUrl;
  final Shop? currentShop;
  final bool showButtons;

  const HomeHeader({
    super.key,
    required this.isFavorite,
    required this.onFavoriteToggle,
    required this.onBackPressed,
    this.onHomeTap,
    this.bannerUrl,
    this.currentShop,
    this.showButtons = true,
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
        // ── Banner avec arrondi bas ───────────────────────────
        ClipRRect(
          borderRadius: const BorderRadius.vertical(bottom: Radius.circular(28)),
          child: Container(
            height: double.infinity,
            width: double.infinity,
            child: Stack(
              children: [
                // Banner API ou couleur boutique
                if (hasCoverPage)
                  Image.network(
                    fullImageUrl,
                    fit: BoxFit.cover,
                    alignment: Alignment.center,
                    width: double.infinity,
                    height: double.infinity,
                    errorBuilder: (context, error, stackTrace) {
                      print('❌ Erreur chargement banner depuis API: $error');
                      return Container(
                        width: double.infinity,
                        height: double.infinity,
                        color: shopTheme.primary,
                      );
                    },
                    loadingBuilder: (context, child, loadingProgress) {
                      if (loadingProgress == null) return child;
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
                  Container(
                    width: double.infinity,
                    height: double.infinity,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [shopTheme.primary, shopTheme.gradientEnd],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                    ),
                  ),

                // Gradient overlay haut → scrim derrière les boutons
                Positioned(
                  top: 0, left: 0, right: 0,
                  child: Container(
                    height: 90,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [Colors.black.withOpacity(0.45), Colors.transparent],
                      ),
                    ),
                  ),
                ),

                // Gradient overlay bas → transition douce
                Positioned(
                  bottom: 0, left: 0, right: 0,
                  child: Container(
                    height: 90,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [Colors.transparent, Colors.black.withOpacity(0.45)],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),

        // ── Boutons glass — style unifié ─────────────────────
        if (widget.showButtons) SafeArea(
          child: Padding(
            padding: EdgeInsets.fromLTRB(
              Responsive.horizontalPadding(context), 6,
              Responsive.horizontalPadding(context), 8,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Gauche : ← + 🏠
                Row(
                  children: [
                    _buildGlassBtn(
                      icon: FontAwesomeIcons.arrowLeft,
                      onPressed: widget.onBackPressed,
                    ),
                    if (widget.onHomeTap != null) ...[
                      const SizedBox(width: 8),
                      _buildGlassBtn(
                        icon: FontAwesomeIcons.house,
                        onPressed: widget.onHomeTap!,
                      ),
                    ],
                  ],
                ),

                // Droite : 🎁 + ❤️ + 🔔
                Row(
                  children: [
                    _buildGlassBtn(
                      icon: widget.isFavorite
                          ? FontAwesomeIcons.solidHeart
                          : FontAwesomeIcons.heart,
                      onPressed: widget.onFavoriteToggle,
                      // Cœur rouge si favori, sinon glass normal
                      activeColor: widget.isFavorite ? const Color(0xFFFF3B30) : null,
                    ),
                    const SizedBox(width: 8),
                    _buildNotificationIconBtn(context),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // ── Bouton glassmorphisme unifié ─────────────────────────────────────────
  Widget _buildGlassBtn({
    required IconData icon,
    required VoidCallback onPressed,
    Color? activeColor, // couleur de l'icône si état actif (ex: cœur favori)
  }) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: activeColor != null
              ? activeColor.withOpacity(0.85)
              : Colors.black.withOpacity(0.35),
          border: Border.all(
            color: Colors.white.withOpacity(0.40),
            width: 1.2,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.30),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        alignment: Alignment.center,
        child: FaIcon(icon, color: Colors.white, size: 17),
      ),
    );
  }

  Widget _buildNotificationIconBtn(BuildContext context) {
    return ValueListenableBuilder<int>(
      valueListenable: PushNotificationService.unreadCount,
      builder: (context, count, _) {
        return GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const NotificationsListScreen()),
            ).then((_) => PushNotificationService.refreshUnreadCount());
          },
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              AnimatedBuilder(
                animation: _shakeAnimation,
                builder: (context, child) => Transform.rotate(
                  angle: count > 0 ? _shakeAnimation.value : 0,
                  child: child,
                ),
                // Même style glass que les autres boutons
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.black.withOpacity(0.35),
                    border: Border.all(
                      color: Colors.white.withOpacity(0.40),
                      width: 1.2,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.30),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  alignment: Alignment.center,
                  child: FaIcon(
                    count > 0 ? FontAwesomeIcons.solidBell : FontAwesomeIcons.bell,
                    color: Colors.white,
                    size: 17,
                  ),
                ),
              ),
              if (count > 0)
                Positioned(
                  right: -2,
                  top: -2,
                  child: AnimatedBuilder(
                    animation: _pulseAnimation,
                    builder: (context, child) => Transform.scale(
                      scale: _pulseAnimation.value,
                      child: child,
                    ),
                    child: Container(
                      padding: const EdgeInsets.all(3),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFF3B30),
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 1.5),
                      ),
                      constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
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
          ),
        );
      },
    );
  }

}

