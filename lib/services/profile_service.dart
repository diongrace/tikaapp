import 'package:http/http.dart' as http;
import 'dart:convert';
import './utils/api_endpoint.dart';
import './models/client_model.dart';
import './models/profile_model.dart';
import './auth_service.dart';

/// Service de gestion du profil client
///
/// IMPORTANT: Necessite une authentification Bearer Token
class ProfileService {
  /// Dernier message d'erreur pour les adresses
  static String? lastAddressError;

  /// Dernier message d'erreur pour la mise a jour du profil
  static String? lastUpdateError;

  /// Extraire les donnees d'une adresse depuis la reponse API
  /// Gere les structures: {data: {address: {...}}}, {data: {...}}, {address: {...}}, {...}
  static Map<String, dynamic> _extractAddressData(Map<String, dynamic> raw) {
    // Cas: { data: { address: { id, label, ... } } }
    if (raw['data'] is Map) {
      final data = raw['data'] as Map<String, dynamic>;
      if (data['address'] is Map) {
        return data['address'] as Map<String, dynamic>;
      }
      // Cas: { data: { id, label, ... } }
      if (data.containsKey('id')) return data;
    }
    // Cas: { address: { id, label, ... } }
    if (raw['address'] is Map) {
      return raw['address'] as Map<String, dynamic>;
    }
    // Fallback: la reponse est directement l'adresse
    return raw;
  }

  /// Headers avec authentification Bearer
  static Map<String, String> get _headers => {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        if (AuthService.authToken != null)
          'Authorization': 'Bearer ${AuthService.authToken}',
      };

  static bool get _isAuthenticated => AuthService.isAuthenticated;

  // ============================================================
  // PROFIL
  // ============================================================

  /// GET /client/profile - Recuperer le profil
  static Future<Client?> getProfile() async {
    if (!_isAuthenticated) return null;

    print('GET PROFILE (ProfileService)');

    try {
      final response = await http.get(
        Uri.parse(Endpoints.clientProfile),
        headers: _headers,
      );

      print('Response Status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        // Support structure: data.data.profile or data.data or data.client or data
        final profileData = data['data'] is Map && data['data']['profile'] != null
            ? data['data']['profile']
            : data['data'] ?? data['client'] ?? data['user'] ?? data;
        return Client.fromJson(profileData);
      } else if (response.statusCode == 401) {
        return null;
      }
    } catch (e) {
      print('Exception ProfileService.getProfile: $e');
    }
    return null;
  }

  /// PUT /client/profile - Mettre a jour le profil
  static Future<Client?> updateProfile({
    String? firstName,
    String? lastName,
    String? email,
    String? birthDate,
  }) async {
    if (!_isAuthenticated) return null;

    lastUpdateError = null;
    print('UPDATE PROFILE (ProfileService)');

    try {
      final body = <String, dynamic>{};
      if (firstName != null) body['first_name'] = firstName;
      if (lastName != null) body['last_name'] = lastName;
      if (email != null) body['email'] = email;
      if (birthDate != null) body['birth_date'] = birthDate;

      print('UPDATE PROFILE body: ${jsonEncode(body)}');

      final response = await http.put(
        Uri.parse(Endpoints.clientProfile),
        headers: _headers,
        body: jsonEncode(body),
      );

      print('Response Status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final profileData = data['data'] is Map && data['data']['profile'] != null
            ? data['data']['profile']
            : data['data'] ?? data['client'] ?? data['user'] ?? data;
        final updatedClient = Client.fromJson(profileData);
        // Synchroniser le cache local pour que le profil s'actualise immediatement
        await AuthService.updateCurrentClient(updatedClient);
        return updatedClient;
      } else {
        print('UPDATE PROFILE error body: ${response.body}');
        try {
          final errorData = jsonDecode(response.body);
          if (errorData['errors'] != null) {
            final errors = errorData['errors'] as Map<String, dynamic>;
            final firstError = errors.values.first;
            lastUpdateError = firstError is List ? firstError.first.toString() : firstError.toString();
          } else {
            lastUpdateError = errorData['message']?.toString() ?? 'Erreur ${response.statusCode}';
          }
        } catch (_) {
          lastUpdateError = 'Erreur ${response.statusCode}';
        }
      }
    } catch (e) {
      print('Exception ProfileService.updateProfile: $e');
      lastUpdateError = 'Erreur de connexion';
    }
    return null;
  }

