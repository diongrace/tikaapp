import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../services/notification_service.dart';

/// Écran de la liste des notifications — Design premium
class NotificationsListScreen extends StatefulWidget {
  const NotificationsListScreen({super.key});

  @override
  State<NotificationsListScreen> createState() => _NotificationsListScreenState();
}

class _NotificationsListScreenState extends State<NotificationsListScreen> {
  List<NotificationItem> _allNotifications = []; // toutes les notifs chargées
  List<NotificationItem> _notifications = [];    // filtrées côté client
  bool _isLoading = true;
  String? _errorMessage;
  int _unreadCount = 0;
  Map<String, int> _countByType = {};
  String _selectedFilter = 'all';

  final List<Map<String, dynamic>> _filters = [
    {'id': 'all',     'label': 'Tout',      'icon': Icons.all_inbox_rounded},
    {'id': 'order',   'label': 'Commandes', 'icon': FontAwesomeIcons.bagShopping},
    {'id': 'payment', 'label': 'Paiements', 'icon': FontAwesomeIcons.creditCard},
    {'id': 'loyalty', 'label': 'Fidélité',  'icon': FontAwesomeIcons.solidStar},
    {'id': 'promo',   'label': 'Promos',    'icon': FontAwesomeIcons.tag},
  ];

  static const _purple = Color(0xFF7C5CBF);
  static const _purpleLight = Color(0xFF9E82CC);

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
      // Toujours charger TOUTES les notifs (sans filtre type) — filtrage client-side
      final response = await NotificationService.getNotifications(
        status: 'all',
      );
      if (!mounted) return;

      // Calcul countByType côté client si l'API ne le fournit pas
      final all = response.notifications;
      // countByType calculé avec le type résolu (détection par mots-clés si API type inconnu)
      final Map<String, int> counts = {};
      for (final n in all) {
        final t = _resolveType(n);
        counts[t] = (counts[t] ?? 0) + 1;
      }

