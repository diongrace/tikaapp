import 'order_model.dart';
import 'client_model.dart';

/// Vue d'ensemble du dashboard client
class DashboardOverview {
  final int totalOrders;
  final int pendingOrders;
  final int completedOrders;
  final double totalSpent;
  final int loyaltyPoints;
  final int favoritesCount;
  final int unreadNotifications;
  final List<Order> recentOrders;
  final Client? client;

  DashboardOverview({
    required this.totalOrders,
    required this.pendingOrders,
    required this.completedOrders,
    required this.totalSpent,
    required this.loyaltyPoints,
    required this.favoritesCount,
    required this.unreadNotifications,
    required this.recentOrders,
    this.client,
  });

  factory DashboardOverview.fromJson(Map<String, dynamic> json) {
    // Structure API Tika (GET /client/dashboard):
    // data.commandes.{total, en_attente, terminé, total_dépensé, récent}
    // data.loyauté.{total_points, cards_count}
    // data.favoris.{compte, magasins}
    // data.profil.{id, nom, email, téléphone, avatar}
    // API retourne 'orders' (anglais) ou 'commandes' (français)
    final commandes = json['commandes'] as Map<String, dynamic>? ??
        json['orders'] as Map<String, dynamic>? ?? {};
    final loyaute = json['loyauté'] as Map<String, dynamic>? ??
        json['loyaute'] as Map<String, dynamic>? ??
        json['loyalty'] as Map<String, dynamic>? ?? {};
    final favoris = json['favoris'] as Map<String, dynamic>? ??
        json['favorites'] as Map<String, dynamic>? ?? {};

    // Fallback structures alternatives
    final stats = json['stats'] as Map<String, dynamic>? ??
        json['overview'] as Map<String, dynamic>? ??
        json;

    // Commandes récentes: chercher dans commandes.récent puis fallbacks
    List<Order> recentOrders = [];
    final ordersRaw = commandes['récent'] ??
        commandes['recent'] ??
        commandes['orders'] ??
        json['recent_orders'] ??
        stats['recent_orders'] ??
        json['orders'] ??
        json['last_orders'] ??
        json['latest_orders'];
    if (ordersRaw is List) {
      recentOrders = ordersRaw.map((e) => Order.fromJson(e)).toList();
    }

    // Profil client: chercher dans profil puis fallbacks
    Client? client;
    final profilRaw = json['profil'] as Map<String, dynamic>? ??
        json['profile'] as Map<String, dynamic>?;
    final clientRaw = profilRaw ??
        json['client'] as Map<String, dynamic>? ??
        json['user'] as Map<String, dynamic>? ??
        json['customer'] as Map<String, dynamic>?;
    if (clientRaw != null) {
      // Normaliser les clés françaises de la section profil
      final normalized = <String, dynamic>{
        'id': clientRaw['id'] ?? 0,
        'full_name': clientRaw['nom'] ?? clientRaw['name'] ?? clientRaw['full_name'],
        'email': clientRaw['email'],
        'phone': clientRaw['téléphone'] ?? clientRaw['telephone'] ?? clientRaw['phone'] ?? '',
        'profile_photo': clientRaw['avatar'] ?? clientRaw['profile_photo'],
        ...clientRaw,
      };
      client = Client.fromJson(normalized);
    }

    // Favoris count: chercher dans favoris.compte puis fallbacks
    final favoritesRaw = favoris['magasins'] ??
        favoris['shops'] ??
        json['favorites'] ??
        stats['favorites'];
    int favoritesCount = _parseInt(favoris['compte']) ??
        _parseInt(favoris['count']) ??
        _parseInt(stats['favorites_count']) ??
        _parseInt(json['favorites_count']) ??
        _parseInt(stats['favorites_total']) ??
        _parseInt(json['favorites_total']) ??
        0;
    if (favoritesCount == 0 && favoritesRaw is List) {
      favoritesCount = (favoritesRaw as List).length;
    }

    return DashboardOverview(
      totalOrders: _parseInt(commandes['total']) ??
          _parseInt(stats['total_orders']) ??
          _parseInt(json['total_orders']) ??
          _parseInt(stats['orders_count']) ??
          _parseInt(json['orders_count']) ??
          0,
      pendingOrders: _parseInt(commandes['en_attente']) ??
          _parseInt(commandes['en attente']) ??
          _parseInt(commandes['pending']) ??
          _parseInt(stats['pending_orders']) ??
          _parseInt(json['pending_orders']) ??
          0,
      completedOrders: _parseInt(commandes['terminé']) ??
          _parseInt(commandes['termine']) ??
          _parseInt(commandes['completed']) ??
          _parseInt(stats['completed_orders']) ??
          _parseInt(json['completed_orders']) ??
          0,
      totalSpent: _parseDouble(commandes['total_dépensé']) ??
          _parseDouble(commandes['total_depense']) ??
          _parseDouble(commandes['total_spent']) ??
          _parseDouble(stats['total_spent']) ??
          _parseDouble(json['total_spent']) ??
          _parseDouble(stats['total_amount']) ??
          _parseDouble(json['total_amount']) ??
          0.0,
      loyaltyPoints: _parseInt(loyaute['total_points']) ??
          _parseInt(loyaute['points']) ??
          _parseInt(stats['loyalty_points']) ??
          _parseInt(json['loyalty_points']) ??
          _parseInt(stats['total_loyalty_points']) ??
          0,
      favoritesCount: favoritesCount,
      unreadNotifications: _parseInt(stats['unread_notifications']) ??
          _parseInt(json['unread_notifications']) ??
          _parseInt(stats['notifications_count']) ??
          0,
      recentOrders: recentOrders,
      client: client,
    );
  }