  // ============================================================
  // MOT DE PASSE
  // ============================================================

  /// PUT /client/profile/password - Changer le mot de passe
  static Future<Map<String, dynamic>> changePassword({
    required String currentPassword,
    required String newPassword,
    required String newPasswordConfirmation,
  }) async {
    if (!_isAuthenticated) {
      return {'success': false, 'message': 'Non authentifie'};
    }

    print('CHANGE PASSWORD (ProfileService)');

    try {
      final response = await http.put(
        Uri.parse(Endpoints.clientProfilePassword),
        headers: _headers,
        body: jsonEncode({
          'current_password': currentPassword,
          'new_password': newPassword,
          'new_password_confirmation': newPasswordConfirmation,
        }),
      );

      print('Response Status: ${response.statusCode}');
      print('CHANGE PASSWORD response body: ${response.body}');

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return {'success': true, 'message': data['message'] ?? 'Mot de passe modifie'};
      } else {
        // Extraire le premier message d'erreur de validation
        String errorMessage = data['message'] ?? 'Erreur lors du changement de mot de passe';
        if (data['errors'] != null) {
          final errors = data['errors'] as Map<String, dynamic>;
          final firstError = errors.values.first;
          errorMessage = firstError is List ? firstError.first.toString() : firstError.toString();
        }
        return {
          'success': false,
          'message': errorMessage,
          'errors': data['errors'],
        };
      }
    } catch (e) {
      print('Exception ProfileService.changePassword: $e');
      return {'success': false, 'message': 'Erreur de connexion'};
    }
  }

  // ============================================================
  // STATISTIQUES
  // ============================================================

  /// GET /client/profile/stats - Statistiques du profil
  static Future<ProfileStats?> getStats() async {
    if (!_isAuthenticated) return null;

    print('GET PROFILE STATS (ProfileService)');

    try {
      final response = await http.get(
        Uri.parse(Endpoints.clientProfileStats),
        headers: _headers,
      );

      print('Response Status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final statsData = data['data'] ?? data['stats'] ?? data;
        return ProfileStats.fromJson(statsData);
      }
    } catch (e) {
      print('Exception ProfileService.getStats: $e');
    }
    return null;
  }

  // ============================================================
  // ADRESSES
  // ============================================================

  /// GET /client/profile/addresses - Liste des adresses
  static Future<List<ProfileAddress>> getAddresses() async {
    if (!_isAuthenticated) return [];

    print('GET ADDRESSES (ProfileService)');

    try {
      final response = await http.get(
        Uri.parse(Endpoints.clientProfileAddresses),
        headers: _headers,
      );

      print('Response Status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final addressesData = data['data'] ?? data['addresses'] ?? data;

        if (addressesData is List) {
          return addressesData.map((e) => ProfileAddress.fromJson(e)).toList();
        } else if (addressesData is Map && addressesData['addresses'] != null) {
          return (addressesData['addresses'] as List)
              .map((e) => ProfileAddress.fromJson(e))
              .toList();
        }
      }
    } catch (e) {
      print('Exception ProfileService.getAddresses: $e');
    }
    return [];
  }

  /// POST /client/profile/addresses - Ajouter une adresse
  static Future<ProfileAddress?> addAddress({
    required String label,
    required String address,
    String? city,
    String? region,
  }) async {
    if (!_isAuthenticated) return null;

    lastAddressError = null;
    print('ADD ADDRESS (ProfileService)');

    try {
      final body = <String, dynamic>{
        'label': label,
        'address': address,
      };
      if (city != null) body['city'] = city;
      if (region != null) body['region'] = region;

      print('ADD ADDRESS body: ${jsonEncode(body)}');

      final response = await http.post(
        Uri.parse(Endpoints.clientProfileAddresses),
        headers: _headers,
        body: jsonEncode(body),
      );

      print('Response Status: ${response.statusCode}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        print('ADD ADDRESS success body: ${response.body}');
        final data = jsonDecode(response.body);
        final addressData = _extractAddressData(data);
        return ProfileAddress.fromJson(addressData);
      } else {
        print('ADD ADDRESS error body: ${response.body}');
        try {
          final errorData = jsonDecode(response.body);
          if (errorData['errors'] != null) {
            final errors = errorData['errors'] as Map<String, dynamic>;
            final firstError = errors.values.first;
            lastAddressError = firstError is List ? firstError.first.toString() : firstError.toString();
          } else {
            lastAddressError = errorData['message']?.toString() ?? 'Erreur ${response.statusCode}';
          }
        } catch (_) {
          lastAddressError = 'Erreur ${response.statusCode}';
        }
      }
    } catch (e) {
      print('Exception ProfileService.addAddress: $e');
      lastAddressError = 'Erreur de connexion';
    }
    return null;
  }

  /// PUT /client/profile/addresses/{id} - Modifier une adresse
  static Future<ProfileAddress?> updateAddress(
    int id, {
    String? label,
    String? address,
    String? city,
    String? region,
  }) async {
    if (!_isAuthenticated) return null;

    print('UPDATE ADDRESS #$id (ProfileService)');

    try {
      final body = <String, dynamic>{};
      if (label != null) body['label'] = label;
      if (address != null) body['address'] = address;
      if (city != null) body['city'] = city;
      if (region != null) body['region'] = region;

      final response = await http.put(
        Uri.parse(Endpoints.clientProfileAddress(id)),
        headers: _headers,
        body: jsonEncode(body),
      );

      print('Response Status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final addressData = data['data'] ?? data['address'] ?? data;
        return ProfileAddress.fromJson(addressData);
      }
    } catch (e) {
      print('Exception ProfileService.updateAddress: $e');
    }
    return null;
  }

  /// DELETE /client/profile/addresses/{id} - Supprimer une adresse
  static Future<bool> deleteAddress(int id) async {
    if (!_isAuthenticated) return false;

    print('DELETE ADDRESS #$id (ProfileService)');

    try {
      final response = await http.delete(
        Uri.parse(Endpoints.clientProfileAddress(id)),
        headers: _headers,
      );

      print('Response Status: ${response.statusCode}');

      return response.statusCode == 200 || response.statusCode == 204;
    } catch (e) {
      print('Exception ProfileService.deleteAddress: $e');
      return false;
    }
  }

  /// PUT /client/profile/addresses/{id}/default - Definir adresse par defaut
  static Future<bool> setDefaultAddress(int id) async {
    if (!_isAuthenticated) return false;

    print('SET DEFAULT ADDRESS #$id (ProfileService)');

    try {
      final response = await http.put(
        Uri.parse(Endpoints.clientProfileAddressDefault(id)),
        headers: _headers,
      );

      print('Response Status: ${response.statusCode}');

      return response.statusCode == 200;
    } catch (e) {
      print('Exception ProfileService.setDefaultAddress: $e');
      return false;
    }
  }

  // ============================================================
  // SUPPRESSION COMPTE
  // ============================================================

  /// DELETE /client/profile - Supprimer le compte
  static Future<Map<String, dynamic>> deleteAccount({
    required String password,
    String? reason,
  }) async {
    if (!_isAuthenticated) {
      return {'success': false, 'message': 'Non authentifie'};
    }

    print('DELETE ACCOUNT (ProfileService)');

    try {
      final body = <String, dynamic>{
        'password': password,
      };
      if (reason != null) body['reason'] = reason;

      final request = http.Request(
        'DELETE',
        Uri.parse(Endpoints.clientProfile),
      );
      request.headers.addAll(_headers);
      request.body = jsonEncode(body);

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      print('Response Status: ${response.statusCode}');

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return {'success': true, 'message': data['message'] ?? 'Compte supprime'};
      } else {
        return {
          'success': false,
          'message': data['message'] ?? 'Erreur lors de la suppression du compte',
        };
      }
    } catch (e) {
      print('Exception ProfileService.deleteAccount: $e');
      return {'success': false, 'message': 'Erreur de connexion'};
    }
  }
}
