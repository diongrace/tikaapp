# 🔍 Guide de Debug - Problème Historique Commandes

## 📋 Résumé du problème

**Symptôme :** Les commandes ne s'affichent pas dans l'historique malgré leur création réussie.

**Commande test créée :**
- Order ID: 82
- Numéro: TK-01122505
- Device Fingerprint: `android_be2a.250530.026.f3_sdk_gphone64_x86_64_emu64xa`
- Téléphone: 0742656566

**Problème :** L'API `/mobile/orders/by-device` retourne 0 commandes alors que la commande vient d'être créée.

---

## 🔎 Étape 1 : Vérification en Base de Données

### A. Vérifier si la commande existe

```sql
-- Vérifier la commande créée
SELECT
    id,
    order_number,
    customer_phone,
    device_fingerprint,
    created_at
FROM orders
WHERE order_number = 'TK-01122505';
```

**Résultat attendu :**
- ✅ La commande devrait exister avec id = 82
- ⚠️ **Vérifiez si `device_fingerprint` est NULL ou vide !**

### B. Vérifier toutes les commandes avec device_fingerprint

```sql
-- Lister toutes les commandes avec un device_fingerprint
SELECT
    id,
    order_number,
    device_fingerprint,
    customer_phone,
    created_at
FROM orders
WHERE device_fingerprint IS NOT NULL
ORDER BY id DESC
LIMIT 10;
```

### C. Vérifier la structure de la table

```sql
-- Vérifier que la colonne device_fingerprint existe
DESCRIBE orders;

-- Ou pour PostgreSQL
\d orders
```

**Vérifiez que :** La colonne `device_fingerprint` existe et est de type VARCHAR ou TEXT.

---

## 🔎 Étape 2 : Vérifier le Controller Laravel

### Fichier probable : `app/Http/Controllers/OrderController.php` ou `app/Http/Controllers/Mobile/OrderController.php`

### A. Méthode `createSimpleOrder()` ou `store()`

Vérifiez que le `device_fingerprint` est bien sauvegardé :

```php
// ❌ INCORRECT - device_fingerprint manquant
public function createSimpleOrder(Request $request)
{
    $order = Order::create([
        'shop_id' => $request->shop_id,
        'customer_name' => $request->customer_name,
        'customer_phone' => $request->customer_phone,
        // ... autres champs
        // ⚠️ device_fingerprint est oublié !
    ]);
}

// ✅ CORRECT - device_fingerprint sauvegardé
public function createSimpleOrder(Request $request)
{
    $order = Order::create([
        'shop_id' => $request->shop_id,
        'customer_name' => $request->customer_name,
        'customer_phone' => $request->customer_phone,
        'device_fingerprint' => $request->device_fingerprint, // ✅ Ajouté
        // ... autres champs
    ]);
}
```

### B. Méthode `getOrdersByDevice()`

Vérifiez la requête de filtrage :

```php
// ✅ CORRECT
public function getOrdersByDevice(Request $request)
{
    $deviceFingerprint = $request->device_fingerprint;

    $orders = Order::where('device_fingerprint', $deviceFingerprint)
        ->orderBy('created_at', 'desc')
        ->paginate(20);

    return response()->json([
        'success' => true,
        'data' => [
            'orders' => $orders->items(),
            'pagination' => [
                'current_page' => $orders->currentPage(),
                'last_page' => $orders->lastPage(),
                'per_page' => $orders->perPage(),
                'total' => $orders->total(),
            ]
        ]
    ]);
}
```

---

## 🔎 Étape 3 : Vérifier le Modèle Laravel

### Fichier : `app/Models/Order.php`

Vérifiez que `device_fingerprint` est dans `$fillable` :

```php
class Order extends Model
{
    protected $fillable = [
        'shop_id',
        'customer_name',
        'customer_phone',
        'customer_email',
        'customer_address',
        'delivery_address',
        'service_type',
        'delivery_zone_id',
        'delivery_fee',
        'payment_method',
        'notes',
        'device_fingerprint', // ✅ Doit être présent
        'coupon_code',
        'discount_amount',
        'loyalty_card_id',
        'loyalty_points_used',
        'loyalty_discount',
        'subtotal',
        'total_amount',
        'status',
        'receipt_url',
        'receipt_view_url',
    ];
}
```