  static int? _parseInt(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is double) return value.toInt();
    if (value is String) return int.tryParse(value);
    return null;
  }

  static double? _parseDouble(dynamic value) {
    if (value == null) return null;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value);
    return null;
  }
}

/// Statistiques du dashboard
class DashboardStats {
  final double totalSpent;
  final int totalOrders;
  final double averageOrderAmount;
  final int totalLoyaltyPoints;
  final int ordersThisMonth;
  final double spentThisMonth;
  final String? favoriteShop;
  final String? favoriteCategory;
  final Map<String, int> ordersByStatus;
  final Map<String, double> spentByMonth;

  DashboardStats({
    required this.totalSpent,
    required this.totalOrders,
    required this.averageOrderAmount,
    required this.totalLoyaltyPoints,
    required this.ordersThisMonth,
    required this.spentThisMonth,
    this.favoriteShop,
    this.favoriteCategory,
    required this.ordersByStatus,
    required this.spentByMonth,
  });

  factory DashboardStats.fromJson(Map<String, dynamic> json) {
    // Structure API Tika (GET /client/dashboard/stats):
    // data.résumé.{total_commandes, total_dépensé, valeur_moyenne_commande}
    // data.ce_mois.{commandes, dépensé, orders_growth}
    // data.top_shops[{shop_id, shop_name, ...}]
    // data.tendance_mensuelle[{month, orders, spent}]
    final resume = json['résumé'] as Map<String, dynamic>? ??
        json['resume'] as Map<String, dynamic>? ??
        json['summary'] as Map<String, dynamic>? ?? {};
    final ceMois = json['ce_mois'] as Map<String, dynamic>? ??
        json['this_month'] as Map<String, dynamic>? ?? {};

    // Fallback structures alternatives
    final stats = json['stats'] as Map<String, dynamic>? ??
        json['overview'] as Map<String, dynamic>? ??
        json;

    // Chercher orders_by_status dans plusieurs endroits
    final ordersByStatusRaw = stats['orders_by_status'] ??
        json['orders_by_status'] ??
        stats['commandes_par_statut'] ??
        json['commandes_par_statut'];

    // Chercher spent_by_month: peut venir de tendance_mensuelle
    final tendanceMensuelle = json['tendance_mensuelle'] as List? ??
        json['monthly_trend'] as List?;
    final spentByMonthRaw = stats['spent_by_month'] ??
        json['spent_by_month'] ??
        stats['depenses_par_mois'] ??
        json['depenses_par_mois'];

    Map<String, double> spentByMonth = {};
    if (spentByMonthRaw != null && spentByMonthRaw is Map) {
      spentByMonth = Map<String, double>.from(
        spentByMonthRaw.map(
          (key, value) => MapEntry(key.toString(), _parseDouble(value) ?? 0.0),
        ),
      );
    } else if (tendanceMensuelle != null) {
      // Construire depuis tendance_mensuelle: [{month_short, spent}]
      for (final item in tendanceMensuelle) {
        if (item is Map) {
          final key = item['month_short']?.toString() ?? item['month']?.toString() ?? '';
          final value = _parseDouble(item['spent']) ?? _parseDouble(item['dépensé']) ?? 0.0;
          if (key.isNotEmpty) spentByMonth[key] = value;
        }
      }
    }

    return DashboardStats(
      totalSpent: _parseDouble(resume['total_dépensé']) ??
          _parseDouble(resume['total_depense']) ??
          _parseDouble(resume['total_spent']) ??
          _parseDouble(stats['total_spent']) ??
          _parseDouble(json['total_spent']) ??
          _parseDouble(stats['total_amount']) ??
          _parseDouble(json['total_amount']) ??
          0.0,
      totalOrders: _parseInt(resume['total_commandes']) ??
          _parseInt(resume['total_orders']) ??
          _parseInt(stats['total_orders']) ??
          _parseInt(json['total_orders']) ??
          _parseInt(stats['orders_count']) ??
          _parseInt(json['orders_count']) ??
          0,
      averageOrderAmount: _parseDouble(resume['valeur_moyenne_commande']) ??
          _parseDouble(resume['average_order_value']) ??
          _parseDouble(resume['average_order_amount']) ??
          _parseDouble(stats['average_order_amount']) ??
          _parseDouble(json['average_order_amount']) ??
          _parseDouble(stats['panier_moyen']) ??
          _parseDouble(json['panier_moyen']) ??
          0.0,
      totalLoyaltyPoints: _parseInt(stats['total_loyalty_points']) ??
          _parseInt(json['total_loyalty_points']) ??
          _parseInt(stats['loyalty_points']) ??
          _parseInt(json['loyalty_points']) ??
          0,
      ordersThisMonth: _parseInt(ceMois['commandes']) ??
          _parseInt(ceMois['orders']) ??
          _parseInt(stats['orders_this_month']) ??
          _parseInt(json['orders_this_month']) ??
          0,
      spentThisMonth: _parseDouble(ceMois['dépensé']) ??
          _parseDouble(ceMois['depense']) ??
          _parseDouble(ceMois['spent']) ??
          _parseDouble(stats['spent_this_month']) ??
          _parseDouble(json['spent_this_month']) ??
          0.0,
      favoriteShop: stats['favorite_shop']?.toString() ??
          json['favorite_shop']?.toString() ??
          stats['boutique_preferee']?.toString() ??
          json['boutique_preferee']?.toString(),
      favoriteCategory: stats['favorite_category']?.toString() ??
          json['favorite_category']?.toString() ??
          stats['categorie_preferee']?.toString() ??
          json['categorie_preferee']?.toString(),
      ordersByStatus: ordersByStatusRaw != null && ordersByStatusRaw is Map
          ? Map<String, int>.from(
              ordersByStatusRaw.map(
                (key, value) => MapEntry(key.toString(), _parseInt(value) ?? 0),
              ),
            )
          : {},
      spentByMonth: spentByMonth,
    );
  }

