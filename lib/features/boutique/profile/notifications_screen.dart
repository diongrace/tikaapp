import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/services/storage_service.dart';

/// Écran de gestion des notifications - Stockage local
/// Préférences de notifications stockées localement (pas d'API pour les clients)
class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  // Préférences de notifications
  bool _ordersNotifications = true;
  bool _promotionsNotifications = true;
  bool _newsNotifications = false;
  bool _loyaltyNotifications = true;
  bool _emailNotifications = false;
  bool _smsNotifications = false;
  bool _pushNotifications = true;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadPreferences();
  }

  Future<void> _loadPreferences() async {
    setState(() => _isLoading = true);

    try {
      final settings = await StorageService.getNotificationSettings();

      setState(() {
        _ordersNotifications = settings['orders'] ?? true;
        _promotionsNotifications = settings['promotions'] ?? true;
        _newsNotifications = settings['news'] ?? false;
        _loyaltyNotifications = settings['loyalty'] ?? true;
        _emailNotifications = settings['email'] ?? false;
        _smsNotifications = settings['sms'] ?? false;
        _pushNotifications = settings['push'] ?? true;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _savePreferences() async {
    // Sauvegarder les préférences dans le stockage local
    final prefs = {
      'orders': _ordersNotifications,
      'promotions': _promotionsNotifications,
      'news': _newsNotifications,
      'loyalty': _loyaltyNotifications,
      'email': _emailNotifications,
      'sms': _smsNotifications,
      'push': _pushNotifications,
    };

    await StorageService.saveNotificationSettings(prefs);

    // Afficher un message de confirmation
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Préférences de notifications enregistrées',
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
                      'Notifications',
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
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                    // Description
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFF8936A8).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: const Color(0xFF8936A8).withOpacity(0.3),
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.info_outline,
                            color: const Color(0xFF8936A8),
                            size: 24,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'Personnalisez vos alertes pour ne recevoir que ce qui vous intéresse',
                              style: GoogleFonts.openSans(
                                fontSize: 13,
                                color: Colors.grey.shade800,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Types de notifications
                    Text(
                      'Types de notifications',
                      style: GoogleFonts.openSans(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey.shade800,
                      ),
                    ),
                    const SizedBox(height: 12),

                    _buildNotificationCard(
                      title: 'Mes commandes',
                      description: 'Suivi de vos commandes, livraisons et confirmations',
                      icon: Icons.shopping_bag_outlined,
                      iconColor: const Color(0xFF2196F3),
                      value: _ordersNotifications,
                      onChanged: (value) {
                        setState(() {
                          _ordersNotifications = value;
                        });
                        _savePreferences();
                      },
                    ),

                    const SizedBox(height: 12),

                    _buildNotificationCard(
                      title: 'Promotions et offres',
                      description: 'Réductions exclusives et codes promo',
                      icon: Icons.local_offer_outlined,
                      iconColor: const Color(0xFFFF9800),
                      value: _promotionsNotifications,
                      onChanged: (value) {
                        setState(() {
                          _promotionsNotifications = value;
                        });
                        _savePreferences();
                      },
                    ),

                    const SizedBox(height: 12),

                    _buildNotificationCard(
                      title: 'Nouveautés',
                      description: 'Nouveaux produits et services',
                      icon: Icons.stars_outlined,
                      iconColor: const Color(0xFFE91E63),
                      value: _newsNotifications,
                      onChanged: (value) {
                        setState(() {
                          _newsNotifications = value;
                        });
                        _savePreferences();
                      },
                    ),

                    const SizedBox(height: 12),

                    _buildNotificationCard(
                      title: 'Programme fidélité',
                      description: 'Points cumulés, récompenses et avantages',
                      icon: Icons.card_giftcard_outlined,
                      iconColor: const Color(0xFF8936A8),
                      value: _loyaltyNotifications,
                      onChanged: (value) {
                        setState(() {
                          _loyaltyNotifications = value;
                        });
                        _savePreferences();
                      },
                    ),

                    const SizedBox(height: 32),

                    // Canaux de notification
                    Text(
                      'Canaux de notification',
                      style: GoogleFonts.openSans(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey.shade800,
                      ),
                    ),
                    const SizedBox(height: 12),

                    _buildChannelCard(
                      title: 'Notifications push',
                      description: 'Alertes instantanées sur votre appareil',
                      icon: Icons.notifications_active_outlined,
                      value: _pushNotifications,
                      onChanged: (value) {
                        setState(() {
                          _pushNotifications = value;
                        });
                        _savePreferences();
                      },
                    ),

                    const SizedBox(height: 12),

                    _buildChannelCard(
                      title: 'Email',
                      description: 'Recevoir les notifications par email',
                      icon: Icons.email_outlined,
                      value: _emailNotifications,
                      onChanged: (value) {
                        setState(() {
                          _emailNotifications = value;
                        });
                        _savePreferences();
                      },
                    ),

                    const SizedBox(height: 12),

                    _buildChannelCard(
                      title: 'SMS',
                      description: 'Alertes par message texte',
                      icon: Icons.sms_outlined,
                      value: _smsNotifications,
                      onChanged: (value) {
                        setState(() {
                          _smsNotifications = value;
                        });
                        _savePreferences();
                      },
                    ),

                    const SizedBox(height: 32),

                    // Bouton tout désactiver
                    Center(
                      child: TextButton.icon(
                        onPressed: () {
                          setState(() {
                            _ordersNotifications = false;
                            _promotionsNotifications = false;
                            _newsNotifications = false;
                            _loyaltyNotifications = false;
                            _emailNotifications = false;
                            _smsNotifications = false;
                            _pushNotifications = false;
                          });
                          _savePreferences();
                        },
                        icon: Icon(
                          Icons.notifications_off_outlined,
                          color: Colors.grey.shade600,
                        ),
                        label: Text(
                          'Désactiver toutes les notifications',
                          style: GoogleFonts.openSans(
                            fontSize: 14,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ),
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

  // Carte de notification
  Widget _buildNotificationCard({
    required String title,
    required String description,
    required IconData icon,
    required Color iconColor,
    required bool value,
    required ValueChanged<bool> onChanged,
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
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: iconColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: iconColor, size: 24),
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
                    description,
                    style: GoogleFonts.openSans(
                      fontSize: 13,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ),
            Switch(
              value: value,
              onChanged: onChanged,
              activeColor: const Color(0xFF8936A8),
            ),
          ],
        ),
      ),
    );
  }

  // Carte de canal
  Widget _buildChannelCard({
    required String title,
    required String description,
    required IconData icon,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: value ? const Color(0xFF8936A8).withOpacity(0.3) : Colors.grey.shade200,
          width: 2,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(
              icon,
              color: value ? const Color(0xFF8936A8) : Colors.grey.shade400,
              size: 24,
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
                    description,
                    style: GoogleFonts.openSans(
                      fontSize: 13,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ),
            Switch(
              value: value,
              onChanged: onChanged,
              activeColor: const Color(0xFF8936A8),
            ),
          ],
        ),
      ),
    );
  }
}
