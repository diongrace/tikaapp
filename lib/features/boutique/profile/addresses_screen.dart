import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../services/auth_service.dart';
import '../../../services/profile_service.dart';
import '../../../services/models/profile_model.dart';
import '../../../core/services/storage_service.dart';

/// Ecran de la liste des adresses de livraison
/// Utilise l'API quand authentifie, stockage local sinon
class AddressesScreen extends StatefulWidget {
  const AddressesScreen({super.key});

  @override
  State<AddressesScreen> createState() => _AddressesScreenState();
}

class _AddressesScreenState extends State<AddressesScreen> {
  bool _isAuthenticated = false;
  bool _isLoading = true;

  // Mode API
  List<ProfileAddress> _apiAddresses = [];

  // Mode local
  List<Map<String, dynamic>> _localAddresses = [];

  static const int _maxAddresses = 3;

  @override
  void initState() {
    super.initState();
    _loadAddresses();
  }

  Future<void> _loadAddresses() async {
    setState(() => _isLoading = true);

    _isAuthenticated = AuthService.isAuthenticated;

    if (_isAuthenticated) {
      final addresses = await ProfileService.getAddresses();
      if (mounted) {
        setState(() {
          _apiAddresses = addresses;
          _isLoading = false;
        });
      }
    } else {
      final addresses = await StorageService.getCustomerAddresses();
      if (mounted) {
        setState(() {
          _localAddresses = addresses;
          _isLoading = false;
        });
      }
    }
  }

  int get _addressCount =>
      _isAuthenticated ? _apiAddresses.length : _localAddresses.length;

  Future<void> _setDefaultAddress(dynamic id) async {
    if (_isAuthenticated) {
      final success = await ProfileService.setDefaultAddress(id as int);
      if (success) {
        await _loadAddresses();
        if (mounted) _showSnackBar('Adresse par defaut modifiee', Colors.green);
      } else {
        if (mounted) _showSnackBar('Erreur', Colors.red);
      }
    } else {
      setState(() {
        for (var address in _localAddresses) {
          address['isDefault'] = address['id'] == id;
        }
      });
      await StorageService.saveCustomerAddresses(_localAddresses);
      _showSnackBar('Adresse par defaut modifiee', Colors.green);
    }
  }

  Future<void> _deleteAddress(dynamic id) async {
    if (_isAuthenticated) {
      final success = await ProfileService.deleteAddress(id as int);
      if (success) {
        await _loadAddresses();
        if (mounted) _showSnackBar('Adresse supprimee', Colors.red);
      } else {
        if (mounted) _showSnackBar('Erreur lors de la suppression', Colors.red);
      }
    } else {
      setState(() {
        _localAddresses.removeWhere((address) => address['id'] == id);
      });
      await StorageService.saveCustomerAddresses(_localAddresses);
      _showSnackBar('Adresse supprimee', Colors.red);
    }
  }

  void _showDeleteConfirmation(dynamic id, String name) {
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
    if (_addressCount >= _maxAddresses) {
      _showSnackBar('Maximum $_maxAddresses adresses', Colors.orange);
      return;
    }

    final labelController = TextEditingController();
    final addressController = TextEditingController();
    final cityController = TextEditingController();
    bool isAdding = false;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(
            'Ajouter une adresse',
            style: GoogleFonts.openSans(fontWeight: FontWeight.bold),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: labelController,
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
                    hintText: 'Adresse complete',
                    labelStyle: GoogleFonts.openSans(),
                    hintStyle: GoogleFonts.openSans(color: Colors.grey),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: cityController,
                  decoration: InputDecoration(
                    labelText: 'Ville (optionnel)',
                    hintText: 'Ex: Abidjan',
                    labelStyle: GoogleFonts.openSans(),
                    hintStyle: GoogleFonts.openSans(color: Colors.grey),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: isAdding ? null : () => Navigator.pop(context),
              child: Text(
                'Annuler',
                style: GoogleFonts.openSans(color: Colors.grey),
              ),
            ),
            TextButton(
              onPressed: isAdding
                  ? null
                  : () async {
                      if (labelController.text.isEmpty || addressController.text.isEmpty) {
                        return;
                      }

                      if (_isAuthenticated) {
                        setDialogState(() => isAdding = true);
                        final newAddress = await ProfileService.addAddress(
                          label: labelController.text,
                          address: addressController.text,
                          city: cityController.text.isNotEmpty ? cityController.text : null,
                        );
                        if (!context.mounted) return;
                        setDialogState(() => isAdding = false);

                        if (newAddress != null) {
                          Navigator.pop(context);
                          await _loadAddresses();
                          if (mounted) _showSnackBar('Adresse ajoutee', Colors.green);
                        } else {
                          if (mounted) _showSnackBar('Erreur lors de l\'ajout', Colors.red);
                        }
                      } else {
                        setState(() {
                          _localAddresses.add({
                            'id': DateTime.now().toString(),
                            'name': labelController.text,
                            'address': addressController.text,
                            'city': cityController.text,
                            'isDefault': _localAddresses.isEmpty,
                          });
                        });
                        await StorageService.saveCustomerAddresses(_localAddresses);
                        if (!context.mounted) return;
                        Navigator.pop(context);
                        _showSnackBar('Adresse ajoutee', Colors.green);
                      }
                    },
              child: isAdding
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Text(
                      'Ajouter',
                      style: GoogleFonts.openSans(color: const Color(0xFF8936A8)),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  void _showSnackBar(String message, Color color) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: GoogleFonts.openSans(fontSize: 15, fontWeight: FontWeight.w600),
        ),
        backgroundColor: color,
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
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
              child: _isLoading
                  ? const Center(
                      child: CircularProgressIndicator(color: Color(0xFF8936A8)),
                    )
                  : _addressCount == 0
                      ? _buildEmptyState()
                      : _isAuthenticated
                          ? _buildApiList()
                          : _buildLocalList(),
            ),
          ],
        ),
      ),
      floatingActionButton: _isLoading
          ? null
          : Container(
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

  Widget _buildApiList() {
    return ListView.builder(
      padding: const EdgeInsets.all(20),
      itemCount: _apiAddresses.length,
      itemBuilder: (context, index) {
        final address = _apiAddresses[index];
        return _buildAddressCard(
          id: address.id,
          name: address.label,
          address: address.fullAddress,
          isDefault: address.isDefault,
        );
      },
    );
  }

  Widget _buildLocalList() {
    return ListView.builder(
      padding: const EdgeInsets.all(20),
      itemCount: _localAddresses.length,
      itemBuilder: (context, index) {
        final address = _localAddresses[index];
        return _buildAddressCard(
          id: address['id'],
          name: address['name'] ?? '',
          address: address['address'] ?? '',
          isDefault: address['isDefault'] ?? false,
        );
      },
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
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

          Text(
            'Aucune adresse enregistree',
            style: GoogleFonts.openSans(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),

          const SizedBox(height: 12),

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

  Widget _buildAddressCard({
    required dynamic id,
    required String name,
    required String address,
    required bool isDefault,
  }) {
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

            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        name,
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
                            'Par defaut',
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
                    address,
                    style: GoogleFonts.openSans(
                      fontSize: 14,
                      color: Colors.grey.shade600,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),

            PopupMenuButton<String>(
              onSelected: (value) {
                if (value == 'default') {
                  _setDefaultAddress(id);
                } else if (value == 'delete') {
                  _showDeleteConfirmation(id, name);
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
                          'Definir par defaut',
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
