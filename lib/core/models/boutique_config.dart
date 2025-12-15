import 'boutique_type.dart';

/// Configuration d'une boutique spécifique
class BoutiqueConfig {
  /// Identifiant unique de la boutique
  final String id;

  /// Nom de la boutique
  final String name;

  /// Description de la boutique
  final String description;

  /// Type de boutique
  final BoutiqueType type;

  /// Chemin vers le logo de la boutique
  final String logoPath;

  /// Numéro de téléphone de la boutique
  final String phoneNumber;

  /// Adresse de la boutique
  final String? address;

  /// Horaires d'ouverture
  final Map<String, String>? openingHours;

  /// URL du lien direct vers la boutique
  final String? directLink;

  /// Données QR code pour accéder à la boutique
  final String? qrCodeData;

  /// Couleur principale de la boutique (hex)
  final String? primaryColor;

  /// Couleur secondaire de la boutique (hex)
  final String? secondaryColor;

  /// Image de fond/bannière
  final String? bannerImagePath;

  /// Email de contact
  final String? email;

  /// Lien WhatsApp
  final String? whatsappLink;

  /// Réseaux sociaux
  final Map<String, String>? socialMedia;

  /// Configuration spécifique selon le type
  final Map<String, dynamic>? typeSpecificConfig;

  const BoutiqueConfig({
    required this.id,
    required this.name,
    required this.description,
    required this.type,
    required this.logoPath,
    required this.phoneNumber,
    this.address,
    this.openingHours,
    this.directLink,
    this.qrCodeData,
    this.primaryColor,
    this.secondaryColor,
    this.bannerImagePath,
    this.email,
    this.whatsappLink,
    this.socialMedia,
    this.typeSpecificConfig,
  });

  /// Crée une configuration depuis un JSON
  factory BoutiqueConfig.fromJson(Map<String, dynamic> json) {
    return BoutiqueConfig(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String,
      type: BoutiqueType.values.firstWhere(
        (e) => e.id == json['type'],
        orElse: () => BoutiqueType.boutiqueEnLigne,
      ),
      logoPath: json['logoPath'] as String,
      phoneNumber: json['phoneNumber'] as String,
      address: json['address'] as String?,
      openingHours: json['openingHours'] != null
          ? Map<String, String>.from(json['openingHours'])
          : null,
      directLink: json['directLink'] as String?,
      qrCodeData: json['qrCodeData'] as String?,
      primaryColor: json['primaryColor'] as String?,
      secondaryColor: json['secondaryColor'] as String?,
      bannerImagePath: json['bannerImagePath'] as String?,
      email: json['email'] as String?,
      whatsappLink: json['whatsappLink'] as String?,
      socialMedia: json['socialMedia'] != null
          ? Map<String, String>.from(json['socialMedia'])
          : null,
      typeSpecificConfig: json['typeSpecificConfig'] as Map<String, dynamic>?,
    );
  }

  /// Convertit la configuration en JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'type': type.id,
      'logoPath': logoPath,
      'phoneNumber': phoneNumber,
      'address': address,
      'openingHours': openingHours,
      'directLink': directLink,
      'qrCodeData': qrCodeData,
      'primaryColor': primaryColor,
      'secondaryColor': secondaryColor,
      'bannerImagePath': bannerImagePath,
      'email': email,
      'whatsappLink': whatsappLink,
      'socialMedia': socialMedia,
      'typeSpecificConfig': typeSpecificConfig,
    };
  }

  /// Copie la configuration avec des modifications
  BoutiqueConfig copyWith({
    String? id,
    String? name,
    String? description,
    BoutiqueType? type,
    String? logoPath,
    String? phoneNumber,
    String? address,
    Map<String, String>? openingHours,
    String? directLink,
    String? qrCodeData,
    String? primaryColor,
    String? secondaryColor,
    String? bannerImagePath,
    String? email,
    String? whatsappLink,
    Map<String, String>? socialMedia,
    Map<String, dynamic>? typeSpecificConfig,
  }) {
    return BoutiqueConfig(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      type: type ?? this.type,
      logoPath: logoPath ?? this.logoPath,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      address: address ?? this.address,
      openingHours: openingHours ?? this.openingHours,
      directLink: directLink ?? this.directLink,
      qrCodeData: qrCodeData ?? this.qrCodeData,
      primaryColor: primaryColor ?? this.primaryColor,
      secondaryColor: secondaryColor ?? this.secondaryColor,
      bannerImagePath: bannerImagePath ?? this.bannerImagePath,
      email: email ?? this.email,
      whatsappLink: whatsappLink ?? this.whatsappLink,
      socialMedia: socialMedia ?? this.socialMedia,
      typeSpecificConfig: typeSpecificConfig ?? this.typeSpecificConfig,
    );
  }
}