      setState(() {
        _allNotifications = all;
        _unreadCount = response.unreadCount;
        _countByType = response.countByType ?? counts;
        _applyFilter();
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

  void _applyFilter() {
    if (_selectedFilter == 'all') {
      _notifications = List.from(_allNotifications);
    } else {
      _notifications = _allNotifications
          .where((n) => _resolveType(n) == _selectedFilter)
          .toList();
    }
  }

  Future<void> _openNotificationDetail(NotificationItem notification) async {
    // Marquer comme lu si nécessaire
    if (!notification.isRead) {
      await NotificationService.markAsRead(notification.id);
      _loadNotifications(); // rafraîchir toute la liste
    }

    // Appel API détail pour infos enrichies (shop, read_at)
    final detail = await NotificationService.getNotificationDetail(notification.id);
    final item = detail ?? notification;

    if (!mounted) return;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _buildDetailSheet(item),
    );
  }

  Widget _buildDetailSheet(NotificationItem n) {
    final resolvedType = _resolveType(n);
    final color = _getColorForType(resolvedType);
    final icon = _getIconForType(resolvedType);

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Handle
          Center(
            child: Container(
              width: 40, height: 4,
              margin: const EdgeInsets.only(bottom: 20),
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          // Icône + type
          Row(children: [
            Container(
              width: 44, height: 44,
              decoration: BoxDecoration(
                color: color.withOpacity(0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(width: 12),
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(
                _getTypeLabelForDisplay(resolvedType),
                style: GoogleFonts.inriaSerif(
                  fontSize: 12, color: color, fontWeight: FontWeight.w700),
              ),
              Text(
                n.createdAtHuman ?? n.createdAt,
                style: GoogleFonts.inriaSerif(fontSize: 11, color: Colors.grey.shade500),
              ),
            ]),
          ]),
          const SizedBox(height: 16),
          // Titre
          Text(
            n.title,
            style: GoogleFonts.inriaSerif(
              fontSize: 16, fontWeight: FontWeight.bold, color: const Color(0xFF1C1C1E)),
          ),
          const SizedBox(height: 8),
          // Message
          Text(
            n.message,
            style: GoogleFonts.inriaSerif(fontSize: 14, color: Colors.grey.shade700, height: 1.5),
          ),
          const SizedBox(height: 24),
          // Bouton fermer
          SizedBox(
            width: double.infinity,
            child: TextButton(
              onPressed: () => Navigator.pop(context),
              style: TextButton.styleFrom(
                backgroundColor: const Color(0xFFF0EDF6),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              child: Text('Fermer',
                style: GoogleFonts.inriaSerif(
                  fontSize: 14, fontWeight: FontWeight.w600, color: _purple)),
            ),
          ),
        ],
      ),
    );
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
      setState(() {
        _allNotifications.removeWhere((n) => n.id == id);
        _applyFilter();
      });
      if (mounted) _showSnack('Notification supprimée', Colors.grey.shade900);
    } catch (e) {
      if (mounted) _showError(e.toString());
    }
  }

  Future<void> _clearRead() async {
    try {
      final count = await NotificationService.clearRead();
      await _loadNotifications();
      if (mounted) _showSnack('$count notification(s) supprimée(s)', Colors.grey.shade900);
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
      backgroundColor: const Color(0xFFF6F6FA),
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
          colors: [Color(0xFF5E3A9E), _purpleLight],
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
                  child: const FaIcon(FontAwesomeIcons.arrowLeft, color: Colors.white, size: 18),
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
              if (_notifications.isNotEmpty)
                PopupMenuButton<String>(
                  onSelected: (value) {
                    if (value == 'mark_all') _markAllAsRead();
                    if (value == 'clear_read') _clearRead();
                  },
                  itemBuilder: (ctx) => [
                    if (_unreadCount > 0)
                      PopupMenuItem(
                        value: 'mark_all',
                        child: Row(children: [
                          const FaIcon(FontAwesomeIcons.checkDouble, size: 16, color: _purple),
                          const SizedBox(width: 12),
                          Text('Tout marquer comme lu', style: GoogleFonts.inriaSerif(fontSize: 14)),
                        ]),
                      ),
                    PopupMenuItem(
                      value: 'clear_read',
                      child: Row(children: [
                        const FaIcon(FontAwesomeIcons.trashCan, size: 16, color: Colors.redAccent),
                        const SizedBox(width: 12),
                        Text('Supprimer les lues', style: GoogleFonts.inriaSerif(fontSize: 14)),
                      ]),
                    ),
                  ],
                  child: _glassContainer(
                    child: const FaIcon(FontAwesomeIcons.ellipsisVertical, color: Colors.white, size: 20),
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
              onTap: () {
                setState(() {
                  _selectedFilter = filter['id'];
                  _applyFilter(); // filtrage côté client, pas de rechargement réseau
                });
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 220),
                curve: Curves.easeInOut,
                padding: const EdgeInsets.symmetric(horizontal: 14),
                decoration: BoxDecoration(
                  gradient: isSelected
                      ? const LinearGradient(
                          colors: [_purple, _purpleLight],
                          begin: Alignment.centerLeft,
                          end: Alignment.centerRight,
                        )
                      : null,
                  color: isSelected ? null : const Color(0xFFEDEDF4),
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
                    // Compteur par type depuis l'API
                    if (filter['id'] != 'all' && (_countByType[filter['id']] ?? 0) > 0) ...[
                      const SizedBox(width: 5),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                        decoration: BoxDecoration(
                          color: isSelected ? Colors.white.withOpacity(0.3) : _purple.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          '${_countByType[filter['id']]}',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: isSelected ? Colors.white : _purple,
                          ),
                        ),
                      ),
                    ],
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
    final resolvedType = _resolveType(notification);
    final iconData = _getIconForType(resolvedType);
    final color = _getColorForType(resolvedType);

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
            const FaIcon(FontAwesomeIcons.trash, color: Colors.white, size: 26),
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
        onTap: () => _openNotificationDetail(notification),
        child: Container(
          margin: const EdgeInsets.only(bottom: 8),
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
                        colors: isRead
                            ? [color.withOpacity(0.30), color.withOpacity(0.10)]
                            : [color, color.withOpacity(0.45)],
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
                                        _getTypeLabelForDisplay(resolvedType),
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
                                    FaIcon(FontAwesomeIcons.clock,
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
            alignment: Alignment.center,
            child: const FaIcon(FontAwesomeIcons.bell, size: 46, color: _purple),
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
              alignment: Alignment.center,
              child: FaIcon(FontAwesomeIcons.circleExclamation, size: 46, color: Colors.red.shade400),
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
              icon: const FaIcon(FontAwesomeIcons.arrowsRotate),
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

  /// Résout le type réel d'une notification.
  /// Utilise le champ type de l'API si connu, sinon détecte depuis titre/message.
  String _resolveType(NotificationItem n) {
    const known = {'order', 'payment', 'wave_payment', 'loyalty', 'promo', 'promotion', 'delivery', 'system'};
    if (known.contains(n.type)) return n.type;

    // Détection par mots-clés dans titre + message
    final text = '${n.title} ${n.message}'.toLowerCase();
    if (text.contains('commande') || text.contains('order')) return 'order';
    if (text.contains('paiement') || text.contains('payment') || text.contains('wave')) return 'payment';
    if (text.contains('point') || text.contains('fidélité') || text.contains('loyalty')) return 'loyalty';
    if (text.contains('promo') || text.contains('réduction') || text.contains('offre')) return 'promo';
    if (text.contains('livraison') || text.contains('delivery') || text.contains('livreur')) return 'delivery';
    return 'system';
  }

  String _getTypeLabelForDisplay(String type) {
    switch (type) {
      case 'order':              return 'Commande';
      case 'payment':
      case 'wave_payment':       return 'Paiement';
      case 'loyalty':            return 'Fidélité';
      case 'promo':
      case 'promotion':          return 'Promotion';
      case 'delivery':           return 'Livraison';
      case 'system':             return 'Système';
      default:                   return 'Notification';
    }
  }

  IconData _getIconForType(String type) {
    switch (type) {
      case 'order':        return FontAwesomeIcons.bagShopping;
      case 'payment':
      case 'wave_payment': return FontAwesomeIcons.creditCard;
      case 'loyalty':      return FontAwesomeIcons.solidStar;
      case 'promo':
      case 'promotion':    return FontAwesomeIcons.tag;
      case 'delivery':     return FontAwesomeIcons.truck;
      case 'system':       return FontAwesomeIcons.circleInfo;
      default:             return FontAwesomeIcons.solidBell;
    }
  }

  Color _getColorForType(String type) {
    switch (type) {
      case 'order':        return const Color(0xFF5585C8);
      case 'payment':
      case 'wave_payment': return const Color(0xFF3DA8B4);
      case 'loyalty':      return const Color(0xFF8B5CB3);
      case 'promo':
      case 'promotion':    return const Color(0xFFEE8A50);
      case 'delivery':     return const Color(0xFF4CAF6A);
      case 'system':       return const Color(0xFF7A96A4);
      default:             return _purple;
    }
  }
}
