import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'personal_info_screen.dart';
import 'addresses_screen.dart';
import 'notifications_screen.dart';
import 'help_support_screen.dart';
import '../../../core/services/storage_service.dart';
import '../../../core/utils/responsive.dart';
import '../../../services/auth_service.dart';
import '../../../services/profile_service.dart';
import '../../../services/order_service.dart';
import '../../../services/device_service.dart';
import '../../../services/favorites_service.dart';
import '../../../services/loyalty_service.dart';
import '../../../services/dashboard_service.dart';
import '../../../core/messages/message_modal.dart';
import '../../auth/auth_choice_screen.dart';
import '../history/global_history_screen.dart';
import '../favorites/favorites_boutiques_screen.dart';
import '../loyalty/loyalty_card_page.dart';
import '../home/components/home_bottom_navigation.dart';

/// Ecran de profil client - Conforme a l'API TIKA
/// Affiche le profil connecte ou les infos locales
class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  String _customerName = '';
  String _customerPhone = '';
  String _customerEmail = '';
  int _ordersCount = 0;
  int _favoritesCount = 0;
  int _loyaltyPoints = 0;
  bool _isAuthenticated = false;

  @override
  void initState() {
    super.initState();
    _loadCustomerData();
  }

  Future<void> _loadCustomerData() async {
    _isAuthenticated = AuthService.isAuthenticated;

    if (_isAuthenticated && AuthService.currentClient != null) {
      final client = AuthService.currentClient!;
      setState(() {
        _customerName = client.name;
        _customerPhone = client.phone;
        _customerEmail = client.email ?? '';
      });

      // Charger les stats depuis l'API
      final stats = await ProfileService.getStats();
      if (stats != null && mounted) {
        setState(() {
          _ordersCount = stats.totalOrders;
          _favoritesCount = stats.favoritesCount;
          _loyaltyPoints = stats.loyaltyPoints;
        });
      }
    } else {
      final customerInfo = await StorageService.getCustomerInfo();
      setState(() {
        _customerName = customerInfo['name'] ?? 'Client';
        _customerPhone = customerInfo['phone'] ?? '';
        _customerEmail = customerInfo['email'] ?? '';
      });
    }

    // Toujours enrichir avec les donnees reelles
    await _loadRealStats();
  }

  /// Charger les stats reelles depuis les APIs
  Future<void> _loadRealStats() async {
    int ordersCount = _ordersCount;
    int favoritesCount = _favoritesCount;
    int loyaltyPoints = _loyaltyPoints;

    // 1. Dashboard authentifie (source la plus fiable)
    if (_isAuthenticated) {
      try {
        final overview = await DashboardService.getOverview();
        if (overview.totalOrders > ordersCount) {
          ordersCount = overview.totalOrders;
        }
        if (overview.favoritesCount > favoritesCount) {
          favoritesCount = overview.favoritesCount;
        }
        if (overview.loyaltyPoints > loyaltyPoints) {
          loyaltyPoints = overview.loyaltyPoints;
        }
      } catch (e) {
        print('Profile: erreur chargement dashboard: $e');
      }
    }

    // 2. Stats commandes via API authentifiee
    if (_isAuthenticated) {
      try {
        final token = AuthService.authToken!;
        final stats = await OrderService.getOrderStats(token);
        final totalFromStats = stats['total_orders'] ?? stats['total'] ?? 0;
        if (totalFromStats is int && totalFromStats > ordersCount) {
          ordersCount = totalFromStats;
        }
      } catch (e) {
        print('Profile: erreur chargement order stats: $e');
      }
    }

    // 3. Commandes via device fingerprint (fallback)
    try {
      final deviceFingerprint = await DeviceService.getDeviceFingerprint();
      final response = await OrderService.getOrdersByDevice(
        deviceFingerprint: deviceFingerprint,
      );
      final pagination = response['pagination'] as Map<String, dynamic>?;
      final total = pagination?['total'] as int? ?? 0;
      final orders = response['orders'] as List? ?? [];
      final realCount = total > 0 ? total : orders.length;
      if (realCount > ordersCount) {
        ordersCount = realCount;
      }
    } catch (e) {
      print('Profile: erreur chargement commandes device: $e');
    }

    // 3. Favoris via API
    if (_isAuthenticated) {
      try {
        await AuthService.ensureToken();
        final favs = await FavoritesService.getFavorites();
        if (favs.length > favoritesCount) {
          favoritesCount = favs.length;
        }
      } catch (e) {
        print('Profile: erreur chargement favoris: $e');
      }
    }

    // 3. Fallback local pour favoris
    try {
      final localFavs = await StorageService.getFavoriteShopIds();
      if (localFavs.length > favoritesCount) {
        favoritesCount = localFavs.length;
      }
    } catch (e) {}

    // 4. Points fidelite via API
    if (_isAuthenticated) {
      try {
        await AuthService.ensureToken();
        final cards = await LoyaltyService.getMyCards();
        int totalPoints = 0;
        for (final card in cards) {
          totalPoints += card.points;
        }
        if (totalPoints > loyaltyPoints) {
          loyaltyPoints = totalPoints;
        }
      } catch (e) {
        print('Profile: erreur chargement fidelite: $e');
      }
    }

    if (mounted) {
      setState(() {
        _ordersCount = ordersCount;
        _favoritesCount = favoritesCount;
        _loyaltyPoints = loyaltyPoints;
      });
    }
  }

  Future<void> _logout() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Deconnexion',
          style: GoogleFonts.openSans(fontWeight: FontWeight.bold),
        ),
        content: Text(
          'Etes-vous sur de vouloir vous deconnecter ?',
          style: GoogleFonts.openSans(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(
              'Annuler',
              style: GoogleFonts.openSans(color: Colors.grey),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(
              'Deconnexion',
              style: GoogleFonts.openSans(
                color: Colors.red,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await AuthService.logout();
      if (mounted) {
        showSuccessModal(context, 'Deconnexion reussie');
        await Future.delayed(const Duration(milliseconds: 800));
        if (mounted) {
          Navigator.of(context).pop(); // ferme le modal de succès
          Navigator.of(context).pop(); // ferme le ProfileScreen → retour accueil
        }
      }
    }
  }

  /// Naviguer vers les cartes de fidelite
  Future<void> _navigateToLoyalty() async {
    if (!_isAuthenticated) {
      _goToAuth();
      return;
    }

    try {
      await AuthService.ensureToken();
      final cards = await LoyaltyService.getMyCards();

      if (!mounted) return;

      if (cards.isEmpty) {
        // Aucune carte
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Aucune carte de fidelite. Visitez une boutique pour en creer une.',
              style: GoogleFonts.openSans(color: Colors.white),
            ),
            backgroundColor: const Color(0xFF8936A8),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
      } else if (cards.length == 1) {
        // Une seule carte → ouvrir directement
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => LoyaltyCardPage(loyaltyCard: cards.first),
          ),
        );
      } else {
        // Plusieurs cartes → afficher la liste
        _showLoyaltyCardPicker(cards);
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
    }
  }

  /// Afficher le picker de cartes de fidelite
  void _showLoyaltyCardPicker(List cards) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.75,
        ),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle bar
            const SizedBox(height: 12),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),

            // Header avec icone et titre
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFFD48EFC), Color(0xFF8936A8)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Icon(
                      Icons.loyalty_rounded,
                      color: Colors.white,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Mes cartes de fidelite',
                        style: GoogleFonts.poppins(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      Text(
                        '${cards.length} carte${cards.length > 1 ? 's' : ''}',
                        style: GoogleFonts.openSans(
                          fontSize: 13,
                          color: Colors.grey.shade500,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),
            Divider(color: Colors.grey.shade100, thickness: 1),
            const SizedBox(height: 8),

            // Liste des cartes
            Flexible(
              child: ListView.separated(
                shrinkWrap: true,
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
                itemCount: cards.length,
                separatorBuilder: (_, __) => const SizedBox(height: 10),
                itemBuilder: (context, index) {
                  final card = cards[index];
                  final hasPoints = card.points > 0;
                  return InkWell(
                    onTap: () {
                      Navigator.pop(ctx);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => LoyaltyCardPage(loyaltyCard: card),
                        ),
                      );
                    },
                    borderRadius: BorderRadius.circular(16),
                    child: Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8F4FF),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: const Color(0xFF8936A8).withOpacity(0.15),
                          width: 1,
                        ),
                      ),
                      child: Row(
                        children: [
                          // Logo ou initiale de la boutique
                          _buildShopAvatar(card),
                          const SizedBox(width: 14),

                          // Infos
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  card.shopName,
                                  style: GoogleFonts.poppins(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.black87,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    Icon(
                                      Icons.stars_rounded,
                                      size: 15,
                                      color: hasPoints
                                          ? const Color(0xFF8936A8)
                                          : Colors.grey.shade400,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      hasPoints
                                          ? '${card.points} points'
                                          : 'Aucun point',
                                      style: GoogleFonts.openSans(
                                        fontSize: 13,
                                        fontWeight: hasPoints
                                            ? FontWeight.w600
                                            : FontWeight.normal,
                                        color: hasPoints
                                            ? const Color(0xFF8936A8)
                                            : Colors.grey.shade400,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),

                          // Fleche
                          Container(
                            width: 32,
                            height: 32,
                            decoration: BoxDecoration(
                              color: const Color(0xFF8936A8).withOpacity(0.1),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(
                              Icons.arrow_forward_ios_rounded,
                              size: 14,
                              color: Color(0xFF8936A8),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _goToAuth() async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (context) => const AuthChoiceScreen(),
      ),
    );

    if (result == true && mounted) {
      _loadCustomerData();
    }
  }

  String _getInitials(String name) {
    if (name.isEmpty) return '?';
    final parts = name.trim().split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return name[0].toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      bottomNavigationBar: const HomeBottomNavigation(
        selectedIndex: 5,
        currentShop: null,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Header violet avec degrade
            Stack(
              children: [
                Container(
                  height: 220,
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Color(0xFFD48EFC),
                        Color(0xFF8936A8),
                      ],
                    ),
                  ),
                ),
                SafeArea(
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(
                      Responsive.horizontalPadding(context), 8,
                      Responsive.horizontalPadding(context), 12,
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            shape: BoxShape.circle,
                          ),
                          child: IconButton(
                            icon: const Icon(Icons.arrow_back, color: Colors.white, size: 24),
                            onPressed: () => Navigator.pop(context),
                            padding: EdgeInsets.zero,
                          ),
                        ),
                        const Spacer(),
                        Text(
                          'Profil',
                          style: GoogleFonts.openSans(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const Spacer(),
                        const SizedBox(width: 48),
                      ],
                    ),
                  ),
                ),
              ],
            ),

            // Carte blanche avec informations utilisateur
            Transform.translate(
              offset: const Offset(0, -100),
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.08),
                            blurRadius: 20,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          // Avatar
                          Container(
                            width: 100,
                            height: 100,
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [Color(0xFFD48EFC), Color(0xFF8936A8)],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFF8936A8).withOpacity(0.4),
                                  blurRadius: 15,
                                  offset: const Offset(0, 5),
                                ),
                              ],
                            ),
                            child: Center(
                              child: _isAuthenticated
                                  ? Text(
                                      _getInitials(_customerName),
                                      style: GoogleFonts.openSans(
                                        fontSize: 36,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                      ),
                                    )
                                  : const Icon(
                                      Icons.person_outline,
                                      size: 48,
                                      color: Colors.white,
                                    ),
                            ),
                          ),

                          const SizedBox(height: 20),

                          // Nom
                          Text(
                            _isAuthenticated
                                ? (_customerName.isEmpty ? 'Mon profil' : _customerName)
                                : 'Bienvenue',
                            style: GoogleFonts.openSans(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                          ),

                          const SizedBox(height: 8),

                          if (_isAuthenticated) ...[
                            if (_customerEmail.isNotEmpty) ...[
                              const SizedBox(height: 4),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(Icons.email_outlined, size: 18, color: Colors.grey),
                                  const SizedBox(width: 8),
                                  Text(
                                    _customerEmail,
                                    style: GoogleFonts.openSans(
                                      fontSize: 14,
                                      color: Colors.grey.shade700,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                            if (_customerPhone.isNotEmpty) ...[
                              const SizedBox(height: 6),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(Icons.phone_outlined, size: 18, color: Colors.grey),
                                  const SizedBox(width: 8),
                                  Text(
                                    _customerPhone,
                                    style: GoogleFonts.openSans(
                                      fontSize: 14,
                                      color: Colors.grey.shade700,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ] else ...[
                            Text(
                              'Connectez-vous pour acceder a votre profil',
                              style: GoogleFonts.openSans(
                                fontSize: 13,
                                color: Colors.grey.shade500,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Statistiques (Commandes, Favoris, Points)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 5),
                    child: Row(
                      children: [
                        Expanded(
                          child: _buildStatCard(
                            _ordersCount.toString(),
                            _ordersCount > 1 ? 'Commandes' : 'Commande',
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => const GlobalHistoryScreen(),
                                ),
                              );
                            },
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildStatCard(
                            _favoritesCount.toString(),
                            'Favoris',
                            locked: !_isAuthenticated,
                            onTap: () {
                              if (!_isAuthenticated) {
                                _goToAuth();
                                return;
                              }
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => const FavoritesBoutiquesScreen(),
                                ),
                              );
                            },
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildStatCard(
                            _loyaltyPoints.toString(),
                            'Points',
                            locked: !_isAuthenticated,
                            onTap: () {
                              if (!_isAuthenticated) {
                                _goToAuth();
                                return;
                              }
                              _navigateToLoyalty();
                            },
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Carte de fidelite
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: GestureDetector(
                      onTap: !_isAuthenticated ? _goToAuth : null,
                      child: Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              Color(0xFFD48EFC),
                              Color(0xFF8936A8),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF8936A8).withOpacity(0.4),
                              blurRadius: 15,
                              offset: const Offset(0, 5),
                            ),
                          ],
                        ),
                        child: _isAuthenticated
                            ? Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      const Icon(Icons.credit_card, color: Colors.white, size: 24),
                                      const SizedBox(width: 12),
                                      Text(
                                        'Programme de fidelite',
                                        style: GoogleFonts.openSans(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w600,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 16),
                                  Text(
                                    '$_loyaltyPoints points',
                                    style: GoogleFonts.openSans(
                                      fontSize: 36,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    _loyaltyPoints > 0
                                        ? 'Valeur: ${(_loyaltyPoints * 5).toStringAsFixed(0)} FCFA'
                                        : 'Creez une carte pour gagner des points',
                                    style: GoogleFonts.openSans(
                                      fontSize: 14,
                                      color: Colors.white.withOpacity(0.9),
                                    ),
                                  ),
                                  const SizedBox(height: 20),
                                  ElevatedButton(
                                    onPressed: () => _navigateToLoyalty(),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.white.withOpacity(0.3),
                                      foregroundColor: Colors.white,
                                      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 24),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      elevation: 0,
                                    ),
                                    child: Text(
                                      'Voir mes cartes',
                                      style: GoogleFonts.openSans(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ],
                              )
                            : Row(
                                children: [
                                  const Icon(Icons.lock_outline, color: Colors.white, size: 28),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Programme de fidelite',
                                          style: GoogleFonts.openSans(
                                            fontSize: 16,
                                            fontWeight: FontWeight.w600,
                                            color: Colors.white,
                                          ),
                                        ),
                                        const SizedBox(height: 6),
                                        Text(
                                          'Connectez-vous pour gagner des points et des recompenses',
                                          style: GoogleFonts.openSans(
                                            fontSize: 13,
                                            color: Colors.white.withOpacity(0.85),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const Icon(Icons.chevron_right, color: Colors.white, size: 22),
                                ],
                              ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Options de menu
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Column(
                      children: [
                        _buildMenuOption(
                          icon: Icons.person_outline,
                          title: 'Mon profil',
                          subtitle: 'Informations personnelles et mot de passe',
                          locked: !_isAuthenticated,
                          onTap: () async {
                            if (!_isAuthenticated) {
                              _goToAuth();
                              return;
                            }
                            final result = await Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const PersonalInfoScreen(),
                              ),
                            );
                            if (result == true) {
                              _loadCustomerData();
                            }
                          },
                        ),
                        const SizedBox(height: 12),
                        _buildMenuOption(
                          icon: Icons.location_on_outlined,
                          title: 'Adresses de livraison',
                          subtitle: 'Gerer vos adresses',
                          locked: !_isAuthenticated,
                          onTap: () {
                            if (!_isAuthenticated) {
                              _goToAuth();
                              return;
                            }
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const AddressesScreen(),
                              ),
                            );
                          },
                        ),
                        const SizedBox(height: 12),
                        _buildMenuOption(
                          icon: Icons.notifications_outlined,
                          title: 'Notifications',
                          subtitle: 'Gerer vos alertes',
                          locked: !_isAuthenticated,
                          onTap: () {
                            if (!_isAuthenticated) {
                              _goToAuth();
                              return;
                            }
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const NotificationsScreen(),
                              ),
                            );
                          },
                        ),
                        const SizedBox(height: 12),
                        _buildMenuOption(
                          icon: Icons.help_outline,
                          title: 'Support / Aide',
                          subtitle: 'Contactez-nous, suivez vos demandes',
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const HelpSupportScreen(),
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Bouton Connexion / Deconnexion
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: _isAuthenticated
                        ? _buildLogoutButton()
                        : _buildLoginButton(),
                  ),

                  const SizedBox(height: 32),

                  // Version et copyright
                  Text(
                    'Tika v1.0.0',
                    style: GoogleFonts.openSans(
                      fontSize: 12,
                      color: Colors.grey.shade500,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '2025 Tika. Tous droits reserves.',
                    style: GoogleFonts.openSans(
                      fontSize: 12,
                      color: Colors.grey.shade500,
                    ),
                  ),

                  const SizedBox(height: 7),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Avatar boutique : logo si disponible, initiale sinon
  Widget _buildShopAvatar(dynamic card) {
    final hasLogo = card.shopLogo != null && card.shopLogo!.isNotEmpty;
    final logoUrl = hasLogo
        ? (card.shopLogo!.startsWith('http')
            ? card.shopLogo!
            : 'https://prepro.tika-ci.com/storage/${card.shopLogo!}')
        : null;
    final initial = card.shopName.isNotEmpty ? card.shopName[0].toUpperCase() : '?';

    if (hasLogo) {
      // Fond blanc pour ne pas colorer les PNG transparents
      return Container(
        width: 52,
        height: 52,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.grey.shade200, width: 1),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(13),
          child: Image.network(
            logoUrl!,
            fit: BoxFit.contain,
            width: 52,
            height: 52,
            errorBuilder: (_, __, ___) => _buildInitialAvatar(initial),
            loadingBuilder: (_, child, progress) =>
                progress == null ? child : _buildInitialAvatar(initial),
          ),
        ),
      );
    }

    return _buildInitialAvatar(initial);
  }

  Widget _buildInitialAvatar(String initial) {
    return Container(
      width: 52,
      height: 52,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFD48EFC), Color(0xFF8936A8)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Center(
        child: Text(
          initial,
          style: GoogleFonts.poppins(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ),
    );
  }

  Widget _buildStatCard(String value, String label, {VoidCallback? onTap, bool locked = false}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
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
            locked
                ? Icon(Icons.lock_outline, size: 28, color: Colors.grey.shade400)
                : Text(
                    value,
                    style: GoogleFonts.openSans(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF8936A8),
                    ),
                  ),
            const SizedBox(height: 4),
            Text(
              label,
              style: GoogleFonts.openSans(
                fontSize: 13,
                color: locked ? Colors.grey.shade400 : Colors.grey.shade700,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuOption({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    bool locked = false,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
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
        child: Row(
          children: [
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: locked
                    ? Colors.grey.withOpacity(0.08)
                    : const Color(0xFF8936A8).withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                color: locked ? Colors.grey.shade400 : const Color(0xFF8936A8),
                size: 24,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.openSans(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: locked ? Colors.grey.shade400 : Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: GoogleFonts.openSans(
                      fontSize: 13,
                      color: Colors.grey.shade500,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              locked ? Icons.lock_outline : Icons.chevron_right,
              color: Colors.grey.shade400,
              size: 22,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoginButton() {
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF8936A8), Color(0xFFB932D6)],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF8936A8).withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: _goToAuth,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.login,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Se connecter',
                        style: GoogleFonts.openSans(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Synchronisez vos donnees',
                        style: GoogleFonts.openSans(
                          fontSize: 13,
                          color: Colors.white.withOpacity(0.8),
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.chevron_right,
                  color: Colors.white.withOpacity(0.8),
                  size: 24,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLogoutButton() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.red.shade200, width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: _logout,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.logout,
                    color: Colors.red.shade700,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Deconnexion',
                        style: GoogleFonts.openSans(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.red.shade700,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Se deconnecter de ce compte',
                        style: GoogleFonts.openSans(
                          fontSize: 13,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.chevron_right,
                  color: Colors.grey.shade400,
                  size: 24,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
