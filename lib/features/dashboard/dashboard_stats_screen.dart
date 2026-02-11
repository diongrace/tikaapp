import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../services/dashboard_service.dart';
import '../../services/models/dashboard_model.dart';

/// Ecran des statistiques du dashboard
class DashboardStatsScreen extends StatefulWidget {
  const DashboardStatsScreen({super.key});

  @override
  State<DashboardStatsScreen> createState() => _DashboardStatsScreenState();
}

class _DashboardStatsScreenState extends State<DashboardStatsScreen> {
  static const Color primaryColor = Color(0xFF670C88);
  static const Color accentColor = Color(0xFF8936A8);

  bool _isLoading = true;
  bool _hasError = false;
  String? _errorMessage;
  DashboardStats? _stats;

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  Future<void> _loadStats() async {
    setState(() {
      _isLoading = true;
      _hasError = false;
    });

    try {
      final stats = await DashboardService.getStats();
      setState(() {
        _stats = stats;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _hasError = true;
        _errorMessage = e.toString().replaceAll('Exception: ', '');
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: primaryColor.withOpacity(0.08),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.arrow_back_ios_rounded,
              color: primaryColor,
              size: 18,
            ),
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Statistiques',
              style: GoogleFonts.poppins(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF1E1E2E),
              ),
            ),
            Text(
              'Mon activité',
              style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: FontWeight.w400,
                color: Colors.grey[500],
              ),
            ),
          ],
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(
            height: 1,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.transparent,
                  primaryColor.withOpacity(0.1),
                  primaryColor.withOpacity(0.1),
                  Colors.transparent,
                ],
                stops: const [0.0, 0.2, 0.8, 1.0],
              ),
            ),
          ),
        ),
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: accentColor),
      );
    }

    if (_hasError) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 64, color: Colors.red[300]),
              const SizedBox(height: 16),
              Text(
                _errorMessage ?? 'Une erreur est survenue',
                style: GoogleFonts.inter(fontSize: 14, color: Colors.grey[600]),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _loadStats,
                style: ElevatedButton.styleFrom(backgroundColor: accentColor),
                child: Text('Réessayer',
                    style: GoogleFonts.inter(color: Colors.white)),
              ),
            ],
          ),
        ),
      );
    }

    final stats = _stats!;

    return RefreshIndicator(
      onRefresh: _loadStats,
      color: accentColor,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Carte principale - Total depensé
            _buildMainCard(stats),
            const SizedBox(height: 16),

            // Stats ce mois-ci
            _buildSectionTitle('Ce mois-ci'),
            const SizedBox(height: 12),
            Row(
              children: [
                _buildStatTile(
                  icon: Icons.shopping_bag_rounded,
                  label: 'Commandes',
                  value: '${stats.ordersThisMonth}',
                  color: const Color(0xFF42A5F5),
                ),
                const SizedBox(width: 12),
                _buildStatTile(
                  icon: Icons.payments_rounded,
                  label: 'Dépensé',
                  value: '${stats.spentThisMonth.toInt()} F',
                  color: const Color(0xFF4CAF50),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Stats globales
            _buildSectionTitle('Vue globale'),
            const SizedBox(height: 12),
            Row(
              children: [
                _buildStatTile(
                  icon: Icons.receipt_long_rounded,
                  label: 'Total commandes',
                  value: '${stats.totalOrders}',
                  color: accentColor,
                ),
                const SizedBox(width: 12),
                _buildStatTile(
                  icon: Icons.trending_up_rounded,
                  label: 'Panier moyen',
                  value: '${stats.averageOrderAmount.toInt()} F',
                  color: const Color(0xFFFF9800),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                _buildStatTile(
                  icon: Icons.card_giftcard_rounded,
                  label: 'Points fidélité',
                  value: '${stats.totalLoyaltyPoints}',
                  color: const Color(0xFFE91E63),
                ),
                const SizedBox(width: 12),
                _buildStatTile(
                  icon: Icons.payments_rounded,
                  label: 'Total dépensé',
                  value: '${stats.totalSpent.toInt()} F',
                  color: const Color(0xFF00897B),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Préférences
            if (stats.favoriteShop != null ||
                stats.favoriteCategory != null) ...[
              _buildSectionTitle('Mes préférences'),
              const SizedBox(height: 12),
              if (stats.favoriteShop != null)
                _buildPreferenceCard(
                  icon: Icons.store_rounded,
                  label: 'Boutique préférée',
                  value: stats.favoriteShop!,
                  color: accentColor,
                ),
              if (stats.favoriteCategory != null) ...[
                const SizedBox(height: 10),
                _buildPreferenceCard(
                  icon: Icons.category_rounded,
                  label: 'Catégorie préférée',
                  value: stats.favoriteCategory!,
                  color: const Color(0xFFFF9800),
                ),
              ],
              const SizedBox(height: 24),
            ],

            // Répartition par statut
            if (stats.ordersByStatus.isNotEmpty) ...[
              _buildSectionTitle('Répartition des commandes'),
              const SizedBox(height: 12),
              _buildStatusChart(stats.ordersByStatus),
              const SizedBox(height: 24),
            ],

            // Dépenses par mois
            if (stats.spentByMonth.isNotEmpty) ...[
              _buildSectionTitle('Dépenses mensuelles'),
              const SizedBox(height: 12),
              _buildMonthlyChart(stats.spentByMonth),
            ],

            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildMainCard(DashboardStats stats) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF8936A8), Color(0xFFB932D6)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: accentColor.withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Total dépensé',
            style: GoogleFonts.inter(
              fontSize: 14,
              color: Colors.white.withOpacity(0.8),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '${stats.totalSpent.toInt()} FCFA',
            style: GoogleFonts.poppins(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 16),
          Container(
            height: 1,
            color: Colors.white.withOpacity(0.2),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildMainStatItem(
                  '${stats.totalOrders}', 'Commandes'),
              _buildMainStatItem(
                  '${stats.averageOrderAmount.toInt()} F', 'Panier moyen'),
              _buildMainStatItem(
                  '${stats.totalLoyaltyPoints}', 'Points'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMainStatItem(String value, String label) {
    return Column(
      children: [
        Text(
          value,
          style: GoogleFonts.poppins(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 11,
            color: Colors.white.withOpacity(0.7),
          ),
        ),
      ],
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: GoogleFonts.poppins(
        fontSize: 18,
        fontWeight: FontWeight.w600,
        color: const Color(0xFF1E1E2E),
      ),
    );
  }

  Widget _buildStatTile({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.08),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: color, size: 18),
            ),
            const SizedBox(height: 12),
            Text(
              value,
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF1E1E2E),
              ),
            ),
            Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 12,
                color: Colors.grey[500],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPreferenceCard({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: primaryColor.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
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
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: GoogleFonts.inter(
                      fontSize: 12, color: Colors.grey[500]),
                ),
                Text(
                  value,
                  style: GoogleFonts.poppins(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF1E1E2E),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusChart(Map<String, int> ordersByStatus) {
    final total =
        ordersByStatus.values.fold<int>(0, (sum, val) => sum + val);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: primaryColor.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        children: ordersByStatus.entries.map((entry) {
          final percentage = total > 0 ? entry.value / total : 0.0;
          final color = _getStatusColor(entry.key);
          final label = _getStatusLabel(entry.key);

          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Row(
              children: [
                SizedBox(
                  width: 100,
                  child: Text(
                    label,
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: Colors.grey[700],
                    ),
                  ),
                ),
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: percentage,
                      backgroundColor: Colors.grey[200],
                      valueColor: AlwaysStoppedAnimation<Color>(color),
                      minHeight: 8,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                SizedBox(
                  width: 30,
                  child: Text(
                    '${entry.value}',
                    style: GoogleFonts.poppins(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF374151),
                    ),
                    textAlign: TextAlign.right,
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildMonthlyChart(Map<String, double> spentByMonth) {
    final maxSpent = spentByMonth.values
        .fold<double>(0.0, (max, val) => val > max ? val : max);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: primaryColor.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        children: [
          SizedBox(
            height: 160,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: spentByMonth.entries.map((entry) {
                final height =
                    maxSpent > 0 ? (entry.value / maxSpent) * 130 : 0.0;

                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Text(
                          '${entry.value.toInt()}',
                          style: GoogleFonts.inter(
                            fontSize: 9,
                            fontWeight: FontWeight.w600,
                            color: Colors.grey[600],
                          ),
                        ),
                        const SizedBox(height: 4),
                        Container(
                          height: height.clamp(4.0, 130.0),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [
                                Color(0xFF8936A8),
                                Color(0xFFB932D6),
                              ],
                              begin: Alignment.bottomCenter,
                              end: Alignment.topCenter,
                            ),
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          _formatMonthLabel(entry.key),
                          style: GoogleFonts.inter(
                            fontSize: 10,
                            color: Colors.grey[500],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  String _formatMonthLabel(String monthKey) {
    final months = {
      '01': 'Jan',
      '02': 'Fév',
      '03': 'Mar',
      '04': 'Avr',
      '05': 'Mai',
      '06': 'Jun',
      '07': 'Jul',
      '08': 'Aoû',
      '09': 'Sep',
      '10': 'Oct',
      '11': 'Nov',
      '12': 'Déc',
    };
    // Format: "2024-01" ou "01"
    final parts = monthKey.split('-');
    final month = parts.length > 1 ? parts[1] : monthKey;
    return months[month] ?? monthKey;
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'reçue':
        return const Color(0xFFFFA726);
      case 'en_traitement':
        return const Color(0xFF42A5F5);
      case 'prête':
        return const Color(0xFF9C27B0);
      case 'en_livraison':
        return const Color(0xFFFF9800);
      case 'livrée':
        return const Color(0xFF4CAF50);
      case 'annulée':
        return const Color(0xFFE91E63);
      default:
        return Colors.grey;
    }
  }

  String _getStatusLabel(String status) {
    switch (status) {
      case 'reçue':
        return 'Reçue';
      case 'en_traitement':
        return 'En préparation';
      case 'prête':
        return 'Prête';
      case 'en_livraison':
        return 'En livraison';
      case 'livrée':
        return 'Livrée';
      case 'annulée':
        return 'Annulée';
      default:
        return status;
    }
  }
}
