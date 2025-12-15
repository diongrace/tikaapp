/// Modèle pour une commande
class Order {
  final int id;
  final String orderNumber;
  final int shopId;
  final String? shopName; // Nom de la boutique (optionnel)
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

  Order({
    required this.id,
    required this.orderNumber,
    required this.shopId,
    this.shopName,
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
  });

  factory Order.fromJson(Map<String, dynamic> json) {
    print('🔍 [Order] Parsing JSON: ${json.keys.toList()}');

    // Parser les items
    final items = json['items'] != null
        ? (json['items'] as List).map((e) => OrderItem.fromJson(e)).toList()
        : <OrderItem>[];

    // Calculer itemsCount: utiliser items_count de l'API ou la longueur des items
    final itemsCount = _parseInt(json['items_count']) ?? items.length;

    // Parser le shop_name (peut être dans shop.name ou directement shop_name)
    String? shopName;
    if (json['shop_name'] != null) {
      shopName = json['shop_name'].toString();
    } else if (json['shop'] != null && json['shop']['name'] != null) {
      shopName = json['shop']['name'].toString();
    }

    // Parser le téléphone (essayer plusieurs variantes)
    final customerPhone = json['customer_phone']?.toString() ??
                         json['phone']?.toString() ??
                         json['telephone']?.toString() ?? '';

    // Parser l'adresse de livraison (essayer plusieurs variantes)
    final deliveryAddress = json['delivery_address']?.toString() ??
                           json['address']?.toString() ??
                           json['customer_address']?.toString();

    // Parser le shopId avec logs
    final shopIdFromDirect = _parseInt(json['shop_id']);
    final shopIdFromNested = _parseInt(json['shop']?['id']);
    final finalShopId = shopIdFromDirect ?? shopIdFromNested ?? 0;

    print('🔍 [Order] shop_id direct: $shopIdFromDirect');
    print('🔍 [Order] shop.id nested: $shopIdFromNested');
    print('🔍 [Order] Final shopId: $finalShopId');

    return Order(
      id: _parseInt(json['id']) ?? 0,
      orderNumber: json['order_number']?.toString() ?? '',
      shopId: finalShopId,
      shopName: shopName,
      customerName: json['customer_name']?.toString() ?? json['name']?.toString() ?? '',
      customerPhone: customerPhone,
      customerEmail: json['customer_email']?.toString() ?? json['email']?.toString(),
      customerAddress: json['customer_address']?.toString(),
      deliveryAddress: deliveryAddress,
      serviceType: json['service_type']?.toString() ?? '',
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
      totalAmount: _parseDouble(json['total_amount']) ?? 0.0,
      status: json['status']?.toString() ?? 'pending',
      items: items,
      itemsCount: itemsCount,
      receiptUrl: json['receipt_url']?.toString(),
      receiptViewUrl: json['receipt_view_url']?.toString(),
      createdAt: DateTime.tryParse(json['created_at']?.toString() ?? '') ??
          DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'order_number': orderNumber,
      'shop_id': shopId,
      'shop_name': shopName,
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
  final int? productId;
  final int? dailyMenuId;
  final int? supplementId;
  final int quantity;
  final double price;
  final String? productName;
  final String? image;

  OrderItem({
    this.productId,
    this.dailyMenuId,
    this.supplementId,
    required this.quantity,
    required this.price,
    this.productName,
    this.image,
  });

  factory OrderItem.fromJson(Map<String, dynamic> json) {
    return OrderItem(
      productId: _parseInt(json['product_id']),
      dailyMenuId: _parseInt(json['daily_menu_id']),
      supplementId: _parseInt(json['supplement_id']),
      quantity: _parseInt(json['quantity']) ?? 1,
      price: _parseDouble(json['price']) ?? 0.0,
      productName: json['product_name']?.toString(),
      image: json['image']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
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
