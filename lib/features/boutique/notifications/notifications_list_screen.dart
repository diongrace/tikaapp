import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../services/notification_service.dart';

/// Écran de la liste des notifications — Design premium
class NotificationsListScreen extends StatefulWidget {
  const NotificationsListScreen({super.key});

  @override
  State<NotificationsListScreen> createState() => _NotificationsListScreenState();
}

class _NotificationsListScreenState extends State<NotificationsListScreen> {
  List<NotificationItem> _allNotifications = [];
  List<NotificationItem> _notifications = [];
  bool _isLoading = true;
  String? _errorMessage;
  int _unreadCount = 0;
  String _selectedFilter = 'all';

  final List<Map<String, dynamic>> _filters = [
    {'id': 'all',     'label': 'Tout',      'icon': Icons.all_inbox_rounded},
    {'id': 'order',   'label': 'Commandes', 'icon': Icons.shopping_bag_rounded},
    {'id': 'payment', 'label': 'Paiements', 'icon': Icons.payment_rounded},
    {'id': 'loyalty', 'label': 'Fidélité',  'icon': Icons.stars_rounded},
    {'id': 'promo',   'label': 'Promos',    'icon': Icons.local_offer_rounded},
  ];

  static const _purple = Color.fromARGB(255, 151, 24, 210);
  static const _purpleLight = Color(0xFFAB47BC);

  // ── Lifecycle ─────────────────────────────────────────────────────────────

  @override
  void initState() {
    super.initState();
    _loadNotifications();
  }

  // ── Data ──────────────────────────────────────────────────────────────────

  Future<void> _loadNotifications() async {
    if (!mounted) return;
    setState(() { _isLoading = true; _errorMessage = null; });

    try {
      final response = await NotificationService.getNotifications(status: 'all');
      final unreadCount = await NotificationService.getUnreadCount();
      if (!mounted) return;

      // Debug: types
      for (final n in response.notifications) {
        print('[Notif] id=${n.id} type="${n.type}" -> ${_detectNotificationType(n)}');
      }

      // Dédupliquer
      final seen = <String>{};
      final dedup = <NotificationItem>[];
      for (final n in response.notifications) {
        final key = '${n.title}|${n.message}|${n.createdAt}';
        if (seen.add(key)) dedup.add(n);
      }

      setState(() {
        _allNotifications = dedup;
        _notifications = _filterNotifications(_allNotifications, _selectedFilter);
        _unreadCount = unreadCount;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = 'Erreur lors du chargement des notifications';
        _isLoading = false;
      });
    }
  }

  List<NotificationItem> _filterNotifications(List<NotificationItem> all, String filter) {
    if (filter == 'all') return all;
    return all.where((n) => _detectNotificationType(n) == filter).toList();
  }

  String _detectNotificationType(NotificationItem n) {
    final type = n.type.toLowerCase();
    if (type == 'wave_payment' || type == 'payment') return 'payment';
    if (type == 'loyalty') return 'loyalty';
    if (type == 'promo' || type == 'promotion') return 'promo';
    if (type == 'delivery') return 'order';

    final content = '${n.title} ${n.message}'.toLowerCase();
    if (content.contains('paiement') || content.contains('payment') ||
        content.contains('wave') || content.contains('payé') ||
        content.contains('remboursement') || content.contains('reçu')) return 'payment';
    if (content.contains('fidélité') || content.contains('loyalty') ||
        content.contains('points') || content.contains('récompense')) return 'loyalty';
    if (content.contains('promo') || content.contains('réduction') ||
        content.contains('offre') || content.contains('solde')) return 'promo';
    if (content.contains('commande') || content.contains('order') ||
        content.contains('#tk') || content.contains('prête') ||
        content.contains('livrée') || content.contains('confirmée') ||
        content.contains('en préparation') || content.contains('en cours de livraison')) return 'order';
    return 'other';
  }

  Future<void> _markAsRead(int id) async {
    try {
      await NotificationService.markAsRead(id);
      await _loadNotifications();
    } catch (e) {
      if (mounted) _showError(e.toString());
    }
  }

  Future<void> _markAllAsRead() async {
    try {
      await NotificationService.markAllAsRead();
      await _loadNotifications();
      if (mounted) _showSnack('Toutes les notifications marquées comme lues', _purple);
    } catch (e) {
      if (mounted) _showError(e.toString());
    }
  }

  Future<void> _deleteNotification(int id) async {

    try {
      await NotificationService.deleteNotification(id);
      await _loadNotifications();
      if (mounted) _showSnack('Notification supprimée', Colors.grey.shade900);
    } catch (e) {
      if (mounted) _showError(e.toString());
    }
  }

