/// Modèle pour une commande
class Order {
  final int id;
  final String orderNumber;
  final int shopId;
  final String? shopName; // Nom de la boutique (optionnel)
  final String? shopLogo; // Logo de la boutique (optionnel)
  final String customerName; // Peut être vide pour liste simplifiée
  final String customerPhone; // Peut être vide pour liste simplifiée
  final String? customerEmail;
  final String? customerAddress;
  final String? deliveryAddress;
  final String serviceType; // Peut être vide pour liste simplifiée
  final int? deliveryZoneId;
  final double deliveryFee; // 0.0 par défaut pour liste simplifiée
  final String paymentMethod; // 'especes' par défaut
  final String? notes;
  final String? deviceFingerprint;
  final String? couponCode;
  final double? discountAmount;
  final int? loyaltyCardId;
  final int? loyaltyPointsUsed;
  final double? loyaltyDiscount;
  final double subtotal; // 0.0 par défaut pour liste simplifiée
  final double totalAmount;
  final String status;
  final List<OrderItem> items; // Peut être vide pour liste simplifiée
  final int itemsCount; // Nombre d'articles (depuis l'API ou calculé)
  final String? receiptUrl;
  final String? receiptViewUrl;
  final DateTime createdAt;
  final List<Map<String, dynamic>>? timeline; // Timeline retournée par l'API de suivi

  Order({
    required this.id,
    required this.orderNumber,
    required this.shopId,
    this.shopName,
    this.shopLogo,
    this.customerName = '',
    this.customerPhone = '',
    this.customerEmail,
    this.customerAddress,
    this.deliveryAddress,
    this.serviceType = '',
    this.deliveryZoneId,
    this.deliveryFee = 0.0,
    this.paymentMethod = 'especes',
    this.notes,
    this.deviceFingerprint,
    this.couponCode,
    this.discountAmount,
    this.loyaltyCardId,
    this.loyaltyPointsUsed,
    this.loyaltyDiscount,
    this.subtotal = 0.0,
    required this.totalAmount,
    required this.status,
    this.items = const [],
    this.itemsCount = 0,
    this.receiptUrl,
    this.receiptViewUrl,
    required this.createdAt,
    this.timeline,
  });

