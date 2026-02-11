import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import '../firebase_options.dart';
import './notification_service.dart';

/// Handler pour les messages en arriere-plan (doit etre une fonction top-level)
/// Quand l'app est fermee, Flutter cree un isolate separe - Firebase doit etre reinitialise
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  print('[Push] Message en arriere-plan: ${message.messageId}');
  print('[Push] Titre: ${message.notification?.title}');
  print('[Push] Body: ${message.notification?.body}');
}

/// Verifie si la plateforme supporte les notifications locales (Android/iOS uniquement)
bool get _isMobilePlatform {
  try {
    return Platform.isAndroid || Platform.isIOS;
  } catch (_) {
    return false;
  }
}

/// Service de gestion des push notifications FCM
class PushNotificationService {
  static final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  static FlutterLocalNotificationsPlugin? _localNotifications;
  static bool _localNotificationsInitialized = false;
  static Timer? _pollingTimer;

  static String? _fcmToken;

  /// Recuperer le token FCM actuel
  static String? get fcmToken => _fcmToken;

  /// Compteur global de notifications non lues (ecoutable par l'UI)
  static final ValueNotifier<int> unreadCount = ValueNotifier<int>(0);

  /// Canal de notification Android
  static const AndroidNotificationChannel _channel = AndroidNotificationChannel(
    'tika_notifications',
    'Notifications Tika',
    description: 'Notifications de commandes, promotions et fidelite',
    importance: Importance.high,
  );

  /// Initialiser le service de push notifications
  static Future<void> initialize() async {
    // 1. Demander la permission FCM
    final settings = await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false,
    );

    print('[Push] Permission: ${settings.authorizationStatus}');

    if (settings.authorizationStatus != AuthorizationStatus.authorized &&
        settings.authorizationStatus != AuthorizationStatus.provisional) {
      print('[Push] Notifications refusees par l\'utilisateur');
      return;
    }

    // 2. Configurer le handler en arriere-plan AVANT tout
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

    // 3. Initialiser les notifications locales (Android/iOS uniquement)
    // IMPORTANT: Doit etre fait AVANT d'ecouter les messages pour que le canal existe
    if (_isMobilePlatform) {
      await _initLocalNotifications();

      // Android 13+ : demander la permission systeme pour afficher les notifications
      if (Platform.isAndroid && _localNotifications != null) {
        final androidPlugin = _localNotifications!
            .resolvePlatformSpecificImplementation<
                AndroidFlutterLocalNotificationsPlugin>();
        if (androidPlugin != null) {
          final granted = await androidPlugin.requestNotificationsPermission();
          print('[Push] Permission Android notifications: $granted');
        }
      }
    }

    // 4. Configurer la presentation iOS au premier plan
    await _messaging.setForegroundNotificationPresentationOptions(
      alert: true,
      badge: true,
      sound: true,
    );

    // 5. Ecouter les messages au premier plan
    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

    // 6. Ecouter les clics sur les notifications
    FirebaseMessaging.onMessageOpenedApp.listen(_handleNotificationTap);

    // 7. Verifier si l'app a ete ouverte via une notification
    final initialMessage = await _messaging.getInitialMessage();
    if (initialMessage != null) {
      _handleNotificationTap(initialMessage);
    }

    // 8. Recuperer le token FCM
    await _refreshToken();

    // 9. Ecouter le rafraichissement du token
    _messaging.onTokenRefresh.listen((newToken) {
      _fcmToken = newToken;
      print('[Push] Token rafraichi: ${newToken.substring(0, 20)}...');
      _registerTokenIfAuthenticated();
    });

