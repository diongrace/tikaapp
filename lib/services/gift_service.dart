import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'dart:convert';
import './utils/api_endpoint.dart';
import './models/gift_model.dart';

/// Service cadeaux & cartes d'achat (API publique, sans auth)
class GiftService {
  static const Map<String, String> _headers = {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
  };

  static const Map<String, String> _multipartHeaders = {
    'Accept': 'application/json',
  };

  // ── Commandes cadeaux ──────────────────────────────────────────────────────

  /// POST /gifts — Créer une commande cadeau
  ///
  /// payment_method: 'especes' → commande créée immédiatement
  /// payment_method: 'mobile_money' → retourne wave_url + pending_id
  static Future<GiftOrderResult> createGiftOrder({
    required int shopId,
    required String senderName,
    required String senderPhone,
    required String recipientName,
    required String recipientPhone,
    required List<Map<String, dynamic>> items,
    String paymentMethod = 'especes',
    String? senderEmail,
    String? recipientEmail,
    String? deliveryAddress,
    double? deliveryLatitude,
    double? deliveryLongitude,
    String? giftMessage,
    int? customerUserId,
  }) async {
    final body = <String, dynamic>{
      'shop_id': shopId,
      'sender_name': senderName,
      'sender_phone': senderPhone,
      'recipient_name': recipientName,
      'recipient_phone': recipientPhone,
      'payment_method': paymentMethod,
      'items': items,
      if (senderEmail != null && senderEmail.isNotEmpty) 'sender_email': senderEmail,
      if (recipientEmail != null && recipientEmail.isNotEmpty) 'recipient_email': recipientEmail,
      if (deliveryAddress != null && deliveryAddress.isNotEmpty) 'delivery_address': deliveryAddress,
      if (deliveryLatitude != null) 'delivery_latitude': deliveryLatitude,
      if (deliveryLongitude != null) 'delivery_longitude': deliveryLongitude,
      if (giftMessage != null && giftMessage.isNotEmpty) 'gift_message': giftMessage,
      if (customerUserId != null) 'customer_user_id': customerUserId,
    };

    print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    print('📤 POST CREATE GIFT ORDER');
    print('🔗 ${Endpoints.gifts}');
    print('💳 payment_method: $paymentMethod');
    print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');

    try {
      final response = await http.post(
        Uri.parse(Endpoints.gifts),
        headers: _headers,
        body: jsonEncode(body),
      );

      print('📥 Status: ${response.statusCode}');
      print('📥 Body: ${response.body}');

      final data = jsonDecode(response.body) as Map<String, dynamic>;

      if (response.statusCode == 200 || response.statusCode == 201) {
        print('✅ Gift order result received');
        print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
        return GiftOrderResult.fromJson(data);
      } else {
        throw Exception(data['message'] ?? 'Erreur lors de la création du cadeau');
      }
    } catch (e) {
      print('❌ Exception: $e');
      print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
      rethrow;
    }
  }

  /// POST /gifts/validate-wave-pending — Upload capture Wave + création commande
  ///
  /// multipart/form-data: pending_id + screenshot
  static Future<GiftOrderResult> validateWavePending({
    required String pendingId,
    required String screenshotPath,
  }) async {
    print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    print('📤 POST VALIDATE WAVE PENDING (GIFT)');
    print('🔗 ${Endpoints.giftsValidateWavePending}');
    print('📸 $screenshotPath');
    print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');

    try {
      final request = http.MultipartRequest(
        'POST', Uri.parse(Endpoints.giftsValidateWavePending));
      request.headers.addAll(_multipartHeaders);
      request.fields['pending_id'] = pendingId;
      request.files.add(await http.MultipartFile.fromPath(
        'screenshot', screenshotPath,
        contentType: MediaType('image', _mimeType(screenshotPath)),
      ));

      final streamed = await request.send();
      final response = await http.Response.fromStream(streamed);

      print('📥 Status: ${response.statusCode}');
      print('📥 Body: ${response.body}');

      final data = jsonDecode(response.body) as Map<String, dynamic>;

      if (response.statusCode == 200 || response.statusCode == 201) {
        print('✅ Wave validated, gift order created');
        print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
        return GiftOrderResult.fromJson(data);
      } else if (response.statusCode == 422) {
        throw GiftValidationException(
          message: data['message'] ?? 'Validation échouée',
          details: _parseDetails(data['details']),
          validationFailed: data['validation_failed'] == true,
        );
      } else {
        throw Exception(data['message'] ?? 'Erreur de validation');
      }
    } catch (e) {
      print('❌ Exception: $e');
      print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
      rethrow;
    }
  }

