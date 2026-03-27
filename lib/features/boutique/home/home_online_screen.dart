import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import '../product/product_detail_screen.dart';
import '../panier/cart_manager.dart';
import '../loyalty/create_loyalty_card_page.dart';
import '../loyalty/loyalty_card_page.dart';
import '../notifications/notifications_list_screen.dart';
import '../gift/gift_bottom_sheet.dart';
import 'widgets/home_header.dart';
import 'widgets/boutique_info_card.dart';
import 'widgets/category_filter_widget.dart';
import 'widgets/product_card.dart';
import '../loading_screens/loading_screens.dart';
import 'components/home_components.dart';
import '../../../services/shop_service.dart';
import '../../../services/favorites_service.dart';
import '../../../services/loyalty_service.dart';
import '../../../services/auth_service.dart';
import '../../../services/push_notification_service.dart';
import '../../../services/models/shop_model.dart';
import '../../../services/models/product_model.dart';
import '../../../services/utils/api_endpoint.dart';
import '../../../core/services/boutique_theme_provider.dart';
import '../../../core/services/storage_service.dart';
import '../../../core/utils/responsive.dart';

/// Écran d'accueil de la boutique - Version modulaire avec intégration API
class HomeScreen extends StatefulWidget {
  final int? shopId;
  final Shop? shop;

  const HomeScreen({super.key, this.shopId, this.shop});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with WidgetsBindingObserver {
  int _selectedNavIndex = 0;
  String _selectedCategory = "Toutes catégories";
  String _sortOrder = "Trier par";
  String _searchQuery = "";
  bool _isFavorite = false;
  final CartManager _cartManager = CartManager();
  final TextEditingController _searchController = TextEditingController();

  // Scroll & collapse
  final ScrollController _scrollController = ScrollController();
  bool _isCollapsed = false;

  // État de chargement et données de l'API
  bool _isLoading = true;
  bool _hasError = false;
  String? _errorMessage;
  Shop? _currentShop;
  List<Product> _products = [];
  List<ProductCategory> _categories = [];
  int? _selectedCategoryId;

  // ── Expanded height du SliverAppBar ──────────────────────────────────────
  // expandedHeight N'inclut PAS la status bar (~30px).
  // Total écran = expandedHeight + statusBar.
  // InfoCard bottom ≈ 218px (depuis top écran) → expandedHeight = 218 - 30 + 12 = 200
  static const double _expandedHeight = 232.0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _scrollController.addListener(_onScroll);
    _loadShopData();
  }

