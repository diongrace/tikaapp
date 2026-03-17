/// Modèles pour les cadeaux et cartes d'achat

// ── Commande cadeau ──────────────────────────────────────────────────────────

class GiftOrderResult {
  final bool success;
  final String message;

  // Réponse especes (dans data{})
  final String? trackingToken;
  final int? totalAmount;
  final String? deliveryType;
  final String? deliveryTypeLabel;
  final bool requiresYangoOrder;
  final Map<String, dynamic>? giftOrder;
  final Map<String, dynamic>? shop;

  // Réponse mobile_money (à la racine)
  final bool waveRedirect;
  final String? waveUrl;
  final String? pendingId;
  final bool requiresProof;
  final bool isPending;

  GiftOrderResult({
    required this.success,
    required this.message,
    this.trackingToken,
    this.totalAmount,
    this.deliveryType,
    this.deliveryTypeLabel,
    this.requiresYangoOrder = false,
    this.giftOrder,
    this.shop,
    this.waveRedirect = false,
    this.waveUrl,
    this.pendingId,
    this.requiresProof = false,
    this.isPending = false,
  });

  bool get isWavePending => waveRedirect == true || isPending == true;

  factory GiftOrderResult.fromJson(Map<String, dynamic> json) {
    final data = json['data'] as Map<String, dynamic>? ?? {};
    return GiftOrderResult(
      success: json['success'] ?? false,
      message: json['message'] ?? '',
      // Especes: champs dans data{}
      trackingToken: data['tracking_token'] ?? json['tracking_token'],
      totalAmount: _parseInt(data['total_amount'] ?? json['total_amount']),
      deliveryType: data['delivery_type'],
      deliveryTypeLabel: data['delivery_type_label'],
      requiresYangoOrder: data['requires_yango_order'] == true,
      giftOrder: data['gift_order'] as Map<String, dynamic>?,
      shop: data['shop'] as Map<String, dynamic>?,
      // mobile_money: champs à la racine
      waveRedirect: json['wave_redirect'] == true,
      waveUrl: json['wave_url'],
      pendingId: json['pending_id'],
      requiresProof: json['requires_proof'] == true,
      isPending: json['is_pending'] == true,
    );
  }

  static int? _parseInt(dynamic v) {
    if (v == null) return null;
    if (v is int) return v;
    if (v is num) return v.toInt();
    return int.tryParse(v.toString());
  }
}

// ── Suivi commande cadeau ────────────────────────────────────────────────────

class GiftTrackData {
  final int? id;
  final String trackingToken;
  final String status;
  final String statusLabel;
  final String? deliveryType;
  final String senderName;
  final String recipientName;
  final String? giftMessage;
  final String? createdAt;

  final String? orderNumber;
  final int? totalAmount;
  final List<Map<String, dynamic>> items;

  final String? shopName;
  final String? shopLogo;
  final String? shopAddress;

  final bool requiresYangoOrder;
  final Map<String, dynamic>? yangoInfo;

  GiftTrackData({
    this.id,
    required this.trackingToken,
    required this.status,
    required this.statusLabel,
    this.deliveryType,
    required this.senderName,
    required this.recipientName,
    this.giftMessage,
    this.createdAt,
    this.orderNumber,
    this.totalAmount,
    this.items = const [],
    this.shopName,
    this.shopLogo,
    this.shopAddress,
    this.requiresYangoOrder = false,
    this.yangoInfo,
  });

  factory GiftTrackData.fromJson(Map<String, dynamic> json) {
    final data = json['data'] as Map<String, dynamic>? ?? json;
    final giftOrder = data['gift_order'] as Map<String, dynamic>? ?? {};
    final order = data['order'] as Map<String, dynamic>? ?? {};
    final shop = data['shop'] as Map<String, dynamic>? ?? {};
    final rawItems = order['items'] as List? ?? [];
    return GiftTrackData(
      id: giftOrder['id'] is num ? (giftOrder['id'] as num).toInt() : null,
      trackingToken: giftOrder['tracking_token'] ?? '',
      status: giftOrder['status'] ?? '',
      statusLabel: giftOrder['status_label'] ?? '',
      deliveryType: giftOrder['delivery_type'],
      senderName: giftOrder['sender_name'] ?? '',
      recipientName: giftOrder['recipient_name'] ?? '',
      giftMessage: giftOrder['gift_message'],
      createdAt: giftOrder['created_at'],
      orderNumber: order['order_number'],
      totalAmount: order['total_amount'] is num
          ? (order['total_amount'] as num).toInt()
          : int.tryParse(order['total_amount']?.toString() ?? ''),
      items: rawItems.map((e) => Map<String, dynamic>.from(e as Map)).toList(),
      shopName: shop['name'],
      shopLogo: shop['logo'],
      shopAddress: shop['address'],
      requiresYangoOrder: data['requires_yango_order'] == true,
      yangoInfo: data['yango_info'] as Map<String, dynamic>?,
    );
  }
}

