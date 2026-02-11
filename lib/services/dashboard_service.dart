import 'package:http/http.dart' as http;
import 'dart:convert';
import './utils/api_endpoint.dart';
import './models/dashboard_model.dart';
import './models/order_model.dart';
import './models/loyalty_card_model.dart';
import './auth_service.dart';

/// Service du tableau de bord client
///
/// IMPORTANT: Nécessite une authentification Bearer Token
/// Tous les endpoints dashboard requièrent un client connecté.
class DashboardService {
  /// Headers avec authentification Bearer
  static Map<String, String> get _headers => {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        if (AuthService.authToken != null)
          'Authorization': 'Bearer ${AuthService.authToken}',
      };

  /// Vérifier l'authentification
  static bool get _isAuthenticated => AuthService.isAuthenticated;

  /// S'assurer que le token est disponible
  static Future<void> _ensureAuth() async {
    await AuthService.ensureToken();
  }

  // ============================================================
  // VUE D'ENSEMBLE
  // ============================================================

  /// GET /client/dashboard - Vue d'ensemble du dashboard
  ///
  /// Retourne un résumé global: commandes, fidélité, favoris, notifications
  static Future<DashboardOverview> getOverview() async {
    await _ensureAuth();
    if (!_isAuthenticated) {
      throw Exception('Authentification requise pour accéder au dashboard');
    }

    print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    print('📤 GET DASHBOARD OVERVIEW');
    print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');

    try {
      final response = await http.get(
        Uri.parse(Endpoints.dashboard),
        headers: _headers,
      );

      print('📥 Response Status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        print('📥 Response Body complet: ${response.body}');
        final overviewData = data['data'] ?? data;
        print('✅ Dashboard overview récupéré');
        print('   Keys dans data: ${overviewData.keys.toList()}');
        print('   total_orders: ${overviewData['total_orders']}');
        print('   orders_count: ${overviewData['orders_count']}');
        print('   favorites_count: ${overviewData['favorites_count']}');
        print('   total_spent: ${overviewData['total_spent']}');
        print('   stats: ${overviewData['stats']}');
        print('   overview: ${overviewData['overview']}');
        print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
        return DashboardOverview.fromJson(overviewData);
      } else if (response.statusCode == 401) {
        throw Exception('Session expirée. Veuillez vous reconnecter.');
      } else {
        final data = jsonDecode(response.body);
        throw Exception(data['message'] ?? 'Erreur lors du chargement du dashboard');
      }
    } catch (e) {
      print('❌ Exception: $e');
      print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
      rethrow;
    }
  }

  // ============================================================
  // HISTORIQUE COMMANDES
  // ============================================================

  /// GET /client/dashboard/orders - Historique des commandes
  ///
  /// [page] - Numéro de page
  /// [perPage] - Nombre par page
  /// [status] - Filtrer par statut (optionnel)
  static Future<DashboardPaginatedResponse<Order>> getOrders({
    int page = 1,
    int perPage = 20,
    String? status,
  }) async {
    if (!_isAuthenticated) {
      throw Exception('Authentification requise');
    }

    print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    print('📤 GET DASHBOARD ORDERS');
    print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');

    try {
      final queryParams = <String, String>{
        'page': page.toString(),
        'per_page': perPage.toString(),
      };
      if (status != null) queryParams['status'] = status;

      final uri = Uri.parse(Endpoints.dashboardOrders)
          .replace(queryParameters: queryParams);

      final response = await http.get(uri, headers: _headers);

      print('📥 Response Status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final responseData = data['data'] ?? data;

        final orders = (responseData['orders'] as List? ??
                responseData['data'] as List? ??
                [])
            .map((e) => Order.fromJson(e))
            .toList();

        final pagination = responseData['pagination'] as Map<String, dynamic>? ??
            responseData['meta'] as Map<String, dynamic>? ??
            {};

        print('✅ ${orders.length} commande(s) récupérée(s)');
        print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');

        return DashboardPaginatedResponse<Order>(
          items: orders,
          currentPage: pagination['current_page'] ?? page,
          lastPage: pagination['last_page'] ?? 1,
          total: pagination['total'] ?? orders.length,
        );
      } else if (response.statusCode == 401) {
        throw Exception('Session expirée. Veuillez vous reconnecter.');
      } else {
        final data = jsonDecode(response.body);
        throw Exception(data['message'] ?? 'Erreur lors du chargement des commandes');
      }
    } catch (e) {
      print('❌ Exception: $e');
      print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
      rethrow;
    }
  }

