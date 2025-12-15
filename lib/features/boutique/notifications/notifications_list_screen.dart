import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/services/storage_service.dart';

/// Écran de la liste des notifications - Stockage local
/// Notifications générées localement (pas d'API pour les clients)
class NotificationsListScreen extends StatefulWidget {
  const NotificationsListScreen({super.key});

  @override
  State<NotificationsListScreen> createState() => _NotificationsListScreenState();
}

class _NotificationsListScreenState extends State<NotificationsListScreen> {
  List<Map<String, dynamic>> _notifications = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadNotifications();
  }

  Future<void> _loadNotifications() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final notifications = await StorageService.getNotifications();

      setState(() {
        _notifications = notifications;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Erreur lors du chargement des notifications';
        _isLoading = false;
      });
    }
  }

  // Liste des notifications par défaut (maintenant supprimée)
  final List<Map<String, dynamic>> _oldNotifications = [
    {
      'id': '1',
      'type': 'order',
      'title': 'Commande livrée',
      'message': 'Votre commande #12345 a été livrée avec succès',
      'time': 'Il y a 2 heures',
      'isRead': false,
      'icon': Icons.shopping_bag,
      'color': Color(0xFF4CAF50),
    },
    {
      'id': '2',
      'type': 'promotion',
      'title': 'Offre spéciale -30%',
      'message': 'Profitez de 30% de réduction sur tous les vêtements ce weekend',
      'time': 'Il y a 5 heures',
      'isRead': false,
      'icon': Icons.local_offer,
      'color': Color(0xFFFF9800),
    },
    {
      'id': '3',
      'type': 'order',
      'title': 'Commande en cours de livraison',
      'message': 'Votre commande #12344 est en cours de livraison',
      'time': 'Hier',
      'isRead': true,
      'icon': Icons.local_shipping,
      'color': Color(0xFF2196F3),
    },
    {
      'id': '4',
      'type': 'loyalty',
      'title': 'Points de fidélité gagnés',
      'message': 'Vous avez gagné 50 points avec votre dernière commande',
      'time': 'Il y a 2 jours',
      'isRead': true,
      'icon': Icons.stars,
      'color': Color(0xFF8936A8),
    },
    {
      'id': '5',
      'type': 'news',
      'title': 'Nouveaux produits disponibles',
      'message': 'Découvrez notre nouvelle collection printemps-été',
      'time': 'Il y a 3 jours',
      'isRead': true,
      'icon': Icons.new_releases,
      'color': Color(0xFFE91E63),
    },
    {
      'id': '6',
      'type': 'order',
      'title': 'Commande confirmée',
      'message': 'Votre commande #12343 a été confirmée et est en cours de préparation',
      'time': 'Il y a 4 jours',
      'isRead': true,
      'icon': Icons.check_circle,
      'color': Color(0xFF4CAF50),
    },
  ];

  int get _unreadCount => _notifications.where((n) => n['isRead'] == false).length;

  Future<void> _markAsRead(String id) async {
    try {
      await StorageService.markNotificationAsRead(id);
      await _loadNotifications();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _markAllAsRead() async {
    try {
      await StorageService.markAllNotificationsAsRead();
      await _loadNotifications();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Toutes les notifications ont été marquées comme lues',
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
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _deleteNotification(String id) async {
    try {
      await StorageService.deleteNotification(id);
      await _loadNotifications();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Notification supprimée',
              style: GoogleFonts.openSans(),
            ),
            backgroundColor: Colors.grey.shade700,
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
            content: Text('Erreur: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _clearAll() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Tout effacer',
          style: GoogleFonts.openSans(fontWeight: FontWeight.bold),
        ),
        content: Text(
          'Voulez-vous vraiment supprimer toutes les notifications ?',
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
            onPressed: () async {
              try {
                await StorageService.clearAllNotifications();
                await _loadNotifications();

                if (mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        'Toutes les notifications ont été supprimées',
                        style: GoogleFonts.openSans(),
                      ),
                      backgroundColor: Colors.grey.shade700,
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  );
                }
              } catch (e) {
                if (mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Erreur: ${e.toString()}'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            child: Text(
              'Effacer',
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
              child: Column(
                children: [
                  Row(
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
                      if (_notifications.isNotEmpty)
                        PopupMenuButton<String>(
                          onSelected: (value) {
                            if (value == 'mark_all') {
                              _markAllAsRead();
                            } else if (value == 'clear_all') {
                              _clearAll();
                            }
                          },
                          itemBuilder: (context) => [
                            if (_unreadCount > 0)
                              PopupMenuItem(
                                value: 'mark_all',
                                child: Row(
                                  children: [
                                    const Icon(Icons.done_all, size: 20),
                                    const SizedBox(width: 12),
                                    Text(
                                      'Tout marquer comme lu',
                                      style: GoogleFonts.openSans(fontSize: 14),
                                    ),
                                  ],
                                ),
                              ),
                            PopupMenuItem(
                              value: 'clear_all',
                              child: Row(
                                children: [
                                  const Icon(Icons.delete_outline,
                                      size: 20, color: Colors.red),
                                  const SizedBox(width: 12),
                                  Text(
                                    'Tout effacer',
                                    style: GoogleFonts.openSans(
                                        fontSize: 14, color: Colors.red),
                                  ),
                                ],
                              ),
                            ),
                          ],
                          icon: const Icon(Icons.more_vert),
                        ),
                    ],
                  ),
                  if (_unreadCount > 0) ...[
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: const Color(0xFF8936A8).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 8,
                            height: 8,
                            decoration: const BoxDecoration(
                              color: Color(0xFF8936A8),
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '$_unreadCount nouvelle${_unreadCount > 1 ? 's' : ''} notification${_unreadCount > 1 ? 's' : ''}',
                            style: GoogleFonts.openSans(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFF8936A8),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
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
                  : _errorMessage != null
                      ? _buildErrorState(_errorMessage!)
                      : _notifications.isEmpty
                          ? _buildEmptyState()
                          : ListView.builder(
                              padding: const EdgeInsets.all(20),
                              itemCount: _notifications.length,
                              itemBuilder: (context, index) {
                                final notification = _notifications[index];
                                return _buildNotificationCard(notification);
                              },
                            ),
            ),
          ],
        ),
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
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.error_outline,
                size: 60,
                color: Colors.red.shade400,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Erreur',
              style: GoogleFonts.openSans(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: GoogleFonts.openSans(
                fontSize: 14,
                color: Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _loadNotifications,
              icon: const Icon(Icons.refresh),
              label: const Text('Réessayer'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF8936A8),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.notifications_outlined,
              size: 60,
              color: Colors.grey.shade400,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Aucune notification',
            style: GoogleFonts.openSans(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Vous êtes à jour !',
            style: GoogleFonts.openSans(
              fontSize: 14,
              color: Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
  }

  // Helper pour convertir string en IconData
  IconData _getIconData(String iconName) {
    switch (iconName) {
      case 'shopping_bag':
        return Icons.shopping_bag;
      case 'local_offer':
        return Icons.local_offer;
      case 'local_shipping':
        return Icons.local_shipping;
      case 'stars':
        return Icons.stars;
      case 'new_releases':
        return Icons.new_releases;
      case 'check_circle':
        return Icons.check_circle;
      default:
        return Icons.notifications;
    }
  }

  // Helper pour convertir string en Color
  Color _getColor(String colorHex) {
    try {
      return Color(int.parse(colorHex.replaceFirst('#', '0xFF')));
    } catch (e) {
      return const Color(0xFF8936A8);
    }
  }

  // Helper pour formater le temps
  String _getTimeAgo(DateTime dateTime) {
    final diff = DateTime.now().difference(dateTime);

    if (diff.inMinutes < 60) {
      return 'Il y a ${diff.inMinutes} min';
    } else if (diff.inHours < 24) {
      return 'Il y a ${diff.inHours}h';
    } else if (diff.inDays == 1) {
      return 'Hier';
    } else if (diff.inDays < 7) {
      return 'Il y a ${diff.inDays} jours';
    } else {
      return 'Il y a ${(diff.inDays / 7).floor()} semaines';
    }
  }

  Widget _buildNotificationCard(Map<String, dynamic> notification) {
    final String notificationId = notification['id'].toString();
    final isRead = notification['isRead'] == true;
    final icon = notification['icon'] as IconData? ?? Icons.notifications;
    final color = notification['color'] as Color? ?? const Color(0xFF8936A8);
    final timeAgo = notification['time'] as String? ?? 'Maintenant';

    return Dismissible(
      key: Key(notificationId.toString()),
      direction: DismissDirection.endToStart,
      onDismissed: (direction) {
        _deleteNotification(notificationId);
      },
      background: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: Colors.red,
          borderRadius: BorderRadius.circular(16),
        ),
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        child: const Icon(
          Icons.delete,
          color: Colors.white,
          size: 28,
        ),
      ),
      child: GestureDetector(
        onTap: () {
          if (!isRead) {
            _markAsRead(notificationId);
          }
          // Navigation vers l'écran approprié selon le type
        },
        child: Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: isRead ? Colors.white : const Color(0xFF8936A8).withOpacity(0.05),
            borderRadius: BorderRadius.circular(16),
            border: isRead
                ? null
                : Border.all(
                    color: const Color(0xFF8936A8).withOpacity(0.2),
                    width: 1,
                  ),
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
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Icône
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    icon,
                    color: color,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),

                // Contenu
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              notification['title'],
                              style: GoogleFonts.openSans(
                                fontSize: 15,
                                fontWeight: isRead
                                    ? FontWeight.w600
                                    : FontWeight.bold,
                                color: Colors.black87,
                              ),
                            ),
                          ),
                          if (!isRead)
                            Container(
                              width: 8,
                              height: 8,
                              decoration: const BoxDecoration(
                                color: Color(0xFF8936A8),
                                shape: BoxShape.circle,
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        notification['message'],
                        style: GoogleFonts.openSans(
                          fontSize: 14,
                          color: Colors.grey.shade700,
                          height: 1.4,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Icon(
                            Icons.access_time,
                            size: 14,
                            color: Colors.grey.shade500,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            timeAgo,
                            style: GoogleFonts.openSans(
                              fontSize: 12,
                              color: Colors.grey.shade500,
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
      ),
    );
  }
}