// ── Carte cadeau ─────────────────────────────────────────────────────────────

class GiftCardResult {
  final bool success;
  final String message;
  final bool validationFailed;
  final List<String> details;
  final int? confidence;

  // Succès
  final int? id;
  final int? amount;
  final String? recipientName;
  final String? trackingToken;
  final bool autoActivated;

  GiftCardResult({
    required this.success,
    required this.message,
    this.validationFailed = false,
    this.details = const [],
    this.confidence,
    this.id,
    this.amount,
    this.recipientName,
    this.trackingToken,
    this.autoActivated = false,
  });

  factory GiftCardResult.fromJson(Map<String, dynamic> json) {
    final card = json['gift_card'] as Map<String, dynamic>? ?? {};
    final rawDetails = json['details'];
    return GiftCardResult(
      success: json['success'] ?? false,
      message: json['message'] ?? '',
      validationFailed: json['validation_failed'] == true,
      details: rawDetails is List
          ? rawDetails.map((e) => e.toString()).toList()
          : [],
      confidence: json['confidence'] is num
          ? (json['confidence'] as num).toInt()
          : null,
      id: card['id'] is num ? (card['id'] as num).toInt() : null,
      amount: card['amount'] is num ? (card['amount'] as num).toInt() : null,
      recipientName: card['recipient_name'],
      trackingToken: card['tracking_token'],
      autoActivated: card['auto_activated'] == true,
    );
  }
}

// ── Suivi carte cadeau ───────────────────────────────────────────────────────

class GiftCardTrackData {
  final String code;
  final int amount;
  final int balance;
  final String status;
  final String statusLabel;
  final String shopName;
  final String? shopSlug;
  final String senderName;
  final String recipientName;
  final String? giftMessage;
  final String? expiresAt;
  final String? createdAt;

  GiftCardTrackData({
    required this.code,
    required this.amount,
    required this.balance,
    required this.status,
    required this.statusLabel,
    required this.shopName,
    this.shopSlug,
    required this.senderName,
    required this.recipientName,
    this.giftMessage,
    this.expiresAt,
    this.createdAt,
  });

  factory GiftCardTrackData.fromJson(Map<String, dynamic> json) {
    final data = json['data'] as Map<String, dynamic>? ?? json;
    return GiftCardTrackData(
      code: data['code'] ?? '',
      amount: data['amount'] is num ? (data['amount'] as num).toInt() : 0,
      balance: data['balance'] is num ? (data['balance'] as num).toInt() : 0,
      status: data['status'] ?? '',
      statusLabel: data['status_label'] ?? '',
      shopName: data['shop_name'] ?? '',
      shopSlug: data['shop_slug'],
      senderName: data['sender_name'] ?? '',
      recipientName: data['recipient_name'] ?? '',
      giftMessage: data['gift_message'],
      expiresAt: data['expires_at'],
      createdAt: data['created_at'],
    );
  }
}

// ── Validation code carte ────────────────────────────────────────────────────

class GiftCardValidation {
  final String code;
  final int balance;
  final int amount;
  final String? senderName;
  final String? expiresAt;

  GiftCardValidation({
    required this.code,
    required this.balance,
    required this.amount,
    this.senderName,
    this.expiresAt,
  });

  factory GiftCardValidation.fromJson(Map<String, dynamic> json) {
    final data = json['data'] as Map<String, dynamic>? ?? json;
    return GiftCardValidation(
      code: data['code'] ?? '',
      balance: data['balance'] is num ? (data['balance'] as num).toInt() : 0,
      amount: data['amount'] is num ? (data['amount'] as num).toInt() : 0,
      senderName: data['sender_name'],
      expiresAt: data['expires_at'],
    );
  }
}

// ── Cadeau envoyé (liste my-sent) ────────────────────────────────────────────

class SentGift {
  final int id;
  final String trackingToken;
  final String recipientName;
  final String status;
  final String statusLabel;
  final String shopName;
  final int totalAmount;
  final String? createdAt;
  final bool requiresYangoOrder;

  SentGift({
    required this.id,
    required this.trackingToken,
    required this.recipientName,
    required this.status,
    required this.statusLabel,
    required this.shopName,
    required this.totalAmount,
    this.createdAt,
    this.requiresYangoOrder = false,
  });

  factory SentGift.fromJson(Map<String, dynamic> json) {
    return SentGift(
      id: json['id'] is num ? (json['id'] as num).toInt() : 0,
      trackingToken: json['tracking_token'] ?? '',
      recipientName: json['recipient_name'] ?? '',
      status: json['status'] ?? '',
      statusLabel: json['status_label'] ?? '',
      shopName: json['shop_name'] ?? '',
      totalAmount: json['total_amount'] is num
          ? (json['total_amount'] as num).toInt()
          : 0,
      createdAt: json['created_at'],
      requiresYangoOrder: json['requires_yango_order'] == true,
    );
  }
}
