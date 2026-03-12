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
import '../../../services/auth_service.dart';
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

class _HomeScreenState extends State<HomeScreen> with WidgetsBindingObserver {
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

  @override
  void initState() {
    super.initState();
    print('🏠 [HomeScreen] initState démarré');
    WidgetsBinding.instance.addObserver(this);
    _loadShopData();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _searchController.dispose();
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
        // Si le detail API ne retourne pas de banner mais que le shop original en a un
        // (venant de la liste qui contient cover_image), le preserver
        if ((_currentShop?.bannerUrl == null || _currentShop!.bannerUrl!.isEmpty) &&
            widget.shop?.bannerUrl != null && widget.shop!.bannerUrl!.isNotEmpty) {
          print('🖼️ [HomeScreen] Banner preserve depuis shop original: ${widget.shop!.bannerUrl}');
          _currentShop = _currentShop!.copyWithBanner(widget.shop!.bannerUrl!);
        }
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

      // Synchroniser le cache persistant des favoris
      if (isFavorite) {
        FavoritesService.addToLocalCache(_currentShop!);
      }

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

  // Toggle favori via POST /client/favorites/toggle (endpoint recommandé)
  Future<void> _toggleFavorite() async {
    if (_currentShop == null) return;

    // Verifier que l'utilisateur est connecte
    if (!AuthService.isAuthenticated) {
      if (!mounted) return;
      final shopTheme = _currentShop?.theme ?? ShopTheme.defaultTheme();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Connectez-vous pour ajouter des favoris',
            style: GoogleFonts.openSans(),
          ),
          backgroundColor: shopTheme.primary,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          duration: const Duration(seconds: 3),
        ),
      );
      return;
    }

    try {
      // Appel API toggle — retourne { data: { is_favorite, action, ... } }
      final result = await FavoritesService.toggleFavorite(_currentShop!.id);

      if (!mounted) return;

      // Lire l'état depuis la réponse API
      final isFav = result['data']?['is_favorite'] == true;

      setState(() {
        _isFavorite = isFav;
      });

      // Synchroniser le cache persistant
      if (isFav) {
        FavoritesService.addToLocalCache(_currentShop!);
      } else {
        FavoritesService.removeFromLocalCache(_currentShop!.id);
      }

      final shopTheme = _currentShop?.theme ?? ShopTheme.defaultTheme();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            result['message'] ?? (isFav
                ? 'Boutique ajoutée aux favoris'
                : 'Boutique retirée des favoris'),
            style: GoogleFonts.openSans(),
          ),
          backgroundColor: isFav ? shopTheme.primary : Colors.grey.shade700,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          duration: const Duration(seconds: 2),
        ),
      );
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


  void _handleAddToCart(Product product) {
    final shopTheme = _currentShop?.theme ?? ShopTheme.defaultTheme();

    // Produit avec variants → ouvrir le détail pour sélectionner
    final hasVariants = (product.sizes?.isNotEmpty ?? false) ||
        (product.colors?.isNotEmpty ?? false);
    if (hasVariants) {
      _navigateToProduct(product);
      return;
    }

    // Produit simple → ajout direct au panier
    final productMap = {
      'id': product.id,
      'name': product.name,
      'price': product.price,
      'stock': product.stockQuantity,
      'isAvailable': product.isAvailable,
      'image': product.primaryImageUrl ?? '',
    };

    final error = _cartManager.addItem(
      productMap,
      1,
      shopId: _currentShop?.id,
    );

    if (!mounted) return;

    if (error != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error, style: GoogleFonts.openSans()),
          backgroundColor: Colors.red.shade600,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          duration: const Duration(seconds: 3),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.check_circle_outline, color: Colors.white, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  '${product.name} ajouté au panier',
                  style: GoogleFonts.openSans(color: Colors.white),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          backgroundColor: shopTheme.primary,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  void _navigateToProduct(Product product) {
    print(' Navigation vers produit: ${product.name} (ID: ${product.id})');
    print('   Prix: ${product.price}');
    print('   Stock: ${product.stockQuantity}');
    print('   👕 Sizes: ${product.sizes}');
    print('   🎨 Colors: ${product.colors}');
    print('   📦 Material: ${product.material}');

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
              'discount': product.discountPercentage,
              'average_rating': product.averageRating,
              'rating_count': product.ratingCount,
              'stock': product.stockQuantity,
              'isAvailable': product.isAvailable,
              'image': product.primaryImageUrl ?? '',
              'description': product.description,
              'category': product.category?.name,
              'shopId': _currentShop?.id,
              'preparation_time': product.cookingTime,
              'portions': product.portions?.map((p) => p.toJson()).toList(),
              'sizes': product.sizes,
              'colors': product.colors,
              'material': product.material,
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
      backgroundColor: Colors.white,
      body: Stack(
        
        children: [
          // Contenu scrollable
          Column(
            children: [
              // Espace pour le header et la carte boutique
              const SizedBox(height: 220),

              // Zone filtres — fond blanc avec bord supérieur arrondi
              Container(
                decoration: const BoxDecoration(
                  color: Colors.white,
                ),
                padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
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
                                  'description': p.description,
                                  'price': p.price,
                                  'oldPrice': p.comparePrice,
                                  'discount': p.discountPercentage,
                                  'stock': p.stockQuantity,
                                  'isAvailable': p.isAvailable,
                                  'image': p.primaryImageUrl,
                                  'category': p.category?.name,
                                  'cooking_time': p.cookingTime,
                                  'sizes': p.sizes,
                                  'colors': p.colors,
                                  'average_rating': p.averageRating,
                                  'rating_count': p.ratingCount,
                                })
                            .toList(),
                        onProductTap: (productMap) {
                          final product = _products.firstWhere(
                            (p) => p.id == productMap['id'],
                          );
                          _navigateToProduct(product);
                        },
                        onProductAddToCart: (productMap) {
                          final product = _products.firstWhere(
                            (p) => p.id == productMap['id'],
                          );
                          _handleAddToCart(product);
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
              onHomeTap: () {
                Navigator.pushNamedAndRemoveUntil(
                  context,
                  '/access-boutique',
                  (route) => false,
                );
              },
            ),
          ),

          // Carte d'informations boutique - Chevauche l'image
          Positioned(
            top: 110,
            left: 16,
            right: 16,
            child: BoutiqueInfoCard(
              shopId: _currentShop?.id ?? 1,
              boutiqueName: _currentShop?.name ?? 'Boutique',
              boutiqueDescription: _currentShop?.description ?? 'Bienvenue dans notre boutique',
              boutiqueLogoPath: _currentShop?.logoUrl ?? 'lib/core/assets/lop.jpeg',
              phoneNumber: _currentShop?.phone ?? '',
              averageRating: _currentShop?.averageRating ?? 0.0,
              totalReviews: _currentShop?.totalReviews ?? 0,
            ),
          ),

        ],
      ),

      // Bottom Navigation Bar
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

  // Afficher le dialog de recherche
  void _showSearchDialog() {
    HomeDialogs.showSearchDialog(
      context: context,
      currentShop: _currentShop,
      searchController: _searchController,
      products: _products.map((p) => {
        'id': p.id,
        'name': p.name,
        'price': p.price,
        'image': p.primaryImageUrl,
      }).toList(),
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

    try {
      await AuthService.ensureToken();
      final loyaltyCard = await LoyaltyService.getCardForShop(_currentShop!.id);

      if (!mounted) return;

      if (loyaltyCard != null) {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => LoyaltyCardPage(loyaltyCard: loyaltyCard),
          ),
        );
      } else {
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
