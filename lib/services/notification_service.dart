import 'package:http/http.dart' as http;
import 'dart:convert';
import './utils/api_endpoint.dart';
import './auth_service.dart';
import '../core/services/storage_service.dart';

/// Service de gestion des notifications client
///
/// IMPORTANT: Nécessite une authentification Bearer Token (via AuthService)
/// Si pas de token, utilise le stockage local comme fallback
///
/// Types de notifications:
/// - order: Commandes
/// - loyalty: Fidélité
/// - promo: Promotions
/// - system: Système
/// - delivery: Livraison
/// - payment: Paiement
class NotificationService {
  /// Compatibilité — ne fait plus rien, on utilise AuthService.authToken directement
  static void setAuthToken(String? token) {}

  /// Vérifier si l'utilisateur est authentifié (via AuthService)
  static bool get isAuthenticated => AuthService.isAuthenticated;

  /// Headers avec authentification Bearer (via AuthService)
  static Map<String, String> get _headers => {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
    if (AuthService.authToken != null) 'Authorization': 'Bearer ${AuthService.authToken}',
  };

  // ============================================================
  // LISTE DES NOTIFICATIONS
  // ============================================================

  /// Récupérer la liste des notifications
  ///
  /// [type] - Filtrer par type: order, loyalty, promo, system, delivery, payment
  /// [status] - Filtrer par statut: all, unread, read
  /// [perPage] - Nombre par page (1-50, défaut: 20)
  /// [page] - Numéro de page
  static Future<NotificationListResponse> getNotifications({
    String? type,
    String status = 'all',
    int perPage = 20,
    int page = 1,
  }) async {
    // Si pas authentifié, utiliser le stockage local
    if (!isAuthenticated) {
      
      return _getLocalNotifications(type: type, status: status);
    }

    print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    print('📤 GET NOTIFICATIONS');
    print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');

    try {
      final queryParams = <String, String>{
        'status': status,
        'per_page': perPage.toString(),
        'page': page.toString(),
      };
      if (type != null) queryParams['type'] = type;

      final uri = Uri.parse(Endpoints.notifications).replace(queryParameters: queryParams);

      final response = await http.get(uri, headers: _headers);

      print('📥 Response Status: ${response.statusCode}');
      print('📥 Response Body: ${response.body}');
      print('📥 URL: $uri');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        print('✅ Notifications récupérées');

        final responseData = data['data'];
        print('📋 Type responseData: ${responseData?.runtimeType}');
        print('📋 Clés responseData: ${responseData is Map ? (responseData as Map).keys.toList() : "N/A"}');

        if (responseData is Map<String, dynamic>) {
          // Format standard: { data: { notifications: [...], unread_count: N } }
          // OU format Laravel paginé: { data: { data: [...], current_page: N, ... } }
          if (responseData.containsKey('notifications')) {
            print('📋 Format détecté: data.notifications');
            print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
            return NotificationListResponse.fromJson(responseData);
          } else if (responseData.containsKey('data') && responseData['data'] is List) {
            // Format Laravel paginé: { data: { data: [...], current_page, total, ... } }
            print('📋 Format détecté: Laravel paginé (data.data)');
            final paginatedList = responseData['data'] as List;
            print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
            return NotificationListResponse(
              unreadCount: responseData['unread_count'] ?? 0,
              totalCount: responseData['total'] ?? paginatedList.length,
              notifications: paginatedList
                  .map((n) => NotificationItem.fromJson(n as Map<String, dynamic>))
                  .toList(),
              pagination: NotificationPagination(
                currentPage: responseData['current_page'] ?? 1,
                lastPage: responseData['last_page'] ?? 1,
                perPage: responseData['per_page'] ?? 20,
                total: responseData['total'] ?? paginatedList.length,
              ),
            );
          } else if (responseData.containsKey('items') && responseData['items'] is List) {
            print('📋 Format détecté: data.items');
            final itemsList = responseData['items'] as List;
            print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
            return NotificationListResponse(
              unreadCount: responseData['unread_count'] ?? 0,
              totalCount: responseData['total_count'] ?? itemsList.length,
              notifications: itemsList
                  .map((n) => NotificationItem.fromJson(n as Map<String, dynamic>))
                  .toList(),
            );
          } else {
            // Tenter le format standard malgré l'absence de 'notifications'
            print('📋 Format non reconnu, tentative standard. Clés: ${responseData.keys.toList()}');
            print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
            return NotificationListResponse.fromJson(responseData);
          }
        } else if (responseData is List) {
          // Format direct: { data: [ ... ] }
          print('📋 Format détecté: data = List directe (${responseData.length} items)');
          print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
          return NotificationListResponse(
            unreadCount: 0,
            totalCount: responseData.length,
            notifications: responseData
                .map((n) => NotificationItem.fromJson(n as Map<String, dynamic>))
                .toList(),
          );
        } else {
          print('⚠️ responseData est null ou type inattendu: ${responseData?.runtimeType}');
          print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
          return _getLocalNotifications(type: type, status: status);
        }
      } else if (response.statusCode == 401) {
        print('⚠️ Non authentifié - Utilisation du stockage local');
        return _getLocalNotifications(type: type, status: status);
      } else {
        throw Exception('Erreur ${response.statusCode}');
      }
    } catch (e) {
      print('❌ Erreur: $e - Utilisation du stockage local');
      return _getLocalNotifications(type: type, status: status);
    }
  }

  /// Fallback: Récupérer les notifications depuis le stockage local
  static Future<NotificationListResponse> _getLocalNotifications({
    String? type,
    String status = 'all',
  }) async {
    final localNotifications = await StorageService.getNotifications();

    var filtered = localNotifications;

    // Filtrer par type
    if (type != null) {
      filtered = filtered.where((n) => n['type'] == type).toList();
    }

    // Filtrer par statut
    if (status == 'unread') {
      filtered = filtered.where((n) => n['isRead'] != true).toList();
    } else if (status == 'read') {
      filtered = filtered.where((n) => n['isRead'] == true).toList();
    }

    final unreadCount = localNotifications.where((n) => n['isRead'] != true).length;

    return NotificationListResponse(
      unreadCount: unreadCount,
      totalCount: localNotifications.length,
      notifications: filtered.map((n) => NotificationItem.fromLocalJson(n)).toList(),
      isLocal: true,
    );
  }

  // ============================================================
  // NOMBRE DE NOTIFICATIONS NON LUES
  // ============================================================

  /// Récupérer le nombre de notifications non lues (pour badge)
  static Future<int> getUnreadCount() async {
    if (!isAuthenticated) {
      return await StorageService.getUnreadNotificationsCount();
    }

    try {
      final response = await http.get(
        Uri.parse(Endpoints.notificationsUnreadCount),
        headers: _headers,
      );

      print('📤 GET unread-count - Status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        // Supporter plusieurs formats de réponse
        final count = data['data']?['unread_count']
            ?? data['unread_count']
            ?? data['data']?['count']
            ?? data['count']
            ?? 0;
        print('📋 Unread count: $count');
        return count is int ? count : int.tryParse(count.toString()) ?? 0;
      }
    } catch (e) {
      print('❌ Erreur getUnreadCount: $e');
    }

    return await StorageService.getUnreadNotificationsCount();
  }

  // ============================================================
  // NOTIFICATIONS RÉCENTES
  // ============================================================

  /// Récupérer les notifications récentes (pour toast/popup)
  static Future<List<NotificationItem>> getRecentNotifications({int limit = 5}) async {
    if (!isAuthenticated) {
      final local = await StorageService.getRecentNotifications();
      return local.take(limit).map((n) => NotificationItem.fromLocalJson(n)).toList();
    }

    try {
      final response = await http.get(
        Uri.parse('${Endpoints.notificationsRecent}?limit=$limit'),
        headers: _headers,
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final notifications = data['data']['notifications'] as List? ?? [];
        return notifications.map((n) => NotificationItem.fromJson(n)).toList();
      }
    } catch (e) {
      print('❌ Erreur getRecentNotifications: $e');
    }

    final local = await StorageService.getRecentNotifications();
    return local.take(limit).map((n) => NotificationItem.fromLocalJson(n)).toList();
  }

  // ============================================================
  // MARQUER COMME LU
  // ============================================================

  /// Marquer une notification comme lue
  static Future<bool> markAsRead(int notificationId) async {
    if (!isAuthenticated) {
      await StorageService.markNotificationAsRead(notificationId.toString());
      return true;
    }

    try {
      final response = await http.post(
        Uri.parse(Endpoints.notificationMarkRead(notificationId)),
        headers: _headers,
      );

      if (response.statusCode == 200) {
        return true;
      }
    } catch (e) {
      print('❌ Erreur markAsRead: $e');
    }

    await StorageService.markNotificationAsRead(notificationId.toString());
    return true;
  }

  /// Marquer plusieurs notifications comme lues
  static Future<bool> markMultipleAsRead(List<int> notificationIds) async {
    if (!isAuthenticated) {
      for (var id in notificationIds) {
        await StorageService.markNotificationAsRead(id.toString());
      }
      return true;
    }

    try {
      final response = await http.post(
        Uri.parse(Endpoints.notificationsMarkMultipleRead),
        headers: _headers,
        body: jsonEncode({'notification_ids': notificationIds}),
      );

      if (response.statusCode == 200) {
        return true;
      }
    } catch (e) {
      print('❌ Erreur markMultipleAsRead: $e');
    }

    for (var id in notificationIds) {
      await StorageService.markNotificationAsRead(id.toString());
    }
    return true;
  }

  /// Marquer toutes les notifications comme lues
  static Future<bool> markAllAsRead() async {
    if (!isAuthenticated) {
      await StorageService.markAllNotificationsAsRead();
      return true;
    }

    try {
      final response = await http.post(
        Uri.parse(Endpoints.notificationsMarkAllRead),
        headers: _headers,
      );

      if (response.statusCode == 200) {
        return true;
      }
    } catch (e) {
      print('❌ Erreur markAllAsRead: $e');
    }

    await StorageService.markAllNotificationsAsRead();
    return true;
  }

  // ============================================================
  // SUPPRIMER
  // ============================================================

  /// Supprimer une notification
  static Future<bool> deleteNotification(int notificationId) async {
    if (!isAuthenticated) {
      await StorageService.deleteNotification(notificationId.toString());
      return true;
    }

    try {
      final response = await http.delete(
        Uri.parse(Endpoints.notificationDetails(notificationId)),
        headers: _headers,
      );

      if (response.statusCode == 200) {
        return true;
      }
    } catch (e) {
      print('❌ Erreur deleteNotification: $e');
    }

    await StorageService.deleteNotification(notificationId.toString());
    return true;
  }

  /// Supprimer toutes les notifications lues
  static Future<int> clearReadNotifications() async {
    if (!isAuthenticated) {
      final notifications = await StorageService.getNotifications();
      final readIds = notifications
          .where((n) => n['isRead'] == true)
          .map((n) => n['id'].toString())
          .toList();

      for (var id in readIds) {
        await StorageService.deleteNotification(id);
      }
      return readIds.length;
    }

    try {
      final response = await http.delete(
        Uri.parse(Endpoints.notificationsClearRead),
        headers: _headers,
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['data']['deleted_count'] ?? 0;
      }
    } catch (e) {
      print('❌ Erreur clearReadNotifications: $e');
    }

    return 0;
  }

  // ============================================================
  // PRÉFÉRENCES
  // ============================================================

  /// Récupérer les préférences de notifications
  static Future<NotificationSettings> getSettings() async {
    if (!isAuthenticated) {
      final local = await StorageService.getNotificationSettings();
      return NotificationSettings.fromLocalJson(local);
    }

    try {
      final response = await http.get(
        Uri.parse(Endpoints.notificationsSettings),
        headers: _headers,
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return NotificationSettings.fromJson(data['data']['settings']);
      }
    } catch (e) {
      print('❌ Erreur getSettings: $e');
    }

    final local = await StorageService.getNotificationSettings();
    return NotificationSettings.fromLocalJson(local);
  }

  /// Mettre à jour les préférences de notifications
  static Future<bool> updateSettings(NotificationSettings settings) async {
    // Toujours sauvegarder localement
    await StorageService.saveNotificationSettings(settings.toLocalJson());

    if (!isAuthenticated) {
      return true;
    }

    try {
      final response = await http.put(
        Uri.parse(Endpoints.notificationsSettings),
        headers: _headers,
        body: jsonEncode(settings.toJson()),
      );

      if (response.statusCode == 200) {
        return true;
      }
    } catch (e) {
      print('❌ Erreur updateSettings: $e');
    }

    return true;
  }

  // ============================================================
  // PUSH NOTIFICATIONS
  // ============================================================

  /// Enregistrer l'appareil pour les push notifications (FCM)
  static Future<bool> registerDevice({
    required String fcmToken,
    String deviceType = 'android',
  }) async {
    if (!isAuthenticated) {
      print('⚠️ [registerDevice] Non authentifié - Auth token: ${AuthService.authToken != null}');
      return false;
    }

    try {
      print('📤 POST /client/notifications/register-device');
      print('🔗 URL: ${Endpoints.notificationsRegisterDevice}');
      print('📱 Device type: $deviceType');
      print('🔑 FCM token: ${fcmToken.length > 20 ? '${fcmToken.substring(0, 20)}...' : fcmToken}');

      final response = await http.post(
        Uri.parse(Endpoints.notificationsRegisterDevice),
        headers: _headers,
        body: jsonEncode({
          'fcm_token': fcmToken,
          'device_type': deviceType,
        }),
      );

      print('📥 Register device status: ${response.statusCode}');
      print('📄 Register device body: ${response.body}');

      if (response.statusCode == 200) {
        print('✅ Device enregistré pour les push notifications');
        return true;
      } else {
        print('❌ Échec enregistrement device: HTTP ${response.statusCode}');
      }
    } catch (e) {
      print('❌ Erreur registerDevice: $e');
    }

    return false;
  }
}

