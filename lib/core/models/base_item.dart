/// Classe de base pour tous les articles (produits, plats, services)
abstract class BaseItem {
  /// Identifiant unique
  final String id;

  /// Nom de l'article
  final String name;

  /// Description
  final String description;

  /// Prix en FCFA
  final int price;

  /// Ancien prix (pour les réductions)
  final int? oldPrice;

  /// Pourcentage de réduction
  final int? discount;

  /// Image de l'article
  final String imagePath;

  /// Catégorie
  final String category;

  /// Disponibilité
  final bool isAvailable;

  const BaseItem({
    required this.id,
    required this.name,
    required this.description,
    required this.price,
    this.oldPrice,
    this.discount,
    required this.imagePath,
    required this.category,
    this.isAvailable = true,
  });

  /// Calcule l'économie réalisée
  int get savings => oldPrice != null ? oldPrice! - price : 0;

  /// Vérifie s'il y a une réduction
  bool get hasDiscount => discount != null && discount! > 0;

  /// Convertit en Map
  Map<String, dynamic> toJson();

  /// Crée une instance depuis JSON
  static BaseItem fromJson(Map<String, dynamic> json, String type) {
    switch (type) {
      case 'product':
        return Product.fromJson(json);
      case 'dish':
        return Dish.fromJson(json);
      case 'service':
        return Service.fromJson(json);
      default:
        throw Exception('Type d\'article inconnu: $type');
    }
  }
}

/// Produit pour boutique en ligne
class Product extends BaseItem {
  /// Stock disponible
  final int stock;

  /// Tailles disponibles (si applicable)
  final List<String>? sizes;

  /// Couleurs disponibles (si applicable)
  final List<String>? colors;

  /// Matériau (si applicable)
  final String? material;

  const Product({
    required super.id,
    required super.name,
    required super.description,
    required super.price,
    super.oldPrice,
    super.discount,
    required super.imagePath,
    required super.category,
    super.isAvailable,
    required this.stock,
    this.sizes,
    this.colors,
    this.material,
  });

  @override
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'price': price,
      'oldPrice': oldPrice,
      'discount': discount,
      'imagePath': imagePath,
      'category': category,
      'isAvailable': isAvailable,
      'stock': stock,
      'sizes': sizes,
      'colors': colors,
      'material': material,
      'type': 'product',
    };
  }

  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String,
      price: json['price'] as int,
      oldPrice: json['oldPrice'] as int?,
      discount: json['discount'] as int?,
      imagePath: json['imagePath'] as String,
      category: json['category'] as String,
      isAvailable: json['isAvailable'] as bool? ?? true,
      stock: json['stock'] as int,
      sizes: json['sizes'] != null ? List<String>.from(json['sizes']) : null,
      colors: json['colors'] != null ? List<String>.from(json['colors']) : null,
      material: json['material'] as String?,
    );
  }

  Product copyWith({
    String? id,
    String? name,
    String? description,
    int? price,
    int? oldPrice,
    int? discount,
    String? imagePath,
    String? category,
    bool? isAvailable,
    int? stock,
    List<String>? sizes,
    List<String>? colors,
    String? material,
  }) {
    return Product(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      price: price ?? this.price,
      oldPrice: oldPrice ?? this.oldPrice,
      discount: discount ?? this.discount,
      imagePath: imagePath ?? this.imagePath,
      category: category ?? this.category,
      isAvailable: isAvailable ?? this.isAvailable,
      stock: stock ?? this.stock,
      sizes: sizes ?? this.sizes,
      colors: colors ?? this.colors,
      material: material ?? this.material,
    );
  }
}

/// Plat pour restaurant et midi express
class Dish extends BaseItem {
  /// Temps de préparation en minutes
  final int preparationTime;

  /// Disponibilité actuelle (en stock)
  final int stock;

  /// Options de préférences (épicé, non épicé, etc.)
  final List<DishPreference> preferences;

  /// Allergènes
  final List<String>? allergens;

  /// Ingrédients principaux
  final List<String>? mainIngredients;

  /// Valeur nutritionnelle (calories)
  final int? calories;

  const Dish({
    required super.id,
    required super.name,
    required super.description,
    required super.price,
    super.oldPrice,
    super.discount,
    required super.imagePath,
    required super.category,
    super.isAvailable,
    required this.preparationTime,
    required this.stock,
    this.preferences = const [],
    this.allergens,
    this.mainIngredients,
    this.calories,
  });

