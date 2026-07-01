import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import '../firebase_options.dart';
import './notification_service.dart';
import '../features/boutique/gift/gift_order_track_screen.dart';
import '../features/boutique/gift/gift_card_track_screen.dart';
import '../features/boutique/notifications/notifications_list_screen.dart';

/// Handler pour les messages en arriere-plan (doit etre une fonction top-level)
/// Quand l'app est fermee, Flutter cree un isolate separe - Firebase doit etre reinitialise
/// IMPORTANT: Doit etre enregistre via FirebaseMessaging.onBackgroundMessage()
/// AVANT Firebase.initializeApp() dans main() pour eviter "duplicate background isolate"
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  print('[BG] ════════════════════════════════════');
  print('[BG] Handler arriere-plan declenche !');
  print('[BG] messageId: ${message.messageId}');
  print('[BG] notification null? ${message.notification == null}');
  print('[BG] notification title: ${message.notification?.title}');
  print('[BG] notification body: ${message.notification?.body}');
  print('[BG] data: ${message.data}');
  print('[BG] ════════════════════════════════════');

  try {
    if (Firebase.apps.isEmpty) {
      await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
    }
    print('[BG] Firebase initialise');
  } catch (e) {
    print('[BG] Firebase deja initialise ou erreur: $e');
  }

  // Construire titre et body (depuis notification OU data)
  final notif = message.notification;
  final data  = message.data;

  final String title = notif?.title ?? data['title'] ?? _buildTitleFromData(data);
  final String body  = notif?.body  ?? data['body']  ?? data['message'] ?? _buildBodyFromData(data);

  print('[BG] titre construit: "$title"');
  print('[BG] body construit: "$body"');

  if (body.isEmpty && title == 'Tika') {
    print('[BG] Aucun contenu utile, notification ignoree');
    return;
  }

  try {
    final localNotifications = FlutterLocalNotificationsPlugin();
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    final initialized = await localNotifications.initialize(
      const InitializationSettings(android: androidSettings),
    );
    print('[BG] FlutterLocalNotifications initialise: $initialized');

    await localNotifications
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(const AndroidNotificationChannel(
          'tika_notifications',
          'Notifications Tika',
          description: 'Notifications de commandes, promotions et fidelite',
          importance: Importance.high,
        ));
    print('[BG] Canal Android cree');

    final notifId = message.messageId?.hashCode
        ?? DateTime.now().millisecondsSinceEpoch.remainder(100000);

    await localNotifications.show(
      notifId,
      title,
      body,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'tika_notifications',
          'Notifications Tika',
          channelDescription: 'Notifications de commandes, promotions et fidelite',
          importance: Importance.high,
          priority: Priority.high,
          icon: '@mipmap/ic_launcher',
        ),
      ),
    );
    print('[BG] Notification affichee avec id: $notifId');
  } catch (e, stack) {
    print('[BG] ERREUR affichage notification: $e');
    print('[BG] Stack: $stack');
  }
}

/// Construit le titre depuis les champs data du backend Tika
/// Payload: { type, order_id, order_number, status, click_action }
String _buildTitleFromData(Map<String, dynamic> data) {
  final type        = data['type']         ?? '';
  final status      = data['status']       ?? '';
  final clickAction = data['click_action'] ?? '';

  if (type == 'order_status') {
    switch (status) {
      case 'en_traitement': return 'Commande en préparation';
      case 'prete':         return 'Commande prête 🎉';
      case 'livree':        return 'Commande livrée ✅';
      case 'annulee':       return 'Commande annulée';
      default:              return 'Mise à jour de commande';
    }
  }
  if (type == 'loyalty')  return 'Points de fidélité ⭐';
  if (type == 'promo')    return 'Nouvelle promotion 🎁';
  if (type == 'payment')  return 'Paiement confirmé 💳';

  // Cartes cadeau
  if (clickAction == 'OPEN_GIFT_CARD' || type == 'gift_card') {
    return 'Carte d\'achat activée 🎁';
  }

  // Commandes cadeaux — titre selon statut
  if (clickAction == 'OPEN_GIFT_TRACKING' || clickAction == 'OPEN_GIFT_ORDER' || type == 'gift_order') {
    switch (status) {
      case 'paid':             return 'Cadeau pour vous ! 🎁';
      case 'preparing':        return 'Cadeau en préparation 🍳';
      case 'ready':            return 'Cadeau prêt ! 🎉';
      case 'delivery_pending': return 'Commandez Yango 🚕';
      case 'delivering':       return 'Livraison en cours 🛵';
      case 'delivered':        return 'Cadeau livré ! ✅';
      case 'cancelled':        return 'Cadeau annulé ❌';
      default:                 return 'Mise à jour cadeau 🎁';
    }
  }

  return 'Tika';
}

