import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../../../services/loyalty_service.dart';
import '../../../services/auth_service.dart';
import '../../../services/models/loyalty_card_model.dart';
import '../../../core/services/boutique_theme_provider.dart';

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
  bool _isDeleting = false;
  Map<String, dynamic> _stats = {};

  Color _primaryColor = const Color(0xFF8936A8);

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _primaryColor = BoutiqueThemeProvider.of(context).primary;
  }

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
      // Charger le QR data et les stats globales en parallele
      Map<String, String> qrInfo = {};
      Map<String, dynamic> stats = {};
      try {
        final results = await Future.wait([
          LoyaltyService.getCardQrCode(_card.id),
          LoyaltyService.getStats(),
        ]);
        qrInfo = results[0] as Map<String, String>;
        stats = results[1] as Map<String, dynamic>;
      } catch (_) {}

      if (mounted) {
        setState(() {
          _card = detail.card;
          _rewards = detail.rewards;
          _recentTransactions = detail.recentTransactions;
          _qrData = qrInfo['qr_data']?.isNotEmpty == true
              ? qrInfo['qr_data']
              : _card.qrCode ?? _card.cardNumber;
          _stats = stats;
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

  /// Supprimer la carte avec confirmation
  Future<void> _deleteCard() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            const Icon(Icons.warning_amber_rounded, color: Color(0xFFEF4444), size: 24),
            const SizedBox(width: 10),
            Text(
              'Supprimer la carte ?',
              style: GoogleFonts.inriaSerif(fontSize: 18, fontWeight: FontWeight.w600),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Vous allez supprimer votre carte de fidélité pour ${_card.shopName}.',
              style: GoogleFonts.inriaSerif(fontSize: 16, color: Colors.black87),
            ),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFFFEF2F2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  const Icon(Icons.info_outline, color: Color(0xFFEF4444), size: 16),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Vos ${_card.points} points seront perdus définitivement.',
                      style: GoogleFonts.inriaSerif(fontSize: 14, color: const Color(0xFFEF4444)),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('Annuler', style: GoogleFonts.inriaSerif(color: Colors.grey.shade600)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFEF4444),
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: Text('Supprimer', style: GoogleFonts.inriaSerif(fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    print('[DELETE] Confirmation reçue pour carte id=${_card.id} shop=${_card.shopName}');
    setState(() => _isDeleting = true);

    try {
      await LoyaltyService.deleteCard(_card.id);
      print('[DELETE] API suppression OK → pop(true)');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Carte supprimée avec succès',
              style: GoogleFonts.inriaSerif(color: Colors.white),
            ),
            backgroundColor: const Color(0xFF10B981),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
        Navigator.of(context).pop(true); // retour avec signal de suppression
      }
    } catch (e) {
      print('[DELETE] Erreur API: $e');
      if (mounted) {
        setState(() => _isDeleting = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              e.toString().replaceAll('Exception: ', ''),
              style: GoogleFonts.inriaSerif(color: Colors.white),
            ),
            backgroundColor: const Color(0xFFEF4444),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
      }
    }
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
      default: return [_primaryColor, _primaryColor.withOpacity(0.6)]; // bronze
    }
  }

  @override
  Widget build(BuildContext context) {
    _primaryColor = BoutiqueThemeProvider.of(context).primary;
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      body: SafeArea(
        child: Column(
          children: [
            // Header premium
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.04),
                    blurRadius: 12,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: _cardGradient,
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: _cardGradient.first.withOpacity(0.38),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 17),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Ma carte de fidélité',
                          style: GoogleFonts.inriaSerif(
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                            color: const Color(0xFF0D0D26),
                            letterSpacing: -0.4,
                          ),
                        ),
                        Text(
                          _card.shopName,
                          style: GoogleFonts.inriaSerif(
                            fontSize: 14,
                            color: Colors.grey[500],
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Badge tier gradient
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: _cardGradient,
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: _cardGradient.first.withOpacity(0.30),
                          blurRadius: 8,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.workspace_premium, color: Colors.white, size: 13),
                        const SizedBox(width: 4),
                        Text(
                          _card.tierLabel,
                          style: GoogleFonts.inriaSerif(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
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

                      // Stats globales (toutes cartes confondues)
                      if (_stats.isNotEmpty) ...[
                        _buildGlobalStats(),
                        const SizedBox(height: 20),
                      ],

                      // Infos de la carte
                      _buildCardInfo(),
                      const SizedBox(height: 20),

                      // Bouton retour boutique (gradient)
                      GestureDetector(
                        onTap: () => Navigator.of(context).pop(),
                        child: Container(
                          width: double.infinity,
                          height: 52,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: _cardGradient,
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(14),
                            boxShadow: [
                              BoxShadow(
                                color: _cardGradient.first.withOpacity(0.38),
                                blurRadius: 14,
                                offset: const Offset(0, 5),
                              ),
                            ],
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.storefront_rounded, size: 18, color: Colors.white),
                              const SizedBox(width: 8),
                              Text(
                                'Retour à la boutique',
                                style: GoogleFonts.inriaSerif(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Bouton supprimer la carte
                      const SizedBox(height: 4),
                      GestureDetector(
                        onTap: _isDeleting ? null : _deleteCard,
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          width: double.infinity,
                          height: 50,
                          decoration: BoxDecoration(
                            color: const Color(0xFFFEF2F2),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: const Color(0xFFEF4444).withOpacity(0.28),
                              width: 1,
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              _isDeleting
                                  ? const SizedBox(
                                      width: 18,
                                      height: 18,
                                      child: CircularProgressIndicator(
                                        color: Color(0xFFEF4444),
                                        strokeWidth: 2,
                                      ),
                                    )
                                  : const Icon(
                                      Icons.delete_outline_rounded,
                                      size: 18,
                                      color: Color(0xFFEF4444),
                                    ),
                              const SizedBox(width: 8),
                              Text(
                                'Supprimer la carte',
                                style: GoogleFonts.inriaSerif(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: const Color(0xFFEF4444),
                                ),
                              ),
                            ],
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
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: _cardGradient,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: _cardGradient.first.withOpacity(0.48),
            blurRadius: 28,
            offset: const Offset(0, 14),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Stack(
          children: [
            // Cercles décoratifs (arrière-plan)
            Positioned(
              right: -50,
              top: -50,
              child: Container(
                width: 200,
                height: 200,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withOpacity(0.07),
                ),
              ),
            ),
            Positioned(
              right: 20,
              bottom: -65,
              child: Container(
                width: 150,
                height: 150,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withOpacity(0.05),
                ),
              ),
            ),
            Positioned(
              left: -35,
              bottom: -25,
              child: Container(
                width: 110,
                height: 110,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withOpacity(0.04),
                ),
              ),
            ),

            // Contenu
            Padding(
              padding: const EdgeInsets.all(24),
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
                            style: GoogleFonts.inriaSerif(
                              fontSize: 26,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                              letterSpacing: -0.5,
                            ),
                          ),
                          Text(
                            'Carte de fidélité',
                            style: GoogleFonts.inriaSerif(
                              fontSize: 13,
                              color: Colors.white.withOpacity(0.78),
                              letterSpacing: 0.4,
                            ),
                          ),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.18),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: Colors.white.withOpacity(0.35), width: 1),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.workspace_premium_rounded, color: Colors.white, size: 14),
                            const SizedBox(width: 5),
                            Text(
                              _card.tierLabel,
                              style: GoogleFonts.inriaSerif(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 28),

                  // Boutique
                  Text(
                    'BOUTIQUE',
                    style: GoogleFonts.inriaSerif(
                      fontSize: 11,
                      color: Colors.white.withOpacity(0.60),
                      letterSpacing: 1.2,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    _card.shopName,
                    style: GoogleFonts.inriaSerif(
                      fontSize: 19,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 22),

                  // Séparateur
                  Divider(color: Colors.white.withOpacity(0.18), height: 1),
                  const SizedBox(height: 18),

                  // Numéro et Points
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'NUMÉRO DE CARTE',
                            style: GoogleFonts.inriaSerif(
                              fontSize: 11,
                              color: Colors.white.withOpacity(0.60),
                              letterSpacing: 1.0,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _card.cardNumber,
                            style: GoogleFonts.robotoMono(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                              letterSpacing: 1.5,
                            ),
                          ),
                        ],
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            'POINTS',
                            style: GoogleFonts.inriaSerif(
                              fontSize: 11,
                              color: Colors.white.withOpacity(0.60),
                              letterSpacing: 1.0,
                            ),
                          ),
                          Text(
                            '${_card.points}',
                            style: GoogleFonts.inriaSerif(
                              fontSize: 42,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                              height: 1.0,
                            ),
                          ),
                          if (_card.pointsValue > 0)
                            Text(
                              '= ${_card.pointsValue} FCFA',
                              style: GoogleFonts.inriaSerif(
                                fontSize: 13,
                                color: Colors.white.withOpacity(0.72),
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
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
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.14),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [color, color.withOpacity(0.68)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: color.withOpacity(0.34),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Icon(icon, color: Colors.white, size: 20),
          ),
          const SizedBox(height: 10),
          Text(
            value,
            style: GoogleFonts.inriaSerif(
              fontSize: 19,
              fontWeight: FontWeight.w800,
              color: const Color(0xFF0D0D26),
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          Text(
            label,
            style: GoogleFonts.inriaSerif(
              fontSize: 13,
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
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: _primaryColor.withOpacity(0.08),
            blurRadius: 18,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // Header avec accent bar
          Row(
            children: [
              Container(
                width: 4,
                height: 22,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: _cardGradient,
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 10),
              Icon(Icons.qr_code_2_rounded, color: _primaryColor, size: 20),
              const SizedBox(width: 8),
              Text(
                'Mon QR Code',
                style: GoogleFonts.inriaSerif(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF1A1A2E),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // QR container avec glow
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: _primaryColor.withOpacity(0.18),
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: _primaryColor.withOpacity(0.12),
                  blurRadius: 24,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: QrImageView(
              data: qrContent,
              version: QrVersions.auto,
              size: 180.0,
              backgroundColor: Colors.white,
            ),
          ),
          const SizedBox(height: 14),
          Text(
            'Scannez ce code en boutique pour cumuler vos points',
            textAlign: TextAlign.center,
            style: GoogleFonts.inriaSerif(
              fontSize: 14,
              color: Colors.grey.shade500,
            ),
          ),
          if (_card.pinCodeHint != null) ...[
            const SizedBox(height: 10),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF8F0),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFFFF9800).withOpacity(0.28), width: 1),
              ),
              child: Row(
                children: [
                  const Icon(Icons.lock_outline_rounded, size: 14, color: Color(0xFFFF9800)),
                  const SizedBox(width: 8),
                  Flexible(
                    child: Text(
                      _card.pinCodeHint!,
                      style: GoogleFonts.inriaSerif(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
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
              Container(
                width: 4,
                height: 22,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFFF9800), Color(0xFFFF6D00)],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 10),
              const Icon(Icons.card_giftcard_rounded, color: Color(0xFFFF9800), size: 18),
              const SizedBox(width: 8),
              Text(
                'Récompenses',
                style: GoogleFonts.inriaSerif(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF1A1A2E),
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
                  style: GoogleFonts.inriaSerif(fontSize: 15, color: Colors.grey[400]),
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
                  style: GoogleFonts.inriaSerif(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF1E1E2E),
                  ),
                ),
                if (reward.description != null)
                  Text(
                    reward.description!,
                    style: GoogleFonts.inriaSerif(fontSize: 13, color: Colors.grey[500]),
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
                  style: GoogleFonts.inriaSerif(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: color,
                  ),
                ),
              ],
            ),
          ),
          Text(
            '${reward.pointsRequired} pts',
            style: GoogleFonts.inriaSerif(
              fontSize: 14,
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
              Container(
                width: 4,
                height: 22,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF2196F3), Color(0xFF1565C0)],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 10),
              const Icon(Icons.history_rounded, color: Color(0xFF2196F3), size: 18),
              const SizedBox(width: 8),
              Text(
                'Historique récent',
                style: GoogleFonts.inriaSerif(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF1A1A2E),
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
                  style: GoogleFonts.inriaSerif(fontSize: 15, color: Colors.grey[400]),
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
                  style: GoogleFonts.inriaSerif(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF1E1E2E),
                  ),
                ),
                if (tx.description != null)
                  Text(
                    tx.description!,
                    style: GoogleFonts.inriaSerif(fontSize: 13, color: Colors.grey[500]),
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
                style: GoogleFonts.inriaSerif(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
              Text(
                tx.createdAtHuman.isNotEmpty ? tx.createdAtHuman : tx.createdAt,
                style: GoogleFonts.inriaSerif(fontSize: 12, color: Colors.grey[400]),
              ),
              if (tx.balanceAfter > 0)
                Text(
                  'Solde: ${tx.balanceAfter} pts',
                  style: GoogleFonts.inriaSerif(fontSize: 12, color: Colors.grey[400]),
                ),
            ],
          ),
        ],
      ),
    );
  }

  // ============================================================
  // STATS GLOBALES
  // ============================================================

  Widget _buildGlobalStats() {
    final totalPoints = _stats['total_points'] ?? _stats['total_points_earned'] ?? 0;
    final totalValue  = _stats['total_value']  ?? _stats['points_value']         ?? 0;
    final cardsCount  = _stats['cards_count']  ?? _stats['total_cards']          ?? 0;

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
              Container(
                width: 4,
                height: 22,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: _cardGradient,
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 10),
              Icon(Icons.bar_chart_rounded, color: _primaryColor, size: 18),
              const SizedBox(width: 8),
              Text(
                'Statistiques globales',
                style: GoogleFonts.inriaSerif(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF1A1A2E),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  icon: Icons.star_rounded,
                  value: '$totalPoints',
                  label: 'Pts totaux',
                  color: _primaryColor,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildStatCard(
                  icon: Icons.monetization_on_rounded,
                  value: '$totalValue F',
                  label: 'Valeur totale',
                  color: const Color(0xFF4CAF50),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildStatCard(
                  icon: Icons.credit_card_rounded,
                  value: '$cardsCount',
                  label: 'Cartes',
                  color: const Color(0xFF2196F3),
                ),
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
              Container(
                width: 4,
                height: 22,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: _cardGradient,
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 10),
              Icon(Icons.info_outline_rounded, color: _primaryColor, size: 18),
              const SizedBox(width: 8),
              Text(
                'Informations',
                style: GoogleFonts.inriaSerif(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF1A1A2E),
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
          style: GoogleFonts.inriaSerif(
            fontSize: 15,
            color: Colors.grey.shade500,
          ),
        ),
        Flexible(
          child: Text(
            value,
            textAlign: TextAlign.right,
            style: GoogleFonts.inriaSerif(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF1E1E2E),
            ),
          ),
        ),
      ],
    );
  }
}
