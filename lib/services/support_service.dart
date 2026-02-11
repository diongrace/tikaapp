import 'package:http/http.dart' as http;
import 'dart:convert';
import './utils/api_endpoint.dart';
import './auth_service.dart';
import './models/support_model.dart';

/// Service pour gerer les tickets de support client
/// Authentification: Bearer Token (Sanctum)
///
/// Endpoints:
/// 1. GET    /client/support            - Mes tickets
/// 2. GET    /client/support/options     - Options (categories, priorites)
/// 3. POST   /client/support            - Creer un ticket
/// 4. GET    /client/support/{id}       - Detail d'un ticket
/// 5. GET    /client/support/{id}/status - Statut d'un ticket
class SupportService {
  static Map<String, String> get _headers => {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        if (AuthService.authToken != null)
          'Authorization': 'Bearer ${AuthService.authToken}',
      };

  // ============================================================
  // 1. GET /client/support - Liste des tickets
  // ============================================================

  static Future<List<SupportTicket>> getTickets() async {
    try {
      print('[Support] GET /client/support');
      final response = await http.get(
        Uri.parse(Endpoints.support),
        headers: _headers,
      );
      print('[Support] Status: ${response.statusCode}');
      print('[Support] Body: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        if (data['success'] == true && data['data'] != null) {
          final responseData = data['data'];

          // Extraire la liste selon le format API
          List ticketsList = [];
          if (responseData is List) {
            ticketsList = responseData;
          } else if (responseData['tickets'] is List) {
            ticketsList = responseData['tickets'];
          } else if (responseData['data'] is List) {
            ticketsList = responseData['data'];
          }

          final tickets = <SupportTicket>[];
          for (var item in ticketsList) {
            try {
              tickets.add(SupportTicket.fromJson(item as Map<String, dynamic>));
            } catch (e) {
              print('[Support] Erreur parsing ticket: $e');
            }
          }

          print('[Support] ${tickets.length} tickets charges');
          return tickets;
        }
      } else if (response.statusCode == 401) {
        throw Exception('Authentification requise');
      }

      return [];
    } catch (e) {
      print('[Support] Erreur getTickets: $e');
      rethrow;
    }
  }

  // ============================================================
  // 2. GET /client/support/options - Options disponibles
  // ============================================================

  static Future<SupportOption> getOptions() async {
    try {
      print('[Support] GET /client/support/options');
      final response = await http.get(
        Uri.parse(Endpoints.supportOptions),
        headers: _headers,
      );
      print('[Support] Status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true && data['data'] != null) {
          return SupportOption.fromJson(data['data']);
        }
      }

      // Fallback avec des options par defaut
      return SupportOption(
        categories: [
          'Probleme de commande',
          'Probleme de paiement',
          'Probleme de livraison',
          'Bug technique',
          'Suggestion',
          'Autre',
        ],
        priorities: ['normal', 'high', 'urgent'],
      );
    } catch (e) {
      print('[Support] Erreur getOptions: $e');
      return SupportOption(
        categories: [
          'Probleme de commande',
          'Probleme de paiement',
          'Probleme de livraison',
          'Bug technique',
          'Suggestion',
          'Autre',
        ],
        priorities: ['normal', 'high', 'urgent'],
      );
    }
  }

  // ============================================================
  // 3. POST /client/support - Creer un ticket
  // ============================================================

  static Future<SupportTicket?> createTicket({
    required String subject,
    required String message,
    required String category,
    String priority = 'normal',
  }) async {
    try {
      print('[Support] POST /client/support');
      print('[Support] subject=$subject, category=$category, priority=$priority');

      final response = await http.post(
        Uri.parse(Endpoints.support),
        headers: _headers,
        body: jsonEncode({
          'subject': subject,
          'message': message,
          'category': category,
          'priority': priority,
        }),
      );
      print('[Support] Status: ${response.statusCode}');
      print('[Support] Body: ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body);
        if (data['success'] == true && data['data'] != null) {
          final ticketData = data['data'];
          if (ticketData is Map<String, dynamic>) {
            // data peut contenir le ticket directement ou dans data.ticket
            final ticketJson = ticketData['ticket'] ?? ticketData;
            return SupportTicket.fromJson(ticketJson as Map<String, dynamic>);
          }
        }
        return null;
      } else if (response.statusCode == 422) {
        final data = jsonDecode(response.body);
        final errors = data['errors'] ?? data['message'] ?? 'Donnees invalides';
        throw Exception('Validation: $errors');
      } else if (response.statusCode == 401) {
        throw Exception('Authentification requise');
      } else {
        throw Exception('Erreur ${response.statusCode}');
      }
    } catch (e) {
      print('[Support] Erreur createTicket: $e');
      rethrow;
    }
  }

  // ============================================================
  // 4. GET /client/support/{id} - Detail d'un ticket
  // ============================================================

  static Future<SupportTicket?> getTicketDetail(int ticketId) async {
    try {
      print('[Support] GET /client/support/$ticketId');
      final response = await http.get(
        Uri.parse(Endpoints.supportDetail(ticketId)),
        headers: _headers,
      );
      print('[Support] Status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true && data['data'] != null) {
          final ticketData = data['data'];
          final ticketJson = ticketData['ticket'] ?? ticketData;
          return SupportTicket.fromJson(ticketJson as Map<String, dynamic>);
        }
      } else if (response.statusCode == 404) {
        throw Exception('Ticket introuvable');
      }
      return null;
    } catch (e) {
      print('[Support] Erreur getTicketDetail: $e');
      rethrow;
    }
  }

  // ============================================================
  // 5. GET /client/support/{id}/status - Statut d'un ticket
  // ============================================================

  static Future<String> getTicketStatus(int ticketId) async {
    try {
      print('[Support] GET /client/support/$ticketId/status');
      final response = await http.get(
        Uri.parse(Endpoints.supportStatus(ticketId)),
        headers: _headers,
      );
      print('[Support] Status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true && data['data'] != null) {
          return data['data']['status']?.toString() ?? 'unknown';
        }
      }
      return 'unknown';
    } catch (e) {
      print('[Support] Erreur getTicketStatus: $e');
      return 'unknown';
    }
  }
}
