import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'form_widgets.dart';
import '../../../core/services/boutique_theme_provider.dart';

/// Étape 1 : Informations client
class Step1ClientInfo extends StatelessWidget {
  final GlobalKey<FormState> formKey;
  final TextEditingController nomController;
  final TextEditingController emailController;
  final TextEditingController phoneController;
  final TextEditingController addressController;

  const Step1ClientInfo({
    super.key,
    required this.formKey,
    required this.nomController,
    required this.emailController,
    required this.phoneController,
    required this.addressController,
  });

  @override
  Widget build(BuildContext context) {
    return Form(
      key: formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Informations de contact',
            style: GoogleFonts.openSans(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Veuillez remplir vos informations pour la livraison',
            style: GoogleFonts.openSans(
              fontSize: 15,
              color: Colors.grey.shade600,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 28),

          // Nom complet
          FormFieldWidget(
            controller: nomController,
            label: 'Nom complet',
            hint: 'Entrez votre nom complet',
            icon: Icons.person_outline,
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'[a-zA-ZÀ-ÿ\s]')), // Lettres et espaces uniquement
            ],
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Veuillez entrer votre nom';
              }
              if (!RegExp(r'^[a-zA-ZÀ-ÿ\s]+$').hasMatch(value)) {
                return 'Le nom ne doit contenir que des lettres';
              }
              return null;
            },
          ),

          const SizedBox(height: 22),

          // Email
          FormFieldWidget(
            controller: emailController,
            label: 'Email (optionnel)',
            hint: 'example@email.com',
            icon: Icons.email_outlined,
            required: false,
            keyboardType: TextInputType.emailAddress,
            validator: (value) {
              if (value != null && value.isNotEmpty && !value.contains('@')) {
                return 'Email invalide';
              }
              return null;
            },
          ),

          const SizedBox(height: 22),

          // Numéro de téléphone
          FormFieldWidget(
            controller: phoneController,
            label: 'Numéro de téléphone',
            hint: '07 XX XX XX XX',
            icon: Icons.phone_outlined,
            keyboardType: TextInputType.phone,
            maxLength: 10,
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly, // Chiffres uniquement
            ],
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Veuillez entrer votre numéro';
              }
              // Nettoyer le numéro (enlever espaces, tirets, parenthèses)
              final cleanedNumber = value.replaceAll(RegExp(r'[\s\-\(\)\.]'), '');
              // Vérifier que le numéro contient uniquement des chiffres
              final phoneRegex = RegExp(r'^[0-9]+$');
              if (!phoneRegex.hasMatch(cleanedNumber)) {
                return 'Le numéro ne doit contenir que des chiffres';
              }
              // Vérifier que le numéro fait exactement 10 chiffres
              if (cleanedNumber.length != 10) {
                return 'Le numéro doit contenir exactement 10 chiffres';
              }
              // Vérifier que c'est un numéro ivoirien valide (commence par 01, 05, 07, 25, 27)
              final ivoirianPrefixes = ['01', '05', '07', '25', '27'];
              final prefix = cleanedNumber.substring(0, 2);
              if (!ivoirianPrefixes.contains(prefix)) {
                return 'Numéro ivoirien invalide (doit commencer par 01, 05, 07, 25 ou 27)';
              }
              return null;
            },
          ),
        ],
      ),
    );
  }
}

/// Étape 2 : Mode de livraison
class Step2DeliveryMode extends StatelessWidget {
  final String? selectedDeliveryMode;
  final Function(String) onDeliveryModeChanged;
  final TextEditingController addressController;
  final DateTime? selectedPickupDate;
  final TimeOfDay? selectedPickupTime;
  final Function(DateTime)? onPickupDateChanged;
  final Function(TimeOfDay)? onPickupTimeChanged;

  const Step2DeliveryMode({
    super.key,
    required this.selectedDeliveryMode,
    required this.onDeliveryModeChanged,
    required this.addressController,
    this.selectedPickupDate,
    this.selectedPickupTime,
    this.onPickupDateChanged,
    this.onPickupTimeChanged,
  });

