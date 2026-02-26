import 'dart:convert';
import 'dart:math';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'dart:io';

/// Service de stockage local - Conforme à l'API TIKA
/// Les clients N'ONT PAS de compte, tout est stocké localement
class StorageService {
  static const String _loyaltyCardKey = 'loyalty_card';
  static const String _ordersKey = 'orders';
  static const String _favoritesKey = 'favorites';

  // Nouvelles clés selon l'API TIKA
  static const String _deviceFingerprintKey = 'device_fingerprint';
  static const String _customerNameKey = 'customer_name';
  static const String _customerPhoneKey = 'customer_phone';
  static const String _customerEmailKey = 'customer_email';
  static const String _customerAddressesKey = 'customer_addresses';
  static const String _notificationsKey = 'notifications';
  static const String _notificationSettingsKey = 'notification_settings';
  static const String _pendingWaveOrdersKey = 'pending_wave_orders';

  // Cle pour l'onboarding
  static const String _onboardingSeenKey = 'onboarding_seen';

  // Clés pour l'authentification client
  static const String _authTokenKey = 'auth_token';
  static const String _authClientKey = 'auth_client';

  // Stockage en mémoire comme fallback
  static Map<String, dynamic>? _memoryLoyaltyCard;
  static List<Map<String, dynamic>> _memoryOrders = [];
  static List<int> _memoryFavorites = [];
  static String? _memoryDeviceFingerprint;
  static String? _memoryCustomerName;
  static String? _memoryCustomerPhone;
  static String? _memoryCustomerEmail;
  static List<Map<String, dynamic>> _memoryCustomerAddresses = [];
  static List<Map<String, dynamic>> _memoryNotifications = [];
  static Map<String, dynamic>? _memoryNotificationSettings;
  static String? _memoryAuthToken;
  static Map<String, dynamic>? _memoryAuthClient;