  @override
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'price': price,
      'oldPrice': oldPrice,
      'discount': discount,
      'imagePath': imagePath,
      'category': category,
      'isAvailable': isAvailable,
      'preparationTime': preparationTime,
      'stock': stock,
      'preferences': preferences.map((p) => p.toJson()).toList(),
      'allergens': allergens,
      'mainIngredients': mainIngredients,
      'calories': calories,
      'type': 'dish',
    };
  }

  factory Dish.fromJson(Map<String, dynamic> json) {
    return Dish(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String,
      price: json['price'] as int,
      oldPrice: json['oldPrice'] as int?,
      discount: json['discount'] as int?,
      imagePath: json['imagePath'] as String,
      category: json['category'] as String,
      isAvailable: json['isAvailable'] as bool? ?? true,
      preparationTime: json['preparationTime'] as int,
      stock: json['stock'] as int,
      preferences: json['preferences'] != null
          ? (json['preferences'] as List)
              .map((p) => DishPreference.fromJson(p))
              .toList()
          : [],
      allergens: json['allergens'] != null
          ? List<String>.from(json['allergens'])
          : null,
      mainIngredients: json['mainIngredients'] != null
          ? List<String>.from(json['mainIngredients'])
          : null,
      calories: json['calories'] as int?,
    );
  }
}

/// Préférence pour un plat
class DishPreference {
  final String id;
  final String label;
  final String icon;

  const DishPreference({
    required this.id,
    required this.label,
    required this.icon,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'label': label,
      'icon': icon,
    };
  }

  factory DishPreference.fromJson(Map<String, dynamic> json) {
    return DishPreference(
      id: json['id'] as String,
      label: json['label'] as String,
      icon: json['icon'] as String,
    );
  }

  // Préférences prédéfinies
  static const spicy = DishPreference(
    id: 'spicy',
    label: 'Épicé',
    icon: '🌶️',
  );

  static const notSpicy = DishPreference(
    id: 'not_spicy',
    label: 'Non épicé',
    icon: '✨',
  );

  static const vegetarian = DishPreference(
    id: 'vegetarian',
    label: 'Végétarien',
    icon: '🥗',
  );

  static const vegan = DishPreference(
    id: 'vegan',
    label: 'Vegan',
    icon: '🌱',
  );

  static const glutenFree = DishPreference(
    id: 'gluten_free',
    label: 'Sans gluten',
    icon: '🌾',
  );

  static const customRequest = DishPreference(
    id: 'custom',
    label: 'Autre demande spécifique',
    icon: '📝',
  );
}

/// Service pour salon de beauté et salon de coiffure
class Service extends BaseItem {
  /// Durée du service en minutes
  final int durationMinutes;

  /// Spécialiste requis
  final String? specialistName;

  /// Niveau de difficulté (1-5)
  final int? difficultyLevel;

  /// Services complémentaires suggérés
  final List<String>? suggestedServices;

  const Service({
    required super.id,
    required super.name,
    required super.description,
    required super.price,
    super.oldPrice,
    super.discount,
    required super.imagePath,
    required super.category,
    super.isAvailable,
    required this.durationMinutes,
    this.specialistName,
    this.difficultyLevel,
    this.suggestedServices,
  });

  @override
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'price': price,
      'oldPrice': oldPrice,
      'discount': discount,
      'imagePath': imagePath,
      'category': category,
      'isAvailable': isAvailable,
      'durationMinutes': durationMinutes,
      'specialistName': specialistName,
      'difficultyLevel': difficultyLevel,
      'suggestedServices': suggestedServices,
      'type': 'service',
    };
  }

  factory Service.fromJson(Map<String, dynamic> json) {
    return Service(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String,
      price: json['price'] as int,
      oldPrice: json['oldPrice'] as int?,
      discount: json['discount'] as int?,
      imagePath: json['imagePath'] as String,
      category: json['category'] as String,
      isAvailable: json['isAvailable'] as bool? ?? true,
      durationMinutes: json['durationMinutes'] as int,
      specialistName: json['specialistName'] as String?,
      difficultyLevel: json['difficultyLevel'] as int?,
      suggestedServices: json['suggestedServices'] != null
          ? List<String>.from(json['suggestedServices'])
          : null,
    );
  }
}