  Future<void> _selectPickupDate(BuildContext context) async {
    final DateTime now = DateTime.now();
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: selectedPickupDate ?? now,
      firstDate: now,
      lastDate: now.add(const Duration(days: 30)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: BoutiqueThemeProvider.of(context).primary,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null && onPickupDateChanged != null) {
      onPickupDateChanged!(picked);
    }
  }

  Future<void> _selectPickupTime(BuildContext context) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: selectedPickupTime ?? TimeOfDay.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: BoutiqueThemeProvider.of(context).primary,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null && onPickupTimeChanged != null) {
      onPickupTimeChanged!(picked);
    }
  }

  String _formatDate(DateTime? date) {
    if (date == null) return 'Sélectionner une date';
    final months = ['jan', 'fév', 'mar', 'avr', 'mai', 'juin', 'juil', 'août', 'sep', 'oct', 'nov', 'déc'];
    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }

  String _formatTime(TimeOfDay? time) {
    if (time == null) return 'Sélectionner une heure';
    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Mode de Récupération',
          style: GoogleFonts.openSans(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Choisissez comment vous souhaitez recevoir votre commande',
          style: GoogleFonts.openSans(
            fontSize: 15,
            color: Colors.grey.shade600,
            height: 1.4,
          ),
        ),
        const SizedBox(height: 28),

        // Option Livraison
        DeliveryOption(
          id: 'Livraison',
          title: 'Livraison',
          description: 'Livraison rapide à votre domicile',
          icon: Icons.local_shipping,
          iconColor: BoutiqueThemeProvider.of(context).primary,
          isSelected: selectedDeliveryMode == 'Livraison',
          onTap: () => onDeliveryModeChanged('Livraison'),
        ),

        const SizedBox(height: 16),

        // Option En boutique
        DeliveryOption(
          id: 'En boutique',
          title: 'En boutique',
          description: 'Récupérez votre commande en boutique',
          icon: Icons.store,
          iconColor: const Color(0xFF10B981),
          isSelected: selectedDeliveryMode == 'En boutique',
          onTap: () => onDeliveryModeChanged('En boutique'),
        ),

        // Champ d'adresse conditionnel (affiché seulement si Livraison est sélectionnée)
        if (selectedDeliveryMode == 'Livraison') ...[
          const SizedBox(height: 28),

          // Adresse de livraison
          FormFieldWidget(
            controller: addressController,
            label: 'Adresse de livraison',
            hint: 'Entrez votre adresse complète (quartier, rue, repère...)',
            icon: Icons.location_on_outlined,
            maxLines: 2,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Veuillez entrer votre adresse';
              }
              // Vérifier que l'adresse contient au moins un quartier ou une ville connu(e)
              final lowerValue = value.toLowerCase();

              // Liste des communes et quartiers d'Abidjan
              final abidjanLocations = [
                'cocody', 'yopougon', 'abobo', 'adjamé', 'plateau', 'treichville',
                'marcory', 'koumassi', 'port-bouët', 'attécoubé', 'anyama', 'bingerville',
                'songon', 'angré', 'riviera', 'deux plateaux', '2 plateaux', 'vallon',
                'blockhaus', 'adjamé', 'williamsville', 'niangon', 'sicogi', 'aghien',
                'akouedo', 'banco', 'gonzagueville', 'zone 4', 'zone 3', 'zone 2', 'zone 1',
                'ancien carrefour', 'carrefour vie', 'millionnaire', 'mosquée', 'génie',
                'dokui', 'wassakara', 'avocatier', 'maroc', 'ananeraie', 'sideci',
                'vridi', 'kennedy', 'biafra', 'siporex', 'terminus', 'abattoir'
              ];

              // Autres villes de Côte d'Ivoire
              final otherCities = [
                'bouaké', 'daloa', 'korhogo', 'yamoussoukro', 'san-pedro', 'san pedro',
                'man', 'divo', 'gagnoa', 'soubré', 'bondoukou', 'sassandra'
              ];

              final allLocations = [...abidjanLocations, ...otherCities];

              // Vérifier si l'adresse contient au moins une localisation connue
              final hasValidLocation = allLocations.any((location) => lowerValue.contains(location));

              if (!hasValidLocation && lowerValue.length < 20) {
                return 'Veuillez entrer une adresse valide avec le quartier';
              }

              // Rejeter les adresses trop courtes ou invalides
              if (value.trim().length < 5) {
                return 'L\'adresse est trop courte';
              }

              return null;
            },
          ),
        ],

        // Champs Date/Heure conditionnels (affichés seulement si En boutique est sélectionné)
        if (selectedDeliveryMode == 'En boutique') ...[
          const SizedBox(height: 28),

          Text(
            'Quand souhaitez-vous récupérer votre commande ?',
            style: GoogleFonts.openSans(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 16),

          // Sélection de date
          GestureDetector(
            onTap: () => _selectPickupDate(context),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: selectedPickupDate != null
                    ? BoutiqueThemeProvider.of(context).primary
                    : Colors.grey.shade300,
                  width: selectedPickupDate != null ? 2 : 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.calendar_today_outlined,
                    color: selectedPickupDate != null
                        ? BoutiqueThemeProvider.of(context).primary
                        : Colors.grey.shade600,
                    size: 22,
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Date de récupération',
                          style: GoogleFonts.openSans(
                            fontSize: 12,
                            color: Colors.grey.shade600,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _formatDate(selectedPickupDate),
                          style: GoogleFonts.openSans(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: selectedPickupDate != null
                                ? Colors.black87
                                : Colors.grey.shade500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    Icons.arrow_forward_ios,
                    size: 16,
                    color: Colors.grey.shade400,
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Sélection d'heure
          GestureDetector(
            onTap: () => _selectPickupTime(context),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: selectedPickupTime != null
                    ? BoutiqueThemeProvider.of(context).primary
                    : Colors.grey.shade300,
                  width: selectedPickupTime != null ? 2 : 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.access_time_outlined,
                    color: selectedPickupTime != null
                        ? BoutiqueThemeProvider.of(context).primary
                        : Colors.grey.shade600,
                    size: 22,
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Heure de récupération',
                          style: GoogleFonts.openSans(
                            fontSize: 12,
                            color: Colors.grey.shade600,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _formatTime(selectedPickupTime),
                          style: GoogleFonts.openSans(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: selectedPickupTime != null
                                ? Colors.black87
                                : Colors.grey.shade500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    Icons.arrow_forward_ios,
                    size: 16,
                    color: Colors.grey.shade400,
                  ),
                ],
              ),
            ),
          ),
        ],
      ],
    );
  }
}