  // Onboarding vu
  static Future<void> setOnboardingSeen() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_onboardingSeenKey, true);
    } catch (e) {
      // ignore
    }
  }

  static Future<bool> hasSeenOnboarding() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getBool(_onboardingSeenKey) ?? false;
    } catch (e) {
      return false;
    }
  }

  // Sauvegarder la carte de fidélité
  static Future<void> saveLoyaltyCard(Map<String, dynamic> cardData) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_loyaltyCardKey, jsonEncode(cardData));
    } catch (e) {
      // Fallback en mémoire
      _memoryLoyaltyCard = cardData;
    }
  }

  // Récupérer la carte de fidélité
  static Future<Map<String, dynamic>?> getLoyaltyCard() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String? cardJson = prefs.getString(_loyaltyCardKey);

      if (cardJson == null) return _memoryLoyaltyCard;

      return jsonDecode(cardJson) as Map<String, dynamic>;
    } catch (e) {
      // Fallback en mémoire
      return _memoryLoyaltyCard;
    }
  }

  // Vérifier si une carte existe
  static Future<bool> hasLoyaltyCard() async {
    final card = await getLoyaltyCard();
    return card != null;
  }

  // Supprimer la carte de fidélité
  static Future<void> deleteLoyaltyCard() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_loyaltyCardKey);
    } catch (e) {
      // Fallback en mémoire
      _memoryLoyaltyCard = null;
    }
  }

  // Sauvegarder une commande
  static Future<void> saveOrder(Map<String, dynamic> orderData) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final orders = await getOrders();

      // Convertir DateTime en String pour le stockage
      final orderToSave = Map<String, dynamic>.from(orderData);
      if (orderToSave['orderDate'] is DateTime) {
        orderToSave['orderDate'] = (orderToSave['orderDate'] as DateTime).toIso8601String();
      }

      orders.add(orderToSave);
      await prefs.setString(_ordersKey, jsonEncode(orders));
    } catch (e) {
      // Fallback en mémoire
      final orderToSave = Map<String, dynamic>.from(orderData);
      _memoryOrders.add(orderToSave);
    }
  }

  // Récupérer toutes les commandes
  static Future<List<Map<String, dynamic>>> getOrders() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String? ordersJson = prefs.getString(_ordersKey);

      if (ordersJson == null) return List.from(_memoryOrders);

      final List<dynamic> ordersList = jsonDecode(ordersJson);

      // Convertir les dates String en DateTime
      return ordersList.map((order) {
        final orderMap = Map<String, dynamic>.from(order);
        if (orderMap['orderDate'] is String) {
          orderMap['orderDate'] = DateTime.parse(orderMap['orderDate']);
        }
        return orderMap;
      }).toList();
    } catch (e) {
      // Fallback en mémoire
      return List.from(_memoryOrders);
    }
  }

  // Supprimer toutes les commandes
  static Future<void> clearOrders() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_ordersKey);
    } catch (e) {
      // Fallback en mémoire
      _memoryOrders.clear();
    }
  }

  // === GESTION DES FAVORIS ===

  // Récupérer la liste des IDs de boutiques favorites
  static Future<List<int>> getFavoriteShopIds() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final List<String>? favorites = prefs.getStringList(_favoritesKey);

      if (favorites == null) return List.from(_memoryFavorites);

      return favorites.map((id) => int.parse(id)).toList();
    } catch (e) {
      // Fallback en mémoire
      return List.from(_memoryFavorites);
    }
  }

  // Ajouter une boutique aux favoris
  static Future<void> addFavorite(int shopId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final favorites = await getFavoriteShopIds();

      if (!favorites.contains(shopId)) {
        favorites.add(shopId);
        await prefs.setStringList(
          _favoritesKey,
          favorites.map((id) => id.toString()).toList(),
        );
      }
    } catch (e) {
      // Fallback en mémoire
      if (!_memoryFavorites.contains(shopId)) {
        _memoryFavorites.add(shopId);
      }
    }
  }

  // Retirer une boutique des favoris
  static Future<void> removeFavorite(int shopId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final favorites = await getFavoriteShopIds();

      favorites.remove(shopId);
      await prefs.setStringList(
        _favoritesKey,
        favorites.map((id) => id.toString()).toList(),
      );
    } catch (e) {
      // Fallback en mémoire
      _memoryFavorites.remove(shopId);
    }
  }

  // Vérifier si une boutique est en favori
  static Future<bool> isFavorite(int shopId) async {
    final favorites = await getFavoriteShopIds();
    return favorites.contains(shopId);
  }

  // Toggle favori (ajouter ou retirer)
  static Future<void> toggleFavorite(int shopId) async {
    final isFav = await isFavorite(shopId);
    if (isFav) {
      await removeFavorite(shopId);
    } else {
      await addFavorite(shopId);
    }
  }

  // Supprimer tous les favoris
  static Future<void> clearFavorites() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_favoritesKey);
    } catch (e) {
      // Fallback en mémoire
      _memoryFavorites.clear();
    }
  }

  // === DEVICE FINGERPRINT (Selon API TIKA) ===

  /// Génère un device_fingerprint unique basé sur les infos de l'appareil
  /// Utilisé par l'API pour identifier les commandes d'un appareil
  static Future<String> _generateDeviceFingerprint() async {
    try {
      final deviceInfo = DeviceInfoPlugin();
      String fingerprint;

      if (Platform.isAndroid) {
        final androidInfo = await deviceInfo.androidInfo;
        fingerprint = 'android_${androidInfo.id}_${androidInfo.model}_${androidInfo.device}';
      } else if (Platform.isIOS) {
        final iosInfo = await deviceInfo.iosInfo;
        fingerprint = 'ios_${iosInfo.identifierForVendor}_${iosInfo.model}';
      } else {
        // Fallback pour autres plateformes
        fingerprint = 'device_${Random().nextInt(999999999)}';
      }

      return fingerprint.replaceAll(' ', '_').toLowerCase();
    } catch (e) {
      // Si erreur, générer un ID aléatoire unique
      return 'device_${DateTime.now().millisecondsSinceEpoch}_${Random().nextInt(999999)}';
    }
  }

  /// Récupère ou génère le device_fingerprint
  /// Ce fingerprint est utilisé par l'API TIKA pour retrouver les commandes
  static Future<String> getDeviceFingerprint() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      String? fingerprint = prefs.getString(_deviceFingerprintKey);

      if (fingerprint == null || fingerprint.isEmpty) {
        // Générer un nouveau fingerprint
        fingerprint = await _generateDeviceFingerprint();
        await prefs.setString(_deviceFingerprintKey, fingerprint);
        _memoryDeviceFingerprint = fingerprint;
      }

      return fingerprint;
    } catch (e) {
      // Fallback en mémoire
      _memoryDeviceFingerprint ??= await _generateDeviceFingerprint();
      return _memoryDeviceFingerprint!;
    }
  }

  /// Réinitialiser le device fingerprint (générer un nouveau)
  /// Utile pour débugger ou réinitialiser l'appareil
  static Future<String> resetDeviceFingerprint() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // Générer un nouveau fingerprint avec timestamp pour garantir l'unicité
      final baseFingerprint = await _generateDeviceFingerprint();
      final uniqueFingerprint = '${baseFingerprint}_${DateTime.now().millisecondsSinceEpoch}';

      // Sauvegarder le nouveau fingerprint
      await prefs.setString(_deviceFingerprintKey, uniqueFingerprint);
      _memoryDeviceFingerprint = uniqueFingerprint;

      print('🔄 Device fingerprint réinitialisé');
      print('   Ancien: ${await prefs.getString(_deviceFingerprintKey)}');
      print('   Nouveau: $uniqueFingerprint');

      return uniqueFingerprint;
    } catch (e) {
      // Fallback en mémoire
      final newFingerprint = 'device_${DateTime.now().millisecondsSinceEpoch}_${Random().nextInt(999999)}';
      _memoryDeviceFingerprint = newFingerprint;
      return newFingerprint;
    }
  }

  // === INFORMATIONS CLIENT (Stockées localement, pas d'authentification) ===

  /// Sauvegarder le nom du client
  static Future<void> saveCustomerName(String name) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_customerNameKey, name);
    } catch (e) {
      _memoryCustomerName = name;
    }
  }

  /// Récupérer le nom du client
  static Future<String?> getCustomerName() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(_customerNameKey) ?? _memoryCustomerName;
    } catch (e) {
      return _memoryCustomerName;
    }
  }

  /// Sauvegarder le téléphone du client (identifiant principal)
  static Future<void> saveCustomerPhone(String phone) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_customerPhoneKey, phone);
    } catch (e) {
      _memoryCustomerPhone = phone;
    }
  }

  /// Récupérer le téléphone du client
  static Future<String?> getCustomerPhone() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(_customerPhoneKey) ?? _memoryCustomerPhone;
    } catch (e) {
      return _memoryCustomerPhone;
    }
  }

  /// Sauvegarder l'email du client (optionnel)
  static Future<void> saveCustomerEmail(String email) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_customerEmailKey, email);
    } catch (e) {
      _memoryCustomerEmail = email;
    }
  }

  /// Récupérer l'email du client
  static Future<String?> getCustomerEmail() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(_customerEmailKey) ?? _memoryCustomerEmail;
    } catch (e) {
      return _memoryCustomerEmail;
    }
  }

  /// Sauvegarder toutes les infos client en une fois
  static Future<void> saveCustomerInfo({
    required String name,
    required String phone,
    String? email,
  }) async {
    await saveCustomerName(name);
    await saveCustomerPhone(phone);
    if (email != null && email.isNotEmpty) {
      await saveCustomerEmail(email);
    }
  }

  /// Sauvegarder le dernier shopId visité
  static Future<void> saveLastShopId(int shopId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt('last_shop_id', shopId);
      print('💾 [Storage] Last shopId sauvegardé: $shopId');
    } catch (e) {
      print('❌ [Storage] Erreur saveLastShopId: $e');
    }
  }

  /// Récupérer le dernier shopId visité
  static Future<int?> getLastShopId() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final shopId = prefs.getInt('last_shop_id');
      print('📖 [Storage] Last shopId récupéré: $shopId');
      return shopId;
    } catch (e) {
      print('❌ [Storage] Erreur getLastShopId: $e');
      return null;
    }
  }

  /// Récupérer toutes les infos client
  static Future<Map<String, dynamic>> getCustomerInfo() async {
    return {
      'name': await getCustomerName(),
      'phone': await getCustomerPhone(),
      'email': await getCustomerEmail(),
      'lastShopId': await getLastShopId(),
    };
  }

  /// Vérifier si le client a déjà saisi ses informations
  static Future<bool> hasCustomerInfo() async {
    final phone = await getCustomerPhone();
    final name = await getCustomerName();
    return phone != null && phone.isNotEmpty && name != null && name.isNotEmpty;
  }

  // === ADRESSES DE LIVRAISON ===

  /// Sauvegarder les adresses de livraison
  static Future<void> saveCustomerAddresses(List<Map<String, dynamic>> addresses) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_customerAddressesKey, jsonEncode(addresses));
    } catch (e) {
      _memoryCustomerAddresses = addresses;
    }
  }

  /// Récupérer les adresses de livraison
  static Future<List<Map<String, dynamic>>> getCustomerAddresses() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String? addressesJson = prefs.getString(_customerAddressesKey);

      if (addressesJson == null) return List.from(_memoryCustomerAddresses);

      final List<dynamic> addressesList = jsonDecode(addressesJson);
      return addressesList.map((addr) => Map<String, dynamic>.from(addr)).toList();
    } catch (e) {
      return List.from(_memoryCustomerAddresses);
    }
  }

  /// Ajouter une nouvelle adresse
  static Future<void> addCustomerAddress(Map<String, dynamic> address) async {
    final addresses = await getCustomerAddresses();
    addresses.add(address);
    await saveCustomerAddresses(addresses);
  }

  /// Supprimer une adresse par index
  static Future<void> removeCustomerAddress(int index) async {
    final addresses = await getCustomerAddresses();
    if (index >= 0 && index < addresses.length) {
      addresses.removeAt(index);
      await saveCustomerAddresses(addresses);
    }
  }

  /// Mettre à jour une adresse
  static Future<void> updateCustomerAddress(int index, Map<String, dynamic> address) async {
    final addresses = await getCustomerAddresses();
    if (index >= 0 && index < addresses.length) {
      addresses[index] = address;
      await saveCustomerAddresses(addresses);
    }
  }

  // === MOYEN DE PAIEMENT PAR DEFAUT ===

  static const String _defaultPaymentMethodKey = 'default_payment_method';

  /// Sauvegarder le moyen de paiement par defaut (ex: "especes", "wave")
  static Future<void> saveDefaultPaymentMethod(String type) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_defaultPaymentMethodKey, type);
    } catch (e) {
      // ignore
    }
  }

  /// Recuperer le moyen de paiement par defaut
  static Future<String?> getDefaultPaymentMethod() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(_defaultPaymentMethodKey);
    } catch (e) {
      return null;
    }
  }

  // === NETTOYAGE ===

  /// Effacer toutes les données client (réinitialisation)
  static Future<void> clearAllCustomerData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_customerNameKey);
      await prefs.remove(_customerPhoneKey);
      await prefs.remove(_customerEmailKey);
      await prefs.remove(_customerAddressesKey);
      await prefs.remove(_loyaltyCardKey);
      await prefs.remove(_ordersKey);
      await prefs.remove(_favoritesKey);
      await prefs.remove(_notificationsKey);
      // Note: On ne supprime PAS le device_fingerprint et les settings de notifications
    } catch (e) {
      _memoryCustomerName = null;
      _memoryCustomerPhone = null;
      _memoryCustomerEmail = null;
      _memoryCustomerAddresses.clear();
      _memoryLoyaltyCard = null;
      _memoryOrders.clear();
      _memoryFavorites.clear();
      _memoryNotifications.clear();
    }
  }

  // === NOTIFICATIONS (Stockage local pour clients) ===

  /// Sauvegarder toutes les notifications
  static Future<void> saveNotifications(List<Map<String, dynamic>> notifications) async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // Convertir DateTime en String pour le stockage
      final notificationsToSave = notifications.map((notif) {
        final n = Map<String, dynamic>.from(notif);
        if (n['createdAt'] is DateTime) {
          n['createdAt'] = (n['createdAt'] as DateTime).toIso8601String();
        }
        return n;
      }).toList();

      await prefs.setString(_notificationsKey, jsonEncode(notificationsToSave));
    } catch (e) {
      _memoryNotifications = notifications;
    }
  }

  /// Récupérer toutes les notifications
  static Future<List<Map<String, dynamic>>> getNotifications() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String? notificationsJson = prefs.getString(_notificationsKey);

      if (notificationsJson == null) return List.from(_memoryNotifications);

      final List<dynamic> notificationsList = jsonDecode(notificationsJson);

      // Convertir les dates String en DateTime
      return notificationsList.map((notif) {
        final notifMap = Map<String, dynamic>.from(notif);
        if (notifMap['createdAt'] is String) {
          notifMap['createdAt'] = DateTime.parse(notifMap['createdAt']);
        }
        return notifMap;
      }).toList();
    } catch (e) {
      return List.from(_memoryNotifications);
    }
  }

  /// Ajouter une nouvelle notification
  static Future<void> addNotification(Map<String, dynamic> notification) async {
    final notifications = await getNotifications();

    // Ajouter au début de la liste (plus récent en premier)
    notifications.insert(0, {
      ...notification,
      'id': DateTime.now().millisecondsSinceEpoch.toString(),
      'createdAt': notification['createdAt'] ?? DateTime.now(),
      'isRead': notification['isRead'] ?? false,
    });

    // Limiter à 100 notifications maximum
    if (notifications.length > 100) {
      notifications.removeRange(100, notifications.length);
    }

    await saveNotifications(notifications);
  }

  /// Marquer une notification comme lue
  static Future<void> markNotificationAsRead(String id) async {
    final notifications = await getNotifications();
    final index = notifications.indexWhere((n) => n['id'] == id);

    if (index >= 0) {
      notifications[index]['isRead'] = true;
      await saveNotifications(notifications);
    }
  }

  /// Marquer toutes les notifications comme lues
  static Future<void> markAllNotificationsAsRead() async {
    final notifications = await getNotifications();

    for (var notif in notifications) {
      notif['isRead'] = true;
    }

    await saveNotifications(notifications);
  }

  /// Supprimer une notification
  static Future<void> deleteNotification(String id) async {
    final notifications = await getNotifications();
    notifications.removeWhere((n) => n['id'] == id);
    await saveNotifications(notifications);
  }

  /// Supprimer toutes les notifications
  static Future<void> clearAllNotifications() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_notificationsKey);
    } catch (e) {
      _memoryNotifications.clear();
    }
  }

  /// Compter les notifications non lues
  static Future<int> getUnreadNotificationsCount() async {
    final notifications = await getNotifications();
    return notifications.where((n) => n['isRead'] == false).length;
  }

  /// Récupérer les notifications récentes (7 derniers jours)
  static Future<List<Map<String, dynamic>>> getRecentNotifications() async {
    final notifications = await getNotifications();
    final sevenDaysAgo = DateTime.now().subtract(const Duration(days: 7));

    return notifications.where((n) {
      final createdAt = n['createdAt'] as DateTime;
      return createdAt.isAfter(sevenDaysAgo);
    }).toList();
  }

  // === PARAMÈTRES DE NOTIFICATIONS ===

  /// Paramètres par défaut
  static Map<String, dynamic> _getDefaultNotificationSettings() {
    return {
      'orders': true,
      'promotions': true,
      'news': false,
      'loyalty': true,
      'push': true,
      'email': false,
      'sms': false,
    };
  }

  /// Sauvegarder les paramètres de notifications
  static Future<void> saveNotificationSettings(Map<String, dynamic> settings) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_notificationSettingsKey, jsonEncode(settings));
    } catch (e) {
      _memoryNotificationSettings = settings;
    }
  }

  /// Récupérer les paramètres de notifications
  static Future<Map<String, dynamic>> getNotificationSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String? settingsJson = prefs.getString(_notificationSettingsKey);

      if (settingsJson == null) {
        return _memoryNotificationSettings ?? _getDefaultNotificationSettings();
      }

      return jsonDecode(settingsJson) as Map<String, dynamic>;
    } catch (e) {
      return _memoryNotificationSettings ?? _getDefaultNotificationSettings();
    }
  }

  /// Vérifier si un type de notification est activé
  static Future<bool> isNotificationTypeEnabled(String type) async {
    final settings = await getNotificationSettings();
    return settings[type] ?? false;
  }

  // === GÉNÉRATION AUTOMATIQUE DE NOTIFICATIONS ===

  /// Créer une notification pour une nouvelle commande
  static Future<void> notifyOrderCreated(String orderNumber, int totalAmount) async {
    if (!await isNotificationTypeEnabled('orders')) return;

    await addNotification({
      'type': 'order',
      'title': 'Commande confirmée',
      'message': 'Votre commande $orderNumber a été confirmée. Montant: ${totalAmount.toStringAsFixed(0)} FCFA',
      'icon': 'shopping_bag',
      'color': '#4CAF50',
      'data': {'orderNumber': orderNumber},
    });
  }

  /// Créer une notification pour des points de fidélité gagnés
  static Future<void> notifyLoyaltyPointsEarned(int points, String shopName) async {
    if (!await isNotificationTypeEnabled('loyalty')) return;

    await addNotification({
      'type': 'loyalty',
      'title': 'Points de fidélité gagnés',
      'message': 'Vous avez gagné $points points chez $shopName',
      'icon': 'stars',
      'color': '#8936A8',
      'data': {'points': points, 'shopName': shopName},
    });
  }

  /// Créer une notification pour une promotion
  static Future<void> notifyPromotion(String title, String message) async {
    if (!await isNotificationTypeEnabled('promotions')) return;

    await addNotification({
      'type': 'promotion',
      'title': title,
      'message': message,
      'icon': 'local_offer',
      'color': '#FF9800',
    });
  }

  /// Créer une notification pour une nouveauté
  static Future<void> notifyNews(String title, String message) async {
    if (!await isNotificationTypeEnabled('news')) return;

    await addNotification({
      'type': 'news',
      'title': title,
      'message': message,
      'icon': 'new_releases',
      'color': '#E91E63',
    });
  }

  // === COMMANDES WAVE EN ATTENTE ===

  /// Sauvegarder une commande Wave en attente (avant capture d'écran)
  static Future<void> savePendingWaveOrder(Map<String, dynamic> orderData) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final pendingOrders = await getPendingWaveOrders();

      pendingOrders[orderData['pending_order_id']] = orderData;
      await prefs.setString(_pendingWaveOrdersKey, jsonEncode(pendingOrders));

      print('💾 [Storage] Commande Wave en attente sauvegardée: ${orderData['pending_order_id']}');
    } catch (e) {
      print('❌ [Storage] Erreur savePendingWaveOrder: $e');
    }
  }

  /// Récupérer toutes les commandes Wave en attente
  static Future<Map<String, dynamic>> getPendingWaveOrders() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String? ordersJson = prefs.getString(_pendingWaveOrdersKey);

      if (ordersJson == null) return {};

      return Map<String, dynamic>.from(jsonDecode(ordersJson));
    } catch (e) {
      print('❌ [Storage] Erreur getPendingWaveOrders: $e');
      return {};
    }
  }

  /// Récupérer une commande Wave en attente par ID
  static Future<Map<String, dynamic>?> getPendingWaveOrder(String pendingOrderId) async {
    final pendingOrders = await getPendingWaveOrders();
    return pendingOrders[pendingOrderId] as Map<String, dynamic>?;
  }

  /// Supprimer une commande Wave en attente
  static Future<void> deletePendingWaveOrder(String pendingOrderId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final pendingOrders = await getPendingWaveOrders();

      pendingOrders.remove(pendingOrderId);
      await prefs.setString(_pendingWaveOrdersKey, jsonEncode(pendingOrders));

      print('🗑️ [Storage] Commande Wave en attente supprimée: $pendingOrderId');
    } catch (e) {
      print('❌ [Storage] Erreur deletePendingWaveOrder: $e');
    }
  }

  /// Nettoyer les commandes Wave expirées (plus de 24h)
  static Future<void> cleanExpiredPendingWaveOrders() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final pendingOrders = await getPendingWaveOrders();
      final now = DateTime.now();

      pendingOrders.removeWhere((key, value) {
        final createdAt = DateTime.tryParse(value['created_at'] ?? '');
        if (createdAt == null) return true;
        return now.difference(createdAt).inHours > 24;
      });

      await prefs.setString(_pendingWaveOrdersKey, jsonEncode(pendingOrders));
    } catch (e) {
      print('❌ [Storage] Erreur cleanExpiredPendingWaveOrders: $e');
    }
  }

  /// Créer une notification pour un paiement Wave en attente
  static Future<void> notifyWavePaymentPending(String orderNumber) async {
    if (!await isNotificationTypeEnabled('orders')) return;

    await addNotification({
      'type': 'wave_payment',
      'title': 'Paiement Wave en attente',
      'message': 'Votre preuve de paiement pour la commande $orderNumber est en cours de vérification',
      'icon': 'hourglass_empty',
      'color': '#1BA5E0',
      'data': {'orderNumber': orderNumber},
    });
  }

  /// Créer une notification pour un paiement Wave approuvé
  static Future<void> notifyWavePaymentApproved(String orderNumber) async {
    if (!await isNotificationTypeEnabled('orders')) return;

    await addNotification({
      'type': 'wave_payment',
      'title': 'Paiement Wave approuvé',
      'message': 'Votre paiement Wave pour la commande $orderNumber a été validé',
      'icon': 'check_circle',
      'color': '#4CAF50',
      'data': {'orderNumber': orderNumber},
    });
  }

  /// Créer une notification pour un paiement Wave rejeté
  static Future<void> notifyWavePaymentRejected(String orderNumber, String? reason) async {
    if (!await isNotificationTypeEnabled('orders')) return;

    await addNotification({
      'type': 'wave_payment',
      'title': 'Paiement Wave rejeté',
      'message': reason ?? 'Votre paiement Wave pour la commande $orderNumber a été rejeté',
      'icon': 'cancel',
      'color': '#F44336',
      'data': {'orderNumber': orderNumber},
    });
  }

  // === AUTHENTIFICATION CLIENT ===

  /// Sauvegarder le token d'authentification
  static Future<void> saveAuthToken(String token) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_authTokenKey, token);
      _memoryAuthToken = token;
      print('🔐 [Storage] Token d\'authentification sauvegardé');
    } catch (e) {
      _memoryAuthToken = token;
      print('❌ [Storage] Erreur saveAuthToken: $e');
    }
  }

  /// Récupérer le token d'authentification
  static Future<String?> getAuthToken() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString(_authTokenKey);
      return token ?? _memoryAuthToken;
    } catch (e) {
      print('❌ [Storage] Erreur getAuthToken: $e');
      return _memoryAuthToken;
    }
  }

  /// Supprimer le token d'authentification
  static Future<void> deleteAuthToken() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_authTokenKey);
      _memoryAuthToken = null;
      print('🔐 [Storage] Token d\'authentification supprimé');
    } catch (e) {
      _memoryAuthToken = null;
      print('❌ [Storage] Erreur deleteAuthToken: $e');
    }
  }

  /// Sauvegarder les informations du client authentifié
  static Future<void> saveAuthClient(Map<String, dynamic> clientData) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_authClientKey, jsonEncode(clientData));
      _memoryAuthClient = clientData;
      print('👤 [Storage] Client authentifié sauvegardé: ${clientData['name']}');
    } catch (e) {
      _memoryAuthClient = clientData;
      print('❌ [Storage] Erreur saveAuthClient: $e');
    }
  }

  /// Récupérer les informations du client authentifié
  static Future<Map<String, dynamic>?> getAuthClient() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final clientJson = prefs.getString(_authClientKey);

      if (clientJson == null) return _memoryAuthClient;

      return jsonDecode(clientJson) as Map<String, dynamic>;
    } catch (e) {
      print('❌ [Storage] Erreur getAuthClient: $e');
      return _memoryAuthClient;
    }
  }

  /// Supprimer les informations du client authentifié
  static Future<void> deleteAuthClient() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_authClientKey);
      _memoryAuthClient = null;
      print('👤 [Storage] Client authentifié supprimé');
    } catch (e) {
      _memoryAuthClient = null;
      print('❌ [Storage] Erreur deleteAuthClient: $e');
    }
  }

  /// Vérifier si un client est authentifié
  static Future<bool> isAuthenticated() async {
    final token = await getAuthToken();
    return token != null && token.isNotEmpty;
  }

  /// Effacer toutes les données d'authentification (déconnexion)
  static Future<void> clearAuthData() async {
    await deleteAuthToken();
    await deleteAuthClient();
    print('🚪 [Storage] Données d\'authentification effacées');
  }
}
