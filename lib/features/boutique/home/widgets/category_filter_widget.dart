import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/services/boutique_theme_provider.dart';
import '../../../../services/models/shop_model.dart';

/// Filtres catégorie (chips horizontaux) + bouton tri (bottom sheet premium)
class CategoryFilterWidget extends StatelessWidget {
  final String selectedCategory;
  final String sortOrder;
  final ValueChanged<String> onCategoryChanged;
  final ValueChanged<String> onSortChanged;
  final List<String> categories;
  final List<String> sortOptions;

  const CategoryFilterWidget({
    super.key,
    required this.selectedCategory,
    required this.sortOrder,
    required this.onCategoryChanged,
    required this.onSortChanged,
    this.categories = const [
      'Toutes catégories',
      'Boissons chaudes',
      'Boissons froides',
      'Pâtisseries',
      'Sandwichs',
    ],
    this.sortOptions = const [
      'Trier par',
      'Nom (A-Z)',
      'Prix croissant',
      'Prix décroissant',
      'Plus récents',
      'En stock',
      'Rupture de stock',
    ],
  });

  @override
  Widget build(BuildContext context) {
    final shopTheme = BoutiqueThemeProvider.of(context);
    final bool sortActive = sortOrder != 'Trier par';

    return Row(
      children: [
        // ── Chips catégories scrollables ──────────────────────────
        Expanded(
          child: SizedBox(
            height: 38,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: EdgeInsets.zero,
              itemCount: categories.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (context, i) {
                final cat = categories[i];
                final isSelected = cat == selectedCategory;
                // Libellé raccourci pour "Toutes catégories"
                final label = cat == 'Toutes catégories' ? 'Tout' : cat;

                return GestureDetector(
                  onTap: () => onCategoryChanged(cat),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 220),
                    curve: Curves.easeInOut,
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      gradient: isSelected
                          ? LinearGradient(
                              colors: [shopTheme.primary, shopTheme.gradientEnd],
                              begin: Alignment.centerLeft,
                              end: Alignment.centerRight,
                            )
                          : null,
                      color: isSelected ? null : Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: isSelected
                            ? shopTheme.primary
                            : Colors.grey.shade200,
                        width: 1,
                      ),
                      boxShadow: isSelected
                          ? [
                              BoxShadow(
                                color: shopTheme.primary.withOpacity(0.40),
                                blurRadius: 12,
                                offset: const Offset(0, 4),
                              ),
                            ]
                          : [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.04),
                                blurRadius: 4,
                                offset: const Offset(0, 1),
                              ),
                            ],
                    ),
                    child: Text(
                      label,
                      style: GoogleFonts.inriaSerif(
                        fontSize: 13,
                        fontWeight:
                            isSelected ? FontWeight.w700 : FontWeight.w500,
                        color: isSelected
                            ? Colors.white
                            : const Color(0xFF555555),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ),

        const SizedBox(width: 8),

        // ── Bouton tri ────────────────────────────────────────────
        GestureDetector(
          onTap: () => _showSortSheet(context, shopTheme),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 220),
            width: 44,
            height: 38,
            decoration: BoxDecoration(
              color: sortActive ? shopTheme.primary : Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: sortActive ? shopTheme.primary : Colors.grey.shade200,
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: sortActive
                      ? shopTheme.primary.withOpacity(0.32)
                      : Colors.black.withOpacity(0.05),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                FaIcon(
                  FontAwesomeIcons.sliders,
                  color: sortActive ? Colors.white : Colors.grey.shade800,
                  size: 20,
                ),
                // Point orange si un tri est actif
                if (sortActive)
                  Positioned(
                    top: 6,
                    right: 7,
                    child: Container(
                      width: 7,
                      height: 7,
                      decoration: const BoxDecoration(
                        color: Color(0xFFFF9A5C),
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  void _showSortSheet(BuildContext context, ShopTheme shopTheme) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Poignée
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Trier les produits',
              style: GoogleFonts.inriaSerif(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF1C1C1E),
              ),
            ),
            const SizedBox(height: 8),
            // Options de tri (on saute la première "Trier par")
            ...sortOptions.skip(1).map((opt) {
              final isSelected = opt == sortOrder;
              return _sortTile(ctx, opt, isSelected, shopTheme);
            }),
            // Réinitialiser si un tri est actif
            if (sortOrder != 'Trier par') ...[
              const Divider(height: 20),
              _resetTile(ctx, shopTheme),
            ],
          ],
        ),
      ),
    );
  }

  Widget _sortTile(
    BuildContext ctx,
    String opt,
    bool isSelected,
    ShopTheme shopTheme,
  ) =>
      ListTile(
        contentPadding: const EdgeInsets.symmetric(vertical: 2),
        leading: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: isSelected
                ? shopTheme.primary.withOpacity(0.12)
                : Colors.grey.shade50,
            shape: BoxShape.circle,
          ),
          alignment: Alignment.center,
          child: Icon(
            _sortIcon(opt),
            size: 18,
            color: isSelected ? shopTheme.primary : Colors.grey.shade800,
          ),
        ),
        title: Text(
          opt,
          style: GoogleFonts.inriaSerif(
            fontSize: 14,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
            color: isSelected ? shopTheme.primary : Colors.black87,
          ),
        ),
        trailing: isSelected
            ? Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  color: shopTheme.primary,
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: const FaIcon(FontAwesomeIcons.check,
                    size: 14, color: Colors.white),
              )
            : null,
        onTap: () {
          onSortChanged(opt);
          Navigator.pop(ctx);
        },
      );

  Widget _resetTile(BuildContext ctx, ShopTheme shopTheme) => ListTile(
        contentPadding: const EdgeInsets.symmetric(vertical: 2),
        leading: Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: Colors.red.shade50,
            shape: BoxShape.circle,
          ),
          alignment: Alignment.center,
          child: FaIcon(FontAwesomeIcons.arrowsRotate, size: 18, color: Colors.red.shade400),
        ),
        title: Text(
          'Réinitialiser le tri',
          style: GoogleFonts.inriaSerif(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Colors.red.shade400,
          ),
        ),
        onTap: () {
          onSortChanged('Trier par');
          Navigator.pop(ctx);
        },
      );

  IconData _sortIcon(String opt) {
    switch (opt) {
      case 'Nom (A-Z)':
        return Icons.sort_by_alpha_rounded;
      case 'Prix croissant':
        return FontAwesomeIcons.arrowTrendUp;
      case 'Prix décroissant':
        return FontAwesomeIcons.arrowTrendDown;
      case 'Plus récents':
        return FontAwesomeIcons.certificate;
      case 'En stock':
        return FontAwesomeIcons.boxOpen;
      case 'Rupture de stock':
        return FontAwesomeIcons.cartShopping;
      default:
        return Icons.sort_rounded;
    }
  }
}