/// Construit le body depuis les champs data du backend Tika
String _buildBodyFromData(Map<String, dynamic> data) {
  final type        = data['type']         ?? '';
  final status      = data['status']       ?? '';
  final orderNumber = data['order_number'] ?? '';
  final clickAction = data['click_action'] ?? '';

  if (type == 'order_status' && orderNumber.isNotEmpty) {
    switch (status) {
      case 'en_traitement': return 'Votre commande $orderNumber est en préparation.';
      case 'prete':         return 'Votre commande $orderNumber est prête à être retirée.';
      case 'livree':        return 'Votre commande $orderNumber a été livrée.';
      case 'annulee':       return 'Votre commande $orderNumber a été annulée.';
      default:              return 'Votre commande $orderNumber a été mise à jour.';
    }
  }

  // Carte cadeau — code + montant + boutique + expéditeur
  if (clickAction == 'OPEN_GIFT_CARD' || type == 'gift_card') {
    final code       = data['code']        ?? '';
    final amount     = data['amount']      ?? '';
    final shopName   = data['shop_name']   ?? '';
    final senderName = data['sender_name'] ?? '';
    // "{sender} vous offre une carte d'achat de {amount} FCFA chez {shop}! Code: {code}"
    if (senderName.isNotEmpty && amount.isNotEmpty && shopName.isNotEmpty && code.isNotEmpty) {
      return '$senderName vous offre une carte d\'achat de $amount FCFA chez $shopName ! Code : $code';
    }
    if (code.isNotEmpty && amount.isNotEmpty) {
      return 'Carte d\'achat de $amount FCFA activée ! Code : $code';
    }
    if (code.isNotEmpty) return 'Votre carte cadeau est activée ! Code : $code';
    return 'Votre carte cadeau a été activée.';
  }

  // Commande cadeau — body selon statut
  if (clickAction == 'OPEN_GIFT_TRACKING' || clickAction == 'OPEN_GIFT_ORDER' || type == 'gift_order') {
    final senderName    = data['sender_name']    ?? '';
    final recipientName = data['recipient_name'] ?? '';
    final shopName      = data['shop_name']      ?? '';
    final trackingToken = data['tracking_token'] ?? '';
    final reason        = data['reason']         ?? '';

    switch (status) {
      case 'paid':
        // Bénéficiaire : "{recipient}, {sender} vous a offert un cadeau chez {shop}!"
        if (senderName.isNotEmpty && shopName.isNotEmpty) {
          final prefix = recipientName.isNotEmpty ? '$recipientName, ' : '';
          return '${prefix}$senderName vous a offert un cadeau chez $shopName !';
        }
        return 'Vous avez reçu un cadeau !';
      case 'preparing':
        // Acheteur : "Cadeau en préparation"
        if (recipientName.isNotEmpty && shopName.isNotEmpty) {
          return 'Le cadeau pour $recipientName est en préparation chez $shopName.';
        }
        return 'Votre cadeau est en préparation.';
      case 'ready':
        // Acheteur (Yango) ou Bénéficiaire (perso)
        if (recipientName.isNotEmpty && shopName.isNotEmpty) {
          return 'Le cadeau pour $recipientName est prêt chez $shopName ! Commandez Yango pour la livraison.';
        }
        if (senderName.isNotEmpty && shopName.isNotEmpty) {
          return 'Le cadeau de $senderName chez $shopName est prêt ! Un livreur vous contactera.';
        }
        return 'Votre cadeau est prêt !';
      case 'delivery_pending':
        if (recipientName.isNotEmpty && shopName.isNotEmpty) {
          return 'Le cadeau pour $recipientName est prêt chez $shopName. Veuillez commander un Yango.';
        }
        return 'Le cadeau est prêt. Veuillez commander un Yango.';
      case 'delivering':
        // Bénéficiaire : "Livraison en cours"
        if (shopName.isNotEmpty) {
          return 'Votre cadeau de $shopName est en route !';
        }
        return 'Votre cadeau est en cours de livraison.';
      case 'delivered':
        // Acheteur ou Bénéficiaire
        if (recipientName.isNotEmpty) {
          return 'Votre cadeau pour $recipientName a été livré avec succès !';
        }
        if (senderName.isNotEmpty) {
          return 'Le cadeau de $senderName vous a été livré !';
        }
        return 'Le cadeau a été livré !';
      case 'cancelled':
        if (recipientName.isNotEmpty && shopName.isNotEmpty) {
          final msg = 'Le cadeau pour $recipientName chez $shopName a été annulé.';
          return reason.isNotEmpty ? '$msg Raison : $reason' : msg;
        }
        if (senderName.isNotEmpty && shopName.isNotEmpty) {
          return 'Le cadeau de $senderName chez $shopName a été annulé.';
        }
        return 'Le cadeau a été annulé.';
      default:
        if (senderName.isNotEmpty && shopName.isNotEmpty) {
          return '$senderName vous a envoyé un cadeau chez $shopName ! Réf : $trackingToken';
        }
        return 'Vous avez reçu un cadeau !';
    }
  }

  // Paiement
  if (type == 'payment') {
    final status      = data['status']       ?? '';
    final orderNumber = data['order_number'] ?? '';
    if (status == 'failed') {
      return orderNumber.isNotEmpty
          ? 'Le paiement pour la commande $orderNumber a échoué.'
          : 'Votre paiement a échoué.';
    }
    return orderNumber.isNotEmpty
        ? 'Paiement de la commande $orderNumber confirmé.'
        : 'Votre paiement a été traité.';
  }

  // Fidélité
  if (type == 'loyalty') {
    final points = data['points'] ?? '';
    return points.isNotEmpty
        ? 'Vous avez gagné $points points de fidélité !'
        : 'Vous avez reçu des points de fidélité.';
  }

  return '';
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

  /// NavigatorKey global — permet de naviguer sans BuildContext (notifications)
  static final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

  static String? _fcmToken;

  /// IDs des notifications déjà vues — évite de re-notifier au prochain poll
  static final Set<int> _seenNotificationIds = {};
  static bool _firstPoll = true;

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
    // NOTE: firebaseMessagingBackgroundHandler est enregistre dans main() avant Firebase.initializeApp()
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

    // 7. Verifier si l'app a ete ouverte via une notification (app etait fermee)
    // Delai necessaire pour que le navigator soit pret avant de naviguer
    final initialMessage = await _messaging.getInitialMessage();
    if (initialMessage != null) {
      Future.delayed(const Duration(milliseconds: 600), () {
        _handleNotificationTap(initialMessage);
      });
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

    // 1. Toujours obtenir un token frais (les tokens FCM peuvent changer)
    print('[Push] Récupération d\'un token FCM frais...');
    await _refreshToken();

    if (_fcmToken == null) {
      print('[Push] ❌ ÉCHEC: Pas de token FCM disponible');
      return;
    }
    print('[Push] ✅ Token FCM COMPLET: $_fcmToken');

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
    _firstPoll = true;
    // Rafraichir immediatement
    refreshUnreadCount();
    _checkRecentNotifications(); // mémorise les IDs existants sans notifier
    // Puis toutes les 30 secondes
    _pollingTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      refreshUnreadCount();
      _checkRecentNotifications();
    });
    print('[Push] Polling demarre (intervalle: 30s)');
  }

  /// Arreter le polling periodique
  static void stopPolling() {
    _pollingTimer?.cancel();
    _pollingTimer = null;
  }

  /// Vérifie les notifications récentes et affiche une notif locale pour chaque nouvelle
  static Future<void> _checkRecentNotifications() async {
    try {
      final recent = await NotificationService.getRecentNotifications(limit: 10);

      if (_firstPoll) {
        // Premier appel : mémoriser les IDs sans notifier (évite de re-notifier l'historique)
        for (final n in recent) {
          _seenNotificationIds.add(n.id);
        }
        _firstPoll = false;
        return;
      }

      for (final n in recent) {
        if (!_seenNotificationIds.contains(n.id)) {
          _seenNotificationIds.add(n.id);
          _showLocalNotificationFromItem(n);
        }
      }
    } catch (e) {
      print('[Push] Erreur checkRecentNotifications: $e');
    }
  }

  /// Affiche une notification locale à partir d'un NotificationItem de l'API
  static void _showLocalNotificationFromItem(NotificationItem n) {
    if (!_localNotificationsInitialized || _localNotifications == null) return;

    _localNotifications!.show(
      n.id.remainder(100000),
      n.title,
      n.message,
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
    );
  }

  /// Gerer un message recu au premier plan
  static void _handleForegroundMessage(RemoteMessage message) {
    print('[Push] ════ MESSAGE RECU (foreground) ════');
    print('[Push] messageId: ${message.messageId}');
    print('[Push] notification null? ${message.notification == null}');
    print('[Push] notification.title: ${message.notification?.title}');
    print('[Push] notification.body:  ${message.notification?.body}');
    print('[Push] data: ${message.data}');
    print('[Push] ════════════════════════════════════');

    // Rafraichir le badge quand un push arrive
    refreshUnreadCount();

    // Extraire titre et body depuis notification OU data OU construction depuis data
    final notification = message.notification;
    final String title = notification?.title
        ?? message.data['title']
        ?? _buildTitleFromData(message.data);
    final String body = notification?.body
        ?? message.data['body']
        ?? message.data['message']
        ?? _buildBodyFromData(message.data);

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
        payload: jsonEncode({
          'click_action': message.data['click_action'],
          'tracking_token': message.data['tracking_token'],
        }),
      );
    }
  }

  /// Gerer le clic sur une notification (app en arriere-plan ou fermee)
  static void _handleNotificationTap(RemoteMessage message) {
    print('[Push] Notification cliquee: ${message.data}');
    _navigateFromData(message.data);
  }

  /// Gerer le clic sur une notification locale (app au premier plan)
  static void _onNotificationTapped(NotificationResponse response) {
    print('[Push] Notification locale cliquee: ${response.payload}');
    if (response.payload == null) return;
    try {
      final data = jsonDecode(response.payload!) as Map<String, dynamic>;
      _navigateFromData(data);
    } catch (_) {}
  }

  /// Naviguer vers la bonne page selon le click_action FCM
  ///
  /// OPEN_GIFT_TRACKING → suivi commande cadeau (GFT-XXXXXX)
  /// OPEN_GIFT_ORDER    → meme ecran (token tracking_token)
  /// OPEN_GIFT_CARD     → suivi carte cadeau (GCA-XXXXXX via tracking_token)
  /// Tout autre cas     → liste des notifications
  static void _navigateFromData(Map<String, dynamic> data) {
    final clickAction = data['click_action'] as String?;
    final context = navigatorKey.currentContext;
    if (context == null) return;

    print('[Push] Navigation -> click_action: $clickAction');

    switch (clickAction) {
      case 'OPEN_GIFT_TRACKING':
        final token = data['tracking_token'] as String?;
        if (token != null) {
          GiftOrderTrackScreen.show(context, token: token);
        } else {
          Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const NotificationsListScreen()),
          );
        }
        break;
      case 'OPEN_GIFT_ORDER':
        // Notification vendeur : pas de tracking_token dans le payload API
        Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const NotificationsListScreen()),
        );
        break;
      case 'OPEN_GIFT_CARD':
        final token = data['tracking_token'] as String?;
        if (token != null) {
          GiftCardTrackScreen.show(context, token: token);
        } else {
          // Payload API ne contient pas tracking_token pour les cartes cadeau
          Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const NotificationsListScreen()),
          );
        }
        break;
      default:
        Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const NotificationsListScreen()),
        );
        break;
    }
  }
}
