import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../services/loyalty_service.dart';
import '../../../services/models/loyalty_card_model.dart';

/// Historique complet des transactions d'une carte de fidelite
/// Utilise GET /client/loyalty/cards/{id}/history avec filtres et pagination
class LoyaltyHistoryScreen extends StatefulWidget {
  final LoyaltyCard card;

  const LoyaltyHistoryScreen({super.key, required this.card});

  static Future<void> show(BuildContext context, {required LoyaltyCard card}) {
    return Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => LoyaltyHistoryScreen(card: card)),
    );
  }

  @override
  State<LoyaltyHistoryScreen> createState() => _LoyaltyHistoryScreenState();
}

class _LoyaltyHistoryScreenState extends State<LoyaltyHistoryScreen> {
  String _filter = 'all';
  List<LoyaltyTransaction> _transactions = [];
  bool _isLoading = true;
  bool _isLoadingMore = false;
  bool _hasMore = true;
  int _currentPage = 1;
  int _totalTransactions = 0;

  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _loadHistory();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      if (!_isLoadingMore && _hasMore) _loadMore();
    }
  }

  Future<void> _loadHistory({bool reset = false}) async {
    if (reset) {
      setState(() {
        _transactions = [];
        _currentPage = 1;
        _hasMore = true;
        _isLoading = true;
      });
    }
    try {
      final result = await LoyaltyService.getCardHistoryPaginated(
        widget.card.id,
        type: _filter,
        page: _currentPage,
        perPage: 20,
      );
      if (mounted) {
        setState(() {
          _transactions = [..._transactions, ...result['transactions']];
          _totalTransactions = result['total'] ?? 0;
          _hasMore = _currentPage < (result['last_page'] ?? 1);
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _loadMore() async {
    setState(() { _isLoadingMore = true; _currentPage++; });
    await _loadHistory();
    if (mounted) setState(() => _isLoadingMore = false);
  }

  void _setFilter(String filter) {
    if (_filter == filter) return;
    setState(() => _filter = filter);
    _loadHistory(reset: true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F2F5),
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) => [
          SliverAppBar(
            backgroundColor: const Color(0xFF8936A8),
            foregroundColor: Colors.white,
            elevation: 0,
            pinned: true,
            expandedHeight: 130,
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFF8936A8), Color(0xFF6A1B9A)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 50, 16, 12),
                    child: Row(
                      children: [
                        // Icône points
                        Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: const Center(
                            child: FaIcon(FontAwesomeIcons.clockRotateLeft,
                                size: 20, color: Colors.white),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                'Historique des points',
                                style: GoogleFonts.inriaSerif(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white,
                                ),
                              ),
                              Text(
                                widget.card.shopName,
                                style: GoogleFonts.inriaSerif(
                                    fontSize: 12, color: Colors.white70),
                              ),
                            ],
                          ),
                        ),
                        // Badge points
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 8),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                                color: Colors.white.withOpacity(0.4)),
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                '${widget.card.points}',
                                style: GoogleFonts.inriaSerif(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white,
                                ),
                              ),
                              Text(
                                'points',
                                style: GoogleFonts.inriaSerif(
                                    fontSize: 10, color: Colors.white70),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(48),
              child: _buildFilters(),
            ),
          ),
        ],
        body: Column(
          children: [
            // Barre résumé
            if (!_isLoading)
              _buildSummaryBar(),

            // Liste transactions
            Expanded(
              child: _isLoading
                  ? const Center(
                      child: CircularProgressIndicator(
                          color: Color(0xFF8936A8)))
                  : _transactions.isEmpty
                      ? _buildEmpty()
                      : RefreshIndicator(
                          color: const Color(0xFF8936A8),
                          onRefresh: () => _loadHistory(reset: true),
                          child: ListView.builder(
                            controller: _scrollController,
                            padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                            itemCount: _transactions.length +
                                (_isLoadingMore ? 1 : 0),
                            itemBuilder: (context, index) {
                              if (index == _transactions.length) {
                                return const Center(
                                  child: Padding(
                                    padding: EdgeInsets.all(16),
                                    child: CircularProgressIndicator(
                                        strokeWidth: 2),
                                  ),
                                );
                              }
                              return _buildTransactionItem(
                                  _transactions[index]);
                            },
                          ),
                        ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilters() {
    return Container(
      color: const Color(0xFF8936A8),
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
      child: Row(
        children: [
          _filterChip('Tout', 'all', FontAwesomeIcons.listUl),
          const SizedBox(width: 8),
          _filterChip('Points gagnés', 'earned', FontAwesomeIcons.circlePlus),
          const SizedBox(width: 8),
          _filterChip('Points utilisés', 'redeemed', FontAwesomeIcons.circleMinus),
        ],
      ),
    );
  }

  Widget _filterChip(String label, String value, IconData icon) {
    final isActive = _filter == value;
    return GestureDetector(
      onTap: () => _setFilter(value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: isActive ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isActive ? Colors.white : Colors.white.withOpacity(0.5),
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            FaIcon(icon,
                size: 10,
                color: isActive ? const Color(0xFF8936A8) : Colors.white),
            const SizedBox(width: 5),
            Text(
              label,
              style: GoogleFonts.inriaSerif(
                fontSize: 11,
                fontWeight: isActive ? FontWeight.w700 : FontWeight.w400,
                color: isActive ? const Color(0xFF8936A8) : Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryBar() {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 6,
              offset: const Offset(0, 2)),
        ],
      ),
      child: Row(
        children: [
          const FaIcon(FontAwesomeIcons.rectangleList,
              size: 14, color: Color(0xFF8936A8)),
          const SizedBox(width: 8),
          Text(
            '$_totalTransactions transaction${_totalTransactions > 1 ? 's' : ''}',
            style: GoogleFonts.inriaSerif(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF1A1A2E),
            ),
          ),
          const Spacer(),
          if (_filter != 'all')
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: const Color(0xFF8936A8).withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                _filter == 'earned' ? 'Points gagnés' : 'Points utilisés',
                style: GoogleFonts.inriaSerif(
                  fontSize: 11,
                  color: const Color(0xFF8936A8),
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildEmpty() {
    String title;
    String subtitle;
    IconData icon;

    switch (_filter) {
      case 'earned':
        title = 'Aucun point gagné';
        subtitle = 'Passez une commande pour commencer\nà accumuler des points';
        icon = FontAwesomeIcons.circlePlus;
        break;
      case 'redeemed':
        title = 'Aucun point utilisé';
        subtitle = 'Vos points utilisés apparaîtront ici';
        icon = FontAwesomeIcons.circleMinus;
        break;
      default:
        title = 'Aucune transaction';
        subtitle = 'Passez votre première commande chez\n${widget.card.shopName} pour gagner des points';
        icon = FontAwesomeIcons.clockRotateLeft;
    }

    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      child: SizedBox(
        height: MediaQuery.of(context).size.height * 0.5,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: const Color(0xFF8936A8).withOpacity(0.08),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: FaIcon(icon, size: 32, color: const Color(0xFF8936A8).withOpacity(0.4)),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              title,
              style: GoogleFonts.inriaSerif(
                fontSize: 17,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF1A1A2E),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: GoogleFonts.inriaSerif(
                  fontSize: 13, color: Colors.grey[500], height: 1.5),
            ),
            const SizedBox(height: 24),
            // Conseil
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 32),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                    color: const Color(0xFF8936A8).withOpacity(0.2)),
              ),
              child: Row(
                children: [
                  FaIcon(FontAwesomeIcons.lightbulb,
                      size: 14, color: const Color(0xFF8936A8)),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Scannez votre QR code en boutique pour cumuler des points',
                      style: GoogleFonts.inriaSerif(
                          fontSize: 12, color: Colors.grey[600]),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTransactionItem(LoyaltyTransaction tx) {
    final isPositive = tx.isEarned;
    final color = isPositive ? const Color(0xFF4CAF50) : const Color(0xFFE91E63);
    final icon = isPositive ? FontAwesomeIcons.circlePlus : FontAwesomeIcons.circleMinus;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 6,
              offset: const Offset(0, 2)),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(child: FaIcon(icon, size: 18, color: color)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  tx.typeLabel.isNotEmpty
                      ? tx.typeLabel
                      : (isPositive ? 'Points gagnés' : 'Points utilisés'),
                  style: GoogleFonts.inriaSerif(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF1A1A2E),
                  ),
                ),
                if (tx.description != null && tx.description!.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    tx.description!,
                    style: GoogleFonts.inriaSerif(
                        fontSize: 12, color: Colors.grey[600]),
                  ),
                ],
                const SizedBox(height: 3),
                Row(
                  children: [
                    const Icon(Icons.access_time_rounded,
                        size: 11, color: Colors.grey),
                    const SizedBox(width: 3),
                    Text(
                      tx.createdAtHuman.isNotEmpty
                          ? tx.createdAtHuman
                          : tx.createdAt,
                      style: GoogleFonts.inriaSerif(
                          fontSize: 11, color: Colors.grey[400]),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  tx.pointsDisplay.isNotEmpty
                      ? tx.pointsDisplay
                      : '${isPositive ? '+' : ''}${tx.points}',
                  style: GoogleFonts.inriaSerif(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: color,
                  ),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Solde: ${tx.balanceAfter} pts',
                style: GoogleFonts.inriaSerif(
                    fontSize: 10, color: Colors.grey[400]),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
