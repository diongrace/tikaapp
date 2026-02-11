/// Modele de donnees pour un client authentifie
/// Utilise par AuthService pour gerer les informations du client connecte
class Client {
  final int id;
  final String? firstName;
  final String? lastName;
  final String? fullName;
  final String phone;
  final String? email;
  final String? profilePhoto;
  final String? birthDate;
  final String? defaultAddress;
  final bool isPhoneVerified;
  final bool isEmailVerified;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  Client({
    required this.id,
    this.firstName,
    this.lastName,
    this.fullName,
    required this.phone,
    this.email,
    this.profilePhoto,
    this.birthDate,
    this.defaultAddress,
    this.isPhoneVerified = false,
    this.isEmailVerified = false,
    this.createdAt,
    this.updatedAt,
  });

  /// Getter calculé pour le nom complet (compatibilité)
  String get name {
    if (fullName != null && fullName!.isNotEmpty) return fullName!;
    final parts = <String>[];
    if (firstName != null && firstName!.isNotEmpty) parts.add(firstName!);
    if (lastName != null && lastName!.isNotEmpty) parts.add(lastName!);
    if (parts.isNotEmpty) return parts.join(' ');
    return '';
  }

  /// Creer un Client depuis une reponse JSON de l'API
  factory Client.fromJson(Map<String, dynamic> json) {
    return Client(
      id: json['id'] ?? 0,
      firstName: json['first_name'],
      lastName: json['last_name'],
      fullName: json['full_name'] ?? json['name'],
      phone: json['phone'] ?? '',
      email: json['email'],
      profilePhoto: json['profile_photo'],
      birthDate: json['birth_date'],
      defaultAddress: json['default_address'] is Map
          ? (json['default_address'] as Map).toString()
          : json['default_address']?.toString(),
      isPhoneVerified: json['is_phone_verified'] == true || json['phone_verified_at'] != null,
      isEmailVerified: json['is_email_verified'] == true || json['email_verified_at'] != null,
      createdAt: json['created_at'] != null ? DateTime.tryParse(json['created_at'].toString()) : null,
      updatedAt: json['updated_at'] != null ? DateTime.tryParse(json['updated_at'].toString()) : null,
    );
  }

  /// Convertir le Client en JSON pour stockage local
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'first_name': firstName,
      'last_name': lastName,
      'full_name': fullName,
      'name': name,
      'phone': phone,
      'email': email,
      'profile_photo': profilePhoto,
      'birth_date': birthDate,
      'default_address': defaultAddress,
      'is_phone_verified': isPhoneVerified,
      'is_email_verified': isEmailVerified,
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }

  /// Creer une copie du Client avec des modifications
  Client copyWith({
    int? id,
    String? firstName,
    String? lastName,
    String? fullName,
    String? phone,
    String? email,
    String? profilePhoto,
    String? birthDate,
    String? defaultAddress,
    bool? isPhoneVerified,
    bool? isEmailVerified,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Client(
      id: id ?? this.id,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      fullName: fullName ?? this.fullName,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      profilePhoto: profilePhoto ?? this.profilePhoto,
      birthDate: birthDate ?? this.birthDate,
      defaultAddress: defaultAddress ?? this.defaultAddress,
      isPhoneVerified: isPhoneVerified ?? this.isPhoneVerified,
      isEmailVerified: isEmailVerified ?? this.isEmailVerified,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  /// Obtenir les initiales du nom pour l'avatar
  String get initials {
    final n = name;
    if (n.isEmpty) return '?';
    final parts = n.trim().split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return n[0].toUpperCase();
  }

  /// Obtenir le numero de telephone formate
  String get formattedPhone {
    if (phone.isEmpty) return '';
    if (phone.startsWith('+225')) return phone;
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

/// Reponse d'authentification de l'API
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
    // L'API peut retourner les donnees a la racine ou dans un objet 'data'
    // Ex: {"success":true,"data":{"user":{...},"token":"..."}}
    // ou: {"success":true,"token":"...","client":{...}}
    final data = json['data'] as Map<String, dynamic>? ?? {};

    return AuthResponse(
      success: json['success'] == true,
      message: json['message'],
      token: json['token'] ?? json['access_token']
          ?? data['token'] ?? data['access_token'],
      client: _extractClient(json, data),
      errors: json['errors'],
    );
  }

  /// Extraire le client depuis la racine ou depuis 'data'
  static Client? _extractClient(
      Map<String, dynamic> json, Map<String, dynamic> data) {
    // Chercher dans la racine
    if (json['client'] != null) return Client.fromJson(json['client']);
    if (json['user'] != null) return Client.fromJson(json['user']);
    // Chercher dans 'data'
    if (data['client'] != null) return Client.fromJson(data['client']);
    if (data['user'] != null) return Client.fromJson(data['user']);
    return null;
  }

  /// Message d'erreur formate
  String get errorMessage {
    if (message != null) return message!;
    if (errors != null && errors!.isNotEmpty) {
      final firstError = errors!.values.first;
      if (firstError is List && firstError.isNotEmpty) {
        return firstError.first.toString();
      }
      return firstError.toString();
    }
    return 'Une erreur est survenue';
  }
}

/// Reponse OTP de l'API
class OtpResponse {
  final bool success;
  final String? message;
  final int? expiresIn;

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
