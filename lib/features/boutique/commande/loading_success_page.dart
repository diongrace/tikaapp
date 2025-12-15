import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
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
    Future.delayed(const Duration(seconds: 2), () {
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

    showDialog(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black.withOpacity(0.85),
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
        elevation: 10,
        backgroundColor: Colors.white,
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
            child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                // Bouton fermer stylisé
                Align(
                  alignment: Alignment.topRight,
                  child: GestureDetector(
                    onTap: () {
                      Navigator.of(context).pop(); // Fermer le modal
                      Navigator.of(context).pop(); // Fermer la page de chargement
                    },
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(Icons.close, size: 20, color: Colors.grey.shade700),
                    ),
                  ),
                ),
                const SizedBox(height: 4),

                // Icône de succès améliorée
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        const Color(0xFF4CAF50).withOpacity(0.15),
                        const Color(0xFF4CAF50).withOpacity(0.05),
                      ],
                    ),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF4CAF50).withOpacity(0.2),
                        blurRadius: 20,
                        spreadRadius: 5,
                      ),
                    ],
                  ),
                  child: const Icon(Icons.check_circle, size: 48, color: Color(0xFF4CAF50)),
                ),
                const SizedBox(height: 18),

                // Titre amélioré
                Text(
                  'Commande confirmée !',
                  style: GoogleFonts.openSans(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 8),

                // Message avec meilleure typographie
                Text(
                  'Effectué avec succès',
                  style: GoogleFonts.openSans(
                    fontSize: 14,
                    color: const Color.fromARGB(255, 49, 49, 49),
                    height: 1.4,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),

              // Bouton Suivre ma commande (style amélioré)
              SizedBox(
                width: double.infinity,
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () async {
                      print('🔍 [LoadingSuccessPage] Bouton Suivre ma commande cliqué');
                      print('🔍 [LoadingSuccessPage] orderData: ${widget.orderData}');

                      // Naviguer vers la page de suivi en temps réel via l'API
                      if (widget.orderData != null &&
                          widget.orderData!['orderNumber'] != null &&
                          widget.orderData!['customerPhone'] != null) {
                        // Capturer le navigator et le shop avant de fermer le dialog
                        final navigator = Navigator.of(context);
                        final rootNavigator = Navigator.of(context, rootNavigator: true);
                        final shop = BoutiqueThemeProvider.shopOf(context);
                        final orderNumber = widget.orderData!['orderNumber'];
                        final customerPhone = widget.orderData!['customerPhone'];

                        print('✅ [LoadingSuccessPage] Données valides');
                        print('   - orderNumber: $orderNumber');
                        print('   - customerPhone: $customerPhone');

                        // Fermer le modal (dialog)
                        navigator.pop();

                        // Attendre que le dialog soit fermé
                        await Future.delayed(const Duration(milliseconds: 200));

                        print('📱 [LoadingSuccessPage] Navigation vers OrderTrackingApiPage...');
                        // Utiliser le root navigator pour naviguer vers la page de suivi
                        rootNavigator.push(
                          MaterialPageRoute(
                            builder: (context) => BoutiqueThemeProvider(
                              shop: shop,
                              child: OrderTrackingApiPage(
                                orderNumber: orderNumber,
                                customerPhone: customerPhone,
                              ),
                            ),
                          ),
                        );
                      } else {
                        print('❌ [LoadingSuccessPage] Données manquantes!');
                        print('   - orderData null: ${widget.orderData == null}');
                        print('   - orderNumber null: ${widget.orderData?['orderNumber'] == null}');
                        print('   - customerPhone null: ${widget.orderData?['customerPhone'] == null}');

                        // Afficher un message d'erreur à l'utilisateur
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Impossible de suivre la commande: numéro de commande manquant'),
                              backgroundColor: Colors.orange,
                              duration: const Duration(seconds: 3),
                            ),
                          );
                        }
                      }
                    },
                    borderRadius: BorderRadius.circular(14),
                    child: Ink(
                      height: 50,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            BoutiqueThemeProvider.of(context).primary,
                            BoutiqueThemeProvider.of(context).primary.withOpacity(0.85),
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(14),
                        boxShadow: [
                          BoxShadow(
                            color: BoutiqueThemeProvider.of(context).primary.withOpacity(0.35),
                            blurRadius: 15,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.local_shipping_outlined, size: 22, color: Colors.white),
                          const SizedBox(width: 10),
                          Text(
                            'Suivre ma commande',
                            style: GoogleFonts.openSans(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                              letterSpacing: 0.3,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // Bouton Télécharger le reçu (style amélioré)
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () async {
                    // Télécharger le reçu depuis l'URL fournie par l'API
                    if (widget.orderData != null && widget.orderData!['receiptUrl'] != null) {
                      final receiptUrl = widget.orderData!['receiptUrl'] as String;
                      final uri = Uri.parse(receiptUrl);

                      try {
                        if (await canLaunchUrl(uri)) {
                          await launchUrl(uri, mode: LaunchMode.externalApplication);
                        }
                      } catch (e) {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Impossible de télécharger le reçu'),
                              backgroundColor: Colors.red,
                              behavior: SnackBarBehavior.floating,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                          );
                        }
                      }
                    }
                  },
                  icon: const Icon(Icons.download_outlined, size: 22),
                  label: Text(
                    'Télécharger le reçu',
                    style: GoogleFonts.openSans(fontSize: 15, fontWeight: FontWeight.w600),
                  ),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: BoutiqueThemeProvider.of(context).primary,
                    side: BorderSide(color: BoutiqueThemeProvider.of(context).primary.withOpacity(0.3), width: 1.5),
                    padding: const EdgeInsets.symmetric(vertical: 13),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    backgroundColor: BoutiqueThemeProvider.of(context).primary.withOpacity(0.05),
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // Bouton Créer une carte de fidélité (seulement si l'utilisateur n'en a pas)
              if (!_hasLoyaltyCard) ...[
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () async {
                      print('🔍 [LoadingSuccessPage] Bouton Créer carte de fidélité cliqué');

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

                      print('📱 [LoadingSuccessPage] Navigation vers CreateLoyaltyCardPage...');
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
                    icon: const Icon(Icons.credit_card_outlined, size: 22),
                    label: Text(
                      'Créer une carte de fidélité',
                      style: GoogleFonts.openSans(fontSize: 15, fontWeight: FontWeight.w600),
                    ),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color.fromARGB(221, 153, 16, 163),
                      side: BorderSide(color: Colors.grey.shade300, width: 1.5),
                      padding: const EdgeInsets.symmetric(vertical: 13),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      backgroundColor: Colors.grey.shade50,
                    ),
                  ),
                ),
              ], // Ferme le if spread
            ], // Ferme children du Column
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
