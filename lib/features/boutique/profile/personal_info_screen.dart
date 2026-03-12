import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/services/storage_service.dart';
import '../../../services/auth_service.dart';
import '../../../services/profile_service.dart';

/// Écran Mon Profil - infos personnelles + changement de mot de passe
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

  final _currentPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _obscureCurrent = true;
  bool _obscureNew = true;
  bool _obscureConfirm = true;

  bool _isLoading = true;
  bool _isSaving = false;
  bool _isAuthenticated = false;

  @override
  void initState() {
    super.initState();
    _loadCustomerInfo();
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _birthDateController.dispose();
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _loadCustomerInfo() async {
    _isAuthenticated = AuthService.isAuthenticated;

    if (_isAuthenticated) {
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

    final info = await StorageService.getCustomerInfo();
    if (mounted) {
      setState(() {
        final parts = (info['name'] ?? '').toString().split(' ');
        _firstNameController.text = parts.isNotEmpty ? parts.first : '';
        _lastNameController.text = parts.length > 1 ? parts.sublist(1).join(' ') : '';
        _phoneController.text = info['phone'] ?? '';
        _emailController.text = info['email'] ?? '';
        _isLoading = false;
      });
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    final hasPassword = _newPasswordController.text.isNotEmpty ||
        _currentPasswordController.text.isNotEmpty;

    if (hasPassword) {
      if (_currentPasswordController.text.isEmpty) {
        _snack('Veuillez entrer votre mot de passe actuel', Colors.red); return;
      }
      if (_newPasswordController.text.length < 6) {
        _snack('Le nouveau mot de passe doit contenir au moins 6 caractères', Colors.red); return;
      }
      if (_newPasswordController.text != _confirmPasswordController.text) {
        _snack('Les mots de passe ne correspondent pas', Colors.red); return;
      }
    }

    setState(() => _isSaving = true);

    try {
      if (_isAuthenticated) {
        final updated = await ProfileService.updateProfile(
          firstName: _firstNameController.text.trim(),
          lastName: _lastNameController.text.trim(),
          email: _emailController.text.trim().isNotEmpty ? _emailController.text.trim() : null,
          birthDate: _birthDateController.text.trim().isNotEmpty ? _birthDateController.text.trim() : null,
        );
        if (updated == null) {
          if (mounted) _snack(ProfileService.lastUpdateError ?? 'Erreur lors de la mise à jour', Colors.red);
          return;
        }
        if (hasPassword) {
          final result = await ProfileService.changePassword(
            currentPassword: _currentPasswordController.text,
            newPassword: _newPasswordController.text,
            newPasswordConfirmation: _confirmPasswordController.text,
          );
          if (mounted) {
            if (result['success'] == true) {
              _currentPasswordController.clear();
              _newPasswordController.clear();
              _confirmPasswordController.clear();
              _snack('Profil et mot de passe mis à jour', Colors.green);
            } else {
              _snack(result['message'] ?? 'Erreur mot de passe', Colors.red);
              return;
            }
          }
        } else {
          if (mounted) _snack('Profil mis à jour', Colors.green);
        }
        if (mounted) Navigator.pop(context, true);
      } else {
        final fullName = '${_firstNameController.text.trim()} ${_lastNameController.text.trim()}'.trim();
        await StorageService.saveCustomerInfo(
          name: fullName,
          phone: _phoneController.text.trim(),
          email: _emailController.text.trim().isNotEmpty ? _emailController.text.trim() : null,
        );
        if (mounted) { _snack('Informations enregistrées', Colors.green); Navigator.pop(context, true); }
      }
    } catch (e) {
      if (mounted) _snack('Erreur: $e', Colors.red);
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  void _snack(String msg, Color color) {
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
                  Text('Mon profil', style: GoogleFonts.inriaSerif(fontSize: 22, fontWeight: FontWeight.bold)),
                ],
              ),
            ),

            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator(color: Color(0xFF8936A8)))
                  : SingleChildScrollView(
                      padding: const EdgeInsets.all(16),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [

                            // Carte infos personnelles
                            _sectionCard(children: [
                              // Prénom + Nom côte à côte
                              Row(
                                children: [
                                  Expanded(child: _field(
                                    label: 'Prénom',
                                    icon: Icons.person_outline,
                                    controller: _firstNameController,
                                    validator: (v) => (v == null || v.isEmpty) ? 'Requis' : null,
                                  )),
                                  const SizedBox(width: 12),
                                  Expanded(child: _field(
                                    label: 'Nom',
                                    icon: Icons.person_outline,
                                    controller: _lastNameController,
                                    validator: (v) => (v == null || v.isEmpty) ? 'Requis' : null,
                                  )),
                                ],
                              ),
                              const SizedBox(height: 16),

                              // Téléphone (non modifiable)
                              _field(
                                label: 'Téléphone',
                                icon: Icons.phone_outlined,
                                controller: _phoneController,
                                readOnly: _isAuthenticated,
                                keyboardType: TextInputType.phone,
                                suffix: _isAuthenticated
                                    ? Icon(Icons.lock_outline, size: 16, color: Colors.grey.shade400)
                                    : null,
                                validator: (v) => (v == null || v.isEmpty) ? 'Requis' : null,
                              ),
                              if (_isAuthenticated) ...[
                                const SizedBox(height: 4),
                                Padding(
                                  padding: const EdgeInsets.only(left: 4),
                                  child: Text(
                                    'Le numéro de téléphone ne peut pas être modifié',
                                    style: GoogleFonts.inriaSerif(fontSize: 13, color: Colors.grey.shade500),
                                  ),
                                ),
                              ],
                              const SizedBox(height: 16),

                              // Email
                              _field(
                                label: 'Email (optionnel)',
                                icon: Icons.email_outlined,
                                controller: _emailController,
                                keyboardType: TextInputType.emailAddress,
                                hint: 'votre@email.com',
                                validator: (v) {
                                  if (v != null && v.isNotEmpty && !v.contains('@')) return 'Email invalide';
                                  return null;
                                },
                              ),

                              if (_isAuthenticated) ...[
                                const SizedBox(height: 16),
                                _field(
                                  label: 'Date de naissance (optionnel)',
                                  icon: Icons.cake_outlined,
                                  controller: _birthDateController,
                                  hint: 'jj/mm/aaaa',
                                  keyboardType: TextInputType.datetime,
                                ),
                              ],
                            ]),

                            // Section mot de passe
                            if (_isAuthenticated) ...[
                              const SizedBox(height: 16),

                              // Séparateur
                              Row(children: [
                                Expanded(child: Divider(color: Colors.grey.shade300)),
                                Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 12),
                                  child: Text(
                                    'Changer le mot de passe',
                                    style: GoogleFonts.inriaSerif(fontSize: 15, color: Colors.grey.shade500),
                                  ),
                                ),
                                Expanded(child: Divider(color: Colors.grey.shade300)),
                              ]),

                              const SizedBox(height: 16),

                              _sectionCard(children: [
                                // Mot de passe actuel (pleine largeur)
                                _passwordField(
                                  label: 'Mot de passe actuel',
                                  hint: 'Votre mot de passe actuel',
                                  controller: _currentPasswordController,
                                  obscure: _obscureCurrent,
                                  onToggle: () => setState(() => _obscureCurrent = !_obscureCurrent),
                                ),
                                const SizedBox(height: 16),

                                // Nouveau + Confirmer côte à côte
                                Row(children: [
                                  Expanded(child: _passwordField(
                                    label: 'Nouveau',
                                    hint: 'Min. 6 car.',
                                    controller: _newPasswordController,
                                    obscure: _obscureNew,
                                    onToggle: () => setState(() => _obscureNew = !_obscureNew),
                                  )),
                                  const SizedBox(width: 12),
                                  Expanded(child: _passwordField(
                                    label: 'Confirmer',
                                    hint: 'Répéter',
                                    controller: _confirmPasswordController,
                                    obscure: _obscureConfirm,
                                    onToggle: () => setState(() => _obscureConfirm = !_obscureConfirm),
                                  )),
                                ]),
                                const SizedBox(height: 12),

                                Row(children: [
                                  Icon(Icons.info_outline, size: 13, color: Colors.grey.shade400),
                                  const SizedBox(width: 6),
                                  Expanded(child: Text(
                                    'Laissez les champs mot de passe vides si vous ne souhaitez pas le modifier.',
                                    style: GoogleFonts.inriaSerif(fontSize: 13, color: Colors.grey.shade500),
                                  )),
                                ]),
                              ]),
                            ],

                            const SizedBox(height: 24),

                            // Boutons
                            Row(children: [
                              Expanded(
                                child: GestureDetector(
                                  onTap: _isSaving ? null : _save,
                                  child: Container(
                                    height: 52,
                                    decoration: BoxDecoration(
                                      gradient: _isSaving ? null : const LinearGradient(
                                        colors: [Color(0xFF8936A8), Color(0xFFE040A0)],
                                        begin: Alignment.centerLeft,
                                        end: Alignment.centerRight,
                                      ),
                                      color: _isSaving ? Colors.grey.shade300 : null,
                                      borderRadius: BorderRadius.circular(14),
                                    ),
                                    child: Center(
                                      child: _isSaving
                                          ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                                          : Row(mainAxisSize: MainAxisSize.min, children: [
                                              const Icon(Icons.save_outlined, color: Colors.white, size: 20),
                                              const SizedBox(width: 8),
                                              Text('Enregistrer', style: GoogleFonts.inriaSerif(fontSize: 17, fontWeight: FontWeight.bold, color: Colors.white)),
                                            ]),
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: OutlinedButton.icon(
                                  onPressed: _isSaving ? null : () => Navigator.pop(context),
                                  icon: const Icon(Icons.close, size: 18),
                                  label: Text('Annuler', style: GoogleFonts.inriaSerif(fontSize: 17, fontWeight: FontWeight.w600)),
                                  style: OutlinedButton.styleFrom(
                                    minimumSize: const Size(0, 52),
                                    foregroundColor: Colors.black87,
                                    side: BorderSide(color: Colors.grey.shade300),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                                  ),
                                ),
                              ),
                            ]),

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

  /// Carte section avec fond blanc et ombre légère
  Widget _sectionCard({required List<Widget> children}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8, offset: const Offset(0, 2)),
        ],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: children),
    );
  }

  /// Champ standard avec label au-dessus
  Widget _field({
    required String label,
    required IconData icon,
    required TextEditingController controller,
    String? hint,
    bool readOnly = false,
    TextInputType keyboardType = TextInputType.text,
    Widget? suffix,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(children: [
          Icon(icon, size: 14, color: const Color(0xFF8936A8)),
          const SizedBox(width: 5),
          Text(label, style: GoogleFonts.inriaSerif(fontSize: 15, fontWeight: FontWeight.w600, color: Colors.black87)),
        ]),
        const SizedBox(height: 6),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          readOnly: readOnly,
          validator: validator,
          style: GoogleFonts.inriaSerif(fontSize: 16, color: readOnly ? Colors.grey.shade600 : Colors.black87),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: GoogleFonts.inriaSerif(fontSize: 16, color: Colors.grey.shade400),
            suffixIcon: suffix,
            filled: true,
            fillColor: readOnly ? Colors.grey.shade50 : const Color(0xFFF8F8F8),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: Colors.grey.shade200)),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: Colors.grey.shade200)),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFF8936A8), width: 1.5)),
            errorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Colors.red)),
            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
          ),
        ),
      ],
    );
  }

  /// Champ mot de passe avec label au-dessus
  Widget _passwordField({
    required String label,
    required String hint,
    required TextEditingController controller,
    required bool obscure,
    required VoidCallback onToggle,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(children: [
          const Icon(Icons.lock_outline, size: 14, color: Color(0xFF8936A8)),
          const SizedBox(width: 5),
          Text(label, style: GoogleFonts.inriaSerif(fontSize: 15, fontWeight: FontWeight.w600, color: Colors.black87)),
        ]),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          obscureText: obscure,
          style: GoogleFonts.inriaSerif(fontSize: 16),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: GoogleFonts.inriaSerif(fontSize: 15, color: Colors.grey.shade400),
            suffixIcon: GestureDetector(
              onTap: onToggle,
              child: Icon(
                obscure ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                size: 18,
                color: Colors.grey.shade400,
              ),
            ),
            filled: true,
            fillColor: const Color(0xFFF8F8F8),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: Colors.grey.shade200)),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: Colors.grey.shade200)),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFF8936A8), width: 1.5)),
            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
          ),
        ),
      ],
    );
  }
}