  factory Order.fromJson(Map<String, dynamic> json) {
    print('🔍 [Order] Parsing JSON: ${json.keys.toList()}');

    // Parser les items
    final items = json['items'] != null
        ? (json['items'] as List).map((e) => OrderItem.fromJson(e)).toList()
        : <OrderItem>[];

    // Calculer itemsCount: utiliser items_count/total_items de l'API,
    // ou la somme des quantités des items
    final totalQty = items.isNotEmpty
        ? items.fold<int>(0, (sum, item) => sum + item.quantity)
        : 0;
    final itemsCount = _parseInt(json['items_count'])
        ?? _parseInt(json['total_items'])
        ?? _parseInt(json['nb_items'])
        ?? (totalQty > 0 ? totalQty : items.length);

    // Parser le shop_name (peut être dans shop.name, boutique.name ou directement shop_name)
    // API Tika dashboard retourne "boutique" (français) au lieu de "shop"
    final boutiqueObj = json['boutique'] as Map<String, dynamic>? ??
        json['shop'] as Map<String, dynamic>?;
    String? shopName;
    if (json['shop_name'] != null) {
      shopName = json['shop_name'].toString();
    } else if (boutiqueObj?['name'] != null) {
      shopName = boutiqueObj!['name'].toString();
    }

    // Parser le shop_logo (peut être dans plusieurs champs)
    String? shopLogo;
    if (json['shop_logo'] != null && json['shop_logo'].toString().isNotEmpty) {
      shopLogo = json['shop_logo'].toString();
    } else if (json['shop_logo_url'] != null && json['shop_logo_url'].toString().isNotEmpty) {
      shopLogo = json['shop_logo_url'].toString();
    } else if (boutiqueObj != null) {
      // Chercher dans l'objet shop/boutique imbriqué
      if (boutiqueObj['logo_url'] != null && boutiqueObj['logo_url'].toString().isNotEmpty) {
        shopLogo = boutiqueObj['logo_url'].toString();
      } else if (boutiqueObj['logo'] != null && boutiqueObj['logo'].toString().isNotEmpty) {
        shopLogo = boutiqueObj['logo'].toString();
      }
    }

    print('🔍 [Order] shop_logo: $shopLogo');

    // Parser le téléphone (essayer plusieurs variantes)
    final customerPhone = json['customer_phone']?.toString() ??
                         json['phone']?.toString() ??
                         json['telephone']?.toString() ?? '';

    // Parser l'adresse de livraison (essayer plusieurs variantes)
    final deliveryAddress = json['delivery_address']?.toString() ??
                           json['address']?.toString() ??
                           json['customer_address']?.toString();

    // Parser le shopId avec logs (boutique = clé française de l'API dashboard)
    final shopIdFromDirect = _parseInt(json['shop_id']);
    final shopIdFromNested = _parseInt(boutiqueObj?['id']);
    final finalShopId = shopIdFromDirect ?? shopIdFromNested ?? 0;

    print('🔍 [Order] shop_id direct: $shopIdFromDirect');
    print('🔍 [Order] shop.id nested: $shopIdFromNested');
    print('🔍 [Order] Final shopId: $finalShopId');

    return Order(
      id: _parseInt(json['id']) ?? 0,
      orderNumber: json['numéro_de_commande']?.toString() ??
          json['order_number']?.toString() ?? '',
      shopId: finalShopId,
      shopName: shopName,
      shopLogo: shopLogo,
      customerName: json['customer_name']?.toString() ?? json['name']?.toString() ?? '',
      customerPhone: customerPhone,
      customerEmail: json['customer_email']?.toString() ?? json['email']?.toString(),
      customerAddress: json['customer_address']?.toString(),
      deliveryAddress: deliveryAddress,
      serviceType: json['type_de_service']?.toString() ??
          json['service_type']?.toString() ?? '',
      deliveryZoneId: _parseInt(json['delivery_zone_id']),
      deliveryFee: _parseDouble(json['delivery_fee']) ?? 0.0,
      paymentMethod: json['payment_method']?.toString() ?? 'especes',
      notes: json['notes']?.toString(),
      deviceFingerprint: json['device_fingerprint']?.toString(),
      couponCode: json['coupon_code']?.toString(),
      discountAmount: _parseDouble(json['discount_amount']),
      loyaltyCardId: _parseInt(json['loyalty_card_id']),
      loyaltyPointsUsed: _parseInt(json['loyalty_points_used']),
      loyaltyDiscount: _parseDouble(json['loyalty_discount']),
      subtotal: _parseDouble(json['subtotal']) ?? 0.0,
      totalAmount: _parseDouble(json['montant_total']) ??
          _parseDouble(json['total_amount']) ?? 0.0,
      status: json['statut']?.toString() ?? json['status']?.toString() ?? 'pending',
      items: items,
      itemsCount: itemsCount,
      receiptUrl: json['receipt_url']?.toString(),
      receiptViewUrl: json['receipt_view_url']?.toString(),
      createdAt: DateTime.tryParse(json['created_at']?.toString() ?? '') ??
          DateTime.now(),
      timeline: (json['timeline'] as List?)
          ?.map((e) => Map<String, dynamic>.from(e as Map))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'order_number': orderNumber,
      'shop_id': shopId,
      'shop_name': shopName,
      'shop_logo': shopLogo,
      'customer_name': customerName,
      'customer_phone': customerPhone,
      'customer_email': customerEmail,
      'customer_address': customerAddress,
      'delivery_address': deliveryAddress,
      'service_type': serviceType,
      'delivery_zone_id': deliveryZoneId,
      'delivery_fee': deliveryFee,
      'payment_method': paymentMethod,
      'notes': notes,
      'device_fingerprint': deviceFingerprint,
      'coupon_code': couponCode,
      'discount_amount': discountAmount,
      'loyalty_card_id': loyaltyCardId,
      'loyalty_points_used': loyaltyPointsUsed,
      'loyalty_discount': loyaltyDiscount,
      'subtotal': subtotal,
      'total_amount': totalAmount,
      'status': status,
      'items': items.map((e) => e.toJson()).toList(),
      'items_count': itemsCount,
      'receipt_url': receiptUrl,
      'receipt_view_url': receiptViewUrl,
      'created_at': createdAt.toIso8601String(),
    };
  }

