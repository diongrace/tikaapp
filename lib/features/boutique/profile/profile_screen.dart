import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
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
import '../loyalty/loyalty_card_list_item.dart';
import '../home/components/home_bottom_navigation.dart';
import '../../../core/services/boutique_theme_provider.dart';

/// Ecran de profil client - Conforme a l'API TIKA
/// Affiche le profil connecte ou les infos locales
class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  Color _shopPrimary = const Color(0xFF8936A8);

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _shopPrimary = BoutiqueThemeProvider.of(context).primary;
  }

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
          style: GoogleFonts.inriaSerif(fontWeight: FontWeight.bold),
        ),
        content: Text(
          'Etes-vous sur de vouloir vous deconnecter ?',
          style: GoogleFonts.inriaSerif(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(
              'Annuler',
              style: GoogleFonts.inriaSerif(color: Colors.grey),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(
              'Deconnexion',
              style: GoogleFonts.inriaSerif(
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
              style: GoogleFonts.inriaSerif(color: Colors.white),
            ),
            backgroundColor: _shopPrimary,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
      } else if (cards.length == 1) {
        // Une seule carte → ouvrir directement
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => BoutiqueThemeProvider(
              shop: BoutiqueThemeProvider.shopOf(context),
              child: LoyaltyCardPage(loyaltyCard: cards.first),
            ),
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
      useSafeArea: true,
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
        child: Container(
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
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [_shopPrimary.withOpacity(0.6), _shopPrimary],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const FaIcon(
                      FontAwesomeIcons.award,
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
                        style: GoogleFonts.inriaSerif(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      Text(
                        '${cards.length} carte${cards.length > 1 ? 's' : ''}',
                        style: GoogleFonts.inriaSerif(
                          fontSize: 13,
                          color: Colors.grey.shade800,
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
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                itemCount: cards.length,
                separatorBuilder: (_, __) => const SizedBox(height: 10),
                itemBuilder: (context, index) {
                  final card = cards[index];
                  return LoyaltyCardListItem(
                    card: card,
                    index: index,
                    onTap: () {
                      Navigator.pop(ctx);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => BoutiqueThemeProvider(
                            shop: BoutiqueThemeProvider.shopOf(context),
                            child: LoyaltyCardPage(loyaltyCard: card),
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
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
    _shopPrimary = BoutiqueThemeProvider.of(context).primary;
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      bottomNavigationBar: HomeBottomNavigation(
        selectedIndex: 5,
        currentShop: BoutiqueThemeProvider.shopOf(context),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Header violet avec degrade
            Stack(
              children: [
                Container(
                  height: 220,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        
                        _shopPrimary.withOpacity(0.6),
                        _shopPrimary,
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
                            icon: const FaIcon(FontAwesomeIcons.arrowLeft, color: Colors.white, size: 24),
                            onPressed: () => Navigator.pop(context),
                            padding: EdgeInsets.zero,
                          ),
                        ),
                        const Spacer(),
                        Text(
                          'Profil',
                          style: GoogleFonts.inriaSerif(
                            fontSize: 16,
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
                            width: 70,
                            height: 70,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [_shopPrimary.withOpacity(0.6), _shopPrimary],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: _shopPrimary.withOpacity(0.4),
                                  blurRadius: 15,
                                  offset: const Offset(0, 5),
                                ),
                              ],
                            ),
                            child: Center(
                              child: _isAuthenticated
                                  ? Text(
                                      _getInitials(_customerName),
                                      style: GoogleFonts.inriaSerif(
                                        fontSize: 20,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                      ),
                                    )
                                  : const FaIcon(
                                      FontAwesomeIcons.user,
                                      size: 36,
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
                            style: GoogleFonts.inriaSerif(
                              fontSize: 18,
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
                                  const FaIcon(FontAwesomeIcons.envelope, size: 18, color: Colors.grey),
                                  const SizedBox(width: 8),
                                  Text(
                                    _customerEmail,
                                    style: GoogleFonts.inriaSerif(
                                      fontSize: 13,
                                      color: Colors.grey.shade900,
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
                                  const FaIcon(FontAwesomeIcons.phone, size: 18, color: Colors.grey),
                                  const SizedBox(width: 8),
                                  Text(
                                    _customerPhone,
                                    style: GoogleFonts.inriaSerif(
                                      fontSize: 13,
                                      color: Colors.grey.shade900,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ] else ...[
                            Text(
                              'Connectez-vous pour acceder a votre profil',
                              style: GoogleFonts.inriaSerif(
                                fontSize: 13,
                                color: Colors.grey.shade800,
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
                                  builder: (context) => BoutiqueThemeProvider(
                                    shop: BoutiqueThemeProvider.shopOf(context),
                                    child: const GlobalHistoryScreen(),
                                  ),
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
                                  builder: (context) => BoutiqueThemeProvider(
                                    shop: BoutiqueThemeProvider.shopOf(context),
                                    child: const FavoritesBoutiquesScreen(),
                                  ),
                                ),
                              );
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
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              _shopPrimary.withOpacity(0.6),
                              _shopPrimary,
                            ],
                          ),
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: _shopPrimary.withOpacity(0.4),
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
                                      const FaIcon(FontAwesomeIcons.creditCard, color: Colors.white, size: 24),
                                      const SizedBox(width: 12),
                                      Text(
                                        'Programme de fidélité',
                                        style: GoogleFonts.inriaSerif(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w600,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 16),
                                  Text(
                                    '$_loyaltyPoints points',
                                    style: GoogleFonts.inriaSerif(
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    _loyaltyPoints > 0
                                        ? 'Valeur: ${(_loyaltyPoints * 5).toStringAsFixed(0)} FCFA'
                                        : 'Créez une carte pour gagner des points',
                                    style: GoogleFonts.inriaSerif(
                                      fontSize: 13,
                                      color: Colors.white.withOpacity(0.9),
                                    ),
                                  ),
                                  const SizedBox(height: 20),
                                  SizedBox(
                                    width: double.infinity,
                                    child: ElevatedButton(
                                      onPressed: () => _navigateToLoyalty(),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.white,
                                        foregroundColor: _shopPrimary,
                                        padding: const EdgeInsets.symmetric(vertical: 13),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                        elevation: 0,
                                      ),
                                      child: Text(
                                        'Voir mes cartes',
                                        style: GoogleFonts.inriaSerif(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w700,
                                          color: _shopPrimary,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              )
                            : Row(
                                children: [
                                  const FaIcon(FontAwesomeIcons.lock, color: Colors.white, size: 28),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Programme de fidélité',
                                          style: GoogleFonts.inriaSerif(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w600,
                                            color: Colors.white,
                                          ),
                                        ),
                                        const SizedBox(height: 6),
                                        Text(
                                          'Connectez-vous pour gagner des points et des récompenses',
                                          style: GoogleFonts.inriaSerif(
                                            fontSize: 13,
                                            color: Colors.white.withOpacity(0.85),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const FaIcon(FontAwesomeIcons.chevronRight, color: Colors.white, size: 22),
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
                          icon: FontAwesomeIcons.user,
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
                                builder: (context) => BoutiqueThemeProvider(
                                  shop: BoutiqueThemeProvider.shopOf(context),
                                  child: const PersonalInfoScreen(),
                                ),
                              ),
                            );
                            if (result == true) {
                              _loadCustomerData();
                            }
                          },
                        ),
                        const SizedBox(height: 12),
                        _buildMenuOption(
                          icon: FontAwesomeIcons.locationDot,
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
                                builder: (context) => BoutiqueThemeProvider(
                                  shop: BoutiqueThemeProvider.shopOf(context),
                                  child: const AddressesScreen(),
                                ),
                              ),
                            );
                          },
                        ),
                        const SizedBox(height: 12),
                        _buildMenuOption(
                          icon: FontAwesomeIcons.bell,
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
                                builder: (context) => BoutiqueThemeProvider(
                                  shop: BoutiqueThemeProvider.shopOf(context),
                                  child: const NotificationsScreen(),
                                ),
                              ),
                            );
                          },
                        ),
                        const SizedBox(height: 12),
                        _buildMenuOption(
                          icon: FontAwesomeIcons.circleQuestion,
                          title: 'Support / Aide',
                          subtitle: 'Contactez-nous, suivez vos demandes',
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => BoutiqueThemeProvider(
                                  shop: BoutiqueThemeProvider.shopOf(context),
                                  child: const HelpSupportScreen(),
                                ),
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
                    style: GoogleFonts.inriaSerif(
                      fontSize: 12,
                      color: Colors.grey.shade800,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '2025 Tika. Tous droits reserves.',
                    style: GoogleFonts.inriaSerif(
                      fontSize: 12,
                      color: Colors.grey.shade800,
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
  Widget _buildShopAvatar(dynamic card, Color accent) {
    final hasLogo = card.shopLogo != null && card.shopLogo!.isNotEmpty;
    final logoUrl = hasLogo
        ? (card.shopLogo!.startsWith('http')
            ? card.shopLogo!
            : 'https://prepro.tika-ci.com/storage/${card.shopLogo!}')
        : null;
    final initial = card.shopName.isNotEmpty ? card.shopName[0].toUpperCase() : '?';

    if (hasLogo) {
      return Container(
        width: 46, height: 46,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade200),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 6)],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(11),
          child: Image.network(logoUrl!, fit: BoxFit.contain, width: 46, height: 46,
            errorBuilder: (_, __, ___) => _buildInitialAvatar(initial, accent)),
        ),
      );
    }
    return _buildInitialAvatar(initial, accent);
  }

  Widget _buildInitialAvatar(String initial, Color accent) {
    return Container(
      width: 46, height: 46,
      decoration: BoxDecoration(
        color: accent.withOpacity(0.12),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Center(
        child: Text(initial, style: GoogleFonts.inriaSerif(
          fontSize: 18, fontWeight: FontWeight.bold, color: accent)),
      ),
    );
  }

  Widget _buildStatCard(String value, String label, {VoidCallback? onTap, bool locked = false}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 10),
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
                ? FaIcon(FontAwesomeIcons.lock, size: 28, color: Colors.grey.shade400)
                : Text(
                    value,
                    style: GoogleFonts.inriaSerif(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: _shopPrimary,
                    ),
                  ),
            const SizedBox(height: 4),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.inriaSerif(
                fontSize: 12,
                color: locked ? Colors.grey.shade900 : Colors.grey.shade900,
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
                    : _shopPrimary.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              alignment: Alignment.center,
              child: FaIcon(
                icon,
                color: locked ? Colors.grey.shade900 : _shopPrimary,
                size: 20,
              ),
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
                      color: locked ? Colors.grey.shade900 : Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: GoogleFonts.inriaSerif(
                      fontSize: 13,
                      color: Colors.grey.shade800,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              locked ? FontAwesomeIcons.lock : FontAwesomeIcons.chevronRight,
              color: Colors.grey.shade900,
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
        gradient: LinearGradient(
          colors: [_shopPrimary, _shopPrimary],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: _shopPrimary.withOpacity(0.3),
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
                  alignment: Alignment.center,
                  child: const FaIcon(
                    FontAwesomeIcons.rightToBracket,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Se connecter',
                        style: GoogleFonts.inriaSerif(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Synchronisez vos donnees',
                        style: GoogleFonts.inriaSerif(
                          fontSize: 13,
                          color: Colors.white.withOpacity(0.8),
                        ),
                      ),
                    ],
                  ),
                ),
                FaIcon(
                  FontAwesomeIcons.chevronRight,
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
                  alignment: Alignment.center,
                  child: FaIcon(
                    FontAwesomeIcons.rightFromBracket,
                    color: Colors.red.shade700,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Deconnexion',
                        style: GoogleFonts.inriaSerif(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Colors.red.shade700,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Se deconnecter de ce compte',
                        style: GoogleFonts.inriaSerif(
                          fontSize: 13,
                          color: Colors.grey.shade800,
                        ),
                      ),
                    ],
                  ),
                ),
                FaIcon(
                  FontAwesomeIcons.chevronRight,
                  color: Colors.grey.shade900,
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
