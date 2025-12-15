# Intégration API - Programme de Fidélité - TIKA App

## 📋 Vue d'ensemble

Ce document détaille l'intégration de l'API TIKA pour le programme de fidélité:
- Création de carte de fidélité
- Consultation du solde de points
- Calcul de réduction
- Historique des transactions

---

## ✅ Modèles et Services créés

### LoyaltyCard Model
**Fichier**: `lib/services/models/loyalty_card_model.dart` ✅ CRÉÉ

**Classes**:
- `LoyaltyCard` - Modèle complet pour une carte de fidélité
- `LoyaltyDiscount` - Modèle pour le calcul de réduction
- `LoyaltyTransaction` - Modèle pour l'historique des transactions

**Fonctionnalités**:
- Parsing type-safe (gestion String/Int/Double)
- Tous les champs de l'API (points, récompenses, statut, etc.)

### Loyalty Service
**Fichier**: `lib/services/loyalty_service.dart` ✅ CRÉÉ

**Méthodes**:
1. `createCard()` - POST /loyalty/cards (créer une carte)
2. `getCard()` - GET /loyalty/shops/{shopId}?phone={phone} (récupérer une carte)
3. `calculateDiscount()` - POST /loyalty/calculate-discount (calculer réduction)
4. `getHistory()` - GET /mobile/loyalty/history (historique avec authentification)
5. `hasCard()` - Helper pour vérifier si une carte existe

---

## 🔄 Intégration dans les écrans

### 1. CreateLoyaltyCardPage

**Fichier actuel**: `lib/features/boutique/loyalty/create_loyalty_card_page.dart`

**Problèmes identifiés**:
- ❌ Génération locale du cardId
- ❌ Pas d'appel API
- ❌ Navigation directe sans vérification

**Modifications à apporter**:

```dart
import '../../../services/loyalty_service.dart';
import '../../../services/models/loyalty_card_model.dart';

class _CreateLoyaltyCardPageState extends State<CreateLoyaltyCardPage> {
  // Ajouter un état de chargement
  bool _isLoading = false;
  int? _shopId; // Récupérer depuis BoutiqueContext ou widget

  // Modifier la méthode _createCard
  Future<void> _createCard() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      // Appeler l'API pour créer la carte
      final loyaltyCard = await LoyaltyService.createCard(
        shopId: _shopId!,
        phone: _phoneController.text,
        customerName: '${_firstNameController.text} ${_lastNameController.text}',
        email: _emailController.text.isNotEmpty ? _emailController.text : null,
        pinCode: _pinController.text.isNotEmpty ? _pinController.text : null,
      );

      if (!mounted) return;

      // Sauvegarder la carte localement (optionnel)
      await _saveLoyaltyCardLocally(loyaltyCard);

      // Naviguer vers la page de carte avec les données de l'API
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (context) => LoyaltyCardPage(
            loyaltyCard: loyaltyCard, // Passer l'objet complet
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString()),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  // Sauvegarder localement avec StorageService
  Future<void> _saveLoyaltyCardLocally(LoyaltyCard card) async {
    await StorageService.saveLoyaltyCard({
      'id': card.id,
      'cardId': card.cardNumber,
      'firstName': card.customerName.split(' ').first,
      'lastName': card.customerName.split(' ').last,
      'phone': card.phone,
      'email': card.email,
      'boutiqueName': card.shopName,
      'points': card.points,
      'rewards': 0, // Ou calculer depuis total_points_earned
    });
  }
}
```

**UI - Ajouter indicateur de chargement**:
```dart
ElevatedButton(
  onPressed: _isLoading ? null : _createCard,
  child: _isLoading
      ? const SizedBox(
          width: 20,
          height: 20,
          child: CircularProgressIndicator(strokeWidth: 2),
        )
      : const Text('Créer ma carte'),
)
```

---

### 2. LoyaltyCardPage

**Fichier actuel**: `lib/features/boutique/loyalty/loyalty_card_page.dart`

**Problèmes identifiés**:
- ❌ Affiche des données passées en paramètres
- ❌ Pas de rechargement depuis l'API
- ❌ Points statiques

**Modifications à apporter**:

