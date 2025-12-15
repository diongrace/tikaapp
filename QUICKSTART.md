# 🚀 Démarrage Rapide - Services API TIKA

## ✅ Étape 1 : Vérifier l'installation

Les dépendances sont déjà installées. Si besoin, exécutez :
```bash
flutter pub get
```

---

## 🎯 Étape 2 : Premier test (Optionnel)

Testez que tout fonctionne dans votre `main.dart` :

```dart
import 'package:flutter/material.dart';
import 'package:tika_app/services/utils/device_helper.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Test rapide
  final deviceId = await DeviceHelper.getDeviceFingerprint();
  print('✅ Device ID: $deviceId');

  runApp(MyApp());
}
```

---

## 📱 Étape 3 : Intégrer dans vos écrans existants

### A. QR Scanner → Extraire Shop ID

**Fichier :** `lib/features/qr_scanner/qr_scanner_screen.dart`

**Ajout :**
```dart
import 'package:tika_app/services/services.dart';

// Dans _onBarcodeDetect()
void _onBarcodeDetect(BarcodeCapture barcodeCapture) {
  // ... code existant ...

  final String? code = barcodes.first.rawValue;
  if (code == null) return;

  setState(() => _isProcessing = true);

  // NOUVEAU : Parser le shop_id
  String? shopId = _extractShopId(code);

  if (shopId != null) {
    // Naviguer vers la boutique avec l'ID
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => HomeOnlineScreen(
          shopIdentifier: shopId,
        ),
      ),
    );
  }
}

// NOUVEAU : Fonction pour extraire l'ID
String? _extractShopId(String qrCode) {
  // Si URL complète : https://tika-ci.com/shop/123
  if (qrCode.startsWith('http')) {
    final uri = Uri.parse(qrCode);
    final segments = uri.pathSegments;

    if (segments.contains('shop') &&
        segments.length > segments.indexOf('shop') + 1) {
      return segments[segments.indexOf('shop') + 1];
    }
  }

  // Sinon, considérer que c'est l'ID directement
  return qrCode;
}
```

---

### B. Home Online Screen → Charger la Boutique

**Fichier :** `lib/features/boutique/home/home_online_screen.dart`

**En haut du fichier :**
```dart
import 'package:tika_app/services/services.dart';
import 'package:tika_app/services/utils/storage_helper.dart';
```

**Modifier le widget :**
```dart
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
  // NOUVEAU : Services
  final ShopService _shopService = ShopService();

  // NOUVEAU : État
  Shop? _shop;
  List<Product> _products = [];
  List<Category> _categories = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadShopData();
  }

  // NOUVEAU : Charger les données
  Future<void> _loadShopData() async {
    setState(() => _isLoading = true);

    try {
      // 1. Charger la boutique
      ApiResponse<Shop> shopResponse;

      if (int.tryParse(widget.shopIdentifier) != null) {
        // Par ID
        shopResponse = await _shopService.getShopById(
          int.parse(widget.shopIdentifier)
        );
      } else {
        // Par slug
        shopResponse = await _shopService.getShopBySlug(
          widget.shopIdentifier
        );
      }

      if (shopResponse.success && shopResponse.data != null) {
        setState(() {
          _shop = shopResponse.data!;
        });

        // 2. Charger les catégories
        final categoriesResponse =
            await _shopService.getShopCategories(_shop!.id);

        if (categoriesResponse.success) {
          setState(() {
            _categories = categoriesResponse.data ?? [];
          });
        }

        // 3. Charger les produits
        final productsResponse =
            await _shopService.getShopProducts(_shop!.id);

        if (productsResponse.success) {
          setState(() {
            _products = productsResponse.data ?? [];
          });
        }

        // Sauvegarder dans l'historique
        await StorageHelper.addRecentShop(_shop!.id);
      }
    } catch (e) {
      print('Erreur: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Afficher un loader pendant le chargement
    if (_isLoading) {
      return Scaffold(
        body: Center(
          child: CircularProgressIndicator(
            color: Color(0xFF9C27B0),
          ),
        ),
      );
    }

    // Si pas de boutique, afficher erreur
    if (_shop == null) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error, size: 64, color: Colors.grey),
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

    // Utiliser _shop, _products, _categories dans votre UI
    return Scaffold(
      // ... votre UI existante
      // Remplacer les données en dur par _shop, _products, etc.
    );
  }
}
```

---

### C. Product Detail Screen → Charger le Produit

**Fichier :** `lib/features/boutique/product/product_detail_screen.dart`

```dart
import 'package:tika_app/services/services.dart';

class ProductDetailScreen extends StatefulWidget {
  final int productId; // Passer l'ID

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

    final response = await _productService.getProductById(
      widget.productId
    );

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

    // Utiliser _product dans votre UI
    return Scaffold(
      // ... votre UI avec _product
    );
  }
}
```

