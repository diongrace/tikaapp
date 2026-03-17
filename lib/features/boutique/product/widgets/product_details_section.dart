import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/models/boutique_type.dart';
import '../../../../core/services/boutique_theme_provider.dart';

/// Widget qui affiche les détails spécifiques selon le type de boutique
class ProductDetailsSection extends StatefulWidget {
  final Map<String, dynamic> product;
  final BoutiqueType boutiqueType;
  final Function(List<String>)? onPreferencesChanged;
  final Function(String?)? onSizeSelected;
  final Function(int?)? onPortionSelected;

  const ProductDetailsSection({
    super.key,
    required this.product,
    required this.boutiqueType,
    this.onPreferencesChanged,
    this.onSizeSelected,
    this.onPortionSelected,
  });

  @override
  State<ProductDetailsSection> createState() => _ProductDetailsSectionState();
}

class _ProductDetailsSectionState extends State<ProductDetailsSection> {
  // Préférences sélectionnées pour restaurant
  final Set<String> _selectedPreferences = {};
  final TextEditingController _customRequestController = TextEditingController();
  int? _selectedPortionId;
  String? _selectedSize;

  @override
  void dispose() {
    _customRequestController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    switch (widget.boutiqueType) {
      case BoutiqueType.restaurant:
      case BoutiqueType.midiExpress:
        return _buildRestaurantSection();
      case BoutiqueType.boutiqueEnLigne:
        return _buildShopSection();
      case BoutiqueType.salonBeaute:
      case BoutiqueType.salonCoiffure:
        return _buildSalonSection();
    }
  }