#### Option 1: Passer l'objet LoyaltyCard complet (RECOMMANDÉ)
```dart
class LoyaltyCardPage extends StatefulWidget {
  final LoyaltyCard loyaltyCard;

  const LoyaltyCardPage({
    super.key,
    required this.loyaltyCard,
  });
}

class _LoyaltyCardPageState extends State<LoyaltyCardPage> {
  late LoyaltyCard _card;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _card = widget.loyaltyCard;
    _refreshCard();
  }

  // Recharger les données depuis l'API
  Future<void> _refreshCard() async {
    setState(() => _isLoading = true);

    try {
      final updatedCard = await LoyaltyService.getCard(
        shopId: _card.shopId,
        phone: _card.phone,
      );

      if (updatedCard != null) {
        setState(() => _card = updatedCard);
        // Mettre à jour le stockage local
        await _updateLocalStorage(updatedCard);
      }
    } catch (e) {
      print('Erreur de rafraîchissement: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: RefreshIndicator(
        onRefresh: _refreshCard,
        child: Stack(
          children: [
            // UI existante avec _card.points, _card.cardNumber, etc.
            SingleChildScrollView(
              child: Column(
                children: [
                  // Afficher les données de _card
                  Text('${_card.points} points'),
                  Text(_card.cardNumber),
                  Text(_card.customerName),
                  // ...
                ],
              ),
            ),
            // Indicateur de chargement
            if (_isLoading)
              Container(
                color: Colors.black.withOpacity(0.3),
                child: const Center(child: CircularProgressIndicator()),
              ),
          ],
        ),
      ),
    );
  }
}
```

#### Option 2: Charger depuis l'API avec phone + shopId
```dart
class LoyaltyCardPage extends StatefulWidget {
  final int shopId;
  final String phone;

  const LoyaltyCardPage({
    required this.shopId,
    required this.phone,
  });
}

class _LoyaltyCardPageState extends State<LoyaltyCardPage> {
  LoyaltyCard? _card;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadCard();
  }

  Future<void> _loadCard() async {
    try {
      final card = await LoyaltyService.getCard(
        shopId: widget.shopId,
        phone: widget.phone,
      );

      setState(() {
        _card = card;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      // Afficher erreur
    }
  }
}
```

---

### 3. BoutiqueInfoCard - Vérifier existence de carte

**Fichier**: `lib/features/boutique/home/widgets/boutique_info_card.dart`

**Modification du bouton "Carte fidélité"**:
```dart
OutlinedButton.icon(
  onPressed: () async {
    // Récupérer le numéro de téléphone (depuis SharedPreferences ou formulaire)
    final phone = await _getPhoneNumber();

    if (phone == null) {
      // Demander le numéro de téléphone
      _showPhoneDialog();
      return;
    }

    // Vérifier si une carte existe
    final hasCard = await LoyaltyService.hasCard(
      shopId: _currentShop.id,
      phone: phone,
    );

    if (!context.mounted) return;

    if (hasCard) {
      // Charger et afficher la carte
      final card = await LoyaltyService.getCard(
        shopId: _currentShop.id,
        phone: phone,
      );

      if (card != null && context.mounted) {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => LoyaltyCardPage(
              loyaltyCard: card,
            ),
          ),
        );
      }
    } else {
      // Aller vers création de carte
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => CreateLoyaltyCardPage(
            shopId: _currentShop.id,
            boutiqueName: _currentShop.name,
          ),
        ),
      );
    }
  },
  icon: const Icon(Icons.credit_card, size: 16),
  label: Text('Carte fidélité'),
)
```

---

### 4. CommandeScreen - Utiliser les points

**Fichier**: `lib/features/boutique/commande/commande_screen.dart`

