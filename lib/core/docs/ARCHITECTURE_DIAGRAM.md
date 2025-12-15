# Diagramme d'architecture - Multi-Boutiques

## Flow utilisateur

```
┌─────────────────────────────────────────────────────────────────┐
│                        UTILISATEUR                               │
└───────────────────────────┬─────────────────────────────────────┘
                            │
                            ▼
                    ┌───────────────┐
                    │  SplashScreen │
                    └───────┬───────┘
                            │
                            ▼
                    ┌───────────────┐
                    │  Onboarding   │
                    │   (1, 2, 3)   │
                    └───────┬───────┘
                            │
                            ▼
              ┌─────────────────────────┐
              │ AccessBoutiqueScreen    │
              │                         │
              │ • Scanner QR Code       │
              │ • Entrer lien boutique  │
              └───────┬─────────────────┘
                      │
        ┌─────────────┴─────────────┐
        │                           │
        ▼                           ▼
  ┌───────────┐           ┌──────────────────┐
  │ QR Scan   │           │ Lien direct      │
  └─────┬─────┘           └────────┬─────────┘
        │                          │
        └──────────┬───────────────┘
                   │
                   ▼
        ┌──────────────────────┐
        │ BoutiqueRegistry     │
        │ .getBoutiqueByQrCode │
        │ .getBoutiqueByLink   │
        └──────────┬───────────┘
                   │
                   ▼
        ┌──────────────────────┐
        │ BoutiqueContext      │
        │ .setBoutique()       │
        └──────────┬───────────┘
                   │
                   ▼
        ┌──────────────────────┐
        │    HomeScreen        │
        │  (Adapté au type)    │
        └──────────────────────┘
```

## Architecture des composants

```
┌─────────────────────────────────────────────────────────────────────┐
│                         CORE LAYER                                   │
├─────────────────────────────────────────────────────────────────────┤
│                                                                      │
│  ┌──────────────────┐  ┌──────────────────┐  ┌─────────────────┐  │
│  │  BoutiqueType    │  │ BoutiqueConfig   │  │   BaseItem      │  │
│  │                  │  │                  │  │                 │  │
│  │  • Enum          │  │  • Config data   │  │  • Product      │  │
│  │  • Extensions    │  │  • JSON support  │  │  • Dish         │  │
│  │  • Properties    │  │  • Type ref      │  │  • Service      │  │
│  └──────────────────┘  └──────────────────┘  └─────────────────┘  │
│                                                                      │
│  ┌──────────────────┐  ┌──────────────────┐                        │
│  │ BoutiqueContext  │  │BoutiqueRegistry  │                        │
│  │                  │  │                  │                        │
│  │  • Current shop  │  │  • All shops     │                        │
│  │  • Notifier      │  │  • CRUD ops      │                        │
│  │  • Helper fns    │  │  • Lookup fns    │                        │
│  └──────────────────┘  └──────────────────┘                        │
│                                                                      │
└─────────────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────────────┐
│                      FEATURES LAYER                                  │
├─────────────────────────────────────────────────────────────────────┤
│                                                                      │
│  ┌────────────────────────────────────────────────────────────┐    │
│  │              SHARED SCREENS (Adaptables)                    │    │
│  │                                                              │    │
│  │  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐     │    │
│  │  │ HomeScreen   │  │ PanierScreen │  │ ProfileScreen│     │    │
│  │  │              │  │              │  │              │     │    │
│  │  │ Adapts to:   │  │ Adapts to:   │  │ Common for   │     │    │
│  │  │ • Product    │  │ • Items      │  │ all types    │     │    │
│  │  │ • Dish       │  │ • Services   │  │              │     │    │
│  │  │ • Service    │  │ • Orders     │  │              │     │    │
│  │  └──────────────┘  └──────────────┘  └──────────────┘     │    │
│  │                                                              │    │
│  └──────────────────────────────────────────────────────────────┘    │
│                                                                      │
│  ┌────────────────────────────────────────────────────────────┐    │
│  │              TYPE-SPECIFIC COMPONENTS                       │    │
│  │                                                              │    │
│  │  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐        │    │
│  │  │  Boutique   │  │ Restaurant  │  │   Salons    │        │    │
│  │  │  en ligne   │  │             │  │             │        │    │
│  │  │             │  │  • Dish     │  │  • Service  │        │    │
│  │  │  • Product  │  │    widgets  │  │    widgets  │        │    │
│  │  │    widgets  │  │  • Prep     │  │  • Booking  │        │    │
│  │  │  • Stock    │  │    time     │  │    system   │        │    │
│  │  │    mgmt     │  │  • Prefs    │  │  • Calendar │        │    │
│  │  └─────────────┘  └─────────────┘  └─────────────┘        │    │
│  │                                                              │    │
│  │  ┌─────────────┐                                            │    │
│  │  │Midi Express │                                            │    │
│  │  │             │                                            │    │
│  │  │  • Dish     │                                            │    │
│  │  │    widgets  │                                            │    │
│  │  │  • Express  │                                            │    │
│  │  │    badge    │                                            │    │
│  │  │  • Timer    │                                            │    │
│  │  └─────────────┘                                            │    │
│  │                                                              │    │
│  └──────────────────────────────────────────────────────────────┘    │
│                                                                      │
└─────────────────────────────────────────────────────────────────────┘
```

