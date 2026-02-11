import 'package:flutter/material.dart';
import '../../core/models/boutique_type.dart';

class Shop {
  final int id;
  final String name;
  final String? slug;
  final String? description;
  final String category;
  final String city;
  final String address;
  final String? location;
  final String logoUrl;
  final String? bannerUrl;
  final String? phone;
  final String? email;
  final String status;
  final double? latitude;
  final double? longitude;
  final Map<String, dynamic>? openingHours;
  final List<DeliveryZone>? deliveryZones;
  final ShopStats? stats;
  final ShopTheme? theme;
  final bool isFeatured;
  final double? distance;

  // Wave Payment
  final bool waveEnabled;
  final String? wavePaymentLink;
  final String? wavePhone;
  final bool wavePartialPaymentEnabled;
  final int wavePartialPaymentPercentage;

  Shop({
    required this.id,
    required this.name,
    this.slug,
    this.description,
    required this.category,
    required this.city,
    required this.address,
    this.location,
    required this.logoUrl,
    this.bannerUrl,
    this.phone,
    this.email,
    this.status = 'active',
    this.latitude,
    this.longitude,
    this.openingHours,
    this.deliveryZones,
    this.stats,
    this.theme,
    this.isFeatured = false,
    this.distance,
    this.waveEnabled = false,
    this.wavePaymentLink,
    this.wavePhone,
    this.wavePartialPaymentEnabled = false,
    this.wavePartialPaymentPercentage = 0,
  });

  // URL de base pour les fichiers de stockage
  static const String _storageBaseUrl = 'https://prepro.tika-ci.com/storage';

  /// Construit une URL complète à partir d'un chemin relatif ou absolu
  static String _buildFullUrl(String path) {
    if (path.isEmpty) return '';
    if (path.startsWith('http')) return path;
    return '$_storageBaseUrl/$path';
  }

  factory Shop.fromJson(Map<String, dynamic> json) {
    // Logo: l'API liste retourne "logo" (chemin relatif), l'API detail retourne "logo_url" (URL complète)
    final logoRaw = json['logo_url']?.toString() ?? json['logo']?.toString() ?? '';
    final parsedLogoUrl = _buildFullUrl(logoRaw);

    // Banner: l'API peut retourner sous differents noms selon l'endpoint
    final bannerUrlRaw = json['banner_url']
        ?? json['cover_image']
        ?? json['banner']
        ?? json['image_banner']
        ?? json['cover']
        ?? json['couverture']
        ?? json['header_image']
        ?? json['background_image']
        ?? json['photo_couverture'];
    final parsedBannerUrl = bannerUrlRaw != null && bannerUrlRaw.toString().trim().isNotEmpty
        ? _parseUrl(_buildFullUrl(bannerUrlRaw.toString()))
        : null;
    print('🖼️ [Shop.fromJson] id=${json['id']} banner_url=$bannerUrlRaw => parsed=$parsedBannerUrl');

    // Parser l'objet wave structuré (nouveau format API)
    // L'API retourne: { "wave": { "enabled": true, "payment_link": "...", "phone": "...", "partial_payment_enabled": false, "partial_payment_percentage": 0 } }
    final waveObj = json['wave'] is Map ? json['wave'] as Map<String, dynamic> : null;

    // Wave enabled: d'abord depuis l'objet wave, sinon champs plats
    final bool parsedWaveEnabled = waveObj != null
        ? (waveObj['enabled'] == true || waveObj['enabled'] == 1)
        : (json['wave_enabled'] == true || json['wave_enabled'] == 1);

    // Wave payment link: d'abord depuis l'objet wave, sinon champs plats
    final wavePaymentLinkRaw = waveObj?['payment_link']
        ?? json['wave_payment_link']
        ?? json['wave_link']
        ?? json['wave_url']
        ?? json['wave_number']
        ?? (json['settings'] is Map ? json['settings']['wave_payment_link'] : null)
        ?? (json['settings'] is Map ? json['settings']['wave_link'] : null)
        ?? (json['payment_settings'] is Map ? json['payment_settings']['wave_payment_link'] : null)
        ?? (json['payment_settings'] is Map ? json['payment_settings']['wave_link'] : null)
        ?? (json['payment'] is Map ? json['payment']['wave_link'] : null)
        ?? (json['payment'] is Map ? json['payment']['wave_payment_link'] : null);

    // Wave phone: depuis l'objet wave ou champs plats
    final wavePhoneRaw = waveObj?['phone']
        ?? json['wave_phone']
        ?? json['wave_number'];

    // Wave partial payment: depuis l'objet wave ou champs plats
    final bool parsedPartialEnabled = waveObj != null
        ? (waveObj['partial_payment_enabled'] == true || waveObj['partial_payment_enabled'] == 1)
        : (json['wave_partial_payment_enabled'] == true || json['wave_partial_payment_enabled'] == 1);

    final int parsedPartialPercentage = waveObj != null
        ? (_parseInt(waveObj['partial_payment_percentage']) ?? 0)
        : (_parseInt(json['wave_partial_payment_percentage']) ?? 0);

    return Shop(
      id: _parseInt(json['id']) ?? 0,
      name: json['name']?.toString() ?? '',
      slug: json['slug']?.toString(),
      description: json['description']?.toString(),
      category: json['category']?.toString() ?? '',
      city: json['city']?.toString() ?? '',
      address: json['address']?.toString() ?? '',
      location: json['location']?.toString(),
      logoUrl: parsedLogoUrl,
      bannerUrl: parsedBannerUrl,
      phone: json['phone']?.toString(),
      email: json['email']?.toString(),
      status: json['status']?.toString() ?? 'active',
      latitude: _parseDouble(json['latitude']),
      longitude: _parseDouble(json['longitude']),
      openingHours: json['opening_hours'] != null
          ? Map<String, dynamic>.from(json['opening_hours'])
          : null,
      deliveryZones: json['delivery_zones'] != null
          ? (json['delivery_zones'] as List).map((e) => DeliveryZone.fromJson(e)).toList()
          : null,
      stats: json['stats'] != null ? ShopStats.fromJson(json['stats']) : null,
      theme: json['theme'] != null ? ShopTheme.fromJson(json['theme']) : null,
      isFeatured: json['is_featured'] == true || json['is_featured'] == 1,
      distance: _parseDouble(json['distance']),
      waveEnabled: parsedWaveEnabled,
      wavePaymentLink: wavePaymentLinkRaw?.toString(),
      wavePhone: wavePhoneRaw?.toString(),
      wavePartialPaymentEnabled: parsedPartialEnabled,
      wavePartialPaymentPercentage: parsedPartialPercentage,
    );
  }