  /// POST /gifts/{id}/wave-proof — Upload capture pour commande existante
  static Future<void> uploadWaveProof({
    required int giftOrderId,
    required String screenshotPath,
  }) async {
    print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    print('📤 POST GIFT WAVE PROOF');
    print('🔗 ${Endpoints.giftWaveProof(giftOrderId)}');
    print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');

    try {
      final request = http.MultipartRequest(
        'POST', Uri.parse(Endpoints.giftWaveProof(giftOrderId)));
      request.headers.addAll(_multipartHeaders);
      request.files.add(await http.MultipartFile.fromPath(
        'screenshot', screenshotPath,
        contentType: MediaType('image', _mimeType(screenshotPath)),
      ));

      final streamed = await request.send();
      final response = await http.Response.fromStream(streamed);

      print('📥 Status: ${response.statusCode}');

      if (response.statusCode != 200 && response.statusCode != 201) {
        final data = jsonDecode(response.body);
        throw Exception(data['message'] ?? 'Erreur lors de l\'upload');
      }
      print('✅ Wave proof uploaded');
      print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    } catch (e) {
      print('❌ Exception: $e');
      print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
      rethrow;
    }
  }

  /// POST /gifts/{trackingToken}/confirm-payment
  static Future<void> confirmGiftPayment(String trackingToken) async {
    final response = await http.post(
      Uri.parse(Endpoints.giftConfirmPayment(trackingToken)),
      headers: _headers,
    );
    if (response.statusCode != 200) {
      final data = jsonDecode(response.body);
      throw Exception(data['message'] ?? 'Erreur de confirmation');
    }
  }