// ============================================================
// MODÈLES
// ============================================================

/// Réponse de la liste des notifications
class NotificationListResponse {
  final int unreadCount;
  final int totalCount;
  final Map<String, int>? countByType;
  final List<NotificationItem> notifications;
  final NotificationPagination? pagination;
  final bool isLocal;

  NotificationListResponse({
    required this.unreadCount,
    required this.totalCount,
    this.countByType,
    required this.notifications,
    this.pagination,
    this.isLocal = false,
  });

  factory NotificationListResponse.fromJson(Map<String, dynamic> json) {
    return NotificationListResponse(
      unreadCount: json['unread_count'] ?? 0,
      totalCount: json['total_count'] ?? 0,
      countByType: json['count_by_type'] != null
          ? Map<String, int>.from(json['count_by_type'])
          : null,
      notifications: (json['notifications'] as List? ?? [])
          .map((n) => NotificationItem.fromJson(n))
          .toList(),
      pagination: json['pagination'] != null
          ? NotificationPagination.fromJson(json['pagination'])
          : null,
    );
  }
}

/// Item de notification
class NotificationItem {
  final int id;
  final String type;
  final String typeLabel;
  final String title;
  final String message;
  final String? icon;
  final String priority;
  final bool isRead;
  final String? actionUrl;
  final Map<String, dynamic>? data;
  final String createdAt;
  final String? createdAtHuman;