**Ajouter section fidélité**:
```dart
class _CommandeScreenState extends State<CommandeScreen> {
  LoyaltyCard? _loyaltyCard;
  int? _pointsToUse;
  double? _loyaltyDiscount;

  // Charger la carte de fidélité au démarrage
  @override
  void initState() {
    super.initState();
    _loadLoyaltyCard();
  }

  Future<void> _loadLoyaltyCard() async {
    final phone = await _getCustomerPhone();
    if (phone == null) return;

    try {
      final card = await LoyaltyService.getCard(
        shopId: _currentShop.id,
        phone: phone,
      );

      setState(() => _loyaltyCard = card);
    } catch (e) {
      print('Pas de carte fidélité: $e');
    }
  }

  // Calculer la réduction avec les points
  Future<void> _applyLoyaltyPoints(int points) async {
    if (_loyaltyCard == null) return;

    try {
      final discount = await LoyaltyService.calculateDiscount(
        loyaltyCardId: _loyaltyCard!.id,
        pointsToUse: points,
        orderAmount: _totalAmount,
      );

      setState(() {
        _pointsToUse = discount.pointsToUse;
        _loyaltyDiscount = discount.discountAmount;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Réduction de ${discount.discountAmount} FCFA appliquée!',
          ),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
    }
  }

  // UI - Afficher section fidélité
  Widget _buildLoyaltySection() {
    if (_loyaltyCard == null) return const SizedBox.shrink();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Carte de fidélité'),
            Text('${_loyaltyCard!.points} points disponibles'),
            if (_loyaltyCard!.points > 0) ...[
              TextFormField(
                decoration: InputDecoration(
                  labelText: 'Points à utiliser',
                  helperText: '1 point = 5 FCFA',
                ),
                keyboardType: TextInputType.number,
                onChanged: (value) {
                  final points = int.tryParse(value);
                  if (points != null && points > 0) {
                    _applyLoyaltyPoints(points);
                  }
                },
              ),
            ],
            if (_loyaltyDiscount != null) ...[
              Text('Réduction: $_loyaltyDiscount FCFA'),
            ],
          ],
        ),
      ),
    );
  }

  // Lors de la création de commande, inclure les points
  Future<void> _submitOrder() async {
    // ... code existant ...

    final result = await OrderService.createSimpleOrder(
      // ... autres paramètres ...
      loyaltyCardId: _loyaltyCard?.id,
      loyaltyPointsUsed: _pointsToUse,
      loyaltyDiscount: _loyaltyDiscount,
      items: cartItems,
    );
  }
}
```

---

## 📊 Résumé des endpoints utilisés

| Méthode | Endpoint | Usage |
|---------|----------|-------|
| POST | `/loyalty/cards` | Créer une carte |
| GET | `/loyalty/shops/{shopId}?phone={phone}` | Récupérer une carte |
| POST | `/loyalty/calculate-discount` | Calculer réduction |
| GET | `/mobile/loyalty/history` | Historique (authentifié) |

---

## 🎯 Plan d'action

### Phase 1: Services et Modèles ✅
1. ✅ Créer LoyaltyCard, LoyaltyDiscount, LoyaltyTransaction models
2. ✅ Créer LoyaltyService avec tous les endpoints
3. ⏳ Ajouter endpoints dans api_endpoint.dart

### Phase 2: Intégration dans les écrans
1. Modifier CreateLoyaltyCardPage pour appeler l'API
2. Modifier LoyaltyCardPage pour charger depuis l'API
3. Ajouter vérification de carte dans BoutiqueInfoCard
4. Intégrer utilisation des points dans CommandeScreen

### Phase 3: Fonctionnalités avancées (Optionnel)
1. Historique des transactions fidélité
2. Notifications lors de gain/utilisation de points
3. Code PIN pour sécuriser la carte

---

## 📝 Fichiers à créer/modifier

### Créés ✅
- ✅ `lib/services/models/loyalty_card_model.dart`
- ✅ `lib/services/loyalty_service.dart`

### À modifier
1. `lib/features/boutique/loyalty/create_loyalty_card_page.dart` - Intégrer API
2. `lib/features/boutique/loyalty/loyalty_card_page.dart` - Charger depuis API
3. `lib/features/boutique/home/widgets/boutique_info_card.dart` - Vérifier carte
4. `lib/features/boutique/commande/commande_screen.dart` - Utiliser points

---

## ⚠️ Points d'attention

1. **Numéro de téléphone**: Centraliser la gestion du numéro de téléphone (SharedPreferences)
2. **Validation**: Valider le format du téléphone (+225...)
3. **Code PIN**: Si implémenté, demander lors de l'utilisation des points
4. **Rechargement**: Rafraîchir les points après chaque commande
5. **Erreurs**: Gérer le cas "carte déjà existante" gracieusement

---

**Date de création**: 19 novembre 2025
**Version**: 1.0
**Statut**: 📋 Services créés, intégration en attente
