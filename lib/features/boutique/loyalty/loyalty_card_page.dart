import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../../../core/services/storage_service.dart';
import '../../../services/loyalty_service.dart';
import '../../../services/models/loyalty_card_model.dart';
import '../home/home_online_screen.dart';

/// Page d'affichage de la carte de fidélité
class LoyaltyCardPage extends StatefulWidget {
  final LoyaltyCard loyaltyCard;

  const LoyaltyCardPage({
    super.key,
    required this.loyaltyCard,
  });

  @override
  State<LoyaltyCardPage> createState() => _LoyaltyCardPageState();
}

class _LoyaltyCardPageState extends State<LoyaltyCardPage> {
  late LoyaltyCard _card;
  bool _isRefreshing = false;

  @override
  void initState() {
    super.initState();
    _card = widget.loyaltyCard;
    // Sauvegarder la carte lors de l'affichage
    _saveCard();
  }

  Future<void> _saveCard() async {
    final nameParts = _card.customerName.split(' ');
    await StorageService.saveLoyaltyCard({
      'id': _card.id,
      'cardId': _card.cardNumber,
      'firstName': nameParts.isNotEmpty ? nameParts.first : '',
      'lastName': nameParts.length > 1 ? nameParts.sublist(1).join(' ') : '',
      'birthDate': '', // Not available in API
      'phone': _card.phone,
      'boutiqueName': _card.shopName,
      'points': _card.points,
      'rewards': _card.totalPointsEarned,
    });
  }

  /// Rafraîchir les données de la carte depuis l'API
  Future<void> _refreshCard() async {
    setState(() => _isRefreshing = true);

    try {
      final updatedCard = await LoyaltyService.getCard(
        shopId: _card.shopId,
        phone: _card.phone,
      );

      if (updatedCard != null) {
        setState(() => _card = updatedCard);
        // Mettre à jour le stockage local
        await _saveCard();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur de rafraîchissement: $e'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isRefreshing = false);
      }
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
              child: Text(
                'Ma carte de fidélité',
                style: GoogleFonts.openSans(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),

            // Contenu
            Expanded(
              child: RefreshIndicator(
                onRefresh: _refreshCard,
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  physics: const AlwaysScrollableScrollPhysics(),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                    // Carte de fidélité principale
                    _buildLoyaltyCard(context),
                    const SizedBox(height: 20),

                    // QR Code
                    _buildQRCodeSection(),
                    const SizedBox(height: 20),

                    // Points et récompenses
                    Row(
                      children: [
                        Expanded(
                          child: _buildStatCard(
                            icon: Icons.star_outline,
                            value: _card.points.toString(),
                            label: 'Points\ncumulés',
                            color: const Color(0xFF8936A8),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: _buildStatCard(
                            icon: Icons.card_giftcard,
                            value: _card.totalPointsEarned.toString(),
                            label: 'Points gagnés',
                            color: const Color(0xFFFF9800),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // Informations du titulaire
                    _buildHolderInfo(),
                    const SizedBox(height: 20),

                    // Bouton retour
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton(
                        onPressed: () {
                          // Remplacer la page actuelle par HomeScreen
                          Navigator.of(context).pushReplacement(
                            MaterialPageRoute(
                              builder: (context) => HomeScreen(
                                shopId: _card.shopId,
                              ),
                            ),
                          );
                        },
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          side: BorderSide(color: Colors.grey.shade300),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Text(
                          'Retour à la boutique',
                          style: GoogleFonts.openSans(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.black87,
                          ),
                        ),
                      ),
                    ),
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

  // Carte de fidélité principale
  Widget _buildLoyaltyCard(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF8936A8), Color(0xFFD48EFC)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF8936A8).withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // En-tête avec logo et icône
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Tika',
                    style: GoogleFonts.openSans(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  Text(
                    'Carte de fidélité',
                    style: GoogleFonts.openSans(
                      fontSize: 13,
                      color: Colors.white.withOpacity(0.9),
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.star,
                  color: Colors.white,
                  size: 24,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Titulaire
          Text(
            'Titulaire',
            style: GoogleFonts.openSans(
              fontSize: 12,
              color: Colors.white.withOpacity(0.8),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            _card.customerName,
            style: GoogleFonts.openSans(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 16),

          // Boutique
          Text(
            'Boutique',
            style: GoogleFonts.openSans(
              fontSize: 12,
              color: Colors.white.withOpacity(0.8),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            _card.shopName,
            style: GoogleFonts.openSans(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 24),

          // Numéro de carte et points
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Numéro de carte',
                    style: GoogleFonts.openSans(
                      fontSize: 11,
                      color: Colors.white.withOpacity(0.8),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _card.cardNumber,
                    style: GoogleFonts.openSans(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    'Points',
                    style: GoogleFonts.openSans(
                      fontSize: 11,
                      color: Colors.white.withOpacity(0.8),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _card.points.toString(),
                    style: GoogleFonts.openSans(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  // Section QR Code
  Widget _buildQRCodeSection() {
    return Container(
      padding: const EdgeInsets.all(24),
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
      child: Column(
        children: [
          // QR Code
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: BorderRadius.circular(12),
            ),
            child: QrImageView(
              data: _card.cardNumber,
              version: QrVersions.auto,
              size: 200.0,
              backgroundColor: Colors.white,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Scannez ce code en boutique pour utiliser votre carte',
            textAlign: TextAlign.center,
            style: GoogleFonts.openSans(
              fontSize: 14,
              color: Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
  }

  // Carte de statistique
  Widget _buildStatCard({
    required IconData icon,
    required String value,
    required String label,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
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
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 28),
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: GoogleFonts.openSans(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            textAlign: TextAlign.center,
            style: GoogleFonts.openSans(
              fontSize: 13,
              color: Colors.grey.shade600,
              height: 1.3,
            ),
          ),
        ],
      ),
    );
  }

  // Informations du titulaire
  Widget _buildHolderInfo() {
    return Container(
      padding: const EdgeInsets.all(20),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Informations du titulaire',
            style: GoogleFonts.openSans(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          _buildInfoRow('Nom complet', _card.customerName),
          const SizedBox(height: 12),
          _buildInfoRow('Téléphone', _card.phone),
          if (_card.email != null) ...[
            const SizedBox(height: 12),
            _buildInfoRow('Email', _card.email!),
          ],
          const SizedBox(height: 12),
          _buildInfoRow('ID Carte', _card.cardNumber),
          const SizedBox(height: 12),
          _buildInfoRow('Statut', _card.status == 'active' ? 'Actif' : _card.status),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: GoogleFonts.openSans(
            fontSize: 14,
            color: Colors.grey.shade600,
          ),
        ),
        Flexible(
          child: Text(
            value,
            textAlign: TextAlign.right,
            style: GoogleFonts.openSans(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
        ),
      ],
    );
  }
}
