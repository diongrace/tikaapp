import 'package:http/http.dart' as http;
import 'dart:convert';
import './utils/api_endpoint.dart';
import './models/client_model.dart';
import '../core/services/storage_service.dart';
import './notification_service.dart';

/// Service d'authentification client pour TIKA
///
/// Gère l'inscription, la connexion, la vérification OTP et la déconnexion.
/// L'authentification est OPTIONNELLE - les clients peuvent utiliser l'app
/// sans compte, mais un compte permet de recevoir les notifications et
/// synchroniser les données.
class AuthService {
  static String? _authToken;
  static Client? _currentClient;
  static bool _initialized = false;

  // ============================================================
  // GETTERS
  // ============================================================

  /// Vérifier si l'utilisateur est authentifié
  static bool get isAuthenticated => _authToken != null && _authToken!.isNotEmpty;

  /// Récupérer le client connecté (null si non connecté)
  static Client? get currentClient => _currentClient;

  /// Récupérer le token d'authentification
  static String? get authToken => _authToken;

  /// Headers avec authentification Bearer
  static Map<String, String> get _headers => {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
    if (_authToken != null) 'Authorization': 'Bearer $_authToken',
  };

  // ============================================================
  // INITIALISATION
  // ============================================================

  /// Initialiser le service au démarrage de l'app
  /// Charge le token et les infos client depuis le stockage local
  static Future<void> initialize() async {
    if (_initialized) return;

    print('🔐 [AuthService] Initialisation...');

    try {
      // Charger le token depuis le stockage
      final token = await StorageService.getAuthToken();
      if (token != null && token.isNotEmpty) {
        _authToken = token;

        // Charger les infos client depuis le stockage
        final clientData = await StorageService.getAuthClient();
        if (clientData != null) {
          _currentClient = Client.fromJson(clientData);
          print('👤 [AuthService] Client restauré: ${_currentClient!.name}');
        }

        // Mettre à jour le token dans NotificationService
        NotificationService.setAuthToken(_authToken);

        // Optionnel: Vérifier si le token est toujours valide
        // await _validateToken();
      }

      _initialized = true;
      print('✅ [AuthService] Initialisé - Authentifié: $isAuthenticated');
    } catch (e) {
      print('❌ [AuthService] Erreur initialisation: $e');
      _initialized = true;
    }
  }

  // ============================================================
  // INSCRIPTION
  // ============================================================

  /// Inscrire un nouveau client
  ///
  /// [name] - Nom complet du client
  /// [phone] - Numéro de téléphone (sans indicatif)
  /// [password] - Mot de passe (min 6 caractères)
  /// [email] - Email (optionnel)
  static Future<AuthResponse> register({
    required String name,
    required String phone,
    required String password,
    String? email,
  }) async {
    print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    print('📤 REGISTER');
    print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    print('📱 Phone: $phone');
    print('👤 Name: $name');

    try {
      final body = {
        'name': name,
        'phone': _formatPhone(phone),
        'password': password,
        'password_confirmation': password,
      };
      if (email != null && email.isNotEmpty) {
        body['email'] = email;
      }

      final response = await http.post(
        Uri.parse(Endpoints.clientRegister),
        headers: {'Content-Type': 'application/json', 'Accept': 'application/json'},
        body: jsonEncode(body),
      );

      print('📥 Response Status: ${response.statusCode}');
      print('📥 Response Body: ${response.body}');

      final data = jsonDecode(response.body);

      if (response.statusCode == 200 || response.statusCode == 201) {
        final authResponse = AuthResponse.fromJson(data);

        if (authResponse.success && authResponse.token != null) {
          await _saveAuthData(authResponse.token!, authResponse.client);
          print('✅ Inscription réussie');
        }

        print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
        return authResponse;
      } else {
        print('❌ Erreur inscription: ${response.statusCode}');
        print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
        return AuthResponse.fromJson(data);
      }
    } catch (e) {
      print('❌ Exception: $e');
      print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
      return AuthResponse(
        success: false,
        message: 'Erreur de connexion. Vérifiez votre connexion internet.',
      );
    }
  }

  // ============================================================
  // CONNEXION
  // ============================================================