  static int? _parseInt(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is double) return value.toInt();
    if (value is String) {
      // Gérer les strings avec décimales comme "1500.00"
      final doubleValue = double.tryParse(value);
      return doubleValue?.toInt();
    }
    return null;
  }

  static double? _parseDouble(dynamic value) {
    if (value == null) return null;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value);
    return null;
  }

  /// Retourne une copie du shop avec un nouveau bannerUrl
  Shop copyWithBanner(String newBannerUrl) {
    return Shop(
      id: id,
      name: name,
      slug: slug,
      description: description,
      category: category,
      city: city,
      address: address,
      location: location,
      logoUrl: logoUrl,
      bannerUrl: newBannerUrl,
      phone: phone,
      email: email,
      status: status,
      latitude: latitude,
      longitude: longitude,
      openingHours: openingHours,
      deliveryZones: deliveryZones,
      stats: stats,
      theme: theme,
      isFeatured: isFeatured,
      distance: distance,
      waveEnabled: waveEnabled,
      wavePaymentLink: wavePaymentLink,
      wavePhone: wavePhone,
      wavePartialPaymentEnabled: wavePartialPaymentEnabled,
      wavePartialPaymentPercentage: wavePartialPaymentPercentage,
    );
  }

  // Parser une URL en gérant les cas invalides
  static String? _parseUrl(dynamic value) {
    if (value == null) return null;

    final String stringValue = value.toString().trim();

    // Gérer les cas invalides qui doivent être traités comme null
    if (stringValue.isEmpty ||
        stringValue.toLowerCase() == 'null' ||
        stringValue.toLowerCase() == 'undefined') {
      return null;
    }

    return stringValue;
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'slug': slug,
      'description': description,
      'category': category,
      'city': city,
      'address': address,
      'location': location,
      'logo_url': logoUrl,
      'banner_url': bannerUrl,
      'phone': phone,
      'email': email,
      'status': status,
      'latitude': latitude,
      'longitude': longitude,
      'opening_hours': openingHours,
      'delivery_zones': deliveryZones?.map((e) => e.toJson()).toList(),
      'stats': stats?.toJson(),
      'theme': theme?.toJson(),
      'is_featured': isFeatured,
      'distance': distance,
      'wave': {
        'enabled': waveEnabled,
        'payment_link': wavePaymentLink,
        'phone': wavePhone,
        'partial_payment_enabled': wavePartialPaymentEnabled,
        'partial_payment_percentage': wavePartialPaymentPercentage,
      },
    };
  }
}

// Classe pour les zones de livraison
class DeliveryZone {
  final int id;
  final String name;
  final int deliveryFee;
  final int minOrderAmount;
  final String? estimatedTime;
  final bool isActive;

  DeliveryZone({
    required this.id,
    required this.name,
    required this.deliveryFee,
    required this.minOrderAmount,
    this.estimatedTime,
    this.isActive = true,
  });

