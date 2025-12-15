# Guide d'Intégration des Services API TIKA

Ce guide vous aide à intégrer les services API dans votre application Flutter TIKA.

## 📦 Étape 1 : Ajouter les dépendances

Modifiez votre `pubspec.yaml` :

```yaml
dependencies:
  flutter:
    sdk: flutter

  # HTTP client
  http: ^1.1.0

  # Device info (pour device_fingerprint)
  device_info_plus: ^9.1.0

  # Storage local
  shared_preferences: ^2.2.2

  # URL launcher (pour les paiements)
  url_launcher: ^6.2.0

  # QR Code scanner (déjà présent)
  mobile_scanner: ^3.5.5

  # Google Fonts (déjà présent)
  google_fonts: ^6.1.0
```

Puis exécutez :
```bash
flutter pub get
```

## 🏗️ Étape 2 : Structure des Services

Tous les services sont dans `lib/services/` :

```
services/
├── models/                    # Modèles de données
│   ├── shop.dart             # Boutique
│   ├── product.dart          # Produit
│   ├── category.dart         # Catégorie
│   ├── order.dart            # Commande
│   ├── coupon.dart           # Coupon
│   ├── delivery_zone.dart    # Zone de livraison
│   ├── loyalty_card.dart     # Carte de fidélité
│   ├── payment.dart          # Paiement
│   └── api_response.dart     # Réponse API générique
│
├── utils/                     # Utilitaires
│   ├── endpoints.dart        # URLs des endpoints
│   ├── device_helper.dart    # Helper pour device info
│   └── storage_helper.dart   # Helper pour stockage local
│
├── api_service.dart          # Service HTTP de base
├── shop_service.dart         # Service boutiques
├── product_service.dart      # Service produits
├── order_service.dart        # Service commandes
├── coupon_service.dart       # Service coupons
├── delivery_service.dart     # Service livraison
├── loyalty_service.dart      # Service fidélité
├── payment_service.dart      # Service paiements
├── category_service.dart     # Service catégories
└── services.dart             # Export global
```

## 🎯 Étape 3 : Intégration par écran

### A. QR Scanner Screen → Home Online Screen

**Fichier :** `lib/features/qr_scanner/qr_scanner_screen.dart`

```dart
import 'package:tika_app/services/services.dart';

void _onBarcodeDetect(BarcodeCapture barcodeCapture) {
  // ... code existant ...

  final String? code = barcodes.first.rawValue;
  if (code == null) return;

  // Parser le QR code pour extraire shop_id ou slug
  // Format attendu: "https://tika-ci.com/shop/123" ou "shop-slug"

  String? shopIdentifier = _extractShopIdentifier(code);

  if (shopIdentifier != null) {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => HomeOnlineScreen(
          shopIdentifier: shopIdentifier,
        ),
      ),
    );
  }
}

String? _extractShopIdentifier(String qrCode) {
  // Si c'est une URL complète
  if (qrCode.startsWith('http')) {
    final uri = Uri.parse(qrCode);
    final segments = uri.pathSegments;

    // Chercher après /shop/
    if (segments.contains('shop') && segments.length > segments.indexOf('shop') + 1) {
      return segments[segments.indexOf('shop') + 1];
    }
  }

  // Sinon, considérer que c'est directement l'ID ou le slug
  return qrCode;
}
```

### B. Home Online Screen - Charger les données de la boutique

**Fichier :** `lib/features/boutique/home/home_online_screen.dart`

