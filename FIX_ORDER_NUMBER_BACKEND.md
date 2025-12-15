# Fix: order_number NULL dans la réponse API

## Problème Identifié

L'API `POST /client/orders` ne retourne **PAS** le champ `order_number` dans la réponse, ce qui empêche le suivi de commande de fonctionner.

### Log d'erreur observé:
```
I/flutter ( 5944): 📦 Réponse complète de l'API: {orderNumber: null, ...}
I/flutter ( 5944): ❌ [LoadingSuccessPage] Données manquantes!
I/flutter ( 5944):    - orderNumber null: true
```

---

## Solution Backend (PHP/Laravel)

### 1. Localiser le fichier contrôleur

Trouvez le fichier qui gère la création de commandes. Il devrait être dans :
```
app/Http/Controllers/Client/OrderController.php
```
ou
```
app/Http/Controllers/API/Client/OrderController.php
```

### 2. Vérifier la méthode de création de commande

Recherchez la méthode qui traite `POST /client/orders`. Elle devrait ressembler à ceci :

```php
public function store(Request $request)
{
    // Validation...

    // Création de la commande
    $order = Order::create([
        'shop_id' => $request->shop_id,
        'customer_name' => $request->customer_name,
        'customer_phone' => $request->customer_phone,
        // ... autres champs ...
    ]);

    // Créer les items de la commande
    foreach ($request->items as $item) {
        // ...
    }

    // PROBLÈME: La réponse ne retourne pas order_number!
    return response()->json([
        'success' => true,
        'order_id' => $order->id,
        // 'order_number' => MANQUANT! ❌
        'customer_phone' => $order->customer_phone,
        'total' => $order->total_amount,
        'message' => 'Commande créée avec succès'
    ]);
}
```

### 3. Correction à appliquer

#### Option A: Si order_number existe déjà dans la base de données

Si votre table `orders` a déjà une colonne `order_number` qui est générée automatiquement :

```php
public function store(Request $request)
{
    // ... validation et création de la commande ...

    $order = Order::create([
        'shop_id' => $request->shop_id,
        'customer_name' => $request->customer_name,
        'customer_phone' => $request->customer_phone,
        'order_number' => $this->generateOrderNumber(), // ← Générer le numéro
        // ... autres champs ...
    ]);

    // ... créer les items ...

    // ✅ CORRECTION: Ajouter order_number dans la réponse
    return response()->json([
        'success' => true,
        'order_id' => $order->id,
        'order_number' => $order->order_number, // ← AJOUT IMPORTANT!
        'customer_phone' => $order->customer_phone,
        'total' => $order->total_amount,
        'receipt_url' => $order->receipt_url,
        'receipt_view_url' => $order->receipt_view_url,
        'message' => 'Commande créée avec succès'
    ], 201);
}

// Méthode pour générer un numéro de commande unique
private function generateOrderNumber()
{
    // Format: ORD-2025-000001
    $year = date('Y');
    $count = Order::whereYear('created_at', $year)->count() + 1;
    return 'ORD-' . $year . '-' . str_pad($count, 6, '0', STR_PAD_LEFT);
}
```

#### Option B: Si order_number n'existe pas encore

Si la colonne `order_number` n'existe pas dans votre table `orders` :

**Étape 1: Créer une migration**

```bash
php artisan make:migration add_order_number_to_orders_table
```

**Étape 2: Modifier la migration**

```php
// database/migrations/xxxx_xx_xx_add_order_number_to_orders_table.php
public function up()
{
    Schema::table('orders', function (Blueprint $table) {
        $table->string('order_number')->unique()->after('id');
    });
}

public function down()
{
    Schema::table('orders', function (Blueprint $table) {
        $table->dropColumn('order_number');
    });
}
```

**Étape 3: Exécuter la migration**

```bash
php artisan migrate
```

**Étape 4: Ajouter order_number dans le modèle Order**

