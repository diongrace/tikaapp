import 'package:http/http.dart' as http;
import 'dart:convert';
import './utils/api_endpoint.dart';
import './models/loyalty_card_model.dart';

class LoyaltyService {
  static const Map<String, String> _headers = {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
  };

  /// 1. Créer une carte de fidélité
  /// Endpoint: POST /client/loyalty/create-card
  static Future<LoyaltyCard> createCard({
    required int shopId,
    required String phone,
    required String customerName,
    String? email,
    String? pinCode,
  }) async {
    final body = {
      'shop_id': shopId,
      'customer_phone': phone,  // L'API attend 'customer_phone', pas 'phone'
      'customer_name': customerName,
      if (email != null) 'email': email,
      if (pinCode != null) 'pin_code': pinCode,
    };

    // Debug: afficher ce qui est envoyé
    print('📤 Création carte fidélité - Body envoyé:');
    print(jsonEncode(body));

    final response = await http.post(
      Uri.parse(Endpoints.loyaltyCreateCard),
      headers: _headers,
      body: jsonEncode(body),
    );

    // Debug: afficher la réponse
    print('📥 Réponse API - Status: ${response.statusCode}');
    print('📥 Réponse API - Body: ${response.body}');

    if (response.statusCode == 200) {
      try {
        final data = jsonDecode(response.body);
        print('📊 Data décodée: $data');

        // Vérifier la structure de la réponse
        if (data == null) {
          throw Exception('Réponse API vide');
        }

        if (data['data'] == null) {
          throw Exception('Champ "data" manquant dans la réponse');
        }

        // L'API peut retourner soit "loyalty_card" soit "card"
        final cardData = data['data']['loyalty_card'] ?? data['data']['card'];

        if (cardData == null) {
          throw Exception('Aucune carte trouvée dans la réponse');
        }

        print('📇 Carte de fidélité reçue: $cardData');
        return LoyaltyCard.fromJson(cardData);
      } catch (e) {
        print('❌ Erreur lors du parsing: $e');
        rethrow;
      }
    } else {
      final data = jsonDecode(response.body);
      // Extraire les erreurs de validation si disponibles
      if (data['errors'] != null) {
        final errors = data['errors'] as Map<String, dynamic>;
        final errorMessages = errors.values.map((e) => e.toString()).join(', ');
        throw Exception(errorMessages);
      }
      throw Exception(data['message'] ?? 'Erreur lors de la création de la carte');
    }
  }

  /// 2. Récupérer une carte de fidélité
  /// Endpoint: GET /client/loyalty/shops/{shopId}?phone={phone}
  static Future<LoyaltyCard?> getCard({
    required int shopId,
    required String phone,
  }) async {
    final uri = Uri.parse(Endpoints.loyaltyCardByPhone(shopId))
        .replace(queryParameters: {'phone': phone});

    final response = await http.get(uri, headers: _headers);

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return LoyaltyCard.fromJson(data['data']['loyalty_card']);
    } else if (response.statusCode == 404) {
      // Aucune carte trouvée
      return null;
    } else {
      final data = jsonDecode(response.body);
      throw Exception(data['message'] ?? 'Erreur lors de la récupération de la carte');
    }
  }

  /// 3. Calculer une réduction fidélité
  /// Endpoint: POST /client/loyalty/calculate-discount
  static Future<LoyaltyDiscount> calculateDiscount({
    required int cardId,
    required int pointsToUse,
    required int orderTotal,
  }) async {
    final body = {
      'card_id': cardId,
      'points_to_use': pointsToUse,
      'order_total': orderTotal,
    };

    final response = await http.post(
      Uri.parse(Endpoints.loyaltyCalculateDiscount),
      headers: _headers,
      body: jsonEncode(body),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return LoyaltyDiscount.fromJson(data['data']);
    } else {
      final data = jsonDecode(response.body);
      throw Exception(data['message'] ?? 'Erreur lors du calcul de la réduction');
    }
  }

  /// 4. Vérifier si une carte existe
  /// Utile avant de créer ou d'afficher le formulaire
  static Future<bool> hasCard({
    required int shopId,
    required String phone,
  }) async {
    try {
      final card = await getCard(shopId: shopId, phone: phone);
      return card != null;
    } catch (e) {
      return false;
    }
  }

  /// 5. Valider carte avec code PIN
  /// Endpoint: POST /client/loyalty/validate-pin
  static Future<Map<String, dynamic>> validateWithPIN({
    required String cardNumber,
    required int shopId,
    required String pinCode,
  }) async {
    final body = {
      'card_number': cardNumber,
      'shop_id': shopId,
      'pin_code': pinCode,
    };

    final response = await http.post(
      Uri.parse(Endpoints.loyaltyValidatePIN),
      headers: _headers,
      body: jsonEncode(body),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return {
        'success': data['success'],
        'valid': data['data']['valid'],
        'message': data['message'],
      };
    } else {
      final data = jsonDecode(response.body);
      throw Exception(data['message'] ?? 'Code PIN invalide');
    }
  }
}
