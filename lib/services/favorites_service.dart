import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import './utils/api_endpoint.dart';
import './models/shop_model.dart';
import './auth_service.dart';

/// Service pour gérer les boutiques favorites
/// Authentification: Bearer Token uniquement (Sanctum)
///
/// Endpoints:
/// 1. GET    /client/favorites              - Liste des favoris
/// 2. GET    /client/favorites/stats        - Statistiques
/// 3. GET    /client/favorites/suggestions  - Suggestions
/// 4. POST   /client/favorites              - Ajouter un favori
/// 5. POST   /client/favorites/toggle       - Toggle favori
/// 6. GET    /client/favorites/{id}         - Détail d'un favori
/// 7. GET    /client/favorites/{id}/check   - Vérifier si favori
/// 8. DELETE /client/favorites/{id}         - Retirer un favori
class FavoritesService {
  /// Headers avec authentification Bearer
  static Map<String, String> get _headers => {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        if (AuthService.authToken != null)
          'Authorization': 'Bearer ${AuthService.authToken}',
      };

  /// S'assurer que le token est disponible avant une requete
  static Future<void> _ensureAuth() async {
    await AuthService.ensureToken();
  }

  // ============================================================
  // CACHE PERSISTANT (SharedPreferences + mémoire)
  // ============================================================

  static const String _cacheKey = 'favorites_shops_cache';

  /// Cache mémoire synchronisé avec SharedPreferences
  static final Map<int, Shop> _localCache = {};
  static bool _cacheLoaded = false;