  factory DeliveryZone.fromJson(Map<String, dynamic> json) {
    return DeliveryZone(
      id: _parseInt(json['id']) ?? 0,
      name: json['name']?.toString() ?? '',
      deliveryFee: _parseInt(json['delivery_fee']) ?? 0,
      minOrderAmount: _parseInt(json['min_order_amount']) ?? 0,
      estimatedTime: json['estimated_time']?.toString(),
      isActive: json['is_active'] == true || json['is_active'] == 1,
    );
  }

  static int? _parseInt(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is double) return value.toInt();
    if (value is String) {
      final doubleValue = double.tryParse(value);
      return doubleValue?.toInt();
    }
    return null;
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'delivery_fee': deliveryFee,
      'min_order_amount': minOrderAmount,
      'estimated_time': estimatedTime,
      'is_active': isActive,
    };
  }
}

// Classe pour les statistiques de la boutique
class ShopStats {
  final int totalProducts;
  final int totalOrders;

  ShopStats({
    required this.totalProducts,
    required this.totalOrders,
  });

  factory ShopStats.fromJson(Map<String, dynamic> json) {
    return ShopStats(
      totalProducts: _parseInt(json['total_products']) ?? 0,
      totalOrders: _parseInt(json['total_orders']) ?? 0,
    );
  }

  static int? _parseInt(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is double) return value.toInt();
    if (value is String) {
      // Gérer les strings avec décimales comme "1500.00"
      final doubleValue = double.tryParse(value);
      return doubleValue?.toInt();
    }
    return null;
  }

  Map<String, dynamic> toJson() {
    return {
      'total_products': totalProducts,
      'total_orders': totalOrders,
    };
  }
}

// Classe pour le thème de la boutique
class ShopTheme {
  final String primaryColor;
  final String secondaryColor;
  final String accentColor;

  ShopTheme({
    required this.primaryColor,
    required this.secondaryColor,
    required this.accentColor,
  });

  factory ShopTheme.fromJson(Map<String, dynamic> json) {
    return ShopTheme(
      primaryColor: json['primary_color']?.toString() ?? '#9C27B0',
      secondaryColor: json['secondary_color']?.toString() ?? '#CE93D8',
      accentColor: json['accent_color']?.toString() ?? '#4A148C',
    );
  }

  /// Thème par défaut (violet TIKA)
  factory ShopTheme.defaultTheme() {
    return ShopTheme(
      primaryColor: '#9C27B0',
      secondaryColor: '#CE93D8',
      accentColor: '#4A148C',
    );
  }

  /// Convertit une couleur hexadécimale en Color Flutter
  static Color hexToColor(String hexString) {
    final buffer = StringBuffer();
    if (hexString.length == 6 || hexString.length == 7) buffer.write('ff');
    buffer.write(hexString.replaceFirst('#', ''));
    return Color(int.parse(buffer.toString(), radix: 16));
  }

  /// Obtient la couleur primaire comme Color Flutter
  Color get primary => hexToColor(primaryColor);

  /// Obtient la couleur secondaire comme Color Flutter
  Color get secondary => hexToColor(secondaryColor);

  /// Obtient la couleur d'accent comme Color Flutter
  Color get accent => hexToColor(accentColor);

  /// Obtient une version claire de la couleur primaire (pour les backgrounds)
  Color get primaryLight => primary.withValues(alpha: 0.1);

  /// Obtient une version moyenne de la couleur primaire
  Color get primaryMedium => primary.withValues(alpha: 0.3);

  /// Couleur du texte sur fond primaire (blanc ou noir selon luminosité)
  Color get textOnPrimary {
    final luminance = primary.computeLuminance();
    return luminance > 0.5 ? const Color(0xFF1A1A1A) : Colors.white;
  }

  Map<String, dynamic> toJson() {
    return {
      'primary_color': primaryColor,
      'secondary_color': secondaryColor,
      'accent_color': accentColor,
    };
  }
}

// Classe pour les options de livraison (objet de configuration)
class DeliveryOptions {
  final bool deliveryEnabled;
  final bool pickupEnabled;
  final List<DeliveryZone>? deliveryZones;
  final int defaultDeliveryFee;
  final int freeDeliveryThreshold;

  DeliveryOptions({
    this.deliveryEnabled = false,
    this.pickupEnabled = false,
    this.deliveryZones,
    this.defaultDeliveryFee = 0,
    this.freeDeliveryThreshold = 0,
  });

  factory DeliveryOptions.fromJson(Map<String, dynamic> json) {
    return DeliveryOptions(
      deliveryEnabled: json['delivery_enabled'] == true || json['delivery_enabled'] == 1,
      pickupEnabled: json['pickup_enabled'] == true || json['pickup_enabled'] == 1,
      deliveryZones: json['delivery_zones'] != null
          ? (json['delivery_zones'] as List).map((e) => DeliveryZone.fromJson(e)).toList()
          : null,
      defaultDeliveryFee: _parseInt(json['default_delivery_fee']) ?? 0,
      freeDeliveryThreshold: _parseInt(json['free_delivery_threshold']) ?? 0,
    );
  }

