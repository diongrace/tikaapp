import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/services/boutique_theme_provider.dart';
import '../../../services/order_service.dart';
import '../../../services/wave_payment_service.dart';

/// Écran de paiement Wave (Mode Screenshot)
///
/// Flux:
/// 1. Afficher le lien Wave du vendeur
/// 2. Client ouvre Wave et effectue le paiement
/// 3. Client prend une capture d'écran de la confirmation
/// 4. App envoie la capture pour validation
/// 5. Afficher le statut de validation
class WavePaymentScreen extends StatefulWidget {
  final int? orderId;
  final double amount;
  final String? wavePaymentLink;
  final String? vendorWaveNumber;
  final Function(WaveProofResponse)? onPaymentSuccess;
  final VoidCallback? onCancel;

  // Données de commande (pour créer la commande au moment de la soumission)
  final int shopId;
  final String customerName;
  final String customerPhone;
  final String serviceType;
  final String deviceFingerprint;
  final List<Map<String, dynamic>> items;
  final String? customerEmail;
  final String? customerAddress;
  final String? deliveryAddress;

  const WavePaymentScreen({
    super.key,
    this.orderId,
    required this.amount,
    this.wavePaymentLink,
    this.vendorWaveNumber,
    this.onPaymentSuccess,
    this.onCancel,
    required this.shopId,
    required this.customerName,
    required this.customerPhone,
    required this.serviceType,
    required this.deviceFingerprint,
    required this.items,
    this.customerEmail,
    this.customerAddress,
    this.deliveryAddress,
  });

  @override
  State<WavePaymentScreen> createState() => _WavePaymentScreenState();
}

class _WavePaymentScreenState extends State<WavePaymentScreen> {
  final ImagePicker _picker = ImagePicker();
  XFile? _screenshot;
  bool _isSubmitting = false;
  String? _errorMessage;
  WaveProofResponse? _response;
  WavePaymentStatus? _paymentStatus;
  Timer? _pollingTimer;
  bool _waveOpened = false; // Wave a été ouvert au moins une fois

  // Couleur Wave
  static const Color waveColor = Color(0xFF1BA5E0);

