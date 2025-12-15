import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'personal_info_screen.dart';
import 'addresses_screen.dart';
import 'payment_methods_screen.dart';
import 'notifications_screen.dart';
import 'help_support_screen.dart';
import '../../../core/services/storage_service.dart';

/// Écran de profil client - Conforme à l'API TIKA
/// Les clients N'ONT PAS de compte, les infos sont stockées localement
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

  @override
  void initState() {
    super.initState();
    _loadCustomerData();
  }

  Future<void> _loadCustomerData() async {
    final customerInfo = await StorageService.getCustomerInfo();
    final orders = await StorageService.getOrders();
    final favorites = await StorageService.getFavoriteShopIds();
    final loyaltyCard = await StorageService.getLoyaltyCard();

    setState(() {
      _customerName = customerInfo['name'] ?? 'Client';
      _customerPhone = customerInfo['phone'] ?? '';
      _customerEmail = customerInfo['email'] ?? '';
      _ordersCount = orders.length;
      _favoritesCount = favorites.length;
      _loyaltyPoints = loyaltyCard?['points'] ?? 0;
    });
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
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Header violet avec dégradé
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
                // Barre de navigation avec flèche retour
                SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
                    child: Row(
                      children: [
                        // Bouton retour
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
                        // Espace vide pour centrer le titre
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
                          // Avatar avec initiales
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
                              child: Text(
                                _getInitials(_customerName),
                                style: GoogleFonts.openSans(
                                  fontSize: 36,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),

                          const SizedBox(height: 20),

                          // Nom
                          Text(
                            _customerName.isEmpty ? 'Bienvenue' : _customerName,
                            style: GoogleFonts.openSans(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                          ),

                          const SizedBox(height: 12),

                          // Email (si renseigné)
                          if (_customerEmail.isNotEmpty)
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

                          if (_customerEmail.isNotEmpty) const SizedBox(height: 8),

                          // Téléphone (si renseigné)
                          if (_customerPhone.isNotEmpty)
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
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Statistiques (Commandes, Favoris, Points)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Row(
                      children: [
                        Expanded(
                          child: _buildStatCard(_ordersCount.toString(), _ordersCount > 1 ? 'Commandes' : 'Commande'),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildStatCard(_favoritesCount.toString(), 'Favoris'),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildStatCard(_loyaltyPoints.toString(), 'Points'),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Carte de fidélité
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
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
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.credit_card, color: Colors.white, size: 24),
                              const SizedBox(width: 12),
                              Text(
                                'Programme de fidélité',
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
                                : 'Créez une carte pour gagner des points',
                            style: GoogleFonts.openSans(
                              fontSize: 14,
                              color: Colors.white.withOpacity(0.9),
                            ),
                          ),

                          const SizedBox(height: 20),

                          ElevatedButton(
                            onPressed: () {},
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
                          title: 'Informations personnelles',
                          subtitle: 'Nom, téléphone, email',
                          onTap: () async {
                            final result = await Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const PersonalInfoScreen(),
                              ),
                            );
                            // Recharger les données si modifiées
                            if (result == true) {
                              _loadCustomerData();
                            }
                          },
                        ),
                        const SizedBox(height: 12),
                        _buildMenuOption(
                          icon: Icons.location_on_outlined,
                          title: 'Adresses de livraison',
                          subtitle: 'Gérer vos adresses',
                          onTap: () {
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
                          icon: Icons.credit_card_outlined,
                          title: 'Moyens de paiement',
                          subtitle: 'Cartes et Mobile Money',
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const PaymentMethodsScreen(),
                              ),
                            );
                          },
                        ),
                        const SizedBox(height: 12),
                        _buildMenuOption(
                          icon: Icons.notifications_outlined,
                          title: 'Notifications',
                          subtitle: 'Gérer vos alertes',
                          onTap: () {
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
                          title: 'Aide et support',
                          subtitle: 'FAQ, contact',
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
                    '© 2025 Tika. Tous droits réservés.',
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

  Widget _buildStatCard(String value, String label) {
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
          Text(
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
              color: Colors.grey.shade700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuOption({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
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
                color: const Color(0xFF8936A8).withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                color: const Color(0xFF8936A8),
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
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
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
    );
  }
}
