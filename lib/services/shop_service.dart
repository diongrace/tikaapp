import 'package:http/http.dart' as http;
import 'dart:convert';
import './utils/api_endpoint.dart';
import './models/shop_model.dart';
import './models/product_model.dart';
import './auth_service.dart';

class ShopService {
  static const Map<String, String> _headers = {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
  };

  /// Headers avec token d'authentification (pour les endpoints qui le requierent)
  static Map<String, String> get _authHeaders => {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        if (AuthService.authToken != null)
          'Authorization': 'Bearer ${AuthService.authToken}',
      };

  // 1. Récupérer une boutique par ID — GET /shops/{id}
  static Future<Shop> getShopById(int id) async {
    final response = await http.get(
      Uri.parse(Endpoints.shopDetails(id)),
      headers: _headers,
    );

    print('🌐 [getShopById] URL: ${Endpoints.shopDetails(id)}');
    print('📊 [getShopById] Status Code: ${response.statusCode}');
    print('📄 [getShopById] RESPONSE BODY COMPLET: ${response.body}');

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final responseData = data['data'] as Map<String, dynamic>? ?? data;
      final shopData = Map<String, dynamic>.from(responseData['shop'] ?? responseData);

      // Chercher le banner a tous les niveaux de la reponse (shop, data, racine)
      // L'API peut le retourner en dehors de l'objet shop
      if (shopData['banner_url'] == null && shopData['banner'] == null &&
          shopData['cover_image'] == null && shopData['image_banner'] == null) {
        // Chercher dans data (niveau parent)
        final bannerFromData = responseData['banner_url']
            ?? responseData['cover_image']
            ?? responseData['banner']
            ?? responseData['image_banner'];
        if (bannerFromData != null) {
          shopData['banner_url'] = bannerFromData;
          print('🖼️ [getShopById] Banner trouvé dans data: $bannerFromData');
        }

        // Chercher dans images/media si present
        final images = shopData['images'] ?? responseData['images'];
        if (images is Map) {
          final bannerFromImages = images['banner'] ?? images['cover'] ?? images['banner_url'];
          if (bannerFromImages != null) {
            shopData['banner_url'] = bannerFromImages;
            print('🖼️ [getShopById] Banner trouvé dans images: $bannerFromImages');
          }
        } else if (images is List && images.isNotEmpty) {
          // Premiere image comme banner
          final firstImage = images.first;
          if (firstImage is String) {
            shopData['banner_url'] = firstImage;
          } else if (firstImage is Map) {
            shopData['banner_url'] = firstImage['url'] ?? firstImage['path'];
          }
          print('🖼️ [getShopById] Banner trouvé dans images[]: ${shopData['banner_url']}');
        }

        final media = shopData['media'] ?? responseData['media'];
        if (media is List) {
          for (final item in media) {
            if (item is Map) {
              final collection = item['collection_name']?.toString().toLowerCase() ?? '';
              if (collection.contains('banner') || collection.contains('cover')) {
                shopData['banner_url'] = item['original_url'] ?? item['url'] ?? item['path'];
                print('🖼️ [getShopById] Banner trouvé dans media: ${shopData['banner_url']}');
                break;
              }
            }
          }
        }
      }

      // Chercher wave_payment_link dans responseData (peut etre en dehors de l'objet shop)
      if (shopData['wave_payment_link'] == null) {
        final waveLink = responseData['wave_payment_link']
            ?? responseData['wave_link']
            ?? responseData['wave_url']
            ?? responseData['wave_number'];
        if (waveLink != null && waveLink.toString().isNotEmpty) {
          shopData['wave_payment_link'] = waveLink;
          print('🌊 [getShopById] wave_payment_link trouvé dans data: $waveLink');
        }

        // Chercher dans payment_settings ou settings au niveau responseData
        final paymentSettings = responseData['payment_settings'] ?? responseData['settings'];
        if (paymentSettings is Map) {
          final waveFromSettings = paymentSettings['wave_payment_link']
              ?? paymentSettings['wave_link']
              ?? paymentSettings['wave_url'];
          if (waveFromSettings != null && waveFromSettings.toString().isNotEmpty) {
            shopData['wave_payment_link'] = waveFromSettings;
            print('🌊 [getShopById] wave_payment_link trouvé dans settings: $waveFromSettings');
          }
        }

        // Chercher dans payment_methods au niveau responseData
        final paymentMethods = responseData['payment_methods'];
        if (paymentMethods is Map) {
          final waveFromPM = paymentMethods['wave_payment_link']
              ?? paymentMethods['wave_link'];
          if (waveFromPM != null && waveFromPM.toString().isNotEmpty) {
            shopData['wave_payment_link'] = waveFromPM;
            print('🌊 [getShopById] wave_payment_link trouvé dans payment_methods: $waveFromPM');
          }
        }
      }

      print('✅ [getShopById] Boutique trouvée: ${shopData['name']}');
      print('🖼️ [getShopById] Banner final: ${shopData['banner_url'] ?? shopData['banner'] ?? shopData['cover_image'] ?? 'AUCUN'}');
      print('🌊 [getShopById] wave_payment_link: ${shopData['wave_payment_link'] ?? 'AUCUN'}');
      print('🔑 [getShopById] Clés shop: ${shopData.keys.toList()}');
      print('🔑 [getShopById] Clés responseData: ${responseData.keys.toList()}');

      final shop = Shop.fromJson(shopData);

      // Si toujours pas de banner, tenter de le recuperer depuis l'endpoint liste
      if (shop.bannerUrl == null || shop.bannerUrl!.isEmpty) {
        print('🖼️ [getShopById] Pas de banner dans detail, tentative via liste...');
        try {
          final listShop = await _getShopBannerFromList(id);
          if (listShop != null) {
            print('🖼️ [getShopById] Banner trouvé via liste: $listShop');
            // Reconstruire le shop avec le banner
            shopData['banner_url'] = listShop;
            return Shop.fromJson(shopData);
          }
        } catch (e) {
          print('🖼️ [getShopById] Erreur fallback liste: $e');
        }
      }

      return shop;
    } else {
      throw Exception('Boutique introuvable');
    }
  }

  /// Tente de recuperer le cover_image depuis l'endpoint liste /shops
  /// L'API liste retourne cover_image (chemin relatif) que le detail ne retourne pas
  static Future<String?> _getShopBannerFromList(int shopId) async {
    try {
      // Charger la liste des shops (l'API liste inclut cover_image)
      final uri = Uri.parse(Endpoints.shops).replace(queryParameters: {
        'page': '1',
        'per_page': '100',
      });
      final response = await http.get(uri, headers: _headers);
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final shops = data['data']['shops'] as List? ?? data['data'] as List? ?? [];
        for (final s in shops) {
          final sId = s['id'];
          if (sId == shopId || sId?.toString() == shopId.toString()) {
            // cover_image est le champ qui contient le banner dans la liste
            final banner = s['cover_image'] ?? s['banner_url'] ?? s['banner'] ?? s['image_banner'];
            print('🖼️ [_getShopBannerFromList] Shop $shopId trouvé, cover_image=$banner');
            if (banner != null && banner.toString().trim().isNotEmpty &&
                banner.toString().toLowerCase() != 'null') {
              return banner.toString();
            }
            break;
          }
        }
      }
    } catch (e) {
      print('🖼️ [_getShopBannerFromList] Erreur: $e');
    }
    return null;
  }

  // 2. Récupérer une boutique par slug — GET /shops/slug/{slug}
  static Future<Shop> getShopBySlug(String slug) async {
    final url = Endpoints.shopBySlug(slug);
    print('🔎 [getShopBySlug] URL: $url');

    final response = await http.get(Uri.parse(url), headers: _headers);

    print('📊 [getShopBySlug] Status Code: ${response.statusCode}');
    print('📄 [getShopBySlug] Body: ${response.body}');

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final shopData = Map<String, dynamic>.from(data['data']['shop']);
      print('✅ [getShopBySlug] Boutique trouvée: ${shopData['name']}');
      return Shop.fromJson(shopData);
    } else {
      print('❌ [getShopBySlug] Échec pour slug: "$slug" (${response.statusCode})');
      throw Exception('Boutique introuvable avec le slug "$slug"');
    }
  }

  // 3. Rechercher une boutique par nom — GET /shops?search=
  static Future<Shop?> searchShopByName(String name) async {
    final uri = Uri.parse(Endpoints.shops).replace(queryParameters: {
      'search': name,
      'page': '1',
    });

    print('🔍 [searchShopByName] URL: $uri');

    final response = await http.get(uri, headers: _headers);

    print('📊 [searchShopByName] Status Code: ${response.statusCode}');

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final shops = data['data']['shops'] as List;
      if (shops.isNotEmpty) {
        print('✅ [searchShopByName] Boutique trouvée: ${shops.first['name']}');
        return Shop.fromJson(Map<String, dynamic>.from(shops.first));
      }
    } else {
      print('❌ [searchShopByName] Échec (${response.statusCode})');
    }
    return null;
  }

  // 4. Récupérer une boutique via un lien, ID ou slug
  // Essaie dans l'ordre: ID → slug → recherche par nom
  static Future<Shop> getShopByLink(String input) async {
    try {
      String identifier;

      // Extraire l'identifiant depuis l'URL ou le texte brut
      if (input.startsWith('http://') || input.startsWith('https://') || input.startsWith('://')) {
        final Uri uri = Uri.parse(input.startsWith('://') ? 'https$input' : input);
        final segments = uri.pathSegments.where((s) => s.isNotEmpty).toList();
        identifier = segments.isNotEmpty ? segments.last : input.trim();
      } else {
        identifier = input.trim();
      }

      print('🔍 [getShopByLink] Identifier: "$identifier"');

      // 1. Essayer comme ID numérique → GET /shops/{id}
      final shopId = int.tryParse(identifier);
      if (shopId != null) {
        print('🔢 [getShopByLink] ID numérique détecté: $shopId');
        return await getShopById(shopId);
      }

      // 2. Essayer comme slug → GET /shops/slug/{slug}
      print('🔎 [getShopByLink] Essai par slug: "$identifier"');
      try {
        return await getShopBySlug(identifier);
      } catch (_) {
        print('⚠️ [getShopByLink] Slug échoué, essai par recherche...');
      }

      // 3. Essayer par recherche → GET /shops?search=
      final shop = await searchShopByName(identifier);
      if (shop != null) return shop;

      throw Exception('Boutique "$identifier" introuvable');
    } catch (e) {
      print('❌ [getShopByLink] Erreur: $e');
      throw Exception(e.toString().replaceAll('Exception: ', ''));
    }
  }

  // 5. Récupérer les produits d'une boutique
  static Future<Map<String, dynamic>> getShopProducts(
    int shopId, {
    int? categoryId,
    String? search,
    bool? inStock,
    String? sortBy,
    int page = 1,
  }) async {
    final queryParams = <String, String>{
      if (categoryId != null) 'category_id': categoryId.toString(),
      if (search != null) 'search': search,
      if (inStock != null) 'in_stock': inStock.toString(),
      if (sortBy != null) 'sort_by': sortBy,
      'page': page.toString(),
    };

    final uri = Uri.parse(Endpoints.shopProducts(shopId))
        .replace(queryParameters: queryParams);
    final response = await http.get(uri, headers: _headers);

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return {
        'products': (data['data']['products'] as List)
            .map((e) => Product.fromJson(e))
            .toList(),
        'pagination': data['data']['pagination'],
        'empty_state': data['data']['empty_state'],
      };
    } else {
      throw Exception('Erreur lors du chargement des produits');
    }
  }

  // 6. Récupérer les catégories d'une boutique
  static Future<List<ProductCategory>> getShopCategories(int shopId) async {
    final response = await http.get(
      Uri.parse(Endpoints.shopCategories(shopId)),
      headers: _headers,
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return (data['data']['categories'] as List)
          .map((e) => ProductCategory.fromJson(e))
          .toList();
    } else {
      throw Exception('Erreur lors du chargement des catégories');
    }
  }

  // 7. Récupérer les boutiques en vedette
  static Future<List<Shop>> getFeaturedShops() async {
    final response = await http.get(
      Uri.parse(Endpoints.shopsFeatured),
      headers: _headers,
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return (data['data']['shops'] as List)
          .map((e) => Shop.fromJson(e))
          .toList();
    } else {
      throw Exception('Erreur lors du chargement des boutiques en vedette (Status: ${response.statusCode})');
    }
  }

  // 8. Récupérer les zones de livraison d'une boutique
  static Future<List<DeliveryZone>> getDeliveryZones(int shopId) async {
    final response = await http.get(
      Uri.parse(Endpoints.deliveryZones(shopId)),
      headers: _headers,
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final zones = data['data']['delivery_zones'] ?? data['data'];
      if (zones is List) {
        return zones.map((e) => DeliveryZone.fromJson(e)).toList();
      }
      return [];
    } else {
      throw Exception('Erreur lors du chargement des zones de livraison');
    }
  }

  // 9. Récupérer les options de livraison d'une boutique
  static Future<DeliveryOptions> getDeliveryOptions(int shopId) async {
    final response = await http.get(
      Uri.parse(Endpoints.deliveryOptions(shopId)),
      headers: _headers,
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return DeliveryOptions.fromJson(data['data']);
    } else {
      throw Exception('Erreur lors du chargement des options de livraison');
    }
  }

  // 10. Récupérer les méthodes de paiement d'une boutique
  static Future<List<PaymentMethod>> getPaymentMethods(int shopId) async {
    final response = await http.get(
      Uri.parse(Endpoints.shopPaymentMethods(shopId)),
      headers: _headers,
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final methods = data['data']['payment_methods'] ?? data['data'];
      if (methods is List) {
        return methods.map((e) => PaymentMethod.fromJson(e)).toList();
      }
      return [];
    } else {
      throw Exception('Erreur lors du chargement des méthodes de paiement');
    }
  }

  // 11. Récupérer les coupons actifs d'une boutique
  static Future<List<Coupon>> getShopCoupons(int shopId) async {
    final response = await http.get(
      Uri.parse(Endpoints.shopCoupons(shopId)),
      headers: _headers,
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final coupons = data['data']['coupons'] ?? data['data'];
      if (coupons is List) {
        return coupons.map((e) => Coupon.fromJson(e)).toList();
      }
      return [];
    } else {
      throw Exception('Erreur lors du chargement des coupons');
    }
  }

  // 12. Récupérer le lien Wave depuis l'API payment-methods
  // Essaie plusieurs endpoints pour trouver le wave_payment_link
  static Future<String?> getWavePaymentLink(int shopId) async {
    print('🌊 ━━━ RECHERCHE WAVE PAYMENT LINK (shop $shopId) ━━━');

    // S'assurer que le token est disponible
    try {
      await AuthService.ensureToken();
    } catch (_) {}

    final bool hasAuth = AuthService.authToken != null;
    print('🌊 Auth token disponible: $hasAuth');

    // Tentative 1: endpoint vendor payment-methods AVEC auth (endpoint documenté)
    if (hasAuth) {
      print('🌊 [1/6] Endpoint vendor payment-methods (auth)...');
      final vendorLink = await _getWavePaymentLinkFromUrl(
        Endpoints.vendorPaymentMethods(shopId),
        useAuth: true,
      );
      if (vendorLink != null) {
        print('🌊 ✅ Lien trouvé via vendor endpoint (auth): $vendorLink');
        return vendorLink;
      }
    }

    // Tentative 2: endpoint client payment-methods AVEC auth
    if (hasAuth) {
      print('🌊 [2/6] Endpoint client payment-methods (auth)...');
      final clientLink = await _getWavePaymentLinkFromUrl(
        Endpoints.shopPaymentMethods(shopId),
        useAuth: true,
      );
      if (clientLink != null) {
        print('🌊 ✅ Lien trouvé via client endpoint (auth): $clientLink');
        return clientLink;
      }
    }

    // Tentative 3: endpoint vendor payment-methods SANS auth
    print('🌊 [3/6] Endpoint vendor payment-methods (sans auth)...');
    final vendorNoAuth = await _getWavePaymentLinkFromUrl(
      Endpoints.vendorPaymentMethods(shopId),
      useAuth: false,
    );
    if (vendorNoAuth != null) {
      print('🌊 ✅ Lien trouvé via vendor endpoint (sans auth): $vendorNoAuth');
      return vendorNoAuth;
    }

    // Tentative 4: endpoint client payment-methods SANS auth
    print('🌊 [4/6] Endpoint client payment-methods (sans auth)...');
    final clientNoAuth = await _getWavePaymentLinkFromUrl(
      Endpoints.shopPaymentMethods(shopId),
      useAuth: false,
    );
    if (clientNoAuth != null) {
      print('🌊 ✅ Lien trouvé via client endpoint (sans auth): $clientNoAuth');
      return clientNoAuth;
    }

    // Tentative 5: recharger les details du shop (wave_payment_link dans le shop)
    print('🌊 [5/6] Rechargement shop details...');
    try {
      final freshShop = await getShopById(shopId);
      if (freshShop.wavePaymentLink != null && freshShop.wavePaymentLink!.isNotEmpty) {
        print('🌊 ✅ Lien trouvé dans shop details: ${freshShop.wavePaymentLink}');
        return freshShop.wavePaymentLink;
      }
    } catch (e) {
      print('🌊 ❌ Erreur rechargement shop: $e');
    }

    // Tentative 6: chercher dans la réponse brute du shop detail
    print('🌊 [6/6] Recherche dans réponse brute shop...');
    try {
      final rawLink = await _getWaveLinkFromShopRawResponse(shopId);
      if (rawLink != null) {
        print('🌊 ✅ Lien trouvé dans réponse brute: $rawLink');
        return rawLink;
      }
    } catch (e) {
      print('🌊 ❌ Erreur recherche brute: $e');
    }

    print('🌊 ❌ Aucun wave_payment_link trouvé après 6 tentatives');
    print('🌊 ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    return null;
  }

  /// Tente d'extraire le wave_payment_link depuis une URL de payment-methods
  static Future<String?> _getWavePaymentLinkFromUrl(String url, {bool useAuth = false}) async {
    try {
      print('🌊 [_getWavePaymentLink] URL: $url (auth: $useAuth)');

      final response = await http.get(
        Uri.parse(url),
        headers: useAuth ? _authHeaders : _headers,
      );

      print('🌊 [_getWavePaymentLink] Status: ${response.statusCode}');

      if (response.statusCode != 200) {
        print('🌊 [_getWavePaymentLink] Échec (${response.statusCode}): ${response.body.length > 200 ? response.body.substring(0, 200) : response.body}');
        return null;
      }

      final data = jsonDecode(response.body);
      print('🌊 [_getWavePaymentLink] Clés racine: ${data is Map ? data.keys.toList() : 'pas un Map'}');

      final paymentData = data['data'] ?? data;
      if (paymentData is Map) {
        print('🌊 [_getWavePaymentLink] Clés data: ${paymentData.keys.toList()}');
      }

      // Cas 1: wave_payment_link directement dans data
      final directLink = paymentData['wave_payment_link']
          ?? paymentData['wave_link']
          ?? paymentData['wave_url'];
      if (directLink != null && directLink.toString().isNotEmpty) {
        print('🌊 [_getWavePaymentLink] Lien direct trouvé: $directLink');
        return directLink.toString();
      }

      // Cas 2: dans l'objet shop du response
      if (paymentData['shop'] is Map) {
        final shopData = paymentData['shop'];
        final shopLink = shopData['wave_payment_link']
            ?? shopData['wave_link']
            ?? shopData['wave_url']
            ?? shopData['wave_number'];
        if (shopLink != null && shopLink.toString().isNotEmpty) {
          print('🌊 [_getWavePaymentLink] Lien trouvé dans shop: $shopLink');
          return shopLink.toString();
        }
      }

      // Cas 3: dans la liste payment_methods
      if (paymentData['payment_methods'] is List) {
        for (var method in paymentData['payment_methods']) {
          if (method is! Map) continue;
          final provider = method['provider']?.toString().toLowerCase() ?? '';
          final name = method['name']?.toString().toLowerCase() ?? '';
          final type = method['type']?.toString().toLowerCase() ?? '';
          if (provider == 'wave' || name == 'wave' || type == 'wave' ||
              provider.contains('wave') || name.contains('wave')) {
            print('🌊 [_getWavePaymentLink] Méthode Wave trouvée: $method');
            final link = method['wave_payment_link']
                ?? method['payment_link']
                ?? method['link']
                ?? method['url']
                ?? method['wave_link']
                ?? method['wave_url']
                ?? method['account_number']
                ?? method['phone']
                ?? method['number'];
            if (link != null && link.toString().isNotEmpty) {
              print('🌊 [_getWavePaymentLink] Lien trouvé dans méthode: $link');
              return link.toString();
            }
          }
        }
      }

      // Cas 4: dans payment_settings ou settings
      final settings = paymentData['payment_settings'] ?? paymentData['settings'];
      if (settings is Map) {
        final settingsLink = settings['wave_payment_link']
            ?? settings['wave_link']
            ?? settings['wave_url'];
        if (settingsLink != null && settingsLink.toString().isNotEmpty) {
          print('🌊 [_getWavePaymentLink] Lien trouvé dans settings: $settingsLink');
          return settingsLink.toString();
        }
      }

      // Cas 5: Parcourir TOUTES les clés pour trouver un champ contenant "wave"
      if (paymentData is Map) {
        for (final key in paymentData.keys) {
          final keyStr = key.toString().toLowerCase();
          if (keyStr.contains('wave') && keyStr.contains('link') ||
              keyStr.contains('wave') && keyStr.contains('url') ||
              keyStr.contains('wave') && keyStr.contains('payment')) {
            final value = paymentData[key];
            if (value != null && value is String && value.isNotEmpty) {
              print('🌊 [_getWavePaymentLink] Lien trouvé via clé "$key": $value');
              return value;
            }
          }
        }
      }

      print('🌊 [_getWavePaymentLink] Aucun lien Wave dans la réponse');
      print('🌊 [_getWavePaymentLink] Body complet: ${response.body.length > 500 ? response.body.substring(0, 500) : response.body}');
      return null;
    } catch (e) {
      print('🌊 [_getWavePaymentLink] Erreur: $e');
      return null;
    }
  }

  /// Recherche le wave_payment_link dans la réponse brute du shop detail
  /// en parcourant récursivement tous les champs
  static Future<String?> _getWaveLinkFromShopRawResponse(int shopId) async {
    try {
      final response = await http.get(
        Uri.parse(Endpoints.shopDetails(shopId)),
        headers: _headers,
      );

      if (response.statusCode != 200) return null;

      final data = jsonDecode(response.body);
      return _findWaveLinkRecursive(data);
    } catch (e) {
      print('🌊 [_getWaveLinkFromShopRawResponse] Erreur: $e');
      return null;
    }
  }

  /// Parcourt récursivement un JSON pour trouver un champ wave_payment_link
  static String? _findWaveLinkRecursive(dynamic data, {int depth = 0}) {
    if (depth > 5) return null; // Limite de profondeur

    if (data is Map) {
      // Chercher directement les clés wave
      for (final key in data.keys) {
        final keyStr = key.toString().toLowerCase();
        if (keyStr == 'wave_payment_link' || keyStr == 'wave_link' || keyStr == 'wave_url') {
          final value = data[key];
          if (value != null && value is String && value.isNotEmpty && value.toLowerCase() != 'null') {
            return value;
          }
        }
      }
      // Parcourir récursivement les valeurs
      for (final value in data.values) {
        final found = _findWaveLinkRecursive(value, depth: depth + 1);
        if (found != null) return found;
      }
    } else if (data is List) {
      for (final item in data) {
        final found = _findWaveLinkRecursive(item, depth: depth + 1);
        if (found != null) return found;
      }
    }

    return null;
  }
}