  @override
  void initState() {
    super.initState();
    // Ouvrir automatiquement le lien Wave du vendeur au chargement
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _openWaveApp();
    });
  }

  @override
  void dispose() {
    _pollingTimer?.cancel();
    super.dispose();
  }

  /// Ouvrir le lien Wave du vendeur avec le montant pré-rempli
  Future<void> _openWaveApp() async {
    String? urlToOpen = widget.wavePaymentLink;

    // Si le lien est un numero/code (pas une URL), construire le lien Wave
    if (urlToOpen != null && !urlToOpen.startsWith('http')) {
      urlToOpen = 'https://wave.com/m/$urlToOpen';
    }

    // Si pas de lien, essayer avec le numéro Wave du vendeur
    if (urlToOpen == null && widget.vendorWaveNumber != null) {
      urlToOpen = 'https://wave.com/m/${widget.vendorWaveNumber}';
    }

    // Ajouter le montant à l'URL Wave
    if (urlToOpen != null) {
      final uri = Uri.tryParse(urlToOpen);
      if (uri != null && !uri.queryParameters.containsKey('amount')) {
        urlToOpen = uri.replace(queryParameters: {
          ...uri.queryParameters,
          'amount': widget.amount.toStringAsFixed(0),
        }).toString();
      }
    }

    print('[Wave] urlToOpen: $urlToOpen');

    if (urlToOpen != null) {
      try {
        final uri = Uri.parse(urlToOpen);
        await launchUrl(uri, mode: LaunchMode.externalApplication);
        if (mounted) {
          setState(() {
            _waveOpened = true;
          });
        }
        return;
      } catch (e) {
        print('[Wave] Erreur ouverture lien: $e');
        if (mounted) {
          setState(() {
            _errorMessage = 'Impossible d\'ouvrir Wave. Vérifiez que l\'app Wave est installée.';
          });
        }
      }
    } else {
      // Pas de lien Wave disponible
      if (mounted) {
        setState(() {
          _errorMessage = 'Le lien de paiement Wave du vendeur n\'est pas disponible.';
        });
      }
    }
  }

  /// Sélectionner une capture d'écran depuis la galerie
  Future<void> _pickScreenshot() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1080,
        maxHeight: 1920,
        imageQuality: 85,
      );

      if (image != null) {
        setState(() {
          _screenshot = image;
          _errorMessage = null;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Erreur lors de la sélection de l\'image: $e';
      });
    }
  }

  /// Prendre une capture d'écran avec la caméra
  Future<void> _takeScreenshot() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.camera,
        maxWidth: 1080,
        maxHeight: 1920,
        imageQuality: 85,
      );

      if (image != null) {
        setState(() {
          _screenshot = image;
          _errorMessage = null;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Erreur lors de la prise de photo: $e';
      });
    }
  }

  /// Soumettre la preuve de paiement Wave
  Future<void> _submitProof() async {
    if (_screenshot == null) {
      setState(() {
        _errorMessage = 'Veuillez sélectionner une capture d\'écran';
      });
      return;
    }

    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
    });

    try {
      WaveProofResponse response;

      if (widget.orderId != null) {
        // Soumettre preuve pour commande existante
        response = await WavePaymentService.submitWaveProof(
          orderId: widget.orderId!,
          screenshotPath: _screenshot!.path,
        );
      } else {
        // Étape 1: Créer la commande via l'API standard avec payment_method='wave'
        print('🌊 ━━━ WAVE: CRÉATION COMMANDE AU MOMENT DU PAIEMENT ━━━');
        print('🌊 payment_method envoyé: wave');
        final orderResponse = await OrderService.createOrder(
          shopId: widget.shopId,
          customerName: widget.customerName,
          customerPhone: widget.customerPhone,
          serviceType: widget.serviceType,
          deviceFingerprint: widget.deviceFingerprint,
          items: widget.items,
          paymentMethod: 'wave',
          customerEmail: widget.customerEmail,
          customerAddress: widget.customerAddress,
          deliveryAddress: widget.deliveryAddress,
        );

        final orderIdRaw = orderResponse['order_id'];
        final orderId = orderIdRaw is int
            ? orderIdRaw
            : int.tryParse(orderIdRaw?.toString() ?? '');

        if (orderId == null) {
          throw Exception('Erreur: impossible de récupérer l\'ID de la commande');
        }

        print('🌊 Commande créée: orderId=$orderId');
        print('🌊 ━━━ WAVE: SOUMISSION PREUVE ━━━');

        // Étape 2: Soumettre la preuve Wave sur cette commande
        response = await WavePaymentService.submitWaveProof(
          orderId: orderId,
          screenshotPath: _screenshot!.path,
        );

        // Enrichir la réponse avec les données de la commande
        final totalAmountRaw = orderResponse['total_amount'];
        final totalAmount = totalAmountRaw is num
            ? totalAmountRaw.toDouble()
            : double.tryParse(totalAmountRaw?.toString() ?? '');

        response = WaveProofResponse(
          success: response.success,
          message: response.message,
          orderId: orderId,
          orderNumber: orderResponse['order_number']?.toString(),
          totalAmount: totalAmount ?? widget.amount,
          paymentStatus: response.paymentStatus ?? orderResponse['payment_status']?.toString(),
          receiptUrl: orderResponse['receipt_url']?.toString(),
          receiptViewUrl: orderResponse['receipt_view_url']?.toString(),
          validation: response.validation,
        );

        print('🌊 ✅ Commande créée + preuve soumise avec succès');
      }

      setState(() {
        _response = response;
        _isSubmitting = false;
      });

      // Callback de succès
      if (widget.onPaymentSuccess != null) {
        widget.onPaymentSuccess!(response);
      }

      // La validation est automatique côté backend
      // Naviguer directement vers le succès après soumission
      if (mounted) {
        _showSuccessAndReturn(response);
      }
    } on WaveValidationException catch (e) {
      setState(() {
        _errorMessage = e.message;
        _isSubmitting = false;
      });
      _showValidationErrorDialog(e);
    } catch (e) {
      setState(() {
        _errorMessage = 'Erreur: $e';
        _isSubmitting = false;
      });
    }
  }

  /// Démarrer le polling du statut de paiement
  void _startStatusPolling(int orderId) {
    _pollingTimer?.cancel();
    _pollingTimer = Timer.periodic(const Duration(seconds: 5), (timer) async {
      try {
        final status = await WavePaymentService.checkPaymentStatus(orderId);
        setState(() {
          _paymentStatus = status;
        });

        // Arrêter le polling si le paiement est terminé
        if (status.isPaid || status.isRejected) {
          timer.cancel();
          if (status.isPaid) {
            _showSuccessDialog();
          } else if (status.isRejected) {
            _showRejectionDialog(status.waveRejectionReason);
          }
        }
      } catch (e) {
        print('Erreur polling: $e');
      }
    });
  }

  /// Afficher le dialog d'erreur de validation
  void _showValidationErrorDialog(WaveValidationException e) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(Icons.error_outline, color: Colors.red, size: 28),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Validation échouée',
                style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 18),
              ),
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                e.message,
                style: GoogleFonts.openSans(fontSize: 14),
              ),
              if (e.details.isNotEmpty) ...[
                const SizedBox(height: 12),
                ...e.details.map((d) => Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('• ', style: GoogleFonts.openSans(color: Colors.red)),
                          Expanded(child: Text(d, style: GoogleFonts.openSans(fontSize: 13))),
                        ],
                      ),
                    )),
              ],
              if (e.expected != null && e.found != null) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.orange.shade50,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Attendu: ${e.expected!['amount']} FCFA',
                        style: GoogleFonts.openSans(fontWeight: FontWeight.w600),
                      ),
                      Text(
                        'Trouvé: ${e.found!['amount']} FCFA',
                        style: GoogleFonts.openSans(fontWeight: FontWeight.w600, color: Colors.red),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Réessayer', style: GoogleFonts.openSans(fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }

  /// Preuve soumise avec succès → afficher confirmation et retourner
  void _showSuccessAndReturn(WaveProofResponse response) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(Icons.check_circle, color: Colors.green, size: 32),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Commande envoyée !',
                style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        content: Text(
          'Votre paiement Wave et votre commande ont été envoyés avec succès. Votre commande est en cours de traitement.',
          style: GoogleFonts.openSans(),
        ),
        actions: [
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context); // Fermer le dialog
              Navigator.pop(context, response); // Retourner la réponse au commande_screen
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: waveColor,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: Text('Continuer', style: GoogleFonts.openSans(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  /// Afficher le dialog de succès (polling)
  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(Icons.check_circle, color: Colors.green, size: 32),
            const SizedBox(width: 8),
            Text(
              'Paiement approuvé!',
              style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
            ),
          ],
        ),
        content: Text(
          'Votre paiement Wave a été validé par le vendeur. Votre commande est confirmée.',
          style: GoogleFonts.openSans(),
        ),
        actions: [
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context, _response);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: Text('Continuer', style: GoogleFonts.openSans(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  /// Afficher le dialog de rejet
  void _showRejectionDialog(String? reason) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(Icons.cancel, color: Colors.red, size: 32),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Paiement rejeté',
                style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Votre paiement Wave a été rejeté par le vendeur.',
              style: GoogleFonts.openSans(),
            ),
            if (reason != null) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline, color: Colors.red.shade700, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Raison: $reason',
                        style: GoogleFonts.openSans(color: Colors.red.shade700),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              setState(() {
                _screenshot = null;
                _response = null;
                _paymentStatus = null;
              });
            },
            child: Text('Réessayer', style: GoogleFonts.openSans()),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context, false);
            },
            child: Text('Annuler', style: GoogleFonts.openSans(color: Colors.grey)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final primaryColor = BoutiqueThemeProvider.of(context).primary;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: waveColor,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () {
            _pollingTimer?.cancel();
            if (widget.onCancel != null) {
              widget.onCancel!();
            }
            Navigator.pop(context);
          },
        ),
        title: Text(
          'Paiement Wave',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Montant à payer
            _buildAmountCard(),

            const SizedBox(height: 24),

            // Instructions
            _buildInstructionsCard(),

            const SizedBox(height: 24),

            // Étape 1: Ouvrir Wave
            _buildStep1Card(),

            const SizedBox(height: 16),

            // Étape 2: Sélectionner la capture
            _buildStep2Card(),

            // Aperçu de la capture
            if (_screenshot != null) ...[
              const SizedBox(height: 16),
              _buildScreenshotPreview(),
            ],

            // Message d'erreur
            if (_errorMessage != null) ...[
              const SizedBox(height: 16),
              _buildErrorMessage(),
            ],

            // Statut de validation
            if (_response != null || _paymentStatus != null) ...[
              const SizedBox(height: 16),
              _buildStatusCard(),
            ],

            const SizedBox(height: 24),

            // Bouton soumettre
            _buildSubmitButton(primaryColor),
          ],
        ),
      ),
    );
  }

  Widget _buildAmountCard() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [waveColor, waveColor.withOpacity(0.8)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: waveColor.withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Text(
            'Montant à payer',
            style: GoogleFonts.openSans(
              fontSize: 14,
              color: Colors.white.withOpacity(0.9),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '${widget.amount.toStringAsFixed(0)} FCFA',
            style: GoogleFonts.poppins(
              fontSize: 36,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInstructionsCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _waveOpened ? Colors.green.shade50 : Colors.blue.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: _waveOpened ? Colors.green.shade100 : Colors.blue.shade100,
        ),
      ),
      child: Row(
        children: [
          Icon(
            _waveOpened ? Icons.camera_alt : Icons.info_outline,
            color: _waveOpened ? Colors.green.shade700 : waveColor,
            size: 24,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              _waveOpened
                  ? 'Apres avoir payé, prenez une capture d\'écran de la confirmation Wave et envoyez-la ci-dessous.'
                  : 'Vous allez être redirigé vers Wave pour effectuer le paiement.',
              style: GoogleFonts.openSans(
                fontSize: 13,
                color: _waveOpened ? Colors.green.shade800 : Colors.blue.shade800,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStep1Card() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: _waveOpened ? Colors.green : Colors.grey.shade200,
          width: _waveOpened ? 2 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: _openWaveApp,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: (_waveOpened ? Colors.green : waveColor).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Center(
                    child: _waveOpened
                        ? Icon(Icons.check, color: Colors.green, size: 24)
                        : Text(
                            '1',
                            style: GoogleFonts.poppins(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: waveColor,
                            ),
                          ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _waveOpened ? 'Wave ouvert' : 'Ouvrir Wave et payer',
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _waveOpened
                            ? 'Effectuez le paiement puis revenez ici'
                            : 'Redirection vers Wave...',
                        style: GoogleFonts.openSans(
                          fontSize: 13,
                          color: _waveOpened ? Colors.green : Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
                if (_waveOpened)
                  TextButton(
                    onPressed: _openWaveApp,
                    child: Text(
                      'Réouvrir',
                      style: GoogleFonts.openSans(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: waveColor,
                      ),
                    ),
                  )
                else
                  SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: waveColor,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStep2Card() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: _screenshot != null ? Colors.green : Colors.grey.shade200,
          width: _screenshot != null ? 2 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: (_screenshot != null ? Colors.green : waveColor).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Center(
                    child: _screenshot != null
                        ? Icon(Icons.check, color: Colors.green, size: 24)
                        : Text(
                            '2',
                            style: GoogleFonts.poppins(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: waveColor,
                            ),
                          ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Capture d\'écran de confirmation',
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _screenshot != null
                            ? 'Capture sélectionnée'
                            : 'Sélectionnez ou prenez une photo',
                        style: GoogleFonts.openSans(
                          fontSize: 13,
                          color: _screenshot != null ? Colors.green : Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Divider(height: 1, color: Colors.grey.shade200),
          Row(
            children: [
              Expanded(
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: _pickScreenshot,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.photo_library, color: waveColor, size: 20),
                          const SizedBox(width: 8),
                          Text(
                            'Galerie',
                            style: GoogleFonts.openSans(
                              fontWeight: FontWeight.w600,
                              color: waveColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              Container(width: 1, height: 40, color: Colors.grey.shade200),
              Expanded(
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: _takeScreenshot,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.camera_alt, color: waveColor, size: 20),
                          const SizedBox(width: 8),
                          Text(
                            'Caméra',
                            style: GoogleFonts.openSans(
                              fontWeight: FontWeight.w600,
                              color: waveColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildScreenshotPreview() {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.green, width: 2),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: Stack(
          children: [
            Image.file(
              File(_screenshot!.path),
              height: 200,
              width: double.infinity,
              fit: BoxFit.cover,
            ),
            Positioned(
              top: 8,
              right: 8,
              child: GestureDetector(
                onTap: () {
                  setState(() {
                    _screenshot = null;
                  });
                },
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: Colors.red,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.close, color: Colors.white, size: 16),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorMessage() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.red.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.red.shade200),
      ),
      child: Row(
        children: [
          Icon(Icons.error_outline, color: Colors.red.shade700, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              _errorMessage!,
              style: GoogleFonts.openSans(
                color: Colors.red.shade700,
                fontSize: 13,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusCard() {
    final status = _paymentStatus?.paymentStatus ?? _response?.paymentStatus ?? 'pending_verification';

    Color statusColor;
    IconData statusIcon;
    String statusText;

    switch (status) {
      case 'paid':
        statusColor = Colors.green;
        statusIcon = Icons.check_circle;
        statusText = 'Paiement approuvé';
        break;
      case 'rejected':
        statusColor = Colors.red;
        statusIcon = Icons.cancel;
        statusText = 'Paiement rejeté';
        break;
      case 'pending_verification':
        statusColor = Colors.orange;
        statusIcon = Icons.hourglass_empty;
        statusText = 'En attente de vérification';
        break;
      default:
        statusColor = Colors.blue;
        statusIcon = Icons.info;
        statusText = 'En cours de traitement';
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: statusColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: statusColor.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          if (status == 'pending_verification')
            SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: statusColor,
              ),
            )
          else
            Icon(statusIcon, color: statusColor, size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  statusText,
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.w600,
                    color: statusColor,
                  ),
                ),
                if (status == 'pending_verification')
                  Text(
                    'Le vendeur vérifie votre paiement...',
                    style: GoogleFonts.openSans(
                      fontSize: 12,
                      color: Colors.grey.shade600,
                    ),
                  ),
                if (_response?.validation != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    'Score de confiance: ${_response!.validation!.score}/5',
                    style: GoogleFonts.openSans(
                      fontSize: 12,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSubmitButton(Color primaryColor) {
    final bool canSubmit = _screenshot != null && !_isSubmitting && _response == null;

    return ElevatedButton(
      onPressed: canSubmit ? _submitProof : null,
      style: ElevatedButton.styleFrom(
        backgroundColor: waveColor,
        disabledBackgroundColor: Colors.grey.shade300,
        padding: const EdgeInsets.symmetric(vertical: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        elevation: canSubmit ? 4 : 0,
      ),
      child: _isSubmitting
          ? Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  'Envoi en cours...',
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ],
            )
          : Text(
              _response != null ? 'Preuve envoyée' : 'Envoyer la preuve de paiement',
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
    );
  }
}
