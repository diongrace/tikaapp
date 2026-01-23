import 'dart:io';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';
import 'package:open_filex/open_filex.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:confetti/confetti.dart';
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
    with TickerProviderStateMixin {
  late AnimationController _scaleController;
  late AnimationController _pulseController;
  late AnimationController _bounceController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _pulseAnimation;
  late Animation<double> _bounceAnimation;
  late ConfettiController _confettiController;
  bool _hasLoyaltyCard = false;

  @override
  void initState() {
    super.initState();

    // Confetti controller - longer duration for better celebration effect
    _confettiController = ConfettiController(duration: const Duration(seconds: 5));

    // Scale animation for checkmark
    _scaleController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _scaleAnimation = CurvedAnimation(
      parent: _scaleController,
      curve: Curves.elasticOut,
    );

    // Pulse animation for glow effect
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat(reverse: true);
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.15).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    // Bounce animation for emojis
    _bounceController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    )..repeat(reverse: true);
    _bounceAnimation = Tween<double>(begin: 0, end: -10).animate(
      CurvedAnimation(parent: _bounceController, curve: Curves.easeInOut),
    );

    // Start animations
    _scaleController.forward();
    _confettiController.play();

    // Show modal after 4 seconds to let user enjoy the celebration
    Future.delayed(const Duration(seconds: 4), () {
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
        insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Animated success icon with gradient
                TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0.0, end: 1.0),
                  duration: const Duration(milliseconds: 500),
                  builder: (context, value, child) {
                    return Transform.scale(
                      scale: value,
                      child: Container(
                        width: 60,
                        height: 60,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              const Color(0xFF10B981),
                              const Color(0xFF34D399),
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF10B981).withOpacity(0.3),
                              blurRadius: 15,
                              spreadRadius: 3,
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.check_rounded,
                          size: 35,
                          color: Colors.white,
                        ),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 16),

                // Title with emoji
                Column(
                  children: [
                    const Text('🎉', style: TextStyle(fontSize: 24)),
                    const SizedBox(height: 6),
                    Text(
                      'Commande confirmée !',
                      style: GoogleFonts.poppins(
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
                const SizedBox(height: 14),

                // Order number card
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        const Color(0xFF3B82F6).withOpacity(0.1),
                        const Color(0xFF8B5CF6).withOpacity(0.1),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: const Color(0xFF3B82F6).withOpacity(0.3),
                    ),
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text('📦', style: TextStyle(fontSize: 14)),
                          const SizedBox(width: 6),
                          Text(
                            'Numéro de commande',
                            style: GoogleFonts.openSans(
                              fontSize: 12,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          orderNumber,
                          style: GoogleFonts.poppins(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFF3B82F6),
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),

                // Success message
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFF10B981).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    children: [
                      const Text('✨', style: TextStyle(fontSize: 16)),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Merci ! Votre commande est en préparation.',
                          style: GoogleFonts.openSans(
                            fontSize: 12,
                            color: const Color(0xFF059669),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Bouton Créer ma carte de fidélité
                if (!_hasLoyaltyCard) ...[
                  SizedBox(
                    width: double.infinity,
                    height: 44,
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
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text('🎁', style: TextStyle(fontSize: 16)),
                          const SizedBox(width: 6),
                          Text(
                            'Créer carte de fidélité',
                            style: GoogleFonts.poppins(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                ],

                // Bouton Voir le reçu
                SizedBox(
                  width: double.infinity,
                  height: 44,
                  child: ElevatedButton(
                    onPressed: () async {
                      if (widget.orderData != null && widget.orderData!['receiptViewUrl'] != null) {
                        final receiptViewUrl = widget.orderData!['receiptViewUrl'] as String;
                        final uri = Uri.parse(receiptViewUrl);

                        try {
                          final canLaunch = await canLaunchUrl(uri);
                          if (canLaunch) {
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
                        const Text('🧾', style: TextStyle(fontSize: 16)),
                        const SizedBox(width: 6),
                        Text(
                          'Voir le reçu',
                          style: GoogleFonts.poppins(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 8),

                // Bouton Télécharger le reçu
                SizedBox(
                  width: double.infinity,
                  height: 44,
                  child: ElevatedButton(
                    onPressed: () async {
                      if (widget.orderData != null && widget.orderData!['receiptUrl'] != null) {
                        final receiptUrl = widget.orderData!['receiptUrl'] as String;
                        final orderNumber = widget.orderData!['orderNumber'] as String? ?? 'recu';

                        try {
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Row(
                                  children: [
                                    SizedBox(
                                      width: 18,
                                      height: 18,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    Text('Téléchargement...'),
                                  ],
                                ),
                                duration: Duration(seconds: 30),
                                backgroundColor: const Color(0xFF10B981),
                              ),
                            );
                          }

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

                          if (downloadDir == null) {
                            throw Exception('Impossible d\'accéder au dossier de téléchargement');
                          }

                          final fileName = 'recu_$orderNumber.pdf';
                          final filePath = '${downloadDir.path}/$fileName';

                          final dio = Dio();
                          await dio.download(
                            receiptUrl,
                            filePath,
                            options: Options(
                              responseType: ResponseType.bytes,
                              followRedirects: true,
                            ),
                          );

                          if (context.mounted) {
                            ScaffoldMessenger.of(context).hideCurrentSnackBar();
                          }

                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Row(
                                  children: [
                                    const Text('✅', style: TextStyle(fontSize: 16)),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: Text('Reçu téléchargé !'),
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
                                content: Text('Erreur de téléchargement'),
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
                              content: Text('Reçu non disponible'),
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
                        const Text('📥', style: TextStyle(fontSize: 16)),
                        const SizedBox(width: 6),
                        Text(
                          'Télécharger le reçu',
                          style: GoogleFonts.poppins(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 8),

                // Bouton Suivre ma commande
                SizedBox(
                  width: double.infinity,
                  height: 44,
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
                        const Text('🔍', style: TextStyle(fontSize: 16)),
                        const SizedBox(width: 6),
                        Text(
                          'Suivre ma commande',
                          style: GoogleFonts.poppins(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 8),

                // Bouton Fermer
                SizedBox(
                  width: double.infinity,
                  height: 44,
                  child: OutlinedButton(
                    onPressed: () {
                      Navigator.of(context).pop();
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
                      'Fermer',
                      style: GoogleFonts.poppins(
                        fontSize: 13,
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
    _scaleController.dispose();
    _pulseController.dispose();
    _bounceController.dispose();
    _confettiController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          // Background gradient
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  const Color(0xFF10B981).withOpacity(0.05),
                  Colors.white,
                  Colors.white,
                ],
              ),
            ),
          ),

          // Confetti
          Align(
            alignment: Alignment.topCenter,
            child: ConfettiWidget(
              confettiController: _confettiController,
              blastDirection: pi / 2,
              maxBlastForce: 5,
              minBlastForce: 2,
              emissionFrequency: 0.05,
              numberOfParticles: 20,
              gravity: 0.1,
              shouldLoop: false,
              colors: const [
                Color(0xFF10B981),
                Color(0xFF3B82F6),
                Color(0xFFF97316),
                Color(0xFFD946EF),
                Color(0xFFFBBF24),
                Color(0xFFEF4444),
              ],
            ),
          ),

          // Main content
          SafeArea(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Animated emojis row
                  AnimatedBuilder(
                    animation: _bounceAnimation,
                    builder: (context, child) {
                      return Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Transform.translate(
                            offset: Offset(0, _bounceAnimation.value),
                            child: const Text('🎊', style: TextStyle(fontSize: 32)),
                          ),
                          const SizedBox(width: 20),
                          Transform.translate(
                            offset: Offset(0, -_bounceAnimation.value),
                            child: const Text('🛍️', style: TextStyle(fontSize: 32)),
                          ),
                          const SizedBox(width: 20),
                          Transform.translate(
                            offset: Offset(0, _bounceAnimation.value),
                            child: const Text('🎊', style: TextStyle(fontSize: 32)),
                          ),
                        ],
                      );
                    },
                  ),
                  const SizedBox(height: 30),

                  // Success icon with pulse animation
                  AnimatedBuilder(
                    animation: _pulseAnimation,
                    builder: (context, child) {
                      return Transform.scale(
                        scale: _pulseAnimation.value,
                        child: ScaleTransition(
                          scale: _scaleAnimation,
                          child: Container(
                            width: 120,
                            height: 120,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  const Color(0xFF10B981),
                                  const Color(0xFF34D399),
                                ],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFF10B981).withOpacity(0.4),
                                  blurRadius: 30,
                                  spreadRadius: 10,
                                ),
                              ],
                            ),
                            child: const Icon(
                              Icons.check_rounded,
                              size: 70,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 40),

                  // Success text
                  FadeTransition(
                    opacity: _scaleController,
                    child: Column(
                      children: [
                        ShaderMask(
                          shaderCallback: (bounds) => LinearGradient(
                            colors: [
                              const Color(0xFF10B981),
                              const Color(0xFF059669),
                            ],
                          ).createShader(bounds),
                          child: Text(
                            'Commande validée ! 🎉',
                            style: GoogleFonts.poppins(
                              fontSize: 26,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Merci pour votre commande',
                          style: GoogleFonts.openSans(
                            fontSize: 16,
                            color: Colors.grey.shade600,
                            fontWeight: FontWeight.w500,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Text('✨', style: TextStyle(fontSize: 18)),
                            const SizedBox(width: 8),
                            Text(
                              'Préparation en cours...',
                              style: GoogleFonts.openSans(
                                fontSize: 14,
                                color: const Color(0xFF10B981),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(width: 8),
                            const Text('✨', style: TextStyle(fontSize: 18)),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
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
    with TickerProviderStateMixin {
  late AnimationController _scaleController;
  late AnimationController _pulseController;
  late AnimationController _bounceController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _pulseAnimation;
  late Animation<double> _bounceAnimation;
  late ConfettiController _confettiController;
  bool _hasLoyaltyCard = false;

  @override
  void initState() {
    super.initState();

    // Confetti controller - longer duration for better celebration effect
    _confettiController = ConfettiController(duration: const Duration(seconds: 5));

    // Scale animation
    _scaleController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _scaleAnimation = CurvedAnimation(
      parent: _scaleController,
      curve: Curves.elasticOut,
    );

    // Pulse animation
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat(reverse: true);
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.15).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    // Bounce animation
    _bounceController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    )..repeat(reverse: true);
    _bounceAnimation = Tween<double>(begin: 0, end: -10).animate(
      CurvedAnimation(parent: _bounceController, curve: Curves.easeInOut),
    );

    // Start animations
    _scaleController.forward();
    _confettiController.play();

    // Show modal after 4 seconds to let user enjoy the celebration
    Future.delayed(const Duration(seconds: 4), () {
      if (mounted) {
        _showSuccessModal();
      }
    });
  }

  // Afficher le modal de succès pour En boutique
  void _showSuccessModal() async {
    // Vérifier carte de fidélité
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
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        backgroundColor: Colors.white,
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Success icon with gradient
              TweenAnimationBuilder<double>(
                tween: Tween(begin: 0.0, end: 1.0),
                duration: const Duration(milliseconds: 500),
                builder: (context, value, child) {
                  return Transform.scale(
                    scale: value,
                    child: Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            const Color(0xFF10B981),
                            const Color(0xFF34D399),
                          ],
                        ),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF10B981).withOpacity(0.4),
                            blurRadius: 20,
                            spreadRadius: 5,
                          ),
                        ],
                      ),
                      child: const Icon(Icons.check_rounded, size: 45, color: Colors.white),
                    ),
                  );
                },
              ),
              const SizedBox(height: 24),

              // Title with emojis
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('🎉', style: TextStyle(fontSize: 22)),
                  const SizedBox(width: 8),
                  Text(
                    'Commande confirmée !',
                    style: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(width: 8),
                  const Text('🎉', style: TextStyle(fontSize: 22)),
                ],
              ),
              const SizedBox(height: 12),

              // Message
              Text(
                'Votre commande a été enregistrée avec succès',
                style: GoogleFonts.openSans(fontSize: 14, color: Colors.grey.shade600, height: 1.4),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),

              // Pickup info card
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      const Color(0xFF10B981).withOpacity(0.1),
                      const Color(0xFF34D399).withOpacity(0.05),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFF10B981).withOpacity(0.3)),
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        const Text('🏪', style: TextStyle(fontSize: 20)),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'Récupération en boutique',
                            style: GoogleFonts.poppins(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFF059669),
                            ),
                          ),
                        ),
                      ],
                    ),
                    if (widget.orderData?['pickupDate'] != null &&
                        widget.orderData?['pickupTime'] != null) ...[
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Row(
                          children: [
                            const Text('📅', style: TextStyle(fontSize: 16)),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
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
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Loyalty card button
              if (!_hasLoyaltyCard) ...[
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: OutlinedButton(
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
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFFD946EF),
                      side: const BorderSide(color: Color(0xFFD946EF), width: 2),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text('🎁', style: TextStyle(fontSize: 18)),
                        const SizedBox(width: 8),
                        Text(
                          'Créer une carte de fidélité',
                          style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),
              ],

              // Close button
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                    Navigator.of(context).pop();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: BoutiqueThemeProvider.of(context).primary,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  child: Text(
                    'Fermer',
                    style: GoogleFonts.poppins(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
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

  // Format date and time
  String _formatPickupDateTime(DateTime? date, TimeOfDay? time) {
    if (date == null || time == null) return '';
    final months = ['jan', 'fév', 'mar', 'avr', 'mai', 'juin', 'juil', 'août', 'sep', 'oct', 'nov', 'déc'];
    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');
    return '${date.day} ${months[date.month - 1]} ${date.year} à $hour:$minute';
  }

  @override
  void dispose() {
    _scaleController.dispose();
    _pulseController.dispose();
    _bounceController.dispose();
    _confettiController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          // Background gradient
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  const Color(0xFF10B981).withOpacity(0.05),
                  Colors.white,
                  Colors.white,
                ],
              ),
            ),
          ),

          // Confetti
          Align(
            alignment: Alignment.topCenter,
            child: ConfettiWidget(
              confettiController: _confettiController,
              blastDirection: pi / 2,
              maxBlastForce: 5,
              minBlastForce: 2,
              emissionFrequency: 0.05,
              numberOfParticles: 20,
              gravity: 0.1,
              shouldLoop: false,
              colors: const [
                Color(0xFF10B981),
                Color(0xFF3B82F6),
                Color(0xFFF97316),
                Color(0xFFD946EF),
                Color(0xFFFBBF24),
                Color(0xFFEF4444),
              ],
            ),
          ),

          // Main content
          SafeArea(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Animated emojis
                  AnimatedBuilder(
                    animation: _bounceAnimation,
                    builder: (context, child) {
                      return Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Transform.translate(
                            offset: Offset(0, _bounceAnimation.value),
                            child: const Text('🎊', style: TextStyle(fontSize: 32)),
                          ),
                          const SizedBox(width: 20),
                          Transform.translate(
                            offset: Offset(0, -_bounceAnimation.value),
                            child: const Text('🏪', style: TextStyle(fontSize: 32)),
                          ),
                          const SizedBox(width: 20),
                          Transform.translate(
                            offset: Offset(0, _bounceAnimation.value),
                            child: const Text('🎊', style: TextStyle(fontSize: 32)),
                          ),
                        ],
                      );
                    },
                  ),
                  const SizedBox(height: 30),

                  // Success icon with pulse
                  AnimatedBuilder(
                    animation: _pulseAnimation,
                    builder: (context, child) {
                      return Transform.scale(
                        scale: _pulseAnimation.value,
                        child: ScaleTransition(
                          scale: _scaleAnimation,
                          child: Container(
                            width: 120,
                            height: 120,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  const Color(0xFF10B981),
                                  const Color(0xFF34D399),
                                ],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFF10B981).withOpacity(0.4),
                                  blurRadius: 30,
                                  spreadRadius: 10,
                                ),
                              ],
                            ),
                            child: const Icon(
                              Icons.check_rounded,
                              size: 70,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 40),

                  // Success text
                  FadeTransition(
                    opacity: _scaleController,
                    child: Column(
                      children: [
                        ShaderMask(
                          shaderCallback: (bounds) => LinearGradient(
                            colors: [
                              const Color(0xFF10B981),
                              const Color(0xFF059669),
                            ],
                          ).createShader(bounds),
                          child: Text(
                            'Commande enregistrée ! 🎉',
                            style: GoogleFonts.poppins(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Text('🏪', style: TextStyle(fontSize: 20)),
                            const SizedBox(width: 8),
                            Text(
                              'Récupération en boutique',
                              style: GoogleFonts.openSans(
                                fontSize: 16,
                                color: Colors.grey.shade600,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Text('✨', style: TextStyle(fontSize: 18)),
                            const SizedBox(width: 8),
                            Text(
                              'Préparation en cours...',
                              style: GoogleFonts.openSans(
                                fontSize: 14,
                                color: const Color(0xFF10B981),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(width: 8),
                            const Text('✨', style: TextStyle(fontSize: 18)),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