/// Widget pour une option de livraison
class DeliveryOption extends StatelessWidget {
  final String id;
  final String title;
  final String description;
  final IconData icon;
  final Color iconColor;
  final bool isSelected;
  final VoidCallback onTap;

  const DeliveryOption({
    super.key,
    required this.id,
    required this.title,
    required this.description,
    required this.icon,
    required this.iconColor,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? BoutiqueThemeProvider.of(context).primary : Colors.grey.shade300,
            width: isSelected ? 2.5 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(isSelected ? 0.08 : 0.04),
              blurRadius: isSelected ? 12 : 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            // Radio button
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: isSelected ? BoutiqueThemeProvider.of(context).primary : Colors.grey.shade400,
                  width: 2,
                ),
              ),
              child: isSelected
                  ? Center(
                      child: Container(
                        width: 12,
                        height: 12,
                        decoration: BoxDecoration(
                          color: BoutiqueThemeProvider.of(context).primary,
                          shape: BoxShape.circle,
                        ),
                      ),
                    )
                  : null,
            ),
            const SizedBox(width: 16),
            // Icône et texte
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: iconColor.withOpacity(0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                icon,
                color: iconColor,
                size: 28,
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
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 4),
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
      ),
    );
  }
}

/// Étape 3 : Mode de paiement et résumé
class Step3PaymentAndSummary extends StatelessWidget {
  final String? selectedPaymentMode;
  final Function(String) onPaymentModeChanged;
  final List<Map<String, dynamic>> items;
  final int total;
  final String? selectedDeliveryMode;
  final String nomClient;
  final String phoneClient;

