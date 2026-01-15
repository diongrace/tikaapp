# Correction: Décrémentation du Stock lors des Commandes

## 📋 Problème Identifié

Lorsqu'un client passe une commande via la boutique en ligne, le stock des produits ne se décrémente pas automatiquement dans la base de données.

## 🔍 Analyse du Flux Actuel

### Côté Frontend (Application Flutter)

Le flux de commande fonctionne correctement:

1. **Ajout au panier** (`CartManager`)
   - Les produits sont ajoutés au panier avec leur quantité
   - Le stock est vérifié avant l'ajout (voir `lib/features/boutique/panier/cart_manager.dart:24-83`)

2. **Création de la commande** (`CommandeScreen`)
   - Les informations du client sont collectées
   - Le panier est envoyé à l'API via `OrderService.createOrder()`
   - Voir `lib/features/boutique/commande/commande_screen.dart:244-255`

3. **Rafraîchissement automatique**
   - Après une commande réussie, `CommandeScreen` retourne `true`
   - `PanierScreen` propage ce résultat
   - `HomeBottomNavigation` appelle `onProductsReload()`
   - Les produits sont rechargés depuis l'API avec le stock mis à jour
   - Voir `lib/features/boutique/home/components/home_bottom_navigation.dart:281-284`

### Côté Backend (API)

**⚠️ PROBLÈME À VÉRIFIER**: Le stock ne se décrémente pas correctement lors des commandes.

Endpoint concerné: `POST /orders-simple` et `POST /client/orders`

**📖 Documentation API Actuelle** (docs-api-flutter/08-API-ORDERS.md):

L'API VÉRIFIE déjà le stock avant de créer une commande:
```
| Code | Message | Cause |
| 400 | Stock insuffisant | Quantité demandée > stock disponible |
```

Cela signifie que l'API:
✅ Vérifie le stock avant la commande
❓ **À VÉRIFIER**: Est-ce que le stock est décrémenté APRÈS la vérification?

**Ce qui doit se passer**:
Lorsqu'une commande est créée avec succès, l'API doit:
1. **VÉRIFIER** le stock disponible (déjà implémenté ✅)
2. Créer la commande dans la base de données
3. Pour chaque item dans `items[]`:
   - Récupérer le produit par `product_id`
   - **DÉCRÉMENTER** `products.stock_quantity` de la quantité commandée
   - Si `stock_quantity = 0`, mettre `is_available = false`

## ✅ Solution Implémentée Côté Frontend

### 1. Message de rappel dans OrderService

Ajout d'un message de log dans `lib/services/order_service.dart:143-145`:

```dart
// ⚠️ IMPORTANT: L'API backend doit automatiquement décrémenter le stock
// des produits commandés. Si ce n'est pas le cas, contactez l'équipe backend.
print('⚠️ RAPPEL: Le backend doit décrémenter le stock automatiquement');
```

### 2. Rafraîchissement automatique des produits

Le mécanisme de rafraîchissement existe déjà:

**Fichier**: `lib/features/boutique/home/components/home_bottom_navigation.dart:281-284`

```dart
if (orderCompleted == true && context.mounted) {
  print('🔄 Commande réussie - Rechargement des produits...');
  onProductsReload();
}
```

Cela garantit que:
- Après chaque commande réussie, les produits sont rechargés depuis l'API
- Le stock mis à jour par le backend sera automatiquement affiché

### 3. Rafraîchissement au retour de l'app

**Fichier**: `lib/features/boutique/home/home_online_screen.dart:114-117`

```dart
if (state == AppLifecycleState.resumed) {
  print('🔄 App resumed - Rafraîchissement des produits...');
  _loadProducts();
}
```

Si l'utilisateur quitte l'app et revient, les produits sont automatiquement rafraîchis.

## 🔧 Solution Requise Côté Backend

L'équipe backend doit implémenter la logique suivante dans l'endpoint `POST /client/orders`:

### Pseudo-code PHP/Laravel

```php
// Dans OrderController.php ou OrderService.php

public function createOrder(Request $request)
{
    DB::beginTransaction();

    try {
        // 1. Créer la commande
        $order = Order::create([
            'shop_id' => $request->shop_id,
            'customer_name' => $request->customer_name,
            // ... autres champs
        ]);

        // 2. Pour chaque item, décrémenter le stock
        foreach ($request->items as $item) {
            // Créer l'item de commande
            OrderItem::create([
                'order_id' => $order->id,
                'product_id' => $item['product_id'],
                'quantity' => $item['quantity'],
                'price' => $item['price'],
            ]);

            // ⚠️ IMPORTANT: Décrémenter le stock du produit
            $product = Product::findOrFail($item['product_id']);

            // Vérifier le stock disponible
            if ($product->stock_quantity < $item['quantity']) {
                throw new \Exception("Stock insuffisant pour le produit {$product->name}");
            }

            // Décrémenter le stock
            $product->stock_quantity -= $item['quantity'];

            // Si stock épuisé, marquer comme non disponible
            if ($product->stock_quantity <= 0) {
                $product->stock_quantity = 0;
                $product->is_available = false;
            }

            $product->save();
        }

        DB::commit();

        return response()->json([
            'success' => true,
            'data' => ['order' => $order->load('items')],
            'message' => 'Commande créée avec succès'
        ]);

    } catch (\Exception $e) {
        DB::rollBack();

        return response()->json([
            'success' => false,
            'message' => $e->getMessage()
        ], 400);
    }
}
```

### Points importants

1. **Transaction de base de données**: Utiliser `DB::beginTransaction()` pour garantir l'intégrité des données
2. **Vérification du stock**: Vérifier que le stock est suffisant AVANT de créer la commande
3. **Décrémentation atomique**: Décrémenter le stock dans la même transaction
4. **Gestion des erreurs**: Si le stock est insuffisant, annuler toute la transaction

