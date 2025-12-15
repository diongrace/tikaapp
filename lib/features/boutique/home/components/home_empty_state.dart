import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../services/models/shop_model.dart';

/// Widget d'état vide pour l'écran d'accueil
class HomeEmptyState extends StatefulWidget {
  final Shop? shop;
  final Color primaryColor;
  final String selectedCategory;
  final String searchQuery;

  const HomeEmptyState({
    super.key,
    required this.shop,
    required this.primaryColor,
    required this.selectedCategory,
    required this.searchQuery,
  });

  @override
  State<HomeEmptyState> createState() => _HomeEmptyStateState();
}

class _HomeEmptyStateState extends State<HomeEmptyState>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _rotationAnimation;

  @override
  void initState() {
    super.initState();

    // Initialiser l'animation
    _animationController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat(reverse: true);

    _scaleAnimation = Tween<double>(begin: 0.9, end: 1.1).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );

    _rotationAnimation = Tween<double>(begin: -0.05, end: 0.05).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final hasFilter = widget.selectedCategory != "Toutes catégories" ||
                      widget.searchQuery.isNotEmpty;

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Animation avec plusieurs icônes empilées
            AnimatedBuilder(
              animation: _animationController,
              builder: (context, child) {
                return Transform.scale(
                  scale: _scaleAnimation.value,
                  child: Transform.rotate(
                    angle: _rotationAnimation.value,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        // Cercle de fond avec dégradé
                        Container(
                          width: 140,
                          height: 140,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: LinearGradient(
                              colors: [
                                widget.primaryColor.withOpacity(0.1),
                                widget.primaryColor.withOpacity(0.05),
                              ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                          ),
                        ),
                        // Cercle intermédiaire
                        Container(
                          width: 100,
                          height: 100,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: widget.primaryColor.withOpacity(0.15),
                          ),
                        ),
                        // Icône principale
                        Container(
                          width: 70,
                          height: 70,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: widget.primaryColor,
                            boxShadow: [
                              BoxShadow(
                                color: widget.primaryColor.withOpacity(0.3),
                                blurRadius: 20,
                                spreadRadius: 5,
                              ),
                            ],
                          ),
                          child: Icon(
                            widget.shop?.isRestaurant == true
                                ? Icons.restaurant_menu
                                : Icons.shopping_bag_outlined,
                            size: 36,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 32),

            // Titre
            Text(
              'Aucun produit disponible',
              style: GoogleFonts.poppins(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),

            // Description
            Text(
              hasFilter
                  ? 'Aucun produit ne correspond à votre recherche'
                  : '${widget.shop?.name ?? "Cette boutique"} n\'a pas encore ajouté de produits',
              style: GoogleFonts.openSans(
                fontSize: 14,
                color: Colors.grey[600],
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),

            // Message d'encouragement avec icône
            if (hasFilter)
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: widget.primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: widget.primaryColor.withOpacity(0.3),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.lightbulb_outline,
                      size: 20,
                      color: widget.primaryColor,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Essayez une autre recherche',
                      style: GoogleFonts.openSans(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: widget.primaryColor,
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}