  static int? _parseInt(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is double) return value.toInt();
    if (value is String) return int.tryParse(value);
    return null;
  }

  static double? _parseDouble(dynamic value) {
    if (value == null) return null;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value);
    return null;
  }
}

/// Item d'une commande
class OrderItem {
  final int? id;
  final int? productId;
  final int? dailyMenuId;
  final int? supplementId;
  final int quantity;
  final double price;
  final String? productName;
  final String? image;

  OrderItem({
    this.id,
    this.productId,
    this.dailyMenuId,
    this.supplementId,
    required this.quantity,
    required this.price,
    this.productName,
    this.image,
  });

  factory OrderItem.fromJson(Map<String, dynamic> json) {
    // Parser l'image (chercher dans plusieurs champs possibles)
    String? image;
    if (json['image'] != null && json['image'].toString().isNotEmpty) {
      image = json['image'].toString();
    } else if (json['image_url'] != null && json['image_url'].toString().isNotEmpty) {
      image = json['image_url'].toString();
    } else if (json['product_image'] != null && json['product_image'].toString().isNotEmpty) {
      image = json['product_image'].toString();
    } else if (json['product'] != null) {
      // Chercher dans l'objet product imbriqué
      final product = json['product'];
      if (product['image'] != null && product['image'].toString().isNotEmpty) {
        image = product['image'].toString();
      } else if (product['image_url'] != null && product['image_url'].toString().isNotEmpty) {
        image = product['image_url'].toString();
      } else if (product['primary_image_url'] != null && product['primary_image_url'].toString().isNotEmpty) {
        image = product['primary_image_url'].toString();
      } else if (product['images'] != null && product['images'] is List && (product['images'] as List).isNotEmpty) {
        final firstImg = (product['images'] as List).first;
        if (firstImg['url'] != null && firstImg['url'].toString().isNotEmpty) {
          image = firstImg['url'].toString();
        }
      }
    }

    // Parser le nom du produit (chercher dans plusieurs champs possibles)
    String? productName;
    if (json['product_name'] != null && json['product_name'].toString().isNotEmpty) {
      productName = json['product_name'].toString();
    } else if (json['name'] != null && json['name'].toString().isNotEmpty) {
      productName = json['name'].toString();
    } else if (json['product'] != null && json['product']['name'] != null) {
      productName = json['product']['name'].toString();
    }

    print('🔍 [OrderItem] Parsing: name=$productName, image=$image');

    return OrderItem(
      id: _parseInt(json['id']),
      productId: _parseInt(json['product_id']),
      dailyMenuId: _parseInt(json['daily_menu_id']),
      supplementId: _parseInt(json['supplement_id']),
      quantity: _parseInt(json['quantity']) ?? 1,
      price: _parseDouble(json['price']) ?? 0.0,
      productName: productName,
      image: image,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      if (productId != null) 'product_id': productId,
      if (dailyMenuId != null) 'daily_menu_id': dailyMenuId,
      if (supplementId != null) 'supplement_id': supplementId,
      'quantity': quantity,
      'price': price,
      if (productName != null) 'product_name': productName,
      if (image != null) 'image': image,
    };
  }

  static int? _parseInt(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is double) return value.toInt();
    if (value is String) return int.tryParse(value);
    return null;
  }

  static double? _parseDouble(dynamic value) {
    if (value == null) return null;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value);
    return null;
  }
}
