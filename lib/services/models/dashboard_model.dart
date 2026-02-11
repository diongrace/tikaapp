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
    // L'API peut retourner les stats sous différentes structures:
    // 1. Directement: {total_orders: X, ...}
    // 2. Sous "stats": {stats: {total_orders: X, ...}}
    // 3. Sous "overview": {overview: {total_orders: X, ...}}
    // 4. Avec des noms alternatifs: orders_count, favorites_total, etc.
    final stats = json['stats'] as Map<String, dynamic>? ??
        json['overview'] as Map<String, dynamic>? ??
        json;

    // Chercher recent_orders dans plusieurs endroits possibles
    List<Order> recentOrders = [];
    final ordersRaw = json['recent_orders'] ??
        stats['recent_orders'] ??
        json['orders'] ??
        json['last_orders'] ??
        json['latest_orders'];
    if (ordersRaw is List) {
      recentOrders = ordersRaw.map((e) => Order.fromJson(e)).toList();
    }

    // Chercher le client dans plusieurs endroits possibles
    Client? client;
    final clientRaw = json['client'] ?? json['user'] ?? json['customer'];
    if (clientRaw is Map<String, dynamic>) {
      client = Client.fromJson(clientRaw);
    }

    // Chercher favorites dans plusieurs endroits
    final favoritesRaw = json['favorites'] ?? stats['favorites'];
    int favoritesCount = _parseInt(stats['favorites_count']) ??
        _parseInt(json['favorites_count']) ??
        _parseInt(stats['favorites_total']) ??
        _parseInt(json['favorites_total']) ??
        0;
    // Si favorites est une liste, prendre son length
    if (favoritesCount == 0 && favoritesRaw is List) {
      favoritesCount = favoritesRaw.length;
    }

    return DashboardOverview(
      totalOrders: _parseInt(stats['total_orders']) ??
          _parseInt(json['total_orders']) ??
          _parseInt(stats['orders_count']) ??
          _parseInt(json['orders_count']) ??
          0,
      pendingOrders: _parseInt(stats['pending_orders']) ??
          _parseInt(json['pending_orders']) ??
          0,
      completedOrders: _parseInt(stats['completed_orders']) ??
          _parseInt(json['completed_orders']) ??
          0,
      totalSpent: _parseDouble(stats['total_spent']) ??
          _parseDouble(json['total_spent']) ??
          _parseDouble(stats['total_amount']) ??
          _parseDouble(json['total_amount']) ??
          0.0,
      loyaltyPoints: _parseInt(stats['loyalty_points']) ??
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
    // L'API peut retourner les stats sous differentes structures:
    // 1. Directement: {total_orders: X, ...}
    // 2. Sous "stats": {stats: {total_orders: X, ...}}
    // 3. Sous "overview": {overview: {total_orders: X, ...}}
    final stats = json['stats'] as Map<String, dynamic>? ??
        json['overview'] as Map<String, dynamic>? ??
        json;

    // Chercher orders_by_status dans plusieurs endroits
    final ordersByStatusRaw = stats['orders_by_status'] ??
        json['orders_by_status'] ??
        stats['commandes_par_statut'] ??
        json['commandes_par_statut'];

    // Chercher spent_by_month dans plusieurs endroits
    final spentByMonthRaw = stats['spent_by_month'] ??
        json['spent_by_month'] ??
        stats['depenses_par_mois'] ??
        json['depenses_par_mois'];

    return DashboardStats(
      totalSpent: _parseDouble(stats['total_spent']) ??
          _parseDouble(json['total_spent']) ??
          _parseDouble(stats['total_amount']) ??
          _parseDouble(json['total_amount']) ??
          _parseDouble(stats['total_depense']) ??
          _parseDouble(json['total_depense']) ??
          0.0,
      totalOrders: _parseInt(stats['total_orders']) ??
          _parseInt(json['total_orders']) ??
          _parseInt(stats['orders_count']) ??
          _parseInt(json['orders_count']) ??
          _parseInt(stats['total_commandes']) ??
          _parseInt(json['total_commandes']) ??
          0,
      averageOrderAmount: _parseDouble(stats['average_order_amount']) ??
          _parseDouble(json['average_order_amount']) ??
          _parseDouble(stats['average_amount']) ??
          _parseDouble(json['average_amount']) ??
          _parseDouble(stats['panier_moyen']) ??
          _parseDouble(json['panier_moyen']) ??
          0.0,
      totalLoyaltyPoints: _parseInt(stats['total_loyalty_points']) ??
          _parseInt(json['total_loyalty_points']) ??
          _parseInt(stats['loyalty_points']) ??
          _parseInt(json['loyalty_points']) ??
          _parseInt(stats['points_fidelite']) ??
          _parseInt(json['points_fidelite']) ??
          0,
      ordersThisMonth: _parseInt(stats['orders_this_month']) ??
          _parseInt(json['orders_this_month']) ??
          _parseInt(stats['commandes_ce_mois']) ??
          _parseInt(json['commandes_ce_mois']) ??
          0,
      spentThisMonth: _parseDouble(stats['spent_this_month']) ??
          _parseDouble(json['spent_this_month']) ??
          _parseDouble(stats['depense_ce_mois']) ??
          _parseDouble(json['depense_ce_mois']) ??
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
      spentByMonth: spentByMonthRaw != null && spentByMonthRaw is Map
          ? Map<String, double>.from(
              spentByMonthRaw.map(
                (key, value) =>
                    MapEntry(key.toString(), _parseDouble(value) ?? 0.0),
              ),
            )
          : {},
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
      isRead: json['is_read'] == true,
      actionUrl: json['action_url']?.toString(),
      data: json['data'] as Map<String, dynamic>?,
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
