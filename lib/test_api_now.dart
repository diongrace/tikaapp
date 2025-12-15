import 'package:http/http.dart' as http;
import 'dart:convert';

/// TEST IMMÉDIAT : Vérifier si le backend est vraiment corrigé
///
/// EXÉCUTER : dart lib/test_api_now.dart

void main() async {
  print('');
  print('=' * 70);
  print('🔍 TEST IMMÉDIAT : Le backend est-il vraiment corrigé ?');
  print('=' * 70);
  print('');

  const baseUrl = 'https://prepro.tika-ci.com/api';
  const deviceFp = 'android_bp41.250822.007_sdk_gphone64_x86_64_emu64xa';

  print('📡 URL testée : $baseUrl/client/favorites');
  print('🔑 Device Fingerprint : $deviceFp');
  print('');
  print('⏳ Envoi de la requête...');
  print('');

  try {
    final uri = Uri.parse('$baseUrl/client/favorites')
        .replace(queryParameters: {'device_fingerprint': deviceFp});

    final response = await http.get(
      uri,
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
    );

    print('─' * 70);
    print('📊 RÉSULTAT :');
    print('─' * 70);
    print('');
    print('HTTP Status Code : ${response.statusCode}');
    print('');
    print('Response Body :');
    print(response.body);
    print('');
    print('─' * 70);
    print('');

    // Analyse du résultat
    if (response.statusCode == 500) {
      final data = jsonDecode(response.body);
      final message = data['message'] ?? '';

      if (message.contains('Attempt to read property')) {
        print('❌❌❌ BACKEND **NON** CORRIGÉ ! ❌❌❌');
        print('');
        print('Le message d\'erreur contient : "Attempt to read property"');
        print('');
        print('Cela signifie que le fichier FavoritesController.php');
        print('n\'a PAS été remplacé par la version corrigée.');
        print('');
        print('🔴 PREUVE : L\'erreur vient du serveur, pas du code Flutter !');
        print('');
        print('💡 CE QU\'IL FAUT FAIRE :');
        print('   1. Demandez au dev backend de montrer une capture d\'écran');
        print('      du fichier app/Http/Controllers/Api/Client/FavoritesController.php');
        print('      ouvert dans un éditeur, montrant la ligne 38');
        print('');
        print('   2. La ligne 38 DOIT contenir :');
        print('      return \$favorite->shop !== null && \$favorite->shop->is_active == true;');
        print('');
        print('   3. Sinon, le fichier n\'a PAS été corrigé !');
        print('');
      } else {
        print('⚠️ Erreur 500 mais message différent :');
        print('   $message');
      }
    } else if (response.statusCode == 200) {
      final data = jsonDecode(response.body);

      if (data['success'] == true) {
        print('✅✅✅ BACKEND CORRIGÉ AVEC SUCCÈS ! ✅✅✅');
        print('');
        print('L\'API fonctionne correctement !');
        print('');

        if (data['data'] != null && data['data']['favorites'] != null) {
          final favorites = data['data']['favorites'] as List;
          print('Nombre de favoris trouvés : ${favorites.length}');
          print('');

          if (favorites.isEmpty) {
            print('✅ Aucun favori (normal si émulateur nettoyé)');
          } else {
            print('✅ Favoris valides retournés :');
            for (var i = 0; i < favorites.length && i < 3; i++) {
              final fav = favorites[i];
              print('   ${i + 1}. Shop ID: ${fav['shop_id']} - ${fav['shop']?['name'] ?? 'N/A'}');
            }
          }
        }
        print('');
        print('🎉 VOUS POUVEZ MAINTENANT TESTER SUR L\'ÉMULATEUR !');
        print('   1. Fermez complètement l\'app');
        print('   2. Relancez-la');
        print('   3. Ouvrez l\'écran des favoris');
        print('   4. Plus d\'erreur 500 !');
      } else {
        print('⚠️ Réponse success=false :');
        print('   ${data['message']}');
      }
    } else {
      print('⚠️ Code HTTP inattendu : ${response.statusCode}');
      print('   Voir la réponse ci-dessus');
    }

  } catch (e) {
    print('❌ Erreur lors du test :');
    print('   $e');
  }

  print('');
  print('=' * 70);
  print('');
}
