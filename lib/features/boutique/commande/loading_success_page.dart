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

/// Page de chargement avec animation de succès
class LoadingSuccessPage extends StatefulWidget {
  final Map<String, dynamic>? orderData;

  const LoadingSuccessPage({super.key, this.orderData});

  @override
  State<LoadingSuccessPage> createState() => _LoadingSuccessPageState();
}

class _LoadingSuccessPageState extends State<LoadingSuccessPage>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  bool _hasLoyaltyCard = false;

  @override
  void initState() {
    super.initState();

    // Contrôleur principal pour l'animation de succès
    _controller = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );

    _scaleAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOut,
    );

    // Lancer l'animation de succès immédiatement
    _controller.forward();

    // Afficher le modal immédiatement (pas de délai)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _showSuccessModal();
      }
    });
  }

  // Afficher le modal de succès sur la page de chargement
  void _showSuccessModal() async {
    // Vérifier si l'utilisateur a déjà une carte de fidélité
    if (widget.orderData != null &&
        widget.orderData!['shopId'] != null &&
        widget.orderData!['customerPhone'] != null) {
      try {
        _hasLoyaltyCard = await LoyaltyService.hasCard(
          shopId: widget.orderData!['shopId'] as int,
          phone: widget.orderData!['customerPhone'] as String,
        );
      } catch (e) {
        print('Erreur lors de la vérification de la carte de fidélité: $e');
        _hasLoyaltyCard = false;
      }
    }

    if (!mounted) return;

    // Récupérer le numéro de commande
    final orderNumber = widget.orderData?['orderNumber'] as String? ?? 'N/A';

    showDialog(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black.withOpacity(0.5),
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        elevation: 0,
        backgroundColor: Colors.white,
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Icône de succès avec cercle vert
                Container(
                  width: 70,
                  height: 70,
                  decoration: BoxDecoration(
                    color: const Color(0xFFD1F2EB),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.check,
                    size: 40,
                    color: Color(0xFF10B981),
                  ),
                ),
                const SizedBox(height: 16),

                // Titre
                Text(
                  'Commande confirmée !',
                  style: GoogleFonts.openSans(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 12),

                // Numéro de commande
                Column(
                  children: [
                    Text(
                      'Numéro de commande',
                      style: GoogleFonts.openSans(
                        fontSize: 13,
                        color: Colors.grey.shade600,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      orderNumber,
                      style: GoogleFonts.openSans(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF3B82F6),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // Bouton Créer ma carte de fidélité (gradient violet/magenta)
                if (!_hasLoyaltyCard) ...[
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      onPressed: () async {
                        final navigator = Navigator.of(context);
                        final rootNavigator = Navigator.of(context, rootNavigator: true);
                        final shop = BoutiqueThemeProvider.shopOf(context);
                        final shopId = widget.orderData?['shopId'] ?? 1;
                        final boutiqueName = widget.orderData?['boutiqueName'] ?? 'Tika Shop';

                        navigator.pop();
                        await Future.delayed(const Duration(milliseconds: 200));

                        rootNavigator.push(
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
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFD946EF),
                        foregroundColor: Colors.white,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.card_giftcard, size: 16),
                          const SizedBox(width: 6),
                          Flexible(
                            child: Text(
                              'Créer carte de fidélité',
                              style: GoogleFonts.openSans(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                ],

                // Bouton Voir le reçu (bleu)
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    onPressed: () async {
                      if (widget.orderData != null && widget.orderData!['receiptViewUrl'] != null) {
                        final receiptViewUrl = widget.orderData!['receiptViewUrl'] as String;
                        final uri = Uri.parse(receiptViewUrl);

                        try {
                          final canLaunch = await canLaunchUrl(uri);
                          if (canLaunch) {
                            // Ouvrir dans un navigateur in-app avec barre d'outils
                            await launchUrl(
                              uri,
                              mode: LaunchMode.inAppBrowserView,
                              webViewConfiguration: const WebViewConfiguration(
                                enableJavaScript: true,
                                enableDomStorage: true,
                              ),
                            );
                          } else {
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Impossible d\'ouvrir le reçu'),
                                  backgroundColor: Colors.red,
                                ),
                              );
                            }
                          }
                        } catch (e) {
                          print('Erreur lors de l\'ouverture du reçu: $e');
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Erreur lors de l\'ouverture du reçu'),
                                backgroundColor: Colors.red,
                              ),
                            );
                          }
                        }
                      } else {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Reçu non disponible'),
                              backgroundColor: Colors.orange,
                            ),
                          );
                        }
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF3B82F6),
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.receipt_long, size: 18),
                        const SizedBox(width: 8),
                        Text(
                          'Voir le reçu',
                          style: GoogleFonts.openSans(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 8),

                // Bouton Télécharger le reçu (vert)
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    onPressed: () async {
                      if (widget.orderData != null && widget.orderData!['receiptUrl'] != null) {
                        final receiptUrl = widget.orderData!['receiptUrl'] as String;
                        final orderNumber = widget.orderData!['orderNumber'] as String? ?? 'recu';

                        try {
                          // Afficher un message de chargement
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Row(
                                  children: [
                                    SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Text('Téléchargement en cours...'),
                                  ],
                                ),
                                duration: Duration(seconds: 30),
                                backgroundColor: const Color(0xFF10B981),
                              ),
                            );
                          }

                          // Demander la permission de stockage sur Android
                          if (Platform.isAndroid) {
                            final status = await Permission.storage.request();
                            if (!status.isGranted) {
                              // Essayer avec la permission photos/media pour Android 13+
                              await Permission.photos.request();
                            }
                          }

                          // Obtenir le répertoire de téléchargement
                          Directory? downloadDir;
                          if (Platform.isAndroid) {
                            downloadDir = Directory('/storage/emulated/0/Download');
                            if (!await downloadDir.exists()) {
                              downloadDir = await getExternalStorageDirectory();
                            }
                          } else {
                            downloadDir = await getApplicationDocumentsDirectory();
                          }

                          if (downloadDir == null) {
                            throw Exception('Impossible d\'accéder au dossier de téléchargement');
                          }

                          // Nom du fichier
                          final fileName = 'recu_$orderNumber.pdf';
                          final filePath = '${downloadDir.path}/$fileName';

                          // Télécharger avec dio
                          final dio = Dio();
                          await dio.download(
                            receiptUrl,
                            filePath,
                            options: Options(
                              responseType: ResponseType.bytes,
                              followRedirects: true,
                            ),
                          );

                          // Fermer le snackbar de chargement
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).hideCurrentSnackBar();
                          }

                          // Afficher succès et proposer d'ouvrir
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Row(
                                  children: [
                                    const Icon(Icons.check_circle, color: Colors.white, size: 20),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Text('Reçu téléchargé: $fileName'),
                                    ),
                                  ],
                                ),
                                duration: Duration(seconds: 5),
                                backgroundColor: const Color(0xFF10B981),
                                action: SnackBarAction(
                                  label: 'Ouvrir',
                                  textColor: Colors.white,
                                  onPressed: () async {
                                    await OpenFilex.open(filePath);
                                  },
                                ),
                              ),
                            );
                          }
                        } catch (e) {
                          print('Erreur lors du téléchargement du reçu: $e');
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).hideCurrentSnackBar();
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Erreur lors du téléchargement: ${e.toString()}'),
                                backgroundColor: Colors.red,
                                duration: Duration(seconds: 4),
                              ),
                            );
                          }
                        }
                      } else {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Reçu non disponible pour téléchargement'),
                              backgroundColor: Colors.orange,
                            ),
                          );
                        }
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF10B981),
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.download, size: 18),
                        const SizedBox(width: 8),
                        Text(
                          'Télécharger le reçu',
                          style: GoogleFonts.openSans(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 8),

                // Bouton Suivre ma commande (orange)
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    onPressed: () async {
                      if (widget.orderData != null &&
                          widget.orderData!['orderNumber'] != null &&
                          widget.orderData!['customerPhone'] != null) {
                        final navigator = Navigator.of(context);
                        final rootNavigator = Navigator.of(context, rootNavigator: true);
                        final shop = BoutiqueThemeProvider.shopOf(context);
                        final orderNum = widget.orderData!['orderNumber'];
                        final customerPhone = widget.orderData!['customerPhone'];

                        navigator.pop();
                        await Future.delayed(const Duration(milliseconds: 200));

                        rootNavigator.push(
                          MaterialPageRoute(
                            builder: (context) => BoutiqueThemeProvider(
                              shop: shop,
                              child: OrderTrackingApiPage(
                                orderNumber: orderNum,
                                customerPhone: customerPhone,
                              ),
                            ),
                          ),
                        );
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFF97316),
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.search, size: 18),
                        const SizedBox(width: 8),
                        Text(
                          'Suivre ma commande',
                          style: GoogleFonts.openSans(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 8),

                // Bouton Fermer (gris)
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.of(context).pop(); // Fermer le modal
                      Navigator.of(context).pop(); // Fermer la page de chargement
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.grey.shade300,
                      foregroundColor: Colors.grey.shade800,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      'Fermer',
                      style: GoogleFonts.openSans(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Icône de succès
              ScaleTransition(
                scale: _scaleAnimation,
                child: Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    color: const Color(0xFF4CAF50).withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.check_circle,
                    size: 70,
                    color: Color(0xFF4CAF50),
                  ),
                ),
              ),
              const SizedBox(height: 32),
              FadeTransition(
                opacity: _controller,
                child: Column(
                  children: [
                    Text(
                      'Commande validée avec succès !',
                      style: GoogleFonts.openSans(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF4CAF50),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Votre commande a été confirmée avec succès',
                      style: GoogleFonts.openSans(
                        fontSize: 14,
                        color: Colors.grey.shade600,
                        fontWeight: FontWeight.w400,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

}

/// Page de chargement avec animation de succès pour commande En boutique
class LoadingSuccessInStorePage extends StatefulWidget {
  final Map<String, dynamic>? orderData;

  const LoadingSuccessInStorePage({super.key, this.orderData});

  @override
  State<LoadingSuccessInStorePage> createState() => _LoadingSuccessInStorePageState();
}

class _LoadingSuccessInStorePageState extends State<LoadingSuccessInStorePage>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  bool _hasLoyaltyCard = false;

  @override
  void initState() {
    super.initState();

    // Contrôleur principal pour l'animation de succès
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );

    _scaleAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.elasticOut,
    );

    // Lancer l'animation de succès immédiatement
    _controller.forward();

    // Afficher le modal après 2 secondes pour laisser voir la page de succès
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) {
        _showSuccessModal();
      }
    });
  }

  // Afficher le modal de succès pour En boutique
  void _showSuccessModal() async {
    // Vérifier si l'utilisateur a déjà une carte de fidélité
    if (widget.orderData != null &&
        widget.orderData!['shopId'] != null &&
        widget.orderData!['customerPhone'] != null) {
      try {
        _hasLoyaltyCard = await LoyaltyService.hasCard(
          shopId: widget.orderData!['shopId'] as int,
          phone: widget.orderData!['customerPhone'] as String,
        );
      } catch (e) {
        print('Erreur lors de la vérification de la carte de fidélité: $e');
        _hasLoyaltyCard = false;
      }
    }

    if (!mounted) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        backgroundColor: Colors.white,
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Icône de succès
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: const Color.fromARGB(255, 175, 76, 167).withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.check, size: 50, color: Color(0xFF4CAF50)),
              ),
              const SizedBox(height: 24),

              // Titre
              Text(
                'Commande confirmée !',
                style: GoogleFonts.openSans(fontSize: 22, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),

              // Message
              Text(
                'Votre commande a été enregistrée avec succès',
                style: GoogleFonts.openSans(fontSize: 15, color: Colors.grey.shade600, height: 1.4),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),

              // Info récupération
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFF10B981).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.store, color: Color(0xFF10B981), size: 20),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Récupération en boutique',
                            style: GoogleFonts.openSans(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFF10B981),
                            ),
                          ),
                        ),
                      ],
                    ),
                    if (widget.orderData?['pickupDate'] != null &&
                        widget.orderData?['pickupTime'] != null) ...[
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          const Icon(Icons.calendar_today, color: Colors.grey, size: 16),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              _formatPickupDateTime(
                                widget.orderData!['pickupDate'],
                                widget.orderData!['pickupTime'],
                              ),
                              style: GoogleFonts.openSans(
                                fontSize: 13,
                                color: Colors.grey.shade700,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 24),
              // Bouton Créer carte de fidélité (seulement si pas encore créée)
              if (!_hasLoyaltyCard) ...[
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () async {
                      print('🔍 [LoadingSuccessInStorePage] Bouton Créer carte de fidélité cliqué');

                      // Capturer le navigator et les données avant de fermer le dialog
                      final navigator = Navigator.of(context);
                      final rootNavigator = Navigator.of(context, rootNavigator: true);
                      final shop = BoutiqueThemeProvider.shopOf(context);
                      final shopId = widget.orderData?['shopId'] ?? 1;
                      final boutiqueName = widget.orderData?['boutiqueName'] ?? 'Tika Shop';

                      // Fermer le modal (dialog)
                      navigator.pop();

                      // Attendre que le dialog soit fermé
                      await Future.delayed(const Duration(milliseconds: 200));

                      print('📱 [LoadingSuccessInStorePage] Navigation vers CreateLoyaltyCardPage...');
                      // Utiliser le root navigator pour naviguer vers la page de création de carte
                      rootNavigator.push(
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
                    icon: const Icon(Icons.credit_card_outlined, size: 20),
                    label: Text(
                      'Créer une carte de fidélité',
                      style: GoogleFonts.openSans(fontSize: 15, fontWeight: FontWeight.w600),
                    ),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: BoutiqueThemeProvider.of(context).primary,
                      side: BorderSide(color: BoutiqueThemeProvider.of(context).primary),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
              ],

              // Bouton Fermer
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).pop(); // Fermer le modal
                    Navigator.of(context).pop(); // Fermer la page de chargement
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: BoutiqueThemeProvider.of(context).primary,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: Text(
                    'Fermer',
                    style: GoogleFonts.openSans(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Formater date et heure de récupération
  String _formatPickupDateTime(DateTime? date, TimeOfDay? time) {
    if (date == null || time == null) return '';
    final months = ['jan', 'fév', 'mar', 'avr', 'mai', 'juin', 'juil', 'août', 'sep', 'oct', 'nov', 'déc'];
    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');
    return '${date.day} ${months[date.month - 1]} ${date.year} à $hour:$minute';
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Icône de succès
              ScaleTransition(
                scale: _scaleAnimation,
                child: Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    color: const Color(0xFF4CAF50).withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.check_circle,
                    size: 70,
                    color: Color(0xFF4CAF50),
                  ),
                ),
              ),
              const SizedBox(height: 32),
              FadeTransition(
                opacity: _controller,
                child: Column(
                  children: [
                    Text(
                      'Commande enregistrée !',
                      style: GoogleFonts.openSans(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF4CAF50),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Récupération en boutique',
                      style: GoogleFonts.openSans(
                        fontSize: 14,
                        color: Colors.grey.shade600,
                        fontWeight: FontWeight.w400,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

}
