import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../services/notification_service.dart';

/// Écran de gestion des préférences de notifications
/// Utilise l'API si authentifié, sinon stockage local
class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  NotificationSettings _settings = NotificationSettings();
  bool _isLoading = true;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    setState(() => _isLoading = true);

    try {
      final settings = await NotificationService.getSettings();
      setState(() {
        _settings = settings;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur lors du chargement: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _saveSettings() async {
    setState(() => _isSaving = true);

    try {
      await NotificationService.updateSettings(_settings);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Préférences enregistrées',
              style: GoogleFonts.openSans(fontWeight: FontWeight.w600),
            ),
            backgroundColor: const Color(0xFF4CAF50),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() => _isSaving = false);
    }
  }

  void _updateSetting(NotificationSettings Function(NotificationSettings) update) {
    setState(() {
      _settings = update(_settings);
    });
    _saveSettings();
  }

  void _disableAll() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Désactiver tout',
          style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
        ),
        content: Text(
          'Voulez-vous désactiver toutes les notifications ?',
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
              setState(() {
                _settings = NotificationSettings(
                  pushEnabled: false,
                  emailEnabled: false,
                  smsEnabled: false,
                  orderUpdates: false,
                  promotions: false,
                  loyaltyUpdates: false,
                );
              });
              _saveSettings();
            },
            child: Text(
              'Désactiver',
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
                      'Préférences',
                      style: GoogleFonts.poppins(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  if (_isSaving)
                    const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Color(0xFF8936A8),
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
                          // Info card
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  const Color(0xFF8936A8).withValues(alpha: 0.1),
                                  const Color(0xFF8936A8).withValues(alpha: 0.05),
                                ],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: const Color(0xFF8936A8).withValues(alpha: 0.2),
                              ),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF8936A8).withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: const Icon(
                                    Icons.notifications_active,
                                    color: Color(0xFF8936A8),
                                    size: 24,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    'Personnalisez vos alertes pour ne recevoir que ce qui vous intéresse',
                                    style: GoogleFonts.openSans(
                                      fontSize: 13,
                                      color: Colors.grey.shade800,
                                      height: 1.4,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 28),

                          // Types de notifications
                          Text(
                            'Types de notifications',
                            style: GoogleFonts.poppins(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Choisissez les notifications que vous souhaitez recevoir',
                            style: GoogleFonts.openSans(
                              fontSize: 13,
                              color: Colors.grey.shade600,
                            ),
                          ),
                          const SizedBox(height: 16),

                          _buildNotificationTypeCard(
                            title: 'Mes commandes',
                            description: 'Suivi de vos commandes, livraisons et confirmations',
                            icon: Icons.shopping_bag_outlined,
                            iconColor: const Color(0xFF2196F3),
                            value: _settings.orderUpdates,
                            onChanged: (value) {
                              _updateSetting((s) => s.copyWith(orderUpdates: value));
                            },
                          ),

                          const SizedBox(height: 12),

                          _buildNotificationTypeCard(
                            title: 'Promotions et offres',
                            description: 'Réductions exclusives et codes promo',
                            icon: Icons.local_offer_outlined,
                            iconColor: const Color(0xFFFF9800),
                            value: _settings.promotions,
                            onChanged: (value) {
                              _updateSetting((s) => s.copyWith(promotions: value));
                            },
                          ),

                          const SizedBox(height: 12),

                          _buildNotificationTypeCard(
                            title: 'Programme fidélité',
                            description: 'Points cumulés, récompenses et avantages',
                            icon: Icons.stars_outlined,
                            iconColor: const Color(0xFF8936A8),
                            value: _settings.loyaltyUpdates,
                            onChanged: (value) {
                              _updateSetting((s) => s.copyWith(loyaltyUpdates: value));
                            },
                          ),

                          const SizedBox(height: 32),

                          // Canaux de notification
                          Text(
                            'Canaux de notification',
                            style: GoogleFonts.poppins(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Comment souhaitez-vous être notifié ?',
                            style: GoogleFonts.openSans(
                              fontSize: 13,
                              color: Colors.grey.shade600,
                            ),
                          ),
                          const SizedBox(height: 16),

                          _buildChannelCard(
                            title: 'Notifications push',
                            description: 'Alertes instantanées sur votre appareil',
                            icon: Icons.notifications_active_outlined,
                            value: _settings.pushEnabled,
                            isPrimary: true,
                            onChanged: (value) {
                              _updateSetting((s) => s.copyWith(pushEnabled: value));
                            },
                          ),

                          const SizedBox(height: 12),

                          _buildChannelCard(
                            title: 'Email',
                            description: 'Recevoir les notifications par email',
                            icon: Icons.email_outlined,
                            value: _settings.emailEnabled,
                            onChanged: (value) {
                              _updateSetting((s) => s.copyWith(emailEnabled: value));
                            },
                          ),

                          const SizedBox(height: 12),

                          _buildChannelCard(
                            title: 'SMS',
                            description: 'Alertes par message texte',
                            icon: Icons.sms_outlined,
                            value: _settings.smsEnabled,
                            onChanged: (value) {
                              _updateSetting((s) => s.copyWith(smsEnabled: value));
                            },
                          ),

                          const SizedBox(height: 32),

                          // Bouton tout désactiver
                          Center(
                            child: TextButton.icon(
                              onPressed: _disableAll,
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

                          const SizedBox(height: 20),
                        ],
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNotificationTypeCard({
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
            color: Colors.black.withValues(alpha: 0.05),
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
                color: iconColor.withValues(alpha: 0.1),
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
                    style: GoogleFonts.poppins(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    description,
                    style: GoogleFonts.openSans(
                      fontSize: 12,
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

  Widget _buildChannelCard({
    required String title,
    required String description,
    required IconData icon,
    required bool value,
    required ValueChanged<bool> onChanged,
    bool isPrimary = false,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: value
              ? const Color(0xFF8936A8).withValues(alpha: 0.3)
              : Colors.grey.shade200,
          width: value ? 2 : 1,
        ),
        boxShadow: value
            ? [
                BoxShadow(
                  color: const Color(0xFF8936A8).withValues(alpha: 0.1),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ]
            : null,
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: value
                    ? const Color(0xFF8936A8).withValues(alpha: 0.1)
                    : Colors.grey.shade100,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                icon,
                color: value ? const Color(0xFF8936A8) : Colors.grey.shade400,
                size: 22,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          title,
                          style: GoogleFonts.poppins(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: Colors.black87,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (isPrimary) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: const Color(0xFF8936A8),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            'Recommandé',
                            style: GoogleFonts.openSans(
                              fontSize: 9,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    description,
                    style: GoogleFonts.openSans(
                      fontSize: 12,
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
