import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';

/// Écran d'aide et support
class HelpSupportScreen extends StatefulWidget {
  const HelpSupportScreen({super.key});

  @override
  State<HelpSupportScreen> createState() => _HelpSupportScreenState();
}

class _HelpSupportScreenState extends State<HelpSupportScreen> {
  final List<Map<String, dynamic>> _faqItems = [
    {
      'question': 'Comment passer une commande ?',
      'answer': 'Pour passer une commande, parcourez notre catalogue de produits, ajoutez les articles souhaités à votre panier, puis suivez le processus de paiement. Vous pouvez payer par carte bancaire, Mobile Money (Orange, Wave, Moov) ou en espèces à la livraison.',
      'isExpanded': false,
    },
    {
      'question': 'Quels sont les délais de livraison ?',
      'answer': 'Les délais de livraison varient selon votre localisation :\n\n• Dakar centre : 1-2 jours\n• Banlieue de Dakar : 2-3 jours\n• Régions : 3-5 jours\n\nVous recevrez une notification dès que votre commande sera expédiée.',
      'isExpanded': false,
    },
    {
      'question': 'Comment suivre ma commande ?',
      'answer': 'Vous pouvez suivre votre commande en temps réel depuis la section "Mes commandes" de votre profil. Vous recevrez également des notifications à chaque étape : confirmation, préparation, expédition et livraison.',
      'isExpanded': false,
    },
    {
      'question': 'Puis-je modifier ou annuler ma commande ?',
      'answer': 'Vous pouvez annuler votre commande gratuitement tant qu\'elle n\'a pas été préparée. Pour modifier une commande, contactez-nous via WhatsApp ou par téléphone. Les frais d\'annulation peuvent s\'appliquer si la commande est déjà en cours de préparation.',
      'isExpanded': false,
    },
    {
      'question': 'Quels moyens de paiement acceptez-vous ?',
      'answer': 'Nous acceptons plusieurs moyens de paiement :\n\n• Cartes bancaires (Visa, Mastercard)\n• Mobile Money (Orange Money, Wave, Moov Money)\n• Espèces à la livraison\n• Virement bancaire',
      'isExpanded': false,
    },
    {
      'question': 'Comment fonctionne le programme de fidélité ?',
      'answer': 'Notre programme de fidélité vous permet de cumuler des points à chaque achat. 1000 FCFA dépensés = 10 points. Utilisez vos points pour obtenir des réductions ou des cadeaux. Créez votre carte de fidélité depuis votre profil.',
      'isExpanded': false,
    },
    {
      'question': 'Que faire si mon article est défectueux ?',
      'answer': 'Si vous recevez un article défectueux ou endommagé, contactez-nous dans les 48h suivant la livraison. Nous organiserons un retour gratuit et un remboursement complet ou un échange selon votre préférence.',
      'isExpanded': false,
    },
    {
      'question': 'Comment retourner un article ?',
      'answer': 'Vous disposez de 14 jours pour retourner un article non utilisé dans son emballage d\'origine. Contactez notre service client pour initier le retour. Les frais de retour sont à votre charge sauf en cas de défaut.',
      'isExpanded': false,
    },
  ];

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
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: const Icon(Icons.arrow_back, size: 24),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Text(
                      'Aide et support',
                      style: GoogleFonts.openSans(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Contenu
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Carte d'accueil
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF8936A8), Color(0xFFD48EFC)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF8936A8).withOpacity(0.3),
                            blurRadius: 15,
                            offset: const Offset(0, 5),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          const Icon(
                            Icons.support_agent,
                            color: Colors.white,
                            size: 48,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Comment pouvons-nous vous aider ?',
                            textAlign: TextAlign.center,
                            style: GoogleFonts.openSans(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Notre équipe est disponible du lundi au samedi de 8h à 20h',
                            textAlign: TextAlign.center,
                            style: GoogleFonts.openSans(
                              fontSize: 14,
                              color: Colors.white.withOpacity(0.9),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Moyens de contact
                    Text(
                      'Contactez-nous',
                      style: GoogleFonts.openSans(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey.shade800,
                      ),
                    ),
                    const SizedBox(height: 12),

                    Row(
                      children: [
                        Expanded(
                          child: _buildContactCard(
                            icon: Icons.phone,
                            title: 'Téléphone',
                            subtitle: '+221 33 123 45 67',
                            color: const Color(0xFF4CAF50),
                            onTap: () => _makePhoneCall('+221331234567'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildContactCard(
                            icon: Icons.chat_bubble,
                            title: 'WhatsApp',
                            subtitle: 'Chat en direct',
                            color: const Color(0xFF25D366),
                            onTap: () => _openWhatsApp(),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 12),

                    Row(
                      children: [
                        Expanded(
                          child: _buildContactCard(
                            icon: Icons.email,
                            title: 'Email',
                            subtitle: 'support@tika.sn',
                            color: const Color(0xFF2196F3),
                            onTap: () => _sendEmail(),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildContactCard(
                            icon: Icons.language,
                            title: 'Site web',
                            subtitle: 'www.tika.sn',
                            color: const Color(0xFF8936A8),
                            onTap: () => _openWebsite(),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 32),

                    // FAQ
                    Text(
                      'Questions fréquentes (FAQ)',
                      style: GoogleFonts.openSans(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey.shade800,
                      ),
                    ),
                    const SizedBox(height: 12),

                    Container(
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
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: ExpansionPanelList(
                          elevation: 0,
                          expandedHeaderPadding: EdgeInsets.zero,
                          expansionCallback: (int index, bool isExpanded) {
                            setState(() {
                              _faqItems[index]['isExpanded'] = !isExpanded;
                            });
                          },
                          children: _faqItems.map<ExpansionPanel>((item) {
                            return ExpansionPanel(
                              canTapOnHeader: true,
                              backgroundColor: Colors.white,
                              headerBuilder: (BuildContext context, bool isExpanded) {
                                return ListTile(
                                  title: Text(
                                    item['question'],
                                    style: GoogleFonts.openSans(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.black87,
                                    ),
                                  ),
                                );
                              },
                              body: Padding(
                                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                                child: Align(
                                  alignment: Alignment.centerLeft,
                                  child: Text(
                                    item['answer'],
                                    style: GoogleFonts.openSans(
                                      fontSize: 14,
                                      color: Colors.grey.shade700,
                                      height: 1.5,
                                    ),
                                  ),
                                ),
                              ),
                              isExpanded: item['isExpanded'],
                            );
                          }).toList(),
                        ),
                      ),
                    ),

                    const SizedBox(height: 32),

                    // Ressources supplémentaires
                    Text(
                      'Ressources utiles',
                      style: GoogleFonts.openSans(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey.shade800,
                      ),
                    ),
                    const SizedBox(height: 12),

                    _buildResourceOption(
                      icon: Icons.description_outlined,
                      title: 'Guide d\'utilisation',
                      subtitle: 'Comment utiliser l\'application',
                      onTap: () => _showGuideDialog(),
                    ),

                    const SizedBox(height: 12),

                    _buildResourceOption(
                      icon: Icons.local_shipping_outlined,
                      title: 'Politique de livraison',
                      subtitle: 'Délais et zones de livraison',
                      onTap: () => _showDeliveryPolicyDialog(),
                    ),

                    const SizedBox(height: 12),

                    _buildResourceOption(
                      icon: Icons.refresh_outlined,
                      title: 'Politique de retour',
                      subtitle: 'Conditions de retour et remboursement',
                      onTap: () => _showReturnPolicyDialog(),
                    ),

                    const SizedBox(height: 12),

                    _buildResourceOption(
                      icon: Icons.announcement_outlined,
                      title: 'Signaler un problème',
                      subtitle: 'Bugs, suggestions, réclamations',
                      onTap: () => _showReportDialog(),
                    ),

                    const SizedBox(height: 32),

                    // Réseaux sociaux
                    Center(
                      child: Column(
                        children: [
                          Text(
                            'Suivez-nous sur',
                            style: GoogleFonts.openSans(
                              fontSize: 14,
                              color: Colors.grey.shade600,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              _buildSocialButton(Icons.facebook, const Color(0xFF1877F2)),
                              const SizedBox(width: 12),
                              _buildSocialButton(Icons.camera_alt, const Color(0xFFE4405F)),
                              const SizedBox(width: 12),
                              _buildSocialButton(Icons.play_arrow, const Color(0xFFFF0000)),
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
    );
  }

  Widget _buildContactCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
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
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(height: 12),
            Text(
              title,
              style: GoogleFonts.openSans(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: GoogleFonts.openSans(
                fontSize: 11,
                color: Colors.grey.shade600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResourceOption({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Container(
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
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF8936A8).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
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
                          fontSize: 15,
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
        ),
      ),
    );
  }

  Widget _buildSocialButton(IconData icon, Color color) {
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        shape: BoxShape.circle,
      ),
      child: IconButton(
        icon: Icon(icon, color: color),
        onPressed: () {
          _showConfirmationSnackBar('Fonctionnalité bientôt disponible');
        },
      ),
    );
  }

  Future<void> _makePhoneCall(String phoneNumber) async {
    final Uri phoneUri = Uri(scheme: 'tel', path: phoneNumber);
    if (await canLaunchUrl(phoneUri)) {
      await launchUrl(phoneUri);
    } else {
      _showConfirmationSnackBar('Impossible d\'ouvrir l\'application téléphone');
    }
  }

  Future<void> _openWhatsApp() async {
    final Uri whatsappUri = Uri.parse('https://wa.me/221331234567');
    if (await canLaunchUrl(whatsappUri)) {
      await launchUrl(whatsappUri, mode: LaunchMode.externalApplication);
    } else {
      _showConfirmationSnackBar('Impossible d\'ouvrir WhatsApp');
    }
  }

  Future<void> _sendEmail() async {
    final Uri emailUri = Uri(
      scheme: 'mailto',
      path: 'support@tika.sn',
      query: 'subject=Demande de support',
    );
    if (await canLaunchUrl(emailUri)) {
      await launchUrl(emailUri);
    } else {
      _showConfirmationSnackBar('Impossible d\'ouvrir l\'application email');
    }
  }

  Future<void> _openWebsite() async {
    final Uri websiteUri = Uri.parse('https://www.tika.sn');
    if (await canLaunchUrl(websiteUri)) {
      await launchUrl(websiteUri, mode: LaunchMode.externalApplication);
    } else {
      _showConfirmationSnackBar('Impossible d\'ouvrir le site web');
    }
  }

  void _showGuideDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Guide d\'utilisation',
          style: GoogleFonts.openSans(fontWeight: FontWeight.bold),
        ),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildGuideStep('1', 'Créez votre compte', 'Inscrivez-vous avec votre email et numéro de téléphone'),
              _buildGuideStep('2', 'Parcourez le catalogue', 'Explorez nos produits par catégorie'),
              _buildGuideStep('3', 'Ajoutez au panier', 'Sélectionnez vos articles préférés'),
              _buildGuideStep('4', 'Passez commande', 'Choisissez votre mode de paiement'),
              _buildGuideStep('5', 'Suivez votre livraison', 'Recevez vos produits à domicile'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Fermer', style: GoogleFonts.openSans()),
          ),
        ],
      ),
    );
  }

  Widget _buildGuideStep(String number, String title, String description) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: const BoxDecoration(
              color: Color(0xFF8936A8),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                number,
                style: GoogleFonts.openSans(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.openSans(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
                Text(
                  description,
                  style: GoogleFonts.openSans(
                    fontSize: 13,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showDeliveryPolicyDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Politique de livraison',
          style: GoogleFonts.openSans(fontWeight: FontWeight.bold),
        ),
        content: SingleChildScrollView(
          child: Text(
            'ZONES ET DÉLAIS DE LIVRAISON\n\n'
            'Dakar Plateau : 1-2 jours ouvrables\n'
            'Banlieue de Dakar : 2-3 jours ouvrables\n'
            'Thiès, Mbour, Saint-Louis : 3-4 jours\n'
            'Autres régions : 4-5 jours\n\n'
            'FRAIS DE LIVRAISON\n\n'
            'Gratuit pour les commandes > 50 000 FCFA\n'
            'Dakar : 2 000 FCFA\n'
            'Banlieue : 3 000 FCFA\n'
            'Régions : 5 000 FCFA\n\n'
            'La livraison est assurée du lundi au samedi de 9h à 18h.',
            style: GoogleFonts.openSans(fontSize: 14, height: 1.5),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Fermer', style: GoogleFonts.openSans()),
          ),
        ],
      ),
    );
  }

  void _showReturnPolicyDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Politique de retour',
          style: GoogleFonts.openSans(fontWeight: FontWeight.bold),
        ),
        content: SingleChildScrollView(
          child: Text(
            'CONDITIONS DE RETOUR\n\n'
            'Vous disposez de 14 jours pour retourner un article :\n\n'
            '• Article non utilisé et dans son emballage d\'origine\n'
            '• Avec preuve d\'achat (facture)\n'
            '• Produits non alimentaires uniquement\n\n'
            'PROCÉDURE\n\n'
            '1. Contactez notre service client\n'
            '2. Obtenez un numéro de retour\n'
            '3. Renvoyez l\'article\n'
            '4. Recevez votre remboursement sous 7 jours\n\n'
            'REMBOURSEMENT\n\n'
            'Le remboursement est effectué par le même moyen de paiement utilisé lors de l\'achat.',
            style: GoogleFonts.openSans(fontSize: 14, height: 1.5),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Fermer', style: GoogleFonts.openSans()),
          ),
        ],
      ),
    );
  }

  void _showReportDialog() {
    final subjectController = TextEditingController();
    final messageController = TextEditingController();
    String selectedCategory = 'Bug technique';

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(
            'Signaler un problème',
            style: GoogleFonts.openSans(fontWeight: FontWeight.bold),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<String>(
                  value: selectedCategory,
                  decoration: InputDecoration(
                    labelText: 'Catégorie',
                    labelStyle: GoogleFonts.openSans(),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  items: [
                    'Bug technique',
                    'Problème de commande',
                    'Problème de paiement',
                    'Suggestion',
                    'Réclamation',
                    'Autre',
                  ].map((category) {
                    return DropdownMenuItem(
                      value: category,
                      child: Text(category, style: GoogleFonts.openSans()),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setDialogState(() {
                      selectedCategory = value!;
                    });
                  },
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: subjectController,
                  decoration: InputDecoration(
                    labelText: 'Sujet',
                    labelStyle: GoogleFonts.openSans(),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: messageController,
                  maxLines: 4,
                  decoration: InputDecoration(
                    labelText: 'Description du problème',
                    labelStyle: GoogleFonts.openSans(),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                'Annuler',
                style: GoogleFonts.openSans(color: Colors.grey),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                _showConfirmationSnackBar('Votre signalement a été envoyé. Nous vous répondrons sous 24h.');
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF8936A8),
                foregroundColor: Colors.white,
              ),
              child: Text('Envoyer', style: GoogleFonts.openSans()),
            ),
          ],
        ),
      ),
    );
  }

  void _showConfirmationSnackBar(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            message,
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
  }
}
