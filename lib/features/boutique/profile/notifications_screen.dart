import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../services/notification_service.dart';
import '../../../services/push_notification_service.dart';

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
  bool _isRegistering = false;
  String _registrationStatus = '';

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
              style: GoogleFonts.inriaSerif(fontWeight: FontWeight.w600),
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
          style: GoogleFonts.inriaSerif(fontWeight: FontWeight.bold),
        ),
        content: Text(
          'Voulez-vous désactiver toutes les notifications ?',
          style: GoogleFonts.inriaSerif(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Annuler',
              style: GoogleFonts.inriaSerif(color: Colors.grey),
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
              style: GoogleFonts.inriaSerif(color: Colors.red),
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
                    child: const FaIcon(FontAwesomeIcons.arrowLeft, size: 24),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Text(
                      'Préférences',
                      style: GoogleFonts.inriaSerif(
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
                                  child: const FaIcon(
                                    FontAwesomeIcons.solidBell,
                                    color: Color(0xFF8936A8),
                                    size: 24,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    'Personnalisez vos alertes pour ne recevoir que ce qui vous intéresse',
                                    style: GoogleFonts.inriaSerif(
                                      fontSize: 14,
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
                            style: GoogleFonts.inriaSerif(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Choisissez les notifications que vous souhaitez recevoir',
                            style: GoogleFonts.inriaSerif(
                              fontSize: 14,
                              color: Colors.grey.shade800,
                            ),
                          ),
                          const SizedBox(height: 16),

                          _buildNotificationTypeCard(
                            title: 'Mes commandes',
                            description: 'Suivi de vos commandes, livraisons et confirmations',
                            icon: FontAwesomeIcons.bagShopping,
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
                            icon: FontAwesomeIcons.tag,
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
                            icon: FontAwesomeIcons.star,
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
                            style: GoogleFonts.inriaSerif(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Comment souhaitez-vous être notifié ?',
                            style: GoogleFonts.inriaSerif(
                              fontSize: 14,
                              color: Colors.grey.shade800,
                            ),
                          ),
                          const SizedBox(height: 16),

                          _buildChannelCard(
                            title: 'Notifications push',
                            description: 'Alertes instantanées sur votre appareil',
                            icon: FontAwesomeIcons.bell,
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
                            icon: FontAwesomeIcons.envelope,
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
                              icon: FaIcon(
                                FontAwesomeIcons.bellSlash,
                                color: Colors.grey.shade800,
                              ),
                              label: Text(
                                'Désactiver toutes les notifications',
                                style: GoogleFonts.inriaSerif(
                                  fontSize: 14,
                                  color: Colors.grey.shade800,
                                ),
                              ),
                            ),
                          ),

                          const SizedBox(height: 32),
                          _buildFcmDiagnosticCard(),
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

  Future<void> _testFcmRegistration() async {
    setState(() { _isRegistering = true; _registrationStatus = ''; });
    try {
      await PushNotificationService.registerDeviceToken();
      final token = PushNotificationService.fcmToken;
      setState(() {
        _registrationStatus = token != null
            ? 'Token enregistré avec succès'
            : 'Aucun token FCM disponible';
      });
    } catch (e) {
      setState(() { _registrationStatus = 'Erreur: $e'; });
    } finally {
      setState(() => _isRegistering = false);
    }
  }

  Widget _buildFcmDiagnosticCard() {
    final token = PushNotificationService.fcmToken;
    final shortToken = token != null && token.length > 30
        ? '${token.substring(0, 15)}...${token.substring(token.length - 10)}'
        : (token ?? 'Non disponible');

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.bug_report_outlined, size: 18, color: Colors.grey),
              const SizedBox(width: 8),
              Text(
                'Diagnostic push notifications',
                style: GoogleFonts.inriaSerif(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey.shade900,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Token FCM
          Text('Token FCM :', style: GoogleFonts.inriaSerif(fontSize: 13, color: Colors.grey.shade800)),
          const SizedBox(height: 4),
          Row(
            children: [
              Expanded(
                child: Text(
                  shortToken,
                  style: GoogleFonts.inriaSerif(
                    fontSize: 13,
                    color: token != null ? Colors.green.shade700 : Colors.red.shade400,
                    fontWeight: FontWeight.w600,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (token != null)
                GestureDetector(
                  onTap: () {
                    Clipboard.setData(ClipboardData(text: token));
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Token copié', style: GoogleFonts.inriaSerif()),
                        backgroundColor: Colors.green,
                        duration: const Duration(seconds: 2),
                        behavior: SnackBarBehavior.floating,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                    );
                  },
                  child: const Icon(Icons.copy_outlined, size: 16, color: Colors.grey),
                ),
            ],
          ),

          const SizedBox(height: 12),

          // Bouton re-enregistrer
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _isRegistering ? null : _testFcmRegistration,
              icon: _isRegistering
                  ? const SizedBox(
                      width: 14, height: 14,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : const FaIcon(FontAwesomeIcons.arrowsRotate, size: 16),
              label: Text(
                _isRegistering ? 'Enregistrement...' : 'Re-enregistrer l\'appareil',
                style: GoogleFonts.inriaSerif(fontSize: 14, fontWeight: FontWeight.w600),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF8936A8),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 10),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
          ),

          if (_registrationStatus.isNotEmpty) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(
                  _registrationStatus.contains('succès')
                      ? FontAwesomeIcons.circleCheck
                      : FontAwesomeIcons.circleExclamation,
                  size: 14,
                  color: _registrationStatus.contains('succès') ? Colors.green : Colors.red,
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    _registrationStatus,
                    style: GoogleFonts.inriaSerif(
                      fontSize: 13,
                      color: _registrationStatus.contains('succès')
                          ? Colors.green.shade700
                          : Colors.red.shade400,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
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
                    style: GoogleFonts.inriaSerif(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    description,
                    style: GoogleFonts.inriaSerif(
                      fontSize: 13,
                      color: Colors.grey.shade800,
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
                color: value ? const Color(0xFF8936A8) : Colors.grey.shade900,
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
                          style: GoogleFonts.inriaSerif(
                            fontSize: 14,
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
                            style: GoogleFonts.inriaSerif(
                              fontSize: 12,
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
                    style: GoogleFonts.inriaSerif(
                      fontSize: 13,
                      color: Colors.grey.shade800,
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