  void _onScroll() {
    const threshold = _expandedHeight - kToolbarHeight - 10;
    final collapsed = _scrollController.offset > threshold;
    if (collapsed != _isCollapsed) {
      setState(() => _isCollapsed = collapsed);
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    if (state == AppLifecycleState.resumed) {
      _loadProducts();
    }
  }

  // ── Chargement boutique ───────────────────────────────────────────────────
  Future<void> _loadShopData() async {
    if (!mounted) return;
    setState(() { _isLoading = true; _hasError = false; });

    try {
      final shopId = widget.shop?.id ?? widget.shopId;
      if (shopId != null) {
        _currentShop = await ShopService.getShopById(shopId);
        if ((_currentShop?.bannerUrl == null || _currentShop!.bannerUrl!.isEmpty) &&
            widget.shop?.bannerUrl != null && widget.shop!.bannerUrl!.isNotEmpty) {
          _currentShop = _currentShop!.copyWithBanner(widget.shop!.bannerUrl!);
        }
      } else {
        if (mounted) setState(() { _isLoading = false; _hasError = true; _errorMessage = 'Aucune boutique sélectionnée'; });
        return;
      }

      final productsResult = await ShopService.getShopProducts(_currentShop!.id);
      final categories    = await ShopService.getShopCategories(_currentShop!.id);
      final isFavorite    = await FavoritesService.isFavorite(_currentShop!.id);

      if (isFavorite) FavoritesService.addToLocalCache(_currentShop!);
      await StorageService.saveLastShopId(_currentShop!.id);

      if (mounted) {
        setState(() {
          _products   = productsResult['products'] as List<Product>;
          _categories = categories;
          _isFavorite = isFavorite;
          _isLoading  = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() { _isLoading = false; _hasError = true; _errorMessage = e.toString(); });
    }
  }

  // ── Toggle favori ─────────────────────────────────────────────────────────
  Future<void> _toggleFavorite() async {
    if (_currentShop == null) return;

    if (!AuthService.isAuthenticated) {
      if (!mounted) return;
      final shopTheme = _currentShop?.theme ?? ShopTheme.defaultTheme();
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Connectez-vous pour ajouter des favoris', style: GoogleFonts.openSans()),
        backgroundColor: shopTheme.primary,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        duration: const Duration(seconds: 3),
      ));
      return;
    }

    try {
      final result = await FavoritesService.toggleFavorite(_currentShop!.id);
      if (!mounted) return;
      final isFav = result['data']?['is_favorite'] == true;
      setState(() => _isFavorite = isFav);
      if (isFav) FavoritesService.addToLocalCache(_currentShop!);
      else FavoritesService.removeFromLocalCache(_currentShop!.id);

      final shopTheme = _currentShop?.theme ?? ShopTheme.defaultTheme();
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(result['message'] ?? (isFav ? 'Boutique ajoutée aux favoris' : 'Boutique retirée des favoris'), style: GoogleFonts.openSans()),
        backgroundColor: isFav ? shopTheme.primary : Colors.grey.shade700,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        duration: const Duration(seconds: 2),
      ));
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erreur: ${e.toString()}'), backgroundColor: Colors.red));
    }
  }

  // ── Filtre catégorie ──────────────────────────────────────────────────────
  void _onCategoryChanged(int? categoryId, String categoryName) {
    if (!mounted) return;
    setState(() {
      _selectedCategoryId = categoryId;
      _selectedCategory   = categoryName;
      _searchQuery        = "";
      _searchController.clear();
    });
    _loadProducts();
  }

  // ── Chargement produits ───────────────────────────────────────────────────
  Future<void> _loadProducts() async {
    if (_currentShop == null) return;
    try {
      String? sortByParam;
      bool? inStockParam;
      if (_sortOrder != "Trier par") {
        if (_sortOrder == "Nom (A-Z)")         sortByParam = "name";
        else if (_sortOrder == "Prix croissant")  sortByParam = "price_asc";
        else if (_sortOrder == "En stock")        inStockParam = true;
        else if (_sortOrder == "Rupture de stock") inStockParam = false;
        else if (_sortOrder == "Prix décroissant") sortByParam = "price_desc";
        else if (_sortOrder == "Plus récents")    sortByParam = "recent";
      }
      final result = await ShopService.getShopProducts(
        _currentShop!.id,
        categoryId: _selectedCategoryId,
        search: _searchQuery.isEmpty ? null : _searchQuery,
        sortBy: sortByParam,
        inStock: inStockParam,
      );
      if (mounted) setState(() => _products = result['products'] as List<Product>);
    } catch (e) {
      if (mounted) setState(() => _products = []);
    }
  }

  // ── Panier ────────────────────────────────────────────────────────────────
  void _handleAddToCart(Product product) {
    final shopTheme = _currentShop?.theme ?? ShopTheme.defaultTheme();
    final hasVariants = (product.sizes?.isNotEmpty ?? false) || (product.colors?.isNotEmpty ?? false);
    if (hasVariants) { _navigateToProduct(product); return; }

    final productMap = {
      'id': product.id, 'name': product.name, 'price': product.price,
      'stock': product.stockQuantity, 'isAvailable': product.isAvailable,
      'image': product.primaryImageUrl ?? '',
    };
    final error = _cartManager.addItem(productMap, 1, shopId: _currentShop?.id);
    if (!mounted) return;

    if (error != null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(error, style: GoogleFonts.openSans()),
        backgroundColor: Colors.red.shade600,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        duration: const Duration(seconds: 3),
      ));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Row(children: [
          const FaIcon(FontAwesomeIcons.circleCheck, color: Colors.white, size: 20),
          const SizedBox(width: 8),
          Expanded(child: Text('${product.name} ajouté au panier', style: GoogleFonts.openSans(color: Colors.white), overflow: TextOverflow.ellipsis)),
        ]),
        backgroundColor: shopTheme.primary,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        duration: const Duration(seconds: 2),
      ));
    }
  }

  // ── Navigation produit ────────────────────────────────────────────────────
  void _navigateToProduct(Product product) {
    Navigator.push(context, MaterialPageRoute(
      builder: (context) => ProductDetailScreen(
        product: {
          'id': product.id, 'name': product.name, 'price': product.price,
          'oldPrice': product.comparePrice, 'discount': product.discountPercentage,
          'average_rating': product.averageRating, 'rating_count': product.ratingCount,
          'stock': product.stockQuantity, 'isAvailable': product.isAvailable,
          'image': product.primaryImageUrl ?? '', 'images': product.images?.map((img) => img.url).toList() ?? [],
          'description': product.description, 'category': product.category?.name,
          'categoryId': product.category?.id, 'shopId': _currentShop?.id,
          'preparation_time': product.cookingTime,
          'portions': product.portions?.map((p) => p.toJson()).toList(),
          'sizes': product.sizes, 'colors': product.colors, 'material': product.material,
        },
        shop: _currentShop,
      ),
    ));
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // BUILD
  // ═══════════════════════════════════════════════════════════════════════════

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const ShopLoadingScreen();
    if (_hasError)  return HomeErrorState(errorMessage: _errorMessage, onRetry: _loadShopData);

    final shopTheme = _currentShop?.theme ?? ShopTheme.defaultTheme();

    return BoutiqueThemeProvider(
      shop: _currentShop,
      child: Scaffold(
        backgroundColor: const Color(0xFFF2F3F5),
        body: Stack(
          children: [
            RefreshIndicator(
              color: shopTheme.primary,
              onRefresh: _loadProducts,
              child: CustomScrollView(
                controller: _scrollController,
                slivers: [
                  _buildSliverAppBar(shopTheme),
                  _buildCategoriesSliver(),
                  _buildProductsSliver(shopTheme),
                ],
              ),
            ),
            // ── Boutons flottants contact (visibles uniquement au scroll) ──
            Positioned(
              right: 12,
              bottom: 12,
              child: AnimatedOpacity(
                opacity: _isCollapsed ? 1.0 : 0.0,
                duration: const Duration(milliseconds: 250),
                curve: Curves.easeInOut,
                child: IgnorePointer(
                  ignoring: !_isCollapsed,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _floatingContactBtn(
                        icon: Icons.call_rounded,
                        color: const Color(0xFF34C759),
                        onTap: _call,
                      ),
                      const SizedBox(height: 8),
                      _floatingContactBtn(
                        icon: FontAwesomeIcons.whatsapp,
                        color: const Color(0xFF25D366),
                        onTap: _whatsapp,
                        isFa: true,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
        bottomNavigationBar: HomeBottomNavigation(
          selectedIndex: _selectedNavIndex,
          currentShop: _currentShop,
          onIndexChanged: (index) => setState(() => _selectedNavIndex = index),
          onSearchTap: _showSearchDialog,
          onActionsTap: _showActionsBottomSheet,
          onProductsReload: _loadProducts,
        ),
      ),
    );
  }

  // ── Boutons contact flottants ─────────────────────────────────────────────
  Future<void> _call() async {
    final phone = _currentShop?.phone ?? '';
    if (phone.isEmpty) return;
    final uri = Uri(scheme: 'tel', path: phone);
    if (await canLaunchUrl(uri)) await launchUrl(uri);
  }

  Future<void> _whatsapp() async {
    final phone = _currentShop?.phone ?? '';
    if (phone.isEmpty) return;
    final uri = Uri.parse('https://wa.me/$phone');
    if (await canLaunchUrl(uri)) await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  Widget _floatingContactBtn({
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
    bool isFa = false,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 46,
        height: 46,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.4),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Center(
          child: isFa
              ? FaIcon(icon, color: Colors.white, size: 20)
              : Icon(icon, color: Colors.white, size: 22),
        ),
      ),
    );
  }

  // ── SliverAppBar ──────────────────────────────────────────────────────────
  Widget _buildSliverAppBar(ShopTheme shopTheme) {
    return SliverAppBar(
      expandedHeight: _expandedHeight,
      pinned: true,
      backgroundColor: shopTheme.primary,
      foregroundColor: Colors.white,
      elevation: _isCollapsed ? 3 : 0,
      systemOverlayStyle: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
      ),
      automaticallyImplyLeading: false,
      // ── Barre collapsed ──
      leading: _isCollapsed ? _buildLeadingBack() : const SizedBox.shrink(),
      leadingWidth: _isCollapsed ? 48 : 0,
      title: _isCollapsed ? _buildCollapsedTitle(shopTheme) : null,
      actions: _isCollapsed ? _buildCollapsedActions() : [],
      // ── Espace étendu : banner + infocard ──
      flexibleSpace: FlexibleSpaceBar(
        collapseMode: CollapseMode.pin,
        background: Stack(
          clipBehavior: Clip.none,
          children: [
            // Fond gris pleine hauteur (évite le vide bleu sous l'infocard)
            Container(color: const Color(0xFFF2F3F5)),
            // Banner avec boutons glass (expanded seulement)
            HomeHeader(
              isFavorite: _isFavorite,
              bannerUrl: _currentShop?.bannerUrl,
              currentShop: _currentShop,
              onFavoriteToggle: _toggleFavorite,
              onBackPressed: () => Navigator.pop(context),
              onHomeTap: () => Navigator.pushNamedAndRemoveUntil(
                context, '/access-boutique', (route) => false,
              ),
              showButtons: true,
            ),
            // Carte info boutique
            Positioned(
              top: 110, left: 16, right: 16,
              child: BoutiqueInfoCard(
                shopId: _currentShop?.id ?? 1,
                boutiqueName: _currentShop?.name ?? 'Boutique',
                boutiqueDescription: _currentShop?.description ?? '',
                boutiqueLogoPath: _currentShop?.logoUrl ?? '',
                phoneNumber: _currentShop?.phone ?? '',
                averageRating: _currentShop?.averageRating ?? 0.0,
                totalReviews: _currentShop?.totalReviews ?? 0,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLeadingBack() {
    return IconButton(
      icon: const FaIcon(FontAwesomeIcons.arrowLeft, color: Colors.white, size: 18),
      onPressed: () => Navigator.pop(context),
    );
  }

  Widget _buildCollapsedTitle(ShopTheme shopTheme) {
    final logoUrl = _resolveUrl(_currentShop?.logoUrl);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Petit logo
        Container(
          width: 28, height: 28,
          decoration: const BoxDecoration(shape: BoxShape.circle, color: Colors.white),
          child: ClipOval(
            child: logoUrl != null
                ? Image.network(
                    logoUrl, fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => FaIcon(FontAwesomeIcons.store, size: 13, color: shopTheme.primary),
                  )
                : FaIcon(FontAwesomeIcons.store, size: 13, color: shopTheme.primary),
          ),
        ),
        const SizedBox(width: 8),
        Flexible(
          child: Text(
            _currentShop?.name ?? 'Boutique',
            style: GoogleFonts.inriaSerif(fontSize: 15, fontWeight: FontWeight.w700, color: Colors.white),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  List<Widget> _buildCollapsedActions() {
    return [
      // 🎁 Cadeau
      IconButton(
        icon: const FaIcon(FontAwesomeIcons.gift, color: Colors.white, size: 18),
        onPressed: () => GiftBottomSheet.show(context, currentShop: _currentShop),
      ),
      // ❤️ Favori
      IconButton(
        icon: FaIcon(
          _isFavorite ? FontAwesomeIcons.solidHeart : FontAwesomeIcons.heart,
          color: _isFavorite ? const Color(0xFFFF3B30) : Colors.white,
          size: 18,
        ),
        onPressed: _toggleFavorite,
      ),
      // 🔔 Notifications
      ValueListenableBuilder<int>(
        valueListenable: PushNotificationService.unreadCount,
        builder: (context, count, _) => Stack(
          clipBehavior: Clip.none,
          children: [
            IconButton(
              icon: FaIcon(
                count > 0 ? FontAwesomeIcons.solidBell : FontAwesomeIcons.bell,
                color: Colors.white, size: 18,
              ),
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const NotificationsListScreen()),
              ).then((_) => PushNotificationService.refreshUnreadCount()),
            ),
            if (count > 0)
              Positioned(
                right: 6, top: 6,
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
                    style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
          ],
        ),
      ),
      const SizedBox(width: 4),
    ];
  }

  // ── Catégories (sticky avec ombre) ───────────────────────────────────────
  Widget _buildCategoriesSliver() {
    return SliverPersistentHeader(
      pinned: true,
      delegate: _CategoriesDelegate(
        child: Container(
          color: const Color(0xFFF2F3F5),
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 4),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              CategoryFilterWidget(
                selectedCategory: _selectedCategory,
                sortOrder: _sortOrder,
                categories: ['Toutes catégories', ..._categories.map((c) => c.name)],
                onCategoryChanged: (value) {
                  if (value == 'Toutes catégories') {
                    _onCategoryChanged(null, value);
                  } else {
                    final category = _categories.firstWhere(
                      (c) => c.name == value, orElse: () => _categories.first,
                    );
                    _onCategoryChanged(category.id, value);
                  }
                },
                onSortChanged: (value) {
                  setState(() => _sortOrder = value);
                  _loadProducts();
                },
              ),
              const SizedBox(height: 5),
              Text(
                _selectedCategory == 'Toutes catégories'
                    ? '${_products.length} produit${_products.length > 1 ? 's' : ''}'
                    : '${_products.length} produit${_products.length > 1 ? 's' : ''} · $_selectedCategory',
                style: GoogleFonts.inriaSerif(fontSize: 12, color: Colors.grey.shade500, fontWeight: FontWeight.w500),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Grille produits ───────────────────────────────────────────────────────
  Widget _buildProductsSliver(ShopTheme shopTheme) {
    if (_products.isEmpty) {
      return SliverFillRemaining(
        child: HomeEmptyState(
          shop: _currentShop,
          primaryColor: shopTheme.primary,
          selectedCategory: _selectedCategory,
          searchQuery: _searchQuery,
        ),
      );
    }

    return SliverPadding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      sliver: SliverGrid(
        delegate: SliverChildBuilderDelegate(
          (context, index) {
            final p = _products[index];
            return ProductCard(
              product: {
                'id': p.id, 'name': p.name, 'description': p.description,
                'price': p.price, 'oldPrice': p.comparePrice,
                'discount': p.discountPercentage, 'stock': p.stockQuantity,
                'isAvailable': p.isAvailable, 'image': p.primaryImageUrl,
                'category': p.category?.name, 'cooking_time': p.cookingTime,
                'sizes': p.sizes, 'colors': p.colors,
                'average_rating': p.averageRating, 'rating_count': p.ratingCount,
              },
              onTap: () => _navigateToProduct(p),
              onAddToCart: () => _handleAddToCart(p),
              isRestaurant: _currentShop?.isRestaurant ?? false,
            );
          },
          childCount: _products.length,
        ),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: Responsive.gridColumns(context),
          childAspectRatio: (_currentShop?.isRestaurant ?? false) ? 0.62 : 0.72,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
        ),
      ),
    );
  }

  // ── Helpers ───────────────────────────────────────────────────────────────
  String? _resolveUrl(String? url) {
    if (url == null || url.isEmpty) return null;
    if (url.startsWith('http://') || url.startsWith('https://')) return url;
    final clean = url.startsWith('/') ? url.substring(1) : url;
    return '${Endpoints.storageBaseUrl}/$clean';
  }

  // ── Dialogs ───────────────────────────────────────────────────────────────
  void _showSearchDialog() {
    HomeDialogs.showSearchDialog(
      context: context,
      currentShop: _currentShop,
      searchController: _searchController,
      products: _products.map((p) => {'id': p.id, 'name': p.name, 'price': p.price, 'image': p.primaryImageUrl}).toList(),
      onProductTap: (productMap) {
        Navigator.pop(context);
        final product = _products.firstWhere((p) => p.id == productMap['id']);
        _navigateToProduct(product);
      },
      onSearchChanged: (query) {
        setState(() => _searchQuery = query);
        _loadProducts();
      },
    );
  }

  void _showActionsBottomSheet() {
    HomeDialogs.showActionsBottomSheet(
      context: context,
      currentShop: _currentShop,
      onLoyaltyCardTap: _navigateToLoyaltyCard,
    );
  }

Future<void> _navigateToLoyaltyCard() async {
    if (_currentShop == null) return;
    try {
      await AuthService.ensureToken();
      final card = await LoyaltyService.getCardForShop(_currentShop!.id);
      if (!mounted) return;

      if (card != null) {
        final deleted = await Navigator.of(context).push<bool>(
          MaterialPageRoute(builder: (_) => LoyaltyCardPage(loyaltyCard: card)),
        );
        if (deleted == true && mounted) {
          await Navigator.of(context).push(MaterialPageRoute(
            builder: (_) => CreateLoyaltyCardPage(
              shopId: _currentShop!.id, boutiqueName: _currentShop!.name,
              shop: _currentShop, cardWasDeleted: true,
            ),
          ));
        }
      } else {
        await Navigator.of(context).push(MaterialPageRoute(
          builder: (_) => CreateLoyaltyCardPage(
            shopId: _currentShop!.id, boutiqueName: _currentShop!.name, shop: _currentShop,
          ),
        ));
      }
    } catch (_) {
      if (!mounted) return;
      await Navigator.of(context).push(MaterialPageRoute(
        builder: (_) => CreateLoyaltyCardPage(
          shopId: _currentShop!.id, boutiqueName: _currentShop!.name, shop: _currentShop,
        ),
      ));
    }
  }
}

// ── Delegate sticky catégories avec ombre ─────────────────────────────────────
class _CategoriesDelegate extends SliverPersistentHeaderDelegate {
  final Widget child;
  static const double _height = 76.0;

  const _CategoriesDelegate({required this.child});

  @override
  double get minExtent => _height;
  @override
  double get maxExtent => _height;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Material(
      elevation: overlapsContent ? 4 : 0,
      shadowColor: Colors.black.withOpacity(0.12),
      color: const Color(0xFFF2F3F5),
      child: child,
    );
  }

  @override
  bool shouldRebuild(_CategoriesDelegate old) => true;
}