---

## 🔎 Étape 4 : Vérifier les Routes

### Fichier probable : `routes/api.php`

```php
// Vérifiez que ces routes existent
Route::post('/orders-simple', [OrderController::class, 'createSimpleOrder']);
Route::post('/mobile/orders/by-device', [OrderController::class, 'getOrdersByDevice']);
```

---

## 🔎 Étape 5 : Test avec Postman

### Test 1 : Créer une commande

**Endpoint:** `POST https://tika-ci.com/api/orders-simple`

**Body:**
```json
{
  "shop_id": 4,
  "customer_name": "Test User",
  "customer_phone": "0700000000",
  "service_type": "À emporter",
  "payment_method": "especes",
  "device_fingerprint": "test_device_12345",
  "items": [
    {
      "product_id": 16,
      "quantity": 1,
      "price": 15000
    }
  ]
}
```

**Notez :** Le `order_number` retourné (ex: TK-01122506)

### Test 2 : Récupérer les commandes

**Endpoint:** `POST https://tika-ci.com/api/mobile/orders/by-device`

**Body:**
```json
{
  "device_fingerprint": "test_device_12345"
}
```

**Résultat attendu :**
- La commande créée à l'étape 1 doit apparaître dans la liste
- `total` doit être > 0

---

## 🔎 Étape 6 : Vérifier les Logs Laravel

### Dans le terminal Laravel

```bash
# Activer le mode debug dans .env
APP_DEBUG=true

# Voir les logs en temps réel
tail -f storage/logs/laravel.log
```

### Ajouter des logs dans le Controller

```php
public function getOrdersByDevice(Request $request)
{
    $deviceFingerprint = $request->device_fingerprint;

    \Log::info('🔍 getOrdersByDevice appelé', [
        'device_fingerprint' => $deviceFingerprint
    ]);

    $orders = Order::where('device_fingerprint', $deviceFingerprint)->get();

    \Log::info('📦 Commandes trouvées', [
        'count' => $orders->count(),
        'orders' => $orders->pluck('order_number')
    ]);

    // ... reste du code
}
```

---

## ✅ Solution la plus probable

**Le `device_fingerprint` n'est probablement pas sauvegardé lors de la création de la commande.**

### Correction rapide (Laravel)

Dans votre Controller de création de commande, ajoutez :

```php
public function createSimpleOrder(Request $request)
{
    // ... validation ...

    $order = Order::create([
        // ... autres champs ...
        'device_fingerprint' => $request->device_fingerprint, // ✅ Ajouter cette ligne
    ]);

    // ... reste du code ...
}
```

Et dans le Modèle `Order.php`, ajoutez dans `$fillable` :

```php
protected $fillable = [
    // ... autres champs ...
    'device_fingerprint', // ✅ Ajouter cette ligne
];
```

---

## 🧪 Test Final

Après avoir appliqué les corrections :

1. **Créez une nouvelle commande** depuis l'app Flutter
2. **Notez le device_fingerprint** dans les logs
3. **Vérifiez en base** :
   ```sql
   SELECT device_fingerprint FROM orders WHERE order_number = 'TK-XXXXX';
   ```
4. **Testez l'historique** dans l'app

---

## 📱 Utiliser l'écran de Debug dans Flutter

J'ai créé un écran de debug dans l'app. Pour l'utiliser :

```dart
// Ajoutez temporairement dans votre menu ou navigation
Navigator.push(
  context,
  MaterialPageRoute(
    builder: (context) => const DebugOrdersScreen(),
  ),
);
```

Cet écran affiche :
- Le device_fingerprint actuel
- Le résultat exact de l'API
- Des instructions de débogage

---

## 📞 Support

Si le problème persiste après ces vérifications, partagez :
1. Le résultat de la requête SQL (Étape 1.A)
2. Un extrait du code Laravel (Controller)
3. Les logs Laravel lors de la création et récupération
