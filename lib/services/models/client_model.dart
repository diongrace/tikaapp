/// Modèle de données pour un client authentifié
/// Utilisé par AuthService pour gérer les informations du client connecté
class Client {
  final int id;
  final String name;
  final String phone;
  final String? email;
  final String? profilePhoto;
  final bool isPhoneVerified;
  final bool isEmailVerified;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  Client({
    required this.id,
    required this.name,
    required this.phone,
    this.email,
    this.profilePhoto,
    this.isPhoneVerified = false,
    this.isEmailVerified = false,
    this.createdAt,
    this.updatedAt,
  });

  /// Créer un Client depuis une réponse JSON de l'API
  factory Client.fromJson(Map<String, dynamic> json) {
    return Client(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      phone: json['phone'] ?? '',
      email: json['email'],
      profilePhoto: json['profile_photo'],
      isPhoneVerified: json['is_phone_verified'] == true || json['phone_verified_at'] != null,
      isEmailVerified: json['is_email_verified'] == true || json['email_verified_at'] != null,
      createdAt: json['created_at'] != null ? DateTime.tryParse(json['created_at']) : null,
      updatedAt: json['updated_at'] != null ? DateTime.tryParse(json['updated_at']) : null,
    );
  }

  /// Convertir le Client en JSON pour stockage local
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'phone': phone,
      'email': email,
      'profile_photo': profilePhoto,
      'is_phone_verified': isPhoneVerified,
      'is_email_verified': isEmailVerified,
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }

  /// Créer une copie du Client avec des modifications
  Client copyWith({
    int? id,
    String? name,
    String? phone,
    String? email,
    String? profilePhoto,
    bool? isPhoneVerified,
    bool? isEmailVerified,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Client(
      id: id ?? this.id,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      profilePhoto: profilePhoto ?? this.profilePhoto,
      isPhoneVerified: isPhoneVerified ?? this.isPhoneVerified,
      isEmailVerified: isEmailVerified ?? this.isEmailVerified,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  /// Obtenir les initiales du nom pour l'avatar
  String get initials {
    if (name.isEmpty) return '?';
    final parts = name.trim().split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return name[0].toUpperCase();
  }

  /// Obtenir le numéro de téléphone formaté
  String get formattedPhone {
    if (phone.isEmpty) return '';
    // Si le numéro commence par +225, on l'affiche tel quel
    if (phone.startsWith('+225')) return phone;
    // Sinon on ajoute l'indicatif
    return '+225 $phone';
  }

  @override
  String toString() {
    return 'Client(id: $id, name: $name, phone: $phone, email: $email)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Client && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}

/// Réponse d'authentification de l'API
class AuthResponse {
  final bool success;
  final String? message;
  final String? token;
  final Client? client;
  final Map<String, dynamic>? errors;

  AuthResponse({
    required this.success,
    this.message,
    this.token,
    this.client,
    this.errors,
  });

  factory AuthResponse.fromJson(Map<String, dynamic> json) {
    return AuthResponse(
      success: json['success'] == true,
      message: json['message'],
      token: json['token'] ?? json['access_token'],
      client: json['client'] != null || json['user'] != null
          ? Client.fromJson(json['client'] ?? json['user'])
          : null,
      errors: json['errors'],
    );
  }

  /// Message d'erreur formaté
  String get errorMessage {
    if (message != null) return message!;
    if (errors != null && errors!.isNotEmpty) {
      // Récupérer la première erreur
      final firstError = errors!.values.first;
      if (firstError is List && firstError.isNotEmpty) {
        return firstError.first.toString();
      }
      return firstError.toString();
    }
    return 'Une erreur est survenue';
  }
}

/// Réponse OTP de l'API
class OtpResponse {
  final bool success;
  final String? message;
  final int? expiresIn; // Durée de validité en secondes

  OtpResponse({
    required this.success,
    this.message,
    this.expiresIn,
  });

  factory OtpResponse.fromJson(Map<String, dynamic> json) {
    return OtpResponse(
      success: json['success'] == true,
      message: json['message'],
      expiresIn: json['expires_in'],
    );
  }
}