```dart
import 'package:tika_app/services/services.dart';
import 'package:tika_app/services/utils/device_helper.dart';
import 'package:tika_app/services/utils/storage_helper.dart';

class HomeOnlineScreen extends StatefulWidget {
  final String shopIdentifier; // ID ou slug

  const HomeOnlineScreen({
    super.key,
    required this.shopIdentifier,
  });

  @override
  State<HomeOnlineScreen> createState() => _HomeOnlineScreenState();
}

class _HomeOnlineScreenState extends State<HomeOnlineScreen> {
  // Services
  final ShopService _shopService = ShopService();
  final CategoryService _categoryService = CategoryService();

  // État
  Shop? _shop;
  List<Product> _products = [];
  List<Category> _categories = [];
  bool _isLoading = true;
  bool _isFavorite = false;

  // Filtres
  String _selectedCategory = "Toutes catégories";
  int? _selectedCategoryId;
  String _searchQuery = "";

  @override
  void initState() {
    super.initState();
    _loadShopData();
    _checkIfFavorite();
  }

  Future<void> _loadShopData() async {
    setState(() => _isLoading = true);

    try {
      // 1. Charger la boutique
      ApiResponse<Shop> shopResponse;

      // Essayer par ID d'abord
      if (int.tryParse(widget.shopIdentifier) != null) {
        shopResponse = await _shopService.getShopById(
          int.parse(widget.shopIdentifier)
        );
      } else {
        // Sinon par slug
        shopResponse = await _shopService.getShopBySlug(
          widget.shopIdentifier
        );
      }

      if (shopResponse.success && shopResponse.data != null) {
        _shop = shopResponse.data!;

        // Ajouter aux boutiques récentes
        await StorageHelper.addRecentShop(_shop!.id);

        // 2. Charger les catégories
        final categoriesResponse = await _shopService.getShopCategories(_shop!.id);
        if (categoriesResponse.success && categoriesResponse.data != null) {
          _categories = categoriesResponse.data!;
        }

        // 3. Charger les produits
        await _loadProducts();
      } else {
        _showError(shopResponse.message ?? 'Boutique introuvable');
      }
    } catch (e) {
      _showError('Erreur de connexion: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _loadProducts() async {
    if (_shop == null) return;

    final response = await _shopService.getShopProducts(
      _shop!.id,
      categoryId: _selectedCategoryId,
      search: _searchQuery.isEmpty ? null : _searchQuery,
    );

    if (response.success && response.data != null) {
      setState(() {
        _products = response.data!;
      });
    }
  }

  Future<void> _checkIfFavorite() async {
    if (_shop != null) {
      final isFav = await StorageHelper.isFavoriteShop(_shop!.id);
      setState(() {
        _isFavorite = isFav;
      });
    }
  }

  Future<void> _toggleFavorite() async {
    if (_shop == null) return;

    if (_isFavorite) {
      await StorageHelper.removeFavoriteShop(_shop!.id);
      await _shopService.removeFromFavorites(_shop!.id);
    } else {
      await StorageHelper.addFavoriteShop(_shop!.id);
      await _shopService.addToFavorites(_shop!.id);
    }

    setState(() {
      _isFavorite = !_isFavorite;
    });
  }

  void _onCategoryChanged(String categoryName) {
    setState(() {
      _selectedCategory = categoryName;

      if (categoryName == "Toutes catégories") {
        _selectedCategoryId = null;
      } else {
        final category = _categories.firstWhere(
          (cat) => cat.name == categoryName,
          orElse: () => _categories.first,
        );
        _selectedCategoryId = category.id;
      }
    });

    _loadProducts();
  }

  void _onSearchChanged(String query) {
    setState(() {
      _searchQuery = query;
    });
    _loadProducts();
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        body: Center(
          child: CircularProgressIndicator(
            color: Color(0xFF9C27B0),
          ),
        ),
      );
    }

    if (_shop == null) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 64, color: Colors.grey),
              SizedBox(height: 16),
              Text('Boutique introuvable'),
              SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => Navigator.pop(context),
                child: Text('Retour'),
              ),
            ],
          ),
        ),
      );
    }

    // Reste de votre UI existante...
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      body: Stack(
        children: [
          Column(
            children: [
              const SizedBox(height: 370),

              // Search & Filters
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  children: [
                    SearchBarWidget(onSearchChanged: _onSearchChanged),
                    const SizedBox(height: 12),
                    CategoryFilterWidget(
                      categories: _categories.map((c) => c.name).toList(),
                      selectedCategory: _selectedCategory,
                      onCategoryChanged: _onCategoryChanged,
                    ),
                  ],
                ),
              ),

              // Products Grid
              Expanded(
                child: _products.isEmpty
                    ? Center(child: Text('Aucun produit disponible'))
                    : ProductGrid(
                        products: _products,
                        onProductTap: _navigateToProduct,
                      ),
              ),
            ],
          ),

          // Header
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: HomeHeader(
              isFavorite: _isFavorite,
              onFavoriteToggle: _toggleFavorite,
              onBackPressed: () => Navigator.pop(context),
            ),
          ),

          // Boutique Info Card
          Positioned(
            top: 120,
            left: 24,
            right: 24,
            child: BoutiqueInfoCard(
              boutiqueName: _shop!.name,
              boutiqueDescription: _shop!.description ?? '',
              boutiqueLogoPath: _shop!.logoUrl,
              phoneNumber: _shop!.phoneNumber ?? '',
            ),
          ),
        ],
      ),
      bottomNavigationBar: _buildBottomNav(),
    );
  }
}
```

