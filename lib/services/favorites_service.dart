import 'package:http/http.dart' as http;
import 'dart:convert';
import './utils/api_endpoint.dart';
import './models/shop_model.dart';
import '../core/services/storage_service.dart';

/// Service pour gérer les boutiques favorites
/// LOGIQUE EXACTE DE L'API TIKA
///
/// Endpoints:
/// - GET /client/favorites?device_fingerprint=xxx : Récupérer les favoris
/// - POST /client/favorites : Ajouter un favori
/// - DELETE /client/favorites/{shopId}?device_fingerprint=xxx : Retirer un favori
class FavoritesService {
  static const Map<String, String> _headers = {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
  };

  /// 1. Récupérer la liste des boutiques favorites
  /// GET /client/favorites?device_fingerprint=xxx
  ///
  /// Retourne: List<Shop> - Liste des boutiques favorites actives
  static Future<List<Shop>> getFavorites() async {
    try {
      // Récupérer le device fingerprint
      final deviceFingerprint = await StorageService.getDeviceFingerprint();

      // Construire l'URL avec le query parameter
      final uri = Uri.parse(Endpoints.favorites).replace(
        queryParameters: {'device_fingerprint': deviceFingerprint},
      );

      print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
      print('📤 GET FAVORITES');
      print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
      print('🔗 URL: $uri');
      print('🔑 Device Fingerprint: $deviceFingerprint');
      print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');

      // Appel API
      final response = await http.get(uri, headers: _headers);

      print('📥 Response Status: ${response.statusCode}');

      // Traitement de la réponse
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        if (data['success'] == true) {
          // L'API retourne: { success: true, data: { favorites: [...] } }
          final favoritesData = data['data'];

          if (favoritesData == null) {
            print('⚠️ data est null');
            return [];
          }

          // Extraire la liste des favoris
          List favoritesList = [];

          if (favoritesData['favorites'] != null) {
            favoritesList = favoritesData['favorites'] as List;
          } else if (favoritesData is List) {
            favoritesList = favoritesData;
          } else {
            print('⚠️ Structure de favoris non reconnue');
            return [];
          }

          if (favoritesList.isEmpty) {
            print('ℹ️ Aucun favori trouvé');
            return [];
          }

          print('✅ ${favoritesList.length} favoris trouvés');

          // Extraire les boutiques des favoris
          // Chaque favori a la structure: { id, shop_id, shop: {...}, created_at }
          final shops = <Shop>[];

          for (var i = 0; i < favoritesList.length; i++) {
            try {
              final favorite = favoritesList[i];

              if (favorite['shop'] != null) {
                final shop = Shop.fromJson(favorite['shop'] as Map<String, dynamic>);
                shops.add(shop);
              } else {
                print('⚠️ Favori $i sans boutique (supprimée?)');
              }
            } catch (e) {
              print('❌ Erreur parsing favori $i: $e');
            }
          }

          print('✅ ${shops.length} boutiques valides chargées');
          print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');

          return shops;
        } else {
          print('⚠️ success = false');
          print('   Message: ${data['message']}');
          return [];
        }
      } else if (response.statusCode == 500) {
        // Erreur serveur - Backend non corrigé
        print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
        print('❌ ERREUR 500 - BACKEND NON CORRIGÉ');
        print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
        throw Exception(
          'Le serveur a rencontré une erreur. '
          'Le backend doit être corrigé (voir GUIDE_CORRECTION_FAVORIS.md)'
        );
      } else {
        throw Exception('Erreur ${response.statusCode}: ${response.body}');
      }
    } catch (e) {
      print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
      print('❌ Erreur getFavorites: $e');
      print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');

      // Si erreur serveur, propager l'exception
      if (e.toString().contains('serveur')) {
        rethrow;
      }

      // Pour les autres erreurs, retourner liste vide
      return [];
    }
  }

  /// 2. Ajouter une boutique aux favoris
  /// POST /client/favorites
  /// Body: { shop_id: int, device_fingerprint: string }
  ///
  /// Retourne: Map avec success, message et data
  static Future<Map<String, dynamic>> addFavorite(int shopId) async {
    try {
      // Récupérer le device fingerprint
      final deviceFingerprint = await StorageService.getDeviceFingerprint();

      print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
      print('📤 POST ADD FAVORITE');
      print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
      print('🆔 Shop ID: $shopId');
      print('🔑 Device Fingerprint: $deviceFingerprint');

      // Construire le body selon l'API
      final body = {
        'shop_id': shopId,
        'device_fingerprint': deviceFingerprint,
      };

      print('📦 Body: ${jsonEncode(body)}');
      print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');

      // Appel API
      final response = await http.post(
        Uri.parse(Endpoints.favorites),
        headers: _headers,
        body: jsonEncode(body),
      );

      print('📥 Response Status: ${response.statusCode}');
      print('📥 Response Body: ${response.body}');

      // Traitement de la réponse
      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body);
        print('✅ Favori ajouté avec succès');
        print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
        return data;
      } else if (response.statusCode == 409) {
        // Déjà en favoris
        final data = jsonDecode(response.body);
        print('ℹ️ Déjà en favoris');
        print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
        return {
          'success': true,
          'message': 'Cette boutique est déjà dans vos favoris',
          'already_exists': true,
        };
      } else if (response.statusCode == 404) {
        // Boutique introuvable ou inactive
        print('❌ Boutique introuvable ou inactive');
        print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
        throw Exception('Boutique introuvable ou inactive');
      } else {
        throw Exception('Erreur ${response.statusCode}: ${response.body}');
      }
    } catch (e) {
      print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
      print('❌ Erreur addFavorite: $e');
      print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
      rethrow;
    }
  }

  /// 3. Retirer une boutique des favoris
  /// DELETE /client/favorites/{shopId}?device_fingerprint=xxx
  ///
  /// Retourne: Map avec success et message
  static Future<Map<String, dynamic>> removeFavorite(int shopId) async {
    try {
      // Récupérer le device fingerprint
      final deviceFingerprint = await StorageService.getDeviceFingerprint();

      // Construire l'URL avec le shop ID et le query parameter
      final uri = Uri.parse(Endpoints.removeFavorite(shopId)).replace(
        queryParameters: {'device_fingerprint': deviceFingerprint},
      );

      print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
      print('📤 DELETE REMOVE FAVORITE');
      print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
      print('🔗 URL: $uri');
      print('🆔 Shop ID: $shopId');
      print('🔑 Device Fingerprint: $deviceFingerprint');
      print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');

      // Appel API
      final response = await http.delete(uri, headers: _headers);

      print('📥 Response Status: ${response.statusCode}');

      // Traitement de la réponse
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        print('✅ Favori retiré avec succès');
        print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
        return data;
      } else if (response.statusCode == 404) {
        // Favori non trouvé (peut-être déjà retiré)
        print('ℹ️ Favori non trouvé');
        print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
        return {
          'success': true,
          'message': 'Favori introuvable (déjà retiré?)',
        };
      } else {
        throw Exception('Erreur ${response.statusCode}: ${response.body}');
      }
    } catch (e) {
      print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
      print('❌ Erreur removeFavorite: $e');
      print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
      rethrow;
    }
  }

  /// 4. Vérifier si une boutique est en favori
  /// Utilise getFavorites() et vérifie si le shop_id est présent
  ///
  /// Note: Cette méthode fait un appel API à chaque fois.
  /// Pour des performances optimales, stocker le résultat localement.
  static Future<bool> isFavorite(int shopId) async {
    try {
      final favorites = await getFavorites();
      final isFav = favorites.any((shop) => shop.id == shopId);

      print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
      print('🔍 CHECK IS FAVORITE');
      print('🆔 Shop ID: $shopId');
      print(isFav ? '✅ Est en favori' : '❌ N\'est pas en favori');
      print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');

      return isFav;
    } catch (e) {
      print('❌ Erreur isFavorite: $e');
      return false;
    }
  }

  /// 5. Toggle favori (ajouter ou retirer)
  /// Helper method pour simplifier l'utilisation
  ///
  /// @param shopId: ID de la boutique
  /// @param currentlyFavorite: État actuel (true = déjà en favori)
  ///
  /// Retourne: Map avec success et message
  static Future<Map<String, dynamic>> toggleFavorite(
    int shopId,
    bool currentlyFavorite,
  ) async {
    print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    print('🔄 TOGGLE FAVORITE');
    print('🆔 Shop ID: $shopId');
    print('📊 État actuel: ${currentlyFavorite ? "EN FAVORI" : "PAS EN FAVORI"}');
    print('➡️  Action: ${currentlyFavorite ? "RETIRER" : "AJOUTER"}');
    print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');

    if (currentlyFavorite) {
      // Retirer des favoris
      return await removeFavorite(shopId);
    } else {
      // Ajouter aux favoris
      return await addFavorite(shopId);
    }
  }
}
