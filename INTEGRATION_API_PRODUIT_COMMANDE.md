# Intégration API - Produits, Panier et Commandes - TIKA App

## 📋 Vue d'ensemble

Ce document détaille l'intégration de l'API TIKA pour les sections:
1. **Détails Produit** - `lib/features/boutique/product/`
2. **Panier** - `lib/features/boutique/panier/` (géré localement)
3. **Commandes** - `lib/features/boutique/commande/`

---

## ✅ 1. Modèles et Services créés

### Order Model
**Fichier**: `lib/services/models/order_model.dart` ✅ CRÉÉ

**Classes**:
- `Order` - Modèle complet pour une commande
- `OrderItem` - Item d'une commande (produit, menu du jour, supplément)

**Fonctionnalités**:
- Parsing type-safe (gestion String/Int/Double)
- Support des 3 types d'items: `product_id`, `daily_menu_id`, `supplement_id`
- Tous les champs de l'API (fidélité, coupons, livraison, etc.)

### Order Service
**Fichier**: `lib/services/order_service.dart` ✅ CRÉÉ

**Méthodes**:
1. `createSimpleOrder()` - POST /orders-simple (sans authentification)
2. `trackOrder()` - GET /orders/{orderNumber}/track
3. `cancelOrder()` - POST /orders/{orderNumber}/cancel
4. `getOrders()` - GET /mobile/orders (avec authentification)

**Fonctionnalités**:
- Création de commande sans compte utilisateur
- Support device_fingerprint pour commandes anonymes
- Support coupons et programme de fidélité
- Gestion paiement Wave (redirection)

### Product Service
**Fichier**: `lib/services/product_service.dart` ✅ EXISTE DÉJÀ

**Méthodes disponibles**:
1. `getProducts()` - Liste avec filtres
2. `getProductById(id)` - Détails d'un produit ✅
3. `getFeaturedProducts()` - Produits en vedette
4. `searchProducts()` - Recherche

---

## 🔄 2. Détails Produit - Intégration API

### État actuel
**Fichier**: `lib/features/boutique/product/product_detail_screen.dart`

**Problèmes identifiés**:
- ❌ Descriptions hardcodées basées sur le nom du produit
- ❌ Catégorie hardcodée avec des règles if/else
- ❌ Pas de chargement depuis l'API
- ✅ Le produit est passé en Map depuis HomeScreen

### Ce qui doit être fait

#### Option 1: Charger depuis l'API avec l'ID
```dart
class ProductDetailScreen extends StatefulWidget {
  final int productId; // Au lieu de Map

  const ProductDetailScreen({
    required this.productId,
  });
}

class _ProductDetailScreenState extends State<ProductDetailScreen> {
  bool _isLoading = true;
  Product? _product;

  @override
  void initState() {
    super.initState();
    _loadProduct();
  }

  Future<void> _loadProduct() async {
    try {
      final product = await ProductService.getProductById(widget.productId);
      setState(() {
        _product = product;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        // Gérer l'erreur
      });
    }
  }
}
```

#### Option 2: Utiliser le Product déjà chargé (RECOMMANDÉ)
```dart
// Dans home_online_screen.dart, passer l'objet Product complet
void _navigateToProduct(Product product) {
  Navigator.push(
    context,
    MaterialPageRoute(
      builder: (context) => ProductDetailScreen(
        product: product, // Passer le Product model au lieu de Map
      ),
    ),
  );
}
```

#### Modifications à apporter
1. Remplacer `Map<String, dynamic> product` par `Product product`
2. Supprimer les méthodes `_getCategory()` et `_getDescription()`
3. Utiliser directement les propriétés du modèle:
   - `product.description` au lieu de `_getDescription()`
   - `product.category?.name` au lieu de `_getCategory()`
   - `product.primaryImageUrl` pour l'image
   - `product.portions` pour les portions
   - `product.cookingTime` pour le temps de cuisson

---

## 🛒 3. Panier - Gestion locale (OK)

### État actuel
**Fichier**: `lib/features/boutique/panier/cart_manager.dart`

**Fonctionnement**:
- ✅ Gestion locale du panier (ChangeNotifier)
- ✅ Ajout/suppression/modification de quantité
- ✅ Calcul du total
- ✅ Persistence locale avec SharedPreferences

**Conclusion**: Le panier est géré localement (standard pour les apps e-commerce), **PAS besoin de l'API ici**. Le panier est envoyé à l'API uniquement lors de la création de la commande.

---

## 📦 4. Commandes - Intégration API

### État actuel
**Fichier**: `lib/features/boutique/commande/commande_screen.dart`

**Problèmes identifiés**:
- ❌ Pas d'appel API pour créer la commande
- ❌ Données simulées
- ✅ UI complète pour la saisie des informations

### Ce qui doit être fait

#### 1. Intégrer OrderService.createSimpleOrder()
```dart
import '../../../services/order_service.dart';

// Dans commande_screen.dart
Future<void> _submitOrder() async {
  // Récupérer les items du panier
  final cartItems = CartManager().items.map((item) => {
    'product_id': item.productId,
    'quantity': item.quantity,
    'price': item.price,
  }).toList();

  try {
    final result = await OrderService.createSimpleOrder(
      shopId: _currentShop.id,
      customerName: _customerNameController.text,
      customerPhone: _customerPhoneController.text,
      customerEmail: _customerEmailController.text,
      deliveryAddress: _deliveryAddressController.text,
      serviceType: _selectedServiceType, // "Livraison à domicile", etc.
      deliveryFee: _deliveryFee,
      paymentMethod: _selectedPaymentMethod,
      notes: _notesController.text,
      items: cartItems,
    );

    if (result['wave_redirect'] == true) {
      // Rediriger vers Wave
      _launchWaveUrl(result['wave_url']);
    } else {
      // Commande créée avec succès
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => OrderTrackingPage(
            orderNumber: result['order_number'],
            customerPhone: result['customer_phone'],
          ),
        ),
      );
    }
  } catch (e) {
    // Afficher l'erreur
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Erreur: ${e.toString()}')),
    );
  }
}
```

