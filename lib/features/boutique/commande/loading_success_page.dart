import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';
import 'package:open_filex/open_filex.dart';
import 'package:permission_handler/permission_handler.dart';
import 'order_tracking_api_page.dart';
import '../loyalty/create_loyalty_card_page.dart';
import '../../../core/services/boutique_theme_provider.dart';
import '../../../services/loyalty_service.dart';

/// Page de succès simple apres commande
class LoadingSuccessPage extends StatefulWidget {
  final Map<String, dynamic>? orderData;

  const LoadingSuccessPage({super.key, this.orderData});

  @override
  State<LoadingSuccessPage> createState() => _LoadingSuccessPageState();
}

class _LoadingSuccessPageState extends State<LoadingSuccessPage>
    with SingleTickerProviderStateMixin {
  late AnimationController _checkController;
  late Animation<double> _checkAnimation;
  bool _hasLoyaltyCard = false;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();

    _checkController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _checkAnimation = CurvedAnimation(
      parent: _checkController,
      curve: Curves.elasticOut,
    );

    _checkController.forward();
    _checkLoyaltyCard();
  }

  Future<void> _checkLoyaltyCard() async {
    if (widget.orderData != null && widget.orderData!['shopId'] != null) {
      try {
        _hasLoyaltyCard = await LoyaltyService.hasCard(
          widget.orderData!['shopId'] as int,
        );
      } catch (e) {
        _hasLoyaltyCard = false;
      }
    }
    if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _checkController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final orderNumber = widget.orderData?['orderNumber'] as String? ?? 'N/A';
    final primaryColor = BoutiqueThemeProvider.of(context).primary;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
          child: Column(
            children: [
              const SizedBox(height: 40),

              // Icone de succes
              ScaleTransition(
                scale: _checkAnimation,
                child: Container(
                  width: 90,
                  height: 90,
                  decoration: BoxDecoration(
                    color: const Color(0xFF10B981),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF10B981).withOpacity(0.3),
                        blurRadius: 20,
                        spreadRadius: 4,
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.check_rounded,
                    size: 50,
                    color: Colors.white,
                  ),
                ),
              ),
              const SizedBox(height: 28),

              // Titre
              Text(
                'Commande confirmee !',
                style: GoogleFonts.poppins(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Merci pour votre commande',
                style: GoogleFonts.openSans(
                  fontSize: 15,
                  color: Colors.grey.shade600,
                ),
              ),
              const SizedBox(height: 28),

              // Numero de commande
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                decoration: BoxDecoration(
                  color: const Color(0xFF3B82F6).withOpacity(0.08),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: const Color(0xFF3B82F6).withOpacity(0.2),
                  ),
                ),
                child: Column(
                  children: [
                    Text(
                      'Numero de commande',
                      style: GoogleFonts.openSans(
                        fontSize: 13,
                        color: Colors.grey.shade600,
                      ),
                    ),
                    const SizedBox(height: 6),
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        orderNumber,
                        style: GoogleFonts.poppins(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF3B82F6),
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Message preparation
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFF10B981).withOpacity(0.08),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  'Votre commande est en cours de preparation.',
                  style: GoogleFonts.openSans(
                    fontSize: 13,
                    color: const Color(0xFF059669),
                    fontWeight: FontWeight.w500,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 32),

              // Boutons d'action
              if (!_isLoading) ...[
                // Carte de fidelite
                if (!_hasLoyaltyCard)
                  _buildActionButton(
                    label: 'Creer carte de fidelite',
                    icon: Icons.card_giftcard,
                    color: const Color(0xFFD946EF),
                    onPressed: () {
                      final shop = BoutiqueThemeProvider.shopOf(context);
                      final shopId = widget.orderData?['shopId'] ?? 1;
                      final boutiqueName = widget.orderData?['boutiqueName'] ?? 'Tika Shop';

                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => BoutiqueThemeProvider(
                            shop: shop,
                            child: CreateLoyaltyCardPage(
                              shopId: shopId,
                              boutiqueName: boutiqueName,
                              shop: shop,
                            ),
                          ),
                        ),
                      );
                    },
                  ),

                if (!_hasLoyaltyCard) const SizedBox(height: 12),

                // Voir le recu
                _buildActionButton(
                  label: 'Voir le recu',
                  icon: Icons.receipt_long,
                  color: const Color(0xFF3B82F6),
                  onPressed: () => _openReceipt(),
                ),
                const SizedBox(height: 12),

                // Telecharger le recu
                _buildActionButton(
                  label: 'Telecharger le recu',
                  icon: Icons.download,
                  color: const Color(0xFF10B981),
                  onPressed: () => _downloadReceipt(),
                ),
                const SizedBox(height: 12),

                // Suivre ma commande
                _buildActionButton(
                  label: 'Suivre ma commande',
                  icon: Icons.local_shipping_outlined,
                  color: const Color(0xFFF97316),
                  onPressed: () => _trackOrder(),
                ),
                const SizedBox(height: 20),

                // Bouton Fermer
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: OutlinedButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.grey.shade700,
                      side: BorderSide(color: Colors.grey.shade300, width: 1.5),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      'Retour a la boutique',
                      style: GoogleFonts.poppins(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActionButton({
    required String label,
    required IconData icon,
    required Color color,
    required VoidCallback onPressed,
  }) {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 20),
            const SizedBox(width: 10),
            Text(
              label,
              style: GoogleFonts.poppins(
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- Actions ---

  Future<void> _openReceipt() async {
    if (widget.orderData == null || widget.orderData!['receiptViewUrl'] == null) {
      _showSnack('Recu non disponible', Colors.orange);
      return;
    }
    final uri = Uri.parse(widget.orderData!['receiptViewUrl'] as String);
    try {
      await launchUrl(uri, mode: LaunchMode.inAppBrowserView);
    } catch (e) {
      if (mounted) _showSnack('Impossible d\'ouvrir le recu', Colors.red);
    }
  }

  Future<void> _downloadReceipt() async {
    if (widget.orderData == null || widget.orderData!['receiptUrl'] == null) {
      _showSnack('Recu non disponible', Colors.orange);
      return;
    }

    final receiptUrl = widget.orderData!['receiptUrl'] as String;
    final orderNum = widget.orderData!['orderNumber'] as String? ?? 'recu';

    _showSnack('Telechargement en cours...', const Color(0xFF10B981));

    try {
      if (Platform.isAndroid) {
        final status = await Permission.storage.request();
        if (!status.isGranted) {
          await Permission.photos.request();
        }
      }

      Directory? downloadDir;
      if (Platform.isAndroid) {
        downloadDir = Directory('/storage/emulated/0/Download');
        if (!await downloadDir.exists()) {
          downloadDir = await getExternalStorageDirectory();
        }
      } else {
        downloadDir = await getApplicationDocumentsDirectory();
      }

      if (downloadDir == null) throw Exception('Dossier non accessible');

      final filePath = '${downloadDir.path}/recu_$orderNum.pdf';
      await Dio().download(
        receiptUrl,
        filePath,
        options: Options(responseType: ResponseType.bytes, followRedirects: true),
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Recu telecharge !'),
          backgroundColor: const Color(0xFF10B981),
          action: SnackBarAction(
            label: 'Ouvrir',
            textColor: Colors.white,
            onPressed: () => OpenFilex.open(filePath),
          ),
        ),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        _showSnack('Erreur de telechargement', Colors.red);
      }
    }
  }

  void _trackOrder() {
    if (widget.orderData == null ||
        widget.orderData!['orderNumber'] == null ||
        widget.orderData!['customerPhone'] == null) return;

    final shop = BoutiqueThemeProvider.shopOf(context);

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => BoutiqueThemeProvider(
          shop: shop,
          child: OrderTrackingApiPage(
            orderNumber: widget.orderData!['orderNumber'],
            customerPhone: widget.orderData!['customerPhone'],
          ),
        ),
      ),
    );
  }

  void _showSnack(String message, Color color) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: color),
    );
  }
}

