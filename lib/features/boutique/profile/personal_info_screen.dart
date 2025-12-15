import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/services/storage_service.dart';

/// Écran des informations personnelles - Conforme à l'API TIKA
/// Stockage local uniquement, pas d'authentification
class PersonalInfoScreen extends StatefulWidget {
  const PersonalInfoScreen({super.key});

  @override
  State<PersonalInfoScreen> createState() => _PersonalInfoScreenState();
}

class _PersonalInfoScreenState extends State<PersonalInfoScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadCustomerInfo();
  }

  Future<void> _loadCustomerInfo() async {
    final customerInfo = await StorageService.getCustomerInfo();

    setState(() {
      _nameController.text = customerInfo['name'] ?? '';
      _phoneController.text = customerInfo['phone'] ?? '';
      _emailController.text = customerInfo['email'] ?? '';
      _isLoading = false;
    });
  }

  Future<void> _saveCustomerInfo() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      await StorageService.saveCustomerInfo(
        name: _nameController.text.trim(),
        phone: _phoneController.text.trim(),
        email: _emailController.text.trim().isNotEmpty ? _emailController.text.trim() : null,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Informations enregistrées avec succès',
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
        Navigator.pop(context, true); // Retour avec indicateur de modification
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur lors de la sauvegarde: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    super.dispose();
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
                      'Informations personnelles',
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
                      child: CircularProgressIndicator(
                        color: Color(0xFF8936A8),
                      ),
                    )
                  : SingleChildScrollView(
                      padding: const EdgeInsets.all(20),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 8),

                            // Note d'information
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: const Color(0xFF8936A8).withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Row(
                                children: [
                                  const Icon(
                                    Icons.info_outline,
                                    color: Color(0xFF8936A8),
                                    size: 22,
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Text(
                                      'Vos informations sont stockées localement et serviront à passer vos commandes',
                                      style: GoogleFonts.openSans(
                                        fontSize: 13,
                                        color: const Color(0xFF8936A8),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            const SizedBox(height: 24),

                            // Section: Informations principales
                            Text(
                              'Informations requises',
                              style: GoogleFonts.openSans(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.black87,
                              ),
                            ),

                            const SizedBox(height: 16),

                            // Nom complet
                            _buildTextField(
                              controller: _nameController,
                              label: 'Nom complet',
                              icon: Icons.person_outline,
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Veuillez entrer votre nom complet';
                                }
                                return null;
                              },
                            ),

                            const SizedBox(height: 16),

                            // Téléphone (identifiant principal)
                            _buildTextField(
                              controller: _phoneController,
                              label: 'Téléphone',
                              icon: Icons.phone_outlined,
                              keyboardType: TextInputType.phone,
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Veuillez entrer votre téléphone';
                                }
                                return null;
                              },
                            ),

                            const SizedBox(height: 24),

                            // Section: Informations optionnelles
                            Text(
                              'Informations optionnelles',
                              style: GoogleFonts.openSans(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.black87,
                              ),
                            ),

                            const SizedBox(height: 16),

                            // Email (optionnel)
                            _buildTextField(
                              controller: _emailController,
                              label: 'Email (optionnel)',
                              icon: Icons.email_outlined,
                              keyboardType: TextInputType.emailAddress,
                              validator: (value) {
                                if (value != null && value.isNotEmpty && !value.contains('@')) {
                                  return 'Veuillez entrer un email valide';
                                }
                                return null;
                              },
                            ),

                            const SizedBox(height: 40),

                            // Bouton Enregistrer
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton(
                                onPressed: _isLoading ? null : _saveCustomerInfo,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF8936A8),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 2,
                            shadowColor: const Color(0xFF8936A8).withOpacity(0.4),
                          ),
                          child: Text(
                            'Enregistrer les modifications',
                            style: GoogleFonts.openSans(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
    String? Function(String?)? validator,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        style: GoogleFonts.openSans(
          fontSize: 15,
          color: Colors.black87,
        ),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: GoogleFonts.openSans(
            fontSize: 14,
            color: Colors.grey.shade600,
          ),
          prefixIcon: Icon(
            icon,
            color: const Color(0xFF8936A8),
            size: 22,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          filled: true,
          fillColor: Colors.white,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        ),
        validator: validator,
      ),
    );
  }
}
