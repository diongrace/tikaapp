import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../services/auth_service.dart';
import '../../../services/profile_service.dart';

/// Ecran de securite et confidentialite
class SecurityScreen extends StatefulWidget {
  const SecurityScreen({super.key});

  @override
  State<SecurityScreen> createState() => _SecurityScreenState();
}

class _SecurityScreenState extends State<SecurityScreen> {
  bool _biometricEnabled = false;
  bool _twoFactorEnabled = false;
  bool _dataCollectionEnabled = true;
  bool _marketingEnabled = false;

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
                      'Securite et confidentialite',
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
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Section Securite du compte
                    Text(
                      'Securite du compte',
                      style: GoogleFonts.openSans(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey.shade800,
                      ),
                    ),
                    const SizedBox(height: 12),

                    _buildSecurityOption(
                      icon: Icons.lock_outline,
                      title: 'Changer le mot de passe',
                      subtitle: 'Modifiez votre mot de passe actuel',
                      onTap: () => _showChangePasswordDialog(),
                    ),

                    const SizedBox(height: 12),

                    _buildSecurityOption(
                      icon: Icons.fingerprint,
                      title: 'Authentification biometrique',
                      subtitle: 'Empreinte digitale ou Face ID',
                      trailing: Switch(
                        value: _biometricEnabled,
                        onChanged: (value) {
                          setState(() {
                            _biometricEnabled = value;
                          });
                          _showConfirmationSnackBar(
                            value
                              ? 'Authentification biometrique activee'
                              : 'Authentification biometrique desactivee'
                          );
                        },
                        activeColor: const Color(0xFF8936A8),
                      ),
                    ),

                    const SizedBox(height: 12),

                    _buildSecurityOption(
                      icon: Icons.verified_user_outlined,
                      title: 'Authentification a deux facteurs',
                      subtitle: 'Protection supplementaire par SMS',
                      trailing: Switch(
                        value: _twoFactorEnabled,
                        onChanged: (value) {
                          setState(() {
                            _twoFactorEnabled = value;
                          });
                          _showConfirmationSnackBar(
                            value
                              ? 'Authentification 2FA activee'
                              : 'Authentification 2FA desactivee'
                          );
                        },
                        activeColor: const Color(0xFF8936A8),
                      ),
                    ),

                    const SizedBox(height: 12),

                    _buildSecurityOption(
                      icon: Icons.devices_outlined,
                      title: 'Appareils connectes',
                      subtitle: 'Gerer les sessions actives',
                      onTap: () => _showDevicesDialog(),
                    ),

                    const SizedBox(height: 32),

                    // Section Confidentialite
                    Text(
                      'Confidentialite des donnees',
                      style: GoogleFonts.openSans(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey.shade800,
                      ),
                    ),
                    const SizedBox(height: 12),

                    _buildSecurityOption(
                      icon: Icons.analytics_outlined,
                      title: 'Collecte de donnees',
                      subtitle: 'Amelioration de l\'experience utilisateur',
                      trailing: Switch(
                        value: _dataCollectionEnabled,
                        onChanged: (value) {
                          setState(() {
                            _dataCollectionEnabled = value;
                          });
                          _showConfirmationSnackBar(
                            value
                              ? 'Collecte de donnees activee'
                              : 'Collecte de donnees desactivee'
                          );
                        },
                        activeColor: const Color(0xFF8936A8),
                      ),
                    ),

                    const SizedBox(height: 12),

                    _buildSecurityOption(
                      icon: Icons.campaign_outlined,
                      title: 'Utilisation marketing',
                      subtitle: 'Personnalisation des offres',
                      trailing: Switch(
                        value: _marketingEnabled,
                        onChanged: (value) {
                          setState(() {
                            _marketingEnabled = value;
                          });
                          _showConfirmationSnackBar(
                            value
                              ? 'Utilisation marketing activee'
                              : 'Utilisation marketing desactivee'
                          );
                        },
                        activeColor: const Color(0xFF8936A8),
                      ),
                    ),

                    const SizedBox(height: 12),

