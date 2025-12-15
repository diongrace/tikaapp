# Guide d'intégration - Architecture Multi-Boutiques

Ce document explique comment utiliser l'architecture multi-boutiques que nous avons mise en place.

## Vue d'ensemble

L'application Tika supporte maintenant **5 types de boutiques différents** :

1. **Boutique en ligne** (déjà implémentée) - Produits physiques
2. **Restaurant** (à implémenter) - Plats avec temps de préparation
3. **Salon de beauté** (à implémenter) - Services avec rendez-vous
4. **Salon de coiffure** (à implémenter) - Services avec rendez-vous
5. **Midi Express** (à implémenter) - Restauration rapide

## Architecture créée

### 1. Modèles de données (`lib/core/models/`)

#### `boutique_type.dart`
Énumération de tous les types de boutiques avec leurs propriétés :
```dart
BoutiqueType.boutiqueEnLigne
BoutiqueType.restaurant
BoutiqueType.salonBeaute
BoutiqueType.salonCoiffure
BoutiqueType.midiExpress
```

Chaque type a des extensions pour obtenir :
- `displayName` : Nom d'affichage
- `itemLabel` : Label pour l'article (Produit/Plat/Service)
- `cartLabel` : Label du panier
- `requiresAppointment` : Si nécessite un rendez-vous
- `hasPreparationTime` : Si a un temps de préparation
- etc.

#### `boutique_config.dart`
Configuration complète d'une boutique :
- Informations de base (nom, description, logo)
- Type de boutique
- Coordonnées (téléphone, adresse, email)
- Branding (couleurs, bannière)
- Lien direct et QR code
- Configuration spécifique au type

#### `base_item.dart`
Classes abstraites et concrètes pour les articles :
- `BaseItem` : Classe de base
- `Product` : Pour boutique en ligne (stock, tailles, couleurs)
- `Dish` : Pour restaurant/midi express (temps préparation, préférences)
- `Service` : Pour salons (durée, spécialiste)

### 2. Services (`lib/core/services/`)

#### `boutique_context.dart`
Gère la boutique actuellement active :
```dart
// Définir la boutique active
BoutiqueContext().setBoutique(config);

// Obtenir des informations
BoutiqueContext().currentType;
BoutiqueContext().itemLabel; // "Produit" ou "Plat" ou "Service"
BoutiqueContext().hasPreparationTime; // true pour restaurant
```

#### `boutique_registry.dart`
Registre de toutes les boutiques disponibles :
```dart
// Récupérer toutes les boutiques
BoutiqueRegistry().getAllBoutiques();

// Récupérer par ID
BoutiqueRegistry().getBoutiqueById('shop_chicap');

// Récupérer par QR code
BoutiqueRegistry().getBoutiqueByQrCode('tika://restaurant');

// Récupérer par lien
BoutiqueRegistry().getBoutiqueByLink('https://tika.com/restaurant');
```

### 3. Structure des dossiers

```
lib/features/boutique_types/
├── boutique_en_ligne/     # Boutique en ligne (existant)
│   ├── screens/
│   ├── widgets/
│   ├── models/
│   └── README.md
├── restaurant/            # Restaurant (à implémenter)
│   ├── screens/
│   ├── widgets/
│   │   └── dish_detail_widget.dart  # Exemple créé
│   ├── models/
│   └── README.md
├── salon_beaute/          # Salon de beauté (à implémenter)
│   ├── screens/
│   ├── widgets/
│   ├── models/
│   └── README.md
├── salon_coiffure/        # Salon de coiffure (à implémenter)
│   ├── screens/
│   ├── widgets/
│   ├── models/
│   └── README.md
└── midi_express/          # Midi Express (à implémenter)
    ├── screens/
    ├── widgets/
    ├── models/
    └── README.md
```

## Comment utiliser

### 1. Initialiser le registre des boutiques

Dans votre `main.dart` ou au démarrage de l'app :
```dart
void main() {
  // Initialiser le registre des boutiques
  BoutiqueRegistry().initialize();

  runApp(MyApp());
}
```

### 2. Définir la boutique active après scan QR ou clic lien

Dans `access_boutique_screen.dart` ou `qr_scanner_screen.dart` :
```dart
// Après scan du QR code
final qrData = scannedQRCode;
final boutique = BoutiqueRegistry().getBoutiqueByQrCode(qrData);

if (boutique != null) {
  // Définir comme boutique active
  BoutiqueContext().setBoutique(boutique);

  // Naviguer vers le home
  Navigator.pushNamed(context, '/home');
}
```

### 3. Adapter les écrans selon le type de boutique

