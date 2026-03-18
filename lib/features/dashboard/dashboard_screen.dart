import 'dart:async';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../services/dashboard_service.dart';
import '../../services/favorites_service.dart';
import '../../services/loyalty_service.dart';
import '../../services/order_service.dart';
import '../../services/auth_service.dart';
import '../../services/push_notification_service.dart';
import '../../core/services/storage_service.dart';
import '../../services/models/client_model.dart';
import '../../services/models/order_model.dart';
import '../../services/models/dashboard_model.dart';
import '../../services/models/loyalty_card_model.dart';
// Ecrans existants du projet (boutique)
import '../access_boutique/access_boutique_screen.dart';
import '../boutique/home/home_online_screen.dart';
import '../boutique/history/global_history_screen.dart';
import '../boutique/favorites/favorites_boutiques_screen.dart';
import '../boutique/loyalty/loyalty_card_page.dart';
import '../boutique/loyalty/create_loyalty_card_page.dart';
import '../boutique/notifications/notifications_list_screen.dart';
import '../boutique/commande/order_tracking_api_page.dart';
import '../boutique/profile/profile_screen.dart';
// Ecran dashboard unique (pas d'equivalent boutique)
import 'dashboard_stats_screen.dart';
import '../../core/utils/format_utils.dart';

/// Ecran principal du tableau de bord client
class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen>
    with SingleTickerProviderStateMixin {
  static const Color primaryColor = Color(0xFF670C88);
  static const Color accentColor = Color(0xFF8936A8);

  bool _isLoading = true;
  bool _hasError = false;
  String? _errorMessage;

  // Donnees du client connecte (depuis l'API dashboard)
  Client? _client;
  DashboardOverview? _overview;
  DashboardStats? _stats;
  List<Order> _recentOrders = [];
  List<DashboardFavorite> _favorites = [];
  List<LoyaltyCard> _loyaltyCards = [];
  int? _currentShopId; // ID de la boutique active pour filtrer les commandes

  // Animation cloche notification
  late AnimationController _bellController;
  late Animation<double> _shakeAnimation;
  Timer? _shakeTimer;

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
      TweenSequenceItem(tween: Tween(begin: -0.1, end: 0), weight: 1),
    ]).animate(CurvedAnimation(parent: _bellController, curve: Curves.easeInOut));

    PushNotificationService.unreadCount.addListener(_onUnreadChanged);
    if (PushNotificationService.unreadCount.value > 0) {
      _startPeriodicShake();
    }

    _loadDashboard();
  }

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

  Future<void> _loadDashboard() async {
    setState(() {
      _isLoading = true;
      _hasError = false;
    });

    try {
      // 0. Recuperer la boutique active (pour filtrer les commandes)
      _currentShopId = await StorageService.getLastShopId();
      print('[Dashboard] currentShopId: $_currentShopId');

      // 1. Charger en parallele: overview, commandes, favoris, cartes fidelite, stats
      final results = await Future.wait([
        DashboardService.getOverview().catchError((e) {
          print('[Dashboard] Erreur getOverview: $e');
          return DashboardOverview(
            totalOrders: 0, pendingOrders: 0, completedOrders: 0,
            totalSpent: 0, loyaltyPoints: 0, favoritesCount: 0,
            unreadNotifications: 0, recentOrders: [],
          );
        }),
        FavoritesService.getFavorites().then((shops) {
          return shops.map((shop) => DashboardFavorite(
            id: shop.id,
            shopId: shop.id,
            shopName: shop.name,
            shopLogo: shop.logoUrl,
            shopCategory: shop.category,
            shopCity: shop.city,
          )).toList();
        }).catchError((e) {
          print('[Dashboard] Erreur getFavorites: $e');
          return <DashboardFavorite>[];
        }),
        LoyaltyService.getMyCards().catchError((e) {
          print('[Dashboard] Erreur getMyCards: $e');
          return <LoyaltyCard>[];
        }),
        DashboardService.getStats().then<DashboardStats?>((s) => s).catchError((e) {
          print('[Dashboard] Erreur getStats: $e');
          return null as DashboardStats?;
        }),
        // Toujours charger les commandes avec shopId valide (overview retourne shopId=0)
        DashboardService.getOrders(page: 1, perPage: 10)
            .then<DashboardPaginatedResponse<Order>?>((r) => r)
            .catchError((e) {
          print('[Dashboard] Erreur getOrders: $e');
          return null as DashboardPaginatedResponse<Order>?;
        }),
      ]);

      var overview = results[0] as DashboardOverview;
      final favorites = results[1] as List<DashboardFavorite>;
      final loyaltyCards = results[2] as List<LoyaltyCard>;
      final stats = results[3] as DashboardStats?;
      final ordersResponse = results[4] as DashboardPaginatedResponse<Order>?;

      print('[Dashboard] overview.totalOrders: ${overview.totalOrders}');
      print('[Dashboard] overview.totalSpent: ${overview.totalSpent}');
      print('[Dashboard] overview.recentOrders: ${overview.recentOrders.length}');
      print('[Dashboard] ordersResponse: ${ordersResponse?.items.length}');
      print('[Dashboard] favorites list: ${favorites.length}');
      print('[Dashboard] loyaltyCards: ${loyaltyCards.length}');

      // 2. Commandes: privilegier getOrders (shopId valide) sur overview (shopId=0)
      List<Order> recentOrders;
      int totalOrders = overview.totalOrders;
      double totalSpent = overview.totalSpent;

      if (ordersResponse != null && ordersResponse.items.isNotEmpty) {
        recentOrders = ordersResponse.items;
        if (totalOrders == 0) totalOrders = ordersResponse.total;
        print('[Dashboard] Commandes depuis getOrders: ${recentOrders.length}');
      } else {
        recentOrders = overview.recentOrders;
        print('[Dashboard] Commandes depuis overview: ${recentOrders.length}');
      }

      // 3. Calculer totalSpent depuis les commandes si l'API retourne 0
      if (totalSpent == 0 && recentOrders.isNotEmpty) {
        totalSpent = recentOrders.fold(0.0, (sum, order) => sum + order.totalAmount);
        print('[Dashboard] totalSpent calcule depuis commandes: $totalSpent');
      }

      // 4. Prendre le max entre stats et overview pour totalOrders/totalSpent
      if (stats != null) {
        if (stats.totalOrders > totalOrders) totalOrders = stats.totalOrders;
        if (stats.totalSpent > totalSpent) totalSpent = stats.totalSpent;
        print('[Dashboard] Apres merge stats: totalOrders=$totalOrders, totalSpent=$totalSpent');
      }

      // 5. Mettre a jour favoritesCount depuis la vraie liste
      int favoritesCount = overview.favoritesCount;
      if (favorites.length > favoritesCount) {
        favoritesCount = favorites.length;
      }

      // 6. Reconstruire l'overview avec les donnees enrichies
      overview = DashboardOverview(
        totalOrders: totalOrders,
        pendingOrders: overview.pendingOrders,
        completedOrders: overview.completedOrders,
        totalSpent: totalSpent,
        loyaltyPoints: overview.loyaltyPoints,
        favoritesCount: favoritesCount,
        unreadNotifications: overview.unreadNotifications,
        recentOrders: recentOrders,
        client: overview.client,
      );

      // Le client vient de l'API dashboard ou du profil
      final client = overview.client ?? AuthService.currentClient;

      // Rafraichir le profil en arriere-plan si disponible
      if (overview.client != null) {
        AuthService.getProfile().catchError((_) => null);
      }

      setState(() {
        _overview = overview;
        _stats = stats;
        _client = client;
        _recentOrders = recentOrders;
        _favorites = favorites;
        _loyaltyCards = loyaltyCards;
        _isLoading = false;
      });
    } catch (e) {
      print('[Dashboard] ERREUR PRINCIPALE: $e');
      // Fallback ultime: charger le profil + commandes individuellement
      try {
        final client = await AuthService.getProfile();
        // Tenter de charger les commandes meme en mode fallback
        List<Order> fallbackOrders = [];
        List<DashboardFavorite> fallbackFavorites = [];
        try {
          final token = AuthService.authToken;
          if (token != null) {
            final result = await OrderService.getOrders(page: 1);
            fallbackOrders = result['orders'] as List<Order>? ?? [];
          }
        } catch (_) {}
        try {
          final shops = await FavoritesService.getFavorites();
          fallbackFavorites = shops.map((shop) => DashboardFavorite(
            id: shop.id, shopId: shop.id, shopName: shop.name,
            shopLogo: shop.logoUrl, shopCategory: shop.category, shopCity: shop.city,
          )).toList();
        } catch (_) {}

        final totalSpent = fallbackOrders.fold(0.0, (sum, o) => sum + o.totalAmount);

        setState(() {
          _client = client ?? AuthService.currentClient;
          _recentOrders = fallbackOrders;
          _favorites = fallbackFavorites;
          
          _overview = DashboardOverview(
            totalOrders: fallbackOrders.length,
            pendingOrders: 0, completedOrders: 0,
            totalSpent: totalSpent, loyaltyPoints: 0,
            favoritesCount: fallbackFavorites.length,
            unreadNotifications: 0, recentOrders: fallbackOrders,
          );
          _hasError = _client == null && fallbackOrders.isEmpty;
          _errorMessage = _hasError ? e.toString().replaceAll('Exception: ', '') : null;
          _isLoading = false;
        });
      } catch (_) {
        setState(() {
          _client = AuthService.currentClient;
          _hasError = _client == null;
          _errorMessage = e.toString().replaceAll('Exception: ', '');
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: primaryColor.withOpacity(0.08),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const FaIcon(
              FontAwesomeIcons.arrowLeft,
              color: primaryColor,
              size: 18,
            ),
          ),
          onPressed: () => Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const AccessBoutiqueScreen()),
          ),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Mon Espace',
              style: GoogleFonts.inriaSerif(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF1E1E2E),
              ),
            ),
            Text(
              _client?.name ?? AuthService.currentClient?.name ?? 'Accueil',
              style: GoogleFonts.inriaSerif(
                fontSize: 13,
                fontWeight: FontWeight.w400,
                color: Colors.grey[800],
              ),
            ),
          ],
        ),
        actions: [
          // Notifications avec animation
          ValueListenableBuilder<int>(
            valueListenable: PushNotificationService.unreadCount,
            builder: (context, count, _) {
              return Stack(
                clipBehavior: Clip.none,
                children: [
                  AnimatedBuilder(
                    animation: _shakeAnimation,
                    builder: (context, child) {
                      return Transform.rotate(
                        angle: count > 0 ? _shakeAnimation.value : 0,
                        child: child,
                      );
                    },
                    child: IconButton(
                      icon: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: primaryColor.withOpacity(0.08),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const FaIcon(
                          FontAwesomeIcons.bell,
                          color: primaryColor,
                          size: 20,
                        ),
                      ),
                      onPressed: () => _navigateTo(const NotificationsListScreen()),
                    ),
                  ),
                  if (count > 0)
                    Positioned(
                      right: 6,
                      top: 4,
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
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
          // Paramètres (Profil + Déconnexion)
          Container(
            margin: const EdgeInsets.only(right: 12),
            child: PopupMenuButton<String>(
              onSelected: (value) {
                if (value == 'profile') _navigateTo(const ProfileScreen());
                if (value == 'logout') _showLogoutDialog();
              },
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              offset: const Offset(0, 48),
              itemBuilder: (ctx) => [
                PopupMenuItem(
                  value: 'profile',
                  child: Row(children: [
                    Container(
                      padding: const EdgeInsets.all(7),
                      decoration: BoxDecoration(
                        color: primaryColor.withOpacity(0.10),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const FaIcon(FontAwesomeIcons.user, size: 14, color: primaryColor),
                    ),
                    const SizedBox(width: 12),
                    Text('Mon profil', style: GoogleFonts.inriaSerif(fontSize: 14, fontWeight: FontWeight.w600)),
                  ]),
                ),
                const PopupMenuDivider(),
                PopupMenuItem(
                  value: 'logout',
                  child: Row(children: [
                    Container(
                      padding: const EdgeInsets.all(7),
                      decoration: BoxDecoration(
                        color: Colors.red.withOpacity(0.10),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const FaIcon(FontAwesomeIcons.rightFromBracket, size: 14, color: Colors.red),
                    ),
                    const SizedBox(width: 12),
                    Text('Déconnexion', style: GoogleFonts.inriaSerif(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.red)),
                  ]),
                ),
              ],
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: primaryColor.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const FaIcon(FontAwesomeIcons.gear, color: primaryColor, size: 20),
              ),
            ),
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(
            height: 1,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.transparent,
                  primaryColor.withOpacity(0.1),
                  primaryColor.withOpacity(0.1),
                  Colors.transparent,
                ],
                stops: const [0.0, 0.2, 0.8, 1.0],
              ),
            ),
          ),
        ),
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: accentColor),
      );
    }

    if (_hasError) {
      return _buildErrorState();
    }

    return RefreshIndicator(
      onRefresh: _loadDashboard,
      color: accentColor,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Banniere d'accueil
            _buildWelcomeBanner(),
            const SizedBox(height: 20),

            // Navigation rapide (comme les onglets du web)
            _buildNavTabs(),
            const SizedBox(height: 20),

            // 3 cartes stats: Commandes | Total Depense | Favoris
            _buildQuickStats(),
            const SizedBox(height: 24),

            // Dernieres commandes
            _buildRecentOrdersSection(),
            const SizedBox(height: 24),

            // Boutiques visitees
            _buildVisitedShopsSection(),
            const SizedBox(height: 24),

            // Mes Favoris
            _buildFavoritesSection(),
            const SizedBox(height: 24),

            // Programme de fidelite
            _buildLoyaltyBanner(),

            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // NAVIGATION RAPIDE (onglets comme le web)
  // ============================================================

  Widget _buildNavTabs() {
    final tabs = [
      _NavTab(FontAwesomeIcons.receipt, 'Commandes',
          () => _navigateTo(const GlobalHistoryScreen())),
      _NavTab(FontAwesomeIcons.idCard, 'Cartes',
          () => _openLoyaltyCards()),
      _NavTab(FontAwesomeIcons.heart, 'Favoris',
          () => _navigateTo(const FavoritesBoutiquesScreen(showBottomNav: false))),
      _NavTab(FontAwesomeIcons.chartBar, 'Stats',
          () => _navigateTo(const DashboardStatsScreen())),
      _NavTab(FontAwesomeIcons.bell, 'Notifications',
          () => _navigateTo(const NotificationsListScreen())),
    ];

    return SizedBox(
      height: 42,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: tabs.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final tab = tabs[index];
          return GestureDetector(
            onTap: tab.onTap,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    primaryColor.withOpacity(0.1),
                    accentColor.withOpacity(0.06),
                  ],
                ),
                borderRadius: BorderRadius.circular(21),
                border: Border.all(color: primaryColor.withOpacity(0.25)),
              ),
              child: Row(
                children: [
                  Icon(tab.icon, color: primaryColor, size: 14),
                  const SizedBox(width: 7),
                  Text(
                    tab.label,
                    style: GoogleFonts.inriaSerif(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: primaryColor,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  // ============================================================
  // DECONNEXION
  // ============================================================

  void _showLogoutDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            const FaIcon(FontAwesomeIcons.rightFromBracket, color: Colors.red, size: 24),
            const SizedBox(width: 10),
            Text(
              'Déconnexion',
              style: GoogleFonts.inriaSerif(
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        content: Text(
          'Voulez-vous vraiment vous déconnecter ?',
          style: GoogleFonts.inriaSerif(fontSize: 14, color: Colors.grey[800]),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              'Annuler',
              style: GoogleFonts.inriaSerif(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.grey[800],
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              _performLogout();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
            child: Text(
              'Quitter',
              style: GoogleFonts.inriaSerif(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _performLogout() async {
    await AuthService.logout();
    if (mounted) {
      Navigator.of(context).pushNamedAndRemoveUntil('/auth/login', (_) => false);
    }
  }

  // ============================================================
  // CARTES DE FIDELITE (utilise boutique/loyalty)
  // ============================================================

  Future<void> _openLoyaltyCards() async {
    try {
      final freshCards = await LoyaltyService.getMyCards();
      if (mounted) setState(() => _loyaltyCards = freshCards);
    } catch (_) {}

    if (_loyaltyCards.isEmpty) {
      _showNoCardDialog();
    } else if (_loyaltyCards.length == 1) {
      final card = _loyaltyCards.first;
      final deleted = await Navigator.push<bool>(
        context,
        MaterialPageRoute(builder: (_) => LoyaltyCardPage(loyaltyCard: card)),
      );
      if (deleted == true && mounted) {
        // Retirer localement sans re-fetcher l'API (getMyCards a un délai de mise à jour)
        setState(() => _loyaltyCards.removeWhere((c) => c.id == card.id));
        _showNoCardDialog(wasDeleted: true);
      }
    } else {
      _showCardPicker();
    }
  }

  void _showNoCardDialog({bool wasDeleted = false}) {
    // Collecter les boutiques connues (commandes + favoris) sans doublons
    // Si une boutique courante est connue, on se limite à elle seule
    final Map<int, String> knownShops = {};
    for (final order in _recentOrders) {
      if (order.shopId > 0 && order.shopName != null) {
        if (_currentShopId == null || order.shopId == _currentShopId) {
          knownShops[order.shopId] = order.shopName!;
        }
      }
    }
    for (final fav in _favorites) {
      if (fav.shopId > 0 && fav.shopName.isNotEmpty) {
        if (_currentShopId == null || fav.shopId == _currentShopId) {
          knownShops[fav.shopId] = fav.shopName;
        }
      }
    }

    // Si une seule boutique connue, aller directement a la creation
    if (knownShops.length == 1) {
      final entry = knownShops.entries.first;
      _navigateTo(CreateLoyaltyCardPage(
        shopId: entry.key,
        boutiqueName: entry.value,
        cardWasDeleted: wasDeleted,
      ));
      return;
    }

    // Sinon afficher le bottom sheet
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
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
                color: accentColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(16),
              ),
              child: const FaIcon(FontAwesomeIcons.creditCard,
                  color: accentColor, size: 30),
            ),
            const SizedBox(height: 16),
            Text(
              'Créer une carte de fidélité',
              style: GoogleFonts.inriaSerif(
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),

            if (knownShops.isEmpty) ...[
              // Aucune boutique connue
              Text(
                'Passez une commande ou ajoutez une boutique en favori pour pouvoir créer une carte.',
                textAlign: TextAlign.center,
                style: GoogleFonts.inriaSerif(
                  fontSize: 14,
                  color: Colors.grey[800],
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.pop(ctx);
                    _navigateTo(const FavoritesBoutiquesScreen(showBottomNav: false));
                  },
                  icon: const FaIcon(FontAwesomeIcons.magnifyingGlass, size: 18),
                  label: Text(
                    'Explorer les boutiques',
                    style: GoogleFonts.inriaSerif(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: accentColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                    elevation: 0,
                  ),
                ),
              ),
            ] else ...[
              // Choisir une boutique parmi celles connues
              Text(
                'Choisissez la boutique',
                style: GoogleFonts.inriaSerif(
                  fontSize: 14,
                  color: Colors.grey[800],
                ),
              ),
              const SizedBox(height: 16),
              ...knownShops.entries.map((entry) => Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    child: ListTile(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      tileColor: const Color(0xFFF8F9FA),
                      leading: Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: primaryColor.withOpacity(0.08),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const FaIcon(FontAwesomeIcons.store,
                            color: primaryColor, size: 22),
                      ),
                      title: Text(
                        entry.value,
                        style: GoogleFonts.inriaSerif(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      trailing: const FaIcon(FontAwesomeIcons.arrowRight,
                          size: 16, color: Colors.grey),
                      onTap: () {
                        Navigator.pop(ctx);
                        _navigateTo(CreateLoyaltyCardPage(
                          shopId: entry.key,
                          boutiqueName: entry.value,
                          cardWasDeleted: wasDeleted,
                        ));
                      },
                    ),
                  )),
            ],
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  void _showCardPicker() {
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
              'Mes cartes de fidélité',
              style: GoogleFonts.inriaSerif(
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 16),
            ..._loyaltyCards.map((card) => ListTile(
                  leading: Container(
                    width: 44,
                    height: 44,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: accentColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const FaIcon(FontAwesomeIcons.gift,
                        color: accentColor, size: 22),
                  ),
                  title: Text(
                    card.shopName,
                    style: GoogleFonts.inriaSerif(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  subtitle: Text(
                    '${card.points} points',
                    style: GoogleFonts.inriaSerif(
                      fontSize: 13,
                      color: Colors.grey[800],
                    ),
                  ),
                  trailing: const FaIcon(FontAwesomeIcons.arrowRight,
                      size: 16, color: Colors.grey),
                  onTap: () async {
                    Navigator.pop(ctx);
                    final deleted = await Navigator.push<bool>(
                      context,
                      MaterialPageRoute(builder: (_) => LoyaltyCardPage(loyaltyCard: card)),
                    );
                    if (deleted == true && mounted) {
                      print('[PICKER] Carte ${card.id} supprimée, cartes restantes: ${_loyaltyCards.length - 1}');
                      setState(() => _loyaltyCards.removeWhere((c) => c.id == card.id));
                      if (_loyaltyCards.isEmpty) {
                        _showNoCardDialog(wasDeleted: true);
                      } else if (_loyaltyCards.length == 1) {
                        // Une seule carte restante → ouvrir directement sans re-fetch
                        final remaining = _loyaltyCards.first;
                        final del = await Navigator.push<bool>(
                          context,
                          MaterialPageRoute(builder: (_) => LoyaltyCardPage(loyaltyCard: remaining)),
                        );
                        if (del == true && mounted) {
                          setState(() => _loyaltyCards.clear());
                          _showNoCardDialog(wasDeleted: true);
                        }
                      } else {
                        // Plusieurs cartes restantes → réafficher le picker sans re-fetch
                        _showCardPicker();
                      }
                    }
                  },
                )),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // BANNIERE D'ACCUEIL
  // ============================================================

  Widget _buildWelcomeBanner() {
    final name = _client?.name ?? AuthService.currentClient?.name ?? 'Client';
    final initials = _client?.initials ??
        (name.isNotEmpty ? name[0].toUpperCase() : '?');
    final memberSince = _formatMemberSince(
        _client?.createdAt ?? AuthService.currentClient?.createdAt);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF8936A8), Color(0xFFB932D6)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: accentColor.withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Center(
              child: Text(
                initials,
                style: GoogleFonts.inriaSerif(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Bonjour, $name !',
                  style: GoogleFonts.inriaSerif(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  'Bienvenue dans votre espace',
                  style: GoogleFonts.inriaSerif(
                    fontSize: 14,
                    color: Colors.white.withOpacity(0.85),
                  ),
                ),
                if (_client?.phone != null && _client!.phone.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    _client!.formattedPhone,
                    style: GoogleFonts.robotoMono(
                      fontSize: 13,
                      color: Colors.white.withOpacity(0.7),
                    ),
                  ),
                ],
              ],
            ),
          ),
          if (memberSince != null)
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  'Membre depuis',
                  style: GoogleFonts.inriaSerif(
                    fontSize: 12,
                    color: Colors.white.withOpacity(0.7),
                  ),
                ),
                Text(
                  memberSince,
                  style: GoogleFonts.inriaSerif(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }

  // ============================================================
  // STATISTIQUES: Commandes | Total Depense | Favoris
  // ============================================================

  Widget _buildQuickStats() {
    // Depenses: max entre stats API, overview API
    final spentFromStats = _stats?.totalSpent ?? 0.0;
    final spentFromOverview = _overview?.totalSpent ?? 0.0;
    final totalSpent = spentFromStats > spentFromOverview ? spentFromStats : spentFromOverview;
    final spentFormatted = fmtAmount(totalSpent);

    // Favoris: max entre stats API, overview API, et liste locale
    final favFromOverview = _overview?.favoritesCount ?? 0;
    final favFromLocal = _favorites.length;
    int actualFavCount = favFromOverview > favFromLocal ? favFromOverview : favFromLocal;

    // Commandes: max entre stats API, overview API, et commandes recentes
    final ordersFromStats = _stats?.totalOrders ?? 0;
    final ordersFromOverview = _overview?.totalOrders ?? 0;
    final ordersFromLocal = _recentOrders.length;
    int actualOrdersCount = ordersFromStats;
    if (ordersFromOverview > actualOrdersCount) actualOrdersCount = ordersFromOverview;
    if (ordersFromLocal > actualOrdersCount) actualOrdersCount = ordersFromLocal;

    return Row(
      children: [
        _buildStatCard(
          icon: FontAwesomeIcons.receipt,
          label: 'COMMANDES',
          value: '$actualOrdersCount',
          color: const Color(0xFF42A5F5),
        ),
        const SizedBox(width: 12),
        _buildStatCard(
          icon: Icons.account_balance_wallet_outlined,
          label: 'TOTAL DÉPENSÉ',
          value: '$spentFormatted F',
          color: const Color(0xFF26A69A),
        ),
        const SizedBox(width: 12),
        _buildStatCard(
          icon: FontAwesomeIcons.heart,
          label: 'FAVORIS',
          value: '$actualFavCount',
          color: const Color(0xFFE91E63),
        ),
      ],
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.12),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: color.withOpacity(0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(height: 10),
            Text(
              value,
              style: GoogleFonts.inriaSerif(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: color,
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: GoogleFonts.inriaSerif(
                fontSize: 10,
                fontWeight: FontWeight.w500,
                color: Colors.grey[700],
                letterSpacing: 0.3,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // DERNIERES COMMANDES
  // ============================================================

  Widget _buildRecentOrdersSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: primaryColor.withOpacity(0.05),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Titre + Voir tout
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                child: Row(
                  children: [
                    FaIcon(FontAwesomeIcons.bagShopping,
                        color: accentColor, size: 20),
                    const SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        'Dernières commandes',
                        style: GoogleFonts.inriaSerif(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF1E1E2E),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              GestureDetector(
                onTap: () => _navigateTo(const GlobalHistoryScreen()),
                child: Row(
                  children: [
                    Text(
                      'Voir tout',
                      style: GoogleFonts.inriaSerif(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: accentColor,
                      ),
                    ),
                    const SizedBox(width: 4),
                    FaIcon(FontAwesomeIcons.arrowRight,
                        color: accentColor, size: 16),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          if (_recentOrders.isEmpty)
            _buildEmptyOrdersState()
          else
            ..._recentOrders
                .take(3)
                .map(_buildRecentOrderCard),
        ],
      ),
    );
  }

  // ============================================================
  // BOUTIQUES VISITEES
  // ============================================================

  Widget _buildVisitedShopsSection() {
    // Extraire les boutiques uniques depuis les commandes
    final Map<String, Map<String, dynamic>> uniqueShops = {};
    for (final order in _recentOrders) {
      final name = order.shopName;
      if (name != null && name.isNotEmpty && !uniqueShops.containsKey(name)) {
        uniqueShops[name] = {
          'name': name,
          'logo': order.shopLogo,
          'shopId': order.shopId,
        };
      }
    }

    if (uniqueShops.isEmpty) return const SizedBox.shrink();

    final shops = uniqueShops.values.toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Titre
        Row(
          children: [
            FaIcon(FontAwesomeIcons.store, color: accentColor, size: 20),
            const SizedBox(width: 8),
            Text(
              'Boutiques visitées',
              style: GoogleFonts.inriaSerif(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF1E1E2E),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),

        // Liste horizontale
        SizedBox(
          height: 132,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            itemCount: shops.length,
            separatorBuilder: (_, __) => const SizedBox(width: 12),
            itemBuilder: (context, index) {
              final shop = shops[index];
              final shopId = shop['shopId'] as int;
              final name = shop['name'] as String;
              final logo = shop['logo'] as String?;

              return GestureDetector(
                onTap: shopId > 0
                    ? () => _navigateTo(HomeScreen(shopId: shopId))
                    : null,
                child: Container(
                  width: 142,
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: [
                      BoxShadow(
                        color: primaryColor.withOpacity(0.06),
                        blurRadius: 8,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 54,
                        height: 54,
                        decoration: BoxDecoration(
                          color: primaryColor.withOpacity(0.08),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: logo != null && logo.isNotEmpty
                            ? ClipRRect(
                                borderRadius: BorderRadius.circular(14),
                                child: Image.network(
                                  logo,
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, __, ___) => FaIcon(
                                    FontAwesomeIcons.store,
                                    color: accentColor,
                                    size: 26,
                                  ),
                                ),
                              )
                            : FaIcon(
                                FontAwesomeIcons.store,
                                color: accentColor,
                                size: 26,
                              ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        name,
                        style: GoogleFonts.inriaSerif(
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                          color: const Color(0xFF1E1E2E),
                        ),
                        maxLines: 2,
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyOrdersState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 24),
        child: Column(
          children: [
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(16),
              ),
              child: FaIcon(FontAwesomeIcons.cartShopping,
                  color: Colors.grey[900], size: 30),
            ),
            const SizedBox(height: 12),
            Text(
              'Aucune commande',
              style: GoogleFonts.inriaSerif(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.grey[800],
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Explorez les restaurants',
              style: GoogleFonts.inriaSerif(
                fontSize: 14,
                color: Colors.grey[900],
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () => Navigator.pop(context),
              icon: const FaIcon(FontAwesomeIcons.magnifyingGlass, size: 18),
              label: Text(
                'Découvrir',
                style: GoogleFonts.inriaSerif(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: accentColor,
                foregroundColor: Colors.white,
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
                elevation: 0,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentOrderCard(Order order) {
    final statusColor = _getStatusColor(order.status);
    final statusLabel = _getStatusLabel(order.status);

    return GestureDetector(
      onTap: () {
        final phone = _client?.phone ?? AuthService.currentClient?.phone ?? '';
        _navigateTo(OrderTrackingApiPage(
          orderNumber: order.orderNumber,
          customerPhone: phone,
        ));
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        decoration: BoxDecoration(
          color: const Color(0xFFF8F9FA),
          borderRadius: BorderRadius.circular(12),
          border: Border(
            left: BorderSide(color: statusColor, width: 3),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: primaryColor.withOpacity(0.08),
                borderRadius: BorderRadius.circular(12),
              ),
              child: order.shopLogo != null && order.shopLogo!.isNotEmpty
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.network(
                        order.shopLogo!,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => const FaIcon(
                          FontAwesomeIcons.store,
                          color: primaryColor,
                          size: 22,
                        ),
                      ),
                    )
                  : const FaIcon(
                      FontAwesomeIcons.store,
                      color: primaryColor,
                      size: 22,
                    ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    order.shopName ?? '#${order.orderNumber}',
                    style: GoogleFonts.inriaSerif(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF1E1E2E),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    _formatDate(order.createdAt),
                    style: GoogleFonts.inriaSerif(
                      fontSize: 13,
                      color: Colors.grey[800],
                    ),
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '${fmtAmount(order.totalAmount)} F',
                  style: GoogleFonts.inriaSerif(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF1E1E2E),
                  ),
                ),
                const SizedBox(height: 4),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    statusLabel,
                    style: GoogleFonts.inriaSerif(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: statusColor,
                    ),
                  ),
                ),
              ],
            ),
          ],
          ),
        ),
      ),
    );
  }

  // ============================================================
  // MES FAVORIS
  // ============================================================

  Widget _buildFavoritesSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const FaIcon(FontAwesomeIcons.solidHeart,
                color: Color(0xFFE91E63), size: 20),
            const SizedBox(width: 8),
            Text(
              'Mes Favoris',
              style: GoogleFonts.inriaSerif(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF1E1E2E),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: primaryColor.withOpacity(0.05),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: _favorites.isEmpty
              ? _buildEmptyFavoritesState()
              : Column(
                  children: [
                    ..._favorites.take(3).map(_buildFavoriteItem),
                    if (_favorites.length > 3) ...[
                      const SizedBox(height: 8),
                      GestureDetector(
                        onTap: () =>
                            _navigateTo(const FavoritesBoutiquesScreen(showBottomNav: false)),
                        child: Text(
                          'Voir tous les favoris',
                          style: GoogleFonts.inriaSerif(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: accentColor,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
        ),
      ],
    );
  }

  Widget _buildEmptyFavoritesState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 24),
        child: Column(
          children: [
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: const Color(0xFFE91E63).withOpacity(0.1),
                borderRadius: BorderRadius.circular(16),
              ),
              child: const FaIcon(FontAwesomeIcons.solidHeart,
                  color: Color(0xFFE91E63), size: 30),
            ),
            const SizedBox(height: 12),
            Text(
              'Aucun favori',
              style: GoogleFonts.inriaSerif(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.grey[800],
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Ajoutez des restaurants à vos favoris',
              style: GoogleFonts.inriaSerif(
                fontSize: 14,
                color: Colors.grey[900],
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () => _navigateTo(const FavoritesBoutiquesScreen(showBottomNav: false)),
              icon: const FaIcon(FontAwesomeIcons.magnifyingGlass, size: 18),
              label: Text(
                'Découvrir',
                style: GoogleFonts.inriaSerif(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: accentColor,
                foregroundColor: Colors.white,
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
                elevation: 0,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFavoriteItem(DashboardFavorite favorite) {
    return GestureDetector(
      onTap: () => _navigateTo(HomeScreen(shopId: favorite.shopId)),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: const Color(0xFFF8F9FA),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: primaryColor.withOpacity(0.08),
                borderRadius: BorderRadius.circular(12),
              ),
              child: favorite.shopLogo != null && favorite.shopLogo!.isNotEmpty
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.network(
                        favorite.shopLogo!,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => const FaIcon(
                          FontAwesomeIcons.store,
                          color: primaryColor,
                          size: 22,
                        ),
                      ),
                    )
                  : const FaIcon(
                      FontAwesomeIcons.store,
                      color: primaryColor,
                      size: 22,
                    ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    favorite.shopName,
                    style: GoogleFonts.inriaSerif(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF1E1E2E),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (favorite.shopCategory != null ||
                      favorite.shopCity != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      [favorite.shopCategory, favorite.shopCity]
                          .where((e) => e != null && e.isNotEmpty)
                          .join(' - '),
                      style: GoogleFonts.inriaSerif(
                        fontSize: 13,
                        color: Colors.grey[800],
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ),
            ),
            const FaIcon(FontAwesomeIcons.solidHeart,
                color: Color(0xFFE91E63), size: 20),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // PROGRAMME DE FIDELITE
  // ============================================================

  Widget _buildLoyaltyBanner() {
    return GestureDetector(
      onTap: () => _openLoyaltyCards(),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF5B2C8E), Color(0xFF8936A8)],
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: primaryColor.withOpacity(0.3),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const FaIcon(FontAwesomeIcons.gift,
                  color: Colors.white, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Programme de fidélité',
                    style: GoogleFonts.inriaSerif(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    _loyaltyCards.isEmpty
                        ? 'Cumulez des points a chaque commande'
                        : '${_loyaltyCards.length} carte(s) - ${_loyaltyCards.fold<int>(0, (sum, c) => sum + c.points)} points',
                    style: GoogleFonts.inriaSerif(
                      fontSize: 13,
                      color: Colors.white.withOpacity(0.85),
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    _loyaltyCards.isEmpty
                        ? FontAwesomeIcons.qrcode
                        : FontAwesomeIcons.eye,
                    color: primaryColor,
                    size: 16,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    _loyaltyCards.isEmpty ? 'Créer une carte' : 'Voir',
                    style: GoogleFonts.inriaSerif(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: primaryColor,
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

  // ============================================================
  // UTILITAIRES
  // ============================================================

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            FaIcon(FontAwesomeIcons.circleExclamation, size: 64, color: Colors.red[300]),
            const SizedBox(height: 16),
            Text(
              'Erreur de chargement',
              style: GoogleFonts.inriaSerif(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _errorMessage ?? 'Une erreur est survenue',
              style: GoogleFonts.inriaSerif(fontSize: 14, color: Colors.grey[800]),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _loadDashboard,
              style: ElevatedButton.styleFrom(
                backgroundColor: accentColor,
                padding:
                    const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              child: Text(
                'Réessayer',
                style: GoogleFonts.inriaSerif(
                  fontSize: 14,
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

  void _navigateTo(Widget screen) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => screen),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'recue':
        return const Color(0xFFFFA726);
      case 'en_traitement':
        return const Color(0xFF42A5F5);
      case 'prete':
        return const Color(0xFF9C27B0);
      case 'en_livraison':
        return const Color(0xFFFF9800);
      case 'livree':
        return const Color(0xFF4CAF50);
      case 'annulee':
        return const Color(0xFFE91E63);
      default:
        return Colors.grey;
    }
  }

  String _getStatusLabel(String status) {
    switch (status) {
      case 'recue':
        return 'Reçue';
      case 'en_traitement':
        return 'En préparation';
      case 'prete':
        return 'Prête';
      case 'en_livraison':
        return 'En livraison';
      case 'livree':
        return 'Livrée';
      case 'annulee':
        return 'Annulée';
      default:
        return status;
    }
  }

  String _formatDate(DateTime date) {
    final months = [
      'Jan', 'Fev', 'Mar', 'Avr', 'Mai', 'Juin',
      'Juil', 'Aout', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }

  String? _formatMemberSince(DateTime? date) {
    if (date == null) return null;
    final months = [
      'Jan', 'Fev', 'Mar', 'Avr', 'Mai', 'Juin',
      'Juil', 'Aout', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${months[date.month - 1]} ${date.year}';
  }
}

class _NavTab {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  _NavTab(this.icon, this.label, this.onTap);
}
