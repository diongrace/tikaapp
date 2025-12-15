import 'package:http/http.dart' as http;
import 'dart:convert';

/// Script de test pour diagnostiquer le problème des favoris
///
/// COMMENT EXÉCUTER :
/// dart test/test_favorites_api.dart

void main() async {
  print('🔍 Test de l\'API Favoris TIKA');
  print('=' * 50);
  print('');

  const baseUrl = 'https://prepro.tika-ci.com/api';
  const deviceFingerprint = 'flutter_test_device_123';

  final headers = {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
  };

  // Test 1: Récupérer les favoris
  print('📥 Test 1: GET /client/favorites');
  print('-' * 50);
  try {
    final uri = Uri.parse('$baseUrl/client/favorites')
        .replace(queryParameters: {'device_fingerprint': deviceFingerprint});

    print('📡 URL: $uri');

    final response = await http.get(uri, headers: headers);

    print('📊 HTTP Status: ${response.statusCode}');
    print('📦 Response Body:');
    print(response.body);

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      print('');
      print('✅ Réponse parsée:');
      print('   - success: ${data['success']}');
      print('   - data type: ${data['data']?.runtimeType}');

      if (data['data'] != null && data['data']['favorites'] != null) {
        final favorites = data['data']['favorites'] as List;
        print('   - Nombre de favoris: ${favorites.length}');

        if (favorites.isNotEmpty) {
          print('   - Premier favori:');
          print('     ${jsonEncode(favorites[0])}');
        }
      }
    } else if (response.statusCode == 500) {
      print('');
      print('❌ Erreur 500 - Le backend a un problème!');
      print('💡 Vérifiez que FIX_FavoritesController.php a été appliqué');
    }
  } catch (e) {
    print('❌ Erreur: $e');
  }

  print('');
  print('');

  // Test 2: Ajouter un favori
  print('📤 Test 2: POST /client/favorites (Ajouter boutique 10)');
  print('-' * 50);
  try {
    final body = {
      'shop_id': 10,
      'device_fingerprint': deviceFingerprint,
    };

    print('📤 Body: ${jsonEncode(body)}');

    final response = await http.post(
      Uri.parse('$baseUrl/client/favorites'),
      headers: headers,
      body: jsonEncode(body),
    );

    print('📊 HTTP Status: ${response.statusCode}');
    print('📦 Response Body:');
    print(response.body);

    if (response.statusCode == 200 || response.statusCode == 201) {
      final data = jsonDecode(response.body);
      print('');
      print('✅ Favori ajouté avec succès!');
      print('   - message: ${data['message']}');
    } else if (response.statusCode == 409) {
      print('');
      print('ℹ️ Boutique déjà en favoris');
    } else if (response.statusCode == 404) {
      print('');
      print('⚠️ Boutique 10 n\'existe pas - Essayez avec shop_id=1');
    }
  } catch (e) {
    print('❌ Erreur: $e');
  }

  print('');
  print('');

  // Test 3: Récupérer à nouveau les favoris
  print('📥 Test 3: GET /client/favorites (après ajout)');
  print('-' * 50);
  try {
    final uri = Uri.parse('$baseUrl/client/favorites')
        .replace(queryParameters: {'device_fingerprint': deviceFingerprint});

    final response = await http.get(uri, headers: headers);

    print('📊 HTTP Status: ${response.statusCode}');

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);

      if (data['data'] != null && data['data']['favorites'] != null) {
        final favorites = data['data']['favorites'] as List;
        print('✅ Nombre de favoris: ${favorites.length}');
      }
    }
  } catch (e) {
    print('❌ Erreur: $e');
  }

  print('');
  print('✅ Tests terminés');
  print('');
  print('💡 ACTIONS À FAIRE SI ERREUR 500:');
  print('   1. Vérifiez que FIX_FavoritesController.php est appliqué sur le serveur');
  print('   2. Nettoyez les favoris orphelins dans la BDD (voir GUIDE_CORRECTION_FAVORIS.md)');
  print('   3. Videz le cache Laravel: php artisan cache:clear');
}
