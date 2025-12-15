import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'loyalty_card_page.dart';
import '../../../services/loyalty_service.dart';
import '../../../services/models/shop_model.dart';
import '../../../services/shop_service.dart';
import '../home/home_online_screen.dart';

/// Page de création de carte de fidélité
class CreateLoyaltyCardPage extends StatefulWidget {
  final int shopId;
  final String boutiqueName;
  final Shop? shop; // Objet Shop pour récupérer le thème

  const CreateLoyaltyCardPage({
    super.key,
    required this.shopId,
    required this.boutiqueName,
    this.shop,
  });

  @override
  State<CreateLoyaltyCardPage> createState() => _CreateLoyaltyCardPageState();
}

class _CreateLoyaltyCardPageState extends State<CreateLoyaltyCardPage> {
  final _formKey = GlobalKey<FormState>();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _pinController = TextEditingController();

  bool _isLoading = false;
  Shop? _loadedShop;

  @override
  void initState() {
    super.initState();
    // Charger le shop depuis l'API si pas fourni
    if (widget.shop == null) {
      _loadShop();
    }
  }

  Future<void> _loadShop() async {
    try {
      final shop = await ShopService.getShopById(widget.shopId);
      if (mounted) {
        setState(() {
          _loadedShop = shop;
        });
      }
    } catch (e) {
      print('❌ Erreur chargement shop: $e');
      // Continuer avec le thème par défaut
    }
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _pinController.dispose();
    super.dispose();
  }

  Future<void> _createCard() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    // Nettoyer le numéro de téléphone (enlever espaces et tirets) - défini avant le try pour être accessible partout
    final cleanPhone = _phoneController.text.replaceAll(RegExp(r'[\s-]'), '');