  /// Section pour Restaurant / Midi Express
  Widget _buildRestaurantSection() {
    final prepTime = _getPreparationTime();
    final isDish = _isDish();

    // Debug: Afficher les informations du produit
    print('🍽️ ProductDetailsSection - Restaurant');
    print('   Produit: ${widget.product['name']}');
    print('   Est un plat: $isDish');
    print('   Temps de préparation: $prepTime');
    print('   Portions: ${widget.product['portions']}');
    print('   A des portions: ${_hasPortions()}');

    // Si c'est une boisson/pâtisserie sans temps de préparation, ne rien afficher
    if (!isDish && prepTime == null) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Carte temps de préparation (uniquement pour les plats)
        if (prepTime != null) ...[
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: const Color(0xFFF3E5F5),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: BoutiqueThemeProvider.of(context).primary.withOpacity(0.2),
                    shape: BoxShape.circle,
                  ),
                  alignment: Alignment.center,
                  child: FaIcon(
                    FontAwesomeIcons.clock,
                    color: BoutiqueThemeProvider.of(context).primary,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 14),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Temps de préparation',
                      style: GoogleFonts.inriaSerif(
                        fontSize: 13,
                        color: Colors.grey.shade800,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      prepTime,
                      style: GoogleFonts.inriaSerif(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: BoutiqueThemeProvider.of(context).primary,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
        ],

        // Section Préférences (uniquement pour les plats, pas boissons/pâtisseries)
        if (isDish) ...[
          // Sélecteur de portions (si disponible)
          if (_hasPortions()) ...[
            Text(
              'Portions disponibles',
              style: GoogleFonts.inriaSerif(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF2D2D2D),
              ),
            ),
            const SizedBox(height: 12),
            _buildPortionSelector(),
            const SizedBox(height: 20),
          ],

          Text(
            'Préférences',
            style: GoogleFonts.inriaSerif(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF2D2D2D),
            ),
          ),
          const SizedBox(height: 12),

          // Options de préférences
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              _buildPreferenceChip('spicy', '🌶️ Épicé'),
              _buildPreferenceChip('not_spicy', '✨ Non épicé'),
            ],
          ),
          const SizedBox(height: 16),

          // Note pour le restaurant
          Text(
            'Note pour le restaurant',
            style: GoogleFonts.inriaSerif(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF2D2D2D),
            ),
          ),
          const SizedBox(height: 8),
          _buildRestaurantNoteField(),
        ],
      ],
    );
  }

  /// Chip de préférence sélectionnable
  Widget _buildPreferenceChip(String id, String label) {
    final isSelected = _selectedPreferences.contains(id);

    return GestureDetector(
      onTap: () {
        setState(() {
          if (isSelected) {
            _selectedPreferences.remove(id);
          } else {
            _selectedPreferences.add(id);
          }
          _notifyPreferencesChanged();
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFF3E5F5) : Colors.white,
          borderRadius: BorderRadius.circular(25),
          border: Border.all(
            color: isSelected ? BoutiqueThemeProvider.of(context).primary : Colors.grey.shade300,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: isSelected ? BoutiqueThemeProvider.of(context).primary : Colors.grey.shade900,
                  width: 2,
                ),
                color: isSelected ? BoutiqueThemeProvider.of(context).primary : Colors.transparent,
              ),
              child: isSelected
                  ? const FaIcon(FontAwesomeIcons.check, size: 14, color: Colors.white)
                  : null,
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: GoogleFonts.inriaSerif(
                fontSize: 14,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                color: isSelected ? BoutiqueThemeProvider.of(context).primary : Colors.grey.shade900,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Chips compactes pour tailles/portions dans la boutique en ligne
  Widget _buildPortionChips() {
    final portions = _getPortions()
        .where((p) => p['is_active'] != false && p['is_active'] != 0)
        .toList();
    if (portions.isEmpty) return const SizedBox.shrink();

    final primary = BoutiqueThemeProvider.of(context).primary;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: portions.map((portion) {
            final isSelected = _selectedPortionId == portion['id'];
            final stock = portion['stock'];
            final outOfStock = stock != null && stock is int && stock <= 0;
            final name = portion['name']?.toString() ?? '';

            return GestureDetector(
              onTap: outOfStock
                  ? null
                  : () {
                      final newPortionId = isSelected ? null : portion['id'] as int?;
                      setState(() {
                        _selectedPortionId = newPortionId;
                        _notifyPreferencesChanged();
                      });
                      widget.onPortionSelected?.call(newPortionId);
                    },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                constraints: const BoxConstraints(minWidth: 52),
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 11),
                decoration: BoxDecoration(
                  color: isSelected ? primary : Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: isSelected
                        ? primary
                        : outOfStock
                            ? Colors.grey.shade200
                            : Colors.grey.shade200,
                    width: isSelected ? 2 : 1,
                  ),
                  boxShadow: isSelected
                      ? [
                          BoxShadow(
                            color: primary.withOpacity(0.35),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ]
                      : [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.04),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          ),
                        ],
                ),
                child: Text(
                  name,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inriaSerif(
                    fontSize: 14,
                    fontWeight:
                        isSelected ? FontWeight.w700 : FontWeight.w500,
                    color: outOfStock
                        ? Colors.grey.shade900
                        : isSelected
                            ? Colors.white
                            : Colors.grey.shade900,
                    decoration: outOfStock
                        ? TextDecoration.lineThrough
                        : TextDecoration.none,
                  ),
                ),
              ),
            );
          }).toList(),
        ),
        // Prix de la portion sélectionnée
        if (_selectedPortionId != null) ...[
          const SizedBox(height: 10),
          Builder(builder: (context) {
            final selected = portions.firstWhere(
              (p) => p['id'] == _selectedPortionId,
              orElse: () => {},
            );
            final price = selected['price'];
            if (price == null) return const SizedBox.shrink();
            return Text(
              '$price FCFA',
              style: GoogleFonts.inriaSerif(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: primary,
              ),
            );
          }),
        ],
      ],
    );
  }

  /// Sélecteur de portions
  Widget _buildPortionSelector() {
    final portions = _getPortions()
        .where((p) => p['is_active'] != false && p['is_active'] != 0)
        .toList();
    if (portions.isEmpty) return const SizedBox.shrink();

    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: portions.map((portion) {
        final isSelected = _selectedPortionId == portion['id'];
        final stock = portion['stock'];
        final outOfStock = stock != null && stock is int && stock <= 0;

        return GestureDetector(
          onTap: outOfStock ? null : () {
            final newPortionId = isSelected ? null : portion['id'] as int?;
            setState(() {
              _selectedPortionId = newPortionId;
              _notifyPreferencesChanged();
            });
            widget.onPortionSelected?.call(newPortionId);
          },
          child: Opacity(
            opacity: outOfStock ? 0.4 : 1.0,
            child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: isSelected ? BoutiqueThemeProvider.of(context).primary.withOpacity(0.1) : Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isSelected ? BoutiqueThemeProvider.of(context).primary : Colors.grey.shade300,
                width: isSelected ? 2 : 1,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 20,
                      height: 20,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: isSelected ? BoutiqueThemeProvider.of(context).primary : Colors.grey.shade900,
                          width: 2,
                        ),
                        color: isSelected ? BoutiqueThemeProvider.of(context).primary : Colors.transparent,
                      ),
                      child: isSelected
                          ? const FaIcon(FontAwesomeIcons.check, size: 14, color: Colors.white)
                          : null,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      portion['name'] as String,
                      style: GoogleFonts.inriaSerif(
                        fontSize: 14,
                        fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                        color: isSelected ? BoutiqueThemeProvider.of(context).primary : Colors.grey.shade900,
                      ),
                    ),
                  ],
                ),
                if (portion['price'] != null) ...[
                  const SizedBox(height: 4),
                  Padding(
                    padding: const EdgeInsets.only(left: 28),
                    child: Text(
                      '${portion['price']} FCFA',
                      style: GoogleFonts.inriaSerif(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: BoutiqueThemeProvider.of(context).primary,
                      ),
                    ),
                  ),
                ],
                if (portion['description'] != null && portion['description'].toString().isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Padding(
                    padding: const EdgeInsets.only(left: 28),
                    child: Text(
                      portion['description'] as String,
                      style: GoogleFonts.inriaSerif(
                        fontSize: 13,
                        color: Colors.grey.shade800,
                      ),
                    ),
                  ),
                ],
                if (outOfStock) ...[
                  const SizedBox(height: 4),
                  Padding(
                    padding: const EdgeInsets.only(left: 28),
                    child: Text(
                      'Rupture de stock',
                      style: GoogleFonts.inriaSerif(
                        fontSize: 13,
                        color: Colors.red.shade400,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
          ),
        );
      }).toList(),
    );
  }

  /// Champ de saisie pour note au restaurant
  Widget _buildRestaurantNoteField() {
    return TextField(
      controller: _customRequestController,
      decoration: InputDecoration(
        hintText: 'Ex: Sans oignons, bien cuit, sauce à part...',
        hintStyle: GoogleFonts.inriaSerif(
          fontSize: 14,
          color: Colors.grey.shade800,
        ),
        prefixIcon: Icon(
          Icons.restaurant_menu,
          color: Colors.grey.shade800,
        ),
        filled: true,
        fillColor: Colors.grey.shade50,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: BoutiqueThemeProvider.of(context).primary, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),
      style: GoogleFonts.inriaSerif(
        fontSize: 14,
        color: Colors.grey.shade800,
      ),
      maxLines: 3,
      minLines: 2,
      onChanged: (value) {
        _selectedPreferences.removeWhere((p) => p.startsWith('note:'));
        if (value.isNotEmpty) {
          _selectedPreferences.add('note:$value');
        }
        _notifyPreferencesChanged();
      },
    );
  }

  /// Section pour Boutique en ligne
  Widget _buildShopSection() {
    // Tailles: utiliser sizes de l'API, sinon les portions comme variantes
    final sizes = widget.product['sizes'];
    final hasSizes = sizes != null && sizes is List && sizes.isNotEmpty;
    final hasPortionsForShop = !hasSizes && _hasPortions();
    final otherDetails = _getShopOtherDetails();

    if (!hasSizes && !hasPortionsForShop && otherDetails.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Sélecteur de taille depuis sizes
        if (hasSizes) ...[
          _buildSectionTitle('Taille', context),
          const SizedBox(height: 12),
          _buildSizeSelector(List<String>.from(sizes.map((s) => s.toString()))),
          const SizedBox(height: 20),
        ]
        // Sinon, utiliser les portions comme tailles/variantes
        else if (hasPortionsForShop) ...[
          _buildSectionTitle('Taille', context),
          const SizedBox(height: 12),
          _buildPortionChips(),
          const SizedBox(height: 20),
        ],

        // Autres caractéristiques (couleurs, matière)
        if (otherDetails.isNotEmpty) ...[
          _buildSectionTitle('Caractéristiques', context),
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Column(children: otherDetails),
          ),
        ],
      ],
    );
  }

  /// Titre de section avec accent gradient à gauche
  Widget _buildSectionTitle(String title, BuildContext context) {
    final t = BoutiqueThemeProvider.of(context);
    return Row(
      children: [
        Container(
          width: 4,
          height: 22,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [t.primary, t.gradientEnd],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 10),
        Text(
          title,
          style: GoogleFonts.inriaSerif(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: const Color(0xFF1A1A2E),
          ),
        ),
      ],
    );
  }

  /// Sélecteur de taille cliquable
  Widget _buildSizeSelector(List<String> sizes) {
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: sizes.map((size) {
        final isSelected = _selectedSize == size;

        return GestureDetector(
          onTap: () {
            setState(() {
              _selectedSize = isSelected ? null : size;
            });
            widget.onSizeSelected?.call(_selectedSize);
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            constraints: const BoxConstraints(minWidth: 56),
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
            decoration: BoxDecoration(
              gradient: isSelected
                  ? LinearGradient(
                      colors: [
                        BoutiqueThemeProvider.of(context).primary,
                        BoutiqueThemeProvider.of(context).gradientEnd,
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    )
                  : null,
              color: isSelected ? null : Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: isSelected
                    ? BoutiqueThemeProvider.of(context).primary
                    : Colors.grey.shade200,
                width: isSelected ? 0 : 1,
              ),
              boxShadow: isSelected
                  ? [
                      BoxShadow(
                        color: BoutiqueThemeProvider.of(context)
                            .primary
                            .withOpacity(0.40),
                        blurRadius: 12,
                        offset: const Offset(0, 5),
                      ),
                    ]
                  : [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.04),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
            ),
            child: Text(
              size,
              textAlign: TextAlign.center,
              style: GoogleFonts.inriaSerif(
                fontSize: 14,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                color: isSelected ? Colors.white : Colors.grey.shade900,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  /// Retourne les détails autres que les tailles (couleurs, matière)
  List<Widget> _getShopOtherDetails() {
    final List<Widget> details = [];

    // Couleurs
    final colors = widget.product['colors'];
    if (colors != null && colors is List && colors.isNotEmpty) {
      details.add(_DetailRow(
        icon: Icons.palette_outlined,
        label: 'Couleurs',
        value: colors.join(', '),
        iconColor: const Color(0xFFE91E63),
      ));
    }

    // Matière
    final material = widget.product['material'];
    if (material != null && material.toString().isNotEmpty) {
      if (details.isNotEmpty) details.add(const _DetailDivider());
      details.add(_DetailRow(
        icon: Icons.layers_outlined,
        label: 'Matière',
        value: material.toString(),
        iconColor: const Color(0xFF795548),
      ));
    }

    return details;
  }

  /// Section pour Salon de beauté / Coiffure
  Widget _buildSalonSection() {
    final duration = _getDuration();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Carte durée du service
        if (duration != null) ...[
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: const Color(0xFFF3E5F5),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: BoutiqueThemeProvider.of(context).primary.withOpacity(0.2),
                    shape: BoxShape.circle,
                  ),
                  alignment: Alignment.center,
                  child: FaIcon(
                    FontAwesomeIcons.clock,
                    color: BoutiqueThemeProvider.of(context).primary,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 14),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Durée du service',
                      style: GoogleFonts.inriaSerif(
                        fontSize: 13,
                        color: Colors.grey.shade800,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      duration,
                      style: GoogleFonts.inriaSerif(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: BoutiqueThemeProvider.of(context).primary,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
        ],

        // Spécialiste
        if (_getSpecialist() != null) ...[
          _buildInfoCard(
            icon: FontAwesomeIcons.user,
            label: 'Spécialiste',
            value: _getSpecialist()!,
          ),
          const SizedBox(height: 16),
        ],
      ],
    );
  }

  Widget _buildInfoCard({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          Icon(icon, color: BoutiqueThemeProvider.of(context).primary, size: 20),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: GoogleFonts.inriaSerif(
                  fontSize: 13,
                  color: Colors.grey.shade800,
                ),
              ),
              Text(
                value,
                style: GoogleFonts.inriaSerif(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF2D2D2D),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // Helpers

  /// Vérifie si le produit a des portions disponibles
  bool _hasPortions() {
    final portions = widget.product['portions'];
    return portions != null && portions is List && portions.isNotEmpty;
  }

  /// Récupère les portions du produit
  List<Map<String, dynamic>> _getPortions() {
    final portions = widget.product['portions'];
    if (portions == null || portions is! List) return [];

    return portions.map((p) {
      if (p is Map<String, dynamic>) {
        return p;
      }
      return <String, dynamic>{};
    }).toList();
  }

  /// Vérifie si le produit est un plat (nécessite temps de préparation et préférences épicé)
  /// Retourne false pour boissons, pâtisseries, desserts, etc.
  bool _isDish() {
    final category = (widget.product['category']?.toString() ?? '').toLowerCase();

    // Catégories qui ne sont PAS des plats (pas de préférences épicé ni temps de préparation)
    final nonDishCategories = [
      'boisson', 'boissons', 'drink', 'drinks', 'beverage', 'beverages',
      'patisserie', 'pâtisserie', 'patisseries', 'pâtisseries', 'pastry', 'pastries',
      'dessert', 'desserts',
      'jus', 'juice', 'juices',
      'cocktail', 'cocktails',
      'cafe', 'café', 'coffee',
      'the', 'thé', 'tea',
      'glace', 'glaces', 'ice cream',
      'gateau', 'gâteau', 'gateaux', 'gâteaux', 'cake', 'cakes',
    ];

    for (final nonDish in nonDishCategories) {
      if (category.contains(nonDish)) {
        return false;
      }
    }

    return true;
  }

  String? _getPreparationTime() {
    // Ne pas afficher le temps de préparation pour boissons/pâtisseries
    if (!_isDish()) return null;

    final prepTime = widget.product['preparation_time'] ??
        widget.product['preparationTime'] ??
        widget.product['cooking_time'] ??
        widget.product['cookingTime'];
    if (prepTime == null) return null;
    return '$prepTime min';
  }

  String? _getDuration() {
    final duration = widget.product['duration_minutes'] ??
        widget.product['durationMinutes'] ??
        widget.product['duration'];
    if (duration == null) return null;
    return '$duration min';
  }

  String? _getSpecialist() {
    return widget.product['specialist_name']?.toString() ??
        widget.product['specialistName']?.toString() ??
        widget.product['specialist']?.toString();
  }

  void _notifyPreferencesChanged() {
    widget.onPreferencesChanged?.call(_selectedPreferences.toList());
  }
}

/// Ligne de détail individuelle
class _DetailRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color iconColor;

  const _DetailRow({
    required this.icon,
    required this.label,
    required this.value,
    required this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: iconColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, size: 20, color: iconColor),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: GoogleFonts.inriaSerif(
                  fontSize: 13,
                  color: Colors.grey.shade800,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: GoogleFonts.inriaSerif(
                  fontSize: 14,
                  color: const Color(0xFF2D2D2D),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Séparateur entre les lignes de détail
class _DetailDivider extends StatelessWidget {
  const _DetailDivider();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Divider(height: 1, color: Colors.grey.shade200),
    );
  }
}