  NotificationItem({
    required this.id,
    required this.type,
    required this.typeLabel,
    required this.title,
    required this.message,
    this.icon,
    this.priority = 'normal',
    required this.isRead,
    this.actionUrl,
    this.data,
    required this.createdAt,
    this.createdAtHuman,
  });

  factory NotificationItem.fromJson(Map<String, dynamic> json) {
    return NotificationItem(
      id: json['id'] ?? 0,
      type: json['type'] ?? 'system',
      typeLabel: json['type_label'] ?? 'Système',
      title: json['title'] ?? '',
      message: json['message'] ?? '',
      icon: json['icon'],
      priority: json['priority'] ?? 'normal',
      isRead: json['is_read'] == true,
      actionUrl: json['action_url'],
      data: json['data'],
      createdAt: json['created_at'] ?? '',
      createdAtHuman: json['created_at_human'],
    );
  }

  /// Créer depuis les données locales
  factory NotificationItem.fromLocalJson(Map<String, dynamic> json) {
    final createdAt = json['createdAt'];
    String createdAtStr = '';
    String? createdAtHuman;

    if (createdAt is DateTime) {
      createdAtStr = createdAt.toIso8601String();
      createdAtHuman = _formatTimeAgo(createdAt);
    } else if (createdAt is String) {
      createdAtStr = createdAt;
      try {
        createdAtHuman = _formatTimeAgo(DateTime.parse(createdAt));
      } catch (_) {}
    }

    return NotificationItem(
      id: int.tryParse(json['id']?.toString() ?? '0') ?? 0,
      type: json['type'] ?? 'system',
      typeLabel: _getTypeLabel(json['type']),
      title: json['title'] ?? '',
      message: json['message'] ?? '',
      icon: json['icon'],
      priority: json['priority'] ?? 'normal',
      isRead: json['isRead'] == true,
      actionUrl: json['actionUrl'],
      data: json['data'],
      createdAt: createdAtStr,
      createdAtHuman: createdAtHuman ?? json['time'],
    );
  }

