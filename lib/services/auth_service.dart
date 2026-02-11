import 'package:http/http.dart' as http;
import 'dart:convert';
import './utils/api_endpoint.dart';
import './models/client_model.dart';
import '../core/services/storage_service.dart';
import './notification_service.dart';
import './push_notification_service.dart';

/// Service d'authentification client pour TIKA
///
/// Gere l'inscription, la connexion, la verification OTP et la deconnexion.
/// L'authentification est OPTIONNELLE - les clients peuvent utiliser l'app
/// sans compte, mais un compte permet de recevoir les notifications et
/// synchroniser les donnees.
class AuthService {
  static String? _authToken;
  static Client? _currentClient;
  static bool _initialized = false;

  // ============================================================
  // GETTERS
  // ============================================================

  /// Verifier si l'utilisateur est authentifie
  static bool get isAuthenticated => _authToken != null && _authToken!.isNotEmpty;

  /// Recuperer le client connecte (null si non connecte)
  static Client? get currentClient => _currentClient;

  /// Recuperer le token d'authentification
  static String? get authToken => _authToken;

  /// Recharger le token depuis le stockage si absent en memoire
  static Future<void> ensureToken() async {
    if (_authToken != null) return;
    final token = await StorageService.getAuthToken();
    if (token != null && token.isNotEmpty) {
      _authToken = token;
      print('[AuthService] Token recharge depuis stockage');
    }
  }

  /// Headers avec authentification Bearer
  static Map<String, String> get _headers => {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
    if (_authToken != null) 'Authorization': 'Bearer $_authToken',
  };

  // ============================================================
  // INITIALISATION
  // ============================================================

  /// Initialiser le service au demarrage de l'app
  /// Charge le token et les infos client depuis le stockage local
  static Future<void> initialize() async {
    if (_initialized) return;

    print('[AuthService] Initialisation...');

    try {
      final token = await StorageService.getAuthToken();
      if (token != null && token.isNotEmpty) {
        _authToken = token;

        final clientData = await StorageService.getAuthClient();
        if (clientData != null) {
          _currentClient = Client.fromJson(clientData);
          print('[AuthService] Client restaure: ${_currentClient!.name}');
        }

        NotificationService.setAuthToken(_authToken);
      }

      _initialized = true;
      print('[AuthService] Initialise - Authentifie: $isAuthenticated');
    } catch (e) {
      print('[AuthService] Erreur initialisation: $e');
      _initialized = true;
    }
  }

  // ============================================================
  // INSCRIPTION
  // ============================================================

  /// Inscrire un nouveau client
  ///
  /// [firstName] - Prenom du client
  /// [lastName] - Nom de famille du client
  /// [phone] - Numero de telephone (sans indicatif)
  /// [password] - Mot de passe (min 6 caracteres)
  /// [email] - Email (optionnel)
  static Future<AuthResponse> register({
    required String firstName,
    required String lastName,
    required String phone,
    required String password,
    String? email,
  }) async {
    print('REGISTER');
    print('Phone: $phone');
    print('Name: $firstName $lastName');

    try {
      final body = {
        'first_name': firstName,
        'last_name': lastName,
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

      print('Response Status: ${response.statusCode}');
      print('Response Body: ${response.body}');

      final data = jsonDecode(response.body);

      if (response.statusCode == 200 || response.statusCode == 201) {
        final authResponse = AuthResponse.fromJson(data);

        if (authResponse.success && authResponse.token != null) {
          await _saveAuthData(authResponse.token!, authResponse.client);
          print('Inscription reussie');
        }

        return authResponse;
      } else {
        print('Erreur inscription: ${response.statusCode}');
        return AuthResponse.fromJson(data);
      }
    } catch (e) {
      print('Exception: $e');
      return AuthResponse(
        success: false,
        message: 'Erreur de connexion. Verifiez votre connexion internet.',
      );
    }
  }

  // ============================================================
  // CONNEXION
  // ============================================================

  /// Connecter un client existant
  ///
  /// [phone] - Numero de telephone
  /// [password] - Mot de passe
  static Future<AuthResponse> login({
    required String phone,
    required String password,
  }) async {
    print('LOGIN');
    print('Phone: $phone');

    try {
      final response = await http.post(
        Uri.parse(Endpoints.clientLogin),
        headers: {'Content-Type': 'application/json', 'Accept': 'application/json'},
        body: jsonEncode({
          'phone': _formatPhone(phone),
          'password': password,
        }),
      );

      print('Response Status: ${response.statusCode}');
      print('Response Body: ${response.body}');

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        final authResponse = AuthResponse.fromJson(data);

        if (authResponse.success && authResponse.token != null) {
          await _saveAuthData(authResponse.token!, authResponse.client);
          print('Connexion reussie');
        }

        return authResponse;
      } else {
        print('Erreur connexion: ${response.statusCode}');
        return AuthResponse.fromJson(data);
      }
    } catch (e) {
      print('Exception: $e');
      return AuthResponse(
        success: false,
        message: 'Erreur de connexion. Verifiez votre connexion internet.',
      );
    }
  }