### C. Product Detail Screen - Charger les détails

**Fichier :** `lib/features/boutique/product/product_detail_screen.dart`

```dart
import 'package:tika_app/services/services.dart';

class ProductDetailScreen extends StatefulWidget {
  final int productId; // Passer l'ID au lieu de l'objet complet

  const ProductDetailScreen({
    super.key,
    required this.productId,
  });

  @override
  State<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen> {
  final ProductService _productService = ProductService();
  Product? _product;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadProduct();
  }

  Future<void> _loadProduct() async {
    setState(() => _isLoading = true);

    final response = await _productService.getProductById(widget.productId);

    if (response.success && response.data != null) {
      setState(() {
        _product = response.data!;
      });
    }

    setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (_product == null) {
      return Scaffold(
        body: Center(child: Text('Produit introuvable')),
      );
    }

    // Votre UI existante avec _product
    return Scaffold(
      // ...
    );
  }
}
```

### D. Commande Screen - Créer une commande

**Fichier :** `lib/features/boutique/commande/commande_screen.dart`

```dart
import 'package:tika_app/services/services.dart';
import 'package:tika_app/services/utils/device_helper.dart';

Future<void> _createOrder() async {
  if (!_formKey.currentState!.validate()) return;

  setState(() => _isSubmitting = true);

  try {
    // 1. Obtenir le device fingerprint
    final deviceFingerprint = await DeviceHelper.getDeviceFingerprint();

    // 2. Préparer les items de la commande
    final items = _cartManager.items.map((item) => {
      'product_id': item.productId,
      'product_name': item.name,
      'quantity': item.quantity,
      'unit_price': item.price,
      'total': item.quantity * item.price,
      if (item.variation != null) 'variation': item.variation,
    }).toList();

    // 3. Créer la commande
    final orderService = OrderService();
    final response = await orderService.createSimpleOrder(
      shopId: widget.shopId,
      customerName: _nameController.text,
      customerPhone: _phoneController.text,
      customerEmail: _emailController.text.isEmpty ? null : _emailController.text,
      deliveryAddress: _addressController.text,
      deliveryZoneId: _selectedDeliveryZone?.id,
      deviceFingerprint: deviceFingerprint,
      items: items,
      subtotal: _subtotal,
      deliveryFee: _deliveryFee,
      discount: _discount,
      total: _total,
      paymentMethod: _selectedPaymentMethod, // 'cash', 'wave', 'cinetpay'
      couponCode: _couponCode,
      notes: _notesController.text.isEmpty ? null : _notesController.text,
    );

    if (response.success && response.data != null) {
      final order = response.data!;

      // Vider le panier
      _cartManager.clear();

      // Si paiement mobile (Wave/CinetPay)
      if (order.paymentUrl != null) {
        // Ouvrir l'URL de paiement
        await launchUrl(Uri.parse(order.paymentUrl!));

        // Naviguer vers la page de confirmation
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => PaymentConfirmationPage(
              order: order,
            ),
          ),
        );
      } else {
        // Paiement cash - afficher le succès
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => LoadingSuccessPage(
              orderNumber: order.orderNumber,
            ),
          ),
        );
      }
    } else {
      _showError(response.message ?? 'Erreur lors de la création de la commande');
    }
  } catch (e) {
    _showError('Erreur: $e');
  } finally {
    setState(() => _isSubmitting = false);
  }
}
```