  static int? _parseInt(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is double) return value.toInt();
    if (value is String) return int.tryParse(value);
    return null;
  }

  static double? _parseDouble(dynamic value) {
    if (value == null) return null;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value);
    return null;
  }
}

/// Boutique favorite dans le dashboard
class DashboardFavorite {
  final int id;
  final int shopId;
  final String shopName;
  final String? shopLogo;
  final String? shopCategory;
  final String? shopCity;
  final DateTime? addedAt;

  DashboardFavorite({
    required this.id,
    required this.shopId,
    required this.shopName,
    this.shopLogo,
    this.shopCategory,
    this.shopCity,
    this.addedAt,
  });

  factory DashboardFavorite.fromJson(Map<String, dynamic> json) {
    final shop = json['shop'] as Map<String, dynamic>?;

    return DashboardFavorite(
      id: json['id'] ?? 0,
      shopId: shop?['id'] ?? json['shop_id'] ?? 0,
      shopName: shop?['name']?.toString() ?? json['shop_name']?.toString() ?? '',
      shopLogo: shop?['logo_url']?.toString() ??
          shop?['logo']?.toString() ??
          json['shop_logo']?.toString(),
      shopCategory: shop?['category']?.toString() ??
          json['shop_category']?.toString(),
      shopCity: shop?['city']?.toString() ?? json['shop_city']?.toString(),
      addedAt: DateTime.tryParse(json['created_at']?.toString() ?? ''),
    );
  }
}