  // ============================================================
  // OTP (VERIFICATION TELEPHONE)
  // ============================================================

  /// Envoyer un code OTP au numero de telephone
  static Future<OtpResponse> sendOtp({
    required String phone,
    String type = 'register',
  }) async {
    print('SEND OTP');
    print('Phone: $phone');
    print('Type: $type');

    try {
      final response = await http.post(
        Uri.parse(Endpoints.clientSendOtp),
        headers: {'Content-Type': 'application/json', 'Accept': 'application/json'},
        body: jsonEncode({
          'phone': _formatPhone(phone),
          'type': type,
        }),
      );

      print('Response Status: ${response.statusCode}');
      print('Response Body: ${response.body}');

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        print('OTP envoye');
        return OtpResponse.fromJson(data);
      } else {
        print('Erreur envoi OTP: ${response.statusCode}');
        return OtpResponse(
          success: false,
          message: data['message'] ?? 'Erreur lors de l\'envoi du code',
        );
      }
    } catch (e) {
      print('Exception: $e');
      return OtpResponse(
        success: false,
        message: 'Erreur de connexion. Verifiez votre connexion internet.',
      );
    }
  }

  /// Verifier le code OTP
  static Future<AuthResponse> verifyOtp({
    required String phone,
    required String otp,
    String type = 'register',
  }) async {
    print('VERIFY OTP');
    print('Phone: $phone');
    print('OTP: $otp');
    print('Type: $type');

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

      print('Response Status: ${response.statusCode}');
      print('Response Body: ${response.body}');

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        final authResponse = AuthResponse.fromJson(data);

        if (authResponse.success && authResponse.token != null) {
          await _saveAuthData(authResponse.token!, authResponse.client);
          print('OTP verifie et client connecte');
        } else {
          print('OTP verifie');
        }

        return authResponse;
      } else {
        print('Erreur verification OTP: ${response.statusCode}');
        return AuthResponse.fromJson(data);
      }
    } catch (e) {
      print('Exception: $e');
      return AuthResponse(
        success: false,
        message: 'Erreur de connexion. Verifiez votre connexion internet.',
      );
    }
  }

  // ============================================================
  // MOT DE PASSE OUBLIE
  // ============================================================

  /// Demander la reinitialisation du mot de passe
  static Future<OtpResponse> forgotPassword({required String phone}) async {
    print('FORGOT PASSWORD');

    try {
      final response = await http.post(
        Uri.parse(Endpoints.clientForgotPassword),
        headers: {'Content-Type': 'application/json', 'Accept': 'application/json'},
        body: jsonEncode({'phone': _formatPhone(phone)}),
      );

      print('Response Status: ${response.statusCode}');

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        print('Code de reinitialisation envoye');
        return OtpResponse.fromJson(data);
      } else {
        print('Erreur: ${response.statusCode}');
        return OtpResponse(
          success: false,
          message: data['message'] ?? 'Erreur lors de l\'envoi du code',
        );
      }
    } catch (e) {
      print('Exception: $e');
      return OtpResponse(
        success: false,
        message: 'Erreur de connexion. Verifiez votre connexion internet.',
      );
    }
  }

  /// Reinitialiser le mot de passe avec le code OTP
  static Future<AuthResponse> resetPassword({
    required String phone,
    required String otp,
    required String newPassword,
  }) async {
    print('RESET PASSWORD');

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

      print('Response Status: ${response.statusCode}');

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        print('Mot de passe reinitialise');
        return AuthResponse.fromJson(data);
      } else {
        print('Erreur: ${response.statusCode}');
        return AuthResponse.fromJson(data);
      }
    } catch (e) {
      print('Exception: $e');
      return AuthResponse(
        success: false,
        message: 'Erreur de connexion. Verifiez votre connexion internet.',
      );
    }
  }

  // ============================================================
  // PROFIL
  // ============================================================

  /// Recuperer le profil du client connecte
  static Future<Client?> getProfile() async {
    if (!isAuthenticated) {
      print('[AuthService] Non authentifie');
      return null;
    }

    print('GET PROFILE');

    try {
      final response = await http.get(
        Uri.parse(Endpoints.clientProfile),
        headers: _headers,
      );

      print('Response Status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        // Support structure: data.data.profile or data.data or data.client or data
        final clientData = data['data'] is Map && data['data']['profile'] != null
            ? data['data']['profile']
            : data['data'] ?? data['client'] ?? data['user'] ?? data;
        _currentClient = Client.fromJson(clientData);
        await StorageService.saveAuthClient(_currentClient!.toJson());
        print('Profil recupere: ${_currentClient!.name}');
        return _currentClient;
      } else if (response.statusCode == 401) {
        print('Token invalide - Deconnexion');
        await logout();
        return null;
      }
    } catch (e) {
      print('Exception: $e');
    }

    return _currentClient;
  }

  /// Mettre a jour le profil du client
  static Future<Client?> updateProfile({
    String? firstName,
    String? lastName,
    String? email,
    String? birthDate,
  }) async {
    if (!isAuthenticated) {
      print('[AuthService] Non authentifie');
      return null;
    }

    print('UPDATE PROFILE');

    try {
      final body = <String, dynamic>{};
      if (firstName != null) body['first_name'] = firstName;
      if (lastName != null) body['last_name'] = lastName;
      if (email != null) body['email'] = email;
      if (birthDate != null) body['birth_date'] = birthDate;

      final response = await http.put(
        Uri.parse(Endpoints.clientProfile),
        headers: _headers,
        body: jsonEncode(body),
      );

      print('Response Status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final clientData = data['data'] is Map && data['data']['profile'] != null
            ? data['data']['profile']
            : data['data'] ?? data['client'] ?? data['user'] ?? data;
        _currentClient = Client.fromJson(clientData);
        await StorageService.saveAuthClient(_currentClient!.toJson());
        print('Profil mis a jour: ${_currentClient!.name}');
        return _currentClient;
      }
    } catch (e) {
      print('Exception: $e');
    }

    return null;
  }

  // ============================================================
  // DECONNEXION
  // ============================================================

  /// Deconnecter le client
  static Future<void> logout() async {
    print('LOGOUT');

    try {
      if (isAuthenticated) {
        await http.post(
          Uri.parse(Endpoints.clientLogout),
          headers: _headers,
        );
      }
    } catch (e) {
      print('Erreur API logout (ignoree): $e');
    }

    _authToken = null;
    _currentClient = null;

    await StorageService.clearAuthData();

    NotificationService.setAuthToken(null);

    // Arreter le polling et remettre le badge a zero
    PushNotificationService.stopPolling();
    PushNotificationService.unreadCount.value = 0;

    print('Deconnexion reussie');
  }

  // ============================================================
  // HELPERS PRIVES
  // ============================================================

  /// Sauvegarder les donnees d'authentification
  static Future<void> _saveAuthData(String token, Client? client) async {
    _authToken = token;
    _currentClient = client;

    await StorageService.saveAuthToken(token);
    if (client != null) {
      await StorageService.saveAuthClient(client.toJson());

      await StorageService.saveCustomerInfo(
        name: client.name,
        phone: client.phone,
        email: client.email,
      );
    }

    NotificationService.setAuthToken(token);

    // Enregistrer le token FCM aupres du backend pour recevoir les push
    PushNotificationService.registerDeviceToken();

    // Demarrer le polling des notifications pour le badge
    PushNotificationService.startPolling();
  }

  /// Formater le numero de telephone (supprimer espaces et indicatif si present)
  static String _formatPhone(String phone) {
    String formatted = phone.replaceAll(' ', '');

    if (formatted.startsWith('+225')) {
      formatted = formatted.substring(4);
    }
    if (formatted.startsWith('00225')) {
      formatted = formatted.substring(5);
    }

    return formatted;
  }
}