  /// Connecter un client existant
  ///
  /// [phone] - Numéro de téléphone
  /// [password] - Mot de passe
  static Future<AuthResponse> login({
    required String phone,
    required String password,
  }) async {
    print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    print('📤 LOGIN');
    print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    print('📱 Phone: $phone');

    try {
      final response = await http.post(
        Uri.parse(Endpoints.clientLogin),
        headers: {'Content-Type': 'application/json', 'Accept': 'application/json'},
        body: jsonEncode({
          'phone': _formatPhone(phone),
          'password': password,
        }),
      );

      print('📥 Response Status: ${response.statusCode}');
      print('📥 Response Body: ${response.body}');

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        final authResponse = AuthResponse.fromJson(data);

        if (authResponse.success && authResponse.token != null) {
          await _saveAuthData(authResponse.token!, authResponse.client);
          print('✅ Connexion réussie');
        }

        print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
        return authResponse;
      } else {
        print('❌ Erreur connexion: ${response.statusCode}');
        print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
        return AuthResponse.fromJson(data);
      }
    } catch (e) {
      print('❌ Exception: $e');
      print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
      return AuthResponse(
        success: false,
        message: 'Erreur de connexion. Vérifiez votre connexion internet.',
      );
    }
  }

  // ============================================================
  // OTP (VÉRIFICATION TÉLÉPHONE)
  // ============================================================

  /// Envoyer un code OTP au numéro de téléphone
  ///
  /// [phone] - Numéro de téléphone
  /// [type] - Type d'OTP: 'register', 'login', 'reset_password'
  static Future<OtpResponse> sendOtp({
    required String phone,
    String type = 'register',
  }) async {
    print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    print('📤 SEND OTP');
    print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    print('📱 Phone: $phone');
    print('📋 Type: $type');

    try {
      final response = await http.post(
        Uri.parse(Endpoints.clientSendOtp),
        headers: {'Content-Type': 'application/json', 'Accept': 'application/json'},
        body: jsonEncode({
          'phone': _formatPhone(phone),
          'type': type,
        }),
      );

      print('📥 Response Status: ${response.statusCode}');
      print('📥 Response Body: ${response.body}');

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        print('✅ OTP envoyé');
        print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
        return OtpResponse.fromJson(data);
      } else {
        print('❌ Erreur envoi OTP: ${response.statusCode}');
        print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
        return OtpResponse(
          success: false,
          message: data['message'] ?? 'Erreur lors de l\'envoi du code',
        );
      }
    } catch (e) {
      print('❌ Exception: $e');
      print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
      return OtpResponse(
        success: false,
        message: 'Erreur de connexion. Vérifiez votre connexion internet.',
      );
    }
  }

  /// Vérifier le code OTP
  ///
  /// [phone] - Numéro de téléphone
  /// [otp] - Code OTP à 6 chiffres
  /// [type] - Type d'OTP: 'register', 'login', 'reset_password'
  static Future<AuthResponse> verifyOtp({
    required String phone,
    required String otp,
    String type = 'register',
  }) async {
    print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    print('📤 VERIFY OTP');
    print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    print('📱 Phone: $phone');
    print('🔢 OTP: $otp');
    print('📋 Type: $type');

    try {
      final response = await http.post(
        Uri.parse(Endpoints.clientVerifyOtp),
        headers: {'Content-Type': 'application/json', 'Accept': 'application/json'},
        body: jsonEncode({
          'phone': _formatPhone(phone),
          'otp': otp,
          'type': type,
        }),
      );

      print('📥 Response Status: ${response.statusCode}');
      print('📥 Response Body: ${response.body}');

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        final authResponse = AuthResponse.fromJson(data);

        // Si la vérification retourne un token, on connecte le client
        if (authResponse.success && authResponse.token != null) {
          await _saveAuthData(authResponse.token!, authResponse.client);
          print('✅ OTP vérifié et client connecté');
        } else {
          print('✅ OTP vérifié');
        }

        print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
        return authResponse;
      } else {
        print('❌ Erreur vérification OTP: ${response.statusCode}');
        print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
        return AuthResponse.fromJson(data);
      }
    } catch (e) {
      print('❌ Exception: $e');
      print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
      return AuthResponse(
        success: false,
        message: 'Erreur de connexion. Vérifiez votre connexion internet.',
      );
    }
  }

  // ============================================================
  // MOT DE PASSE OUBLIÉ
  // ============================================================

  /// Demander la réinitialisation du mot de passe
  static Future<OtpResponse> forgotPassword({required String phone}) async {
    print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    print('📤 FORGOT PASSWORD');
    print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');

    try {
      final response = await http.post(
        Uri.parse(Endpoints.clientForgotPassword),
        headers: {'Content-Type': 'application/json', 'Accept': 'application/json'},
        body: jsonEncode({'phone': _formatPhone(phone)}),
      );

      print('📥 Response Status: ${response.statusCode}');

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        print('✅ Code de réinitialisation envoyé');
        print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
        return OtpResponse.fromJson(data);
      } else {
        print('❌ Erreur: ${response.statusCode}');
        print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
        return OtpResponse(
          success: false,
          message: data['message'] ?? 'Erreur lors de l\'envoi du code',
        );
      }
    } catch (e) {
      print('❌ Exception: $e');
      print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
      return OtpResponse(
        success: false,
        message: 'Erreur de connexion. Vérifiez votre connexion internet.',
      );
    }
  }

  /// Réinitialiser le mot de passe avec le code OTP
  static Future<AuthResponse> resetPassword({
    required String phone,
    required String otp,
    required String newPassword,
  }) async {
    print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    print('📤 RESET PASSWORD');
    print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');

    try {
      final response = await http.post(
        Uri.parse(Endpoints.clientResetPassword),
        headers: {'Content-Type': 'application/json', 'Accept': 'application/json'},
        body: jsonEncode({
          'phone': _formatPhone(phone),
          'otp': otp,
          'password': newPassword,
          'password_confirmation': newPassword,
        }),
      );

      print('📥 Response Status: ${response.statusCode}');

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        print('✅ Mot de passe réinitialisé');
        print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
        return AuthResponse.fromJson(data);
      } else {
        print('❌ Erreur: ${response.statusCode}');
        print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
        return AuthResponse.fromJson(data);
      }
    } catch (e) {
      print('❌ Exception: $e');
      print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
      return AuthResponse(
        success: false,
        message: 'Erreur de connexion. Vérifiez votre connexion internet.',
      );
    }
  }

  // ============================================================
  // PROFIL
  // ============================================================

  /// Récupérer le profil du client connecté
  static Future<Client?> getProfile() async {
    if (!isAuthenticated) {
      print('⚠️ [AuthService] Non authentifié');
      return null;
    }

    print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    print('📤 GET PROFILE');
    print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');

    try {
      final response = await http.get(
        Uri.parse(Endpoints.clientProfile),
        headers: _headers,
      );

      print('📥 Response Status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final clientData = data['data'] ?? data['client'] ?? data['user'] ?? data;
        _currentClient = Client.fromJson(clientData);
        await StorageService.saveAuthClient(_currentClient!.toJson());
        print('✅ Profil récupéré: ${_currentClient!.name}');
        print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
        return _currentClient;
      } else if (response.statusCode == 401) {
        // Token expiré ou invalide
        print('⚠️ Token invalide - Déconnexion');
        await logout();
        return null;
      }
    } catch (e) {
      print('❌ Exception: $e');
    }

    print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    return _currentClient;
  }

  /// Mettre à jour le profil du client
  ///
  /// [name] - Nouveau nom (optionnel)
  /// [email] - Nouvel email (optionnel)
  static Future<Client?> updateProfile({
    String? name,
    String? email,
  }) async {
    if (!isAuthenticated) {
      print('⚠️ [AuthService] Non authentifié');
      return null;
    }

    print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    print('📤 UPDATE PROFILE');
    print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');

    try {
      final body = <String, dynamic>{};
      if (name != null) body['name'] = name;
      if (email != null) body['email'] = email;

      final response = await http.put(
        Uri.parse(Endpoints.clientProfile),
        headers: _headers,
        body: jsonEncode(body),
      );

      print('📥 Response Status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final clientData = data['data'] ?? data['client'] ?? data['user'] ?? data;
        _currentClient = Client.fromJson(clientData);
        await StorageService.saveAuthClient(_currentClient!.toJson());
        print('✅ Profil mis à jour: ${_currentClient!.name}');
        print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
        return _currentClient;
      }
    } catch (e) {
      print('❌ Exception: $e');
    }

    print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    return null;
  }

  // ============================================================
  // DÉCONNEXION
  // ============================================================

  /// Déconnecter le client
  static Future<void> logout() async {
    print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    print('📤 LOGOUT');
    print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');

    try {
      // Appeler l'API de déconnexion si authentifié
      if (isAuthenticated) {
        await http.post(
          Uri.parse(Endpoints.clientLogout),
          headers: _headers,
        );
      }
    } catch (e) {
      print('⚠️ Erreur API logout (ignorée): $e');
    }

    // Nettoyer les données locales
    _authToken = null;
    _currentClient = null;

    // Supprimer les données du stockage
    await StorageService.clearAuthData();

    // Notifier NotificationService
    NotificationService.setAuthToken(null);

    print('✅ Déconnexion réussie');
    print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
  }

  // ============================================================
  // HELPERS PRIVÉS
  // ============================================================

  /// Sauvegarder les données d'authentification
  static Future<void> _saveAuthData(String token, Client? client) async {
    _authToken = token;
    _currentClient = client;

    // Sauvegarder dans le stockage local
    await StorageService.saveAuthToken(token);
    if (client != null) {
      await StorageService.saveAuthClient(client.toJson());

      // Synchroniser avec les infos client existantes
      await StorageService.saveCustomerInfo(
        name: client.name,
        phone: client.phone,
        email: client.email,
      );
    }

    // Mettre à jour NotificationService
    NotificationService.setAuthToken(token);
  }

  /// Formater le numéro de téléphone (supprimer espaces et indicatif si présent)
  static String _formatPhone(String phone) {
    // Supprimer les espaces
    String formatted = phone.replaceAll(' ', '');

    // Si le numéro commence par +225, le supprimer
    if (formatted.startsWith('+225')) {
      formatted = formatted.substring(4);
    }
    // Si le numéro commence par 00225
    if (formatted.startsWith('00225')) {
      formatted = formatted.substring(5);
    }

    return formatted;
  }
}
