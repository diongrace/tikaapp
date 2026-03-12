import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../services/auth_service.dart';
import '../../../services/profile_service.dart';
import '../../../services/models/profile_model.dart';
import '../../../core/services/storage_service.dart';

/// Écran des adresses de livraison - conforme au web
class AddressesScreen extends StatefulWidget {
  const AddressesScreen({super.key});

  @override
  State<AddressesScreen> createState() => _AddressesScreenState();
}

class _AddressesScreenState extends State<AddressesScreen> {
  bool _isAuthenticated = false;
  bool _isLoading = true;

  List<ProfileAddress> _apiAddresses = [];
  List<Map<String, dynamic>> _localAddresses = [];

  static const int _maxAddresses = 3;

  // Régions de Côte d'Ivoire
  static const List<String> _ciRegions = [
    'Abidjan', 'Bouaké', 'Yamoussoukro', 'San-Pédro', 'Daloa', 'Korhogo',
    'Man', 'Divo', 'Gagnoa', 'Abengourou', 'Bondoukou', 'Soubré',
    'Odienné', 'Touba', 'Séguéla', 'Issia', 'Sassandra', 'Duekoué',
    'Aboisso', 'Adzopé',
  ];

  // Icônes emoji pour les adresses
  static const List<Map<String, String>> _addressEmojis = [
    {'emoji': '🏠', 'label': 'Maison'},
    {'emoji': '💼', 'label': 'Bureau'},
    {'emoji': '🏢', 'label': 'Immeuble'},
    {'emoji': '🏫', 'label': 'École'},
    {'emoji': '🏪', 'label': 'Commerce'},
    {'emoji': '📍', 'label': 'Épingle'},
    {'emoji': '❤️', 'label': 'Favori'},
    {'emoji': '⭐', 'label': 'Principal'},
    {'emoji': '🎯', 'label': 'Cible'},
    {'emoji': '🏥', 'label': 'Hôpital'},
    {'emoji': '⛪', 'label': 'Église'},
    {'emoji': '🏛️', 'label': 'Bâtiment'},
  ];

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
      if (mounted) setState(() { _apiAddresses = addresses; _isLoading = false; });
    } else {
      final addresses = await StorageService.getCustomerAddresses();
      if (mounted) setState(() { _localAddresses = addresses; _isLoading = false; });
    }
  }

  int get _addressCount =>
      _isAuthenticated ? _apiAddresses.length : _localAddresses.length;

  Future<void> _setDefaultAddress(dynamic id) async {
    if (_isAuthenticated) {
      final success = await ProfileService.setDefaultAddress(id as int);
      if (success) { await _loadAddresses(); if (mounted) _snack('Adresse par défaut modifiée', Colors.green); }
      else if (mounted) _snack('Erreur', Colors.red);
    } else {
      setState(() {
        for (var a in _localAddresses) a['isDefault'] = a['id'] == id;
      });
      await StorageService.saveCustomerAddresses(_localAddresses);
      _snack('Adresse par défaut modifiée', Colors.green);
    }
  }

  Future<void> _deleteAddress(dynamic id) async {
    if (_isAuthenticated) {
      final success = await ProfileService.deleteAddress(id as int);
      if (success) { await _loadAddresses(); if (mounted) _snack('Adresse supprimée', Colors.red); }
      else if (mounted) _snack('Erreur lors de la suppression', Colors.red);
    } else {
      setState(() => _localAddresses.removeWhere((a) => a['id'] == id));
      await StorageService.saveCustomerAddresses(_localAddresses);
      _snack('Adresse supprimée', Colors.red);
    }
  }

  void _confirmDelete(dynamic id, String name) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Supprimer', style: GoogleFonts.inriaSerif(fontWeight: FontWeight.bold)),
        content: Text('Supprimer l\'adresse "$name" ?', style: GoogleFonts.inriaSerif()),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text('Annuler', style: GoogleFonts.inriaSerif(color: Colors.grey))),
          TextButton(
            onPressed: () { Navigator.pop(ctx); _deleteAddress(id); },
            child: Text('Supprimer', style: GoogleFonts.inriaSerif(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _showAddForm() {
    if (_addressCount >= _maxAddresses) {
      _snack('Maximum $_maxAddresses adresses atteint', Colors.orange);
      return;
    }

    final labelController = TextEditingController();
    final addressController = TextEditingController();
    final cityController = TextEditingController();
    String? selectedRegion;
    int selectedEmojiIndex = 0;
    bool isAdding = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheet) => DraggableScrollableSheet(
          initialChildSize: 0.92,
          minChildSize: 0.6,
          maxChildSize: 0.95,
          builder: (_, scrollController) => Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: Column(
              children: [
                // Header gradient
                Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Color(0xFF8936A8), Color(0xFFE040A0)],
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                    ),
                    borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                  ),
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 18),
                  child: Row(
                    children: [
                      Text(
                        'Ajouter une adresse',
                        style: GoogleFonts.inriaSerif(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),

                // Formulaire
                Expanded(
                  child: SingleChildScrollView(
                    controller: scrollController,
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [

                        // Nom de l'adresse
                        _formLabel('🏷️', 'Nom de l\'adresse'),
                        const SizedBox(height: 8),
                        _formField(
                          controller: labelController,
                          hint: 'Ex: Maison, Bureau, etc.',
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Donnez un nom pour identifier facilement cette adresse',
                          style: GoogleFonts.inriaSerif(fontSize: 14, color: Colors.grey.shade500),
                        ),

                        const SizedBox(height: 18),

                        // Région
                        _formLabel('🗺️', 'Région'),
                        const SizedBox(height: 8),
                        DropdownButtonFormField<String>(
                          value: selectedRegion,
                          style: GoogleFonts.inriaSerif(fontSize: 16, color: Colors.black87),
                          decoration: InputDecoration(
                            hintText: 'Sélectionnez une région',
                            hintStyle: GoogleFonts.inriaSerif(fontSize: 16, color: Colors.grey.shade400),
                            filled: true,
                            fillColor: const Color(0xFFF8F8F8),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: BorderSide(color: Colors.grey.shade200),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: BorderSide(color: Colors.grey.shade200),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: const BorderSide(color: Color(0xFF8936A8), width: 1.5),
                            ),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                          ),
                          items: _ciRegions.map((r) => DropdownMenuItem(
                            value: r,
                            child: Text(r, style: GoogleFonts.inriaSerif(fontSize: 16)),
                          )).toList(),
                          onChanged: (v) => setSheet(() => selectedRegion = v),
                        ),

                        const SizedBox(height: 18),

                        // Commune / Ville
                        _formLabel('🏙️', 'Commune / Ville'),
                        const SizedBox(height: 8),
                        _formField(
                          controller: cityController,
                          hint: 'Ex: Cocody, Plateau, Yopougon',
                        ),

                        const SizedBox(height: 18),

                        // Icône (optionnel)
                        _formLabel('🏘️', 'Icône', optional: true),
                        const SizedBox(height: 10),
                        GridView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 6,
                            crossAxisSpacing: 8,
                            mainAxisSpacing: 8,
                            childAspectRatio: 1,
                          ),
                          itemCount: _addressEmojis.length,
                          itemBuilder: (_, i) {
                            final isSelected = selectedEmojiIndex == i;
                            return GestureDetector(
                              onTap: () => setSheet(() => selectedEmojiIndex = i),
                              child: Container(
                                decoration: BoxDecoration(
                                  color: isSelected
                                      ? const Color(0xFF8936A8).withOpacity(0.1)
                                      : Colors.grey.shade100,
                                  borderRadius: BorderRadius.circular(10),
                                  border: isSelected
                                      ? Border.all(color: const Color(0xFF8936A8), width: 2)
                                      : Border.all(color: Colors.grey.shade200),
                                ),
                                child: Center(
                                  child: Text(
                                    _addressEmojis[i]['emoji']!,
                                    style: const TextStyle(fontSize: 24),
                                  ),
                                ),
                              ),
                            );
                          },
                        ),

                        const SizedBox(height: 18),

                        // Adresse complète
                        _formLabel('📍', 'Adresse complète'),
                        const SizedBox(height: 8),
                        _formField(
                          controller: addressController,
                          hint: 'Ex: Cocody Angré 8ème tranche, villa 234',
                          maxLines: 3,
                        ),

                        const SizedBox(height: 28),

                        // Boutons
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton(
                                onPressed: isAdding ? null : () => Navigator.pop(ctx),
                                style: OutlinedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(vertical: 14),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                  side: BorderSide(color: Colors.grey.shade300),
                                ),
                                child: Text(
                                  'Annuler',
                                  style: GoogleFonts.inriaSerif(
                                    fontSize: 17,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.black87,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: GestureDetector(
                                onTap: isAdding ? null : () async {
                                  if (labelController.text.trim().isEmpty ||
                                      addressController.text.trim().isEmpty ||
                                      cityController.text.trim().isEmpty ||
                                      selectedRegion == null) {
                                    _snack('Veuillez remplir tous les champs', Colors.orange);
                                    return;
                                  }

                                  final emoji = _addressEmojis[selectedEmojiIndex]['emoji']!;

                                  setSheet(() => isAdding = true);

                                  if (_isAuthenticated) {
                                    final newAddress = await ProfileService.addAddress(
                                      label: labelController.text.trim(),
                                      address: addressController.text.trim(),
                                      city: cityController.text.trim(),
                                      region: selectedRegion!,
                                    );
                                    if (!ctx.mounted) return;
                                    setSheet(() => isAdding = false);
                                    if (newAddress != null) {
                                      Navigator.pop(ctx);
                                      await _loadAddresses();
                                      if (mounted) _snack('Adresse ajoutée', Colors.green);
                                    } else {
                                      if (mounted) _snack(ProfileService.lastAddressError ?? 'Erreur', Colors.red);
                                    }
                                  } else {
                                    setState(() {
                                      _localAddresses.add({
                                        'id': DateTime.now().toString(),
                                        'name': labelController.text.trim(),
                                        'address': '${addressController.text.trim()}, ${cityController.text.trim()}, ${selectedRegion!}',
                                        'city': cityController.text.trim(),
                                        'region': selectedRegion!,
                                        'emoji': emoji,
                                        'isDefault': _localAddresses.isEmpty,
                                      });
                                    });
                                    await StorageService.saveCustomerAddresses(_localAddresses);
                                    if (!ctx.mounted) return;
                                    Navigator.pop(ctx);
                                    if (mounted) _snack('Adresse ajoutée', Colors.green);
                                  }
                                },
                                child: Container(
                                  height: 48,
                                  decoration: BoxDecoration(
                                    gradient: isAdding ? null : const LinearGradient(
                                      colors: [Color(0xFF8936A8), Color(0xFFE040A0)],
                                      begin: Alignment.centerLeft,
                                      end: Alignment.centerRight,
                                    ),
                                    color: isAdding ? Colors.grey.shade300 : null,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Center(
                                    child: isAdding
                                        ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                                        : Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              const Icon(Icons.save_outlined, color: Colors.white, size: 18),
                                              const SizedBox(width: 8),
                                              Text('Enregistrer', style: GoogleFonts.inriaSerif(fontSize: 17, fontWeight: FontWeight.bold, color: Colors.white)),
                                            ],
                                          ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 16),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _formLabel(String emoji, String label, {bool optional = false}) {
    return Row(
      children: [
        Text(emoji, style: const TextStyle(fontSize: 18)),
        const SizedBox(width: 6),
        Text(
          label,
          style: GoogleFonts.inriaSerif(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.black87),
        ),
        if (optional) ...[
          const SizedBox(width: 6),
          Text('(optionnel)', style: GoogleFonts.inriaSerif(fontSize: 15, color: Colors.grey.shade400)),
        ],
      ],
    );
  }

  Widget _formField({
    required TextEditingController controller,
    required String hint,
    int maxLines = 1,
  }) {
    return TextField(
      controller: controller,
      maxLines: maxLines,
      style: GoogleFonts.inriaSerif(fontSize: 16),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: GoogleFonts.inriaSerif(fontSize: 16, color: Colors.grey.shade400),
        filled: true,
        fillColor: const Color(0xFFF8F8F8),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: Colors.grey.shade200)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: Colors.grey.shade200)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFF8936A8), width: 1.5)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      ),
    );
  }

  void _snack(String msg, Color color) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg, style: GoogleFonts.inriaSerif(fontWeight: FontWeight.w600)),
      backgroundColor: color,
      duration: const Duration(seconds: 2),
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF2F2F7),
      body: SafeArea(
        child: Column(
          children: [
            // Header blanc
            Container(
              color: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: const Icon(Icons.arrow_back, size: 24),
                  ),
                  const SizedBox(width: 10),
                  const Icon(Icons.location_on, color: Color(0xFFE53935), size: 22),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Mes adresses de livraison',
                      style: GoogleFonts.inriaSerif(fontSize: 19, fontWeight: FontWeight.bold),
                    ),
                  ),
                  Text(
                    '$_addressCount/$_maxAddresses adresses',
                    style: GoogleFonts.inriaSerif(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF8936A8),
                    ),
                  ),
                ],
              ),
            ),

            // Contenu
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator(color: Color(0xFF8936A8)))
                  : SingleChildScrollView(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          // Bannière info
                          Container(
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: const Color(0xFF2196F3).withOpacity(0.08),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(6),
                                  decoration: const BoxDecoration(
                                    color: Color(0xFF2196F3),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(Icons.info_outline, color: Colors.white, size: 14),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Gérez vos adresses',
                                        style: GoogleFonts.inriaSerif(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.black87,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        'Vous pouvez enregistrer jusqu\'à $_maxAddresses adresses de livraison. L\'adresse marquée comme "par défaut" sera automatiquement pré-remplie lors de vos commandes.',
                                        style: GoogleFonts.inriaSerif(
                                          fontSize: 14,
                                          color: Colors.grey.shade600,
                                          height: 1.4,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 14),

                          // Carte pointillée "Ajouter une adresse" (si pas au max)
                          if (_addressCount < _maxAddresses)
                            GestureDetector(
                              onTap: _showAddForm,
                              child: Container(
                                width: double.infinity,
                                padding: const EdgeInsets.symmetric(vertical: 28),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF8936A8).withOpacity(0.04),
                                  borderRadius: BorderRadius.circular(14),
                                  border: Border.all(
                                    color: const Color(0xFF8936A8).withOpacity(0.3),
                                    width: 1.5,
                                    style: BorderStyle.solid,
                                  ),
                                ),
                                child: Column(
                                  children: [
                                    Container(
                                      width: 48,
                                      height: 48,
                                      decoration: BoxDecoration(
                                        color: const Color(0xFF8936A8).withOpacity(0.1),
                                        shape: BoxShape.circle,
                                      ),
                                      child: const Icon(Icons.add, color: Color(0xFF8936A8), size: 26),
                                    ),
                                    const SizedBox(height: 10),
                                    Text(
                                      'Ajouter une adresse',
                                      style: GoogleFonts.inriaSerif(
                                        fontSize: 17,
                                        fontWeight: FontWeight.bold,
                                        color: const Color(0xFF8936A8),
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      '${_maxAddresses - _addressCount} adresse(s) disponible(s)',
                                      style: GoogleFonts.inriaSerif(
                                        fontSize: 14,
                                        color: Colors.grey.shade500,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),

                          const SizedBox(height: 14),

                          // Liste adresses ou état vide
                          if (_addressCount == 0)
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.symmetric(vertical: 36, horizontal: 20),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(14),
                                boxShadow: [
                                  BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8, offset: const Offset(0, 2)),
                                ],
                              ),
                              child: Column(
                                children: [
                                  Container(
                                    width: 64,
                                    height: 64,
                                    decoration: BoxDecoration(color: Colors.grey.shade100, shape: BoxShape.circle),
                                    child: Icon(Icons.map_outlined, size: 32, color: Colors.grey.shade400),
                                  ),
                                  const SizedBox(height: 16),
                                  Text(
                                    'Aucune adresse enregistrée',
                                    style: GoogleFonts.inriaSerif(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    'Ajoutez votre première adresse de livraison',
                                    style: GoogleFonts.inriaSerif(fontSize: 15, color: Colors.grey.shade500),
                                  ),
                                  const SizedBox(height: 20),
                                  GestureDetector(
                                    onTap: _showAddForm,
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(vertical: 13, horizontal: 28),
                                      decoration: BoxDecoration(
                                        gradient: const LinearGradient(
                                          colors: [Color(0xFF8936A8), Color(0xFFE040A0)],
                                          begin: Alignment.centerLeft,
                                          end: Alignment.centerRight,
                                        ),
                                        borderRadius: BorderRadius.circular(30),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          const Icon(Icons.add, color: Colors.white, size: 18),
                                          const SizedBox(width: 8),
                                          Text(
                                            'Ajouter une adresse',
                                            style: GoogleFonts.inriaSerif(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.white),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            )
                          else
                            ..._buildAddressList(),
                        ],
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildAddressList() {
    if (_isAuthenticated) {
      return _apiAddresses.map((addr) => _buildAddressCard(
        id: addr.id,
        name: addr.label,
        address: addr.fullAddress,
        isDefault: addr.isDefault,
        emoji: _emojiFromLabel(addr.label),
      )).toList();
    } else {
      return _localAddresses.map((addr) => _buildAddressCard(
        id: addr['id'],
        name: addr['name'] ?? '',
        address: addr['address'] ?? '',
        isDefault: addr['isDefault'] ?? false,
        emoji: addr['emoji'] ?? '📍',
      )).toList();
    }
  }

  String _emojiFromLabel(String label) {
    final l = label.toLowerCase();
    if (l.contains('maison') || l.contains('home') || l.contains('chez')) return '🏠';
    if (l.contains('bureau') || l.contains('office') || l.contains('travail')) return '💼';
    if (l.contains('appart') || l.contains('immeuble')) return '🏢';
    if (l.contains('école') || l.contains('ecole')) return '🏫';
    if (l.contains('commerce') || l.contains('boutique')) return '🏪';
    if (l.contains('favori')) return '❤️';
    return '📍';
  }

  Widget _buildAddressCard({
    required dynamic id,
    required String name,
    required String address,
    required bool isDefault,
    String emoji = '📍',
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: isDefault ? Border.all(color: const Color(0xFF8936A8), width: 2) : null,
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8, offset: const Offset(0, 2)),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Emoji icône
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: const Color(0xFF8936A8).withOpacity(0.08),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(
                child: Text(emoji, style: const TextStyle(fontSize: 26)),
              ),
            ),

            const SizedBox(width: 14),

            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        name,
                        style: GoogleFonts.inriaSerif(fontSize: 17, fontWeight: FontWeight.bold, color: Colors.black87),
                      ),
                      if (isDefault) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFF8936A8), Color(0xFFE040A0)],
                              begin: Alignment.centerLeft,
                              end: Alignment.centerRight,
                            ),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            'Par défaut',
                            style: GoogleFonts.inriaSerif(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.white),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    address,
                    style: GoogleFonts.inriaSerif(fontSize: 15, color: Colors.grey.shade600, height: 1.4),
                  ),
                ],
              ),
            ),

            PopupMenuButton<String>(
              onSelected: (val) {
                if (val == 'default') _setDefaultAddress(id);
                else if (val == 'delete') _confirmDelete(id, name);
              },
              itemBuilder: (_) => [
                if (!isDefault)
                  PopupMenuItem(
                    value: 'default',
                    child: Row(children: [
                      const Icon(Icons.check_circle_outline, size: 18, color: Color(0xFF8936A8)),
                      const SizedBox(width: 10),
                      Text('Définir par défaut', style: GoogleFonts.inriaSerif(fontSize: 16)),
                    ]),
                  ),
                PopupMenuItem(
                  value: 'delete',
                  child: Row(children: [
                    const Icon(Icons.delete_outline, size: 18, color: Colors.red),
                    const SizedBox(width: 10),
                    Text('Supprimer', style: GoogleFonts.inriaSerif(fontSize: 16, color: Colors.red)),
                  ]),
                ),
              ],
              icon: Icon(Icons.more_vert, color: Colors.grey.shade500),
            ),
          ],
        ),
      ),
    );
  }
}