  // ============================================================
  // DÉTAIL COMMANDE
  // ============================================================

  /// GET /client/dashboard/orders/{id} - Détail d'une commande
  static Future<Order> getOrderDetails(int orderId) async {
    if (!_isAuthenticated) {
      throw Exception('Authentification requise');
    }

    print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    print('📤 GET DASHBOARD ORDER DETAILS #$orderId');
    print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');

    try {
      final response = await http.get(
        Uri.parse(Endpoints.dashboardOrderDetails(orderId)),
        headers: _headers,
      );

      print('📥 Response Status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final orderData = data['data'] ?? data['order'] ?? data;
        print('✅ Détails commande #$orderId récupérés');
        print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
        return Order.fromJson(orderData);
      } else if (response.statusCode == 404) {
        throw Exception('Commande introuvable');
      } else if (response.statusCode == 401) {
        throw Exception('Session expirée. Veuillez vous reconnecter.');
      } else {
        final data = jsonDecode(response.body);
        throw Exception(data['message'] ?? 'Erreur lors du chargement de la commande');
      }
    } catch (e) {
      print('❌ Exception: $e');
      print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
      rethrow;
    }
  }

  // ============================================================
  // CARTES DE FIDÉLITÉ
  // ============================================================

  /// GET /client/dashboard/loyalty - Cartes de fidélité du client
  static Future<List<LoyaltyCard>> getLoyaltyCards() async {
    await _ensureAuth();
    if (!_isAuthenticated) {
      throw Exception('Authentification requise');
    }

    print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    print('📤 GET DASHBOARD LOYALTY CARDS');
    print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');

    try {
      final response = await http.get(
        Uri.parse(Endpoints.dashboardLoyalty),
        headers: _headers,
      );

      print('📥 Response Status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final cardsData = data['data'] ?? data['cards'] ?? data;

        List<LoyaltyCard> cards;
        if (cardsData is List) {
          cards = cardsData.map((e) => LoyaltyCard.fromJson(e)).toList();
        } else if (cardsData is Map && cardsData['cards'] != null) {
          cards = (cardsData['cards'] as List)
              .map((e) => LoyaltyCard.fromJson(e))
              .toList();
        } else {
          cards = [];
        }

        print('✅ ${cards.length} carte(s) de fidélité récupérée(s)');
        print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
        return cards;
      } else if (response.statusCode == 401) {
        throw Exception('Session expirée. Veuillez vous reconnecter.');
      } else {
        final data = jsonDecode(response.body);
        throw Exception(data['message'] ?? 'Erreur lors du chargement des cartes');
      }
    } catch (e) {
      print('❌ Exception: $e');
      print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
      rethrow;
    }
  }

  // ============================================================
  // FAVORIS
  // ============================================================

  /// GET /client/dashboard/favorites - Favoris du client
  static Future<List<DashboardFavorite>> getFavorites() async {
    if (!_isAuthenticated) {
      throw Exception('Authentification requise');
    }

    print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    print('📤 GET DASHBOARD FAVORITES');
    print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');

    try {
      final response = await http.get(
        Uri.parse(Endpoints.dashboardFavorites),
        headers: _headers,
      );

      print('📥 Response Status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        print('📥 Favorites Response Body: ${response.body}');
        final favoritesData = data['data'] ?? data['favorites'] ?? data;

        List<DashboardFavorite> favorites;
        if (favoritesData is List) {
          favorites = favoritesData
              .map((e) => DashboardFavorite.fromJson(e))
              .toList();
        } else if (favoritesData is Map) {
          // Chercher la liste dans plusieurs clés possibles
          final list = favoritesData['favorites'] ??
              favoritesData['data'] ??
              favoritesData['shops'];
          if (list is List) {
            favorites = list
                .map((e) => DashboardFavorite.fromJson(e))
                .toList();
          } else {
            favorites = [];
          }
        } else {
          favorites = [];
        }

        print('✅ ${favorites.length} favori(s) récupéré(s)');
        print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
        return favorites;
      } else if (response.statusCode == 401) {
        throw Exception('Session expirée. Veuillez vous reconnecter.');
      } else {
        final data = jsonDecode(response.body);
        throw Exception(data['message'] ?? 'Erreur lors du chargement des favoris');
      }
    } catch (e) {
      print('❌ Exception: $e');
      print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
      rethrow;
    }
  }

