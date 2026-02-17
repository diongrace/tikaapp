import 'package:flutter/material.dart';
import 'product_card.dart';
import '../../../../core/utils/responsive.dart';

/// Grille de produits affichés en scrollable
class ProductGrid extends StatelessWidget {
  final List<Map<String, dynamic>> products;
  final Function(Map<String, dynamic>) onProductTap;
  final bool isRestaurant;

  const ProductGrid({
    super.key,
    required this.products,
    required this.onProductTap,
    this.isRestaurant = false,
  });

  @override
  Widget build(BuildContext context) {
    final columns = Responsive.gridColumns(context);
    final hPadding = Responsive.horizontalPadding(context);

    return GridView.builder(
      padding: EdgeInsets.symmetric(horizontal: hPadding, vertical: 12),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: columns,
        childAspectRatio: isRestaurant ? 0.52 : 0.55,
        crossAxisSpacing: 14,
        mainAxisSpacing: 16,
      ),
      itemCount: products.length,
      itemBuilder: (context, index) {
        final product = products[index];
        return AnimatedScale(
          scale: 1.0,
          duration: const Duration(milliseconds: 200),
          child: ProductCard(
            product: product,
            onTap: () => onProductTap(product),
            isRestaurant: isRestaurant,
          ),
        );
      },
    );
  }
}
