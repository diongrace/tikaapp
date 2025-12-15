import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Écran de la liste des adresses de livraison
class AddressesScreen extends StatefulWidget {
  const AddressesScreen({super.key});

  @override
  State<AddressesScreen> createState() => _AddressesScreenState();
}

class _AddressesScreenState extends State<AddressesScreen> {
  // Liste des adresses enregistrées
  final List<Map<String, dynamic>> _addresses = [
    {
      'id': '1',
      'name': 'Maison',
      'address': 'Cocody, Angré 7ème tranche\nAbidjan, Côte d\'Ivoire',
      'isDefault': true,
    },
    {
      'id': '2',
      'name': 'Bureau',
      'address': 'Plateau, Avenue Franchet d\'Esperey\nAbidjan, Côte d\'Ivoire',
      'isDefault': false,
    },
  ];

  void _setDefaultAddress(String id) {
    setState(() {
      for (var address in _addresses) {
        address['isDefault'] = address['id'] == id;
      }
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Adresse par défaut modifiée',
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

  void _deleteAddress(String id) {
    setState(() {
      _addresses.removeWhere((address) => address['id'] == id);
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Adresse supprimée',
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
          'Voulez-vous vraiment supprimer l\'adresse "$name" ?',
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
              _deleteAddress(id);
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

  void _showAddAddressDialog() {
    final nameController = TextEditingController();
    final addressController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Ajouter une adresse',
          style: GoogleFonts.openSans(fontWeight: FontWeight.bold),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: InputDecoration(
                labelText: 'Nom',
                hintText: 'Ex: Maison, Bureau',
                labelStyle: GoogleFonts.openSans(),
                hintStyle: GoogleFonts.openSans(color: Colors.grey),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: addressController,
              maxLines: 3,
              decoration: InputDecoration(
                labelText: 'Adresse',
                hintText: 'Adresse complète',
                labelStyle: GoogleFonts.openSans(),
                hintStyle: GoogleFonts.openSans(color: Colors.grey),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
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
              if (nameController.text.isNotEmpty &&
                  addressController.text.isNotEmpty) {
                setState(() {
                  _addresses.add({
                    'id': DateTime.now().toString(),
                    'name': nameController.text,
                    'address': addressController.text,
                    'isDefault': false,
                  });
                });
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      'Adresse ajoutée avec succès',
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
            },
            child: Text(
              'Ajouter',
              style: GoogleFonts.openSans(color: const Color(0xFF8936A8)),
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
                      'Adresses de livraison',
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
              child: _addresses.isEmpty
                  ? _buildEmptyState()
                  : ListView.builder(
                      padding: const EdgeInsets.all(20),
                      itemCount: _addresses.length,
                      itemBuilder: (context, index) {
                        final address = _addresses[index];
                        return _buildAddressCard(address);
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
          onPressed: _showAddAddressDialog,
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
              Icons.location_on_outlined,
              size: 60,
              color: Colors.grey.shade400,
            ),
          ),

          const SizedBox(height: 32),

          // Titre
          Text(
            'Aucune adresse enregistrée',
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
              'Ajoutez une adresse de livraison\npour vos commandes',
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

  Widget _buildAddressCard(Map<String, dynamic> address) {
    final isDefault = address['isDefault'] ?? false;

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
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Icône
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: const Color(0xFF8936A8).withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.location_on,
                color: Color(0xFF8936A8),
                size: 24,
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
                        address['name'],
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
                  const SizedBox(height: 8),
                  Text(
                    address['address'],
                    style: GoogleFonts.openSans(
                      fontSize: 14,
                      color: Colors.grey.shade600,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),

            // Menu
            PopupMenuButton<String>(
              onSelected: (value) {
                if (value == 'default') {
                  _setDefaultAddress(address['id']);
                } else if (value == 'delete') {
                  _showDeleteConfirmation(address['id'], address['name']);
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