  /// GET /gifts/{trackingToken}/track
  static Future<GiftTrackData> trackGiftOrder(String trackingToken) async {
    print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    print('📤 GET TRACK GIFT ORDER: $trackingToken');
    print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');

    final response = await http.get(
      Uri.parse(Endpoints.giftTrack(trackingToken)),
      headers: _headers,
    );

    print('📥 Status: ${response.statusCode}');

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return GiftTrackData.fromJson(data);
    } else {
      final data = jsonDecode(response.body);
      throw Exception(data['message'] ?? 'Commande cadeau introuvable');
    }
  }

  /// POST /gifts/{trackingToken}/confirm-yango
  static Future<void> confirmYangoOrder({
    required String trackingToken,
    required String yangoOrderId,
  }) async {
    final response = await http.post(
      Uri.parse(Endpoints.giftConfirmYango(trackingToken)),
      headers: _headers,
      body: jsonEncode({'yango_order_id': yangoOrderId}),
    );
    if (response.statusCode != 200) {
      final data = jsonDecode(response.body);
      throw Exception(data['message'] ?? 'Erreur confirmation Yango');
    }
  }

  /// GET /gifts/my-sent?phone=...
  static Future<List<SentGift>> getMySentGifts(String phone) async {
    final uri = Uri.parse(Endpoints.giftsMySent)
        .replace(queryParameters: {'phone': phone});
    final response = await http.get(uri, headers: _headers);
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final list = data['data'] as List? ?? [];
      print('🎁 [my-sent] raw first item: ${list.isNotEmpty ? list.first : "vide"}');
      return list.map((e) => SentGift.fromJson(e as Map<String, dynamic>)).toList();
    } else {
      final data = jsonDecode(response.body);
      throw Exception(data['message'] ?? 'Erreur');
    }
  }

  /// POST /gifts/cancel-pending
  static Future<void> cancelPendingGift(String pendingId) async {
    final response = await http.post(
      Uri.parse(Endpoints.giftsCancelPending),
      headers: _headers,
      body: jsonEncode({'pending_id': pendingId}),
    );
    if (response.statusCode != 200) {
      final data = jsonDecode(response.body);
      throw Exception(data['message'] ?? 'Erreur d\'annulation');
    }
  }

  /// POST /gifts/{id}/cancel
  static Future<void> cancelGiftOrder(int giftOrderId) async {
    final response = await http.post(
      Uri.parse(Endpoints.giftCancel(giftOrderId)),
      headers: _headers,
    );
    if (response.statusCode != 200) {
      final data = jsonDecode(response.body);
      throw Exception(data['message'] ?? 'Erreur d\'annulation');
    }
  }

  // ── Cartes d'achat ─────────────────────────────────────────────────────────

  /// POST /gift-cards — Créer une carte cadeau (multipart, screenshot Wave requis)
  static Future<GiftCardResult> createGiftCard({
    required int shopId,
    required int amount,
    required String senderName,
    required String senderPhone,
    required String recipientName,
    required String recipientPhone,
    required String screenshotPath,
    String? senderEmail,
    String? recipientEmail,
    String? giftMessage,
    int? customerUserId,
  }) async {
    print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    print('📤 POST CREATE GIFT CARD');
    print('🔗 ${Endpoints.giftCards}');
    print('💰 amount: $amount');
    print('📸 screenshot: $screenshotPath');
    print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');

    try {
      final request = http.MultipartRequest(
          'POST', Uri.parse(Endpoints.giftCards));
      request.headers.addAll(_multipartHeaders);

      request.fields['shop_id'] = shopId.toString();
      request.fields['amount'] = amount.toString();
      request.fields['sender_name'] = senderName;
      request.fields['sender_phone'] = senderPhone;
      request.fields['recipient_name'] = recipientName;
      request.fields['recipient_phone'] = recipientPhone;
      if (senderEmail != null && senderEmail.isNotEmpty) {
        request.fields['sender_email'] = senderEmail;
      }
      if (recipientEmail != null && recipientEmail.isNotEmpty) {
        request.fields['recipient_email'] = recipientEmail;
      }
      if (giftMessage != null && giftMessage.isNotEmpty) {
        request.fields['gift_message'] = giftMessage;
      }
      if (customerUserId != null) {
        request.fields['customer_user_id'] = customerUserId.toString();
      }

      request.files.add(await http.MultipartFile.fromPath(
        'screenshot', screenshotPath,
        contentType: MediaType('image', _mimeType(screenshotPath)),
      ));

      final streamed = await request.send();
      final response = await http.Response.fromStream(streamed);

      print('📥 Status: ${response.statusCode}');
      print('📥 Body: ${response.body}');

      final data = jsonDecode(response.body) as Map<String, dynamic>;

      if (response.statusCode == 200 || response.statusCode == 201) {
        print('✅ Gift card created');
        print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
        return GiftCardResult.fromJson(data);
      } else if (response.statusCode == 422) {
        // Peut être un échec OCR ou une erreur de validation
        final result = GiftCardResult.fromJson(data);
        if (result.validationFailed) return result;
        throw Exception(data['message'] ?? 'Erreur de validation');
      } else {
        throw Exception(data['message'] ?? 'Erreur lors de la création de la carte');
      }
    } catch (e) {
      print('❌ Exception: $e');
      print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
      rethrow;
    }
  }

  /// POST /gift-cards/validate — Valider un code carte au checkout
  static Future<GiftCardValidation> validateGiftCard({
    required String code,
    required int shopId,
  }) async {
    final response = await http.post(
      Uri.parse(Endpoints.giftCardsValidate),
      headers: _headers,
      body: jsonEncode({'code': code, 'shop_id': shopId}),
    );

    if (response.statusCode == 200) {
      return GiftCardValidation.fromJson(jsonDecode(response.body));
    } else {
      final data = jsonDecode(response.body);
      throw Exception(data['message'] ?? 'Code invalide');
    }
  }

  /// GET /gift-cards/track/{trackingToken}
  static Future<GiftCardTrackData> trackGiftCard(String trackingToken) async {
    final response = await http.get(
      Uri.parse(Endpoints.giftCardTrack(trackingToken)),
      headers: _headers,
    );

    if (response.statusCode == 200) {
      return GiftCardTrackData.fromJson(jsonDecode(response.body));
    } else {
      final data = jsonDecode(response.body);
      throw Exception(data['message'] ?? 'Carte introuvable');
    }
  }

  // ── Helpers ────────────────────────────────────────────────────────────────

  static String _mimeType(String path) {
    final ext = path.split('.').last.toLowerCase();
    switch (ext) {
      case 'png': return 'png';
      case 'webp': return 'webp';
      default: return 'jpeg';
    }
  }

  static List<String> _parseDetails(dynamic raw) {
    if (raw is List) return raw.map((e) => e.toString()).toList();
    if (raw is String) return [raw];
    return [];
  }
}

// ── Exception OCR ─────────────────────────────────────────────────────────────

class GiftValidationException implements Exception {
  final String message;
  final List<String> details;
  final bool validationFailed;

  GiftValidationException({
    required this.message,
    this.details = const [],
    this.validationFailed = true,
  });

  @override
  String toString() => message;
}