/// Notification du dashboard
class DashboardNotification {
  final int id;
  final String type;
  final String title;
  final String message;
  final bool isRead;
  final String? actionUrl;
  final Map<String, dynamic>? data;
  final DateTime createdAt;
  final String? createdAtHuman;

  DashboardNotification({
    required this.id,
    required this.type,
    required this.title,
    required this.message,
    required this.isRead,
    this.actionUrl,
    this.data,
    required this.createdAt,
    this.createdAtHuman,
  });

  factory DashboardNotification.fromJson(Map<String, dynamic> json) {
    return DashboardNotification(
      id: json['id'] ?? 0,
      type: json['type']?.toString() ?? 'system',
      title: json['title']?.toString() ?? '',
      message: json['message']?.toString() ?? '',
      isRead: json['lire'] == true || json['is_read'] == true,
      actionUrl: json['action_url']?.toString(),
      data: json['données'] as Map<String, dynamic>? ??
          json['data'] as Map<String, dynamic>?,
      createdAt: DateTime.tryParse(json['created_at']?.toString() ?? '') ??
          DateTime.now(),
      createdAtHuman: json['created_at_human']?.toString(),
    );
  }

  String get typeLabel {
    switch (type) {
      case 'order':
        return 'Commande';
      case 'loyalty':
        return 'Fidelite';
      case 'promo':
        return 'Promotion';
      case 'delivery':
        return 'Livraison';
      case 'payment':
        return 'Paiement';
      default:
        return 'Notification';
    }
  }

  String get timeAgo {
    if (createdAtHuman != null) return createdAtHuman!;
    final diff = DateTime.now().difference(createdAt);
    if (diff.inMinutes < 1) return 'A l\'instant';
    if (diff.inMinutes < 60) return 'Il y a ${diff.inMinutes} min';
    if (diff.inHours < 24) return 'Il y a ${diff.inHours}h';
    if (diff.inDays == 1) return 'Hier';
    if (diff.inDays < 7) return 'Il y a ${diff.inDays} jours';
    return 'Il y a ${(diff.inDays / 7).floor()} semaines';
  }
}

/// Reponse paginee pour les listes du dashboard
class DashboardPaginatedResponse<T> {
  final List<T> items;
  final int currentPage;
  final int lastPage;
  final int total;

  DashboardPaginatedResponse({
    required this.items,
    required this.currentPage,
    required this.lastPage,
    required this.total,
  });

  bool get hasMore => currentPage < lastPage;
}