  static String _getTypeLabel(String? type) {
    switch (type) {
      case 'order':
        return 'Commande';
      case 'loyalty':
        return 'Fidélité';
      case 'promo':
      case 'promotion':
        return 'Promotion';
      case 'delivery':
        return 'Livraison';
      case 'payment':
      case 'wave_payment':
        return 'Paiement';
      default:
        return 'Notification';
    }
  }

  static String _formatTimeAgo(DateTime dateTime) {
    final diff = DateTime.now().difference(dateTime);

    if (diff.inMinutes < 1) return 'À l\'instant';
    if (diff.inMinutes < 60) return 'Il y a ${diff.inMinutes} min';
    if (diff.inHours < 24) return 'Il y a ${diff.inHours}h';
    if (diff.inDays == 1) return 'Hier';
    if (diff.inDays < 7) return 'Il y a ${diff.inDays} jours';
    return 'Il y a ${(diff.inDays / 7).floor()} semaines';
  }
}

/// Pagination des notifications
class NotificationPagination {
  final int currentPage;
  final int lastPage;
  final int perPage;
  final int total;

  NotificationPagination({
    required this.currentPage,
    required this.lastPage,
    required this.perPage,
    required this.total,
  });

  factory NotificationPagination.fromJson(Map<String, dynamic> json) {
    return NotificationPagination(
      currentPage: json['current_page'] ?? 1,
      lastPage: json['last_page'] ?? 1,
      perPage: json['per_page'] ?? 20,
      total: json['total'] ?? 0,
    );
  }

