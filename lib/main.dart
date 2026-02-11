import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart'; // import Firebase
import 'firebase_options.dart';                   // import options générées
import 'app/app.dart';                             // ton app existante
import 'services/auth_service.dart';               // Service d'authentification
import 'services/push_notification_service.dart';  // Service push notifications

void main() async {
  WidgetsFlutterBinding.ensureInitialized(); // nécessaire pour async

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Initialiser le service d'authentification
  await AuthService.initialize();

  // Initialiser les push notifications (FCM + notifications locales)
  try {
    await PushNotificationService.initialize();

    // Si l'utilisateur est deja connecte, enregistrer le token FCM + demarrer le polling
    if (AuthService.isAuthenticated) {
      print('[Main] Client authentifié -> enregistrement device FCM...');
      await PushNotificationService.registerDeviceToken();
      PushNotificationService.startPolling();
    } else {
      print('[Main] Client non authentifié -> pas d\'enregistrement FCM');
    }
  } catch (e) {
    print('[Main] Erreur init push notifications: $e');
  }

  runApp(const TikaApp());
}
