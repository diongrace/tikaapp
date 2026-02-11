import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../../../services/loyalty_service.dart';
import '../../../services/auth_service.dart';
import '../../../services/models/loyalty_card_model.dart';
import '../home/home_online_screen.dart';

/// Page d'affichage de la carte de fidelite
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
  List<LoyaltyReward> _rewards = [];
  List<LoyaltyTransaction> _recentTransactions = [];
  String? _qrData;
  bool _isLoadingDetail = true;

  static const Color _primaryColor = Color(0xFF8936A8);

  @override
  void initState() {
    super.initState();
    _card = widget.loyaltyCard;
    _loadCardDetail();
  }

  /// Charger le detail complet (carte + recompenses + transactions)
  Future<void> _loadCardDetail() async {
    try {
      final detail = await LoyaltyService.getCardDetail(_card.id);
      // Charger le QR data en parallele
      Map<String, String> qrInfo = {};
      try {
        qrInfo = await LoyaltyService.getCardQrCode(_card.id);
      } catch (_) {}

      if (mounted) {
        setState(() {
          _card = detail.card;
          _rewards = detail.rewards;
          _recentTransactions = detail.recentTransactions;
          _qrData = qrInfo['qr_data']?.isNotEmpty == true
              ? qrInfo['qr_data']
              : _card.qrCode ?? _card.cardNumber;
          _isLoadingDetail = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoadingDetail = false;
          _qrData = _card.qrCode ?? _card.cardNumber;
        });
      }
    }
  }

  /// Rafraichir les donnees
  Future<void> _refreshCard() async {
    setState(() => _isLoadingDetail = true);
    await _loadCardDetail();
  }

  Color get _tierColor {
    switch (_card.tier) {
      case 'silver': return const Color(0xFF9E9E9E);
      case 'gold': return const Color(0xFFFFD700);
      case 'platinum': return const Color(0xFF9C27B0);
      default: return const Color(0xFFCD7F32); // bronze
    }
  }

  List<Color> get _cardGradient {
    switch (_card.tier) {
      case 'silver': return [const Color(0xFF757575), const Color(0xFFBDBDBD)];
      case 'gold': return [const Color(0xFFFF8F00), const Color(0xFFFFD54F)];
      case 'platinum': return [const Color(0xFF6A1B9A), const Color(0xFFCE93D8)];
      default: return [const Color(0xFF8936A8), const Color(0xFFD48EFC)]; // bronze
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
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  IconButton(
                    icon: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: _primaryColor.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.arrow_back_ios_rounded, color: _primaryColor, size: 18),
                    ),
                    onPressed: () => Navigator.pop(context),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Ma carte de fidelite',
                          style: GoogleFonts.poppins(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFF1E1E2E),
                          ),
                        ),
                        Text(
                          _card.shopName,
                          style: GoogleFonts.openSans(
                            fontSize: 12,
                            color: Colors.grey[500],
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Badge tier
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: _tierColor.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.workspace_premium, color: _tierColor, size: 14),
                        const SizedBox(width: 4),
                        Text(
                          _card.tierLabel,
                          style: GoogleFonts.poppins(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: _tierColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Contenu
            Expanded(
              child: RefreshIndicator(
                onRefresh: _refreshCard,
                color: _primaryColor,
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  physics: const AlwaysScrollableScrollPhysics(),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Carte visuelle
                      _buildCardVisual(),
                      const SizedBox(height: 20),

                      // Stats rapides
                      _buildStatsRow(),
                      const SizedBox(height: 20),

                      // QR Code
                      _buildQRCodeSection(),
                      const SizedBox(height: 20),

                      // Recompenses
                      if (_rewards.isNotEmpty || _isLoadingDetail) ...[
                        _buildRewardsSection(),
                        const SizedBox(height: 20),
                      ],

                      // Transactions recentes
                      if (_recentTransactions.isNotEmpty || _isLoadingDetail) ...[
                        _buildTransactionsSection(),
                        const SizedBox(height: 20),
                      ],

                      // Infos de la carte
                      _buildCardInfo(),
                      const SizedBox(height: 20),

                      // Bouton retour boutique
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          onPressed: () {
                            Navigator.of(context).pushReplacement(
                              MaterialPageRoute(
                                builder: (context) => HomeScreen(shopId: _card.shopId),
                              ),
                            );
                          },
                          icon: const Icon(Icons.storefront_rounded, size: 18),
                          label: Text(
                            'Retour a la boutique',
                            style: GoogleFonts.openSans(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            side: BorderSide(color: Colors.grey.shade300),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
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

  // ============================================================
  // CARTE VISUELLE
  // ============================================================

  Widget _buildCardVisual() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: _cardGradient,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: _cardGradient.first.withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Tika',
                    style: GoogleFonts.poppins(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  Text(
                    'Carte de fidelite',
                    style: GoogleFonts.openSans(
                      fontSize: 12,
                      color: Colors.white.withOpacity(0.85),
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.workspace_premium, color: Colors.white, size: 16),
                    const SizedBox(width: 4),
                    Text(
                      _card.tierLabel,
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Boutique
          Text(
            'Boutique',
            style: GoogleFonts.openSans(
              fontSize: 11,
              color: Colors.white.withOpacity(0.7),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            _card.shopName,
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 20),

          // Numero et Points
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Numero de carte',
                    style: GoogleFonts.openSans(
                      fontSize: 10,
                      color: Colors.white.withOpacity(0.7),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    _card.cardNumber,
                    style: GoogleFonts.robotoMono(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                      letterSpacing: 1,
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
                      fontSize: 10,
                      color: Colors.white.withOpacity(0.7),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${_card.points}',
                    style: GoogleFonts.poppins(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ],
          ),

          if (_card.pointsValue > 0) ...[
            const SizedBox(height: 4),
            Align(
              alignment: Alignment.centerRight,
              child: Text(
                '= ${_card.pointsValue} FCFA',
                style: GoogleFonts.openSans(
                  fontSize: 11,
                  color: Colors.white.withOpacity(0.8),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  // ============================================================
  // STATS RAPIDES
  // ============================================================

  Widget _buildStatsRow() {
    return Row(
      children: [
        Expanded(
          child: _buildStatCard(
            icon: Icons.star_rounded,
            value: '${_card.points}',
            label: 'Points',
            color: _primaryColor,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _buildStatCard(
            icon: Icons.monetization_on_rounded,
            value: '${_card.pointsValue} F',
            label: 'Valeur',
            color: const Color(0xFF4CAF50),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _buildStatCard(
            icon: Icons.storefront_rounded,
            value: '${_card.visitsCount}',
            label: 'Visites',
            color: const Color(0xFF2196F3),
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required String value,
    required String label,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.08),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(height: 8),
          Text(
            value,
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF1E1E2E),
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          Text(
            label,
            style: GoogleFonts.openSans(
              fontSize: 11,
              color: Colors.grey[500],
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // QR CODE
  // ============================================================

  Widget _buildQRCodeSection() {
    final qrContent = _qrData ?? _card.qrCode ?? _card.cardNumber;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Icon(Icons.qr_code_rounded, color: _primaryColor, size: 20),
              const SizedBox(width: 8),
              Text(
                'Mon QR Code',
                style: GoogleFonts.poppins(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF1E1E2E),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: BorderRadius.circular(12),
            ),
            child: QrImageView(
              data: qrContent,
              version: QrVersions.auto,
              size: 180.0,
              backgroundColor: Colors.white,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Scannez ce code en boutique pour cumuler vos points',
            textAlign: TextAlign.center,
            style: GoogleFonts.openSans(
              fontSize: 12,
              color: Colors.grey.shade500,
            ),
          ),
          if (_card.pinCodeHint != null) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF3E0),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.lock_outline, size: 14, color: Color(0xFFFF9800)),
                  const SizedBox(width: 6),
                  Flexible(
                    child: Text(
                      _card.pinCodeHint!,
                      style: GoogleFonts.openSans(
                        fontSize: 11,
                        color: const Color(0xFFE65100),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  // ============================================================
  // RECOMPENSES
  // ============================================================

  Widget _buildRewardsSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.card_giftcard_rounded, color: Color(0xFFFF9800), size: 20),
              const SizedBox(width: 8),
              Text(
                'Recompenses',
                style: GoogleFonts.poppins(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF1E1E2E),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          if (_isLoadingDetail)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            )
          else if (_rewards.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  'Aucune recompense disponible pour le moment',
                  style: GoogleFonts.openSans(fontSize: 13, color: Colors.grey[400]),
                ),
              ),
            )
          else
            ..._rewards.map(_buildRewardItem),
        ],
      ),
    );
  }

  Widget _buildRewardItem(LoyaltyReward reward) {
    final color = reward.canClaim ? const Color(0xFF4CAF50) : const Color(0xFFFF9800);
    final icon = _getRewardIcon(reward.rewardType);

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.04),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.15)),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  reward.name,
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF1E1E2E),
                  ),
                ),
                if (reward.description != null)
                  Text(
                    reward.description!,
                    style: GoogleFonts.openSans(fontSize: 11, color: Colors.grey[500]),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                const SizedBox(height: 4),
                // Barre de progression
                if (!reward.canClaim && reward.progressPercent > 0) ...[
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: reward.progressPercent / 100,
                      backgroundColor: Colors.grey.shade200,
                      valueColor: AlwaysStoppedAnimation<Color>(color),
                      minHeight: 4,
                    ),
                  ),
                  const SizedBox(height: 2),
                ],
                Text(
                  reward.canClaim
                      ? 'Disponible !'
                      : 'Encore ${reward.pointsNeeded} points',
                  style: GoogleFonts.openSans(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: color,
                  ),
                ),
              ],
            ),
          ),
          Text(
            '${reward.pointsRequired} pts',
            style: GoogleFonts.poppins(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  IconData _getRewardIcon(String type) {
    switch (type) {
      case 'free_delivery': return Icons.local_shipping_outlined;
      case 'gift_product': return Icons.card_giftcard;
      case 'percent_discount': return Icons.percent;
      case 'fixed_discount': return Icons.money_off;
      default: return Icons.star_outline;
    }
  }

  // ============================================================
  // TRANSACTIONS RECENTES
  // ============================================================

  Widget _buildTransactionsSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.history_rounded, color: Color(0xFF2196F3), size: 20),
              const SizedBox(width: 8),
              Text(
                'Historique recent',
                style: GoogleFonts.poppins(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF1E1E2E),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          if (_isLoadingDetail)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            )
          else if (_recentTransactions.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  'Aucune transaction pour le moment',
                  style: GoogleFonts.openSans(fontSize: 13, color: Colors.grey[400]),
                ),
              ),
            )
          else
            ..._recentTransactions.take(5).map(_buildTransactionItem),
        ],
      ),
    );
  }

  Widget _buildTransactionItem(LoyaltyTransaction tx) {
    final isPositive = tx.isEarned;
    final color = isPositive ? const Color(0xFF4CAF50) : const Color(0xFFE91E63);
    final icon = isPositive ? Icons.add_circle_outline : Icons.remove_circle_outline;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: const Color(0xFFF8F9FA),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  tx.typeLabel.isNotEmpty ? tx.typeLabel : tx.type,
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF1E1E2E),
                  ),
                ),
                if (tx.description != null)
                  Text(
                    tx.description!,
                    style: GoogleFonts.openSans(fontSize: 11, color: Colors.grey[500]),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                tx.pointsDisplay.isNotEmpty ? tx.pointsDisplay : '${isPositive ? "+" : ""}${tx.points}',
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
              Text(
                tx.createdAtHuman.isNotEmpty ? tx.createdAtHuman : tx.createdAt,
                style: GoogleFonts.openSans(fontSize: 10, color: Colors.grey[400]),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ============================================================
  // INFOS DE LA CARTE
  // ============================================================

  Widget _buildCardInfo() {
    final clientName = AuthService.currentClient?.name ?? '';
    final clientPhone = AuthService.currentClient?.phone ?? '';

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.info_outline_rounded, color: _primaryColor, size: 20),
              const SizedBox(width: 8),
              Text(
                'Informations',
                style: GoogleFonts.poppins(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF1E1E2E),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (clientName.isNotEmpty)
            _buildInfoRow('Titulaire', clientName),
          if (clientPhone.isNotEmpty) ...[
            const SizedBox(height: 10),
            _buildInfoRow('Telephone', clientPhone),
          ],
          const SizedBox(height: 10),
          _buildInfoRow('N carte', _card.cardNumber),
          const SizedBox(height: 10),
          _buildInfoRow('Boutique', _card.shopName),
          const SizedBox(height: 10),
          _buildInfoRow('Niveau', _card.tierLabel),
          const SizedBox(height: 10),
          _buildInfoRow('Statut', _card.isActive ? 'Actif' : 'Inactif'),
          if (_card.activatedAt != null) ...[
            const SizedBox(height: 10),
            _buildInfoRow('Active le', _card.activatedAt!),
          ],
          if (_card.lastUsedAt != null) ...[
            const SizedBox(height: 10),
            _buildInfoRow('Derniere utilisation', _card.lastUsedAt!),
          ],
          if (_card.lifetimeSpent > 0) ...[
            const SizedBox(height: 10),
            _buildInfoRow('Total depense', '${_card.lifetimeSpent} FCFA'),
          ],
          const SizedBox(height: 10),
          _buildInfoRow('Valeur du point', '1 pt = ${_card.pointValue} FCFA'),
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
            fontSize: 13,
            color: Colors.grey.shade500,
          ),
        ),
        Flexible(
          child: Text(
            value,
            textAlign: TextAlign.right,
            style: GoogleFonts.openSans(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF1E1E2E),
            ),
          ),
        ),
      ],
    );
  }
}