    try {

      // Appeler l'API pour créer la carte
      final loyaltyCard = await LoyaltyService.createCard(
        shopId: widget.shopId,
        phone: cleanPhone,
        customerName: '${_firstNameController.text} ${_lastNameController.text}',
        email: _emailController.text.isNotEmpty ? _emailController.text : null,
        pinCode: _pinController.text.isNotEmpty ? _pinController.text : null,
      );

      if (!mounted) return;

      // Afficher message de succès
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Carte de fidélité créée avec succès!'),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 2),
        ),
      );

      // Naviguer vers la page de carte avec les données de l'API
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (context) => LoyaltyCardPage(
            loyaltyCard: loyaltyCard,
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;

      final errorMessage = e.toString().replaceAll('Exception: ', '');

      // Si la carte existe déjà, charger et afficher la carte existante
      if (errorMessage.contains('existe déjà') || errorMessage.contains('already exists')) {
        try {
          final existingCard = await LoyaltyService.getCard(
            shopId: widget.shopId,
            phone: cleanPhone,
          );

          if (!mounted) return;

          if (existingCard != null) {
            // Afficher message informatif
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Vous avez déjà une carte dans cette boutique!'),
                backgroundColor: Colors.orange,
                duration: const Duration(seconds: 2),
              ),
            );

            // Naviguer vers la carte existante
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(
                builder: (context) => LoyaltyCardPage(
                  loyaltyCard: existingCard,
                ),
              ),
            );
            return;
          }
        } catch (e2) {
          // Si on ne peut pas récupérer la carte, afficher l'erreur originale
        }
      }

      // Afficher l'erreur
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(errorMessage),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 4),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Récupérer le thème de la boutique (widget.shop a priorité, sinon _loadedShop, sinon thème par défaut)
    final currentShop = widget.shop ?? _loadedShop;
    final shopTheme = currentShop?.theme ?? ShopTheme.defaultTheme();

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Container(
              color: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: Text(
                'Carte de fidélité',
                style: GoogleFonts.openSans(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),

            // Contenu
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Bannière de présentation
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [shopTheme.primary, shopTheme.secondary],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Icon(
                                Icons.credit_card,
                                color: Colors.white,
                                size: 32,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Créez votre carte de fidélité',
                                    style: GoogleFonts.openSans(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Bénéficiez de réductions, promotions et cumulez des points à chaque achat chez ${widget.boutiqueName}',
                                    style: GoogleFonts.openSans(
                                      fontSize: 13,
                                      color: Colors.white.withOpacity(0.9),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Formulaire
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Prénom
                            Text(
                              'Prénom *',
                              style: GoogleFonts.openSans(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 8),
                            TextFormField(
                              controller: _firstNameController,
                              decoration: InputDecoration(
                                hintText: 'Jean',
                                filled: true,
                                fillColor: Colors.grey.shade50,
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide.none,
                                ),
                              ),
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Veuillez entrer votre prénom';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 16),

                            // Nom
                            Text(
                              'Nom *',
                              style: GoogleFonts.openSans(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 8),
                            TextFormField(
                              controller: _lastNameController,
                              decoration: InputDecoration(
                                hintText: 'Dupont',
                                filled: true,
                                fillColor: Colors.grey.shade50,
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide.none,
                                ),
                              ),
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Veuillez entrer votre nom';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 16),

                            // Téléphone
                            Text(
                              'Numéro de téléphone *',
                              style: GoogleFonts.openSans(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 8),
                            TextFormField(
                              controller: _phoneController,
                              keyboardType: TextInputType.phone,
                              decoration: InputDecoration(
                                hintText: '+225 07 12 34 56 78',
                                helperText: 'Format international avec indicatif pays',
                                filled: true,
                                fillColor: Colors.grey.shade50,
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide.none,
                                ),
                              ),
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Veuillez entrer votre numéro de téléphone';
                                }
                                // Nettoyer le numéro (enlever espaces et tirets)
                                final cleanNumber = value.replaceAll(RegExp(r'[\s-]'), '');

                                // Vérifier que le numéro contient au moins des chiffres
                                if (cleanNumber.length < 8) {
                                  return 'Numéro de téléphone trop court';
                                }

                                return null;
                              },
                            ),
                            const SizedBox(height: 16),

                            // Email (optionnel)
                            Text(
                              'Email (optionnel)',
                              style: GoogleFonts.openSans(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 8),
                            TextFormField(
                              controller: _emailController,
                              keyboardType: TextInputType.emailAddress,
                              decoration: InputDecoration(
                                hintText: 'exemple@email.com',
                                filled: true,
                                fillColor: Colors.grey.shade50,
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide.none,
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),

                            // Code PIN (optionnel)
                            Text(
                              'Code PIN (optionnel)',
                              style: GoogleFonts.openSans(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Sécurisez votre carte avec un code PIN à 4 chiffres',
                              style: GoogleFonts.openSans(
                                fontSize: 12,
                                color: Colors.grey.shade600,
                              ),
                            ),
                            const SizedBox(height: 8),
                            TextFormField(
                              controller: _pinController,
                              keyboardType: TextInputType.number,
                              obscureText: true,
                              maxLength: 4,
                              decoration: InputDecoration(
                                hintText: '••••',
                                filled: true,
                                fillColor: Colors.grey.shade50,
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide.none,
                                ),
                                counterText: '',
                              ),
                              validator: (value) {
                                if (value != null && value.isNotEmpty && value.length != 4) {
                                  return 'Le code PIN doit contenir 4 chiffres';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 24),

                            // Bouton créer
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton(
                                onPressed: _isLoading ? null : _createCard,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: shopTheme.primary,
                                  padding: const EdgeInsets.symmetric(vertical: 16),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                child: _isLoading
                                    ? const SizedBox(
                                        width: 20,
                                        height: 20,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                        ),
                                      )
                                    : Text(
                                        'Créer ma carte de fidélité',
                                        style: GoogleFonts.openSans(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.white,
                                        ),
                                      ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Avantages de la carte
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Avantages de la carte',
                              style: GoogleFonts.openSans(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 16),
                            _buildAdvantageItem(
                              icon: Icons.discount,
                              text: 'Réductions exclusives sur vos achats',
                              color: const Color(0xFF8936A8),
                            ),
                            const SizedBox(height: 12),
                            _buildAdvantageItem(
                              icon: Icons.local_offer,
                              text: 'Promotions et offres spéciales',
                              color: const Color(0xFFFF9800),
                            ),
                            const SizedBox(height: 12),
                            _buildAdvantageItem(
                              icon: Icons.stars,
                              text: 'Cumul de points à chaque achat',
                              color: const Color(0xFF4CAF50),
                            ),
                            const SizedBox(height: 12),
                            _buildAdvantageItem(
                              icon: Icons.card_giftcard,
                              text: 'Cadeaux et récompenses fidélité',
                              color: const Color(0xFF2196F3),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Bouton retour à la boutique
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          onPressed: () {
                            // Retourner à la page de la boutique (HomeScreen)
                            final shop = widget.shop ?? _loadedShop;

                            // Remplacer la page actuelle par HomeScreen
                            Navigator.of(context).pushReplacement(
                              MaterialPageRoute(
                                builder: (context) => HomeScreen(
                                  shop: shop,
                                  shopId: widget.shopId,
                                ),
                              ),
                            );
                          },
                          icon: const Icon(Icons.storefront, size: 20),
                          label: Text(
                            'Retour à la boutique',
                            style: GoogleFonts.openSans(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: shopTheme.primary,
                            side: BorderSide(color: Colors.grey.shade300, width: 1.5),
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),
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

  Widget _buildAdvantageItem({
    required IconData icon,
    required String text,
    required Color color,
  }) {
    return Row(
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            text,
            style: GoogleFonts.openSans(
              fontSize: 14,
              color: Colors.grey.shade700,
            ),
          ),
        ),
      ],
    );
  }
}