## 🔍 TEST PRIORITAIRE: Vérifier si la décrémentation fonctionne déjà

**AVANT de modifier le code backend, effectuez ce test simple:**

### Test de Décrémentation (5 minutes)

1. **Préparer un produit test**
   ```sql
   -- Dans la base de données
   SELECT id, name, stock_quantity FROM products WHERE id = 1;
   -- Exemple: Produit "Attiéké Poisson" avec stock_quantity = 100
   ```

2. **Créer une commande via l'API**
   ```bash
   curl -X POST https://prepro.tika-ci.com/api/orders-simple \
     -H "Content-Type: application/json" \
     -d '{
       "shop_id": 1,
       "customer_name": "Test Client",
       "customer_phone": "+22507000000",
       "service_type": "À emporter",
       "device_fingerprint": "test-device",
       "items": [
         {
           "product_id": 1,
           "quantity": 3,
           "price": 2500
         }
       ]
     }'
   ```

3. **Vérifier le stock après la commande**
   ```sql
   SELECT id, name, stock_quantity FROM products WHERE id = 1;
   -- Le stock devrait être: 100 - 3 = 97
   ```

### Résultats Possibles

#### ✅ Si le stock = 97
**La décrémentation fonctionne déjà!**
- Le problème vient peut-être du cache côté frontend
- Vérifier que l'endpoint `GET /mobile/products` retourne le stock mis à jour
- Pas besoin de modifier le code backend

#### ❌ Si le stock = 100 (inchangé)
**La décrémentation n'est PAS implémentée**
- Suivre les instructions dans "Solution Requise Côté Backend" ci-dessous
- Implémenter la décrémentation du stock dans `POST /orders-simple`

---

## 🧪 Tests Recommandés (après implémentation)

### Test 1: Commande simple
1. Produit A avec `stock_quantity = 10`
2. Commander 3 unités du produit A
3. Vérifier que `stock_quantity = 7` après la commande

### Test 2: Épuisement du stock
1. Produit B avec `stock_quantity = 5`
2. Commander 5 unités du produit B
3. Vérifier que:
   - `stock_quantity = 0`
   - `is_available = false`

### Test 3: Stock insuffisant
1. Produit C avec `stock_quantity = 3`
2. Tenter de commander 5 unités du produit C
3. Vérifier que:
   - La commande est refusée avec une erreur claire
   - Le stock reste inchangé (`stock_quantity = 3`)

### Test 4: Commande multiple produits
1. Produit D avec `stock_quantity = 10`
2. Produit E avec `stock_quantity = 8`
3. Commander 2x D + 3x E
4. Vérifier que:
   - D: `stock_quantity = 8`
   - E: `stock_quantity = 5`

### Test 5: Transaction rollback
1. Produit F avec `stock_quantity = 5`
2. Produit G avec `stock_quantity = 2`
3. Tenter de commander 3x F + 5x G (stock insuffisant pour G)
4. Vérifier que:
   - La commande échoue
   - Le stock de F reste à 5 (rollback)
   - Le stock de G reste à 2 (rollback)

## 📊 Impact sur les Tables

### Table `products`

Champs concernés:
- `stock_quantity` (INT) - Décrémenté à chaque commande
- `is_available` (BOOLEAN) - Mis à `false` si `stock_quantity = 0`

### Table `orders` et `order_items`

Aucune modification requise - les tables existantes sont suffisantes.

## 🔄 Flux Complet Après Correction

```
1. Client ajoute produits au panier (Flutter)
   └─> Vérification stock locale (CartManager)

2. Client finalise la commande (CommandeScreen)
   └─> Envoi à l'API: POST /client/orders

3. API traite la commande (Backend)
   ├─> Crée l'enregistrement Order
   ├─> Crée les OrderItem
   └─> ⚠️ DÉCRÉMENTE le stock_quantity de chaque produit

4. API retourne succès

5. Flutter recharge les produits (HomeBottomNavigation)
   └─> GET /client/products

6. Stock mis à jour affiché à l'utilisateur
```

## 📝 Checklist pour l'Équipe Backend

- [ ] Implémenter la décrémentation du stock dans `POST /client/orders`
- [ ] Utiliser une transaction DB pour garantir l'atomicité
- [ ] Vérifier le stock disponible avant de créer la commande
- [ ] Retourner une erreur claire si stock insuffisant
- [ ] Mettre `is_available = false` quand `stock_quantity = 0`
- [ ] Tester tous les cas (voir section Tests Recommandés)
- [ ] Documenter le comportement dans la documentation API

## 🚀 Statut

- ✅ **Frontend**: Prêt et fonctionnel (rafraîchissement automatique)
- ✅ **API - Vérification stock**: Déjà implémentée (retourne erreur si stock insuffisant)
- ❓ **API - Décrémentation stock**: **À VÉRIFIER** (voir test prioritaire ci-dessus)

### Action Immédiate

1. **Équipe Backend**: Effectuer le test prioritaire (section "TEST PRIORITAIRE" ci-dessus)
2. Si la décrémentation ne fonctionne pas, implémenter le code dans "Solution Requise Côté Backend"
3. Tester tous les cas d'usage (section "Tests Recommandés")
4. Confirmer que l'endpoint `GET /mobile/products` retourne le stock mis à jour

## 📞 Contact

Pour toute question sur cette correction, contactez l'équipe de développement.

---

**Date**: 15 décembre 2025
**Version**: 1.0
**Fichiers concernés**:
- Frontend: `lib/services/order_service.dart`, `lib/features/boutique/home/components/home_bottom_navigation.dart`
- Backend: `OrderController.php` ou équivalent
