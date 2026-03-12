import 'package:http/http.dart' as http;
import 'dart:convert';
import './utils/api_endpoint.dart';
import './models/order_model.dart';
import './auth_service.dart';

/// Service de gestion des commandes
/// LOGIQUE EXACTE DE L'API TIKA
///
/// POST /client/orders : Créer une commande (SANS payment_method)
/// POST /client/orders/track : Suivre une commande
/// GET /client/orders/number/{orderNumber} : Détails par numéro
/// POST /client/orders/by-device : Commandes par appareil
/// POST /client/orders/{id}/cancel : Annuler une commande
class OrderService {
  static const Map<String, String> _headers = {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
  };

  /// Headers incluant le token auth si l'utilisateur est connecté
  static Map<String, String> get _authHeaders => {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        if (AuthService.authToken != null)
          'Authorization': 'Bearer ${AuthService.authToken}',
      };

  /// Créer une commande
  /// POST /orders-simple (ou /client/orders)
  ///
  /// LOGIQUE EXACTE DE L'API (docs-api-flutter/08-API-ORDERS.md)
  ///
  /// Body requis:
  /// - shop_id
  /// - customer_name
  /// - customer_phone
  /// - device_fingerprint
  /// - service_type: "Livraison à domicile", "À emporter", "Sur place"
  /// - items: [{product_id, quantity, price, portion_id?}]
  /// - payment_method: "especes", "mobile_money", "carte" (défaut: "especes")
  ///
  /// Optionnels:
  /// - customer_email
  /// - customer_address
  /// - delivery_address
  /// - delivery_zone_id
  /// - delivery_fee
  /// - notes
  /// - coupon_code
  /// - discount_amount
  /// - loyalty_card_id
  /// - loyalty_points_used
  /// - loyalty_discount
  static Future<Map<String, dynamic>> createOrder({
    required int shopId,
    required String customerName,
    required String customerPhone,
    required String serviceType,
    required String deviceFingerprint,
    required List<Map<String, dynamic>> items,
    String paymentMethod = 'especes', // ✅ AJOUTÉ SELON DOC
    String? customerEmail,
    String? customerAddress,
    String? deliveryAddress,
    int? deliveryZoneId,
    double? deliveryFee,
    String? notes,
    String? couponCode,
    double? discountAmount,
    int? loyaltyCardId,
    int? loyaltyPointsUsed,
    double? loyaltyDiscount,
    String? pickupDate,
    String? pickupTime,
  }) async {
    // Construire le body selon la spec API EXACTE (docs-api-flutter)
    final body = {
      'shop_id': shopId,
      'customer_name': customerName,
      'customer_phone': customerPhone,
      'service_type': serviceType,
      'device_fingerprint': deviceFingerprint,
      'payment_method': paymentMethod, // ✅ AJOUTÉ
      'items': items,
      if (customerEmail != null && customerEmail.isNotEmpty)
        'customer_email': customerEmail,
      if (customerAddress != null && customerAddress.isNotEmpty)
        'customer_address': customerAddress,
      if (deliveryAddress != null && deliveryAddress.isNotEmpty)
        'delivery_address': deliveryAddress,
      if (deliveryZoneId != null) 'delivery_zone_id': deliveryZoneId,
      if (deliveryFee != null) 'delivery_fee': deliveryFee, // ✅ AJOUTÉ
      if (notes != null && notes.isNotEmpty) 'notes': notes,
      if (couponCode != null && couponCode.isNotEmpty) 'coupon_code': couponCode,
      if (discountAmount != null) 'discount_amount': discountAmount, // ✅ AJOUTÉ
      if (loyaltyCardId != null) 'loyalty_card_id': loyaltyCardId,
      if (loyaltyPointsUsed != null && loyaltyPointsUsed > 0)
        'loyalty_points_used': loyaltyPointsUsed,
      if (loyaltyDiscount != null) 'loyalty_discount': loyaltyDiscount,
      if (pickupDate != null && pickupDate.isNotEmpty) 'pickup_date': pickupDate,
      if (pickupTime != null && pickupTime.isNotEmpty) 'pickup_time': pickupTime,
    };

    print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    print('📤 POST CREATE ORDER');
    print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    print('🔗 Endpoint: ${Endpoints.orders}');
    print('📦 Body:');
    print('   - shop_id: $shopId');
    print('   - customer_name: $customerName');
    print('   - customer_phone: $customerPhone');
    print('   - service_type: $serviceType');
    print('   - device_fingerprint: $deviceFingerprint');
    print('   - payment_method: $paymentMethod');
    print('   - items: ${items.length} produits');
    if (deliveryAddress != null) {
      print('   - delivery_address: $deliveryAddress');
    }
    if (deliveryZoneId != null) {
      print('   - delivery_zone_id: $deliveryZoneId');
    }
    print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');

    try {
      // Charger le token depuis le stockage si absent en mémoire
      await AuthService.ensureToken();

      final response = await http.post(
        Uri.parse(Endpoints.orders),
        headers: _authHeaders, // ✅ Token inclus si utilisateur connecté
        body: jsonEncode(body),
      );

      print('📥 Response Status: ${response.statusCode}');
      print('📥 Response Body: ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body);

        if (data['success'] != true) {
          throw Exception(data['message'] ?? 'Erreur lors de la création de la commande');
        }

        // Structure API: {success, message, data: {order: {...}}}
        final orderData = data['data']?['order'];

        if (orderData == null) {
          print('⚠️ Structure de réponse inattendue');
          throw Exception('Structure de réponse invalide');
        }

        print('✅ Commande créée avec succès');
        print('   - Order ID: ${orderData['id']}');
        print('   - Order Number: ${orderData['order_number']}');
        print('   - Total: ${orderData['total_amount']}');
        print('   - Status: ${orderData['status']}');
        print('   - Payment Status: ${orderData['payment_status']}');

        print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');

        // Chercher wave_redirect et wave_url à tous les niveaux possibles
        final waveRedirect = data['wave_redirect']
            ?? data['data']?['wave_redirect']
            ?? orderData['wave_redirect']
            ?? false;
        final waveUrl = data['wave_url']
            ?? data['data']?['wave_url']
            ?? orderData['wave_url']
            ?? orderData['payment_url'];

        if (waveRedirect == true || waveUrl != null) {
          print('🌊 Wave redirect: $waveRedirect');
          print('🌊 Wave URL: $waveUrl');
        }

        // Construire l'URL du recu avec l'ID de commande
        final orderId = orderData['id'];
        final receiptUrl = orderId != null
            ? Endpoints.orderReceipt(orderId as int)
            : null;

        // Retourner les données essentielles
        return {
          'success': true,
          'message': data['message'] ?? 'Commande créée avec succès',
          'order_id': orderId,
          'order_number': orderData['order_number'],
          'total_amount': orderData['total_amount'],
          'status': orderData['status'],
          'payment_status': orderData['payment_status'],
          'receipt_url': receiptUrl,
          // GESTION WAVE REDIRECT
          'wave_redirect': waveRedirect,
          'wave_url': waveUrl,
          // Retourner les items pour rafraîchir le stock localement
          'items': items,
        };
      } else {
        final data = jsonDecode(response.body);
        print('❌ Erreur API: ${data['message']}');
        print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
        throw Exception(data['message'] ?? 'Erreur lors de la création de la commande');
      }
    } catch (e) {
      print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
      print('❌ Exception: $e');
      print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
      rethrow;
    }
  }