  void _showSnack(String msg, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg, style: GoogleFonts.inriaSerif()),
      backgroundColor: color,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ));
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text('Erreur : $msg'),
      backgroundColor: Colors.red,
    ));
  }

  // ── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF2F2F8),
      body: Column(
        children: [
          _buildHeader(),
          _buildTabChips(),
          Expanded(child: _buildContent()),
        ],
      ),
    );
  }

  // ── Header gradient ────────────────────────────────────────────────────────

  Widget _buildHeader() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF4A0072), _purple],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
          child: Row(
            children: [
              // Bouton retour glass
              GestureDetector(
                onTap: () => Navigator.pop(context),
                child: _glassContainer(
                  child: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 18),
                ),
              ),
              const SizedBox(width: 14),

              // Titre + compteur
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Notifications',
                      style: GoogleFonts.inriaSerif(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                        letterSpacing: -0.3,
                      ),
                    ),
                    if (_unreadCount > 0) ...[
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          Container(
                            width: 7, height: 7,
                            decoration: const BoxDecoration(
                              color: Color(0xFFFFD54F),
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            '$_unreadCount non lue${_unreadCount > 1 ? 's' : ''}',
                            style: GoogleFonts.inriaSerif(
                              fontSize: 13,
                              color: Colors.white.withOpacity(0.80),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),

              // Menu actions
              if (_notifications.isNotEmpty && _unreadCount > 0)
                PopupMenuButton<String>(
                  onSelected: (value) {
                    if (value == 'mark_all') _markAllAsRead();
                  },
                  itemBuilder: (ctx) => [
                    PopupMenuItem(
                      value: 'mark_all',
                      child: Row(children: [
                        const Icon(Icons.done_all_rounded, size: 20, color: _purple),
                        const SizedBox(width: 12),
                        Text('Tout marquer comme lu', style: GoogleFonts.inriaSerif(fontSize: 14)),
                      ]),
                    ),
                  ],
                  child: _glassContainer(
                    child: const Icon(Icons.more_vert_rounded, color: Colors.white, size: 20),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _glassContainer({required Widget child}) => Container(
    width: 40,
    height: 40,
    decoration: BoxDecoration(
      color: Colors.white.withOpacity(0.18),
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: Colors.white.withOpacity(0.45), width: 1.5),
    ),
    child: Center(child: child),
  );

  // ── Chips filtres ──────────────────────────────────────────────────────────

  Widget _buildTabChips() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: SizedBox(
        height: 36,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          itemCount: _filters.length,
          separatorBuilder: (_, __) => const SizedBox(width: 8),
          itemBuilder: (context, i) {
            final filter = _filters[i];
            final isSelected = _selectedFilter == filter['id'];
            return GestureDetector(
              onTap: () => setState(() {
                _selectedFilter = filter['id'];
                _notifications = _filterNotifications(_allNotifications, _selectedFilter);
              }),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 220),
                curve: Curves.easeInOut,
                padding: const EdgeInsets.symmetric(horizontal: 14),
                decoration: BoxDecoration(
                  gradient: isSelected
                      ? const LinearGradient(
                          colors: [Color(0xFF4A0072), _purpleLight],
                          begin: Alignment.centerLeft,
                          end: Alignment.centerRight,
                        )
                      : null,
                  color: isSelected ? null : const Color(0xFFF2F2F8),
                  borderRadius: BorderRadius.circular(18),
                  boxShadow: isSelected
                      ? [BoxShadow(
                          color: _purple.withOpacity(0.38),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        )]
                      : [],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      filter['icon'],
                      size: 14,
                      color: isSelected ? Colors.white : Colors.grey.shade800,
                    ),
                    const SizedBox(width: 5),
                    Text(
                      filter['label'],
                      style: GoogleFonts.inriaSerif(
                        fontSize: 13,
                        fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                        color: isSelected ? Colors.white : Colors.grey.shade800,
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  // ── Contenu ────────────────────────────────────────────────────────────────

  Widget _buildContent() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator(color: _purple));
    }
    if (_errorMessage != null) return _buildErrorState(_errorMessage!);
    if (_notifications.isEmpty) return _buildEmptyState();

    return RefreshIndicator(
      onRefresh: _loadNotifications,
      color: _purple,
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
        itemCount: _notifications.length,
        itemBuilder: (context, index) =>
            _buildNotificationCard(_notifications[index]),
      ),
    );
  }

  // ── Carte notification premium ─────────────────────────────────────────────

  Widget _buildNotificationCard(NotificationItem notification) {
    final isRead = notification.isRead;
    final detectedType = _detectNotificationType(notification);
    final iconData = _getIconForType(detectedType);
    final color = _getColorForType(detectedType);

    return Dismissible(
      key: Key(notification.id.toString()),
      direction: DismissDirection.endToStart,
      onDismissed: (_) => _deleteNotification(notification.id),
      background: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFFFF5252), Color(0xFFE53935)],
          ),
          borderRadius: BorderRadius.circular(16),
        ),
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.delete_rounded, color: Colors.white, size: 26),
            const SizedBox(height: 3),
            Text(
              'Supprimer',
              style: GoogleFonts.inriaSerif(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
      child: GestureDetector(
        onTap: () {
          if (!isRead) _markAsRead(notification.id);
        },
        child: Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(isRead ? 0.04 : 0.07),
                blurRadius: isRead ? 8 : 14,
                offset: const Offset(0, 3),
              ),
              if (!isRead)
                BoxShadow(
                  color: color.withOpacity(0.08),
                  blurRadius: 12,
                  offset: const Offset(0, 5),
                ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // ── Barre latérale colorée ──
                  Container(
                    width: 4,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [color, color.withOpacity(0.35)],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                    ),
                  ),

                  // ── Contenu ──
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Icône gradient
                          Container(
                            width: 46,
                            height: 46,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [color, color.withOpacity(0.68)],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius: BorderRadius.circular(13),
                              boxShadow: [
                                BoxShadow(
                                  color: color.withOpacity(0.32),
                                  blurRadius: 10,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Icon(iconData, color: Colors.white, size: 22),
                          ),
                          const SizedBox(width: 12),

                          // Texte
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    // Badge type
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 7, vertical: 3),
                                      decoration: BoxDecoration(
                                        color: color.withOpacity(0.10),
                                        borderRadius: BorderRadius.circular(5),
                                      ),
                                      child: Text(
                                        _getTypeLabelForDisplay(detectedType),
                                        style: GoogleFonts.inriaSerif(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w700,
                                          color: color,
                                          letterSpacing: 0.2,
                                        ),
                                      ),
                                    ),
                                    const Spacer(),
                                    // Indicateur non-lu avec halo
                                    if (!isRead)
                                      Container(
                                        width: 9,
                                        height: 9,
                                        decoration: BoxDecoration(
                                          color: color,
                                          shape: BoxShape.circle,
                                          boxShadow: [
                                            BoxShadow(
                                              color: color.withOpacity(0.55),
                                              blurRadius: 6,
                                              spreadRadius: 1,
                                            ),
                                          ],
                                        ),
                                      ),
                                  ],
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  notification.title,
                                  style: GoogleFonts.inriaSerif(
                                    fontSize: 14,
                                    fontWeight:
                                        isRead ? FontWeight.w500 : FontWeight.w700,
                                    color: const Color(0xFF1A1A2E),
                                    height: 1.3,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  notification.message,
                                  style: GoogleFonts.inriaSerif(
                                    fontSize: 13,
                                    color: Colors.grey.shade800,
                                    height: 1.4,
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 8),
                                Row(
                                  children: [
                                    Icon(Icons.access_time_rounded,
                                        size: 12, color: Colors.grey.shade900),
                                    const SizedBox(width: 4),
                                    Text(
                                      notification.createdAtHuman ??
                                          notification.createdAt,
                                      style: GoogleFonts.inriaSerif(
                                        fontSize: 13,
                                        color: Colors.grey.shade900,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ── États vide / erreur ────────────────────────────────────────────────────

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 90,
            height: 90,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [_purple.withOpacity(0.12), _purpleLight.withOpacity(0.08)],
              ),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.notifications_none_rounded, size: 46, color: _purple),
          ),
          const SizedBox(height: 20),
          Text(
            'Aucune notification',
            style: GoogleFonts.inriaSerif(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF1A1A2E),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            _selectedFilter == 'all'
                ? 'Vous êtes à jour !'
                : 'Aucune notification dans cette catégorie',
            style: GoogleFonts.inriaSerif(fontSize: 14, color: Colors.grey.shade800),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 90,
              height: 90,
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.error_outline_rounded, size: 46, color: Colors.red.shade400),
            ),
            const SizedBox(height: 20),
            Text(
              'Erreur',
              style: GoogleFonts.inriaSerif(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: GoogleFonts.inriaSerif(fontSize: 14, color: Colors.grey.shade800),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _loadNotifications,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Réessayer'),
              style: ElevatedButton.styleFrom(
                backgroundColor: _purple,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Helpers type ───────────────────────────────────────────────────────────

  String _getTypeLabelForDisplay(String type) {
    switch (type) {
      case 'order':   return 'Commande';
      case 'payment': return 'Paiement';
      case 'loyalty': return 'Fidélité';
      case 'promo':   return 'Promotion';
      case 'delivery':return 'Livraison';
      default:        return 'Notification';
    }
  }

  IconData _getIconForType(String type) {
    switch (type) {
      case 'order':        return Icons.shopping_bag_rounded;
      case 'payment':
      case 'wave_payment': return Icons.payment_rounded;
      case 'loyalty':      return Icons.stars_rounded;
      case 'promo':
      case 'promotion':    return Icons.local_offer_rounded;
      case 'delivery':     return Icons.local_shipping_rounded;
      case 'system':       return Icons.info_rounded;
      default:             return Icons.notifications_rounded;
    }
  }

  Color _getColorForType(String type) {
    switch (type) {
      case 'order':        return const Color(0xFF1565C0);
      case 'payment':
      case 'wave_payment': return const Color(0xFF00838F);
      case 'loyalty':      return const Color(0xFF6A1B9A);
      case 'promo':
      case 'promotion':    return const Color(0xFFE65100);
      case 'delivery':     return const Color(0xFF2E7D32);
      case 'system':       return const Color(0xFF546E7A);
      default:             return _purple;
    }
  }
}
