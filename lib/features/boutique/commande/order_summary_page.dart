import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../panier/cart_manager.dart';
import '../../../core/services/boutique_theme_provider.dart';

/// Page de résumé de commande avant confirmation finale
class OrderSummaryPage extends StatelessWidget {
  final String customerName;
  final String customerPhone;
  final String? customerEmail;
  final String deliveryMode;
  final String? deliveryAddress;
  final String? paymentMethod;
  final VoidCallback onConfirm;
  final VoidCallback onBack;

  const OrderSummaryPage({
    super.key,
    required this.customerName,
    required this.customerPhone,
    this.customerEmail,
    required this.deliveryMode,
    this.deliveryAddress,
    this.paymentMethod,
    required this.onConfirm,
    required this.onBack,
  });

  String _paymentLabel(String? method) {
    switch (method) {
      case 'wave':        return 'Wave';
      case 'especes':     return 'Espèces';
      case 'mobile_money': return 'Mobile Money';
      default:            return method ?? 'Espèces';
    }
  }

  IconData _paymentIcon(String? method) {
    switch (method) {
      case 'wave':         return Icons.waves_rounded;
      case 'especes':      return Icons.payments_outlined;
      case 'mobile_money': return Icons.phone_android_outlined;
      default:             return Icons.payments_outlined;
    }
  }

