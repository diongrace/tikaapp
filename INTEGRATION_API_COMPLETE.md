# Intégration API TIKA - Documentation Complète

## ✅ Résumé de l'intégration

L'intégration de l'API TIKA dans l'application Flutter a été complétée avec succès. L'application communique maintenant avec la base de données via les endpoints de l'API.

---

## 📦 Modèles de données créés

### 1. **Shop Model** (`lib/services/models/shop_model.dart`)
Modèle complet pour les boutiques avec :
- Informations de base (id, nom, description, catégorie)
- Localisation (adresse, ville, latitude, longitude)
- Contact (téléphone, email)
- Horaires d'ouverture
- Zones de livraison (`DeliveryZone`)
- Statistiques (`ShopStats`)
- Thème personnalisé (`ShopTheme`)

### 2. **Product Model** (`lib/services/models/product_model.dart`)
Modèle complet pour les produits avec :
- Informations de base (id, nom, description, prix)
- Stock et disponibilité
- Catégorie (`ProductCategory`)
- Images (`ProductImage`)
- Portions (`ProductPortion`)
- Calcul automatique du pourcentage de réduction

---

## 🔌 Services API créés

### 1. **ShopService** (`lib/services/shop_service.dart`)

Méthodes disponibles :

```dart
// Lister toutes les boutiques avec filtres
ShopService.getShops({category, search, latitude, longitude, radius, page})

// Récupérer une boutique par ID
ShopService.getShopById(int id)

// Récupérer une boutique par slug (QR code/lien)
ShopService.getShopBySlug(String slug)

// Récupérer une boutique via un lien complet
ShopService.getShopByLink(String url)

// Récupérer les produits d'une boutique
ShopService.getShopProducts(int shopId, {categoryId, search, inStock, sortBy, page})

// Récupérer les catégories d'une boutique
ShopService.getShopCategories(int shopId)

// Récupérer les boutiques en vedette
ShopService.getFeaturedShops()
```

### 2. **ProductService** (`lib/services/product_service.dart`)

Méthodes disponibles :

```dart
// Lister tous les produits avec filtres
ProductService.getProducts({shopId, categoryId, search, inStock, sortBy, page})

// Détails d'un produit
ProductService.getProductById(int id)

// Produits en vedette
ProductService.getFeaturedProducts({shopId})

// Recherche de produits
ProductService.searchProducts(String query, {shopId, page})
```

---

## 🎨 Écrans mis à jour

### 1. **HomeScreen** (`lib/features/boutique/home/home_online_screen.dart`)

#### Nouvelles fonctionnalités :
- ✅ Accepte un `shopId` ou un objet `Shop` en paramètre
- ✅ Charge automatiquement les données de la boutique depuis l'API
- ✅ Charge les produits et catégories de la boutique
- ✅ Affiche un indicateur de chargement pendant le chargement
- ✅ Gère les erreurs avec message d'erreur et bouton "Réessayer"
- ✅ Affiche un message si aucun produit n'est disponible
- ✅ Utilise les vraies données de la boutique (nom, description, logo, téléphone)

#### Utilisation :
```dart
// Avec un objet Shop
Navigator.push(
  context,
  MaterialPageRoute(
    builder: (context) => HomeScreen(shop: shop),
  ),
);

// Avec un shopId
Navigator.push(
  context,
  MaterialPageRoute(
    builder: (context) => HomeScreen(shopId: 1),
  ),
);
```

### 2. **QrScannerScreen** (`lib/features/qr_scanner/qr_scanner_screen.dart`)

#### Fonctionnalités :
- ✅ Scanne le QR code et récupère le slug de la boutique
- ✅ Appelle l'API pour récupérer les données de la boutique via `ShopService.getShopBySlug()`
- ✅ Navigue automatiquement vers `HomeScreen` avec les données de la boutique
- ✅ Gère les erreurs avec messages appropriés

#### Flux :
1. Utilisateur scanne un QR code
2. App extrait le slug de la boutique
3. App appelle l'API pour récupérer la boutique
4. App navigue vers `HomeScreen` avec les données

