import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../product/product_detail_screen.dart';
import '../panier/cart_manager.dart';
import '../loyalty/create_loyalty_card_page.dart';
import '../loyalty/loyalty_card_page.dart';
import 'widgets/home_header.dart';
import 'widgets/boutique_info_card.dart';
import 'widgets/category_filter_widget.dart';
import 'widgets/product_grid.dart';
import '../loading_screens/loading_screens.dart';
import 'components/home_components.dart';
import '../../../services/shop_service.dart';
import '../../../services/favorites_service.dart';
import '../../../services/loyalty_service.dart';
import '../../../services/models/shop_model.dart';
import '../../../services/models/product_model.dart';
import '../../../core/services/boutique_theme_provider.dart';
import '../../../core/services/storage_service.dart';

/// Écran d'accueil de la boutique - Version modulaire avec intégration API
class HomeScreen extends StatefulWidget {
  final int? shopId; // ID de la boutique (optionnel pour l'instant)
  final Shop? shop; // Objet Shop (si déjà chargé)

  const HomeScreen({super.key, this.shopId, this.shop});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin, WidgetsBindingObserver {
  int _selectedNavIndex = 0;
  String _selectedCategory = "Toutes catégories";
  String _sortOrder = "Trier par";
  String _searchQuery = "";
  bool _isFavorite = false;
  final CartManager _cartManager = CartManager();
  final TextEditingController _searchController = TextEditingController();

  // État de chargement et données de l'API
  bool _isLoading = true;
  bool _hasError = false;
  String? _errorMessage;
  Shop? _currentShop;
  List<Product> _products = [];
  List<ProductCategory> _categories = [];
  int? _selectedCategoryId;

  // Animation pour le badge du panier
  late AnimationController _cartBadgeAnimationController;
  late Animation<double> _cartBadgeAnimation;
  int _previousCartCount = 0;
  bool _cartListenerAdded = false;

  @override
  void initState() {
    super.initState();
    print('🏠 [HomeScreen] initState démarré');

    // Ajouter le listener après un microtask pour éviter les problèmes de synchronisation
    Future.microtask(() {
      if (mounted) {
        _cartManager.addListener(_onCartChanged);
        _cartListenerAdded = true;
        print('🏠 [HomeScreen] Listener du panier ajouté');
      }
    });

    WidgetsBinding.instance.addObserver(this);

    // Initialiser l'animation pour le badge du panier (simplifiée)
    _cartBadgeAnimationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    // Animation simplifiée pour éviter les blocages
    _cartBadgeAnimation = Tween<double>(
      begin: 1.0,
      end: 1.3,
    ).animate(CurvedAnimation(
      parent: _cartBadgeAnimationController,
      curve: Curves.easeInOut,
    ));

    _previousCartCount = _cartManager.itemCount;

    _loadShopData();
  }

  @override
  void dispose() {
    print('🏠 [HomeScreen] dispose appelé - _cartListenerAdded: $_cartListenerAdded');
    try {
      // Seulement enlever le listener s'il a été ajouté
      if (_cartListenerAdded) {
        _cartManager.removeListener(_onCartChanged);
        print('🏠 [HomeScreen] Listener du panier enlevé');
      }
      WidgetsBinding.instance.removeObserver(this);
      _searchController.dispose();
      _cartBadgeAnimationController.dispose();
    } catch (e) {
      print('❌ [HomeScreen] Erreur dans dispose: $e');
    }
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    // Rafraîchir les produits quand l'utilisateur revient à l'application
    // Cela permet de mettre à jour le stock après une commande
    if (state == AppLifecycleState.resumed) {
      print('🔄 App resumed - Rafraîchissement des produits...');
      _loadProducts();
    }
  }

  // Charger les données de la boutique depuis l'API
  Future<void> _loadShopData() async {
    if (!mounted) return;

    setState(() {
      _isLoading = true;
      _hasError = false;
    });

    try {
      // Toujours recharger la boutique depuis l'API pour avoir toutes les infos (incluant le thème)
      // Le ShopService.getShopById récupère automatiquement le cover_image depuis l'API de liste si nécessaire
      final shopId = widget.shop?.id ?? widget.shopId;

      if (shopId != null) {
        _currentShop = await ShopService.getShopById(shopId);
      } else {
        // Mode démo : utiliser une boutique par défaut ou afficher un message
        if (mounted) {
          setState(() {
            _isLoading = false;
            _hasError = true;
            _errorMessage = 'Aucune boutique sélectionnée';
          });
        }
        return;
      }

      // Charger les produits, catégories et statut favori en parallèle
      final productsResult = await ShopService.getShopProducts(_currentShop!.id);
      final categories = await ShopService.getShopCategories(_currentShop!.id);
      final isFavorite = await FavoritesService.isFavorite(_currentShop!.id);

      // Sauvegarder le shopId pour usage futur
      await StorageService.saveLastShopId(_currentShop!.id);

      if (mounted) {
        setState(() {
          _products = productsResult['products'] as List<Product>;
          _categories = categories;
          _isFavorite = isFavorite;
          _isLoading = false;
        });
      }

      // Debug: Afficher les données de la boutique
      print(' Boutique chargée: ${_currentShop?.name} (ID: ${_currentShop?.id})');
      print(' Catégorie API: "${_currentShop?.category}"');
      print(' isRestaurant: ${_currentShop?.isRestaurant}');
      print(' boutiqueType: ${_currentShop?.boutiqueType}');
      print(' Logo URL: ${_currentShop?.logoUrl}');
      print(' Est favori: $_isFavorite');
      print(' Banner URL: ${_currentShop?.bannerUrl}');
      print(' Banner URL est null: ${_currentShop?.bannerUrl == null}');
      print(' Banner URL est vide: ${_currentShop?.bannerUrl?.isEmpty ?? true}');
      if (_currentShop?.bannerUrl != null && _currentShop!.bannerUrl!.isNotEmpty) {
        print(' Banner disponible - URL: ${_currentShop!.bannerUrl}');
      } else {
        print(' Pas de banner pour cette boutique');
      }
      print(' Nombre de produits: ${_products.length}');
      print(' Nombre de catégories: ${_categories.length}');
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _hasError = true;
          _errorMessage = e.toString();
        });
      }
    }
  }

  // Toggle favori avec appel API
  Future<void> _toggleFavorite() async {
    if (_currentShop == null) return;

    try {
      final result = await FavoritesService.toggleFavorite(
        _currentShop!.id,
        _isFavorite,
      );

      if (mounted) {
        setState(() {
          _isFavorite = !_isFavorite;
        });
      }

      if (mounted) {
        final shopTheme = _currentShop?.theme ?? ShopTheme.defaultTheme();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              result['message'] ?? (_isFavorite
                  ? 'Boutique ajoutée aux favoris'
                  : 'Boutique retirée des favoris'),
              style: GoogleFonts.openSans(),
            ),
            backgroundColor: _isFavorite ? shopTheme.primary : Colors.grey.shade700,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // Filtrer les produits par catégorie
  void _onCategoryChanged(int? categoryId, String categoryName) {
    if (!mounted) return;

    setState(() {
      _selectedCategoryId = categoryId;
      _selectedCategory = categoryName;
      // Effacer la recherche textuelle quand on change de catégorie
      _searchQuery = "";
      _searchController.clear();
    });
    _loadProducts();
  }

  // Recharger les produits avec filtres
  Future<void> _loadProducts() async {
    if (_currentShop == null) return;

    try {
      // Mapper les valeurs de tri vers ce que l'API attend
      // API accepte: price_asc, price_desc, name, recent
      String? sortByParam;
      bool? inStockParam;

      if (_sortOrder != "Trier par") {
        if (_sortOrder == "Nom (A-Z)") {
          sortByParam = "name";
        } else if (_sortOrder == "Prix croissant") {
          sortByParam = "price_asc";
        } else if (_sortOrder == "En stock") {
          inStockParam = true; // Filtre pour afficher uniquement les produits en stock
        } else if (_sortOrder == "Rupture de stock") {
          inStockParam = false; // Filtre pour afficher uniquement les produits en rupture
        } else if (_sortOrder == "Prix décroissant") {
          sortByParam = "price_desc";
        } else if (_sortOrder == "Plus récents") {
          sortByParam = "recent";
        }
      }

      final result = await ShopService.getShopProducts(
        _currentShop!.id,
        categoryId: _selectedCategoryId,
        search: _searchQuery.isEmpty ? null : _searchQuery,
        sortBy: sortByParam,
        inStock: inStockParam,
      );

      if (mounted) {
        setState(() {
          _products = result['products'] as List<Product>;
        });
      }
    } catch (e) {
      print('❌ Erreur chargement produits: $e');
      if (mounted) {
        setState(() => _products = []);
      }
    }
  }


  void _onCartChanged() {
    print('🔔 [HomeScreen] _onCartChanged appelé');

    // Utiliser microtask pour éviter setState pendant le build
    Future.microtask(() {
      if (!mounted) {
        print('⚠️ [HomeScreen] Widget non monté, abandon');
        return;
      }

      final currentCount = _cartManager.itemCount;
      print('🔔 [HomeScreen] Nombre d\'articles: $currentCount (précédent: $_previousCartCount)');

      // Si un produit a été ajouté, déclencher l'animation
      if (currentCount > _previousCartCount) {
        print('✨ [HomeScreen] Déclenchement de l\'animation du badge');
        try {
          // Animation aller-retour simplifiée
          _cartBadgeAnimationController.forward(from: 0.0).then((_) {
            if (mounted) {
              _cartBadgeAnimationController.reverse();
            }
          });
        } catch (e) {
          print('❌ [HomeScreen] Erreur animation: $e');
        }
      }

      _previousCartCount = currentCount;

      // setState protégé
      if (mounted) {
        setState(() {});
      }
    });
  }

  void _navigateToProduct(Product product) {
    print(' Navigation vers produit: ${product.name} (ID: ${product.id})');
    print('   Prix: ${product.price}');
    print('   Stock: ${product.stockQuantity}');

    try {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ProductDetailScreen(
            product: {
              'id': product.id,
              'name': product.name,
              'price': product.price,
              'oldPrice': product.comparePrice,
              'stock': product.stockQuantity,
              'isAvailable': product.isAvailable,
              'image': product.primaryImageUrl ?? '',
              'description': product.description,
              'category': product.category?.name,
              'shopId': _currentShop?.id, // Pour validation du panier
              // Champs spécifiques selon le type de boutique
              'preparation_time': product.cookingTime,
              'portions': product.portions?.map((p) => p.toJson()).toList(),
            },
            shop: _currentShop, // Passer la boutique pour adapter l'affichage
          ),
        ),
      );
      print('Navigation lancée avec succès');
    } catch (e) {
      print('Erreur lors de la navigation: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    // Afficher un indicateur de chargement élégant
    if (_isLoading) {
      return const ShopLoadingScreen();
    }

    // Afficher un message d'erreur
    if (_hasError) {
      return HomeErrorState(
        errorMessage: _errorMessage,
        onRetry: _loadShopData,
      );
    }

    // Obtenir le thème de la boutique
    final shopTheme = _currentShop?.theme ?? ShopTheme.defaultTheme();

    return BoutiqueThemeProvider(
      shop: _currentShop,
      child: Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      body: Stack(
        children: [
          // Contenu scrollable
          Column(
            children: [
              // Espace pour le header et la carte
              const SizedBox(height: 220),

              // Espacement entre la carte et les filtres
              const SizedBox(height: 17),

              // Filtres uniquement
              Container(
                color: const Color(0xFFF5F5F5),
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  children: [
                    CategoryFilterWidget(
                      selectedCategory: _selectedCategory,
                      sortOrder: _sortOrder,
                      categories: [
                        'Toutes catégories',
                        ..._categories.map((c) => c.name),
                      ],
                      onCategoryChanged: (value) {
                        if (value == 'Toutes catégories') {
                          _onCategoryChanged(null, value);
                        } else {
                          final category = _categories.firstWhere(
                            (c) => c.name == value,
                            orElse: () => _categories.first,
                          );
                          _onCategoryChanged(category.id, value);
                        }
                      },
                      onSortChanged: (value) {
                        setState(() {
                          _sortOrder = value;
                        });
                        _loadProducts();
                      },
                    ),
                    const SizedBox(height: 4),
                  ],
                ),
              ),

              // Grille de produits
              Expanded(
                child: _products.isEmpty
                    ? HomeEmptyState(
                        shop: _currentShop,
                        primaryColor: shopTheme.primary,
                        selectedCategory: _selectedCategory,
                        searchQuery: _searchQuery,
                      )
                    : ProductGrid(
                        products: _products
                            .map((p) => {
                                  'id': p.id,
                                  'name': p.name,
                                  'price': p.price,
                                  'oldPrice': p.comparePrice,
                                  'discount': p.discountPercentage,
                                  'stock': p.stockQuantity,
                                  'isAvailable': p.isAvailable,
                                  'image': p.primaryImageUrl,
                                  'category': p.category?.name,
                                  'cooking_time': p.cookingTime,
                                })
                            .toList(),
                        onProductTap: (productMap) {
                          // Trouver le Product complet
                          final product = _products.firstWhere(
                            (p) => p.id == productMap['id'],
                          );
                          _navigateToProduct(product);
                        },
                        isRestaurant: _currentShop?.isRestaurant ?? false,
                      ),
              ),
            ],
          ),

          // Header fixe avec image de fond
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: HomeHeader(
              isFavorite: _isFavorite,
              bannerUrl: _currentShop?.bannerUrl,
              onFavoriteToggle: _toggleFavorite,
              onBackPressed: () => Navigator.pop(context),
            ),
          ),

          // Carte d'informations boutique - Chevauche l'image
          Positioned(
            top: 140,
            left: 16,
            right: 16,
            child: BoutiqueInfoCard(
              shopId: _currentShop?.id ?? 1,
              boutiqueName: _currentShop?.name ?? 'Boutique',
              boutiqueDescription: _currentShop?.description ?? 'Bienvenue dans notre boutique',
              boutiqueLogoPath: _currentShop?.logoUrl ?? 'lib/core/assets/lop.jpeg',
              phoneNumber: _currentShop?.phone ?? '',
            ),
          ),

        ],
      ),

      // Bottom Navigation Bar
      bottomNavigationBar: HomeBottomNavigation(
        selectedIndex: _selectedNavIndex,
        currentShop: _currentShop,
        cartManager: _cartManager,
        cartBadgeAnimation: _cartBadgeAnimation,
        onIndexChanged: (index) => setState(() => _selectedNavIndex = index),
        onSearchTap: _showSearchDialog,
        onActionsTap: _showActionsBottomSheet,
        onProductsReload: _loadProducts,
      ),
    ),
    );
  }

  // Afficher le dialog de recherche
  void _showSearchDialog() {
    HomeDialogs.showSearchDialog(
      context: context,
      currentShop: _currentShop,
      searchController: _searchController,
      onSearchChanged: (query) {
        setState(() {
          _searchQuery = query;
        });
        _loadProducts();
      },
    );
  }

  // Afficher le bottom sheet avec les icônes d'actions
  void _showActionsBottomSheet() {
    HomeDialogs.showActionsBottomSheet(
      context: context,
      currentShop: _currentShop,
      onLoyaltyCardTap: _navigateToLoyaltyCard,
    );
  }

  // Naviguer vers la carte de fidélité
  Future<void> _navigateToLoyaltyCard() async {
    if (_currentShop == null) return;

    // Récupérer le téléphone depuis le stockage local
    final cardData = await StorageService.getLoyaltyCard();
    final phone = cardData?['phone'];

    if (!mounted) return;

    if (phone != null && phone.isNotEmpty) {
      // Vérifier si une carte existe sur l'API
      try {
        final loyaltyCard = await LoyaltyService.getCard(
          shopId: _currentShop!.id,
          phone: phone,
        );

        if (!mounted) return;

        if (loyaltyCard != null) {
          // Carte trouvée, afficher
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => LoyaltyCardPage(
                loyaltyCard: loyaltyCard,
              ),
            ),
          );
        } else {
          // Pas de carte, créer
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => CreateLoyaltyCardPage(
                shopId: _currentShop!.id,
                boutiqueName: _currentShop!.name,
                shop: _currentShop,
              ),
            ),
          );
        }
      } catch (e) {
        if (!mounted) return;
        // En cas d'erreur, aller vers création
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => CreateLoyaltyCardPage(
              shopId: _currentShop!.id,
              boutiqueName: _currentShop!.name,
              shop: _currentShop,
            ),
          ),
        );
      }
    } else {
      // Pas de téléphone enregistré, créer carte
      if (!mounted) return;
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => CreateLoyaltyCardPage(
            shopId: _currentShop!.id,
            boutiqueName: _currentShop!.name,
            shop: _currentShop,
          ),
        ),
      );
    }
  }

  // Widget pour créer une icône flottante
  Widget _buildFloatingActionIcon({
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 50,
        height: 50,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.4),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Center(
          child: Icon(
            icon,
            color: Colors.white,
            size: 22,
          ),
        ),
      ),
    );
  }
}
