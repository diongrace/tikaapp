/// Modele pour une carte de fidelite
/// Format API: GET /client/loyalty et GET /client/loyalty/cards/{id}
class LoyaltyCard {
  final int id;
  final String cardNumber;
  final int points;
  final int pointsValue;
  final String tier; // bronze, silver, gold, platinum
  final String tierLabel;
  final bool isActive;

  // Shop
  final int shopId;
  final String shopName;
  final String? shopLogo;
  final String? shopSlug;
  final int pointValue; // valeur d'1 point en FCFA
  final String? shopPhone;
  final String? shopAddress;
  final bool loyaltyEnabled;

  // Detail (depuis GET /client/loyalty/cards/{id})
  final String? qrCode;
  final String? pinCodeHint;
  final int visitsCount;
  final int lifetimeSpent;

  // Dates (format texte depuis l'API)
  final String? activatedAt;
  final String? lastUsedAt;

  LoyaltyCard({
    required this.id,
    required this.cardNumber,
    required this.points,
    this.pointsValue = 0,
    this.tier = 'bronze',
    this.tierLabel = 'Bronze',
    this.isActive = true,
    required this.shopId,
    required this.shopName,
    this.shopLogo,
    this.shopSlug,
    this.pointValue = 10,
    this.shopPhone,
    this.shopAddress,
    this.loyaltyEnabled = true,
    this.qrCode,
    this.pinCodeHint,
    this.visitsCount = 0,
    this.lifetimeSpent = 0,
    this.activatedAt,
    this.lastUsedAt,
  });

  String get status => isActive ? 'active' : 'inactive';

  factory LoyaltyCard.fromJson(Map<String, dynamic> json) {
    final shop = json['shop'] as Map<String, dynamic>?;

    return LoyaltyCard(
      id: _parseInt(json['id']) ?? 0,
      cardNumber: json['card_number']?.toString() ?? '',
      points: _parseInt(json['points']) ?? 0,
      pointsValue: _parseInt(json['points_value']) ?? 0,
      tier: json['tier']?.toString() ?? 'bronze',
      tierLabel: json['tier_label']?.toString() ?? 'Bronze',
      isActive: json['is_active'] == true || json['is_active'] == 1,
      shopId: _parseInt(shop?['id']) ?? _parseInt(json['shop_id']) ?? 0,
      shopName: shop?['name']?.toString() ?? json['shop_name']?.toString() ?? '',
      shopLogo: shop?['logo']?.toString(),
      shopSlug: shop?['slug']?.toString(),
      pointValue: _parseInt(shop?['point_value']) ?? _parseInt(json['point_value']) ?? 10,
      shopPhone: shop?['phone']?.toString(),
      shopAddress: shop?['address']?.toString(),
      loyaltyEnabled: shop?['loyalty_enabled'] == true || json['loyalty_enabled'] == true,
      qrCode: json['qr_code']?.toString(),
      pinCodeHint: json['pin_code_hint']?.toString(),
      visitsCount: _parseInt(json['visits_count']) ?? 0,
      lifetimeSpent: _parseInt(json['lifetime_spent']) ?? 0,
      activatedAt: json['activated_at']?.toString(),
      lastUsedAt: json['last_used_at']?.toString(),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'card_number': cardNumber,
    'points': points,
    'points_value': pointsValue,
    'tier': tier,
    'tier_label': tierLabel,
    'is_active': isActive,
    'shop': {
      'id': shopId,
      'name': shopName,
      'logo': shopLogo,
      'slug': shopSlug,
      'point_value': pointValue,
      'phone': shopPhone,
      'address': shopAddress,
      'loyalty_enabled': loyaltyEnabled,
    },
    'qr_code': qrCode,
    'pin_code_hint': pinCodeHint,
    'visits_count': visitsCount,
    'lifetime_spent': lifetimeSpent,
    'activated_at': activatedAt,
    'last_used_at': lastUsedAt,
  };

  static int? _parseInt(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is double) return value.toInt();
    if (value is String) return int.tryParse(value);
    return null;
  }
}

/// Detail complet d'une carte (carte + recompenses + transactions recentes)
/// Retourne par GET /client/loyalty/cards/{id}
class LoyaltyCardDetail {
  final LoyaltyCard card;
  final List<LoyaltyReward> rewards;
  final List<LoyaltyTransaction> recentTransactions;

  LoyaltyCardDetail({
    required this.card,
    this.rewards = const [],
    this.recentTransactions = const [],
  });
}

/// Recompense fidelite
class LoyaltyReward {
  final int id;
  final String name;
  final String? description;
  final int pointsRequired;
  final String rewardType; // free_delivery, gift_product, percent_discount, fixed_discount, custom
  final String? rewardValue;
  final bool canClaim;
  final int pointsNeeded;
  final int progressPercent;

  LoyaltyReward({
    required this.id,
    required this.name,
    this.description,
    required this.pointsRequired,
    required this.rewardType,
    this.rewardValue,
    this.canClaim = false,
    this.pointsNeeded = 0,
    this.progressPercent = 0,
  });

  String get rewardTypeLabel {
    switch (rewardType) {
      case 'free_delivery': return 'Livraison gratuite';
      case 'gift_product': return 'Produit offert';
      case 'percent_discount': return 'Remise ${rewardValue ?? ''}%';
      case 'fixed_discount': return 'Remise ${rewardValue ?? ''} FCFA';
      case 'custom': return name;
      default: return rewardType;
    }
  }

  factory LoyaltyReward.fromJson(Map<String, dynamic> json) {
    return LoyaltyReward(
      id: _parseInt(json['id']) ?? 0,
      name: json['name']?.toString() ?? '',
      description: json['description']?.toString(),
      pointsRequired: _parseInt(json['points_required']) ?? 0,
      rewardType: json['reward_type']?.toString() ?? 'custom',
      rewardValue: json['reward_value']?.toString(),
      canClaim: json['can_claim'] == true,
      pointsNeeded: _parseInt(json['points_needed']) ?? 0,
      progressPercent: _parseInt(json['progress_percent']) ?? 0,
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

/// Transaction fidelite (historique points)
class LoyaltyTransaction {
  final int id;
  final String type; // earned, redeemed, expired, bonus
  final String typeLabel;
  final int points;
  final String pointsDisplay;
  final int balanceAfter;
  final String? description;
  final int? orderId;
  final String createdAt;
  final String createdAtHuman;

  LoyaltyTransaction({
    required this.id,
    required this.type,
    this.typeLabel = '',
    required this.points,
    this.pointsDisplay = '',
    this.balanceAfter = 0,
    this.description,
    this.orderId,
    required this.createdAt,
    this.createdAtHuman = '',
  });

  bool get isEarned => type == 'earned' || type == 'bonus';

  factory LoyaltyTransaction.fromJson(Map<String, dynamic> json) {
    return LoyaltyTransaction(
      id: _parseInt(json['id']) ?? 0,
      type: json['type']?.toString() ?? 'earned',
      typeLabel: json['type_label']?.toString() ?? '',
      points: _parseInt(json['points']) ?? 0,
      pointsDisplay: json['points_display']?.toString() ?? '',
      balanceAfter: _parseInt(json['balance_after']) ?? 0,
      description: json['description']?.toString(),
      orderId: _parseInt(json['order_id']),
      createdAt: json['created_at']?.toString() ?? '',
      createdAtHuman: json['created_at_human']?.toString() ?? '',
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

/// Modele pour le calcul de reduction fidelite
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