Dans `home_screen.dart` :
```dart
@override
Widget build(BuildContext context) {
  final context = BoutiqueContext();
  final type = context.currentType;

  return Scaffold(
    appBar: AppBar(
      title: Text(context.currentBoutique?.name ?? 'Tika'),
    ),
    body: Column(
      children: [
        // Label adaptatif
        Text('Nos ${context.itemsLabel}'), // "Nos Produits" ou "Nos Plats"

        // Affichage conditionnel selon le type
        if (type == BoutiqueType.restaurant)
          RestaurantProductGrid()
        else if (type == BoutiqueType.salonBeaute)
          SalonServicesGrid()
        else
          ProductGrid(),
      ],
    ),
    bottomNavigationBar: BottomNavBar(
      cartLabel: context.cartLabel, // "Panier" ou "Ma commande"
    ),
  );
}
```

### 4. Créer des widgets adaptés pour chaque type

Exemple pour un plat de restaurant :
```dart
// Utiliser le modèle Dish au lieu de Product
final dish = Dish(
  id: '1',
  name: 'Poulet Braisé',
  description: 'Délicieux poulet braisé avec accompagnement',
  price: 3500,
  preparationTime: 25, // Spécifique aux plats
  stock: 15,
  imagePath: 'assets/poulet.jpg',
  category: 'Viandes',
  preferences: [
    DishPreference.spicy,
    DishPreference.notSpicy,
    DishPreference.customRequest,
  ],
);

// Afficher avec le widget adapté
DishDetailWidget(
  dish: dish,
  onAddToCart: () {
    // Ajouter au panier avec les préférences
  },
)
```

## Étapes pour implémenter un nouveau type de boutique

### Exemple : Restaurant

1. **Lire le README** dans `lib/features/boutique_types/restaurant/README.md`

2. **Créer les écrans** dans `restaurant/screens/` :
   - `restaurant_home_screen.dart` (si différent du home classique)
   - `dish_detail_screen.dart` (adaptation du product_detail_screen)

3. **Créer les widgets** dans `restaurant/widgets/` :
   - `dish_card.dart` (carte de plat avec temps de préparation)
   - `preparation_time_badge.dart`
   - `preferences_selector.dart`

4. **Adapter le home_screen.dart existant** :
```dart
// Dans home_screen.dart
if (BoutiqueContext().currentType == BoutiqueType.restaurant) {
  // Affichage adapté pour restaurant
  products = getRestaurantDishes();
} else if (BoutiqueContext().currentType == BoutiqueType.boutiqueEnLigne) {
  // Affichage pour boutique en ligne
  products = getProducts();
}
```

5. **Adapter product_detail_screen.dart** :
```dart
// Dans product_detail_screen.dart
if (BoutiqueContext().hasPreparationTime) {
  // Afficher le temps de préparation au lieu du stock
  DishDetailWidget(dish: dish)
} else {
  // Afficher les détails produit classiques
  ProductDetailWidget(product: product)
}
```

6. **Ajouter la boutique au registre** :
Éditer `boutique_registry.dart` et ajouter votre restaurant avec ses vraies données.

## Checklist d'implémentation

### Restaurant
- [ ] Lire le cahier des charges
- [ ] Créer les données de test (plats)
- [ ] Adapter `home_screen.dart` pour afficher les plats
- [ ] Adapter `product_detail_screen.dart` pour les plats
- [ ] Créer `dish_card.dart` avec temps de préparation
- [ ] Implémenter le sélecteur de préférences
- [ ] Tester le flow complet

### Salon de beauté
- [ ] Lire le cahier des charges
- [ ] Créer le système de rendez-vous
- [ ] Créer le calendrier de disponibilités
- [ ] Adapter les écrans pour les services
- [ ] Implémenter la sélection de spécialiste
- [ ] Tester le flow complet

### Salon de coiffure
- [ ] Lire le cahier des charges
- [ ] Créer le système de rendez-vous
- [ ] Créer la galerie de styles (optionnel)
- [ ] Adapter les écrans pour les services
- [ ] Implémenter la sélection de coiffeur
- [ ] Tester le flow complet

### Midi Express
- [ ] Lire le cahier des charges
- [ ] Adapter les écrans restaurant pour le mode express
- [ ] Ajouter les badges "Express"
- [ ] Implémenter le timer de préparation
- [ ] Simplifier le processus de commande
- [ ] Tester le flow complet

## Points importants

1. **Réutilisation du code existant** : La plupart des écrans (home, panier, profil) peuvent être réutilisés avec des adaptations conditionnelles.

2. **Labels dynamiques** : Utiliser `BoutiqueContext()` pour obtenir les bons labels selon le type.

3. **Widgets spécifiques** : Créer des widgets spécifiques dans les dossiers `boutique_types/*/widgets/` pour les fonctionnalités uniques.

4. **README dans chaque dossier** : Consultez les README pour comprendre les spécificités de chaque type.

5. **Modèles de données** : Utiliser `Product`, `Dish`, ou `Service` selon le type.

## Prochaines étapes

1. Attendre le cahier des charges de chaque boutique
2. Implémenter les fonctionnalités spécifiques
3. Adapter les écrans existants
4. Tester chaque type de boutique
5. Connecter à une vraie API (remplacer `BoutiqueRegistry.initialize()`)

## Questions ?

Consultez les README dans chaque dossier `boutique_types/*/README.md` pour plus de détails sur chaque type de boutique.