  /// Charger le cache depuis SharedPreferences
  static Future<void> _loadCacheFromDisk() async {
    if (_cacheLoaded) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      final cacheJson = prefs.getString(_cacheKey);
      if (cacheJson != null) {
        final List<dynamic> list = jsonDecode(cacheJson);
        for (var item in list) {
          try {
            final shop = Shop.fromJson(item as Map<String, dynamic>);
            _localCache[shop.id] = shop;
          } catch (_) {}
        }
        print('💾 Cache disque chargé: ${_localCache.length} favoris');
      }
    } catch (e) {
      print('❌ Erreur chargement cache disque: $e');
    }
    _cacheLoaded = true;
  }

  /// Persister le cache vers SharedPreferences
  static Future<void> _saveCacheToDisk() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final list = _localCache.values.map((shop) => shop.toJson()).toList();
      await prefs.setString(_cacheKey, jsonEncode(list));
    } catch (e) {
      print('❌ Erreur sauvegarde cache disque: $e');
    }
  }

  /// Ajouter une boutique au cache + persister
  static void addToLocalCache(Shop shop) {
    _localCache[shop.id] = shop;
    _saveCacheToDisk();
    print('💾 Cache: ajouté ${shop.name} (${_localCache.length} favoris)');
  }

  /// Retirer une boutique du cache + persister
  static void removeFromLocalCache(int shopId) {
    _localCache.remove(shopId);
    _saveCacheToDisk();
    print('💾 Cache: retiré shopId=$shopId (${_localCache.length} favoris)');
  }

  /// Vérifier si une boutique est en cache
  static bool isInLocalCache(int shopId) {
    return _localCache.containsKey(shopId);
  }

  /// Vider le cache
  static void clearLocalCache() {
    _localCache.clear();
    _saveCacheToDisk();
  }

  /// Fallback cache si API vide/erreur
  static List<Shop> _fallbackToCache() {
    if (_localCache.isNotEmpty) {
      print('💾 Fallback cache: ${_localCache.length} favoris');
      return _localCache.values.toList();
    }
    return [];
  }

  // ============================================================
  // 1. GET /client/favorites - Liste des favoris
  // ============================================================

  /// Récupère la liste des boutiques favorites
  /// [type]: all, restaurant, boutique (défaut: all)
  /// [search]: recherche par nom/catégorie/ville
  static Future<List<Shop>> getFavorites({
    String type = 'all',
    String? search,
    int perPage = 50,
  }) async {
    await _ensureAuth();
    await _loadCacheFromDisk();
    print('💾 Cache après chargement: ${_localCache.length} favoris [${_localCache.keys.toList()}]');

    try {
      final queryParams = <String, String>{
        'type': type,
        'per_page': perPage.toString(),
        if (search != null && search.isNotEmpty) 'search': search,
      };
      final uri = Uri.parse(Endpoints.favorites).replace(queryParameters: queryParams);

      print('📤 GET /client/favorites?type=$type');
      print('🔗 URL: $uri');
      print('🔑 Auth: ${AuthService.authToken != null ? "Bearer token present" : "No token"}');

      final response = await http.get(uri, headers: _headers);
      print('📥 Status: ${response.statusCode}');
      print('📄 Body: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        if (data['success'] == true && data['data'] != null) {
          final responseData = data['data'];

          // Extraire la liste des favoris selon le format API
          // Format attendu: { data: { favorites: [...], summary: {...}, pagination: {...} } }
          List favoritesList = [];
          if (responseData['favorites'] is List) {
            favoritesList = responseData['favorites'] as List;
          } else if (responseData is List) {
            favoritesList = responseData;
          }

          print('📋 ${favoritesList.length} favoris depuis l\'API');

          if (favoritesList.isEmpty) {
            print('ℹ️ API retourne 0 favoris');
            return _fallbackToCache();
          }

          // Parser les favoris — format API: objets directs avec id, name, logo, etc.
          final shops = <Shop>[];
          for (var favorite in favoritesList) {
            try {
              final map = favorite as Map<String, dynamic>;
              shops.add(Shop.fromJson(map));
              print('  ✅ ${map['name']}');
            } catch (e) {
              print('  ❌ Erreur parsing: $e');
            }
          }

          // Synchroniser le cache avec l'API
          _localCache.clear();
          for (var shop in shops) {
            _localCache[shop.id] = shop;
          }
          _saveCacheToDisk();

          print('✅ ${shops.length} favoris chargés');
          return shops;
        }

        print('⚠️ Réponse inattendue: ${data['message'] ?? 'success != true'}');
        return _fallbackToCache();
      } else if (response.statusCode == 401) {
        print('❌ Non authentifié (401)');
        throw Exception('Authentification requise');
      } else {
        print('❌ Erreur HTTP ${response.statusCode}');
        return _fallbackToCache();
      }
    } catch (e) {
      print('❌ Erreur getFavorites: $e');
      if (_localCache.isNotEmpty) {
        return _fallbackToCache();
      }
      rethrow;
    }
  }

  // ============================================================
  // 2. GET /client/favorites/stats - Statistiques
  // ============================================================

  static Future<Map<String, dynamic>> getStats() async {
    try {
      print('📤 GET /client/favorites/stats');
      final response = await http.get(
        Uri.parse(Endpoints.favoritesStats),
        headers: _headers,
      );
      print('📥 Status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          return data['data'] ?? {};
        }
      }
      return {};
    } catch (e) {
      print('❌ Erreur getStats: $e');
      return {};
    }
  }

  // ============================================================
  // 3. GET /client/favorites/suggestions - Suggestions
  // ============================================================

  static Future<List<Shop>> getSuggestions({int limit = 10}) async {
    try {
      final uri = Uri.parse(Endpoints.favoritesSuggestions).replace(
        queryParameters: {'limit': limit.toString()},
      );

      print('📤 GET /client/favorites/suggestions');
      final response = await http.get(uri, headers: _headers);
      print('📥 Status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          final suggestions = data['data']?['suggestions'];
          if (suggestions is List) {
            return suggestions
                .map((e) => Shop.fromJson(e as Map<String, dynamic>))
                .toList();
          }
        }
      }
      return [];
    } catch (e) {
      print('❌ Erreur getSuggestions: $e');
      return [];
    }
  }

  // ============================================================
  // 4. POST /client/favorites - Ajouter un favori
  // ============================================================

  static Future<Map<String, dynamic>> addFavorite(int shopId) async {
    try {
      await _ensureAuth();
      print('📤 POST /client/favorites (shop_id: $shopId)');
      final response = await http.post(
        Uri.parse(Endpoints.favorites),
        headers: _headers,
        body: jsonEncode({'shop_id': shopId}),
      );
      print('📥 Status: ${response.statusCode}');
      print('📄 Body: ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body);
        print('✅ Favori ajouté');
        return data;
      } else if (response.statusCode == 400) {
        final data = jsonDecode(response.body);
        print('ℹ️ Déjà en favoris');
        return data;
      } else if (response.statusCode == 404) {
        throw Exception('Boutique introuvable ou inactive');
      } else {
        throw Exception('Erreur ${response.statusCode}');
      }
    } catch (e) {
      print('❌ Erreur addFavorite: $e');
      rethrow;
    }
  }

  // ============================================================
  // 5. POST /client/favorites/toggle - Toggle favori (RECOMMANDÉ)
  // ============================================================

  /// Toggle un favori — endpoint recommandé par l'API
  /// Retourne { success, message, data: { shop_id, shop_name, is_favorite, action, total_favorites } }
  static Future<Map<String, dynamic>> toggleFavorite(int shopId) async {
    try {
      await _ensureAuth();
      print('📤 POST /client/favorites/toggle (shop_id: $shopId)');
      print('🔑 Auth: ${AuthService.isAuthenticated ? "OK" : "NON CONNECTE"}');

      final response = await http.post(
        Uri.parse(Endpoints.favoritesToggle),
        headers: _headers,
        body: jsonEncode({'shop_id': shopId}),
      );
      print('📥 Status: ${response.statusCode}');
      print('📄 Body: ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body);
        final isFav = data['data']?['is_favorite'] == true;
        final action = data['data']?['action']; // "added" ou "removed"
        print('✅ Toggle: is_favorite=$isFav, action=$action');
        return data;
      } else {
        throw Exception('Erreur ${response.statusCode}');
      }
    } catch (e) {
      print('❌ Erreur toggleFavorite: $e');
      rethrow;
    }
  }

  // ============================================================
  // 6. GET /client/favorites/{id} - Détail d'un favori
  // ============================================================

  static Future<Map<String, dynamic>> getFavoriteDetail(int shopId) async {
    try {
      print('📤 GET /client/favorites/$shopId');
      final response = await http.get(
        Uri.parse(Endpoints.favoriteDetail(shopId)),
        headers: _headers,
      );
      print('📥 Status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          return data['data'] ?? {};
        }
        return {};
      } else if (response.statusCode == 404) {
        throw Exception('Favori introuvable');
      } else {
        throw Exception('Erreur ${response.statusCode}');
      }
    } catch (e) {
      print('❌ Erreur getFavoriteDetail: $e');
      rethrow;
    }
  }

  // ============================================================
  // 7. GET /client/favorites/{id}/check - Vérifier si favori
  // ============================================================

  /// Vérifie si une boutique est en favori
  /// Retourne { data: { shop_id, shop_name, is_favorite } }
  static Future<bool> isFavorite(int shopId) async {
    await _ensureAuth();
    await _loadCacheFromDisk();

    // Vérifier d'abord le cache
    if (_localCache.containsKey(shopId)) {
      print('💾 isFavorite cache: true (shopId=$shopId)');
      return true;
    }

    try {
      print('📤 GET /client/favorites/$shopId/check');
      final response = await http.get(
        Uri.parse(Endpoints.favoriteCheck(shopId)),
        headers: _headers,
      );
      print('📥 Status: ${response.statusCode}');
      print('📄 Body: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final isFav = data['data']?['is_favorite'] == true;
        print(isFav ? '✅ Est en favori' : '❌ N\'est pas en favori');
        return isFav;
      }
      return false;
    } catch (e) {
      print('❌ Erreur isFavorite: $e');
      return false;
    }
  }

  // ============================================================
  // 8. DELETE /client/favorites/{id} - Retirer un favori
  // ============================================================

  static Future<Map<String, dynamic>> removeFavorite(int shopId) async {
    try {
      await _ensureAuth();
      removeFromLocalCache(shopId);

      print('📤 DELETE /client/favorites/$shopId');
      final response = await http.delete(
        Uri.parse(Endpoints.removeFavorite(shopId)),
        headers: _headers,
      );
      print('📥 Status: ${response.statusCode}');
      print('📄 Body: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        print('✅ Favori retiré');
        return data;
      } else if (response.statusCode == 404) {
        return {'success': true, 'message': 'Favori déjà retiré'};
      } else {
        throw Exception('Erreur ${response.statusCode}');
      }
    } catch (e) {
      print('❌ Erreur removeFavorite: $e');
      rethrow;
    }
  }
}