### E. Order Tracking - Suivre une commande

**Fichier :** `lib/features/boutique/commande/order_tracking_page.dart`

```dart
import 'package:tika_app/services/services.dart';

Future<void> _trackOrder() async {
  if (!_formKey.currentState!.validate()) return;

  setState(() => _isLoading = true);

  try {
    final orderService = OrderService();
    final response = await orderService.trackOrder(
      orderNumber: _orderNumberController.text,
      customerPhone: _phoneController.text,
    );

    if (response.success && response.data != null) {
      final order = response.data!;

      // Afficher les détails de la commande
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => OrderDetailsPage(order: order),
        ),
      );
    } else {
      _showError(response.message ?? 'Commande introuvable');
    }
  } catch (e) {
    _showError('Erreur: $e');
  } finally {
    setState(() => _isLoading = false);
  }
}
```

## ✅ Checklist d'intégration

### Phase 1 - Configuration de base
- [ ] Ajouter les dépendances dans `pubspec.yaml`
- [ ] Exécuter `flutter pub get`
- [ ] Vérifier que les services sont bien importés

### Phase 2 - QR Scanner
- [ ] Modifier `qr_scanner_screen.dart` pour parser le QR et extraire shop_id
- [ ] Passer le shop_id à `HomeOnlineScreen`

### Phase 3 - Home Online Screen
- [ ] Intégrer `ShopService` pour charger la boutique
- [ ] Charger les catégories avec `getShopCategories()`
- [ ] Charger les produits avec `getShopProducts()`
- [ ] Implémenter la recherche et le filtrage
- [ ] Gérer les favoris avec `StorageHelper`

### Phase 4 - Product Detail Screen
- [ ] Charger les détails du produit avec `ProductService`
- [ ] Afficher toutes les images
- [ ] Gérer les variations (taille, couleur, etc.)

### Phase 5 - Panier & Commande
- [ ] Implémenter la validation de coupon avec `CouponService`
- [ ] Calculer les frais de livraison avec `DeliveryService`
- [ ] Créer la commande avec `OrderService.createSimpleOrder()`
- [ ] Gérer les paiements Wave/CinetPay

### Phase 6 - Suivi de commande
- [ ] Implémenter le suivi avec `trackOrder()`
- [ ] Afficher la timeline de la commande
- [ ] Récupérer l'historique avec `getOrdersByDevice()`

### Phase 7 - Fidélité
- [ ] Créer une carte de fidélité avec `LoyaltyService`
- [ ] Afficher les points disponibles
- [ ] Appliquer les réductions fidélité

## 🔧 Configuration de l'URL de l'API

**Fichier :** `lib/services/utils/endpoints.dart`

Pour passer en mode test/production :

```dart
class ApiEndpoints {
  // PRODUCTION
  static const String currentBaseUrl = baseUrl;

  // TEST
  // static const String currentBaseUrl = baseUrlTest;
}
```

## 🐛 Debug & Tests

### Activer les logs HTTP

Les logs sont déjà activés dans `api_service.dart`. Vous verrez dans la console :
- Les URLs appelées
- Les body envoyés
- Les réponses reçues

### Tester avec Postman

Utilisez la collection fournie :
`docs-api-flutter/TIKA-API-FLUTTER.postman_collection.json`

## 📞 Support

En cas de problème :
1. Vérifier les logs dans la console
2. Tester l'endpoint dans Postman
3. Vérifier que l'URL de base est correcte
4. Vérifier la connexion internet

## 🎉 Prêt !

Votre application est maintenant prête à communiquer avec l'API TIKA !

Pour toute question, consultez :
- `lib/services/README.md` - Documentation des services
- `docs-api-flutter/` - Documentation de l'API