  /// Suivre une commande
  /// POST /client/orders/track
  ///
  /// Body: {order_number, customer_phone}
  static Future<Order> trackOrder({
    required String orderNumber,
    required String customerPhone,
  }) async {
    final body = {
      'order_number': orderNumber,
      'phone': customerPhone,
    };

    print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    print('📤 POST TRACK ORDER');
    print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    print('🔗 Endpoint: ${Endpoints.orderTrack}');
    print('📦 Order Number: $orderNumber');
    print('📦 Phone: $customerPhone');
    print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');

    try {
      final response = await http.post(
        Uri.parse(Endpoints.orderTrack),
        headers: _headers,
        body: jsonEncode(body),
      );

      print('📥 Response Status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        if (data['success'] != true) {
          throw Exception(data['message'] ?? 'Commande introuvable');
        }

        final orderData = data['data']?['order'] as Map<String, dynamic>?;
        if (orderData == null) {
          throw Exception('Commande introuvable');
        }

        // Injecter la timeline dans l'objet order pour qu'elle soit parsée par Order.fromJson
        final timeline = data['data']?['timeline'];
        if (timeline != null) orderData['timeline'] = timeline;

        print('✅ Commande trouvée');
        print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');

        return Order.fromJson(orderData);
      } else {
        final data = jsonDecode(response.body);
        throw Exception(data['message'] ?? 'Commande introuvable');
      }
    } catch (e) {
      print('❌ Erreur: $e');
      print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
      rethrow;
    }
  }

  /// Récupérer une commande par numéro
  /// GET /client/orders/number/{orderNumber}
  static Future<Order> getOrderByNumber(String orderNumber) async {
    print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    print('📤 GET ORDER BY NUMBER');
    print('🔗 Endpoint: ${Endpoints.orderByNumber(orderNumber)}');
    print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');

    try {
      final response = await http.get(
        Uri.parse(Endpoints.orderByNumber(orderNumber)),
        headers: _headers,
      );

      print('📥 Response Status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        if (data['success'] != true) {
          throw Exception(data['message'] ?? 'Commande introuvable');
        }

        print('✅ Commande trouvée');
        print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');

        return Order.fromJson(data['data']['order']);
      } else {
        final data = jsonDecode(response.body);
        throw Exception(data['message'] ?? 'Commande introuvable');
      }
    } catch (e) {
      print('❌ Erreur: $e');
      print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
      rethrow;
    }
  }

  /// Récupérer les commandes de l'utilisateur authentifié
  /// GET /client/orders
  static Future<Map<String, dynamic>> getOrders({
    String status = 'all',
    String sort = 'newest',
    int perPage = 20,
    int page = 1,
  }) async {
    final headers = Map<String, String>.from(_headers);
    if (AuthService.authToken != null) {
      headers['Authorization'] = 'Bearer ${AuthService.authToken}';
    }

    final uri = Uri.parse(Endpoints.orders).replace(queryParameters: {
      'status': status,
      'sort': sort,
      'per_page': perPage.toString(),
      'page': page.toString(),
    });

    print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    print('📤 GET ORDERS (authentifié)');
    print('🔗 Endpoint: $uri');
    print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');

    try {
      final response = await http.get(uri, headers: headers);

      print('📥 Response Status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        if (data['success'] != true) {
          throw Exception(data['message'] ?? 'Erreur lors du chargement des commandes');
        }

        final ordersData = data['data']?['orders'] as List? ?? [];
        final orders = ordersData.map((e) => Order.fromJson(e as Map<String, dynamic>)).toList();

        print('✅ ${orders.length} commandes chargées');
        print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');

        return {
          'orders': orders,
          'pagination': data['data']?['pagination'] ?? {
            'current_page': page,
            'last_page': page,
            'per_page': perPage,
            'total': orders.length,
          },
        };
      } else {
        final data = jsonDecode(response.body);
        throw Exception(data['message'] ?? 'Erreur lors du chargement des commandes');
      }
    } catch (e) {
      print('❌ Erreur: $e');
      print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
      rethrow;
    }
  }

  /// Récupérer les commandes par appareil
  /// POST /client/orders/by-device
  ///
  /// Body: {device_fingerprint, status?, shop_id?}
  static Future<Map<String, dynamic>> getOrdersByDevice({
    required String deviceFingerprint,
    String? status,
    int? shopId,
    int page = 1,
  }) async {
    final body = {
      'device_fingerprint': deviceFingerprint,
      if (status != null && status.isNotEmpty) 'status': status,
      if (shopId != null) 'shop_id': shopId,
    };

    final uri = Uri.parse(Endpoints.ordersByDevice).replace(
      queryParameters: {'page': page.toString()},
    );

    print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    print('📤 POST ORDERS BY DEVICE');
    print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    print('🔗 Endpoint: $uri');
    print('📦 Device Fingerprint: $deviceFingerprint');
    if (status != null) print('📦 Status Filter: $status');
    if (shopId != null) print('📦 Shop ID: $shopId');
    print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');

    try {
      final response = await http.post(
        uri,
        headers: _headers,
        body: jsonEncode(body),
      );

      print('📥 Response Status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        if (data['success'] != true) {
          throw Exception(data['message'] ?? 'Erreur lors du chargement des commandes');
        }

        final ordersData = data['data']?['orders'] as List? ?? [];
        final orders = ordersData.map((e) => Order.fromJson(e)).toList();

        print('✅ ${orders.length} commandes chargées');
        print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');

        return {
          'orders': orders,
          'pagination': data['data']?['pagination'],
        };
      } else {
        final data = jsonDecode(response.body);
        throw Exception(data['message'] ?? 'Erreur lors du chargement des commandes');
      }
    } catch (e) {
      print('❌ Erreur: $e');
      print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
      rethrow;
    }
  }

  /// Annuler une commande (nécessite authentification)
  /// POST /client/orders/{id}/cancel
  ///
  /// Restaurants/Petit-restau: annulable si statut = recue
  /// Autres boutiques: annulable si statut = recue ou en_traitement ET < 20 min
  /// Body: {reason?: string (max 500)}
  static Future<Map<String, dynamic>> cancelOrder(
    int orderId,
    String token, {
    String? reason,
  }) async {
    final headers = Map<String, String>.from(_headers);
    headers['Authorization'] = 'Bearer $token';

    final body = {
      if (reason != null && reason.isNotEmpty) 'reason': reason,
    };

    print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    print('📤 POST CANCEL ORDER');
    print('🔗 Endpoint: ${Endpoints.orderCancel(orderId)}');
    if (reason != null) print('📦 Reason: $reason');
    print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');

    try {
      final response = await http.post(
        Uri.parse(Endpoints.orderCancel(orderId)),
        headers: headers,
        body: jsonEncode(body),
      );

      print('📥 Response Status: ${response.statusCode}');
      print('📥 Response Body: ${response.body}');

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        print('✅ Commande annulée');
        print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');

        return {
          'success': true,
          'message': data['message'] ?? 'Commande annulée',
        };
      } else if (response.statusCode == 422) {
        // Erreur métier: en préparation, délai dépassé, etc.
        print('⚠️ Annulation refusée: ${data['message']}');
        print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
        return {
          'success': false,
          'message': data['message'] ?? 'Annulation impossible',
        };
      } else {
        throw Exception(data['message'] ?? 'Erreur lors de l\'annulation');
      }
    } catch (e) {
      print('❌ Erreur: $e');
      print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
      rethrow;
    }
  }


  /// Détails d'une commande (nécessite authentification)
  /// GET /client/orders/{id}
  static Future<Order> getOrderDetails(int orderId, String token) async {
    final headers = Map<String, String>.from(_headers);
    headers['Authorization'] = 'Bearer $token';

    print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    print('📤 GET ORDER DETAILS');
    print('🔗 Endpoint: ${Endpoints.orderDetails(orderId)}');
    print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');

    try {
      final response = await http.get(
        Uri.parse(Endpoints.orderDetails(orderId)),
        headers: headers,
      );

      print('📥 Response Status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        if (data['success'] != true) {
          throw Exception(data['message'] ?? 'Commande introuvable');
        }

        print('✅ Détails de la commande chargés');
        print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');

        return Order.fromJson(data['data']['order']);
      } else {
        final data = jsonDecode(response.body);
        throw Exception(data['message'] ?? 'Commande introuvable');
      }
    } catch (e) {
      print('❌ Erreur: $e');
      print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
      rethrow;
    }
  }

  /// Commandes en cours (nécessite authentification)
  /// GET /client/orders/pending
  static Future<List<Order>> getPendingOrders(String token) async {
    final headers = Map<String, String>.from(_headers);
    headers['Authorization'] = 'Bearer $token';

    print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    print('📤 GET PENDING ORDERS');
    print('🔗 Endpoint: ${Endpoints.ordersPending}');
    print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');

    try {
      final response = await http.get(
        Uri.parse(Endpoints.ordersPending),
        headers: headers,
      );

      print('📥 Response Status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final ordersData = data['data']?['orders'] as List? ?? [];
        final orders = ordersData.map((e) => Order.fromJson(e)).toList();

        print('✅ ${orders.length} commandes en cours');
        print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
        return orders;
      } else {
        final data = jsonDecode(response.body);
        throw Exception(data['message'] ?? 'Erreur lors du chargement');
      }
    } catch (e) {
      print('❌ Erreur: $e');
      print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
      rethrow;
    }
  }

  /// Suivre une commande par ID (nécessite authentification)
  /// GET /client/orders/{id}/track
  static Future<Order> trackOrderById(int orderId, String token) async {
    final headers = Map<String, String>.from(_headers);
    headers['Authorization'] = 'Bearer $token';

    print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    print('📤 GET TRACK ORDER BY ID');
    print('🔗 Endpoint: ${Endpoints.orderTrackById(orderId)}');
    print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');

    try {
      final response = await http.get(
        Uri.parse(Endpoints.orderTrackById(orderId)),
        headers: headers,
      );

      print('📥 Response Status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        if (data['success'] != true) {
          throw Exception(data['message'] ?? 'Commande introuvable');
        }

        final orderData = data['data']?['order'];
        if (orderData == null) {
          throw Exception('Commande introuvable');
        }

        print('✅ Suivi de commande chargé');
        print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
        return Order.fromJson(orderData);
      } else {
        final data = jsonDecode(response.body);
        throw Exception(data['message'] ?? 'Commande introuvable');
      }
    } catch (e) {
      print('❌ Erreur: $e');
      print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
      rethrow;
    }
  }

  /// Vérifier la disponibilité pour recommander (nécessite authentification)
  /// POST /client/orders/{id}/reorder
  ///
  /// Vérifie la disponibilité des produits avant de confirmer
  static Future<Map<String, dynamic>> reorder(int orderId, String token) async {
    final headers = Map<String, String>.from(_headers);
    headers['Authorization'] = 'Bearer $token';

    print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    print('📤 POST REORDER (vérification)');
    print('🔗 Endpoint: ${Endpoints.orderReorder(orderId)}');
    print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');

    try {
      final response = await http.post(
        Uri.parse(Endpoints.orderReorder(orderId)),
        headers: headers,
      );

      print('📥 Response Status: ${response.statusCode}');
      print('📥 Response Body: ${response.body}');

      final data = jsonDecode(response.body);

      if (response.statusCode == 200 || response.statusCode == 201) {
        print('✅ Disponibilité vérifiée');
        print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');

        return {
          'success': data['success'] ?? true,
          'message': data['message'] ?? 'Produits disponibles',
          'data': data['data'],
        };
      } else {
        throw Exception(data['message'] ?? 'Erreur lors de la vérification');
      }
    } catch (e) {
      print('❌ Erreur: $e');
      print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
      rethrow;
    }
  }

  /// Confirmer la recommande (nécessite authentification)
  /// POST /client/orders/{id}/confirm-reorder
  ///
  /// Body optionnel: {items?, service_type?, delivery_address?, delivery_zone_id?, notes?}
  static Future<Map<String, dynamic>> confirmReorder({
    required int orderId,
    required String token,
    List<Map<String, dynamic>>? items,
    String? serviceType,
    String? deliveryAddress,
    int? deliveryZoneId,
    String? notes,
    String? deviceFingerprint,
  }) async {
    final headers = Map<String, String>.from(_headers);
    headers['Authorization'] = 'Bearer $token';

    final body = {
      if (items != null && items.isNotEmpty) 'items': items,
      if (serviceType != null && serviceType.isNotEmpty) 'service_type': serviceType,
      if (deliveryAddress != null && deliveryAddress.isNotEmpty) 'delivery_address': deliveryAddress,
      if (deliveryZoneId != null) 'delivery_zone_id': deliveryZoneId,
      if (notes != null && notes.isNotEmpty) 'notes': notes,
      if (deviceFingerprint != null && deviceFingerprint.isNotEmpty) 'device_fingerprint': deviceFingerprint,
    };

    print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    print('📤 POST CONFIRM REORDER');
    print('🔗 Endpoint: ${Endpoints.orderConfirmReorder(orderId)}');
    print('📦 Body: ${jsonEncode(body)}');
    print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');

    try {
      final response = await http.post(
        Uri.parse(Endpoints.orderConfirmReorder(orderId)),
        headers: headers,
        body: jsonEncode(body),
      );

      print('📥 Response Status: ${response.statusCode}');
      print('📥 Response Body: ${response.body}');

      final data = jsonDecode(response.body);

      if (response.statusCode == 200 || response.statusCode == 201) {
        print('✅ Commande recréée');
        print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');

        return {
          'success': true,
          'message': data['message'] ?? 'Commande créée avec succès !',
          'order': data['data']?['order'],
        };
      } else {
        throw Exception(data['message'] ?? 'Erreur lors de la recommande');
      }
    } catch (e) {
      print('❌ Erreur: $e');
      print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
      rethrow;
    }
  }

  /// Noter une commande (nécessite authentification)
  /// POST /client/orders/{id}/rate
  /// Statut requis: livree ou prete
  ///
  /// Body: {rating: 1-5, comment?, delivery_rating?: 1-5, food_rating?: 1-5}
  static Future<Map<String, dynamic>> rateOrder({
    required int orderId,
    required String token,
    required int rating,
    String? comment,
    int? deliveryRating,
    int? foodRating,
  }) async {
    final headers = Map<String, String>.from(_headers);
    headers['Authorization'] = 'Bearer $token';

    final body = {
      'rating': rating,
      if (comment != null && comment.isNotEmpty) 'comment': comment,
      if (deliveryRating != null) 'delivery_rating': deliveryRating,
      if (foodRating != null) 'food_rating': foodRating,
    };

    print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    print('📤 POST RATE ORDER');
    print('🔗 Endpoint: ${Endpoints.orderRate(orderId)}');
    print('⭐ Rating: $rating');
    print('📦 Body: ${jsonEncode(body)}');
    print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');

    try {
      final response = await http.post(
        Uri.parse(Endpoints.orderRate(orderId)),
        headers: headers,
        body: jsonEncode(body),
      );

      print('📥 RATE Response Status: ${response.statusCode}');
      print('📥 RATE Response Body: ${response.body}');

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        print('✅ Commande notée');
        print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');

        return {
          'success': true,
          'message': data['message'] ?? 'Merci pour votre avis',
        };
      } else if (response.statusCode == 422) {
        final msg = data['message'] ?? '';
        // Commande déjà notée — pas une vraie erreur
        if (msg.toString().toLowerCase().contains('deja') ||
            msg.toString().toLowerCase().contains('déjà')) {
          print('⚠️ Commande déjà notée');
          print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
          return {
            'success': false,
            'already_rated': true,
            'message': 'Cette commande a déjà été notée.',
          };
        }
        throw Exception(msg.isNotEmpty ? msg : 'Erreur lors de la notation');
      } else {
        throw Exception(data['message'] ?? 'Erreur lors de la notation');
      }
    } catch (e) {
      print('❌ Erreur: $e');
      print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
      rethrow;
    }
  }

  /// Statistiques des commandes (nécessite authentification)
  /// GET /client/orders/stats
  static Future<Map<String, dynamic>> getOrderStats(String token) async {
    final headers = Map<String, String>.from(_headers);
    headers['Authorization'] = 'Bearer $token';

    print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    print('📤 GET ORDER STATS');
    print('🔗 Endpoint: ${Endpoints.ordersStats}');
    print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');

    try {
      final response = await http.get(
        Uri.parse(Endpoints.ordersStats),
        headers: headers,
      );

      print('📥 Response Status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        print('✅ Stats chargées');
        print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');

        return data['data'] ?? {};
      } else {
        final data = jsonDecode(response.body);
        throw Exception(data['message'] ?? 'Erreur lors du chargement des stats');
      }
    } catch (e) {
      print('❌ Erreur: $e');
      print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
      rethrow;
    }
  }
}
