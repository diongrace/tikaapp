/// Modèle pour une carte de fidélité
class LoyaltyCard {
  final int id;
  final String cardNumber;
  final int shopId;
  final String shopName;
  final String customerName;
  final String phone;
  final String? email;
  final int points;
  final int totalPointsEarned;
  final int totalPointsRedeemed;
  final String status; // "active", "suspended", "cancelled"
  final bool hasPin;
  final DateTime createdAt;

  LoyaltyCard({
    required this.id,
    required this.cardNumber,
    required this.shopId,
    required this.shopName,
    required this.customerName,
    required this.phone,
    this.email,
    required this.points,
    required this.totalPointsEarned,
    required this.totalPointsRedeemed,
    required this.status,
    required this.hasPin,
    required this.createdAt,
  });

  factory LoyaltyCard.fromJson(Map<String, dynamic> json) {
    // L'API peut retourner les données de deux façons :
    // 1. Format plat : {id, card_number, shop_id, shop_name, customer_name, phone, ...}
    // 2. Format imbriqué : {id, card_number, customer: {...}, shop: {...}, ...}

    // Extraire les données du customer (si imbriqué)
    final customer = json['customer'] as Map<String, dynamic>?;
    final customerName = customer?['name']?.toString() ?? json['customer_name']?.toString() ?? '';
    final phone = customer?['phone']?.toString() ?? json['phone']?.toString() ?? '';
    final email = customer?['email']?.toString() ?? json['email']?.toString();

    // Extraire les données du shop (si imbriqué)
    final shop = json['shop'] as Map<String, dynamic>?;
    final shopId = _parseInt(shop?['id']) ?? _parseInt(json['shop_id']) ?? 0;
    final shopName = shop?['name']?.toString() ?? json['shop_name']?.toString() ?? '';

    // Gérer le status (is_active ou status)
    String status = 'active';
    if (json['status'] != null) {
      status = json['status'].toString();
    } else if (json['is_active'] != null) {
      status = (json['is_active'] == true || json['is_active'] == 1) ? 'active' : 'inactive';
    }

    return LoyaltyCard(
      id: _parseInt(json['id']) ?? 0,
      cardNumber: json['card_number']?.toString() ?? '',
      shopId: shopId,
      shopName: shopName,
      customerName: customerName,
      phone: phone,
      email: email,
      points: _parseInt(json['points']) ?? 0,
      totalPointsEarned: _parseInt(json['total_points_earned']) ?? 0,
      totalPointsRedeemed: _parseInt(json['total_points_redeemed']) ?? 0,
      status: status,
      hasPin: json['has_pin'] == true || json['has_pin'] == 1,
      createdAt: DateTime.tryParse(json['created_at']?.toString() ?? '') ??
          DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'card_number': cardNumber,
      'shop_id': shopId,
      'shop_name': shopName,
      'customer_name': customerName,
      'phone': phone,
      'email': email,
      'points': points,
      'total_points_earned': totalPointsEarned,
      'total_points_redeemed': totalPointsRedeemed,
      'status': status,
      'has_pin': hasPin,
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
}

/// Modèle pour le calcul de réduction fidélité
class LoyaltyDiscount {
  final int pointsToUse;
  final double discountAmount;
  final double newTotal;
  final int remainingPoints;
  final int conversionRate;
  final int maxUsablePoints;

  LoyaltyDiscount({
    required this.pointsToUse,
    required this.discountAmount,
    required this.newTotal,
    required this.remainingPoints,
    required this.conversionRate,
    required this.maxUsablePoints,
  });

  factory LoyaltyDiscount.fromJson(Map<String, dynamic> json) {
    return LoyaltyDiscount(
      pointsToUse: _parseInt(json['points_to_use']) ?? 0,
      discountAmount: _parseDouble(json['discount_amount']) ?? 0.0,
      newTotal: _parseDouble(json['new_total']) ?? 0.0,
      remainingPoints: _parseInt(json['remaining_points']) ?? 0,
      conversionRate: _parseInt(json['conversion_rate']) ?? 5,
      maxUsablePoints: _parseInt(json['max_usable_points']) ?? 0,
    );
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

/// Modèle pour l'historique des transactions fidélité
class LoyaltyTransaction {
  final int id;
  final int loyaltyCardId;
  final String type; // "earned", "redeemed", "restored"
  final int points;
  final String? description;
  final int? orderId;
  final String? orderNumber;
  final DateTime createdAt;

  LoyaltyTransaction({
    required this.id,
    required this.loyaltyCardId,
    required this.type,
    required this.points,
    this.description,
    this.orderId,
    this.orderNumber,
    required this.createdAt,
  });

  factory LoyaltyTransaction.fromJson(Map<String, dynamic> json) {
    return LoyaltyTransaction(
      id: _parseInt(json['id']) ?? 0,
      loyaltyCardId: _parseInt(json['loyalty_card_id']) ?? 0,
      type: json['type']?.toString() ?? 'earned',
      points: _parseInt(json['points']) ?? 0,
      description: json['description']?.toString(),
      orderId: _parseInt(json['order_id']),
      orderNumber: json['order_number']?.toString(),
      createdAt: DateTime.tryParse(json['created_at']?.toString() ?? '') ??
          DateTime.now(),
    );
  }

  static int? _parseInt(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is double) return value.toInt();
    if (value is String) return int.tryParse(value);
    return null;
  }
}