  static int? _parseInt(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is double) return value.toInt();
    if (value is String) {
      final doubleValue = double.tryParse(value);
      return doubleValue?.toInt();
    }
    return null;
  }

  Map<String, dynamic> toJson() {
    return {
      'delivery_enabled': deliveryEnabled,
      'pickup_enabled': pickupEnabled,
      'delivery_zones': deliveryZones?.map((e) => e.toJson()).toList(),
      'default_delivery_fee': defaultDeliveryFee,
      'free_delivery_threshold': freeDeliveryThreshold,
    };
  }
}

// Classe pour les méthodes de paiement
class PaymentMethod {
  final String id;
  final String name;
  final String? description;
  final String? icon;
  final bool isEnabled;

  PaymentMethod({
    required this.id,
    required this.name,
    this.description,
    this.icon,
    this.isEnabled = true,
  });

  factory PaymentMethod.fromJson(Map<String, dynamic> json) {
    return PaymentMethod(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      description: json['description']?.toString(),
      icon: json['icon']?.toString(),
      isEnabled: json['is_enabled'] == true || json['is_enabled'] == 1,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'icon': icon,
      'is_enabled': isEnabled,
    };
  }
}

// Classe pour les coupons
class Coupon {
  final int id;
  final String code;
  final String? description;
  final String discountType;
  final double discountValue;
  final double? minOrderAmount;
  final double? maxDiscount;
  final String? validUntil;
  final bool isActive;

  Coupon({
    required this.id,
    required this.code,
    this.description,
    required this.discountType,
    required this.discountValue,
    this.minOrderAmount,
    this.maxDiscount,
    this.validUntil,
    this.isActive = true,
  });

  factory Coupon.fromJson(Map<String, dynamic> json) {
    return Coupon(
      id: _parseInt(json['id']) ?? 0,
      code: json['code']?.toString() ?? '',
      description: json['description']?.toString(),
      discountType: json['discount_type']?.toString() ?? 'fixed',
      discountValue: _parseDouble(json['discount_value']) ?? 0,
      minOrderAmount: _parseDouble(json['min_order_amount']),
      maxDiscount: _parseDouble(json['max_discount']),
      validUntil: json['valid_until']?.toString(),
      isActive: json['is_active'] == true || json['is_active'] == 1,
    );
  }

  static int? _parseInt(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is double) return value.toInt();
    if (value is String) {
      final doubleValue = double.tryParse(value);
      return doubleValue?.toInt();
    }
    return null;
  }

  static double? _parseDouble(dynamic value) {
    if (value == null) return null;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value);
    return null;
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'code': code,
      'description': description,
      'discount_type': discountType,
      'discount_value': discountValue,
      'min_order_amount': minOrderAmount,
      'max_discount': maxDiscount,
      'valid_until': validUntil,
      'is_active': isActive,
    };
  }
}

/// Extension pour obtenir le type de boutique à partir de la catégorie API
extension ShopBoutiqueType on Shop {
  /// Convertit la catégorie API en BoutiqueType
  BoutiqueType get boutiqueType {
    final cat = category.toLowerCase().trim();

    // Restaurant
    if (cat.contains('restaurant') || cat.contains('resto') || cat.contains('restauration')) {
      return BoutiqueType.restaurant;
    }

    // Midi Express / Fast-food
    if (cat.contains('midi') || cat.contains('express') || cat.contains('fast')) {
      return BoutiqueType.midiExpress;
    }

    // Salon de beauté
    if (cat.contains('beauté') || cat.contains('beaute') || cat.contains('beauty')) {
      return BoutiqueType.salonBeaute;
    }

    // Salon de coiffure
    if (cat.contains('coiffure') || cat.contains('hair') || cat.contains('coiffeur')) {
      return BoutiqueType.salonCoiffure;
    }

    // Boutique en ligne (par défaut)
    return BoutiqueType.boutiqueEnLigne;
  }

  /// Vérifie si c'est un restaurant ou midi express
  bool get isRestaurant =>
      boutiqueType == BoutiqueType.restaurant ||
      boutiqueType == BoutiqueType.midiExpress;

  /// Vérifie si c'est un salon (beauté ou coiffure)
  bool get isSalon =>
      boutiqueType == BoutiqueType.salonBeaute ||
      boutiqueType == BoutiqueType.salonCoiffure;

  /// Vérifie si c'est une boutique en ligne
  bool get isShop => boutiqueType == BoutiqueType.boutiqueEnLigne;
}
