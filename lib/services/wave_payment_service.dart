import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'dart:convert';
import 'dart:io';
import './utils/api_endpoint.dart';

/// Service de paiement Wave (Mode Screenshot)
///
/// Flux:
/// 1. Client passe commande avec Wave
/// 2. App affiche le lien Wave du vendeur
/// 3. Client paie via Wave et prend une capture d'écran
/// 4. App envoie la capture: POST /api/mobile/orders/create-with-wave-proof
/// 5. Système valide automatiquement (OCR)
/// 6. Vendeur approuve ou rejette
class WavePaymentService {
  static const Map<String, String> _headers = {
    'Accept': 'application/json',
  };

  /// Créer une commande avec preuve Wave en une seule étape
  /// POST /api/mobile/orders/create-with-wave-proof
  ///
  /// Paramètres:
  /// - pendingOrderId: ID de la commande en attente (du cache local)
  /// - screenshotPath: Chemin vers la capture d'écran Wave
  ///
  /// Retourne les données de la commande créée avec le statut de validation
  static Future<WaveProofResponse> createOrderWithWaveProof({
    required String pendingOrderId,
    required String screenshotPath,
  }) async {
    print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    print('📤 POST CREATE ORDER WITH WAVE PROOF');
    print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    print('🔗 Endpoint: ${Endpoints.waveCreateWithProof}');
    print('📦 Pending Order ID: $pendingOrderId');
    print('📸 Screenshot Path: $screenshotPath');
    print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');

    try {
      final uri = Uri.parse(Endpoints.waveCreateWithProof);
      final request = http.MultipartRequest('POST', uri);

      // Ajouter les headers
      request.headers.addAll(_headers);

      // Ajouter le pending_order_id
      request.fields['pending_order_id'] = pendingOrderId;

      // Ajouter la capture d'écran
      final file = File(screenshotPath);
      final extension = screenshotPath.split('.').last.toLowerCase();
      final mimeType = _getMimeType(extension);

      request.files.add(
        await http.MultipartFile.fromPath(
          'screenshot',
          screenshotPath,
          contentType: MediaType('image', mimeType),
        ),
      );

      // Envoyer la requête
      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      print('📥 Response Status: ${response.statusCode}');
      print('📥 Response Body: ${response.body}');

      final data = jsonDecode(response.body);

      if (response.statusCode == 200 || response.statusCode == 201) {
        print('✅ Commande créée avec preuve Wave');
        print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');

        return WaveProofResponse(
          success: data['success'] ?? true,
          message: data['message'] ?? 'Commande créée avec succès',
          orderId: data['order_id'],
          orderNumber: data['order_number'],
          totalAmount: (data['total_amount'] as num?)?.toDouble(),
          paymentStatus: data['payment_status'],
          validation: data['validation'] != null
              ? WaveValidation.fromJson(data['validation'])
              : null,
        );
      } else if (response.statusCode == 400) {
        // Validation échouée
        print('❌ Validation Wave échouée');
        print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');

        throw WaveValidationException(
          message: data['message'] ?? 'Validation échouée',
          details: List<String>.from(data['details'] ?? []),
          expected: data['expected'],
          found: data['found'],
          validationFailed: data['validation_failed'] ?? true,
          autoRejected: data['auto_rejected'] ?? false,
        );
      } else {
        throw Exception(data['message'] ?? 'Erreur lors de la création de la commande');
      }
    } catch (e) {
      print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
      print('❌ Exception: $e');
      print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
      rethrow;
    }
  }

  /// Soumettre une preuve de paiement Wave pour une commande existante
  /// POST /api/mobile/orders/{orderId}/wave-proof
  static Future<WaveProofResponse> submitWaveProof({
    required int orderId,
    required String screenshotPath,
  }) async {
    print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    print('📤 POST SUBMIT WAVE PROOF');
    print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    print('🔗 Endpoint: ${Endpoints.waveSubmitProof(orderId)}');
    print('📸 Screenshot Path: $screenshotPath');
    print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');

    try {
      final uri = Uri.parse(Endpoints.waveSubmitProof(orderId));
      final request = http.MultipartRequest('POST', uri);

      // Ajouter les headers
      request.headers.addAll(_headers);

      // Ajouter la capture d'écran
      final extension = screenshotPath.split('.').last.toLowerCase();
      final mimeType = _getMimeType(extension);

      request.files.add(
        await http.MultipartFile.fromPath(
          'screenshot',
          screenshotPath,
          contentType: MediaType('image', mimeType),
        ),
      );

      // Envoyer la requête
      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      print('📥 Response Status: ${response.statusCode}');
      print('📥 Response Body: ${response.body}');

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        print('✅ Preuve Wave soumise');
        print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');

        return WaveProofResponse(
          success: data['success'] ?? true,
          message: data['message'] ?? 'Preuve de paiement enregistrée',
          validation: data['validation'] != null
              ? WaveValidation.fromJson(data['validation'])
              : null,
        );
      } else if (response.statusCode == 400) {
        throw WaveValidationException(
          message: data['message'] ?? 'Validation échouée',
          details: List<String>.from(data['details'] ?? []),
          expected: data['expected'],
          found: data['found'],
          validationFailed: data['validation_failed'] ?? true,
          autoRejected: data['auto_rejected'] ?? false,
        );
      } else {
        throw Exception(data['message'] ?? 'Erreur lors de l\'envoi de la preuve');
      }
    } catch (e) {
      print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
      print('❌ Exception: $e');
      print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
      rethrow;
    }
  }

  /// Vérifier le statut d'un paiement Wave
  /// GET /api/mobile/orders/{orderId}/payment-status
  static Future<WavePaymentStatus> checkPaymentStatus(int orderId) async {
    print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    print('📤 GET WAVE PAYMENT STATUS');
    print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    print('🔗 Endpoint: ${Endpoints.wavePaymentStatus(orderId)}');
    print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');

    try {
      final response = await http.get(
        Uri.parse(Endpoints.wavePaymentStatus(orderId)),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      );

      print('📥 Response Status: ${response.statusCode}');
      print('📥 Response Body: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final statusData = data['data'] ?? data;

        print('✅ Statut récupéré');
        print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');

        return WavePaymentStatus.fromJson(statusData);
      } else {
        final data = jsonDecode(response.body);
        throw Exception(data['message'] ?? 'Erreur lors de la vérification du statut');
      }
    } catch (e) {
      print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
      print('❌ Exception: $e');
      print('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
      rethrow;
    }
  }

  /// Obtenir le type MIME pour une extension de fichier
  static String _getMimeType(String extension) {
    switch (extension) {
      case 'jpg':
      case 'jpeg':
        return 'jpeg';
      case 'png':
        return 'png';
      case 'webp':
        return 'webp';
      default:
        return 'jpeg';
    }
  }
}