---

### D. Commande Screen → Créer une Commande

**Fichier :** `lib/features/boutique/commande/commande_screen.dart`

```dart
import 'package:tika_app/services/services.dart';
import 'package:tika_app/services/utils/device_helper.dart';

// Dans votre fonction de création de commande
Future<void> _createOrder() async {
  if (!_formKey.currentState!.validate()) return;

  setState(() => _isSubmitting = true);

  try {
    // 1. Device fingerprint
    final deviceFingerprint = await DeviceHelper.getDeviceFingerprint();

    // 2. Préparer les items
    final items = _cartManager.items.map((item) => {
      'product_id': item.productId,
      'product_name': item.name,
      'quantity': item.quantity,
      'unit_price': item.price,
      'total': item.quantity * item.price,
    }).toList();

    // 3. Créer la commande
    final orderService = OrderService();
    final response = await orderService.createSimpleOrder(
      shopId: widget.shopId,
      customerName: _nameController.text,
      customerPhone: _phoneController.text,
      customerEmail: _emailController.text.isEmpty
          ? null
          : _emailController.text,
      deliveryAddress: _addressController.text,
      deviceFingerprint: deviceFingerprint,
      items: items,
      subtotal: _subtotal,
      deliveryFee: _deliveryFee,
      discount: _discount,
      total: _total,
      paymentMethod: _selectedPaymentMethod, // 'cash', 'wave', 'cinetpay'
      notes: _notesController.text.isEmpty
          ? null
          : _notesController.text,
    );

    if (response.success && response.data != null) {
      final order = response.data!;

      // Vider le panier
      _cartManager.clear();

      // Si paiement Wave/CinetPay
      if (order.paymentUrl != null) {
        // Ouvrir l'URL
        await launchUrl(Uri.parse(order.paymentUrl!));
      }

      // Naviguer vers succès
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => LoadingSuccessPage(
            orderNumber: order.orderNumber,
          ),
        ),
      );
    } else {
      _showError(response.message ?? 'Erreur lors de la création');
    }
  } catch (e) {
    _showError('Erreur: $e');
  } finally {
    setState(() => _isSubmitting = false);
  }
}

void _showError(String message) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text(message)),
  );
}
```

---

### E. Order Tracking → Suivre une Commande

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

      // Afficher les détails
      setState(() {
        _order = order;
      });
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

---

## 🎯 Fonctionnalités Bonus

### 1. Valider un Coupon

```dart
import 'package:tika_app/services/services.dart';

final couponService = CouponService();
final validation = await couponService.validateCoupon(
  code: 'PROMO10',
  shopId: shopId,
  subtotal: 5000,
);

if (validation.success && validation.data != null) {
  if (validation.data!.valid) {
    // Appliquer la réduction
    setState(() {
      discount = validation.data!.discount;
    });
  }
}
```

### 2. Calculer les Frais de Livraison

```dart
import 'package:tika_app/services/services.dart';

final deliveryService = DeliveryService();
final feeResponse = await deliveryService.calculateDeliveryFee(
  shopId: shopId,
  deliveryAddress: addressController.text,
  subtotal: subtotal,
);

if (feeResponse.success && feeResponse.data != null) {
  setState(() {
    deliveryFee = feeResponse.data!.deliveryFee;
  });
}
```

---

## 📚 Documentation Complète

- **Guide détaillé :** `INTEGRATION_GUIDE.md`
- **Documentation services :** `lib/services/README.md`
- **Structure :** `lib/services/STRUCTURE.txt`
- **Statut :** `lib/services/STATUS.md`

---

## 🐛 Problèmes Courants

### 1. "Aucune donnée reçue"
- Vérifier l'URL de l'API dans `lib/services/utils/endpoints.dart`
- Vérifier la connexion internet
- Tester l'endpoint dans Postman

### 2. "Device fingerprint null"
- Vérifier que `device_info_plus` est bien installé
- Tester : `await DeviceHelper.getDeviceFingerprint()`

### 3. "Les fichiers sont en rouge"
- Exécuter : `flutter pub get`
- Redémarrer l'IDE

---

## ✅ Checklist Finale

- [x] Dépendances installées (`flutter pub get`)
- [x] Services créés et compilent sans erreur
- [x] Documentation complète disponible
- [ ] QR Scanner extrait le shop_id
- [ ] Home Screen charge la boutique via API
- [ ] Product Detail charge le produit via API
- [ ] Commande utilise `createSimpleOrder()`
- [ ] Tracking utilise `trackOrder()`

---

**Vous êtes prêt ! Bon développement ! 🚀**
