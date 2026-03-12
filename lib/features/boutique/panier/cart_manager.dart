import 'package:flutter/foundation.dart';

/// Gestionnaire du panier d'achat
/// Gère l'ajout, la suppression et la mise à jour des produits dans le panier
/// Respecte le format de l'API TIKA pour la création de commandes
class CartManager extends ChangeNotifier {
  static final CartManager _instance = CartManager._internal();
  factory CartManager() => _instance;
  CartManager._internal();

  final List<Map<String, dynamic>> _items = [];
  int? _shopId; // ID de la boutique (tous les items doivent venir de la même boutique)

  List<Map<String, dynamic>> get items => List.unmodifiable(_items);
  int? get shopId => _shopId;

  int get itemCount => _items.fold(0, (sum, item) {
    final q = item['quantity'];
    return sum + (q is int ? q : int.tryParse(q?.toString() ?? '0') ?? 0);
  });

  int get totalPrice => _items.fold(0, (sum, item) {
    final p = item['price'];
    final q = item['quantity'];
    final price = p is int ? p : (p is num ? p.toInt() : int.tryParse(p?.toString() ?? '0') ?? 0);
    final qty = q is int ? q : (q is num ? q.toInt() : int.tryParse(q?.toString() ?? '0') ?? 0);
    return sum + price * qty;
  });

  /// Ajoute un produit au panier
  /// Retourne un message d'erreur si l'ajout échoue, null si succès
  String? addItem(Map<String, dynamic> product, int quantity, {int? shopId, String? selectedSize, int? portionId}) {
    // Validation 1: Vérifier la disponibilité du produit
    final int stock = product['stock'] ?? 0;
    final bool isAvailable = product['isAvailable'] ?? true;

    if (!isAvailable) {
      return 'Ce produit n\'est pas disponible actuellement';
    }

    if (stock <= 0) {
      return 'Ce produit est en rupture de stock';
    }

    // Validation 2: Vérifier que la boutique est la même
    // Si le panier est vide, réinitialiser le shopId et accepter n'importe quelle boutique
    if (_items.isEmpty) {
      _shopId = shopId;
    } else if (_shopId != null && shopId != null && _shopId != shopId) {
      return 'Vous ne pouvez commander que dans une seule boutique à la fois. Videz votre panier pour changer de boutique.';
    }

    // Définir le shop_id si ce n'est pas encore fait
    if (_shopId == null && shopId != null) {
      _shopId = shopId;
    }

    // Vérifier si le produit existe déjà dans le panier (même ID + même taille + même portion)
    final existingIndex = _items.indexWhere(
      (item) => item['id'] == product['id'] &&
                item['size'] == selectedSize &&
                item['portion_id'] == portionId,
    );

    if (existingIndex >= 0) {
      // Produit existe avec la même taille, vérifier que la nouvelle quantité ne dépasse pas le stock
      final newQuantity = (_items[existingIndex]['quantity'] as int) + quantity;

      if (newQuantity > stock) {
        return 'Stock insuffisant. Disponible: $stock';
      }

      _items[existingIndex]['quantity'] = newQuantity;
    } else {
      // Nouveau produit ou nouvelle taille, vérifier le stock
      if (quantity > stock) {
        return 'Stock insuffisant. Disponible: $stock';
      }

      _items.add({
        'id': product['id'],           // ✅ ID requis par l'API
        'name': product['name'],       // Pour affichage
        'price': product['price'],     // Prix unitaire pour l'API
        'image': product['image'],     // Pour affichage
        'quantity': quantity,          // Quantité pour l'API
        'stock': stock,                // Pour validation continue
        'isAvailable': isAvailable,    // Pour validation continue
        'size': selectedSize,          // Taille sélectionnée (pour affichage)
        'portion_id': portionId,       // ✅ ID de portion requis par l'API
      });
    }

    notifyListeners();
    return null; // Succès
  }