```php
// app/Models/Order.php
protected $fillable = [
    'order_number', // ← Ajouter ici
    'shop_id',
    'customer_name',
    'customer_phone',
    // ... autres champs ...
];

// Observer pour générer automatiquement le numéro de commande
protected static function boot()
{
    parent::boot();

    static::creating(function ($order) {
        if (empty($order->order_number)) {
            $order->order_number = static::generateOrderNumber();
        }
    });
}

public static function generateOrderNumber()
{
    $year = date('Y');
    $count = static::whereYear('created_at', $year)->count() + 1;
    return 'ORD-' . $year . '-' . str_pad($count, 6, '0', STR_PAD_LEFT);
}
```

**Étape 5: Modifier le contrôleur**

```php
public function store(Request $request)
{
    // ... validation ...

    $order = Order::create([
        'shop_id' => $request->shop_id,
        'customer_name' => $request->customer_name,
        'customer_phone' => $request->customer_phone,
        // order_number sera généré automatiquement via l'observer
        // ... autres champs ...
    ]);

    // ... créer les items ...

    // ✅ Retourner order_number dans la réponse
    return response()->json([
        'success' => true,
        'order_id' => $order->id,
        'order_number' => $order->order_number, // ← IMPORTANT!
        'customer_phone' => $order->customer_phone,
        'total' => $order->total_amount,
        'receipt_url' => $order->receipt_url,
        'receipt_view_url' => $order->receipt_view_url,
        'message' => 'Commande créée avec succès'
    ], 201);
}
```

---

## 4. Structure de réponse attendue

L'application Flutter s'attend à recevoir cette réponse JSON :

```json
{
  "success": true,
  "order_id": 123,
  "order_number": "ORD-2025-000001",  // ← OBLIGATOIRE pour le suivi
  "customer_phone": "+2250700000000",
  "total": 15500,
  "receipt_url": "https://prepro.tika-ci.com/storage/receipts/abc123.pdf",
  "receipt_view_url": "https://prepro.tika-ci.com/receipts/view/abc123",
  "message": "Commande créée avec succès"
}
```

---

## 5. Test avec Postman

Après avoir appliqué la correction, testez avec Postman :

**Requête:**
```
POST https://prepro.tika-ci.com/api/client/orders
Content-Type: application/json

{
  "shop_id": 10,
  "customer_name": "Test Client",
  "customer_phone": "0756222222",
  "customer_address": "Test address",
  "service_type": "Livraison à domicile",
  "payment_method": "especes",
  "device_fingerprint": "test123",
  "items": [
    {
      "product_id": 1,
      "quantity": 1,
      "price": 15500
    }
  ]
}
```

**Vérifiez que la réponse contient bien:**
- ✅ `order_number` (non null)
- ✅ `order_id`
- ✅ `customer_phone`
- ✅ `total`

---

## 6. Vérification dans la base de données

Connectez-vous à votre base de données MySQL/PostgreSQL et vérifiez :

```sql
SELECT id, order_number, customer_name, customer_phone, total_amount, created_at
FROM orders
ORDER BY id DESC
LIMIT 5;
```

Vous devriez voir que chaque commande a bien un `order_number` unique.

---

## 7. Après correction

Une fois le backend corrigé :

1. Testez la création d'une commande dans l'app Flutter
2. Vérifiez les logs Flutter pour confirmer que `order_number` n'est plus null
3. Testez le bouton "Suivre ma commande" dans le modal de succès
4. Le suivi de commande devrait maintenant fonctionner ✅

---

## Fichiers modifiés côté Frontend (déjà fait) ✅

Les fichiers Flutter suivants ont déjà été corrigés pour mieux gérer ce problème :

- ✅ `lib/features/boutique/commande/commande_screen.dart` (logs d'avertissement ajoutés)
- ✅ `lib/features/boutique/commande/loading_success_page.dart` (message d'erreur utilisateur)
- ✅ Navigation des flèches corrigée dans toutes les pages

---

## Besoin d'aide ?

Si vous avez des questions ou besoin d'aide pour localiser les fichiers backend :

1. Cherchez le fichier : `app/Http/Controllers/Client/OrderController.php`
2. Cherchez la méthode qui gère `POST /client/orders`
3. Appliquez la correction selon l'Option A ou B ci-dessus
4. Testez avec Postman avant de tester dans l'app

---

**Date de création:** 2025-12-09
**Créé par:** Claude Code Assistant
