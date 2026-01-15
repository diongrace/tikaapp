# Guide de Test: Décrémentation du Stock - Backend

## 🎯 Objectif

Vérifier si le stock des produits se décrémente automatiquement lors de la création d'une commande via l'API.

## ⏱️ Durée Estimée: 5 minutes

---

## 📋 Prérequis

- Accès à la base de données de préproduction
- Outil pour tester l'API (Postman, cURL, ou autre)
- URL API: `https://prepro.tika-ci.com/api`

---

## 🧪 Test 1: Vérification Basique

### Étape 1: Noter le stock actuel

Exécutez cette requête SQL pour choisir un produit et noter son stock:

```sql
-- Afficher les produits avec leur stock
SELECT id, name, stock_quantity, is_available
FROM products
WHERE shop_id = 1
  AND stock_quantity > 10
LIMIT 5;
```

**Notez les valeurs:**
- Product ID: `_____`
- Nom: `_____________________`
- Stock avant commande: `_____`

### Étape 2: Créer une commande de test

Utilisez Postman ou cURL pour créer une commande:

```bash
curl -X POST https://prepro.tika-ci.com/api/orders-simple \
  -H "Content-Type: application/json" \
  -H "Accept: application/json" \
  -d '{
    "shop_id": 1,
    "customer_name": "Test Backend",
    "customer_phone": "+22507000001",
    "service_type": "À emporter",
    "device_fingerprint": "test-backend-001",
    "payment_method": "especes",
    "items": [
      {
        "product_id": REMPLACER_PAR_ID_PRODUIT,
        "quantity": 3,
        "price": 2500
      }
    ]
  }'
```

**Réponse attendue:**
```json
{
  "success": true,
  "order_id": 123,
  "order_number": "TK251215XXXX",
  ...
}
```

### Étape 3: Vérifier le stock après

Exécutez à nouveau la requête SQL:

```sql
SELECT id, name, stock_quantity, is_available
FROM products
WHERE id = REMPLACER_PAR_ID_PRODUIT;
```

**Notez la valeur:**
- Stock après commande: `_____`

### Étape 4: Analyser le résultat

**Calcul attendu:**
```
Stock après = Stock avant - Quantité commandée
Stock après = _____ - 3 = _____
```

**Résultat du test:**
- [ ] ✅ **SUCCÈS**: Le stock a diminué correctement
- [ ] ❌ **ÉCHEC**: Le stock n'a pas changé

---

## 🧪 Test 2: Stock Épuisé

Si le Test 1 a réussi, vérifiez que `is_available` se met à `false` quand le stock atteint 0.

### Étape 1: Trouver un produit avec peu de stock

```sql
-- Produits avec stock < 5
SELECT id, name, stock_quantity, is_available
FROM products
WHERE shop_id = 1
  AND stock_quantity > 0
  AND stock_quantity < 5
LIMIT 5;
```

**Notez:**
- Product ID: `_____`
- Stock actuel: `_____`

### Étape 2: Commander tout le stock

Créez une commande qui épuise le stock:

```json
{
  "shop_id": 1,
  "customer_name": "Test Stock Zero",
  "customer_phone": "+22507000002",
  "service_type": "À emporter",
  "device_fingerprint": "test-backend-002",
  "items": [
    {
      "product_id": REMPLACER_PAR_ID_PRODUIT,
      "quantity": REMPLACER_PAR_STOCK_ACTUEL,
      "price": 2500
    }
  ]
}
```

### Étape 3: Vérifier `is_available`

```sql
SELECT id, name, stock_quantity, is_available
FROM products
WHERE id = REMPLACER_PAR_ID_PRODUIT;
```

**Résultat attendu:**
- `stock_quantity` = 0
- `is_available` = 0 (false)

**Résultat du test:**
- [ ] ✅ **SUCCÈS**: stock = 0 ET is_available = false
- [ ] ⚠️ **PARTIEL**: stock = 0 mais is_available = true (à corriger)
- [ ] ❌ **ÉCHEC**: stock inchangé

---

## 🧪 Test 3: Stock Insuffisant

Vérifier que l'API refuse une commande si le stock est insuffisant.

### Étape 1: Identifier le stock d'un produit

```sql
SELECT id, name, stock_quantity
FROM products
WHERE shop_id = 1
  AND stock_quantity > 0
  AND stock_quantity < 10
LIMIT 1;
```

**Notez:**
- Product ID: `_____`
- Stock disponible: `_____`

### Étape 2: Commander plus que le stock disponible

Tentez de commander une quantité supérieure au stock:

```json
{
  "shop_id": 1,
  "customer_name": "Test Stock Insuffisant",
  "customer_phone": "+22507000003",
  "service_type": "À emporter",
  "device_fingerprint": "test-backend-003",
  "items": [
    {
      "product_id": REMPLACER_PAR_ID_PRODUIT,
      "quantity": 999,
      "price": 2500
    }
  ]
}
```

**Résultat attendu:**
```json
{
  "success": false,
  "message": "Stock insuffisant pour [Nom du produit]"
}
```

**Code HTTP:** 400

**Résultat du test:**
- [ ] ✅ **SUCCÈS**: Erreur 400 avec message "Stock insuffisant"
- [ ] ❌ **ÉCHEC**: Commande créée malgré le stock insuffisant

---

## 📊 Tableau de Résultats

| Test | Description | Résultat | Notes |
|------|-------------|----------|-------|
| Test 1 | Décrémentation basique | ☐ Réussi ☐ Échoué | |
| Test 2 | Stock à zéro + is_available | ☐ Réussi ☐ Échoué | |
| Test 3 | Stock insuffisant | ☐ Réussi ☐ Échoué | |

---

## ✅ Diagnostic

### Si tous les tests réussissent ✅

**La décrémentation fonctionne correctement!**

Action: Vérifier côté frontend que les produits se rafraîchissent après une commande.

### Si Test 1 échoue ❌

**La décrémentation du stock n'est PAS implémentée**

Action requise:
1. Ouvrir le fichier du contrôleur de commandes (probablement `OrderController.php`)
2. Localiser la méthode qui crée les commandes (`createOrder` ou similaire)
3. Ajouter le code de décrémentation du stock (voir `STOCK_DECREMENTATION_FIX.md`)

### Si Test 2 échoue ⚠️

**La décrémentation fonctionne, mais `is_available` n'est pas mis à jour**

Action requise:
```php
// Après la décrémentation
if ($product->stock_quantity <= 0) {
    $product->stock_quantity = 0;
    $product->is_available = false;
}
$product->save();
```

### Si Test 3 échoue ❌

**La vérification du stock avant commande ne fonctionne pas**

Action requise:
```php
// AVANT de créer la commande
if ($product->stock_quantity < $requestedQuantity) {
    throw new \Exception("Stock insuffisant pour {$product->name}");
}
```

---

## 🔄 Après Correction

Une fois les corrections effectuées:

1. **Re-tester** avec les 3 tests ci-dessus
2. **Vérifier** que l'endpoint `GET /mobile/products` retourne le stock mis à jour
3. **Tester** avec l'application Flutter pour confirmer le comportement end-to-end
4. **Documenter** les changements dans le changelog de l'API

---

## 📞 Support

Si vous avez des questions ou si les tests ne se passent pas comme prévu:
1. Consultez le document `STOCK_DECREMENTATION_FIX.md`
2. Vérifiez les logs de l'API pendant la création de commande
3. Contactez l'équipe frontend pour coordination

---

**Date de création**: 15 décembre 2025
**Version**: 1.0
**Environnement**: Préproduction (prepro.tika-ci.com)
