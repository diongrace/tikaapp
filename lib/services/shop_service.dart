import 'package:http/http.dart' as http;
import 'dart:convert';
import './utils/api_endpoint.dart';
import './models/shop_model.dart';
import './models/product_model.dart';

class ShopService {
  static const Map<String, String> _headers = {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
  };

  // 1. Lister toutes les boutiques avec filtres
  static Future<Map<String, dynamic>> getShops({
    String? category,
    String? search,
    double? latitude,
    double? longitude,
    double? radius,
    int page = 1,
  }) async {
    final queryParams = <String, String>{
      if (category != null) 'category': category,
      if (search != null) 'search': search,
      if (latitude != null) 'latitude': latitude.toString(),
      if (longitude != null) 'longitude': longitude.toString(),
      if (radius != null) 'radius': radius.toString(),
      'page': page.toString(),
    };

    final uri = Uri.parse(Endpoints.shops).replace(queryParameters: queryParams);

    print('🌐 [getShops] URL: $uri');

    final response = await http.get(uri, headers: _headers);

    print('📊 [getShops] Status Code: ${response.statusCode}');

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return {
        'shops': (data['data']['shops'] as List)
            .map((e) => Shop.fromJson(e))
            .toList(),
        'pagination': data['data']['pagination'],
      };
    } else {
      print('❌ [getShops] Erreur API - Status: ${response.statusCode}');
      print('❌ [getShops] Response body: ${response.body}');
      throw Exception('Erreur lors du chargement des boutiques (Status: ${response.statusCode})');
    }
  }

  // 2. Récupérer une boutique par ID
  // Note: L'API de détail (/client/shops/{id}) ne retourne pas toujours cover_image
  // On récupère aussi les données de l'API de liste pour avoir le cover_image
  static Future<Shop> getShopById(int id) async {
    final response = await http.get(
      Uri.parse(Endpoints.shopDetails(id)),
      headers: _headers,
    );

    print('🌐 Requête API: ${Endpoints.shopDetails(id)}');
    print('📊 Status Code: ${response.statusCode}');

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final shopData = Map<String, dynamic>.from(data['data']['shop']);

      // Debug: Afficher TOUTES les clés de la réponse API
      print('');
      print('══════════════════════════════════════════════════════');
      print('📡 API RESPONSE COMPLÈTE pour boutique $id:');
      print('══════════════════════════════════════════════════════');
      print('🔑 Toutes les clés disponibles: ${shopData.keys.toList()}');
      print('');

      // Afficher les valeurs brutes de l'API
      print('   - Nom: ${shopData['name']}');
      print('   - banner_url (brut): ${shopData['banner_url']}');
      print('   - cover_image (brut): ${shopData['cover_image']}');
      print('   - banner_url est null: ${shopData['banner_url'] == null}');
      print('   - logo_url (brut): ${shopData['logo_url']}');
      print('══════════════════════════════════════════════════════');

      // Si cover_image et banner_url sont null, essayer de récupérer depuis l'API de liste
      if (shopData['cover_image'] == null && shopData['banner_url'] == null) {
        print('⚠️ cover_image non disponible dans l\'API de détail, récupération depuis l\'API de liste...');
        try {
          final coverImage = await _getCoverImageFromList(id);
          if (coverImage != null) {
            shopData['cover_image'] = coverImage;
            print('✅ cover_image récupéré depuis l\'API de liste: $coverImage');
          }
        } catch (e) {
          print('❌ Erreur lors de la récupération du cover_image: $e');
        }
      }

      // Debug: Afficher le thème de la boutique
      print('🎨 THEME DEBUG pour boutique $id:');
      print('   - theme (brut): ${shopData['theme']}');
      if (shopData['theme'] != null) {
        print('   - primary_color: ${shopData['theme']['primary_color']}');
      } else {
        print('   ⚠️ ATTENTION: Le thème est NULL');
      }

      return Shop.fromJson(shopData);
    } else {
      throw Exception('Boutique introuvable');
    }
  }

  // Récupérer le cover_image depuis l'API de liste
  static Future<String?> _getCoverImageFromList(int shopId) async {
    final response = await http.get(
      Uri.parse(Endpoints.shops),
      headers: _headers,
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final shops = data['data']['shops'] as List;

      for (var shop in shops) {
        if (shop['id'] == shopId) {
          return shop['cover_image']?.toString();
        }
      }
    }
    return null;
  }

  // 3. Récupérer une boutique via un lien, ID ou slug
  // Format acceptés:
  // - ID: "123"
  // - URL avec ID: "https://prepro.tika-ci.com/123"
  // - URL avec slug: "https://prepro.tika-ci.com/ma-boutique-abc123"
  // - Slug seul: "ma-boutique-abc123"
  static Future<Shop> getShopByLink(String input) async {
    try {
      String identifier;

      // Si c'est une URL complète, extraire le dernier segment
      if (input.startsWith('http://') || input.startsWith('https://') || input.startsWith('://')) {
        final Uri uri = Uri.parse(input.startsWith('://') ? 'https$input' : input);
        identifier = uri.pathSegments.isNotEmpty ? uri.pathSegments.last : input;
      } else {
        identifier = input.trim();
      }

      print('🔍 [getShopByLink] Identifier extrait: "$identifier"');

      // Essayer de parser comme un ID numérique
      final shopId = int.tryParse(identifier);

      if (shopId != null) {
        // C'est un ID valide, récupérer directement par ID
        print('✅ [getShopByLink] ID numérique détecté: $shopId');
        return await getShopById(shopId);
      }

      // C'est un slug, récupérer toutes les boutiques et chercher par slug
      print('🔎 [getShopByLink] Slug détecté: "$identifier"');
      print('📡 [getShopByLink] Récupération des boutiques depuis l\'API...');

      try {
        // Récupérer toutes les boutiques
        final result = await getShops();
        final shops = result['shops'] as List<Shop>;

        print('📦 [getShopByLink] ${shops.length} boutiques récupérées');

        // Chercher par slug exact (l'API retourne un champ slug)
        Shop? matchedShop;

        for (var shop in shops) {
          print('   - Boutique: ${shop.name} (slug: ${shop.slug})');

          // Comparaison par slug si disponible
          if (shop.slug != null) {
            final shopSlug = shop.slug!.toLowerCase();
            final searchSlug = identifier.toLowerCase();

            print('     Comparaison slug: "$shopSlug" vs "$searchSlug"');

            // Comparaison exacte
            if (shopSlug == searchSlug) {
              matchedShop = shop;
              print('     ✅ MATCH EXACT TROUVÉ !');
              break;
            }

            // Comparaison partielle
            if (shopSlug.contains(searchSlug) || searchSlug.contains(shopSlug)) {
              matchedShop = shop;
              print('     ✅ MATCH PARTIEL TROUVÉ !');
              break;
            }
          }

          // Fallback: comparaison par nom slugifié si slug pas disponible
          final slugifiedShopName = _slugify(shop.name);
          final slugifiedIdentifier = identifier.toLowerCase();

          print('     Comparaison nom: "$slugifiedShopName" vs "$slugifiedIdentifier"');

          if (slugifiedShopName == slugifiedIdentifier ||
              slugifiedShopName.contains(slugifiedIdentifier) ||
              slugifiedIdentifier.contains(slugifiedShopName)) {
            matchedShop = shop;
            print('     ✅ MATCH PAR NOM TROUVÉ !');
            break;
          }
        }

        if (matchedShop != null) {
          print('✅ [getShopByLink] Boutique trouvée: ${matchedShop.name}');
          return matchedShop;
        }

        print('❌ [getShopByLink] Aucune correspondance trouvée pour: "$identifier"');
        throw Exception('Boutique introuvable avec le slug "$identifier"');

      } catch (e) {
        print('❌ [getShopByLink] Erreur lors de la recherche: $e');
        throw Exception('Impossible de récupérer la boutique: ${e.toString().replaceAll("Exception: ", "")}');
      }

    } catch (e) {
      print('❌ [getShopByLink] Erreur finale: $e');
      throw Exception('Boutique introuvable: ${e.toString().replaceAll("Exception: ", "")}');
    }
  }

  // Helper pour convertir un nom en slug
  static String _slugify(String text) {
    return text
        .toLowerCase()
        .replaceAll(RegExp(r'[àáâãäå]'), 'a')
        .replaceAll(RegExp(r'[èéêë]'), 'e')
        .replaceAll(RegExp(r'[ìíîï]'), 'i')
        .replaceAll(RegExp(r'[òóôõö]'), 'o')
        .replaceAll(RegExp(r'[ùúûü]'), 'u')
        .replaceAll(RegExp(r'[ñ]'), 'n')
        .replaceAll(RegExp(r'[ç]'), 'c')
        .replaceAll(RegExp(r'''['"\s]+'''), '-')
        .replaceAll(RegExp(r'[^a-z0-9\-]'), '')
        .replaceAll(RegExp(r'\-+'), '-')
        .replaceAll(RegExp(r'^-|-$'), '');
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
      throw Exception('Erreur lors du chargement des boutiques en vedette');
    }
  }
}


