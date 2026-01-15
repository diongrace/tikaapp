import 'package:http/http.dart' as http;
import 'dart:convert';
import './utils/api_endpoint.dart';
import './models/order_model.dart';

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
      if (loyaltyDiscount != null) 'loyalty_discount': loyaltyDiscount, // ✅ AJOUTÉ
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
    print('   - items: ${items.length} produits');
    if (deliveryAddress != null) {
      print('   - delivery_address: $deliveryAddress');
    }
    if (deliveryZoneId != null) {
      print('   - delivery_zone_id: $deliveryZoneId');
    }
    print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');

    try {
      final response = await http.post(
        Uri.parse(Endpoints.orders),
        headers: _headers,
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

        // ⚠️ IMPORTANT: L'API backend doit automatiquement décrémenter le stock
        // des produits commandés. Si ce n'est pas le cas, contactez l'équipe backend.
        print('⚠️ RAPPEL: Le backend doit décrémenter le stock automatiquement');
        print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');

        // Retourner les données essentielles
        return {
          'success': true,
          'message': data['message'] ?? 'Commande créée avec succès',
          'order_id': orderData['id'],
          'order_number': orderData['order_number'],
          'total_amount': orderData['total_amount'],
          'status': orderData['status'],
          'payment_status': orderData['payment_status'],
          'receipt_url': orderData['receipt_url'],
          'receipt_view_url': orderData['receipt_view_url'],
          // ✅ GESTION WAVE REDIRECT
          'wave_redirect': data['wave_redirect'] ?? false,
          'wave_url': data['wave_url'],
          // ✅ Retourner les items pour rafraîchir le stock localement
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
      'customer_phone': customerPhone,
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

        final orderData = data['data']?['order'];
        if (orderData == null) {
          throw Exception('Commande introuvable');
        }

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
  static Future<Map<String, dynamic>> cancelOrder(
    int orderId,
    String token,
  ) async {
    final headers = Map<String, String>.from(_headers);
    headers['Authorization'] = 'Bearer $token';

    print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    print('📤 POST CANCEL ORDER');
    print('🔗 Endpoint: ${Endpoints.orderCancel(orderId)}');
    print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');

    try {
      final response = await http.post(
        Uri.parse(Endpoints.orderCancel(orderId)),
        headers: headers,
      );

      print('📥 Response Status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        print('✅ Commande annulée');
        print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');

        return {
          'success': data['success'] ?? true,
          'message': data['message'] ?? 'Commande annulée',
        };
      } else {
        final data = jsonDecode(response.body);
        throw Exception(data['message'] ?? 'Erreur lors de l\'annulation');
      }
    } catch (e) {
      print('❌ Erreur: $e');
      print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
      rethrow;
    }
  }

  /// Lister les commandes (nécessite authentification)
  /// GET /client/orders
  static Future<Map<String, dynamic>> getOrders({
    String? status,
    int page = 1,
    required String token,
  }) async {
    final queryParams = <String, String>{
      if (status != null && status.isNotEmpty) 'status': status,
      'page': page.toString(),
    };

    final headers = Map<String, String>.from(_headers);
    headers['Authorization'] = 'Bearer $token';

    final uri = Uri.parse(Endpoints.orders).replace(queryParameters: queryParams);

    print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    print('📤 GET ORDERS');
    print('🔗 Endpoint: $uri');
    print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');

    try {
      final response = await http.get(uri, headers: headers);

      print('📥 Response Status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        final ordersData = data['data']?['orders'] as List? ?? [];
        final orders = ordersData.map((e) => Order.fromJson(e)).toList();

        print('✅ ${orders.length} commandes chargées');
        print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');

        return {
          'orders': orders,
          'pagination': data['data']?['pagination'],
        };
      } else {
        throw Exception('Erreur lors du chargement des commandes');
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
}