  @override
  Widget build(BuildContext context) {
    final cartManager = CartManager();
    final items = cartManager.items;
    final total = cartManager.totalPrice;
    final shopTheme = BoutiqueThemeProvider.of(context);

    return Scaffold(
      backgroundColor: const Color(0xFFF3F4F8),
      body: SafeArea(
        child: Column(
          children: [
            // ── Header ─────────────────────────────────────────────────
            Container(
              color: Colors.white,
              padding: const EdgeInsets.fromLTRB(16, 12, 20, 12),
              child: Row(
                children: [
                  // Bouton retour
                  GestureDetector(
                    onTap: onBack,
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(Icons.arrow_back_ios_new_rounded,
                          size: 16, color: Colors.grey.shade800),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Text(
                    'Résumé de la commande',
                    style: GoogleFonts.inriaSerif(
                      fontSize: 19,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF0D0D26),
                    ),
                  ),
                ],
              ),
            ),

            // ── Contenu scrollable ──────────────────────────────────────
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 20, 16, 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [

                    // ── Section : Articles ─────────────────────────────
                    _sectionLabel('Articles'),
                    const SizedBox(height: 8),
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 10,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: Column(
                        children: items.asMap().entries.map((entry) {
                          final index = entry.key;
                          final item = entry.value;
                          final itemTotal =
                              (item['price'] as int) * (item['quantity'] as int);
                          final isLast = index == items.length - 1;

                          return Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 14),
                            decoration: BoxDecoration(
                              border: !isLast
                                  ? Border(
                                      bottom: BorderSide(
                                          color: Colors.grey.shade100,
                                          width: 1))
                                  : null,
                            ),
                            child: Row(
                              children: [
                                // Quantité badge
                                Container(
                                  width: 32,
                                  height: 32,
                                  decoration: BoxDecoration(
                                    color: Colors.grey.shade100,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Center(
                                    child: Text(
                                      'x${item['quantity']}',
                                      style: GoogleFonts.inriaSerif(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w700,
                                        color: Colors.grey.shade700,
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                // Nom + taille
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        item['name'] ?? 'Produit',
                                        style: GoogleFonts.inriaSerif(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w600,
                                          color: const Color(0xFF1A1A2E),
                                        ),
                                      ),
                                      if (item['size'] != null)
                                        Text(
                                          'Taille : ${item['size']}',
                                          style: GoogleFonts.inriaSerif(
                                            fontSize: 14,
                                            color: Colors.grey.shade500,
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                                // Prix
                                Text(
                                  '${itemTotal.toStringAsFixed(0)} FCFA',
                                  style: GoogleFonts.inriaSerif(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w700,
                                    color: const Color(0xFF0D0D26),
                                  ),
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                      ),
                    ),

                    const SizedBox(height: 20),

                    // ── Section : Livraison ────────────────────────────
                    _sectionLabel('Livraison'),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 14),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 10,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: Colors.grey.shade100,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Icon(
                              deliveryMode == 'Livraison'
                                  ? Icons.local_shipping_outlined
                                  : Icons.storefront_outlined,
                              color: Colors.grey.shade600,
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  deliveryMode == 'Livraison'
                                      ? 'Livraison à domicile'
                                      : 'Récupération en boutique',
                                  style: GoogleFonts.inriaSerif(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    color: const Color(0xFF1A1A2E),
                                  ),
                                ),
                                if (deliveryAddress != null &&
                                    deliveryAddress!.isNotEmpty)
                                  Text(
                                    deliveryAddress!,
                                    style: GoogleFonts.inriaSerif(
                                      fontSize: 14,
                                      color: Colors.grey.shade500,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                              ],
                            ),
                          ),
                          // Badge frais
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 5),
                            decoration: BoxDecoration(
                              color: Colors.grey.shade100,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              'Frais variables',
                              style: GoogleFonts.inriaSerif(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: Colors.grey.shade600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 20),

                    // ── Section : Paiement ─────────────────────────────
                    _sectionLabel('Paiement'),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 14),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 10,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: Colors.grey.shade100,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Icon(
                              _paymentIcon(paymentMethod),
                              color: Colors.grey.shade600,
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Text(
                            _paymentLabel(paymentMethod),
                            style: GoogleFonts.inriaSerif(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFF1A1A2E),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 20),

                    // ── Section : Coordonnées ──────────────────────────
                    _sectionLabel('Coordonnées'),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 10,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          _infoRow(Icons.person_outline_rounded, customerName),
                          _divider(),
                          _infoRow(Icons.phone_outlined, customerPhone),
                          if (deliveryAddress != null &&
                              deliveryAddress!.isNotEmpty) ...[
                            _divider(),
                            _infoRow(
                                Icons.location_on_outlined, deliveryAddress!),
                          ],
                          if (customerEmail != null &&
                              customerEmail!.isNotEmpty) ...[
                            _divider(),
                            _infoRow(Icons.email_outlined, customerEmail!),
                          ],
                        ],
                      ),
                    ),

                    const SizedBox(height: 20),

                    // ── Total ──────────────────────────────────────────
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 18),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 10,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Total à payer',
                            style: GoogleFonts.inriaSerif(
                              fontSize: 17,
                              fontWeight: FontWeight.w600,
                              color: Colors.grey.shade600,
                            ),
                          ),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                '${total.toStringAsFixed(0)}',
                                style: GoogleFonts.inriaSerif(
                                  fontSize: 28,
                                  fontWeight: FontWeight.w800,
                                  color: const Color(0xFF0D0D26),
                                  height: 1,
                                ),
                              ),
                              const SizedBox(width: 4),
                              Padding(
                                padding: const EdgeInsets.only(bottom: 2),
                                child: Text(
                                  'FCFA',
                                  style: GoogleFonts.inriaSerif(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.grey.shade500,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // ── Bouton confirmation ─────────────────────────────────────
            Container(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.07),
                    blurRadius: 16,
                    offset: const Offset(0, -4),
                  ),
                ],
              ),
              child: SafeArea(
                top: false,
                child: GestureDetector(
                  onTap: onConfirm,
                  child: Container(
                    height: 56,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          shopTheme.primary,
                          shopTheme.gradientEnd,
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: shopTheme.primary.withOpacity(0.40),
                          blurRadius: 16,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.check_circle_outline_rounded,
                            color: Colors.white, size: 22),
                        const SizedBox(width: 10),
                        Text(
                          'Confirmer la commande',
                          style: GoogleFonts.inriaSerif(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
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
          ],
        ),
      ),
    );
  }

  Widget _sectionLabel(String label) => Text(
        label,
        style: GoogleFonts.inriaSerif(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: Colors.grey.shade500,
          letterSpacing: 0.8,
        ),
      );

  Widget _divider() => Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Divider(height: 1, color: Colors.grey.shade100),
      );

  Widget _infoRow(IconData icon, String text) => Row(
        children: [
          Icon(icon, size: 18, color: Colors.grey.shade500),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: GoogleFonts.inriaSerif(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: const Color(0xFF1A1A2E),
              ),
            ),
          ),
        ],
      );
}
