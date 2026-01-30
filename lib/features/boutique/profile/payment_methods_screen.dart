import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Écran des moyens de paiement
class PaymentMethodsScreen extends StatefulWidget {
  const PaymentMethodsScreen({super.key});

  @override
  State<PaymentMethodsScreen> createState() => _PaymentMethodsScreenState();
}

class _PaymentMethodsScreenState extends State<PaymentMethodsScreen> {
  // Liste des moyens de paiement enregistrés
  // Seuls Wave et Espèces sont disponibles dans l'API actuelle
  final List<Map<String, dynamic>> _paymentMethods = [
    {
      'id': '1',
      'type': 'especes',
      'name': 'Espèces',
      'details': 'Paiement à la livraison',
      'imagePath': 'lib/core/assets/cash.png',
      'isDefault': true,
    },
    {
      'id': '2',
      'type': 'wave',
      'name': 'Wave',
      'details': 'Paiement par capture d\'écran',
      'imagePath': 'lib/core/assets/WAVE.png',
      'isDefault': false,
    },
    // ============================================================
    // MODES DE PAIEMENT NON DISPONIBLES DANS L'API ACTUELLE
    // Décommenter quand l'API les supportera
    // ============================================================
    // {
    //   'id': '3',
    //   'type': 'card',
    //   'name': 'Carte bancaire',
    //   'details': '**** **** **** 4532',
    //   'imagePath': 'lib/core/assets/card.png',
    //   'isDefault': false,
    // },
    // {
    //   'id': '4',
    //   'type': 'orange',
    //   'name': 'Orange Money',
    //   'details': '+225 07 XX XX XX XX',
    //   'imagePath': 'lib/core/assets/orange.png',
    //   'isDefault': false,
    // },
    // {
    //   'id': '5',
    //   'type': 'moov',
    //   'name': 'Moov Money',
    //   'details': '+225 01 XX XX XX XX',
    //   'imagePath': 'lib/core/assets/moov.png',
    //   'isDefault': false,
    // },
  ];

  void _setDefaultPayment(String id) {
    setState(() {
      for (var method in _paymentMethods) {
        method['isDefault'] = method['id'] == id;
      }
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Moyen de paiement par défaut modifié',
          style: GoogleFonts.openSans(
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
        ),
        backgroundColor: const Color(0xFF4CAF50),
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
    );
  }

  void _deletePaymentMethod(String id) {
    setState(() {
      _paymentMethods.removeWhere((method) => method['id'] == id);
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Moyen de paiement supprimé',
          style: GoogleFonts.openSans(
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
        ),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
    );
  }

  void _showDeleteConfirmation(String id, String name) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Supprimer',
          style: GoogleFonts.openSans(fontWeight: FontWeight.bold),
        ),
        content: Text(
          'Voulez-vous vraiment supprimer $name ?',
          style: GoogleFonts.openSans(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Annuler',
              style: GoogleFonts.openSans(color: Colors.grey),
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _deletePaymentMethod(id);
            },
            child: Text(
              'Supprimer',
              style: GoogleFonts.openSans(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Container(
              color: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: const Icon(Icons.arrow_back, size: 24),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Text(
                      'Moyens de paiement',
                      style: GoogleFonts.openSans(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Contenu
            Expanded(
              child: _paymentMethods.isEmpty
                  ? _buildEmptyState()
                  : ListView.builder(
                      padding: const EdgeInsets.all(20),
                      itemCount: _paymentMethods.length,
                      itemBuilder: (context, index) {
                        final method = _paymentMethods[index];
                        return _buildPaymentCard(method);
                      },
                    ),
            ),
          ],
        ),
      ),
      floatingActionButton: Container(
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFFD48EFC), Color(0xFF8936A8)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(100),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF8936A8).withOpacity(0.4),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: FloatingActionButton.extended(
          onPressed: () {
            // Navigation vers l'écran d'ajout
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  'Ajouter un moyen de paiement',
                  style: GoogleFonts.openSans(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                backgroundColor: const Color(0xFF8936A8),
                duration: const Duration(seconds: 2),
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            );
          },
          backgroundColor: Colors.transparent,
          elevation: 0,
          icon: const Icon(Icons.add, color: Colors.white),
          label: Text(
            'Ajouter',
            style: GoogleFonts.openSans(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Icône
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.credit_card_outlined,
              size: 60,
              color: Colors.grey.shade400,
            ),
          ),

          const SizedBox(height: 32),

          // Titre
          Text(
            'Aucun moyen de paiement',
            style: GoogleFonts.openSans(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),

          const SizedBox(height: 12),

          // Description
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40),
            child: Text(
              'Ajoutez une carte ou un compte\nMobile Money',
              textAlign: TextAlign.center,
              style: GoogleFonts.openSans(
                fontSize: 15,
                color: Colors.grey.shade600,
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentCard(Map<String, dynamic> method) {
    final isDefault = method['isDefault'] ?? false;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: isDefault
            ? Border.all(color: const Color(0xFF8936A8), width: 2)
            : null,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            // Image du moyen de paiement
            Container(
              width: 60,
              height: 60,
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade200, width: 1),
              ),
              child: Image.asset(
                method['imagePath'],
                fit: BoxFit.contain,
              ),
            ),

            const SizedBox(width: 16),

            // Informations
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        method['name'],
                        style: GoogleFonts.openSans(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
                        ),
                      ),
                      if (isDefault) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: const Color(0xFF8936A8),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            'Par défaut',
                            style: GoogleFonts.openSans(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    method['details'],
                    style: GoogleFonts.openSans(
                      fontSize: 14,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ),

            // Menu
            PopupMenuButton<String>(
              onSelected: (value) {
                if (value == 'default') {
                  _setDefaultPayment(method['id']);
                } else if (value == 'delete') {
                  _showDeleteConfirmation(method['id'], method['name']);
                }
              },
              itemBuilder: (context) => [
                if (!isDefault)
                  PopupMenuItem(
                    value: 'default',
                    child: Row(
                      children: [
                        const Icon(Icons.check_circle_outline,
                            size: 20, color: Color(0xFF8936A8)),
                        const SizedBox(width: 12),
                        Text(
                          'Définir par défaut',
                          style: GoogleFonts.openSans(fontSize: 14),
                        ),
                      ],
                    ),
                  ),
                PopupMenuItem(
                  value: 'delete',
                  child: Row(
                    children: [
                      const Icon(Icons.delete_outline,
                          size: 20, color: Colors.red),
                      const SizedBox(width: 12),
                      Text(
                        'Supprimer',
                        style: GoogleFonts.openSans(
                            fontSize: 14, color: Colors.red),
                      ),
                    ],
                  ),
                ),
              ],
              icon: Icon(
                Icons.more_vert,
                color: Colors.grey.shade600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
