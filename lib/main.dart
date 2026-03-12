import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'firebase_options.dart';
import 'app/app.dart';
import 'services/auth_service.dart';
import 'services/push_notification_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // DOIT être fait AVANT Firebase.initializeApp() pour éviter "duplicate background isolate"
  // C'est le pattern officiel Firebase Flutter pour les notifications hors app
  FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

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