### 3. **AccessBoutiqueScreen** (`lib/features/access_boutique/access_boutique_screen.dart`)

#### Fonctionnalités :
- ✅ Permet à l'utilisateur d'entrer un lien de boutique
- ✅ Appelle l'API pour récupérer la boutique via `ShopService.getShopByLink()`
- ✅ Navigue vers `HomeScreen` avec les données de la boutique
- ✅ Affiche un indicateur de chargement pendant la requête
- ✅ Gère les erreurs avec messages appropriés

#### Flux :
1. Utilisateur entre un lien (ex: https://tika-ci.com/boutique-chez-marie)
2. App extrait le slug et appelle l'API
3. App navigue vers `HomeScreen` avec les données

---

## 🔧 Configuration API

### Endpoints utilisés (`lib/services/utils/api_endpoint.dart`)

```dart
class Endpoints {
  static const String baseUrl = 'https://tika-ci.com/api';

  // Shops
  static const String shops = '$baseUrl/mobile/shops';
  static String shopDetails(int id) => '$baseUrl/mobile/shops/$id';
  static String shopSlug(String slug) => '$baseUrl/mobile/shops/slug/$slug';
  static String shopProducts(int id) => '$baseUrl/mobile/shops/$id/products';
}
```

---

## 📱 Flux de navigation complet

### 1. **Via QR Code**
```
SplashScreen → WelcomeScreen → OnboardingScreens → AccessBoutiqueScreen
                                                              ↓
                                                    [Scanner QR Code]
                                                              ↓
                                                    QrScannerScreen
                                                              ↓
                                               [Scan QR → Récupère slug]
                                                              ↓
                                          API: ShopService.getShopBySlug()
                                                              ↓
                                          HomeScreen(shop: shopData)
                                                              ↓
                                    [Affiche produits de la boutique]
```

### 2. **Via Lien**
```
AccessBoutiqueScreen → [Entre le lien] → API: ShopService.getShopByLink()
                                                              ↓
                                          HomeScreen(shop: shopData)
                                                              ↓
                                    [Affiche produits de la boutique]
```

---

## 🎯 Prochaines étapes recommandées

### APIs à intégrer :

1. **API Orders** (Commandes)
   - Créer une commande
   - Suivre une commande
   - Historique des commandes

2. **API Payments** (Paiements)
   - Intégrer Mobile Money
   - Intégrer Wave
   - Intégrer CinetPay

3. **API Loyalty** (Fidélité)
   - Créer une carte de fidélité
   - Gérer les points
   - Récompenses

4. **API Favorites** (Favoris)
   - Ajouter/Retirer des favoris
   - Lister les boutiques favorites

5. **API Auth** (Authentification)
   - Register
   - Login
   - Logout
   - Gestion de profil

---

## 🐛 Debugging

### Tester l'intégration :

1. **Vérifier la connexion API** :
```bash
curl https://tika-ci.com/api/mobile/shops
```

2. **Tester avec un slug spécifique** :
```bash
curl https://tika-ci.com/api/mobile/shops/slug/boutique-chez-marie
```

3. **Vérifier les logs Flutter** :
```bash
flutter logs
```

### Erreurs communes :

- **"Boutique introuvable"** : Le slug n'existe pas dans la BD
- **"Erreur lors du chargement"** : Problème de connexion réseau ou API down
- **"Lien invalide"** : Le format du lien n'est pas valide

---

## 📚 Documentation API utilisée

Tous les endpoints sont documentés dans :
- `c:\Users\LENOVO\Downloads\docs-api-flutter\docs-api-flutter\05-API-SHOPS.md`

---

## ✨ Résultat final

L'application communique maintenant avec la vraie base de données via l'API REST. Les utilisateurs peuvent :

✅ Scanner un QR code pour accéder à une boutique
✅ Entrer un lien pour accéder à une boutique
✅ Voir les vraies données de la boutique (nom, description, logo)
✅ Voir les vrais produits de la boutique
✅ Filtrer les produits par catégorie
✅ Voir les détails d'un produit

**L'intégration backend est complète et fonctionnelle !** 🎉

---

**Dernière mise à jour** : 19 novembre 2025
**Version** : 1.0