  // ============================================================
  // STATISTIQUES
  // ============================================================

  /// GET /client/dashboard/stats - Statistiques du client
  static Future<DashboardStats> getStats() async {
    if (!_isAuthenticated) {
      throw Exception('Authentification requise');
    }

    print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    print('📤 GET DASHBOARD STATS');
    print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');

    try {
      final response = await http.get(
        Uri.parse(Endpoints.dashboardStats),
        headers: _headers,
      );

      print('📥 Response Status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        print('📥 Stats Response Body: ${response.body}');
        final statsData = data['data'] ?? data['stats'] ?? data;
        print('✅ Statistiques récupérées');
        print('   Keys dans statsData: ${statsData is Map ? (statsData as Map).keys.toList() : 'pas un Map'}');
        print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
        return DashboardStats.fromJson(statsData);
      } else if (response.statusCode == 401) {
        throw Exception('Session expirée. Veuillez vous reconnecter.');
      } else {
        final data = jsonDecode(response.body);
        throw Exception(data['message'] ?? 'Erreur lors du chargement des statistiques');
      }
    } catch (e) {
      print('❌ Exception: $e');
      print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
      rethrow;
    }
  }

  // ============================================================
  // NOTIFICATIONS
  // ============================================================

  /// GET /client/dashboard/notifications - Notifications du client
  ///
  /// [page] - Numéro de page
  /// [perPage] - Nombre par page
  static Future<DashboardPaginatedResponse<DashboardNotification>>
      getNotifications({
    int page = 1,
    int perPage = 20,
  }) async {
    if (!_isAuthenticated) {
      throw Exception('Authentification requise');
    }

    print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    print('📤 GET DASHBOARD NOTIFICATIONS');
    print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');

    try {
      final queryParams = <String, String>{
        'page': page.toString(),
        'per_page': perPage.toString(),
      };

      final uri = Uri.parse(Endpoints.dashboardNotifications)
          .replace(queryParameters: queryParams);

      final response = await http.get(uri, headers: _headers);

      print('📥 Response Status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final responseData = data['data'] ?? data;

        final notifications = (responseData['notifications'] as List? ??
                responseData['data'] as List? ??
                [])
            .map((e) => DashboardNotification.fromJson(e))
            .toList();

        final pagination = responseData['pagination'] as Map<String, dynamic>? ??
            responseData['meta'] as Map<String, dynamic>? ??
            {};

        print('✅ ${notifications.length} notification(s) récupérée(s)');
        print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');

        return DashboardPaginatedResponse<DashboardNotification>(
          items: notifications,
          currentPage: pagination['current_page'] ?? page,
          lastPage: pagination['last_page'] ?? 1,
          total: pagination['total'] ?? notifications.length,
        );
      } else if (response.statusCode == 401) {
        throw Exception('Session expirée. Veuillez vous reconnecter.');
      } else {
        final data = jsonDecode(response.body);
        throw Exception(
            data['message'] ?? 'Erreur lors du chargement des notifications');
      }
    } catch (e) {
      print('❌ Exception: $e');
      print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
      rethrow;
    }
  }

  // ============================================================
  // MARQUER NOTIFICATIONS COMME LUES
  // ============================================================

  /// POST /client/dashboard/notifications/read - Marquer notifications lues
  ///
  /// [notificationIds] - Liste des IDs à marquer (null = marquer toutes)
  static Future<bool> markNotificationsRead({
    List<int>? notificationIds,
  }) async {
    if (!_isAuthenticated) {
      throw Exception('Authentification requise');
    }

    print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    print('📤 MARK DASHBOARD NOTIFICATIONS READ');
    print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');

    try {
      final body = <String, dynamic>{};
      if (notificationIds != null) {
        body['notification_ids'] = notificationIds;
      } else {
        body['all'] = true;
      }

      final response = await http.post(
        Uri.parse(Endpoints.dashboardNotificationsRead),
        headers: _headers,
        body: jsonEncode(body),
      );

      print('📥 Response Status: ${response.statusCode}');

      if (response.statusCode == 200) {
        print('✅ Notifications marquées comme lues');
        print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
        return true;
      } else if (response.statusCode == 401) {
        throw Exception('Session expirée. Veuillez vous reconnecter.');
      } else {
        print('❌ Erreur: ${response.statusCode}');
        print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
        return false;
      }
    } catch (e) {
      print('❌ Exception: $e');
      print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
      rethrow;
    }
  }
}