  bool get hasMore => currentPage < lastPage;
}

/// Préférences de notifications
class NotificationSettings {
  final bool pushEnabled;
  final bool emailEnabled;
  final bool smsEnabled;
  final bool orderUpdates;
  final bool promotions;
  final bool loyaltyUpdates;

  NotificationSettings({
    this.pushEnabled = true,
    this.emailEnabled = false,
    this.smsEnabled = false,
    this.orderUpdates = true,
    this.promotions = true,
    this.loyaltyUpdates = true,
  });

  factory NotificationSettings.fromJson(Map<String, dynamic> json) {
    return NotificationSettings(
      pushEnabled: json['push_enabled'] ?? true,
      emailEnabled: json['email_enabled'] ?? false,
      smsEnabled: json['sms_enabled'] ?? false,
      orderUpdates: json['order_updates'] ?? true,
      promotions: json['promotions'] ?? true,
      loyaltyUpdates: json['loyalty_updates'] ?? true,
    );
  }

  factory NotificationSettings.fromLocalJson(Map<String, dynamic> json) {
    return NotificationSettings(
      pushEnabled: json['push'] ?? true,
      emailEnabled: json['email'] ?? false,
      smsEnabled: json['sms'] ?? false,
      orderUpdates: json['orders'] ?? true,
      promotions: json['promotions'] ?? true,
      loyaltyUpdates: json['loyalty'] ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'push_enabled': pushEnabled,
      'email_enabled': emailEnabled,
      'sms_enabled': smsEnabled,
      'order_updates': orderUpdates,
      'promotions': promotions,
      'loyalty_updates': loyaltyUpdates,
    };
  }

  Map<String, dynamic> toLocalJson() {
    return {
      'push': pushEnabled,
      'email': emailEnabled,
      'sms': smsEnabled,
      'orders': orderUpdates,
      'promotions': promotions,
      'loyalty': loyaltyUpdates,
    };
  }

  NotificationSettings copyWith({
    bool? pushEnabled,
    bool? emailEnabled,
    bool? smsEnabled,
    bool? orderUpdates,
    bool? promotions,
    bool? loyaltyUpdates,
  }) {
    return NotificationSettings(
      pushEnabled: pushEnabled ?? this.pushEnabled,
      emailEnabled: emailEnabled ?? this.emailEnabled,
      smsEnabled: smsEnabled ?? this.smsEnabled,
      orderUpdates: orderUpdates ?? this.orderUpdates,
      promotions: promotions ?? this.promotions,
      loyaltyUpdates: loyaltyUpdates ?? this.loyaltyUpdates,
    );
  }
}