#### 2. Ajouter le device_fingerprint
```dart
import 'package:device_info_plus/device_info_plus.dart';

Future<String> _getDeviceFingerprint() async {
  final deviceInfo = DeviceInfoPlugin();
  if (Platform.isAndroid) {
    final androidInfo = await deviceInfo.androidInfo;
    return androidInfo.id ?? 'unknown';
  } else if (Platform.isIOS) {
    final iosInfo = await deviceInfo.iosInfo;
    return iosInfo.identifierForVendor ?? 'unknown';
  }
  return 'unknown';
}

// Utiliser dans createSimpleOrder
deviceFingerprint: await _getDeviceFingerprint(),
```

#### 3. Gérer les zones de livraison
```dart
// Charger les zones de livraison depuis l'API
Future<void> _loadDeliveryZones() async {
  final zones = await ShopService.getDeliveryZones(_currentShop.id);
  setState(() {
    _deliveryZones = zones;
  });
}

// Calculer les frais de livraison
void _onDeliveryZoneSelected(DeliveryZone zone) {
  setState(() {
    _selectedDeliveryZone = zone;
    _deliveryFee = zone.fee;
  });
}
```

#### 4. Support des coupons
```dart
Future<void> _validateCoupon(String code) async {
  try {
    final coupon = await CouponService.validateCoupon(
      code: code,
      shopId: _currentShop.id,
    );

    setState(() {
      _appliedCoupon = coupon;
      _discountAmount = _calculateDiscount(coupon);
    });
  } catch (e) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Coupon invalide')),
    );
  }
}
```

---

## 📊 Structure des données API

### Créer une commande
**Endpoint**: `POST /orders-simple`

**Body minimal**:
```json
{
  "shop_id": 1,
  "customer_name": "Jean Kouassi",
  "customer_phone": "+22507123456",
  "service_type": "Livraison à domicile",
  "items": [
    {
      "product_id": 15,
      "quantity": 2,
      "price": 2500
    }
  ]
}
```

**Réponse succès**:
```json
{
  "success": true,
  "order_id": 123,
  "order_number": "TK251027ABCD",
  "customer_phone": "+22507123456",
  "total": 5000,
  "receipt_url": "https://tika-ci.com/recu/123/download",
  "receipt_view_url": "https://tika-ci.com/recu/123",
  "message": "Commande créée avec succès!"
}
```

---

## 🎯 Plan d'action recommandé

### Phase 1: Product Detail (Simple) ⚡
1. Modifier `home_online_screen.dart` pour passer l'objet `Product` complet
2. Modifier `ProductDetailScreen` pour accepter `Product` au lieu de `Map`
3. Remplacer les données hardcodées par les propriétés du modèle
4. Tester avec différents produits

### Phase 2: Commandes (Prioritaire) 🔥
1. Ajouter `device_info_plus` dans `pubspec.yaml`
2. Intégrer `OrderService.createSimpleOrder()` dans `commande_screen.dart`
3. Mapper les items du panier au format API
4. Gérer la redirection Wave si paiement mobile
5. Naviguer vers OrderTrackingPage après succès
6. Vider le panier après commande réussie

### Phase 3: Fonctionnalités avancées (Optionnel)
1. Ajouter support des coupons
2. Ajouter support de la fidélité
3. Charger et afficher les zones de livraison
4. Calculer automatiquement les frais de livraison

---

## 📝 Fichiers à modifier

### Priorité HAUTE 🔴
1. `lib/features/boutique/product/product_detail_screen.dart` - Remplacer Map par Product
2. `lib/features/boutique/home/home_online_screen.dart` - Passer Product au lieu de Map
3. `lib/features/boutique/commande/commande_screen.dart` - Intégrer OrderService

### Priorité MOYENNE 🟡
4. `lib/features/boutique/commande/order_tracking_page.dart` - Utiliser OrderService.trackOrder()
5. `lib/features/boutique/commande/orders_list_page.dart` - Charger depuis API

### Déjà fait ✅
- ✅ `lib/services/models/order_model.dart` - Modèle Order
- ✅ `lib/services/order_service.dart` - Service API commandes
- ✅ `lib/services/product_service.dart` - Service API produits (déjà existant)

---

## 🔧 Dépendances à ajouter

```yaml
# pubspec.yaml
dependencies:
  device_info_plus: ^10.0.0  # Pour device_fingerprint
```

---

## ⚠️ Points d'attention

1. **Validation des champs**: Vérifier que tous les champs requis sont remplis avant de créer la commande
2. **Gestion d'erreurs**: Afficher des messages clairs si la commande échoue (stock insuffisant, etc.)
3. **Chargement**: Afficher un indicateur de chargement pendant la création de la commande
4. **Navigation**: Vider le panier et naviguer vers le suivi après succès
5. **Paiement Wave**: Ouvrir l'URL Wave dans un navigateur externe ou WebView
6. **Images**: Utiliser la même logique `_getFullImageUrl()` que pour les autres écrans

---

**Date de création**: 19 novembre 2025
**Version**: 1.0
**Statut**: 📋 Plan créé, implémentation en cours
