/// Statistiques du profil client
class ProfileStats {
  final int totalOrders;
  final int completedOrders;
  final double totalAmount;
  final int favoritesCount;
  final int loyaltyPoints;
  final int addressesCount;

  ProfileStats({
    required this.totalOrders,
    required this.completedOrders,
    required this.totalAmount,
    required this.favoritesCount,
    required this.loyaltyPoints,
    required this.addressesCount,
  });

  factory ProfileStats.fromJson(Map<String, dynamic> json) {
    return ProfileStats(
      totalOrders: _parseInt(json['total_orders']) ?? 0,
      completedOrders: _parseInt(json['completed_orders']) ?? 0,
      totalAmount: _parseDouble(json['total_amount'] ?? json['total_spent']) ?? 0.0,
      favoritesCount: _parseInt(json['favorites_count'] ?? json['favorites']) ?? 0,
      loyaltyPoints: _parseInt(json['loyalty_points'] ?? json['loyalty']) ?? 0,
      addressesCount: _parseInt(json['addresses_count'] ?? json['addresses']) ?? 0,
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

/// Adresse du profil client
class ProfileAddress {
  final int id;
  final String label;
  final String address;
  final String? city;
  final String? region;
  final bool isDefault;
  final DateTime? createdAt;

  ProfileAddress({
    required this.id,
    required this.label,
    required this.address,
    this.city,
    this.region,
    this.isDefault = false,
    this.createdAt,
  });

  factory ProfileAddress.fromJson(Map<String, dynamic> json) {
    return ProfileAddress(
      id: json['id'] ?? 0,
      label: json['label'] ?? json['name'] ?? '',
      address: json['address'] ?? '',
      city: json['city'],
      region: json['region'],
      isDefault: json['is_default'] == true || json['is_default'] == 1,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'].toString())
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'label': label,
      'address': address,
      'city': city,
      'region': region,
      'is_default': isDefault,
      'created_at': createdAt?.toIso8601String(),
    };
  }

  /// Adresse formatee sur une ligne
  String get fullAddress {
    final parts = <String>[address];
    if (city != null && city!.isNotEmpty) parts.add(city!);
    if (region != null && region!.isNotEmpty) parts.add(region!);
    return parts.join(', ');
  }
}