    print('[Push] Service initialise avec succes');
  }

  /// Initialiser flutter_local_notifications (Android/iOS)
  static Future<void> _initLocalNotifications() async {
    try {
      _localNotifications = FlutterLocalNotificationsPlugin();

      const androidSettings =
          AndroidInitializationSettings('@mipmap/ic_launcher');
      const iosSettings = DarwinInitializationSettings(
        requestAlertPermission: true,
        requestBadgePermission: true,
        requestSoundPermission: true,
      );
      const initSettings = InitializationSettings(
        android: androidSettings,
        iOS: iosSettings,
      );

      await _localNotifications!.initialize(
        initSettings,
        onDidReceiveNotificationResponse: _onNotificationTapped,
      );

      // Creer le canal Android
      if (Platform.isAndroid) {
        await _localNotifications!
            .resolvePlatformSpecificImplementation<
                AndroidFlutterLocalNotificationsPlugin>()
            ?.createNotificationChannel(_channel);
      }

      _localNotificationsInitialized = true;
      print('[Push] Notifications locales initialisees');
    } catch (e) {
      print('[Push] Erreur init notifications locales: $e');
      _localNotifications = null;
      _localNotificationsInitialized = false;
    }
  }

  /// Recuperer/rafraichir le token FCM
  static Future<void> _refreshToken() async {
    try {
      _fcmToken = await _messaging.getToken();
      if (_fcmToken != null && _fcmToken!.length > 20) {
        print('[Push] Token FCM: ${_fcmToken!.substring(0, 20)}...');
      }
    } catch (e) {
      print('[Push] Erreur recuperation token: $e');
    }
  }

  /// Enregistrer le token FCM aupres du backend si authentifie
  static Future<void> registerDeviceToken() async {
    print('[Push] ━━━ ENREGISTREMENT DEVICE ━━━');

    // 1. Obtenir le token FCM
    if (_fcmToken == null) {
      print('[Push] Pas de token en mémoire, récupération...');
      await _refreshToken();
    }

    if (_fcmToken == null) {
      print('[Push] ❌ ÉCHEC: Pas de token FCM disponible');
      return;
    }
    print('[Push] ✅ Token FCM: ${_fcmToken!.substring(0, 20)}...');

    // 2. Vérifier l'authentification
    if (!NotificationService.isAuthenticated) {
      print('[Push] ❌ ÉCHEC: Non authentifié');
      return;
    }
    print('[Push] ✅ Client authentifié');

    // 3. Enregistrer auprès du backend
    String deviceType = 'android';
    try {
      deviceType = Platform.isIOS ? 'ios' : 'android';
    } catch (_) {}

    final success = await NotificationService.registerDevice(
      fcmToken: _fcmToken!,
      deviceType: deviceType,
    );

    if (success) {
      print('[Push] ✅ Device enregistré auprès du backend');
    } else {
      print('[Push] ❌ ÉCHEC enregistrement device');
    }
    print('[Push] ━━━━━━━━━━━━━━━━━━━━━━━━━━━');
  }

  /// Enregistrer le token si l'utilisateur est authentifie
  static Future<void> _registerTokenIfAuthenticated() async {
    if (NotificationService.isAuthenticated) {
      await registerDeviceToken();
    }
  }

  /// Rafraichir le compteur de notifications non lues depuis l'API
  static Future<void> refreshUnreadCount() async {
    try {
      final count = await NotificationService.getUnreadCount();
      unreadCount.value = count;
      print('[Push] Badge mis a jour: $count non lues');
    } catch (e) {
      print('[Push] Erreur refresh unread count: $e');
    }
  }

  /// Demarrer le polling periodique du compteur (toutes les 30 secondes)
  static void startPolling() {
    stopPolling();
    // Rafraichir immediatement
    refreshUnreadCount();
    // Puis toutes les 30 secondes
    _pollingTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      refreshUnreadCount();
    });
    print('[Push] Polling demarre (intervalle: 30s)');
  }

  /// Arreter le polling periodique
  static void stopPolling() {
    _pollingTimer?.cancel();
    _pollingTimer = null;
  }

  /// Gerer un message recu au premier plan
  static void _handleForegroundMessage(RemoteMessage message) {
    print('[Push] Message au premier plan: ${message.notification?.title}');
    print('[Push] Data: ${message.data}');

    // Rafraichir le badge quand un push arrive
    refreshUnreadCount();

    // Extraire titre et body depuis notification OU data
    final notification = message.notification;
    final String title = notification?.title
        ?? message.data['title']
        ?? 'Tika';
    final String body = notification?.body
        ?? message.data['body']
        ?? message.data['message']
        ?? '';

    if (title == 'Tika' && body.isEmpty) return;

    // Afficher la notification locale si le plugin est disponible
    if (_localNotificationsInitialized && _localNotifications != null) {
      // Utiliser messageId pour eviter les doublons
      final notifId = message.messageId?.hashCode
          ?? DateTime.now().millisecondsSinceEpoch.remainder(100000);

      _localNotifications!.show(
        notifId,
        title,
        body,
        NotificationDetails(
          android: AndroidNotificationDetails(
            _channel.id,
            _channel.name,
            channelDescription: _channel.description,
            importance: Importance.high,
            priority: Priority.high,
            icon: '@mipmap/ic_launcher',
          ),
          iOS: const DarwinNotificationDetails(
            presentAlert: true,
            presentBadge: true,
            presentSound: true,
          ),
        ),
        payload: message.data['action_url'],
      );
    }
  }

  /// Gerer le clic sur une notification (app en arriere-plan)
  static void _handleNotificationTap(RemoteMessage message) {
    print('[Push] Notification cliquee: ${message.data}');
  }

  /// Gerer le clic sur une notification locale
  static void _onNotificationTapped(NotificationResponse response) {
    print('[Push] Notification locale cliquee: ${response.payload}');
  }
}
