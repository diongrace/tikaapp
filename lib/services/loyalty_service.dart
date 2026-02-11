import 'package:http/http.dart' as http;
import 'dart:convert';
import './utils/api_endpoint.dart';
import './models/loyalty_card_model.dart';
import './auth_service.dart';

/// Service pour gerer les cartes de fidelite
/// Endpoints:
/// 1. GET    /client/loyalty                      - Toutes mes cartes
/// 2. GET    /client/loyalty/cards/{id}           - Detail carte
/// 3. GET    /client/loyalty/shops/{id}           - Carte pour une boutique
/// 4. POST   /client/loyalty/cards                - Creer une carte
/// 5. GET    /client/loyalty/cards/{id}/history   - Historique
/// 6. GET    /client/loyalty/cards/{id}/rewards   - Recompenses
/// 7. GET    /client/loyalty/cards/{id}/qr-code   - QR Code
/// 8. POST   /client/loyalty/cards/{id}/verify-pin - Verifier PIN
/// 9. GET    /client/loyalty/stats                - Statistiques
class LoyaltyService {
  static Map<String, String> get _headers => {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        if (AuthService.authToken != null)
          'Authorization': 'Bearer ${AuthService.authToken}',
      };

  // ============================================================
  // 1. GET /client/loyalty - Toutes mes cartes
  // ============================================================

