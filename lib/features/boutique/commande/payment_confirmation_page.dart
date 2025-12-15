import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/messages/message_modal.dart';
import '../../../core/services/boutique_theme_provider.dart';

/// Page de confirmation de paiement (PIN ou Carte)
class PaymentConfirmationPage extends StatefulWidget {
  final Map<String, dynamic> paymentData;
  final int total;
  final bool isCard;
  final VoidCallback onConfirm;

  const PaymentConfirmationPage({
    super.key,
    required this.paymentData,
    required this.total,
    required this.isCard,
    required this.onConfirm,
  });

  @override
  State<PaymentConfirmationPage> createState() => _PaymentConfirmationPageState();
}

class _PaymentConfirmationPageState extends State<PaymentConfirmationPage> with WidgetsBindingObserver {
  final _cardNumberController = TextEditingController();
  final _cardHolderController = TextEditingController();
  final _expiryController = TextEditingController();
  final _cvvController = TextEditingController();
  bool _hasLaunchedUSSD = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    // Redirection USSD désactivée - l'utilisateur validera manuellement
    // if (!widget.isCard) {
    //   _launchMobileMoneyPayment();
    // }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _cardNumberController.dispose();
    _cardHolderController.dispose();
    _expiryController.dispose();
    _cvvController.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Détecter quand l'utilisateur revient à l'app après avoir utilisé USSD
    if (state == AppLifecycleState.resumed && _hasLaunchedUSSD) {
      // Simuler un retour réussi après USSD
      Future.delayed(const Duration(milliseconds: 500), () {
        if (mounted) {
          Navigator.pop(context);
          widget.onConfirm();
        }
      });
    }
  }

  // Lancer le paiement Mobile Money via USSD
  Future<void> _launchMobileMoneyPayment() async {
    setState(() {
      _hasLaunchedUSSD = true;
    });

    // Codes USSD pour chaque service
    String ussdCode = '';
    final paymentName = widget.paymentData['name'] as String;

    if (paymentName.contains('Orange')) {
      ussdCode = '*144*4*6#'; // Exemple: Orange Money
    } else if (paymentName.contains('Wave')) {
      ussdCode = '*145#'; // Exemple: Wave
    } else if (paymentName.contains('Moov')) {
      ussdCode = '*155#'; // Exemple: Moov Money
    }

    try {
      final Uri ussdUri = Uri(scheme: 'tel', path: Uri.encodeComponent(ussdCode));
      if (await canLaunchUrl(ussdUri)) {
        await launchUrl(ussdUri);
      } else {
        if (mounted) {
          showErrorModal(context, 'Impossible de lancer le paiement mobile');
        }
      }
    } catch (e) {
      if (mounted) {
        showErrorModal(context, 'Erreur lors du lancement du paiement');
      }
    }
  }

  void _handleCardValidation() {
    // Validation pour carte bancaire (simple check non vide)
    if (_cardNumberController.text.isEmpty ||
        _cardHolderController.text.isEmpty ||
        _expiryController.text.isEmpty ||
        _cvvController.text.isEmpty) {
      showErrorModal(context, 'Veuillez remplir tous les champs');
      return;
    }

    // Fermer la page et lancer le traitement
    Navigator.pop(context);
    widget.onConfirm();
  }

  @override
  Widget build(BuildContext context) {
    // Si c'est mobile money, afficher un écran de confirmation
    if (!widget.isCard) {
      return Scaffold(
        body: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.white,
                widget.paymentData['color'].withOpacity(0.1),
              ],
            ),
          ),
          child: SafeArea(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Paiement ${widget.paymentData['name']}',
                    style: GoogleFonts.openSans(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 40),
                    child: Text(
                      'Montant: ${widget.total} FCFA',
                      style: GoogleFonts.openSans(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: widget.paymentData['color'],
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  const SizedBox(height: 40),
                  // Bouton Confirmer
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 40),
                    child: SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.pop(context);
                          widget.onConfirm();
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: widget.paymentData['color'],
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Text(
                          'Confirmer le paiement',
                          style: GoogleFonts.openSans(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text(
                      'Annuler',
                      style: GoogleFonts.openSans(
                        fontSize: 16,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    // Pour carte bancaire, afficher le formulaire
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: const Icon(Icons.arrow_back, size: 24),
                  ),
                  const SizedBox(width: 16),
                  Text(
                    'Finaliser la commande',
                    style: GoogleFonts.openSans(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),

            // Indicateur d'étapes
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: Row(
                children: [
                  _buildSmallStepIndicator(1, 'Informations', true),
                  Expanded(child: Container(height: 2, color: BoutiqueThemeProvider.of(context).primary)),
                  _buildSmallStepIndicator(2, 'Livraison', true),
                  Expanded(child: Container(height: 2, color: BoutiqueThemeProvider.of(context).primary)),
                  _buildSmallStepIndicator(3, 'Paiement', true),
                ],
              ),
            ),

            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: _buildCardForm(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSmallStepIndicator(int step, String label, bool isActive) {
    return Column(
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: isActive ? BoutiqueThemeProvider.of(context).primary : Colors.grey.shade300,
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Text(
              '$step',
              style: GoogleFonts.openSans(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: GoogleFonts.openSans(
            fontSize: 10,
            color: Colors.grey.shade600,
          ),
        ),
      ],
    );
  }

  // Formulaire Carte Bancaire
  Widget _buildCardForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Informations de la carte',
          style: GoogleFonts.openSans(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 20),

        // Numéro de carte
        Text('Numéro de carte *', style: GoogleFonts.openSans(fontSize: 13, fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        TextField(
          controller: _cardNumberController,
          keyboardType: TextInputType.number,
          decoration: InputDecoration(
            hintText: '1234 5678 9012 3456',
            filled: true,
            fillColor: Colors.grey.shade50,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
          ),
        ),
        const SizedBox(height: 16),

        // Nom du titulaire
        Text('Nom du titulaire *', style: GoogleFonts.openSans(fontSize: 13, fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        TextField(
          controller: _cardHolderController,
          decoration: InputDecoration(
            hintText: 'JEAN DUPONT',
            filled: true,
            fillColor: Colors.grey.shade50,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
          ),
        ),
        const SizedBox(height: 16),

        // Date expiration et CVV
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Date d\'expiration *', style: GoogleFonts.openSans(fontSize: 13, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _expiryController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      hintText: 'MM/AA',
                      filled: true,
                      fillColor: Colors.grey.shade50,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.grey.shade300),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('CVV *', style: GoogleFonts.openSans(fontSize: 13, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _cvvController,
                    keyboardType: TextInputType.number,
                    maxLength: 3,
                    decoration: InputDecoration(
                      hintText: '123',
                      filled: true,
                      fillColor: Colors.grey.shade50,
                      counterText: '',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.grey.shade300),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),

        // Carte visuelle
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: const Color(0xFF2C3E50),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.credit_card, color: Colors.white, size: 32),
              const SizedBox(height: 24),
              Text('Numéro de carte', style: GoogleFonts.openSans(fontSize: 11, color: Colors.grey.shade400)),
              const SizedBox(height: 4),
              Text(
                _cardNumberController.text.isEmpty ? '•••• •••• •••• ••••' : _cardNumberController.text,
                style: GoogleFonts.openSans(fontSize: 16, color: Colors.white, letterSpacing: 2),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Titulaire', style: GoogleFonts.openSans(fontSize: 11, color: Colors.grey.shade400)),
                      const SizedBox(height: 4),
                      Text(
                        _cardHolderController.text.isEmpty ? 'NOM PRÉNOM' : _cardHolderController.text.toUpperCase(),
                        style: GoogleFonts.openSans(fontSize: 14, color: Colors.white, fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text('Expire', style: GoogleFonts.openSans(fontSize: 11, color: Colors.grey.shade400)),
                      const SizedBox(height: 4),
                      Text(
                        _expiryController.text.isEmpty ? 'MM/AA' : _expiryController.text,
                        style: GoogleFonts.openSans(fontSize: 14, color: Colors.white, fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),

        // Récapitulatif
        Text('Récapitulatif', style: GoogleFonts.openSans(fontSize: 16, fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Sous-total', style: GoogleFonts.openSans(fontSize: 14)),
            Text('${widget.total} FCFA', style: GoogleFonts.openSans(fontSize: 14)),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Total', style: GoogleFonts.openSans(fontSize: 16, fontWeight: FontWeight.bold)),
            Text(
              '${widget.total} FCFA',
              style: GoogleFonts.openSans(fontSize: 18, fontWeight: FontWeight.bold, color: BoutiqueThemeProvider.of(context).primary),
            ),
          ],
        ),
        const SizedBox(height: 24),

        // Bouton payer
        SizedBox(
          width: double.infinity,
          child: InkWell(
            onTap: _handleCardValidation,
            borderRadius: BorderRadius.circular(12),
            child: Container(
              height: 56,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [const Color(0xFFD48EFC), BoutiqueThemeProvider.of(context).primary],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: BoutiqueThemeProvider.of(context).primary.withOpacity(0.4),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Center(
                child: Text(
                  'Payer ${widget.total} FCFA',
                  style: GoogleFonts.openSans(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