## Flux de données

```
┌──────────────────────────────────────────────────────────────────┐
│                        DATA FLOW                                  │
└──────────────────────────────────────────────────────────────────┘

1. INITIALISATION
   ═══════════════

   App Start
      │
      ▼
   BoutiqueRegistry.initialize()
      │
      └──> Charge les boutiques (JSON/API)


2. SÉLECTION BOUTIQUE
   ═══════════════════

   Scan QR / Click Link
      │
      ▼
   BoutiqueRegistry.getBoutiqueBy...()
      │
      ▼
   BoutiqueContext.setBoutique(config)
      │
      ▼
   notifyListeners()
      │
      ▼
   Rebuild UI with new context


3. AFFICHAGE ADAPTÉ
   ════════════════

   HomeScreen.build()
      │
      ▼
   BoutiqueContext.currentType
      │
      ├──> BoutiqueType.boutiqueEnLigne
      │    └──> Show ProductGrid
      │
      ├──> BoutiqueType.restaurant
      │    └──> Show DishGrid (with prep time)
      │
      ├──> BoutiqueType.salonBeaute
      │    └──> Show ServiceGrid (with booking)
      │
      └──> ...


4. DÉTAILS ARTICLE
   ═══════════════

   User taps item
      │
      ▼
   Check BoutiqueContext.currentType
      │
      ├──> Product → ProductDetailScreen
      ├──> Dish    → DishDetailWidget
      └──> Service → ServiceDetailWidget
```

## Structure des modèles de données

```
BaseItem (abstract)
├── id: String
├── name: String
├── description: String
├── price: int
├── imagePath: String
├── category: String
└── isAvailable: bool

    │
    ├──> Product (extends BaseItem)
    │    ├── stock: int
    │    ├── sizes: List<String>?
    │    ├── colors: List<String>?
    │    └── material: String?
    │
    ├──> Dish (extends BaseItem)
    │    ├── preparationTime: int
    │    ├── stock: int
    │    ├── preferences: List<DishPreference>
    │    ├── allergens: List<String>?
    │    └── calories: int?
    │
    └──> Service (extends BaseItem)
         ├── durationMinutes: int
         ├── specialistName: String?
         ├── difficultyLevel: int?
         └── suggestedServices: List<String>?
```

## Mapping des fonctionnalités

```
┌─────────────────┬──────────────┬──────────────┬──────────────┐
│   FEATURE       │  E-Commerce  │  Restaurant  │    Salons    │
├─────────────────┼──────────────┼──────────────┼──────────────┤
│ Item type       │  Product     │  Dish        │  Service     │
│ Main info       │  Stock       │  Prep time   │  Duration    │
│ Action button   │  Add to cart │  Add to cart │  Book        │
│ Customization   │  Size/Color  │  Prefs/Spice │  Specialist  │
│ Availability    │  Stock count │  In stock    │  Calendar    │
│ Cart label      │  Panier      │  Ma commande │  Rendez-vous │
└─────────────────┴──────────────┴──────────────┴──────────────┘
```

## Exemple de condition dans le code

```dart
// Dans HomeScreen
@override
Widget build(BuildContext context) {
  final boutiqueContext = BoutiqueContext();
  final currentType = boutiqueContext.currentType;

  return Scaffold(
    appBar: AppBar(
      title: Text(boutiqueContext.currentBoutique?.name ?? 'Tika'),
    ),
    body: Column(
      children: [
        // Header adapté
        Text('Nos ${boutiqueContext.itemsLabel}'),

        // Grille adaptée selon le type
        if (currentType == BoutiqueType.boutiqueEnLigne)
          ProductGrid(products: getProducts())
        else if (currentType == BoutiqueType.restaurant)
          DishGrid(dishes: getDishes())
        else if (currentType == BoutiqueType.salonBeaute)
          ServiceGrid(services: getServices())
        else if (currentType == BoutiqueType.salonCoiffure)
          ServiceGrid(services: getServices())
        else if (currentType == BoutiqueType.midiExpress)
          ExpressDishGrid(dishes: getExpressDishes()),
      ],
    ),
    bottomNavigationBar: BottomNav(
      cartLabel: boutiqueContext.cartLabel,
    ),
  );
}
```

## Résumé visuel

```
                    TIKA APP
                       │
        ┌──────────────┼──────────────┐
        │              │              │
        ▼              ▼              ▼
    [QR Code]     [Lien]        [Favoris]
        │              │              │
        └──────────────┼──────────────┘
                       │
                       ▼
              [BoutiqueRegistry]
                       │
                       ▼
              [BoutiqueContext]
                       │
        ┌──────────────┼──────────────┬──────────────┬──────────────┐
        │              │              │              │              │
        ▼              ▼              ▼              ▼              ▼
   [Boutique]    [Restaurant]   [S. Beauté]   [S. Coiffure]  [M. Express]
    en ligne
        │              │              │              │              │
        ▼              ▼              ▼              ▼              ▼
   [Product]      [Dish]         [Service]      [Service]      [Dish]
   + Stock      + Prep Time    + Duration     + Duration    + Express
                + Prefs        + Booking      + Booking     + Timer
```