/// Page de succes pour commande En boutique (A emporter)
class LoadingSuccessInStorePage extends StatefulWidget {
  final Map<String, dynamic>? orderData;

  const LoadingSuccessInStorePage({super.key, this.orderData});

  @override
  State<LoadingSuccessInStorePage> createState() => _LoadingSuccessInStorePageState();
}

class _LoadingSuccessInStorePageState extends State<LoadingSuccessInStorePage>
    with SingleTickerProviderStateMixin {
  late AnimationController _checkController;
  late Animation<double> _checkAnimation;
  bool _hasLoyaltyCard = false;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();

    _checkController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _checkAnimation = CurvedAnimation(
      parent: _checkController,
      curve: Curves.elasticOut,
    );

    _checkController.forward();
    _checkLoyaltyCard();
  }

  Future<void> _checkLoyaltyCard() async {
    if (widget.orderData != null && widget.orderData!['shopId'] != null) {
      try {
        _hasLoyaltyCard = await LoyaltyService.hasCard(
          widget.orderData!['shopId'] as int,
        );
      } catch (e) {
        _hasLoyaltyCard = false;
      }
    }
    if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _checkController.dispose();
    super.dispose();
  }

  String _formatPickupDateTime(DateTime? date, TimeOfDay? time) {
    if (date == null || time == null) return '';
    final months = ['jan', 'fev', 'mar', 'avr', 'mai', 'juin', 'juil', 'aout', 'sep', 'oct', 'nov', 'dec'];
    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');
    return '${date.day} ${months[date.month - 1]} ${date.year} a $hour:$minute';
  }

  @override
  Widget build(BuildContext context) {
    final primaryColor = BoutiqueThemeProvider.of(context).primary;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
          child: Column(
            children: [
              const SizedBox(height: 40),

              // Icone de succes
              ScaleTransition(
                scale: _checkAnimation,
                child: Container(
                  width: 90,
                  height: 90,
                  decoration: BoxDecoration(
                    color: const Color(0xFF10B981),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF10B981).withOpacity(0.3),
                        blurRadius: 20,
                        spreadRadius: 4,
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.check_rounded,
                    size: 50,
                    color: Colors.white,
                  ),
                ),
              ),
              const SizedBox(height: 28),

              // Titre
              Text(
                'Commande enregistree !',
                style: GoogleFonts.poppins(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Votre commande a ete enregistree avec succes',
                style: GoogleFonts.openSans(
                  fontSize: 15,
                  color: Colors.grey.shade600,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 28),

              // Info recuperation
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFF10B981).withOpacity(0.08),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: const Color(0xFF10B981).withOpacity(0.2),
                  ),
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Icon(Icons.store, color: const Color(0xFF059669), size: 22),
                        const SizedBox(width: 10),
                        Text(
                          'Recuperation en boutique',
                          style: GoogleFonts.poppins(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF059669),
                          ),
                        ),
                      ],
                    ),
                    if (widget.orderData?['pickupDate'] != null &&
                        widget.orderData?['pickupTime'] != null) ...[
                      const SizedBox(height: 12),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.calendar_today, size: 18, color: Colors.grey.shade700),
                            const SizedBox(width: 10),
                            Text(
                              _formatPickupDateTime(
                                widget.orderData!['pickupDate'],
                                widget.orderData!['pickupTime'],
                              ),
                              style: GoogleFonts.openSans(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: Colors.grey.shade800,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 32),

              // Boutons
              if (!_isLoading) ...[
                if (!_hasLoyaltyCard) ...[
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: OutlinedButton.icon(
                      onPressed: () {
                        final shop = BoutiqueThemeProvider.shopOf(context);
                        final shopId = widget.orderData?['shopId'] ?? 1;
                        final boutiqueName = widget.orderData?['boutiqueName'] ?? 'Tika Shop';

                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) => BoutiqueThemeProvider(
                              shop: shop,
                              child: CreateLoyaltyCardPage(
                                shopId: shopId,
                                boutiqueName: boutiqueName,
                                shop: shop,
                              ),
                            ),
                          ),
                        );
                      },
                      icon: const Icon(Icons.card_giftcard, size: 20),
                      label: Text(
                        'Creer une carte de fidelite',
                        style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w600),
                      ),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFFD946EF),
                        side: const BorderSide(color: Color(0xFFD946EF), width: 1.5),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],

                // Fermer
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryColor,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      'Retour a la boutique',
                      style: GoogleFonts.poppins(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