  static Future<List<LoyaltyCard>> getMyCards() async {
    try {
      await AuthService.ensureToken();
      print('GET /client/loyalty');
      final response = await http.get(
        Uri.parse(Endpoints.loyaltyCards),
        headers: _headers,
      );
      print('Status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true && data['data'] != null) {
          final cardsData = data['data']['cards'];
          if (cardsData is List) {
            final cards = cardsData
                .map((e) => LoyaltyCard.fromJson(e as Map<String, dynamic>))
                .toList();
            print('${cards.length} cartes recuperees');
            return cards;
          }
        }
        return [];
      } else if (response.statusCode == 401) {
        throw Exception('Authentification requise');
      } else {
        throw Exception('Erreur ${response.statusCode}');
      }
    } catch (e) {
      print('Erreur getMyCards: $e');
      rethrow;
    }
  }

  // ============================================================
  // 2. GET /client/loyalty/cards/{id} - Detail carte
  // ============================================================

  static Future<LoyaltyCardDetail> getCardDetail(int cardId) async {
    try {
      await AuthService.ensureToken();
      print('GET /client/loyalty/cards/$cardId');
      final response = await http.get(
        Uri.parse(Endpoints.loyaltyCardDetail(cardId)),
        headers: _headers,
      );
      print('Status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true && data['data'] != null) {
          final responseData = data['data'];

          final card = LoyaltyCard.fromJson(responseData['card'] as Map<String, dynamic>);

          final rewards = (responseData['rewards'] as List?)
              ?.map((e) => LoyaltyReward.fromJson(e as Map<String, dynamic>))
              .toList() ?? [];

          final transactions = (responseData['recent_transactions'] as List?)
              ?.map((e) => LoyaltyTransaction.fromJson(e as Map<String, dynamic>))
              .toList() ?? [];

          print('Detail carte: ${card.points} pts, ${rewards.length} recompenses, ${transactions.length} transactions');
          return LoyaltyCardDetail(
            card: card,
            rewards: rewards,
            recentTransactions: transactions,
          );
        }
        throw Exception('Reponse invalide');
      } else if (response.statusCode == 404) {
        throw Exception('Carte introuvable');
      } else {
        throw Exception('Erreur ${response.statusCode}');
      }
    } catch (e) {
      print('Erreur getCardDetail: $e');
      rethrow;
    }
  }

  // ============================================================
  // 3. GET /client/loyalty/shops/{id} - Carte pour une boutique
  // ============================================================

  static Future<LoyaltyCard?> getCardForShop(int shopId) async {
    try {
      await AuthService.ensureToken();
      print('GET /client/loyalty/shops/$shopId');
      final response = await http.get(
        Uri.parse(Endpoints.loyaltyCardByShop(shopId)),
        headers: _headers,
      );
      print('Status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true && data['data'] != null) {
          final hasCard = data['data']['has_card'] == true;
          if (hasCard && data['data']['card'] != null) {
            return LoyaltyCard.fromJson(data['data']['card'] as Map<String, dynamic>);
          }
        }
        return null;
      } else if (response.statusCode == 404) {
        return null;
      } else {
        throw Exception('Erreur ${response.statusCode}');
      }
    } catch (e) {
      print('Erreur getCardForShop: $e');
      if (e.toString().contains('404')) return null;
      rethrow;
    }
  }

  // ============================================================
  // 4. POST /client/loyalty/cards - Creer une carte
  // ============================================================

  /// Cree une carte de fidelite. Seul shop_id est requis.
  /// Le PIN est auto-genere depuis les 4 derniers chiffres du telephone.
  static Future<LoyaltyCard> createCard({required int shopId}) async {
    try {
      await AuthService.ensureToken();
      print('POST /client/loyalty/cards (shop_id: $shopId)');
      final response = await http.post(
        Uri.parse(Endpoints.loyaltyCreateCard),
        headers: _headers,
        body: jsonEncode({'shop_id': shopId}),
      );
      print('Status: ${response.statusCode}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body);
        final cardData = data['data']?['card'];
        if (cardData == null) {
          throw Exception('Carte non trouvee dans la reponse');
        }
        print('Carte creee');
        return LoyaltyCard.fromJson(cardData as Map<String, dynamic>);
      } else if (response.statusCode == 422) {
        final data = jsonDecode(response.body);
        throw Exception(data['message'] ?? 'Programme fidelite non actif');
      } else {
        final data = jsonDecode(response.body);
        throw Exception(data['message'] ?? 'Erreur lors de la creation');
      }
    } catch (e) {
      print('Erreur createCard: $e');
      rethrow;
    }
  }

  // ============================================================
  // 5. GET /client/loyalty/cards/{id}/history - Historique
  // ============================================================

  static Future<List<LoyaltyTransaction>> getCardHistory(
    int cardId, {
    String type = 'all',
    int perPage = 20,
  }) async {
    try {
      await AuthService.ensureToken();
      final uri = Uri.parse(Endpoints.loyaltyCardHistory(cardId)).replace(
        queryParameters: {
          'type': type,
          'per_page': perPage.toString(),
        },
      );

      print('GET /client/loyalty/cards/$cardId/history?type=$type');
      final response = await http.get(uri, headers: _headers);
      print('Status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true && data['data'] != null) {
          final transactions = data['data']['transactions'];
          if (transactions is List) {
            return transactions
                .map((e) => LoyaltyTransaction.fromJson(e as Map<String, dynamic>))
                .toList();
          }
        }
        return [];
      } else {
        throw Exception('Erreur ${response.statusCode}');
      }
    } catch (e) {
      print('Erreur getCardHistory: $e');
      rethrow;
    }
  }

  // ============================================================
  // 6. GET /client/loyalty/cards/{id}/rewards - Recompenses
  // ============================================================

  /// Retourne { 'available': [...], 'upcoming': [...] }
  static Future<Map<String, List<LoyaltyReward>>> getCardRewards(int cardId) async {
    try {
      await AuthService.ensureToken();
      print('GET /client/loyalty/cards/$cardId/rewards');
      final response = await http.get(
        Uri.parse(Endpoints.loyaltyCardRewards(cardId)),
        headers: _headers,
      );
      print('Status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true && data['data'] != null) {
          final available = (data['data']['available_rewards'] as List?)
              ?.map((e) => LoyaltyReward.fromJson(e as Map<String, dynamic>))
              .toList() ?? [];
          final upcoming = (data['data']['upcoming_rewards'] as List?)
              ?.map((e) => LoyaltyReward.fromJson(e as Map<String, dynamic>))
              .toList() ?? [];
          return {'available': available, 'upcoming': upcoming};
        }
        return {'available': [], 'upcoming': []};
      } else {
        throw Exception('Erreur ${response.statusCode}');
      }
    } catch (e) {
      print('Erreur getCardRewards: $e');
      return {'available': [], 'upcoming': []};
    }
  }

  // ============================================================
  // 7. GET /client/loyalty/cards/{id}/qr-code - QR Code
  // ============================================================

  /// Retourne { 'qr_code': '...', 'qr_data': '{"type":"loyalty_card",...}' }
  static Future<Map<String, String>> getCardQrCode(int cardId) async {
    try {
      await AuthService.ensureToken();
      print('GET /client/loyalty/cards/$cardId/qr-code');
      final response = await http.get(
        Uri.parse(Endpoints.loyaltyCardQrCode(cardId)),
        headers: _headers,
      );
      print('Status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true && data['data'] != null) {
          return {
            'qr_code': data['data']['qr_code']?.toString() ?? '',
            'qr_data': data['data']['qr_data']?.toString() ?? '',
          };
        }
        return {};
      } else {
        throw Exception('Erreur ${response.statusCode}');
      }
    } catch (e) {
      print('Erreur getCardQrCode: $e');
      rethrow;
    }
  }

  // ============================================================
  // 8. POST /client/loyalty/cards/{id}/verify-pin - Verifier PIN
  // ============================================================

  static Future<Map<String, dynamic>> verifyPin({
    required int cardId,
    required String pinCode,
  }) async {
    try {
      await AuthService.ensureToken();
      print('POST /client/loyalty/cards/$cardId/verify-pin');
      final response = await http.post(
        Uri.parse(Endpoints.loyaltyCardVerifyPin(cardId)),
        headers: _headers,
        body: jsonEncode({'pin_code': pinCode}),
      );
      print('Status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {
          'success': true,
          'verified': data['data']?['verified'] ?? true,
          'message': data['message'],
        };
      } else {
        final data = jsonDecode(response.body);
        throw Exception(data['message'] ?? 'Code PIN invalide');
      }
    } catch (e) {
      print('Erreur verifyPin: $e');
      rethrow;
    }
  }

  // ============================================================
  // 9. GET /client/loyalty/stats - Statistiques
  // ============================================================

  static Future<Map<String, dynamic>> getStats() async {
    try {
      await AuthService.ensureToken();
      print('GET /client/loyalty/stats');
      final response = await http.get(
        Uri.parse(Endpoints.loyaltyStats),
        headers: _headers,
      );
      print('Status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          return data['data'] ?? {};
        }
        return {};
      } else {
        throw Exception('Erreur ${response.statusCode}');
      }
    } catch (e) {
      print('Erreur getStats: $e');
      return {};
    }
  }

  // ============================================================
  // HELPERS
  // ============================================================

  /// Verifier si le client a une carte pour une boutique
  static Future<bool> hasCard(int shopId) async {
    final card = await getCardForShop(shopId);
    return card != null;
  }

  /// Calculer une reduction fidelite
  static Future<LoyaltyDiscount> calculateDiscount({
    required int cardId,
    required int pointsToUse,
    required int orderTotal,
  }) async {
    await AuthService.ensureToken();
    final body = {
      'card_id': cardId,
      'points_to_use': pointsToUse,
      'order_total': orderTotal,
    };

    print('POST /client/loyalty/calculate-discount');
    final response = await http.post(
      Uri.parse(Endpoints.loyaltyCalculateDiscount),
      headers: _headers,
      body: jsonEncode(body),
    );
    print('Status: ${response.statusCode}');

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return LoyaltyDiscount.fromJson(data['data']);
    } else {
      final data = jsonDecode(response.body);
      throw Exception(data['message'] ?? 'Erreur lors du calcul');
    }
  }
}