/// Réponse après soumission de preuve Wave
class WaveProofResponse {
  final bool success;
  final String message;
  final int? orderId;
  final String? orderNumber;
  final double? totalAmount;
  final String? paymentStatus;
  final WaveValidation? validation;

  WaveProofResponse({
    required this.success,
    required this.message,
    this.orderId,
    this.orderNumber,
    this.totalAmount,
    this.paymentStatus,
    this.validation,
  });
}

/// Résultat de la validation OCR Wave
class WaveValidation {
  final int score;
  final double confidence;
  final bool valid;
  final bool amountMatched;
  final bool dateMatched;
  final String? transactionId;

  WaveValidation({
    required this.score,
    required this.confidence,
    required this.valid,
    required this.amountMatched,
    required this.dateMatched,
    this.transactionId,
  });

  factory WaveValidation.fromJson(Map<String, dynamic> json) {
    return WaveValidation(
      score: json['score'] ?? 0,
      confidence: (json['confidence'] as num?)?.toDouble() ?? 0.0,
      valid: json['valid'] ?? false,
      amountMatched: json['amount_matched'] ?? false,
      dateMatched: json['date_matched'] ?? false,
      transactionId: json['transaction_id'],
    );
  }
}

/// Statut d'un paiement Wave
class WavePaymentStatus {
  final int orderId;
  final String paymentMethod;
  final String paymentStatus;
  final bool waveProofUploaded;
  final String? waveProofUrl;
  final DateTime? waveApprovedAt;
  final String? waveRejectionReason;
  final double totalAmount;
  final double amountPaid;

  WavePaymentStatus({
    required this.orderId,
    required this.paymentMethod,
    required this.paymentStatus,
    required this.waveProofUploaded,
    this.waveProofUrl,
    this.waveApprovedAt,
    this.waveRejectionReason,
    required this.totalAmount,
    required this.amountPaid,
  });

  factory WavePaymentStatus.fromJson(Map<String, dynamic> json) {
    return WavePaymentStatus(
      orderId: json['order_id'] ?? 0,
      paymentMethod: json['payment_method'] ?? 'wave',
      paymentStatus: json['payment_status'] ?? 'pending',
      waveProofUploaded: json['wave_proof_uploaded'] ?? false,
      waveProofUrl: json['wave_proof_url'],
      waveApprovedAt: json['wave_approved_at'] != null
          ? DateTime.parse(json['wave_approved_at'])
          : null,
      waveRejectionReason: json['wave_rejection_reason'],
      totalAmount: (json['total_amount'] as num?)?.toDouble() ?? 0.0,
      amountPaid: (json['amount_paid'] as num?)?.toDouble() ?? 0.0,
    );
  }

  /// Le paiement est-il en attente de vérification?
  bool get isPendingVerification => paymentStatus == 'pending_verification';

  /// Le paiement est-il approuvé?
  bool get isPaid => paymentStatus == 'paid';

  /// Le paiement est-il rejeté?
  bool get isRejected => paymentStatus == 'rejected';

  /// Le paiement est-il en attente?
  bool get isPending => paymentStatus == 'pending';
}

/// Exception pour les erreurs de validation Wave
class WaveValidationException implements Exception {
  final String message;
  final List<String> details;
  final Map<String, dynamic>? expected;
  final Map<String, dynamic>? found;
  final bool validationFailed;
  final bool autoRejected;

  WaveValidationException({
    required this.message,
    required this.details,
    this.expected,
    this.found,
    this.validationFailed = true,
    this.autoRejected = false,
  });

  @override
  String toString() => message;
}
