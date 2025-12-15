import 'dart:io';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

class DeviceService {
  static const String _deviceFingerprintKey = 'device_fingerprint';

  /// Obtenir ou générer un device_fingerprint unique
  /// Ce fingerprint est utilisé pour tracker les commandes sans authentification
  static Future<String> getDeviceFingerprint() async {
    final prefs = await SharedPreferences.getInstance();

    // Vérifier si un fingerprint existe déjà
    String? existingFingerprint = prefs.getString(_deviceFingerprintKey);

    if (existingFingerprint != null && existingFingerprint.isNotEmpty) {
      print('✅ [DeviceService] Device fingerprint existant: $existingFingerprint');
      return existingFingerprint;
    }

    print('🆕 [DeviceService] Génération d\'un nouveau device fingerprint...');

    // Générer un nouveau fingerprint basé sur les infos de l'appareil
    final deviceInfo = DeviceInfoPlugin();
    String fingerprint;

    try {
      if (Platform.isAndroid) {
        final androidInfo = await deviceInfo.androidInfo;
        // Créer un ID unique basé sur les infos Android
        fingerprint = 'android_${androidInfo.id}_${androidInfo.model}_${DateTime.now().millisecondsSinceEpoch}';
      } else if (Platform.isIOS) {
        final iosInfo = await deviceInfo.iosInfo;
        // Créer un ID unique basé sur les infos iOS
        fingerprint = 'ios_${iosInfo.identifierForVendor}_${iosInfo.model}_${DateTime.now().millisecondsSinceEpoch}';
      } else {
        // Pour les autres plateformes (web, desktop), générer un ID aléatoire
        fingerprint = 'device_${DateTime.now().millisecondsSinceEpoch}_${DateTime.now().microsecondsSinceEpoch}';
      }
    } catch (e) {
      // En cas d'erreur, générer un ID basé sur le timestamp
      print('Erreur lors de la génération du device fingerprint: $e');
      fingerprint = 'device_${DateTime.now().millisecondsSinceEpoch}_fallback';
    }

    // Sauvegarder le fingerprint pour les prochaines utilisations
    await prefs.setString(_deviceFingerprintKey, fingerprint);

    print('✅ [DeviceService] Nouveau device fingerprint généré et sauvegardé: $fingerprint');

    return fingerprint;
  }

  /// Réinitialiser le device fingerprint (utile pour les tests)
  static Future<void> resetDeviceFingerprint() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_deviceFingerprintKey);
  }

  /// Obtenir le fingerprint existant sans en générer un nouveau
  static Future<String?> getExistingFingerprint() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_deviceFingerprintKey);
  }
}
