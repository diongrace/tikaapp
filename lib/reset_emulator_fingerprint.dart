import 'package:http/http.dart' as http;
import 'dart:convert';
import './core/services/storage_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Script pour réinitialiser le device fingerprint de l'émulateur
///
/// EXÉCUTER : dart lib/reset_emulator_fingerprint.dart

void main() async {
  print('');
  print('=' * 70);
  print('🔄 RÉINITIALISATION DU DEVICE FINGERPRINT');
  print('=' * 70);
  print('');

  // Initialiser SharedPreferences
  await SharedPreferences.getInstance();

  print('📋 Étape 1 : Afficher l\'ancien device fingerprint...');
  final oldFingerprint = await StorageService.getDeviceFingerprint();
  print('   Ancien: $oldFingerprint');
  print('');

  print('🔄 Étape 2 : Générer un nouveau device fingerprint...');
  final newFingerprint = await StorageService.resetDeviceFingerprint();
  print('   Nouveau: $newFingerprint');
  print('');

  print('✅ Device fingerprint réinitialisé avec succès !');
  print('');

  print('🧪 Étape 3 : Tester l\'API avec le nouveau fingerprint...');
  print('');

  const baseUrl = 'https://prepro.tika-ci.com/api';

  final uri = Uri.parse('$baseUrl/client/favorites')
      .replace(queryParameters: {'device_fingerprint': newFingerprint});

  print('📡 URL testée : $uri');
  print('');

  try {
    final response = await http.get(uri, headers: {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    });

    print('📊 Status Code: ${response.statusCode}');
    print('📦 Response:');
    print(response.body);
    print('');

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      if (data['success'] == true) {
        print('✅✅✅ SUCCÈS ! ✅✅✅');
        print('');
        print('L\'API fonctionne avec le nouveau device fingerprint !');
        print('');
        final favorites = data['data']['favorites'] as List;
        print('Favoris trouvés: ${favorites.length}');
        print('');
        print('🎉 VOUS POUVEZ MAINTENANT UTILISER L\'APP !');
        print('');
        print('Action suivante :');
        print('   1. Fermez complètement l\'app sur l\'émulateur');
        print('   2. Relancez l\'app (hot reload ne suffit pas)');
        print('   3. Ouvrez l\'écran des favoris');
        print('   4. Plus d\'erreur 500 !');
      }
    } else if (response.statusCode == 500) {
      print('❌ Erreur 500 - CELA NE DEVRAIT PAS ARRIVER !');
      print('');
      print('Le nouveau fingerprint devrait être "propre".');
      print('Cela signifie que le backend a un problème plus profond.');
    }
  } catch (e) {
    print('❌ Erreur: $e');
  }

  print('');
  print('=' * 70);
  print('');
  print('📝 IMPORTANT :');
  print('   - Le nouveau fingerprint a été sauvegardé localement');
  print('   - L\'app utilisera automatiquement ce nouveau fingerprint');
  print('   - Les anciens favoris orphelins ne sont plus associés à cet émulateur');
  print('   - Vous repartez avec un appareil "neuf" côté API');
  print('');
}
