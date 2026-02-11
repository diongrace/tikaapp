import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/services/storage_service.dart';
import '../../../services/auth_service.dart';
import '../../../services/profile_service.dart';

/// Ecran des informations personnelles
/// Utilise l'API quand authentifie, stockage local sinon
class PersonalInfoScreen extends StatefulWidget {
  const PersonalInfoScreen({super.key});

  @override
  State<PersonalInfoScreen> createState() => _PersonalInfoScreenState();
}

class _PersonalInfoScreenState extends State<PersonalInfoScreen> {
  final _formKey = GlobalKey<FormState>();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _birthDateController = TextEditingController();
  bool _isLoading = true;
  bool _isSaving = false;
  bool _isAuthenticated = false;

  @override
  void initState() {
    super.initState();
    _loadCustomerInfo();
  }

  Future<void> _loadCustomerInfo() async {
    _isAuthenticated = AuthService.isAuthenticated;

    if (_isAuthenticated) {
      // Charger depuis l'API
      final client = await ProfileService.getProfile();
      if (client != null && mounted) {
        setState(() {
          _firstNameController.text = client.firstName ?? '';
          _lastNameController.text = client.lastName ?? '';
          _phoneController.text = client.phone;
          _emailController.text = client.email ?? '';
          _birthDateController.text = client.birthDate ?? '';
          _isLoading = false;
        });
        return;
      }
      // Fallback sur les donnees locales du client authentifie
      final localClient = AuthService.currentClient;
      if (localClient != null && mounted) {
        setState(() {
          _firstNameController.text = localClient.firstName ?? '';
          _lastNameController.text = localClient.lastName ?? '';
          _phoneController.text = localClient.phone;
          _emailController.text = localClient.email ?? '';
          _birthDateController.text = localClient.birthDate ?? '';
          _isLoading = false;
        });
        return;
      }
    }

    // Mode non authentifie: stockage local
    final customerInfo = await StorageService.getCustomerInfo();
    if (mounted) {
      setState(() {
        final fullName = customerInfo['name'] ?? '';
        final parts = fullName.toString().split(' ');
        _firstNameController.text = parts.isNotEmpty ? parts.first : '';
        _lastNameController.text = parts.length > 1 ? parts.sublist(1).join(' ') : '';
        _phoneController.text = customerInfo['phone'] ?? '';
        _emailController.text = customerInfo['email'] ?? '';
        _isLoading = false;
      });
    }
  }

  Future<void> _saveCustomerInfo() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    try {
      if (_isAuthenticated) {
        // Sauvegarder via l'API
        final updatedClient = await ProfileService.updateProfile(
          firstName: _firstNameController.text.trim(),
          lastName: _lastNameController.text.trim(),
          email: _emailController.text.trim().isNotEmpty
              ? _emailController.text.trim()
              : null,
          birthDate: _birthDateController.text.trim().isNotEmpty
              ? _birthDateController.text.trim()
              : null,
        );

        if (mounted) {
          if (updatedClient != null) {
            _showSnackBar('Informations mises a jour', Colors.green);
            Navigator.pop(context, true);
          } else {
            _showSnackBar('Erreur lors de la mise a jour', Colors.red);
          }
        }
      } else {
        // Sauvegarder localement
        final fullName = '${_firstNameController.text.trim()} ${_lastNameController.text.trim()}'.trim();
        await StorageService.saveCustomerInfo(
          name: fullName,
          phone: _phoneController.text.trim(),
          email: _emailController.text.trim().isNotEmpty ? _emailController.text.trim() : null,
        );

        if (mounted) {
          _showSnackBar('Informations enregistrees', Colors.green);
          Navigator.pop(context, true);
        }
      }
    } catch (e) {
      if (mounted) {
        _showSnackBar('Erreur: $e', Colors.red);
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  void _showSnackBar(String message, Color color) {
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
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _birthDateController.dispose();
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
                                      _isAuthenticated
                                          ? 'Vos informations sont synchronisees avec votre compte'
                                          : 'Vos informations sont stockees localement',
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

                            Text(
                              'Informations requises',
                              style: GoogleFonts.openSans(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.black87,
                              ),
                            ),

                            const SizedBox(height: 16),

                            // Prenom
                            _buildTextField(
                              controller: _firstNameController,
                              label: 'Prenom',
                              icon: Icons.person_outline,
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Veuillez entrer votre prenom';
                                }
                                return null;
                              },
                            ),

                            const SizedBox(height: 16),

                            // Nom
                            _buildTextField(
                              controller: _lastNameController,
                              label: 'Nom',
                              icon: Icons.person_outline,
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Veuillez entrer votre nom';
                                }
                                return null;
                              },
                            ),

                            const SizedBox(height: 16),

                            // Telephone (lecture seule si authentifie)
                            _buildTextField(
                              controller: _phoneController,
                              label: 'Telephone',
                              icon: Icons.phone_outlined,
                              keyboardType: TextInputType.phone,
                              readOnly: _isAuthenticated,
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Veuillez entrer votre telephone';
                                }
                                return null;
                              },
                            ),

                            const SizedBox(height: 24),

                            Text(
                              'Informations optionnelles',
                              style: GoogleFonts.openSans(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.black87,
                              ),
                            ),

                            const SizedBox(height: 16),

                            // Email
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

                            if (_isAuthenticated) ...[
                              const SizedBox(height: 16),

                              // Date de naissance
                              _buildTextField(
                                controller: _birthDateController,
                                label: 'Date de naissance (optionnel)',
                                icon: Icons.cake_outlined,
                                keyboardType: TextInputType.datetime,
                              ),
                            ],

                            const SizedBox(height: 40),

                            // Bouton Enregistrer
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton(
                                onPressed: _isSaving ? null : _saveCustomerInfo,
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
                                child: _isSaving
                                    ? const SizedBox(
                                        width: 24,
                                        height: 24,
                                        child: CircularProgressIndicator(
                                          color: Colors.white,
                                          strokeWidth: 2,
                                        ),
                                      )
                                    : Text(
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
    bool readOnly = false,
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
        readOnly: readOnly,
        style: GoogleFonts.openSans(
          fontSize: 15,
          color: readOnly ? Colors.grey.shade600 : Colors.black87,
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
          suffixIcon: readOnly
              ? Icon(Icons.lock_outline, color: Colors.grey.shade400, size: 18)
              : null,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          filled: true,
          fillColor: readOnly ? Colors.grey.shade50 : Colors.white,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        ),
        validator: validator,
      ),
    );
  }
}
