import 'package:http/http.dart' as http;
import 'dart:convert';

/// Test pour vérifier si le backend a bien été corrigé
void main() async {
  print('🔍 Test: Le backend a-t-il été corrigé ?');
  print('=' * 60);
  print('');

  const baseUrl = 'https://prepro.tika-ci.com/api';
  const deviceFingerprint = 'android_bp41.250822.007_sdk_gphone64_x86_64_emu64xa';

  final uri = Uri.parse('$baseUrl/client/favorites')
      .replace(queryParameters: {'device_fingerprint': deviceFingerprint});

  print('📡 URL: $uri');
  print('');

  try {
    final response = await http.get(
      uri,
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
    );

    print('📊 HTTP Status: ${response.statusCode}');
    print('📦 Response Body:');
    print(response.body);
    print('');

    if (response.statusCode == 500) {
      final data = jsonDecode(response.body);
      final message = data['message'] ?? '';

      if (message.contains('Attempt to read property')) {
        print('❌ BACKEND NON CORRIGÉ!');
        print('');
        print('Le message d\'erreur contient: "$message"');
        print('');
        print('💡 ACTIONS REQUISES:');
        print('   1. Le fichier FIX_FavoritesController.php n\'a PAS été appliqué');
        print('   2. Vérifiez le fichier sur le serveur:');
        print('      app/Http/Controllers/Api/Client/FavoritesController.php');
        print('   3. Il doit contenir la vérification: if (\$favorite->shop !== null)');
        print('');
      } else {
        print('⚠️ Erreur 500 mais différente');
        print('Message: $message');
      }
    } else if (response.statusCode == 200) {
      print('✅ Backend semble OK!');
      final data = jsonDecode(response.body);
      print('Success: ${data['success']}');

      if (data['data'] != null && data['data']['favorites'] != null) {
        final favorites = data['data']['favorites'] as List;
        print('Favoris trouvés: ${favorites.length}');
      }
    }
  } catch (e) {
    print('❌ Erreur: $e');
  }

  print('');
  print('=' * 60);
}
