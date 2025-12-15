import 'package:http/http.dart' as http;
import 'dart:convert';

/// Test après nettoyage de la BDD
void main() async {
  print('🧹 Test après nettoyage des favoris orphelins\n');

  const baseUrl = 'https://prepro.tika-ci.com/api';
  const deviceFp = 'android_bp41.250822.007_sdk_gphone64_x86_64_emu64xa';

  final uri = Uri.parse('$baseUrl/client/favorites')
      .replace(queryParameters: {'device_fingerprint': deviceFp});

  print('📡 Test pour l\'émulateur...');
  print('Device: $deviceFp\n');

  try {
    final response = await http.get(uri, headers: {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    });

    print('📊 Status: ${response.statusCode}');
    print('📦 Response:');
    print(response.body);
    print('');

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      if (data['success'] == true) {
        print('✅✅✅ SUCCÈS ! L\'API fonctionne maintenant !');
        print('');
        final favorites = data['data']['favorites'] as List;
        print('Favoris trouvés: ${favorites.length}');
        print('');
        print('🎉 Vous pouvez maintenant tester sur l\'émulateur !');
      }
    } else if (response.statusCode == 500) {
      print('❌ Erreur 500 encore présente');
      print('');
      print('La BDD n\'a peut-être pas été nettoyée.');
      print('');
      print('Demandez au dev backend d\'exécuter :');
      print('DELETE FROM favorites');
      print('WHERE device_fingerprint = \'$deviceFp\';');
    }
  } catch (e) {
    print('❌ Erreur: $e');
  }
}