  /// Supprime un produit du panier
  void removeItem(int index) {
    if (index >= 0 && index < _items.length) {
      _items.removeAt(index);
      notifyListeners();
    }
  }

  /// Met à jour la quantité d'un produit
  /// Retourne un message d'erreur si la mise à jour échoue, null si succès
  String? updateQuantity(int index, int newQuantity) {
    if (index >= 0 && index < _items.length) {
      if (newQuantity <= 0) {
        removeItem(index);
        return null;
      }

      // Valider que la nouvelle quantité ne dépasse pas le stock
      final int stock = _items[index]['stock'] ?? 0;
      if (newQuantity > stock) {
        return 'Stock insuffisant. Disponible: $stock';
      }

      _items[index]['quantity'] = newQuantity;
      notifyListeners();
      return null; // Succès
    }
    return 'Produit introuvable dans le panier';
  }

  /// Vide le panier et réinitialise le shop_id
  void clear() {
    _items.clear();
    _shopId = null;
    notifyListeners();
  }

  /// Charge des articles depuis un reorder (disponibilité déjà vérifiée par l'API)
  /// items: liste retournée par POST /client/orders/{id}/reorder
  /// Format attendu: [{ "product_id", "name", "image", "price", "quantity" }]
  void loadReorderItems(List<Map<String, dynamic>> items, int shopId) {
    _items.clear();
    _shopId = shopId;
    for (final item in items) {
      final qtyRaw = item['quantity'] ?? item['available_quantity'] ?? 1;
      final qty = qtyRaw is int ? qtyRaw : int.tryParse(qtyRaw.toString()) ?? 1;
      if (qty <= 0) continue; // ignorer les articles non disponibles
      final priceRaw = item['price'];
      final price = priceRaw is int
          ? priceRaw
          : priceRaw is num
              ? priceRaw.toInt()
              : int.tryParse(priceRaw?.toString() ?? '0') ?? 0;
      _items.add({
        'id': item['product_id'],
        'name': item['name'] ?? item['product_name'] ?? 'Produit',
        'price': price,
        'image': item['image'] ?? '',
        'quantity': qty,
        'stock': 999,         // déjà validé par l'API
        'isAvailable': true,  // déjà validé par l'API
        'size': null,
        'portion_id': null,
      });
    }
    notifyListeners();
  }

  /// Prépare les items au format requis par l'API TIKA pour créer une commande
  /// Format API: [{"product_id": 15, "quantity": 2, "price": 2500, "portion_id": 3}]
  /// Endpoint: POST /client/orders
  /// Documentation: 08-API-ORDERS.md
  List<Map<String, dynamic>> getItemsForOrder() {
    return _items.map((item) {
      final orderItem = {
        'product_id': item['id'],      // ✅ ID du produit (requis par l'API)
        'quantity': item['quantity'],   // ✅ Quantité (requis par l'API)
        'price': item['price'],         // ✅ Prix unitaire (requis par l'API)
      };
      if (item['portion_id'] != null) {
        orderItem['portion_id'] = item['portion_id']; // ✅ ID de portion (si applicable)
      }
      return orderItem;
    }).toList();
  }

  /// Valide que le panier peut être converti en commande
  /// Retourne un message d'erreur ou null si valide
  String? validateForOrder() {
    if (_items.isEmpty) {
      return 'Votre panier est vide';
    }

    if (_shopId == null) {
      return 'Shop ID manquant';
    }

    // Vérifier que tous les produits sont toujours disponibles
    for (var item in _items) {
      final bool isAvailable = item['isAvailable'] ?? true;
      final int stock = item['stock'] ?? 0;
      final int quantity = item['quantity'] ?? 0;

      if (!isAvailable) {
        return '${item['name']} n\'est plus disponible';
      }

      if (stock <= 0) {
        return '${item['name']} est en rupture de stock';
      }

      if (quantity > stock) {
        return 'Stock insuffisant pour ${item['name']}. Disponible: $stock';
      }
    }

    return null; // Panier valide
  }
}
