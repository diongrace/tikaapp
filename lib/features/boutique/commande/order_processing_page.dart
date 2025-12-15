import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/services/boutique_theme_provider.dart';
import '../../../services/models/shop_model.dart';

/// Page de chargement qui s'affiche pendant le traitement de la commande
class OrderProcessingPage extends StatefulWidget {
  final Shop? shop;

  const OrderProcessingPage({super.key, this.shop});

  @override
  State<OrderProcessingPage> createState() => _OrderProcessingPageState();
}

class _OrderProcessingPageState extends State<OrderProcessingPage>
    with SingleTickerProviderStateMixin {
  late AnimationController _dotController;
  late Animation<int> _dotAnimation;

  @override
  void initState() {
    super.initState();

    // Animation pour les points "..."
    _dotController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat();

    _dotAnimation = IntTween(begin: 0, end: 3).animate(_dotController);
  }

  @override
  void dispose() {
    _dotController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final shopTheme = widget.shop?.theme ?? ShopTheme.defaultTheme();

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Logo de l'application dans un cercle
              Container(
                width: 200,
                height: 200,
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.15),
                      blurRadius: 20,
                      spreadRadius: 5,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                padding: const EdgeInsets.all(15),
                child: Image.asset(
                  'lib/core/assets/loading.png',
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) {
                    // Fallback vers une icône simple
                    return Icon(
                      Icons.shopping_bag_outlined,
                      size: 100,
                      color: Colors.grey.shade400,
                    );
                  },
                ),
              ),
              const SizedBox(height: 40),

              // Texte "Traitement de votre commande" avec points animés
              AnimatedBuilder(
                animation: _dotAnimation,
                builder: (context, child) {
                  String dots = '.' * _dotAnimation.value;
                  return Text(
                    'Traitement de votre commande$dots',
                    style: GoogleFonts.openSans(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: const Color.fromARGB(255, 20, 20, 20),
                    ),
                    textAlign: TextAlign.center,
                  );
                },
              ),
              const SizedBox(height: 30),

              // Indicateur de chargement circulaire
              SizedBox(
                width: 35,
                height: 35,
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(
                    shopTheme.primary,
                  ),
                  strokeWidth: 3,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