                    _buildSecurityOption(
                      icon: Icons.description_outlined,
                      title: 'Politique de confidentialite',
                      subtitle: 'Consultez notre politique',
                      onTap: () => _showPrivacyPolicy(),
                    ),

                    const SizedBox(height: 12),

                    _buildSecurityOption(
                      icon: Icons.article_outlined,
                      title: 'Conditions d\'utilisation',
                      subtitle: 'Consultez nos conditions',
                      onTap: () => _showTermsOfService(),
                    ),

                    const SizedBox(height: 32),

                    // Section Actions sur les donnees
                    Text(
                      'Gestion des donnees',
                      style: GoogleFonts.openSans(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey.shade800,
                      ),
                    ),
                    const SizedBox(height: 12),

                    _buildSecurityOption(
                      icon: Icons.download_outlined,
                      title: 'Telecharger mes donnees',
                      subtitle: 'Exportez toutes vos donnees personnelles',
                      iconColor: const Color(0xFF2196F3),
                      onTap: () => _showDownloadDataDialog(),
                    ),

                    const SizedBox(height: 12),

                    _buildSecurityOption(
                      icon: Icons.delete_outline,
                      title: 'Supprimer mon compte',
                      subtitle: 'Action irreversible',
                      iconColor: Colors.red,
                      onTap: () => _showDeleteAccountDialog(),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSecurityOption({
    required IconData icon,
    required String title,
    required String subtitle,
    Color? iconColor,
    Widget? trailing,
    VoidCallback? onTap,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: (iconColor ?? const Color(0xFF8936A8)).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    icon,
                    color: iconColor ?? const Color(0xFF8936A8),
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: GoogleFonts.openSans(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        style: GoogleFonts.openSans(
                          fontSize: 13,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
                if (trailing != null)
                  trailing
                else
                  Icon(
                    Icons.chevron_right,
                    color: Colors.grey.shade400,
                    size: 24,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showChangePasswordDialog() {
    final currentPasswordController = TextEditingController();
    final newPasswordController = TextEditingController();
    final confirmPasswordController = TextEditingController();
    bool obscureCurrent = true;
    bool obscureNew = true;
    bool obscureConfirm = true;
    bool isSubmitting = false;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(
            'Changer le mot de passe',
            style: GoogleFonts.openSans(fontWeight: FontWeight.bold),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: currentPasswordController,
                  obscureText: obscureCurrent,
                  decoration: InputDecoration(
                    labelText: 'Mot de passe actuel',
                    labelStyle: GoogleFonts.openSans(),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    suffixIcon: IconButton(
                      icon: Icon(
                        obscureCurrent ? Icons.visibility_off : Icons.visibility,
                      ),
                      onPressed: () {
                        setDialogState(() {
                          obscureCurrent = !obscureCurrent;
                        });
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: newPasswordController,
                  obscureText: obscureNew,
                  decoration: InputDecoration(
                    labelText: 'Nouveau mot de passe',
                    labelStyle: GoogleFonts.openSans(),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    suffixIcon: IconButton(
                      icon: Icon(
                        obscureNew ? Icons.visibility_off : Icons.visibility,
                      ),
                      onPressed: () {
                        setDialogState(() {
                          obscureNew = !obscureNew;
                        });
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: confirmPasswordController,
                  obscureText: obscureConfirm,
                  decoration: InputDecoration(
                    labelText: 'Confirmer le mot de passe',
                    labelStyle: GoogleFonts.openSans(),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    suffixIcon: IconButton(
                      icon: Icon(
                        obscureConfirm ? Icons.visibility_off : Icons.visibility,
                      ),
                      onPressed: () {
                        setDialogState(() {
                          obscureConfirm = !obscureConfirm;
                        });
                      },
                    ),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: isSubmitting ? null : () => Navigator.pop(context),
              child: Text(
                'Annuler',
                style: GoogleFonts.openSans(color: Colors.grey),
              ),
            ),
            ElevatedButton(
              onPressed: isSubmitting
                  ? null
                  : () async {
                      if (newPasswordController.text != confirmPasswordController.text) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              'Les mots de passe ne correspondent pas',
                              style: GoogleFonts.openSans(),
                            ),
                            backgroundColor: Colors.red,
                          ),
                        );
                        return;
                      }

                      if (newPasswordController.text.length < 6) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              'Le mot de passe doit contenir au moins 6 caracteres',
                              style: GoogleFonts.openSans(),
                            ),
                            backgroundColor: Colors.red,
                          ),
                        );
                        return;
                      }

                      if (AuthService.isAuthenticated) {
                        setDialogState(() => isSubmitting = true);

                        final result = await ProfileService.changePassword(
                          currentPassword: currentPasswordController.text,
                          newPassword: newPasswordController.text,
                          newPasswordConfirmation: confirmPasswordController.text,
                        );

                        if (!context.mounted) return;
                        setDialogState(() => isSubmitting = false);

                        if (result['success'] == true) {
                          Navigator.pop(context);
                          _showConfirmationSnackBar(result['message'] ?? 'Mot de passe modifie');
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                result['message'] ?? 'Erreur',
                                style: GoogleFonts.openSans(),
                              ),
                              backgroundColor: Colors.red,
                            ),
                          );
                        }
                      } else {
                        Navigator.pop(context);
                        _showConfirmationSnackBar('Mot de passe modifie avec succes');
                      }
                    },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF8936A8),
                foregroundColor: Colors.white,
              ),
              child: isSubmitting
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                    )
                  : Text('Confirmer', style: GoogleFonts.openSans()),
            ),
          ],
        ),
      ),
    );
  }

  void _showDevicesDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Appareils connectes',
          style: GoogleFonts.openSans(fontWeight: FontWeight.bold),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildDeviceItem('Cet appareil', '', 'Actif maintenant', true),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Fermer', style: GoogleFonts.openSans()),
          ),
        ],
      ),
    );
  }

  Widget _buildDeviceItem(String device, String location, String lastActive, bool isActive) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          Icon(
            Icons.phone_android,
            color: isActive ? const Color(0xFF8936A8) : Colors.grey,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  device,
                  style: GoogleFonts.openSans(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
                if (location.isNotEmpty)
                  Text(
                    location,
                    style: GoogleFonts.openSans(
                      fontSize: 12,
                      color: Colors.grey.shade600,
                    ),
                  ),
                Text(
                  lastActive,
                  style: GoogleFonts.openSans(
                    fontSize: 11,
                    color: isActive ? Colors.green : Colors.grey,
                  ),
                ),
              ],
            ),
          ),
          if (!isActive)
            IconButton(
              icon: const Icon(Icons.logout, color: Colors.red, size: 20),
              onPressed: () {
                Navigator.pop(context);
                _showConfirmationSnackBar('Session deconnectee');
              },
            ),
        ],
      ),
    );
  }

  void _showPrivacyPolicy() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Politique de confidentialite',
          style: GoogleFonts.openSans(fontWeight: FontWeight.bold),
        ),
        content: SingleChildScrollView(
          child: Text(
            'Notre politique de confidentialite decrit comment nous collectons, utilisons et protegeons vos donnees personnelles.\n\n'
            '1. Collecte des donnees\n'
            '2. Utilisation des donnees\n'
            '3. Protection des donnees\n'
            '4. Vos droits\n'
            '5. Modifications de la politique',
            style: GoogleFonts.openSans(fontSize: 14),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Fermer', style: GoogleFonts.openSans()),
          ),
        ],
      ),
    );
  }

  void _showTermsOfService() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Conditions d\'utilisation',
          style: GoogleFonts.openSans(fontWeight: FontWeight.bold),
        ),
        content: SingleChildScrollView(
          child: Text(
            'En utilisant l\'application Tika, vous acceptez les conditions suivantes :\n\n'
            '1. Utilisation du service\n'
            '2. Compte utilisateur\n'
            '3. Paiements et remboursements\n'
            '4. Propriete intellectuelle\n'
            '5. Limitation de responsabilite',
            style: GoogleFonts.openSans(fontSize: 14),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Fermer', style: GoogleFonts.openSans()),
          ),
        ],
      ),
    );
  }

  void _showDownloadDataDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Telecharger mes donnees',
          style: GoogleFonts.openSans(fontWeight: FontWeight.bold),
        ),
        content: Text(
          'Nous allons preparer une archive de toutes vos donnees personnelles. Vous recevrez un email avec un lien de telechargement dans les 48 heures.',
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
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _showConfirmationSnackBar('Demande envoyee. Vous recevrez un email sous 48h');
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF2196F3),
              foregroundColor: Colors.white,
            ),
            child: Text('Confirmer', style: GoogleFonts.openSans()),
          ),
        ],
      ),
    );
  }

  void _showDeleteAccountDialog() {
    final passwordController = TextEditingController();
    final reasonController = TextEditingController();
    bool obscurePassword = true;
    bool isDeleting = false;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(
            'Supprimer mon compte',
            style: GoogleFonts.openSans(
              fontWeight: FontWeight.bold,
              color: Colors.red,
            ),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.warning_amber_rounded, color: Colors.red, size: 48),
                const SizedBox(height: 16),
                Text(
                  'Cette action est irreversible. Toutes vos donnees seront definitivement supprimees :',
                  style: GoogleFonts.openSans(),
                ),
                const SizedBox(height: 12),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    '- Informations personnelles\n'
                    '- Historique des commandes\n'
                    '- Cartes de fidelite\n'
                    '- Adresses et moyens de paiement',
                    style: GoogleFonts.openSans(fontSize: 13),
                  ),
                ),
                if (AuthService.isAuthenticated) ...[
                  const SizedBox(height: 16),
                  TextField(
                    controller: passwordController,
                    obscureText: obscurePassword,
                    decoration: InputDecoration(
                      labelText: 'Mot de passe',
                      labelStyle: GoogleFonts.openSans(),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      suffixIcon: IconButton(
                        icon: Icon(
                          obscurePassword ? Icons.visibility_off : Icons.visibility,
                        ),
                        onPressed: () {
                          setDialogState(() {
                            obscurePassword = !obscurePassword;
                          });
                        },
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: reasonController,
                    maxLines: 2,
                    decoration: InputDecoration(
                      labelText: 'Raison (optionnel)',
                      labelStyle: GoogleFonts.openSans(),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: isDeleting ? null : () => Navigator.pop(context),
              child: Text(
                'Annuler',
                style: GoogleFonts.openSans(color: Colors.grey),
              ),
            ),
            ElevatedButton(
              onPressed: isDeleting
                  ? null
                  : () async {
                      if (AuthService.isAuthenticated) {
                        if (passwordController.text.isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                'Veuillez entrer votre mot de passe',
                                style: GoogleFonts.openSans(),
                              ),
                              backgroundColor: Colors.red,
                            ),
                          );
                          return;
                        }

                        setDialogState(() => isDeleting = true);

                        final result = await ProfileService.deleteAccount(
                          password: passwordController.text,
                          reason: reasonController.text.isNotEmpty ? reasonController.text : null,
                        );

                        if (!context.mounted) return;
                        setDialogState(() => isDeleting = false);

                        if (result['success'] == true) {
                          await AuthService.logout();
                          if (!context.mounted) return;
                          Navigator.pop(context);
                          _showConfirmationSnackBar('Compte supprime');
                          // Retour a l'ecran principal
                          if (mounted) {
                            Navigator.of(this.context).popUntil((route) => route.isFirst);
                          }
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                result['message'] ?? 'Erreur',
                                style: GoogleFonts.openSans(),
                              ),
                              backgroundColor: Colors.red,
                            ),
                          );
                        }
                      } else {
                        Navigator.pop(context);
                        _showConfirmationSnackBar('Votre demande de suppression a ete enregistree');
                      }
                    },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              child: isDeleting
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                    )
                  : Text('Supprimer', style: GoogleFonts.openSans()),
            ),
          ],
        ),
      ),
    );
  }

  void _showConfirmationSnackBar(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            message,
            style: GoogleFonts.openSans(),
          ),
          backgroundColor: const Color(0xFF4CAF50),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
    }
  }
}