  const Step3PaymentAndSummary({
    super.key,
    required this.selectedPaymentMode,
    required this.onPaymentModeChanged,
    required this.items,
    required this.total,
    required this.selectedDeliveryMode,
    required this.nomClient,
    required this.phoneClient,
  });

  Map<String, dynamic> _getPaymentData(String id) {
    switch (id) {
      case 'especes':
        return {
          'name': 'Espèces (à la livraison)',
          'image': 'lib/core/assets/cash.png',
          'color': const Color(0xFF4CAF50),
          'icon': Icons.money,
        };
      case 'wave':
        return {
          'name': 'Wave',
          'image': 'lib/core/assets/WAVE.png',
          'color': const Color(0xFF1BA5E0),
          'icon': Icons.account_balance_wallet,
        };
      // ============================================================
      // MODES DE PAIEMENT NON DISPONIBLES DANS L'API ACTUELLE
      // ============================================================
      // case 'orange':
      //   return {
      //     'name': 'Orange Money',
      //     'image': 'lib/core/assets/orange.png',
      //     'color': const Color(0xFFFF7900),
      //     'icon': Icons.phone_android,
      //   };
      // case 'moov':
      //   return {
      //     'name': 'Moov Money',
      //     'image': 'lib/core/assets/moov.png',
      //     'color': const Color(0xFFFF6600),
      //     'icon': Icons.smartphone,
      //   };
      // case 'card':
      //   return {
      //     'name': 'Carte bancaire',
      //     'image': 'lib/core/assets/card.png',
      //     'color': const Color(0xFF424242),
      //     'icon': Icons.credit_card,
      //   };
      default:
        return {
          'name': 'Non sélectionné',
          'image': '',
          'color': Colors.grey,
          'icon': Icons.payment,
        };
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Mode de paiement
        Text(
          'Mode de paiement',
          style: GoogleFonts.openSans(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Sélectionnez votre méthode de paiement préférée',
          style: GoogleFonts.openSans(
            fontSize: 15,
            color: Colors.grey.shade600,
            height: 1.4,
          ),
        ),
        const SizedBox(height: 20),

        // Menu déroulant pour le mode de paiement
        PaymentDropdown(
          selectedPaymentMode: selectedPaymentMode,
          onPaymentModeChanged: onPaymentModeChanged,
          getPaymentData: _getPaymentData,
        ),

        const SizedBox(height: 32),

        // Résumé de la commande (simplifié)
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.06),
                blurRadius: 12,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Titre
              Text(
                'Résumé de la commande',
                style: GoogleFonts.openSans(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 20),

              // Liste des produits (format simplifié)
              ...items.map((item) {
                final itemTotal = (item['price'] as int) * (item['quantity'] as int);
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          '${item['name']} x${item['quantity']}',
                          style: GoogleFonts.openSans(
                            fontSize: 14,
                            color: Colors.black87,
                          ),
                        ),
                      ),
                      Text(
                        '${itemTotal.toStringAsFixed(0)} FCFA',
                        style: GoogleFonts.openSans(
                          fontSize: 14,
                          color: Colors.black87,
                        ),
                      ),
                    ],
                  ),
                );
              }),

              const SizedBox(height: 16),
              Divider(color: Colors.grey.shade300, thickness: 1),
              const SizedBox(height: 12),

              // Sous-total
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Sous-total:',
                    style: GoogleFonts.openSans(
                      fontSize: 15,
                      color: Colors.black87,
                    ),
                  ),
                  Text(
                    '$total FCFA',
                    style: GoogleFonts.openSans(
                      fontSize: 15,
                      color: Colors.black87,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 12),
              Divider(color: Colors.grey.shade900, thickness: 2),
              const SizedBox(height: 12),

              // Total
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Total:',
                    style: GoogleFonts.openSans(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  Text(
                    '$total FCFA',
                    style: GoogleFonts.openSans(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPaymentSummaryRow(Map<String, dynamic> paymentData) {
    return Row(
      children: [
        // Image ou icône du mode de paiement
        Container(
          width: 50,
          height: 50,
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.grey.shade50,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: Image.asset(
            paymentData['image'],
            fit: BoxFit.contain,
            errorBuilder: (context, error, stackTrace) {
              return Icon(
                paymentData['icon'],
                color: paymentData['color'],
                size: 28,
              );
            },
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Paiement',
                style: GoogleFonts.openSans(
                  fontSize: 12,
                  color: Colors.grey.shade600,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                paymentData['name'],
                style: GoogleFonts.openSans(
                  fontSize: 14,
                  color: Colors.black87,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Widget pour le menu déroulant de paiement
class PaymentDropdown extends StatelessWidget {
  final String? selectedPaymentMode;
  final Function(String) onPaymentModeChanged;
  final Map<String, dynamic> Function(String) getPaymentData;

  const PaymentDropdown({
    super.key,
    required this.selectedPaymentMode,
    required this.onPaymentModeChanged,
    required this.getPaymentData,
  });

  List<Map<String, dynamic>> _getPaymentOptions() {
    return [
      {'id': 'especes', 'name': 'Espèces (à la livraison)', 'imagePath': 'lib/core/assets/cash.png', 'color': const Color(0xFF4CAF50), 'icon': Icons.money},
      {'id': 'wave', 'name': 'Wave', 'imagePath': 'lib/core/assets/WAVE.png', 'color': const Color(0xFF1BA5E0), 'icon': Icons.account_balance_wallet},
      // ============================================================
      // MODES DE PAIEMENT NON DISPONIBLES DANS L'API ACTUELLE
      // Décommenter quand l'API les supportera
      // ============================================================
      // {'id': 'orange', 'name': 'Orange Money', 'imagePath': 'lib/core/assets/orange.png', 'color': const Color(0xFFFF7900), 'icon': Icons.phone_android},
      // {'id': 'moov', 'name': 'Moov Money', 'imagePath': 'lib/core/assets/moov.png', 'color': const Color(0xFFFF6600), 'icon': Icons.smartphone},
      // {'id': 'card', 'name': 'Carte bancaire', 'imagePath': 'lib/core/assets/card.png', 'color': const Color(0xFF424242), 'icon': Icons.credit_card},
    ];
  }

  void _showPaymentOptions(BuildContext context) {
    // Fermer le clavier s'il est ouvert
    FocusScope.of(context).unfocus();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      enableDrag: true,
      isDismissible: true,
      builder: (context) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
          ),
          padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Titre
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      'Choisir un mode de paiement',
                      style: GoogleFonts.poppins(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: Colors.black87,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              // Liste des options
              ..._getPaymentOptions().map((option) {
                final isSelected = selectedPaymentMode == option['id'];
                return GestureDetector(
                  onTap: () {
                    onPaymentModeChanged(option['id']);
                    Navigator.pop(context);
                  },
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isSelected ? BoutiqueThemeProvider.of(context).primary : Colors.grey.shade200,
                        width: isSelected ? 2.5 : 1,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(isSelected ? 0.08 : 0.04),
                          blurRadius: isSelected ? 12 : 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        // Image ou icône
                        Container(
                          width: 50,
                          height: 50,
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: (option['color'] as Color).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Image.asset(
                            option['imagePath'],
                            fit: BoxFit.contain,
                            errorBuilder: (context, error, stackTrace) {
                              return Icon(
                                option['icon'],
                                size: 28,
                                color: option['color'],
                              );
                            },
                          ),
                        ),
                        const SizedBox(width: 16),
                        // Nom
                        Expanded(
                          child: Text(
                            option['name'],
                            style: GoogleFonts.openSans(
                              fontSize: 15,
                              fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                              color: isSelected ? BoutiqueThemeProvider.of(context).primary : Colors.black87,
                            ),
                          ),
                        ),
                        // Indicateur de sélection
                        if (isSelected)
                          Icon(
                            Icons.check_circle,
                            color: BoutiqueThemeProvider.of(context).primary,
                            size: 24,
                          ),
                      ],
                    ),
                  ),
                );
              }).toList(),
              const SizedBox(height: 10),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final paymentData = selectedPaymentMode != null
        ? getPaymentData(selectedPaymentMode!)
        : null;

    return GestureDetector(
      onTap: () => _showPaymentOptions(context),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: selectedPaymentMode != null
                ? BoutiqueThemeProvider.of(context).primary
                : Colors.grey.shade300,
            width: selectedPaymentMode != null ? 2 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          children: [
            // Image ou icône du mode sélectionné
            if (paymentData != null) ...[
              Container(
                width: 50,
                height: 50,
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: (paymentData['color'] as Color).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Image.asset(
                  paymentData['image'],
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) {
                    return Icon(
                      paymentData['icon'],
                      size: 28,
                      color: paymentData['color'],
                    );
                  },
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  paymentData['name'],
                  style: GoogleFonts.openSans(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: const Color.fromARGB(221, 133, 30, 151),
                  ),
                ),
              ),
            ] else ...[
              Icon(
                Icons.mobile_friendly,
                size: 26,
                color: const Color.fromARGB(255, 8, 110, 78),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Sélectionner un mode de paiement',
                  style: GoogleFonts.openSans(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: const Color.fromARGB(255, 26, 26, 26),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
            // Icône déroulante
            Icon(
              Icons.keyboard_arrow_down,
              size: 28,
              color: const Color.fromARGB(255, 111, 12, 120),
            ),
          ],
        ),
      ),
    );
  }
}

/// Widget pour une option de paiement
class PaymentOption extends StatelessWidget {
  final String id;
  final String name;
  final String imagePath;
  final Color color;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  const PaymentOption({
    super.key,
    required this.id,
    required this.name,
    required this.imagePath,
    required this.color,
    required this.icon,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? BoutiqueThemeProvider.of(context).primary : Colors.grey.shade200,
            width: isSelected ? 2.5 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isSelected ? 0.08 : 0.04),
              blurRadius: isSelected ? 12 : 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Essayer d'abord l'image, sinon utiliser l'icône colorée
            Image.asset(
              imagePath,
              height: 45,
              fit: BoxFit.contain,
              errorBuilder: (context, error, stackTrace) {
                return Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    icon,
                    size: 32,
                    color: color,
                  ),
                );
              },
            ),
            const SizedBox(height: 12),
            // Nom du mode de paiement
            Text(
              name,
              style: GoogleFonts.openSans(
                fontSize: 13,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                color: isSelected ? BoutiqueThemeProvider.of(context).primary : Colors.black87,
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}

/// Widget pour une option de paiement horizontale (pour espèces)
class PaymentOptionHorizontal extends StatelessWidget {
  final String id;
  final String name;
  final String imagePath;
  final Color color;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  const PaymentOptionHorizontal({
    super.key,
    required this.id,
    required this.name,
    required this.imagePath,
    required this.color,
    required this.icon,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? BoutiqueThemeProvider.of(context).primary : Colors.grey.shade200,
            width: isSelected ? 2.5 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isSelected ? 0.08 : 0.04),
              blurRadius: isSelected ? 12 : 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            // Image ou icône
            Container(
              width: 50,
              height: 50,
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                icon,
                size: 28,
                color: color,
              ),
            ),
            const SizedBox(width: 16),
            // Nom du mode de paiement
            Expanded(
              child: Text(
                name,
                style: GoogleFonts.openSans(
                  fontSize: 15,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                  color: isSelected ? BoutiqueThemeProvider.of(context).primary : Colors.black87,
                ),
              ),
            ),
            // Radio button
            if (isSelected)
              Icon(
                Icons.check_circle,
                color: BoutiqueThemeProvider.of(context).primary,
                size: 24,
              ),
          ],
        ),
      ),
    );
  }
}
