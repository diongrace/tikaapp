import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Widget de filtrage par catégorie et tri
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
    return Row(
      children: [
        // Filtre par catégorie
        Expanded(
          flex: 3,
          child: Container(
            height: 45,
            padding: const EdgeInsets.symmetric(horizontal: 8),
            decoration: BoxDecoration(
              color: const Color.fromARGB(172, 255, 255, 255),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: selectedCategory,
                isExpanded: true,
                icon: Icon(
                  Icons.keyboard_arrow_down,
                  color: Colors.grey.shade700,
                  size: 18,
                ),
                style: GoogleFonts.openSans(
                  fontSize: 10.5,
                  fontWeight: FontWeight.w600,
                  color: Colors.black,
                ),
                dropdownColor: Colors.white,
                borderRadius: BorderRadius.circular(16),
                elevation: 8,
                menuMaxHeight: 300,
                onChanged: (String? newValue) {
                  if (newValue != null) {
                    onCategoryChanged(newValue);
                  }
                },
                items: categories.map<DropdownMenuItem<String>>((String value) {
                  return DropdownMenuItem<String>(
                    value: value,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                      child: Text(
                        value,
                        style: GoogleFonts.openSans(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Colors.black,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
        ),
        const SizedBox(width: 10),
        // Tri
        Expanded(
          flex: 2,
          child: Container(
            height: 45,
            padding: const EdgeInsets.symmetric(horizontal: 8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: sortOrder,
                isExpanded: true,
                icon: Icon(
                  Icons.keyboard_arrow_down,
                  color: const Color.fromARGB(255, 97, 97, 97),
                  size: 18,
                ),
                style: GoogleFonts.openSans(
                  fontSize: 10.5,
                  fontWeight: FontWeight.w600,
                  color: Colors.black,
                ),
                dropdownColor: Colors.white,
                borderRadius: BorderRadius.circular(16),
                elevation: 8,
                menuMaxHeight: 250,
                onChanged: (String? newValue) {
                  if (newValue != null) {
                    onSortChanged(newValue);
                  }
                },
                items: sortOptions.map<DropdownMenuItem<String>>((String value) {
                  return DropdownMenuItem<String>(
                    value: value,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                      child: Text(
                        value,
                        style: GoogleFonts.openSans(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Colors.black,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
