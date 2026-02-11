class Product {
  final int id;
  final String name;
  final String? description;
  final int? price; // Prix nullable - si null, l'API n'a pas fourni de prix
  final int? comparePrice;
  final int stockQuantity;
  final bool isAvailable;
  final bool isFeatured;
  final int? cookingTime;
  final ProductCategory? category;
  final List<ProductImage>? images;
  final String? primaryImageUrl;
  final List<ProductPortion>? portions;
  final bool hasPortions;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  Product({
    required this.id,
    required this.name,
    this.description,
    this.price, // Pas required, peut être null
    this.comparePrice,
    required this.stockQuantity,
    this.isAvailable = true,
    this.isFeatured = false,
    this.cookingTime,
    this.category,
    this.images,
    this.primaryImageUrl,
    this.portions,
    this.hasPortions = false,
    this.createdAt,
    this.updatedAt,
  });

  factory Product.fromJson(Map<String, dynamic> json) {
    final parsedPrice = _parseInt(json['price']);
    final parsedComparePrice = _parseInt(json['compare_price']);

    // Debug: Afficher les valeurs brutes de l'API pour détecter les incohérences
    if (parsedComparePrice != null) {
      print('🔍 Produit "${json['name']}": price=${parsedPrice}, compare_price=${parsedComparePrice} (brut: ${json['compare_price']})');
      if (parsedPrice != null && parsedComparePrice <= parsedPrice) {
        print('⚠️ Incohérence: compare_price (${parsedComparePrice}) <= price (${parsedPrice}) - compare_price ignoré');
      }
    }

    return Product(
      id: _parseInt(json['id']) ?? 0,
      name: json['name']?.toString() ?? '',
      description: json['description']?.toString(),
      price: parsedPrice, // Pas de valeur par défaut - null si l'API ne fournit pas de prix
      // N'utiliser compare_price que s'il est strictement supérieur au prix actuel
      comparePrice: (parsedComparePrice != null && parsedPrice != null && parsedComparePrice > parsedPrice)
          ? parsedComparePrice
          : null,
      stockQuantity: _parseInt(json['stock_quantity']) ?? 0,
      isAvailable: json['is_available'] == true || json['is_available'] == 1,
      isFeatured: json['is_featured'] == true || json['is_featured'] == 1,
      cookingTime: _parseInt(json['cooking_time']),
      category: json['category'] != null
          ? ProductCategory.fromJson(json['category'])
          : null,
      images: json['images'] != null
          ? (json['images'] as List)
              .map((e) => ProductImage.fromJson(e))
              .toList()
          : null,
      primaryImageUrl: json['primary_image_url']?.toString(),
      portions: json['portions'] != null
          ? (json['portions'] as List)
              .map((e) => ProductPortion.fromJson(e))
              .toList()
          : null,
      hasPortions: json['has_portions'] == true || json['has_portions'] == 1,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'].toString())
          : null,
      updatedAt: json['updated_at'] != null
          ? DateTime.tryParse(json['updated_at'].toString())
          : null,
    );
  }

  // Helper pour convertir les valeurs en int de manière sécurisée
  static int? _parseInt(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is double) return value.toInt();
    if (value is String) {
      // Gérer les strings avec décimales comme "850000.00"
      final doubleValue = double.tryParse(value);
      return doubleValue?.toInt();
    }
    return null;
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'price': price,
      'compare_price': comparePrice,
      'stock_quantity': stockQuantity,
      'is_available': isAvailable,
      'is_featured': isFeatured,
      'cooking_time': cookingTime,
      'category': category?.toJson(),
      'images': images?.map((e) => e.toJson()).toList(),
      'primary_image_url': primaryImageUrl,
      'portions': portions?.map((e) => e.toJson()).toList(),
      'has_portions': hasPortions,
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }

  // Calculer le pourcentage de réduction
  int? get discountPercentage {
    if (price != null && comparePrice != null && comparePrice! > price!) {
      return (((comparePrice! - price!) / comparePrice!) * 100).round();
    }
    return null;
  }

  // Vérifier si le produit est en promotion
  bool get isOnSale => price != null && comparePrice != null && comparePrice! > price!;
}

// Classe pour les catégories de produits
class ProductCategory {
  final int id;
  final String name;
  final String? description;
  final String? color;
  final String? image;
  final int? productsCount;

  ProductCategory({
    required this.id,
    required this.name,
    this.description,
    this.color,
    this.image,
    this.productsCount,
  });

  factory ProductCategory.fromJson(Map<String, dynamic> json) {
    return ProductCategory(
      id: _parseInt(json['id']) ?? 0,
      name: json['name']?.toString() ?? '',
      description: json['description']?.toString(),
      color: json['color']?.toString(),
      image: json['image']?.toString(),
      productsCount: _parseInt(json['products_count']),
    );
  }

  static int? _parseInt(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is double) return value.toInt();
    if (value is String) {
      // Gérer les strings avec décimales comme "850000.00"
      final doubleValue = double.tryParse(value);
      return doubleValue?.toInt();
    }
    return null;
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'color': color,
      'image': image,
      'products_count': productsCount,
    };
  }
}

// Classe pour les images de produits
class ProductImage {
  final int id;
  final String url;
  final bool isPrimary;

  ProductImage({
    required this.id,
    required this.url,
    this.isPrimary = false,
  });

  factory ProductImage.fromJson(Map<String, dynamic> json) {
    return ProductImage(
      id: _parseInt(json['id']) ?? 0,
      url: json['url']?.toString() ?? '',
      isPrimary: json['is_primary'] == true || json['is_primary'] == 1,
    );
  }

  static int? _parseInt(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is double) return value.toInt();
    if (value is String) {
      // Gérer les strings avec décimales comme "850000.00"
      final doubleValue = double.tryParse(value);
      return doubleValue?.toInt();
    }
    return null;
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'url': url,
      'is_primary': isPrimary,
    };
  }
}

// Classe pour les portions de produits
class ProductPortion {
  final int id;
  final String name;
  final int? price; // Prix nullable - si null, l'API n'a pas fourni de prix
  final String? description;

  ProductPortion({
    required this.id,
    required this.name,
    this.price, // Pas required, peut être null
    this.description,
  });

  factory ProductPortion.fromJson(Map<String, dynamic> json) {
    return ProductPortion(
      id: _parseInt(json['id']) ?? 0,
      name: json['name']?.toString() ?? '',
      price: _parseInt(json['price']), // Pas de valeur par défaut - null si l'API ne fournit pas de prix
      description: json['description']?.toString(),
    );
  }

  static int? _parseInt(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is double) return value.toInt();
    if (value is String) {
      // Gérer les strings avec décimales comme "850000"
      final doubleValue = double.tryParse(value);
      return doubleValue?.toInt();
    }
    return null;
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'price': price,
      'description': description,
    };
  }
}
